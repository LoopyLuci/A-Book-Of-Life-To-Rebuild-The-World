"""The tkinter user interface of the desktop reader.

The window is built from plain ``tkinter`` and ``ttk`` widgets only: there is
no web view, no third party toolkit and no network access anywhere in this
module.  The reader pane renders Markdown into a ``Text`` widget by using the
widget's tag system for headings, lists, quotes, code and links.

The corpus is loaded on a background thread so that the window appears
immediately; the loader reports its progress through a queue that the main
thread polls.
"""

from __future__ import annotations

import queue
import re
import threading
import tkinter as tk
from collections.abc import Callable, Sequence
from pathlib import Path
from tkinter import ttk
from typing import Any

from . import configure_logging
from .corpus import Corpus, Entry, load_corpus, load_disclaimer, load_domain_descriptions
from .i18n import Translator
from .search import SearchEngine, SearchResult
from .settings import Settings
from .theme import Palette, get_palette

LOGGER = configure_logging()

__all__ = ["AbookApp", "AboutDialog", "MarkdownRenderer", "QuickJumpDialog"]

#: How long the search waits after the last keystroke.
SEARCH_DEBOUNCE_MS = 180

#: The maximum number of results shown in the results list.
MAX_RESULTS = 50

#: The identifier prefixes used in the tree widget.
DOMAIN_PREFIX = "domain:"
ENTRY_PREFIX = "entry:"
RECENT_PREFIX = "recent:"


class MarkdownRenderer:
    """Render Markdown into a ``Text`` widget with styled tags.

    Args:
        widget: The ``Text`` widget the content is rendered into.
    """

    HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
    RULE_RE = re.compile(r"^(?:-{3,}|\*{3,}|_{3,})$")
    ITEM_RE = re.compile(r"^(\s*)([-*+]|\d+[.)])\s+(.*)$")
    INLINE_RE = re.compile(
        r"\*\*(?P<bold>.+?)\*\*"
        r"|`(?P<code>[^`]+)`"
        r"|\[(?P<link>[^\]]+)\]\((?P<href>[^)]+)\)"
        r"|(?<![\w*])\*(?P<italic>[^*\n]+)\*(?![\w*])"
    )

    def __init__(self, widget: tk.Text) -> None:
        self._widget = widget

    # ------------------------------------------------------------------
    # Styling
    # ------------------------------------------------------------------
    def configure(self, palette: Palette) -> None:
        """Apply *palette* to the text widget and to every tag."""
        widget = self._widget
        widget.configure(
            background=palette.code_background,
            foreground=palette.foreground,
            insertbackground=palette.foreground,
            selectbackground=palette.selection,
            selectforeground=palette.selection_foreground,
            highlightthickness=0,
            padx=18,
            pady=14,
            spacing1=1,
            spacing3=3,
        )
        widget.tag_configure("title", font=("TkDefaultFont", 19, "bold"), foreground=palette.accent, spacing1=6, spacing3=10)
        widget.tag_configure("meta", foreground=palette.muted, font=("TkDefaultFont", 10))
        widget.tag_configure("h1", font=("TkDefaultFont", 16, "bold"), foreground=palette.foreground, spacing1=12, spacing3=6)
        widget.tag_configure("h2", font=("TkDefaultFont", 14, "bold"), foreground=palette.accent, spacing1=10, spacing3=5)
        widget.tag_configure("h3", font=("TkDefaultFont", 12, "bold"), foreground=palette.foreground, spacing1=8, spacing3=4)
        widget.tag_configure("h4", font=("TkDefaultFont", 11, "bold"), foreground=palette.muted, spacing1=6, spacing3=3)
        widget.tag_configure("body", foreground=palette.foreground)
        widget.tag_configure("bullet", foreground=palette.foreground)
        widget.tag_configure("quote", foreground=palette.quote, font=("TkDefaultFont", 10, "italic"))
        widget.tag_configure("code", font=("TkFixedFont", 10), foreground=palette.foreground)
        widget.tag_configure("codeblock", font=("TkFixedFont", 10), background=palette.panel, foreground=palette.foreground)
        widget.tag_configure("link", foreground=palette.link, underline=True)
        widget.tag_configure("muted", foreground=palette.muted, font=("TkDefaultFont", 9))
        widget.tag_configure("rule", foreground=palette.border)
        widget.tag_configure("strong", font=("TkDefaultFont", 10, "bold"))
        widget.tag_configure("italic", font=("TkDefaultFont", 10, "italic"))
        widget.tag_configure("inlinecode", font=("TkFixedFont", 10), foreground=palette.accent)

    # ------------------------------------------------------------------
    # Rendering
    # ------------------------------------------------------------------
    def begin(self) -> None:
        """Clear the widget and make it writable."""
        self._widget.configure(state="normal")
        self._widget.delete("1.0", "end")

    def end(self) -> None:
        """Make the widget read-only again."""
        self._widget.configure(state="disabled")

    def render(self, markdown: str, *, skip_first_heading: bool = True) -> None:
        """Render *markdown* into the widget.

        Headings, bullet and numbered lists, block quotes, horizontal rules,
        fenced code blocks and inline emphasis are preserved.

        Args:
            markdown: The Markdown source.
            skip_first_heading: When ``True`` a leading level one heading is
                left out, because the reader shows the title separately.
        """
        widget = self._widget
        in_code = False
        code_buffer: list[str] = []
        skip_heading = skip_first_heading

        for raw in markdown.splitlines():
            stripped = raw.strip()

            if stripped.startswith("```"):
                if in_code:
                    self._flush_code(code_buffer)
                    code_buffer = []
                in_code = not in_code
                continue
            if in_code:
                code_buffer.append(raw)
                continue

            if not stripped:
                widget.insert("end", "\n")
                continue

            if skip_heading and self.HEADING_RE.match(stripped):
                skip_heading = False
                continue
            skip_heading = False

            heading = self.HEADING_RE.match(stripped)
            if heading is not None:
                level = min(len(heading.group(1)), 4)
                self._insert_inline(heading.group(2).strip(), f"h{level}")
                widget.insert("end", "\n")
                continue

            if self.RULE_RE.match(stripped):
                widget.insert("end", "─" * 48 + "\n", "rule")
                continue

            if stripped.startswith(">"):
                self._insert_inline(stripped.lstrip(">").strip(), "quote")
                widget.insert("end", "\n")
                continue

            item = self.ITEM_RE.match(raw)
            if item is not None:
                indent, marker, text = item.groups()
                depth = len(indent.expandtabs(4)) // 2
                prefix = "• " if marker[0] in "-*+" else f"{marker} "
                widget.insert("end", "  " * depth + prefix, "bullet")
                self._insert_inline(text.strip(), "body")
                widget.insert("end", "\n")
                continue

            self._insert_inline(raw.rstrip(), "body")
            widget.insert("end", "\n")

        if code_buffer:
            self._flush_code(code_buffer)
        if in_code:
            LOGGER.debug("the document ended inside a fenced code block")

    def _flush_code(self, lines: Sequence[str]) -> None:
        """Write a fenced code block into the widget."""
        if not lines:
            return
        self._widget.insert("end", "\n")
        for line in lines:
            self._widget.insert("end", line + "\n", "codeblock")
        self._widget.insert("end", "\n")

    def _insert_inline(self, text: str, base_tag: str) -> None:
        """Insert *text*, honouring the inline emphasis of the Markdown syntax."""
        widget = self._widget
        position = 0
        for match in self.INLINE_RE.finditer(text):
            if match.start() > position:
                widget.insert("end", text[position : match.start()], base_tag)
            bold = match.group("bold")
            code = match.group("code")
            link = match.group("link")
            href = match.group("href")
            if bold is not None:
                widget.insert("end", bold, (base_tag, "strong"))
            elif code is not None:
                widget.insert("end", code, (base_tag, "inlinecode"))
            elif link is not None:
                widget.insert("end", link, (base_tag, "link"))
                if href and href != link:
                    widget.insert("end", f" ({href})", (base_tag, "muted"))
            else:
                italic = match.group("italic")
                if italic is not None:
                    widget.insert("end", italic, (base_tag, "italic"))
            position = match.end()
        if position < len(text):
            widget.insert("end", text[position:], base_tag)


