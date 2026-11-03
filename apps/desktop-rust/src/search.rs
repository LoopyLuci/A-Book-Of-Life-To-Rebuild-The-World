//! Search over the corpus.
//!
//! A title match ranks above a tag match, which ranks above a body match.
//! The scoring is deliberately simple and explainable: a reader who searches
//! for "solar" should see the entry called "Solar Photovoltaic Systems"
//! before an entry that merely mentions solar in its body.

use crate::corpus::Entry;

/// One search result.
#[derive(Debug, Clone)]
pub struct Hit {
    /// The index of the entry in the corpus.
    pub index: usize,
    /// The entry itself.
    pub entry: Entry,
    /// The score. Higher is better.
    pub score: f32,
}

/// The filters a reader can apply.
#[derive(Debug, Clone, Default)]
pub struct Filters {
    /// Only entries in this domain.
    pub domain: Option<String>,
    /// Only entries with this safety level.
    pub safety: Option<String>,
    /// Only entries with this difficulty.
    pub difficulty: Option<String>,
}

impl Filters {
    /// Whether an entry passes the filters.
    pub fn accepts(&self, entry: &Entry) -> bool {
        if let Some(domain) = &self.domain {
            if &entry.domain != domain {
                return false;
            }
        }
        if let Some(safety) = &self.safety {
            if &entry.safety != safety {
                return false;
            }
        }
        if let Some(difficulty) = &self.difficulty {
            if &entry.difficulty != difficulty {
                return false;
            }
        }
        true
    }
}

/// Searches the entries, returning the best hits first.
pub fn search(entries: &[Entry], query: &str, filters: &Filters, limit: usize) -> Vec<Hit> {
    let needle = query.trim().to_lowercase();
    if needle.is_empty() {
        return Vec::new();
    }

    let mut hits: Vec<Hit> = Vec::new();
    for (index, entry) in entries.iter().enumerate() {
        if !filters.accepts(entry) {
            continue;
        }
        let score = score_entry(entry, &needle);
        if score > 0.0 {
            hits.push(Hit {
                index,
                entry: entry.clone(),
                score,
            });
        }
    }

    hits.sort_by(|a, b| {
        b.score
            .partial_cmp(&a.score)
            .unwrap_or(std::cmp::Ordering::Equal)
            .then_with(|| a.entry.title.cmp(&b.entry.title))
    });
    hits.truncate(limit);
    hits
}

/// Scores one entry against a lowercase query.
fn score_entry(entry: &Entry, needle: &str) -> f32 {
    let title = entry.title.to_lowercase();
    let tags = entry.tags.join(" ").to_lowercase();
    let body = entry.body.to_lowercase();

    let mut score = 0.0;
    if title.starts_with(needle) {
        score += 100.0;
    } else if title.contains(needle) {
        score += 60.0;
    }
    if tags.contains(needle) {
        score += 30.0;
    }
    if body.contains(needle) {
        score += 10.0;
    }
    score
}

/// A short excerpt of the body around the first match.
pub fn snippet(body: &str, query: &str, length: usize) -> String {
    let needle = query.trim().to_lowercase();
    if needle.is_empty() {
        return body.chars().take(length).collect();
    }
    let lower = body.to_lowercase();
    match lower.find(&needle) {
        Some(position) => {
            let start = position.saturating_sub(length / 3);
            let mut text: String = body.chars().skip(start).take(length).collect();
            if start > 0 {
                text.insert(0, '…');
            }
            text
        }
        None => body.chars().take(length).collect(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::corpus::{Source, Verification};

    fn entry(title: &str, domain: &str, tags: &[&str], body: &str) -> Entry {
        Entry {
            id: String::new(),
            title: title.to_string(),
            domain: domain.to_string(),
            tags: tags.iter().map(|t| t.to_string()).collect(),
            difficulty: "novice".to_string(),
            safety: "green".to_string(),
            time_to_complete: String::new(),
            verification: Verification::default(),
            sources: vec![Source {
                title: "A".to_string(),
                author: String::new(),
                year: String::new(),
                license: "public-domain".to_string(),
            }],
            body: body.to_string(),
        }
    }

    fn corpus() -> Vec<Entry> {
        vec![
            entry(
                "Making Fire",
                "survival",
                &["fire"],
                "Bow drill and ferro rod.",
            ),
            entry(
                "Solar Photovoltaic Systems",
                "energy",
                &["solar"],
                "Panels and inverters.",
            ),
            entry(
                "Solar Still",
                "water",
                &["water", "solar"],
                "Distils water from the sun.",
            ),
        ]
    }

    #[test]
    fn a_title_match_ranks_first() {
        let hits = search(&corpus(), "solar", &Filters::default(), 50);
        assert!(!hits.is_empty());
        assert_eq!(hits[0].entry.title, "Solar Photovoltaic Systems");
    }

    #[test]
    fn a_tag_match_outranks_a_body_match() {
        let hits = search(&corpus(), "bow", &Filters::default(), 50);
        assert!(!hits.is_empty());
        assert_eq!(hits[0].entry.title, "Making Fire");
    }

    #[test]
    fn filters_narrow_the_results() {
        let hits = search(
            &corpus(),
            "solar",
            &Filters {
                domain: Some("water".to_string()),
                ..Filters::default()
            },
            50,
        );
        assert_eq!(hits.len(), 1);
        assert_eq!(hits[0].entry.domain, "water");
    }

    #[test]
    fn an_empty_query_returns_nothing() {
        assert!(search(&corpus(), "   ", &Filters::default(), 50).is_empty());
    }

    #[test]
    fn a_query_with_no_match_returns_nothing() {
        assert!(search(&corpus(), "zzzznotfound", &Filters::default(), 50).is_empty());
    }

    #[test]
    fn the_limit_is_applied() {
        let hits = search(&corpus(), "solar", &Filters::default(), 1);
        assert_eq!(hits.len(), 1);
    }

    #[test]
    fn a_snippet_is_built_around_the_match() {
        let text = snippet("the quick brown fox jumps", "brown", 10);
        assert!(text.contains("brown"));
    }
}
