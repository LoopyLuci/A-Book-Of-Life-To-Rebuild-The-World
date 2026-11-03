//! The interface strings, read from `i18n/strings/<lang>.yaml`.
//!
//! The app ships in nine languages. When a catalogue is missing, or a key is
//! missing from it, the English catalogue is used, and when that fails too
//! the key itself is shown, so the interface never goes blank.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

/// The English strings, which every other catalogue is measured against.
const FALLBACK: &[(&str, &str)] = &[
    ("search", "Search"),
    ("domains", "Domains"),
    ("entries", "Entries"),
    ("difficulty", "Difficulty"),
    ("safety", "Safety"),
    ("time_to_complete", "Time to complete"),
    ("prerequisites", "Prerequisites"),
    ("materials", "Materials & Tools"),
    ("procedure", "Procedure"),
    ("safety_notes", "Safety Notes"),
    ("verification", "Verification"),
    ("sources", "Sources"),
    ("recently_read", "Recently read"),
    ("about", "About"),
    ("close", "Close"),
    ("no_results", "Nothing found"),
    ("all_domains", "All domains"),
    ("all_safety", "Any safety"),
    ("all_levels", "Any level"),
];

/// A catalogue of interface strings.
#[derive(Debug, Default, Clone)]
pub struct Strings {
    /// The language code, for example `en`.
    pub language: String,
    /// The strings, keyed by their canonical name.
    pub values: BTreeMap<String, String>,
}

impl Strings {
    /// Reads the catalogue for a language, falling back to English.
    pub fn load(root: &Path, language: &str) -> Self {
        let mut values: BTreeMap<String, String> = FALLBACK
            .iter()
            .map(|(k, v)| (k.to_string(), v.to_string()))
            .collect();

        for candidate in [language, "en"] {
            if candidate.is_empty() {
                continue;
            }
            let path = root
                .join("i18n")
                .join("strings")
                .join(format!("{candidate}.yaml"));
            if let Ok(raw) = fs::read_to_string(&path) {
                if let Ok(parsed) =
                    serde_yaml::from_str::<BTreeMap<String, serde_yaml::Value>>(&raw)
                {
                    for (key, value) in parsed {
                        if let Some(text) = scalar_to_string(&value) {
                            values.insert(key, text);
                        }
                    }
                    return Self {
                        language: candidate.to_string(),
                        values,
                    };
                }
            }
        }

        Self {
            language: "en".to_string(),
            values,
        }
    }

    /// The languages that have a catalogue.
    pub fn available(root: &Path) -> Vec<String> {
        let mut languages = Vec::new();
        if let Ok(dir) = fs::read_dir(root.join("i18n").join("strings")) {
            for entry in dir.flatten() {
                let path = entry.path();
                if path.extension().and_then(|e| e.to_str()) != Some("yaml") {
                    continue;
                }
                if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
                    languages.push(stem.to_string());
                }
            }
        }
        languages.sort();
        if languages.is_empty() {
            languages.push("en".to_string());
        }
        languages
    }

    /// A string, falling back to English and then to the key.
    pub fn get<'a>(&'a self, key: &'a str) -> &'a str {
        self.values.get(key).map(String::as_str).unwrap_or(key)
    }
}

/// Turns a YAML scalar into text.
fn scalar_to_string(value: &serde_yaml::Value) -> Option<String> {
    match value {
        serde_yaml::Value::String(text) => Some(text.clone()),
        serde_yaml::Value::Number(number) => Some(number.to_string()),
        serde_yaml::Value::Bool(flag) => Some(flag.to_string()),
        _ => None,
    }
}

/// The path of the settings file.
#[allow(dead_code)]
pub fn settings_path() -> PathBuf {
    let base = if let Ok(appdata) = std::env::var("APPDATA") {
        PathBuf::from(appdata)
    } else if let Ok(home) = std::env::var("HOME") {
        PathBuf::from(home).join(".config")
    } else {
        std::env::temp_dir()
    };
    base.join("abook").join("settings.json")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_missing_catalogue_falls_back_to_english() {
        let strings = Strings::load(Path::new("/nonexistent"), "zz");
        assert_eq!(strings.language, "en");
        assert_eq!(strings.get("domains"), "Domains");
    }

    #[test]
    fn an_unknown_key_returns_itself() {
        let strings = Strings::load(Path::new("/nonexistent"), "en");
        assert_eq!(strings.get("not_a_real_key"), "not_a_real_key");
    }
}
