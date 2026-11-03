//! The desktop interface, built with egui.
//!
//! The whole interface is Rust. There is no web view, no embedded HTML and
//! no JavaScript: the app is a native window that draws its own widgets.

use egui::{Align, Color32, Frame, Layout, RichText, Stroke, TextEdit, Vec2, Visuals};

use crate::corpus::Corpus;
use crate::i18n::Strings;
use crate::search::{search, Filters, Hit};
use crate::settings::Settings;

/// The `eframe` entry point, so the window draws the interface every frame.
impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.ui(ctx);
    }
}

/// The colour palette, in the light and the dark theme.
#[derive(Debug, Clone, Copy)]
pub struct Palette {
    /// The page background.
    #[allow(dead_code)]
    pub background: Color32,
    /// The panel background.
    pub panel: Color32,
    /// The main text.
    pub text: Color32,
    /// The dimmed text.
    pub muted: Color32,
    /// The accent used for the selection and the highlights.
    pub accent: Color32,
    /// The colour used for a green safety level.
    pub safe: Color32,
    /// The colour used for a yellow safety level.
    pub caution: Color32,
    /// The colour used for a red safety level.
    pub danger: Color32,
    /// The border colour.
    #[allow(dead_code)]
    pub border: Color32,
}

impl Palette {
    /// The dark theme.
    pub const DARK: Palette = Palette {
        background: Color32::from_rgb(24, 26, 24),
        panel: Color32::from_rgb(32, 35, 32),
        text: Color32::from_rgb(232, 235, 232),
        muted: Color32::from_rgb(150, 156, 150),
        accent: Color32::from_rgb(126, 200, 160),
        safe: Color32::from_rgb(140, 200, 140),
        caution: Color32::from_rgb(220, 190, 110),
        danger: Color32::from_rgb(220, 130, 120),
        border: Color32::from_rgb(60, 66, 60),
    };

    /// The light theme.
    pub const LIGHT: Palette = Palette {
        background: Color32::from_rgb(250, 248, 242),
        panel: Color32::from_rgb(242, 239, 231),
        text: Color32::from_rgb(35, 38, 35),
        muted: Color32::from_rgb(120, 126, 120),
        accent: Color32::from_rgb(40, 120, 80),
        safe: Color32::from_rgb(50, 130, 50),
        caution: Color32::from_rgb(160, 120, 20),
        danger: Color32::from_rgb(170, 50, 40),
        border: Color32::from_rgb(200, 196, 186),
    };

    /// The colour for a safety level.
    pub fn safety(&self, level: &str) -> Color32 {
        match level {
            "green" => self.safe,
            "yellow" => self.caution,
            "red" => self.danger,
            _ => self.muted,
        }
    }
}

/// The state of the application.
pub struct App {
    /// The corpus.
    pub corpus: Corpus,
    /// The interface strings.
    pub strings: Strings,
    /// The reader's settings.
    pub settings: Settings,
    /// The search text.
    pub query: String,
    /// The filters.
    pub filters: Filters,
    /// The index of the selected entry.
    pub selected: usize,
    /// The entry whose full text is being read, if any.
    pub open_entry: Option<usize>,
    /// Whether the about window is open.
    pub about_open: bool,
    /// Whether the quick jump window is open.
    pub jump_open: bool,
    /// The quick jump text.
    pub jump_text: String,
    /// A transient message shown in the status bar.
    pub message: String,
    /// The corpus is still loading.
    #[allow(dead_code)]
    pub loading: bool,
}

impl App {
    /// Creates the application state.
    pub fn new(corpus: Corpus, settings: Settings) -> Self {
        let strings = Strings::load(&corpus.root, &settings.language);
        Self {
            corpus,
            strings,
            settings,
            query: String::new(),
            filters: Filters::default(),
            selected: 0,
            open_entry: None,
            about_open: false,
            jump_open: false,
            jump_text: String::new(),
            message: String::new(),
            loading: false,
        }
    }

