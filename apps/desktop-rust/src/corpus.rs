//! Corpus loading for the Book of Life desktop app.
//!
//! The corpus is the repository's own content: one Markdown file and one
//! YAML sidecar per entry. Nothing is fetched, and the app works with no
//! network at all.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use serde::Deserialize;

/// A single knowledge entry, read from a sidecar and its Markdown body.
#[derive(Debug, Clone, Deserialize)]
pub struct Entry {
    /// The stable identifier, for example `pnk:01ABC/energy/solar-pv`.
    #[serde(default)]
    pub id: String,
    /// The English title.
    pub title: String,
    /// The domain the entry belongs to.
    pub domain: String,
    /// The tags, used for search and for the entry view.
    #[serde(default)]
    pub tags: Vec<String>,
    /// `novice`, `apprentice`, `journeyman` or `master`.
    #[serde(default = "default_difficulty")]
    pub difficulty: String,
    /// `green`, `yellow` or `red`.
    #[serde(default = "default_safety")]
    pub safety: String,
    /// How long the procedure takes.
    #[serde(default)]
    pub time_to_complete: String,
    /// The verification lifecycle status.
    #[serde(default)]
    pub verification: Verification,
    /// The cited sources.
    #[serde(default)]
    pub sources: Vec<Source>,
    /// The Markdown body.
    #[serde(skip)]
    pub body: String,
}

fn default_difficulty() -> String {
    "novice".to_string()
}

fn default_safety() -> String {
    "green".to_string()
}

/// The verification state of an entry.
#[derive(Debug, Clone, Default, Deserialize)]
pub struct Verification {
    /// `draft`, `peer-reviewed`, `field-tested` or `deprecated`.
    #[serde(default)]
    pub status: String,
}

/// A cited source.
#[derive(Debug, Clone, Deserialize)]
pub struct Source {
    /// The title of the source.
    #[serde(default)]
    pub title: String,
    /// The author, when known.
    #[serde(default)]
    pub author: String,
    /// The year, when known.
    #[serde(default)]
    pub year: String,
    /// The licence.
    #[serde(default)]
    pub license: String,
}

/// A domain and how many entries it holds.
#[derive(Debug, Clone)]
pub struct Domain {
    /// The domain slug, for example `energy`.
    pub slug: String,
    /// The number of entries in the domain.
    pub count: usize,
}

/// The whole corpus, held in memory.
#[derive(Debug, Default)]
pub struct Corpus {
    /// The repository root the corpus was read from.
    pub root: PathBuf,
    /// Every entry, sorted by domain and then by title.
    pub entries: Vec<Entry>,
    /// The domains, in the order the manifest lists them.
    pub domains: Vec<Domain>,
    /// The project version, read from the manifest.
    pub version: String,
    /// The disclaimer, quoted from `docs/DISCLAIMER.md`.
    pub disclaimer: String,
}

impl Corpus {
    /// Reads the corpus from the repository root.
    pub fn load(root: &Path) -> Result<Self, String> {
        let version = read_version(root);
        let disclaimer = read_disclaimer(root);
        let mut entries: Vec<Entry> = Vec::new();

        let sidecars = root.join("sidecars");
        let sidecar_dir = fs::read_dir(&sidecars).map_err(|e| format!("sidecars: {e}"))?;
        let mut domain_names: Vec<String> = Vec::new();

        for domain_entry in sidecar_dir.flatten() {
            if !domain_entry.path().is_dir() {
                continue;
            }
            let domain = domain_entry.file_name().to_string_lossy().to_string();
            domain_names.push(domain.clone());

            let files = match fs::read_dir(domain_entry.path()) {
                Ok(files) => files,
                Err(_) => continue,
            };
            for file in files.flatten() {
                let path = file.path();
                if path.extension().and_then(|e| e.to_str()) != Some("yaml") {
                    continue;
                }
                let slug = path
                    .file_stem()
                    .and_then(|s| s.to_str())
                    .unwrap_or_default()
                    .trim_end_matches(".pnk")
                    .to_string();

                let raw = match fs::read_to_string(&path) {
                    Ok(raw) => raw,
                    Err(_) => continue,
                };
                let mut entry: Entry = match serde_yaml::from_str(&raw) {
                    Ok(entry) => entry,
                    // A malformed sidecar is skipped, not fatal.
                    Err(_) => continue,
                };

                let body_path = root
                    .join("domains")
                    .join(&domain)
                    .join(format!("{slug}.md"));
                entry.body = fs::read_to_string(&body_path).unwrap_or_default();
                entries.push(entry);
            }
        }

        entries.sort_by(|a, b| a.domain.cmp(&b.domain).then(a.title.cmp(&b.title)));

        // Keep the manifest order when the manifest is available.
        let manifest_order = read_manifest_domains(root);
        let mut counts: BTreeMap<String, usize> = BTreeMap::new();
        for entry in &entries {
            *counts.entry(entry.domain.clone()).or_insert(0) += 1;
        }
        let mut domains: Vec<Domain> = Vec::new();
        for slug in &manifest_order {
            if let Some(count) = counts.get(slug) {
                domains.push(Domain {
                    slug: slug.clone(),
                    count: *count,
                });
            }
        }
        for slug in &domain_names {
            if !manifest_order.contains(slug) {
                if let Some(count) = counts.get(slug) {
                    domains.push(Domain {
                        slug: slug.clone(),
                        count: *count,
                    });
                }
            }
        }

        Ok(Self {
            root: root.to_path_buf(),
            entries,
            domains,
            version,
            disclaimer,
        })
    }

