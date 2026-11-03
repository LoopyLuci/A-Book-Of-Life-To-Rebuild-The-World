//! The desktop application entry point.
//!
//! Run it with:
//!
//! ```text
//! cargo run --release
//! ```
//!
//! Or verify it without a display:
//!
//! ```text
//! cargo run -- --selftest
//! ```

use std::path::PathBuf;
use std::process::ExitCode;

use abook_desktop::corpus::Corpus;
use abook_desktop::i18n::Strings;
use abook_desktop::search::{search, Filters};
use abook_desktop::settings::Settings;
use abook_desktop::ui::App;

/// The version of the app.
fn app_version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

/// The repository root: the `ABOOK_ROOT` environment variable when it is set,
/// otherwise the first ancestor of the working directory with a manifest.
fn resolve_root() -> Option<PathBuf> {
    if let Ok(root) = std::env::var("ABOOK_ROOT") {
        let path = PathBuf::from(root);
        if path.join("manifest.toml").is_file() {
            return Some(path);
        }
    }
    if let Ok(current) = std::env::current_dir() {
        if let Some(found) = abook_desktop::corpus::find_root(&current) {
            return Some(found);
        }
    }
    if let Ok(exe) = std::env::current_exe() {
        if let Some(found) = abook_desktop::corpus::find_root(&exe) {
            return Some(found);
        }
    }
    None
}

/// Loads the corpus and checks the app end to end, without a window.
fn selftest() -> ExitCode {
    println!("Book of Life desktop self-test");
    let mut failures = 0;

    let Some(root) = resolve_root() else {
        println!("  xx  the repository root was not found; set ABOOK_ROOT");
        return ExitCode::from(1);
    };
    println!("  ok  the repository root is {}", root.display());

    let corpus = match Corpus::load(&root) {
        Ok(corpus) => corpus,
        Err(error) => {
            println!("  xx  the corpus did not load: {error}");
            return ExitCode::from(1);
        }
    };
    if corpus.entries.len() > 100 {
        println!("  ok  the corpus loads ({} entries)", corpus.entries.len());
    } else {
        println!(
            "  xx  the corpus looks empty ({} entries)",
            corpus.entries.len()
        );
        failures += 1;
    }
    if corpus.domains.len() >= 16 {
        println!("  ok  the domains load ({} domains)", corpus.domains.len());
    } else {
        println!("  xx  only {} domains were found", corpus.domains.len());
        failures += 1;
    }

    let hits = search(&corpus.entries, "Making Fire", &Filters::default(), 50);
    if !hits.is_empty() && hits[0].entry.title == "Making Fire" {
        println!("  ok  a title match ranks first");
    } else {
        println!("  xx  the search did not rank the title match first");
        failures += 1;
    }

    let languages = Strings::available(&root);
    if languages.len() >= 9 {
        println!("  ok  the languages are available ({})", languages.len());
    } else {
        println!("  xx  only {} languages were found", languages.len());
        failures += 1;
    }

    let fallback = Strings::load(&root, "zz");
    if fallback.language == "en" {
        println!("  ok  an unknown language falls back to English");
    } else {
        println!("  xx  the language fallback did not work");
        failures += 1;
    }

    if corpus.disclaimer.len() > 40 {
        println!("  ok  the disclaimer is loaded");
    } else {
        println!("  xx  the disclaimer is missing");
        failures += 1;
    }

    println!();
    if failures > 0 {
        println!("{failures} check(s) failed");
        ExitCode::from(1)
    } else {
        println!("all checks passed");
        ExitCode::SUCCESS
    }
}

/// Starts the desktop application.
fn run() -> ExitCode {
    let Some(root) = resolve_root() else {
        eprintln!("Could not find the repository root.");
        eprintln!("Run the app from a checkout, or set ABOOK_ROOT to the project directory.");
        return ExitCode::from(2);
    };

    let corpus = match Corpus::load(&root) {
        Ok(corpus) => corpus,
        Err(error) => {
            eprintln!("The knowledge base could not be read: {error}");
            return ExitCode::from(2);
        }
    };

    let settings = Settings::load();
    let title = format!(
        "A Book Of Life {} — {} entries",
        app_version(),
        corpus.entries.len()
    );

    let native_options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([1100.0, 720.0])
            .with_min_inner_size([720.0, 480.0]),
        ..Default::default()
    };

    let result = eframe::run_native(
        &title,
        native_options,
        Box::new(move |_cc| Ok(Box::new(App::new(corpus, settings)))),
    );

    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("The window could not be opened: {error}");
            ExitCode::from(1)
        }
    }
}

/// The entry point.
fn main() -> ExitCode {
    let arguments: Vec<String> = std::env::args().collect();
    if arguments.iter().any(|argument| argument == "--selftest") {
        return selftest();
    }
    if arguments
        .iter()
        .any(|argument| argument == "--version" || argument == "-V")
    {
        println!("abook-desktop {}", app_version());
        return ExitCode::SUCCESS;
    }
    if arguments
        .iter()
        .any(|argument| argument == "--help" || argument == "-h")
    {
        println!("A Book Of Life — a native, offline desktop reader.");
        println!();
        println!("Usage:");
        println!("  abook-desktop            open the reader");
        println!("  abook-desktop --selftest load the corpus and check the app, then exit");
        println!("  abook-desktop --version  print the version");
        println!();
        println!("The repository root is found from the working directory, or set ABOOK_ROOT.");
        return ExitCode::SUCCESS;
    }
    run()
}