    /// The palette for the current theme.
    fn palette(&self) -> Palette {
        if self.settings.theme == "light" {
            Palette::LIGHT
        } else {
            Palette::DARK
        }
    }

    /// The entries the reader is looking at.
    fn visible(&self) -> Vec<Hit> {
        if self.query.trim().is_empty() {
            self.corpus
                .entries
                .iter()
                .enumerate()
                .filter(|(_, entry)| self.filters.accepts(entry))
                .map(|(index, entry)| Hit {
                    index,
                    entry: entry.clone(),
                    score: 0.0,
                })
                .collect()
        } else {
            search(&self.corpus.entries, &self.query, &self.filters, 200)
        }
    }

    /// Draws the interface.
    pub fn ui(&mut self, ctx: &egui::Context) {
        let palette = self.palette();
        ctx.set_visuals(match self.settings.theme.as_str() {
            "light" => Visuals::light(),
            _ => Visuals::dark(),
        });
        ctx.style_mut(|style| {
            style.spacing.item_spacing = Vec2::new(8.0, 6.0);
            style.visuals.widgets.noninteractive.bg_fill = palette.panel;
            style.visuals.widgets.noninteractive.weak_bg_fill = palette.panel;
            style.visuals.widgets.inactive.bg_fill = palette.panel;
            style.visuals.widgets.inactive.weak_bg_fill = palette.panel;
        });

        egui::TopBottomPanel::top("header")
            .frame(
                Frame::none()
                    .fill(palette.panel)
                    .inner_margin(egui::Margin::symmetric(12.0, 8.0)),
            )
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    ui.label(
                        RichText::new("A Book Of Life")
                            .strong()
                            .size(18.0)
                            .color(palette.text),
                    );
                    ui.label(
                        RichText::new(format!("v{}", self.corpus.version))
                            .small()
                            .color(palette.muted),
                    );
                    ui.separator();
                    ui.label(
                        RichText::new(format!("{} entries", self.corpus.entries.len()))
                            .small()
                            .color(palette.muted),
                    );
                });
            });

        egui::TopBottomPanel::bottom("status").show(ctx, |ui| {
            ui.horizontal(|ui| {
                if !self.message.is_empty() {
                    ui.label(RichText::new(&self.message).small().color(palette.caution));
                }
                ui.with_layout(Layout::right_to_left(Align::RIGHT), |ui| {
                    ui.label(
                        RichText::new("Ctrl+F search   F1 about   Ctrl+Q quit")
                            .small()
                            .color(palette.muted),
                    );
                });
            });
        });

        egui::SidePanel::left("domains")
            .resizable(true)
            .default_width(220.0)
            .frame(
                Frame::none()
                    .fill(palette.panel)
                    .inner_margin(egui::Margin::symmetric(8.0, 8.0)),
            )
            .show(ctx, |ui| {
                ui.label(
                    RichText::new(self.strings.get("domains"))
                        .strong()
                        .color(palette.accent),
                );
                ui.separator();

                let all = ui.selectable_label(
                    self.filters.domain.is_none(),
                    format!(
                        "{} ({})",
                        self.strings.get("all_domains"),
                        self.corpus.entries.len()
                    ),
                );
                if all.clicked() {
                    self.filters.domain = None;
                }

                for domain in &self.corpus.domains {
                    let selected = self.filters.domain.as_deref() == Some(domain.slug.as_str());
                    if ui
                        .selectable_label(selected, format!("{}  {}", domain.slug, domain.count))
                        .clicked()
                    {
                        self.filters.domain = if selected {
                            None
                        } else {
                            Some(domain.slug.clone())
                        };
                    }
                }

                ui.separator();
                ui.label(
                    RichText::new(self.strings.get("recently_read"))
                        .strong()
                        .color(palette.accent),
                );
                let recent = self.settings.recent.clone();
                let mut chosen: Option<usize> = None;
                for key in recent.iter().rev().take(10) {
                    let found =
                        self.corpus.entries.iter().position(|e| {
                            e.id == *key || format!("{}/{}", e.domain, e.title) == *key
                        });
                    if let Some(index) = found {
                        let title = self.corpus.entries[index].title.clone();
                        if ui
                            .button(RichText::new(title).small().color(palette.text))
                            .clicked()
                        {
                            chosen = Some(index);
                        }
                    }
                }
                if let Some(index) = chosen {
                    let entry = self.corpus.entries[index].clone();
                    self.open_entry(&entry);
                }
            });

        egui::CentralPanel::default().show(ctx, |ui| {
            if let Some(index) = self.open_entry {
                self.show_entry(ui, index, &palette);
                return;
            }
            ui.horizontal(|ui| {
                ui.label(RichText::new(self.strings.get("search")).color(palette.muted));
                let response = ui.add(
                    TextEdit::singleline(&mut self.query)
                        .hint_text("solar, fire, water…")
                        .desired_width(f32::INFINITY),
                );
                if response.changed() {
                    self.selected = 0;
                }
                if response.lost_focus() && ui.input(|i| i.key_pressed(egui::Key::Enter)) {
                    self.selected = 0;
                }
            });

            ui.horizontal(|ui| {
                ui.label(RichText::new(self.strings.get("safety")).color(palette.muted));
                for level in ["green", "yellow", "red"] {
                    let selected = self.filters.safety.as_deref() == Some(level);
                    let text = RichText::new(level).color(palette.safety(level));
                    if ui.selectable_label(selected, text).clicked() {
                        self.filters.safety = if selected {
                            None
                        } else {
                            Some(level.to_string())
                        };
                        self.selected = 0;
                    }
                }
                ui.separator();
                ui.label(RichText::new(self.strings.get("difficulty")).color(palette.muted));
                for level in ["novice", "apprentice", "journeyman", "master"] {
                    let selected = self.filters.difficulty.as_deref() == Some(level);
                    if ui.selectable_label(selected, level).clicked() {
                        self.filters.difficulty = if selected {
                            None
                        } else {
                            Some(level.to_string())
                        };
                        self.selected = 0;
                    }
                }
                ui.separator();
                if ui
                    .button(RichText::new("Theme").color(palette.text))
                    .clicked()
                {
                    self.settings.theme = if self.settings.theme == "dark" {
                        "light".to_string()
                    } else {
                        "dark".to_string()
                    };
                    let _ = self.settings.save();
                }
                if ui
                    .button(RichText::new("Language").color(palette.text))
                    .clicked()
                {
                    let languages = Strings::available(&self.corpus.root);
                    let index = languages
                        .iter()
                        .position(|l| l == &self.settings.language)
                        .unwrap_or(0);
                    let next = (index + 1) % languages.len();
                    self.settings.language = languages[next].clone();
                    self.strings = Strings::load(&self.corpus.root, &self.settings.language);
                    let _ = self.settings.save();
                    self.message = format!("language: {}", self.settings.language);
                }
                if ui
                    .button(RichText::new("About").color(palette.text))
                    .clicked()
                {
                    self.about_open = true;
                }
            });

            ui.separator();

            let hits = self.visible();
            if hits.is_empty() {
                ui.label(RichText::new(self.strings.get("no_results")).color(palette.muted));
            }

            let mut open: Option<usize> = None;
            let mut selected = self.selected;

            egui::ScrollArea::vertical().show(ui, |ui| {
                for (position, hit) in hits.iter().enumerate() {
                    let entry = &hit.entry;
                    let is_selected = position == selected;
                    let frame = Frame::none()
                        .fill(if is_selected {
                            palette.accent.gamma_multiply(0.18)
                        } else {
                            Color32::TRANSPARENT
                        })
                        .inner_margin(egui::Margin::symmetric(6.0, 4.0))
                        .stroke(Stroke::NONE);

                    frame.show(ui, |ui| {
                        ui.horizontal(|ui| {
                            let response = ui.selectable_label(
                                false,
                                RichText::new(&entry.title).color(palette.text).strong(),
                            );
                            if response.clicked() {
                                selected = position;
                                open = Some(hit.index);
                            }
                            if response.double_clicked() {
                                selected = position;
                                open = Some(hit.index);
                            }
                            ui.with_layout(Layout::right_to_left(Align::RIGHT), |ui| {
                                ui.label(RichText::new(&entry.domain).small().color(palette.muted));
                                let safety = RichText::new(&entry.safety)
                                    .small()
                                    .strong()
                                    .color(palette.safety(&entry.safety));
                                ui.label(safety);
                            });
                        });
                        if !self.query.trim().is_empty() {
                            let text = crate::search::snippet(&entry.body, &self.query, 110);
                            ui.label(RichText::new(text).small().color(palette.muted));
                        }
                    });
                }
            });

            self.selected = selected;
            if let Some(index) = open {
                let entry = self.corpus.entries[index].clone();
                self.open_entry(&entry);
            }
        });
        if self.about_open {
            self.show_about(ctx);
        }
        if self.jump_open {
            self.show_jump(ctx);
        }
    }

    /// Shows the full text of one entry, with its metadata and its sources.
    fn show_entry(&mut self, ui: &mut egui::Ui, index: usize, palette: &Palette) {
        let Some(entry) = self.corpus.entries.get(index).cloned() else {
            self.open_entry = None;
            return;
        };

        ui.horizontal(|ui| {
            if ui
                .button(RichText::new("← Back").color(palette.accent))
                .clicked()
            {
                self.open_entry = None;
            }
            ui.label(
                RichText::new(&entry.title)
                    .strong()
                    .size(20.0)
                    .color(palette.text),
            );
        });
        ui.separator();

        ui.horizontal(|ui| {
            ui.label(
                RichText::new(format!(
                    "{} · {} · {} · {}",
                    entry.domain, entry.difficulty, entry.safety, entry.time_to_complete
                ))
                .small()
                .color(palette.muted),
            );
            ui.label(
                RichText::new(format!(
                    "{}: {}",
                    self.strings.get("verification"),
                    if entry.verification.status.is_empty() {
                        "draft"
                    } else {
                        &entry.verification.status
                    }
                ))
                .small()
                .color(palette.muted),
            );
            if !entry.tags.is_empty() {
                ui.label(
                    RichText::new(entry.tags.join(" · "))
                        .small()
                        .color(palette.accent),
                );
            }
        });
        ui.separator();

        egui::ScrollArea::vertical().show(ui, |ui| {
            for line in entry.body.lines() {
                let trimmed = line.trim_start();
                if trimmed.starts_with('#') {
                    let level = trimmed.chars().take_while(|c| *c == '#').count();
                    let text = trimmed.trim_start_matches('#').trim();
                    let size = match level {
                        1 => 22.0,
                        2 => 18.0,
                        3 => 16.0,
                        _ => 14.0,
                    };
                    ui.add_space(4.0);
                    ui.label(RichText::new(text).strong().size(size).color(palette.text));
                } else if trimmed.starts_with("- ") || trimmed.starts_with("* ") {
                    ui.horizontal(|ui| {
                        ui.label(RichText::new("•").color(palette.accent));
                        ui.label(RichText::new(trimmed[2..].trim()).color(palette.text));
                    });
                } else if let Some(number) = trimmed.split_once(". ").filter(|(head, _)| {
                    head.chars().all(|c| c.is_ascii_digit()) && !head.is_empty()
                }) {
                    ui.horizontal(|ui| {
                        ui.label(RichText::new(format!("{}.", number.0)).color(palette.accent));
                        ui.label(RichText::new(number.1.trim()).color(palette.text));
                    });
                } else if trimmed.starts_with('>') {
                    ui.label(
                        RichText::new(trimmed.trim_start_matches('>').trim())
                            .small()
                            .color(palette.caution),
                    );
                } else if trimmed.is_empty() {
                    ui.add_space(4.0);
                } else {
                    ui.label(RichText::new(line.trim()).color(palette.text));
                }
            }

            if !entry.sources.is_empty() {
                ui.separator();
                ui.label(
                    RichText::new(self.strings.get("sources"))
                        .strong()
                        .color(palette.accent),
                );
                for source in &entry.sources {
                    let mut line = source.title.clone();
                    if !source.author.is_empty() {
                        line.push_str(&format!(" — {}", source.author));
                    }
                    if !source.year.is_empty() {
                        line.push_str(&format!(" ({})", source.year));
                    }
                    if !source.license.is_empty() {
                        line.push_str(&format!(" [{}]", source.license));
                    }
                    ui.label(RichText::new(line).small().color(palette.muted));
                }
            }
        });
    }

    /// Marks an entry as read and opens it.
    fn open_entry(&mut self, entry: &crate::corpus::Entry) {
        self.settings.push_recent(entry.id.clone(), 20);
        let _ = self.settings.save();
        if let Some(position) = self
            .visible()
            .iter()
            .position(|hit| hit.entry.id == entry.id)
        {
            self.selected = position;
        }
        self.open_entry = self
            .corpus
            .entries
            .iter()
            .position(|candidate| candidate.id == entry.id);
        self.message = format!("opened: {}", entry.title);
    }

    /// The about window, with the disclaimer.
    fn show_about(&mut self, ctx: &egui::Context) {
        let palette = self.palette();
        let mut open = true;
        egui::Window::new("About")
            .open(&mut open)
            .resizable(false)
            .anchor(
                egui::Align2([egui::Align::Center, egui::Align::Center]),
                egui::Vec2::ZERO,
            )
            .show(ctx, |ui| {
                ui.label(
                    RichText::new("A Book Of Life")
                        .strong()
                        .size(16.0)
                        .color(palette.text),
                );
                ui.label(
                    RichText::new(format!("version {}", self.corpus.version))
                        .small()
                        .color(palette.muted),
                );
                ui.separator();
                ui.label(
                    RichText::new("Reference material")
                        .strong()
                        .color(palette.caution),
                );
                ui.label(RichText::new(&self.corpus.disclaimer).color(palette.text));
                ui.separator();
                ui.label(
                    RichText::new("The knowledge base is provided as is, with no warranty.")
                        .small()
                        .color(palette.muted),
                );
                if ui.button("Close").clicked() {
                    self.about_open = false;
                }
            });
        if !open {
            self.about_open = false;
        }
    }

    /// The quick jump window.
    fn show_jump(&mut self, ctx: &egui::Context) {
        let palette = self.palette();
        let mut open = true;
        let mut chosen: Option<usize> = None;
        egui::Window::new("Quick jump")
            .open(&mut open)
            .resizable(false)
            .anchor(
                egui::Align2([egui::Align::Center, egui::Align::Center]),
                egui::Vec2::ZERO,
            )
            .show(ctx, |ui| {
                ui.add(TextEdit::singleline(&mut self.jump_text).hint_text("entry name…"));
                egui::ScrollArea::vertical()
                    .max_height(280.0)
                    .show(ui, |ui| {
                        let needle = self.jump_text.trim().to_lowercase();
                        for (index, entry) in self.corpus.entries.iter().enumerate() {
                            if !needle.is_empty()
                                && !entry.title.to_lowercase().contains(&needle)
                                && !entry.domain.to_lowercase().contains(&needle)
                            {
                                continue;
                            }
                            if ui
                                .button(RichText::new(&entry.title).color(palette.text))
                                .clicked()
                            {
                                chosen = Some(index);
                            }
                        }
                    });
            });
        if let Some(index) = chosen {
            let entry = self.corpus.entries[index].clone();
            self.open_entry(&entry);
            self.jump_open = false;
        }
        if !open {
            self.jump_open = false;
        }
    }
}