    /// The entries in one domain.
    #[allow(dead_code)]
    pub fn in_domain(&self, domain: &str) -> Vec<&Entry> {
        self.entries
            .iter()
            .filter(|entry| entry.domain == domain)
            .collect()
    }
}

/// Walks up from `start` until a directory with a `manifest.toml` is found.
pub fn find_root(start: &Path) -> Option<PathBuf> {
    let mut current = start.to_path_buf();
    for _ in 0..12 {
        if current.join("manifest.toml").is_file() {
            return Some(current);
        }
        if !current.pop() {
            break;
        }
    }
    None
}

/// Reads the project version from the manifest.
pub fn read_version(root: &Path) -> String {
    let raw = match fs::read_to_string(root.join("manifest.toml")) {
        Ok(raw) => raw,
        Err(_) => return "unknown".to_string(),
    };
    for line in raw.lines() {
        let trimmed = line.trim();
        if let Some(rest) = trimmed.strip_prefix("version") {
            if let Some(value) = rest.split('=').nth(1) {
                return value.trim().trim_matches('"').to_string();
            }
        }
    }
    "unknown".to_string()
}

/// Reads the domain list from the manifest.
pub fn read_manifest_domains(root: &Path) -> Vec<String> {
    let raw = match fs::read_to_string(root.join("manifest.toml")) {
        Ok(raw) => raw,
        Err(_) => return Vec::new(),
    };
    let mut domains = Vec::new();
    let mut in_list = false;
    for line in raw.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("list") && trimmed.contains('[') {
            in_list = true;
            continue;
        }
        if in_list {
            if trimmed.starts_with(']') {
                break;
            }
            if let Some(start) = trimmed.find('"') {
                if let Some(end) = trimmed[start + 1..].find('"') {
                    domains.push(trimmed[start + 1..start + 1 + end].to_string());
                }
            }
        }
    }
    domains
}

/// Quotes the disclaimer summary from `docs/DISCLAIMER.md`.
pub fn read_disclaimer(root: &Path) -> String {
    let path = root.join("docs").join("DISCLAIMER.md");
    let raw = match fs::read_to_string(&path) {
        Ok(raw) => raw,
        Err(_) => return "Reference material only. Verify before acting.".to_string(),
    };
    let mut collecting = false;
    let mut parts: Vec<String> = Vec::new();
    for line in raw.lines() {
        if line.starts_with("## 12.") {
            collecting = true;
            continue;
        }
        if collecting && line.starts_with("## ") {
            break;
        }
        if collecting && !line.trim().is_empty() {
            parts.push(line.trim().to_string());
        }
    }
    if parts.is_empty() {
        "Reference material only. Verify before acting.".to_string()
    } else {
        parts.join(" ")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_corpus(name: &str) -> PathBuf {
        let base =
            std::env::temp_dir().join(format!("abook-rust-test-{name}-{}", std::process::id()));
        let domain = base.join("sidecars").join("demo");
        std::fs::create_dir_all(&domain).unwrap();
        std::fs::create_dir_all(base.join("domains").join("demo")).unwrap();
        std::fs::write(
            base.join("manifest.toml"),
            "[project]\nversion = \"1.2.3\"\n\n[domains]\nlist = [\n  \"demo\",\n]\n",
        )
        .unwrap();
        std::fs::write(
            domain.join("alpha.pnk.yaml"),
            "id: pnk:01ABC/demo/alpha\ntitle: Alpha\ndomain: demo\ntags: [one, two]\ndifficulty: novice\nsafety: green\nverification:\n  status: draft\nsources:\n  - title: A Manual\n    license: public-domain\n",
        )
        .unwrap();
        std::fs::write(
            base.join("domains").join("demo").join("alpha.md"),
            "# Alpha\n\n## Overview\n\nA body.\n",
        )
        .unwrap();
        base
    }

    #[test]
    fn reads_the_version_and_the_domains() {
        let base = temp_corpus("version");
        assert_eq!(read_version(&base), "1.2.3");
        assert_eq!(read_manifest_domains(&base), vec!["demo".to_string()]);
        let _ = std::fs::remove_dir_all(&base);
    }

    #[test]
    fn loads_entries_with_their_bodies() {
        let base = temp_corpus("load");
        let corpus = Corpus::load(&base).expect("the corpus loads");
        assert_eq!(corpus.entries.len(), 1);
        assert_eq!(corpus.entries[0].title, "Alpha");
        assert!(corpus.entries[0].body.contains("Overview"));
        assert_eq!(corpus.domains.len(), 1);
        assert_eq!(corpus.domains[0].count, 1);
        let _ = std::fs::remove_dir_all(&base);
    }

    #[test]
    fn skips_a_malformed_sidecar_without_failing() {
        let base = temp_corpus("broken");
        std::fs::write(
            base.join("sidecars").join("demo").join("broken.pnk.yaml"),
            "title: [unclosed\n",
        )
        .unwrap();
        let corpus = Corpus::load(&base).expect("the corpus still loads");
        assert_eq!(corpus.entries.len(), 1);
        let _ = std::fs::remove_dir_all(&base);
    }
}
