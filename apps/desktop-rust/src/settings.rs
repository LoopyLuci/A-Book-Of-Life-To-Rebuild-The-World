//! The reader's preferences, kept in a small JSON-free settings file.
//!
//! The format is a plain `key = value` text file so that it can be read and
//! written without a JSON dependency, and so that a reader can edit it.

use std::fs;
use std::path::PathBuf;

/// The reader's settings.
#[derive(Debug, Clone)]
pub struct Settings {
    /// The interface language.
    pub language: String,
    /// `dark` or `light`.
    pub theme: String,
    /// The most recently read entries, newest last.
    pub recent: Vec<String>,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            language: "en".to_string(),
            theme: "dark".to_string(),
            recent: Vec::new(),
        }
    }
}

impl Settings {
    /// Reads the settings, filling in the defaults.
    pub fn load() -> Self {
        let mut settings = Settings::default();
        let path = settings_path();
        let raw = match fs::read_to_string(&path) {
            Ok(raw) => raw,
            Err(_) => return settings,
        };
        for line in raw.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            let Some((key, value)) = line.split_once('=') else {
                continue;
            };
            let key = key.trim();
            let value = value.trim().trim_matches('"').to_string();
            match key {
                "language" => settings.language = value,
                "theme" => settings.theme = value,
                "recent" => {
                    settings.recent = value
                        .split(',')
                        .map(str::trim)
                        .filter(|item| !item.is_empty())
                        .map(str::to_string)
                        .collect()
                }
                _ => {}
            }
        }
        settings
    }

    /// Writes the settings.
    pub fn save(&self) -> Result<(), String> {
        let path = settings_path();
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(|e| format!("{}: {e}", parent.display()))?;
        }
        let body = format!(
            "language = \"{}\"\ntheme = \"{}\"\nrecent = \"{}\"\n",
            self.language,
            self.theme,
            self.recent.join(",")
        );
        fs::write(&path, body).map_err(|e| format!("{}: {e}", path.display()))
    }

    /// Records an entry as recently read.
    pub fn push_recent(&mut self, key: String, limit: usize) {
        self.recent.retain(|item| item != &key);
        self.recent.push(key);
        if self.recent.len() > limit {
            let excess = self.recent.len() - limit;
            self.recent.drain(0..excess);
        }
    }
}

/// The path of the settings file.
pub fn settings_path() -> PathBuf {
    if let Ok(appdata) = std::env::var("APPDATA") {
        return PathBuf::from(appdata).join("abook").join("settings.txt");
    }
    if let Ok(home) = std::env::var("HOME") {
        return PathBuf::from(home)
            .join(".config")
            .join("abook")
            .join("settings.txt");
    }
    std::env::temp_dir().join("abook-settings.txt")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_defaults_are_sensible() {
        let settings = Settings::default();
        assert_eq!(settings.language, "en");
        assert_eq!(settings.theme, "dark");
        assert!(settings.recent.is_empty());
    }

    #[test]
    fn the_recent_list_keeps_the_newest_and_drops_the_oldest() {
        let mut settings = Settings::default();
        settings.push_recent("a".to_string(), 3);
        settings.push_recent("b".to_string(), 3);
        settings.push_recent("c".to_string(), 3);
        settings.push_recent("d".to_string(), 3);
        assert_eq!(settings.recent, vec!["b", "c", "d"]);
    }

    #[test]
    fn the_recent_list_does_not_repeat_an_entry() {
        let mut settings = Settings::default();
        settings.push_recent("a".to_string(), 5);
        settings.push_recent("a".to_string(), 5);
        assert_eq!(settings.recent, vec!["a"]);
    }
}