class AboutDialog(tk.Toplevel):
    """The about box: the version and the disclaimer, with an acknowledgement.

    Args:
        master: The parent window.
        translator: The active translator.
        version: The application version.
        disclaimer: The disclaimer text, quoted from ``docs/DISCLAIMER.md``.
    """

    def __init__(
        self,
        master: tk.Misc,
        translator: Translator,
        version: str,
        disclaimer: str,
        palette: Palette | None = None,
    ) -> None:
        super().__init__(master)
        self._translator = translator
        self._acknowledged = False
        self._palette = palette or get_palette("light")
        self.title(translator.t("about"))
        self.resizable(False, False)
        self.transient(master)
        self.protocol("WM_DELETE_WINDOW", self.destroy)

        frame = ttk.Frame(self, padding=18)
        frame.grid(row=0, column=0, sticky="nsew")

        ttk.Label(
            frame, text=translator.t("app_title"), font=("TkDefaultFont", 14, "bold")
        ).grid(row=0, column=0, sticky="w")
        ttk.Label(
            frame, text=f"{translator.t('version')}: {version}"
        ).grid(row=1, column=0, sticky="w", pady=(2, 12))

        ttk.Label(frame, text=translator.t("disclaimer"), font=("TkDefaultFont", 11, "bold")).grid(
            row=2, column=0, sticky="w"
        )

        text = tk.Text(
            frame,
            width=64,
            height=11,
            wrap="word",
            relief="solid",
            borderwidth=1,
            font=("TkDefaultFont", 10),
        )
        text.grid(row=3, column=0, sticky="nsew", pady=(6, 4))
        text.insert("1.0", disclaimer)
        text.configure(
            background=self._palette.panel,
            foreground=self._palette.foreground,
            selectbackground=self._palette.selection,
            selectforeground=self._palette.selection_foreground,
            highlightthickness=0,
            borderwidth=1,
            relief="solid",
        )
        text.configure(state="disabled")

        ttk.Label(frame, text=translator.t("disclaimer_full")).grid(
            row=4, column=0, sticky="w", pady=(0, 10)
        )

        self._check = ttk.Checkbutton(
            frame, text=translator.t("disclaimer_acknowledge"), command=self._toggle
        )
        self._check.grid(row=5, column=0, sticky="w")

        self._message = ttk.Label(
            frame, text=translator.t("disclaimer_required"), foreground=self._palette.danger
        )
        self._message.grid(row=6, column=0, sticky="w", pady=(4, 0))

        buttons = ttk.Frame(frame)
        buttons.grid(row=7, column=0, sticky="e", pady=(14, 0))
        self._ok_button = ttk.Button(buttons, text=translator.t("ok"), command=self._accept, state="disabled")
        self._ok_button.grid(row=0, column=0, padx=(0, 8))
        ttk.Button(buttons, text=translator.t("close"), command=self.destroy).grid(row=0, column=1)

        self.bind("<Return>", lambda _event: self._accept())
        self.update_idletasks()
        self.grab_set()
        self.focus_set()

    def _toggle(self) -> None:
        """Enable the confirmation button once the box has been ticked."""
        self._acknowledged = bool(self._check.instate(["selected"]))
        self._ok_button.configure(state="normal" if self._acknowledged else "disabled")
        if self._acknowledged:
            self._message.configure(text="")

    def _accept(self) -> None:
        """Close the dialog when the disclaimer has been acknowledged."""
        if not self._acknowledged:
            self._message.configure(text=self._translator.t("disclaimer_required"))
            return
        self.destroy()


class QuickJumpDialog(tk.Toplevel):
    """A small palette-style dialog that jumps to an entry by name.

    Args:
        master: The parent window.
        entries: The entries that can be jumped to.
        on_select: Called with the chosen entry.
    """

    def __init__(
        self,
        master: tk.Misc,
        entries: Sequence[Entry],
        translator: Translator,
        on_select: Callable[[Entry], None],
        engine: SearchEngine | None = None,
        palette: Palette | None = None,
    ) -> None:
        super().__init__(master)
        self._entries = list(entries)
        self._on_select = on_select
        self._translator = translator
        self._engine = engine
        self._palette = palette or get_palette("light")
        self._filtered: list[Entry] = list(self._entries)

        self.title(translator.t("quick_jump"))
        self.geometry("520x420")
        self.transient(master)
        self.protocol("WM_DELETE_WINDOW", self.destroy)

        frame = ttk.Frame(self, padding=12)
        frame.pack(fill="both", expand=True)

        self._entry = ttk.Entry(frame)
        self._entry.pack(fill="x")
        self._entry.insert(0, "")
        self._entry.bind("<KeyRelease>", self._filter)
        self._entry.bind("<Return>", self._choose)
        self._entry.bind("<Down>", self._focus_list)

        self._listbox = tk.Listbox(frame, exportselection=False, activestyle="none")
        self._listbox.pack(fill="both", expand=True, pady=(8, 0))
        self._listbox.configure(
            background=self._palette.panel,
            foreground=self._palette.foreground,
            selectbackground=self._palette.selection,
            selectforeground=self._palette.selection_foreground,
            highlightthickness=0,
            borderwidth=1,
            relief="solid",
            font=("TkDefaultFont", 10),
        )
        self._listbox.bind("<Double-Button-1>", self._choose)
        self._listbox.bind("<Return>", self._choose)
        self._listbox.bind("<Escape>", lambda _event: self.destroy())

        self.bind("<Escape>", lambda _event: self.destroy())
        self.update_idletasks()
        self._centre(master)
        self.grab_set()
        self._entry.focus_set()

    def _centre(self, master: tk.Misc) -> None:
        """Centre the dialog over its parent."""
        try:
            x = master.winfo_rootx() + (master.winfo_width() - self.winfo_width()) // 2
            y = master.winfo_rooty() + (master.winfo_height() - self.winfo_height()) // 3
            self.geometry(f"+{max(x, 0)}+{max(y, 0)}")
        except tk.TclError:  # pragma: no cover - defensive
            pass

    def _filter(self, _event: tk.Event | None = None) -> None:
        """Filter the list with the text that has been typed."""
        query = self._entry.get().strip().lower()
        if self._engine is not None:
            self._filtered = self._engine.quick_jump(query, limit=200)
        else:
            self._filtered = [
                entry
                for entry in self._entries
                if not query
                or query in entry.title.lower()
                or query in entry.slug.lower()
                or any(query in tag.lower() for tag in entry.tags)
            ]
        self._listbox.delete(0, "end")
        for entry in self._filtered:
            self._listbox.insert("end", f"{entry.title}  —  {entry.domain}")

    def _focus_list(self, _event: tk.Event | None = None) -> None:
        """Move the focus from the query field to the list."""
        self._listbox.focus_set()
        if self._listbox.size():
            self._listbox.selection_set(0)
        return "break"

    def _choose(self, _event: tk.Event | None = None) -> None:
        """Open the highlighted entry and close the dialog."""
        selection = self._listbox.curselection()
        if not selection:
            return
        index = int(selection[0])
        if index >= len(self._filtered):
            return
        entry = self._filtered[index]
        self.destroy()
        self._on_select(entry)


class AbookApp(tk.Tk):
    """The main window of the desktop reader.

    Args:
        root_path: The repository root.
        settings: The persisted preferences.
        translator: The translator of the active language.
    """

    def __init__(
        self,
        root_path: Path,
        settings: Settings,
        translator: Translator,
    ) -> None:
        super().__init__()
        self._root_path = Path(root_path)
        self._settings = settings
        self._translator = translator
        self._corpus: Corpus | None = None
        self._engine: SearchEngine | None = None
        self._domain_descriptions: dict[str, str] = {}
        self._current_entry: Entry | None = None
        self._messages: queue.Queue[tuple[Any, ...]] = queue.Queue()
        self._search_after: str | None = None
        self._poll_after: str | None = None
        self._refreshing_tree = False
        self._recent_shown: list[str] = []
        self._palette = get_palette(settings.theme)
        self._result_entries: list[Entry] = []

        self._build_widgets()
        self._apply_theme()
        self._apply_language()
        self._restore_geometry()
        self.protocol("WM_DELETE_WINDOW", self._on_close)

        self.bind_all("<Control-f>", self._focus_search)
        self.bind_all("<Control-k>", self._open_quick_jump)
        self.bind_all("<F1>", self._open_about)
        self.bind_all("<Control-q>", self._quit)

        self.after(50, self._poll_messages)
        self._start_loading()
    # ------------------------------------------------------------------
    # Construction
    # ------------------------------------------------------------------
    def _build_widgets(self) -> None:
        """Create every widget of the window."""
        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)

        toolbar = ttk.Frame(self, style="Panel.TFrame", padding=(14, 10))
        toolbar.grid(row=0, column=0, sticky="ew")
        toolbar.columnconfigure(2, weight=1)

        brand = ttk.Frame(toolbar, style="Panel.TFrame")
        brand.grid(row=0, column=0, sticky="w", padx=(0, 18))
        self._title_label = ttk.Label(brand, text="", style="Title.TLabel")
        self._title_label.grid(row=0, column=0, sticky="w")
        self._tagline_label = ttk.Label(brand, text="", style="Muted.TLabel")
        self._tagline_label.grid(row=1, column=0, sticky="w")

        self._search_label = ttk.Label(toolbar, text="", style="Panel.TLabel")
        self._search_label.grid(row=0, column=1, sticky="w", padx=(0, 6))
        self._search_var = tk.StringVar()
        self._search_entry = ttk.Entry(toolbar, textvariable=self._search_var, width=30)
        self._search_entry.grid(row=0, column=2, sticky="ew", padx=(0, 14))
        self._search_var.trace_add("write", self._on_search_changed)

        self._domain_label = ttk.Label(toolbar, text="", style="Panel.TLabel")
        self._domain_label.grid(row=0, column=3, sticky="w", padx=(0, 6))
        self._domain_index = 0
        self._domain_combo = ttk.Combobox(
            toolbar, state="readonly", width=16
        )
        self._domain_combo.grid(row=0, column=4, sticky="w", padx=(0, 12))
        self._domain_combo.bind("<<ComboboxSelected>>", self._on_filter_changed)

        self._safety_label = ttk.Label(toolbar, text="", style="Panel.TLabel")
        self._safety_label.grid(row=0, column=5, sticky="w", padx=(0, 6))
        self._safety_index = 0
        self._safety_combo = ttk.Combobox(
            toolbar, state="readonly", width=16
        )
        self._safety_combo.grid(row=0, column=6, sticky="w", padx=(0, 12))
        self._safety_combo.bind("<<ComboboxSelected>>", self._on_filter_changed)

        self._language_label = ttk.Label(toolbar, text="", style="Panel.TLabel")
        self._language_label.grid(row=0, column=7, sticky="w", padx=(0, 6))
        self._language_codes: list[str] = []
        self._language_var = tk.StringVar()
        self._language_combo = ttk.Combobox(
            toolbar, textvariable=self._language_var, state="readonly", width=14
        )
        self._language_combo.grid(row=0, column=8, sticky="w", padx=(0, 12))
        self._language_combo.bind("<<ComboboxSelected>>", self._on_language_changed)

        self._theme_button = ttk.Button(toolbar, text="", width=8, command=self._toggle_theme)
        self._theme_button.grid(row=0, column=9, sticky="w", padx=(0, 8))
        self._about_button = ttk.Button(toolbar, text="", width=8, command=self._open_about)
        self._about_button.grid(row=0, column=10, sticky="w")

        self._progress = ttk.Progressbar(toolbar, mode="indeterminate", length=140)
        self._progress.grid(row=0, column=11, sticky="e", padx=(12, 0))

        body = ttk.Frame(self, padding=(10, 8, 10, 0))
        body.grid(row=1, column=0, sticky="nsew")
        body.columnconfigure(1, weight=1)
        body.rowconfigure(0, weight=1)

        left = ttk.Frame(body)
        left.grid(row=0, column=0, sticky="nsew", padx=(0, 10))
        left.rowconfigure(0, weight=3)
        left.rowconfigure(1, weight=2)
        left.columnconfigure(0, weight=1)

        tree_frame = ttk.Frame(left)
        tree_frame.grid(row=0, column=0, sticky="nsew")
        tree_frame.rowconfigure(0, weight=1)
        tree_frame.columnconfigure(0, weight=1)
        self._tree = ttk.Treeview(tree_frame, columns=("count", "safety"), show="tree headings")
        self._tree.grid(row=0, column=0, sticky="nsew")
        tree_scroll = ttk.Scrollbar(tree_frame, orient="vertical", command=self._tree.yview)
        tree_scroll.grid(row=0, column=1, sticky="ns")
        self._tree.configure(yscrollcommand=tree_scroll.set)
        self._tree.bind("<<TreeviewSelect>>", self._on_tree_select)
        self._tree.bind("<Double-Button-1>", self._on_tree_activate)

        results_frame = ttk.Frame(left)
        results_frame.grid(row=1, column=0, sticky="nsew", pady=(10, 0))
        results_frame.rowconfigure(1, weight=1)
        results_frame.columnconfigure(0, weight=1)
        self._results_label = ttk.Label(results_frame, text="")
        self._results_label.grid(row=0, column=0, sticky="w", pady=(0, 4))
        self._results = tk.Listbox(
            results_frame,
            exportselection=False,
            activestyle="none",
            height=8,
            font=("TkDefaultFont", 10),
        )
        self._results.grid(row=1, column=0, sticky="nsew")
        results_scroll = ttk.Scrollbar(results_frame, orient="vertical", command=self._results.yview)
        results_scroll.grid(row=1, column=1, sticky="ns")
        self._results.configure(yscrollcommand=results_scroll.set)
        self._results.bind("<<ListboxSelect>>", self._on_result_selected)
        self._results.bind("<Double-Button-1>", self._on_result_activated)

        right = ttk.Frame(body)
        right.grid(row=0, column=1, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self._reader = tk.Text(
            right,
            wrap="word",
            borderwidth=0,
            highlightthickness=0,
            cursor="arrow",
            font=("TkDefaultFont", 10),
        )
        self._reader.grid(row=0, column=0, sticky="nsew")
        reader_scroll = ttk.Scrollbar(right, orient="vertical", command=self._reader.yview)
        reader_scroll.grid(row=0, column=1, sticky="ns")
        self._reader.configure(yscrollcommand=reader_scroll.set)
        self._renderer = MarkdownRenderer(self._reader)

        status = ttk.Frame(self, style="Panel.TFrame", padding=(14, 6))
        status.grid(row=2, column=0, sticky="ew")
        status.columnconfigure(0, weight=1)
        self._status_label = ttk.Label(status, text="", style="Muted.TLabel")
        self._status_label.grid(row=0, column=0, sticky="w")
        self._shortcut_label = ttk.Label(status, text="", style="Muted.TLabel")
        self._shortcut_label.grid(row=0, column=1, sticky="e")

    def _restore_geometry(self) -> None:
        """Apply the stored window size and position."""
        width = max(self._settings.window_width, 900)
        height = max(self._settings.window_height, 600)
        if self._settings.window_x is not None and self._settings.window_y is not None:
            self.geometry(f"{width}x{height}+{self._settings.window_x}+{self._settings.window_y}")
        else:
            self.geometry(f"{width}x{height}")
        self.minsize(900, 600)

    # ------------------------------------------------------------------
    # Loading
    # ------------------------------------------------------------------
    def _start_loading(self) -> None:
        """Load the corpus on a background thread."""
        self._progress.start(12)
        self._set_status(self._translator.t("loading"))
        worker = threading.Thread(target=self._load_worker, name="abook-loader", daemon=True)
        worker.start()

    def _load_worker(self) -> None:
        """Load the corpus and post the result to the message queue."""
        try:
            corpus = load_corpus(self._root_path, progress=self._report_progress)
        except Exception as error:  # noqa: BLE001 - the window must survive anything
            LOGGER.exception("the corpus could not be loaded")
            self._messages.put(("error", error))
        else:
            self._messages.put(("loaded", corpus))

    def _report_progress(self, done: int, total: int) -> None:
        """Report the loading progress to the main thread."""
        self._messages.put(("progress", done, total))

    def _poll_messages(self) -> None:
        """Handle the messages posted by the loader thread."""
        try:
            while True:
                message = self._messages.get_nowait()
                kind = message[0]
                if kind == "progress":
                    self._set_status(
                        self._translator.t("loading_progress", done=message[1], total=message[2])
                    )
                elif kind == "loaded":
                    self._on_corpus_loaded(message[1])
                elif kind == "error":
                    self._on_corpus_failed(message[1])
        except queue.Empty:
            pass
        self._poll_after = self.after(50, self._poll_messages)

    def _on_corpus_loaded(self, corpus: Corpus) -> None:
        """Populate the window once the corpus is available."""
        self._progress.stop()
        self._progress.grid_remove()
        self._corpus = corpus
        self._engine = SearchEngine(corpus)
        self._domain_descriptions = load_domain_descriptions(corpus.root)
        for warning in corpus.warnings:
            LOGGER.warning("%s", warning)
        self._populate_filters()
        self._populate_tree()
        self._update_status()
        self._show_placeholder()

    def _on_corpus_failed(self, error: Exception) -> None:
        """Report a failure to load the corpus."""
        self._progress.stop()
        self._progress.grid_remove()
        message = self._translator.t("loading_failed", error=error)
        self._renderer.begin()
        self._reader.insert("end", message + "\n", "muted")
        self._renderer.end()
        self._set_status(message)

    # ------------------------------------------------------------------
    # Content
    # ------------------------------------------------------------------
    def _populate_filters(self) -> None:
        """Fill the domain and safety filters with the corpus values."""
        corpus = self._corpus
        if corpus is None:
            return
        domain_values = [self._translator.t("all_domains")] + list(corpus.domains)
        self._domain_combo.configure(values=domain_values)
        self._domain_combo.current(min(self._domain_index, len(domain_values) - 1))
        safety_values = [self._translator.t("all_safety_levels")] + [
            self._safety_label_for(level) for level in ("green", "yellow", "red")
        ]
        self._safety_combo.configure(values=safety_values)
        self._safety_combo.current(min(self._safety_index, len(safety_values) - 1))

    def _safety_label_for(self, level: str) -> str:
        """Return the translated label of a safety level."""
        key = f"safety_{level}"
        label = self._translator.t(key)
        return label if label != key else level

    def _selected_domain(self) -> str | None:
        """Return the domain filter, or ``None`` when everything is shown."""
        corpus = self._corpus
        if corpus is None or self._domain_index <= 0:
            return None
        domains = list(corpus.domains)
        if self._domain_index > len(domains):
            return None
        return domains[self._domain_index - 1]

    def _selected_safety(self) -> str | None:
        """Return the safety filter, or ``None`` when everything is shown."""
        levels = ("green", "yellow", "red")
        if self._safety_index <= 0 or self._safety_index > len(levels):
            return None
        return levels[self._safety_index - 1]

    def _populate_tree(self) -> None:
        """Rebuild the tree of domains and entries."""
        corpus = self._corpus
        if corpus is None:
            return
        tree = self._tree
        tree.delete(*tree.get_children())
        domain = self._selected_domain()
        safety = self._selected_safety()

        self._tree.insert(
            "", "end", iid=RECENT_PREFIX + "root", text=self._translator.t("recently_read")
        )
        identifiers: list[str] = []
        for entry_id in self._settings.recently_read:
            entry = corpus.get(entry_id)
            if entry is not None:
                identifiers.append(entry_id)
                self._tree.insert(
                    RECENT_PREFIX + "root",
                    "end",
                    iid=RECENT_PREFIX + entry.id,
                    text=entry.title,
                    values=("", self._safety_label_for(entry.safety)),
                )
        self._recent_shown = identifiers

        for name in corpus.domains:
            entries = corpus.entries_by_domain.get(name, ())
            if domain is not None and name != domain:
                continue
            visible = [
                entry
                for entry in entries
                if safety is None or entry.safety == safety
            ]
            if not visible and safety is not None:
                continue
            iid = DOMAIN_PREFIX + name
            self._tree.insert(
                "",
                "end",
                iid=iid,
                text=name,
                values=(len(visible), ""),
                open=bool(domain is not None),
            )
            for entry in visible:
                self._tree.insert(
                    iid,
                    "end",
                    iid=ENTRY_PREFIX + entry.id,
                    text=entry.title,
                    values=("", self._safety_label_for(entry.safety)),
                )

    def _show_placeholder(self) -> None:
        """Show the empty state in the reader pane."""
        self._current_entry = None
        self._renderer.begin()
        self._reader.insert("end", self._translator.t("select_entry") + "\n", "muted")
        self._renderer.end()

    def _show_entry(self, entry: Entry) -> None:
        """Render *entry* in the reader pane."""
        self._current_entry = entry
        self._settings.remember_entry(entry.id)
        self._refresh_recent_node()
        renderer = self._renderer
        renderer.begin()
        self._reader.insert("end", entry.title + "\n", "title")
        meta = " · ".join(
            (
                entry.domain,
                self._difficulty_label(entry.difficulty),
                self._safety_label_for(entry.safety),
                self._verification_label(entry.verification.status),
            )
        )
        self._reader.insert("end", meta + "\n", "meta")
        if entry.tags:
            self._reader.insert(
                "end", f"{self._translator.t('tags')}: {', '.join(entry.tags)}\n", "muted"
            )
        self._reader.insert("end", "─" * 48 + "\n", "rule")
        renderer.render(entry.body)
        self._reader.insert(
            "end", f"\n{self._translator.t('path')}: {entry.path}\n", "muted"
        )
        renderer.end()
        self._reader.see("1.0")

    def _show_domain(self, domain: str) -> None:
        """Render the overview of *domain* in the reader pane."""
        corpus = self._corpus
        if corpus is None:
            return
        entries = corpus.entries_by_domain.get(domain, ())
        self._current_entry = None
        renderer = self._renderer
        renderer.begin()
        self._reader.insert("end", domain.capitalize() + "\n", "title")
        description = self._domain_descriptions.get(domain)
        if description:
            self._reader.insert("end", description + "\n", "meta")
        self._reader.insert(
            "end",
            self._translator.t("domain_entry_count", count=len(entries)) + "\n",
            "meta",
        )
        self._reader.insert("end", "─" * 48 + "\n", "rule")
        for entry in entries:
            self._reader.insert("end", "• ", "bullet")
            self._reader.insert("end", entry.title + "\n", "body")
            self._reader.insert(
                "end",
                "  "
                + " · ".join(
                    (
                        self._difficulty_label(entry.difficulty),
                        self._safety_label_for(entry.safety),
                        self._verification_label(entry.verification.status),
                    )
                )
                + "\n",
                "muted",
            )
        renderer.end()
        self._reader.see("1.0")

    def _difficulty_label(self, difficulty: str) -> str:
        """Return the translated label of a difficulty level."""
        if not difficulty:
            return "-"
        key = f"difficulty_{difficulty}"
        label = self._translator.t(key)
        return label if label != key else difficulty.capitalize()

    def _verification_label(self, status: str) -> str:
        """Return the translated label of a verification status."""
        key = f"status_{status.replace('-', '_')}"
        label = self._translator.t(key)
        return label if label != key else status

    def _refresh_recent_node(self) -> None:
        """Refresh the "recently read" node of the tree.

        The node is only rebuilt when the list has actually changed: rebuilding
        it clears the selection, and the selection event would otherwise send
        the application back here in a loop.
        """
        corpus = self._corpus
        if corpus is None:
            return
        identifiers = [
            entry_id for entry_id in self._settings.recently_read if corpus.get(entry_id)
        ]
        if identifiers == self._recent_shown:
            return
        root = RECENT_PREFIX + "root"
        selection = self._tree.selection()
        self._refreshing_tree = True
        try:
            children = self._tree.get_children(root)
            if children:
                self._tree.delete(*children)
            for entry_id in identifiers:
                entry = corpus.get(entry_id)
                if entry is not None:
                    self._tree.insert(
                        root,
                        "end",
                        iid=RECENT_PREFIX + entry.id,
                        text=entry.title,
                        values=("", self._safety_label_for(entry.safety)),
                    )
            if selection and self._tree.exists(selection[0]):
                self._tree.selection_set(selection[0])
        finally:
            self._refreshing_tree = False
            self._recent_shown = identifiers

    # ------------------------------------------------------------------
    # Events
    # ------------------------------------------------------------------
    def _on_tree_select(self, _event: tk.Event | None = None) -> None:
        """Show the entry or the domain that was selected in the tree."""
        if self._refreshing_tree:
            return
        selection = self._tree.selection()
        if not selection:
            return
        iid = selection[0]
        if iid.startswith(ENTRY_PREFIX):
            self._open_entry_id(iid[len(ENTRY_PREFIX) :])
        elif iid.startswith(RECENT_PREFIX) and iid != RECENT_PREFIX + "root":
            self._open_entry_id(iid[len(RECENT_PREFIX) :])
        elif iid.startswith(DOMAIN_PREFIX):
            self._show_domain(iid[len(DOMAIN_PREFIX) :])

    def _on_tree_activate(self, _event: tk.Event | None = None) -> None:
        """Open the selected entry in the reader."""
        self._on_tree_select()

    def _open_entry_id(self, entry_id: str) -> None:
        """Show the entry with *entry_id*."""
        if self._corpus is None:
            return
        entry = self._corpus.get(entry_id)
        if entry is not None:
            self._show_entry(entry)

    def _on_search_changed(self, *_args: Any) -> None:
        """Run the search after the last keystroke."""
        if self._search_after is not None:
            self.after_cancel(self._search_after)
        self._search_after = self.after(SEARCH_DEBOUNCE_MS, self._run_search)

    def _run_search(self) -> None:
        """Search the corpus and fill the results list."""
        self._search_after = None
        query = self._search_var.get().strip()
        results: list[SearchResult] = []
        if query and self._engine is not None:
            results = self._engine.search(
                query,
                limit=MAX_RESULTS,
                domain=self._selected_domain(),
                safety=self._selected_safety(),
            )
        self._fill_results(query, results)

    def _fill_results(self, query: str, results: Sequence[SearchResult]) -> None:
        """Show the search results in the results list."""
        self._results.delete(0, "end")
        self._result_entries = []
        if not query:
            count = len(self._corpus) if self._corpus is not None else 0
            self._results_label.configure(
                text=self._translator.t("search_placeholder", count=count)
            )
            return
        if not results:
            self._results_label.configure(text=self._translator.t("no_results"))
            self._results.insert("end", self._translator.t("no_results"))
            return
        for result in results:
            self._results.insert(
                "end", f"{result.entry.title}  —  {result.entry.domain}"
            )
            self._result_entries.append(result.entry)
        self._results_label.configure(
            text=(
                f"{self._translator.t('results')} — "
                f"{self._translator.t('result_count', count=len(results))}"
            )
        )

    def _on_result_selected(self, _event: tk.Event | None = None) -> None:
        """Open the entry of the highlighted result."""
        selection = self._results.curselection()
        if not selection:
            return
        index = int(selection[0])
        entries = self._result_entries
        if index < len(entries):
            self._show_entry(entries[index])

    def _on_result_activated(self, _event: tk.Event | None = None) -> None:
        """Open the entry of the highlighted result."""
        self._on_result_selected()

    def _on_filter_changed(self, _event: tk.Event | None = None) -> None:
        """Apply the domain and safety filters."""
        self._domain_index = max(self._domain_combo.current(), 0)
        self._safety_index = max(self._safety_combo.current(), 0)
        self._populate_tree()
        self._run_search()

    def _on_language_changed(self, _event: tk.Event | None = None) -> None:
        """Switch the language of the interface."""
        index = self._language_combo.current()
        if index < 0 or index >= len(self._language_codes):
            return
        language = self._language_codes[index]
        self._translator.set_language(language)
        self._settings.language = language
        self._apply_language()
        self._populate_filters()
        self._populate_tree()
        self._run_search()
        if self._current_entry is not None:
            self._show_entry(self._current_entry)

    def _toggle_theme(self) -> None:
        """Switch between the light and the dark theme."""
        self._settings.theme = "dark" if self._settings.theme == "light" else "light"
        self._apply_theme()
        self._apply_language()
        self._run_search()
        if self._current_entry is not None:
            self._show_entry(self._current_entry)

    def _focus_search(self, _event: tk.Event | None = None) -> str:
        """Move the focus to the search field."""
        self._search_entry.focus_set()
        self._search_entry.selection_range(0, "end")
        return "break"

    def _open_quick_jump(self, _event: tk.Event | None = None) -> str:
        """Open the quick-jump dialog."""
        if self._corpus is None:
            return "break"
        QuickJumpDialog(
            self,
            self._corpus.entries,
            self._translator,
            self._show_entry,
            self._engine,
            self._palette,
        )
        return "break"

    def _open_about(self, _event: tk.Event | None = None) -> str:
        """Open the about box."""
        version = self._corpus.version if self._corpus is not None else ""
        disclaimer = load_disclaimer(self._root_path)
        AboutDialog(self, self._translator, version, disclaimer, self._palette)
        return "break"

    def _quit(self, _event: tk.Event | None = None) -> str:
        """Close the application."""
        self._on_close()
        return "break"

    # ------------------------------------------------------------------
    # Appearance
    # ------------------------------------------------------------------
    def _apply_theme(self) -> None:
        """Apply the current palette to every widget."""
        palette = get_palette(self._settings.theme)
        self._palette = palette
        style = ttk.Style(self)
        try:
            style.theme_use("clam")
        except tk.TclError:  # pragma: no cover - defensive
            pass
        style.configure(".", background=palette.background, foreground=palette.foreground)
        style.configure("TFrame", background=palette.background)
        style.configure("Panel.TFrame", background=palette.panel)
        style.configure("TLabel", background=palette.background, foreground=palette.foreground)
        style.configure("Panel.TLabel", background=palette.panel, foreground=palette.foreground)
        style.configure("Title.TLabel", background=palette.panel, foreground=palette.accent, font=("TkDefaultFont", 13, "bold"))
        style.configure("Muted.TLabel", background=palette.panel, foreground=palette.muted, font=("TkDefaultFont", 9))
        style.configure("TButton", background=palette.panel, foreground=palette.foreground, bordercolor=palette.border)
        style.map(
            "TButton",
            background=[("active", palette.accent)],
            foreground=[("active", palette.accent_foreground)],
        )
        style.configure("TEntry", fieldbackground=palette.panel, foreground=palette.foreground, bordercolor=palette.border)
        style.configure("TCombobox", fieldbackground=palette.panel, background=palette.panel, foreground=palette.foreground, arrowcolor=palette.foreground, bordercolor=palette.border)
        style.map("TCombobox", fieldbackground=[("readonly", palette.panel)], foreground=[("readonly", palette.foreground)])
        style.configure("Treeview", background=palette.panel, fieldbackground=palette.panel, foreground=palette.foreground, bordercolor=palette.border)
        style.map(
            "Treeview",
            background=[("selected", palette.selection)],
            foreground=[("selected", palette.selection_foreground)],
        )
        style.configure("Treeview.Heading", background=palette.panel, foreground=palette.muted, relief="flat")
        style.configure("TProgressbar", background=palette.accent, troughcolor=palette.panel, bordercolor=palette.border)
        style.configure("TCheckbutton", background=palette.background, foreground=palette.foreground)

        self._results.configure(
            background=palette.panel,
            foreground=palette.foreground,
            selectbackground=palette.selection,
            selectforeground=palette.selection_foreground,
            highlightthickness=0,
            borderwidth=1,
            relief="solid",
        )
        self._renderer.configure(palette)

    def _apply_language(self) -> None:
        """Refresh every visible string after a language change."""
        translator = self._translator
        self._title_label.configure(text=translator.t("site_name"))
        self._tagline_label.configure(text=translator.t("tagline"))
        self._search_label.configure(text=translator.t("search"))
        self._domain_label.configure(text=translator.t("filter_domain"))
        self._safety_label.configure(text=translator.t("filter_safety"))
        self._language_label.configure(text=translator.t("language"))
        self._about_button.configure(text=translator.t("about"))
        self._theme_button.configure(
            text=translator.t("theme_dark") if self._settings.theme == "light" else translator.t("theme_light")
        )
        self._results_label.configure(text=translator.t("results"))
        if self._search_var.get().strip():
            self._results_label.configure(
                text=(
                    f"{translator.t('results')} — "
                    f"{translator.t('result_count', count=len(self._result_entries))}"
                )
            )
        self._tree.heading("#0", text=translator.t("domains"))
        self._tree.heading("count", text=translator.t("entries"))
        self._tree.heading("safety", text=translator.t("safety"))
        self._shortcut_label.configure(
            text=f"{translator.t('shortcut_search')}   ·   {translator.t('shortcut_jump')}   ·   "
            f"{translator.t('shortcut_about')}   ·   {translator.t('shortcut_quit')}"
        )

        languages = translator.available_languages()
        self._language_codes = list(languages)
        self._language_combo.configure(
            values=[translator.language_name(code) for code in languages]
        )
        current = translator.language
        if current in self._language_codes:
            self._language_combo.current(self._language_codes.index(current))
        self.title(f"{translator.t('app_title')} — {translator.t('site_name')}")
        self._update_status()

    def _update_status(self) -> None:
        """Refresh the status bar."""
        if self._corpus is None:
            self._set_status(self._translator.t("loading"))
            return
        source = self._translator.t("index_source_db") if self._corpus.source == "index-db" else self._translator.t("index_source_scan")
        self._set_status(
            "   ·   ".join(
                (
                    self._translator.t("entry_count", count=len(self._corpus)),
                    self._translator.t("index_source", source=source),
                    self._translator.language_name(self._translator.language),
                    self._translator.t(f"theme_{self._settings.theme}"),
                )
            )
        )

    def _set_status(self, message: str) -> None:
        """Show *message* in the status bar."""
        self._status_label.configure(text=message)

    # ------------------------------------------------------------------
    # Shutdown
    # ------------------------------------------------------------------
    def _on_close(self) -> None:
        """Save the preferences and close the window."""
        if self._poll_after is not None:
            try:
                self.after_cancel(self._poll_after)
            except tk.TclError:  # pragma: no cover - defensive
                pass
            self._poll_after = None
        if self._search_after is not None:
            try:
                self.after_cancel(self._search_after)
            except tk.TclError:  # pragma: no cover - defensive
                pass
            self._search_after = None
        try:
            self._settings.window_width = self.winfo_width()
            self._settings.window_height = self.winfo_height()
            self._settings.window_x = self.winfo_x()
            self._settings.window_y = self.winfo_y()
            self._settings.save()
        except tk.TclError:  # pragma: no cover - defensive
            LOGGER.warning("could not store the window geometry")
        self.destroy()
