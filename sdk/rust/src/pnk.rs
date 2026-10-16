use crate::error::{ABookError, Result};
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PnkUri {
    pub node_id: String,
    pub entry_ulid: Option<String>,
    pub domain: String,
    pub slug: String,
}

impl PnkUri {
    pub fn parse(s: &str) -> Result<Self> {
        if let Some(rest) = s.strip_prefix("pnk://") {
            let mut parts = rest.splitn(2, '/');
            let node_id = parts.next().unwrap_or("").to_string();
            let tail = parts
                .next()
                .ok_or_else(|| ABookError::InvalidPnk(s.to_string()))?;
            let segs: Vec<&str> = tail.split('/').filter(|x| !x.is_empty()).collect();
            if segs.len() != 2 {
                return Err(ABookError::InvalidPnk(s.to_string()));
            }
            return Ok(Self {
                node_id,
                entry_ulid: None,
                domain: segs[0].to_string(),
                slug: segs[1].to_string(),
            });
        }

        if let Some(rest) = s.strip_prefix("pnk:") {
            let segs: Vec<&str> = rest.split('/').collect();
            match segs.len() {
                3 => {
                    return Ok(Self {
                        node_id: String::new(),
                        entry_ulid: Some(segs[0].to_string()),
                        domain: segs[1].to_string(),
                        slug: segs[2].to_string(),
                    })
                }
                2 => {
                    return Ok(Self {
                        node_id: String::new(),
                        entry_ulid: None,
                        domain: segs[0].to_string(),
                        slug: segs[1].to_string(),
                    })
                }
                _ => {}
            }
        }

        Err(ABookError::InvalidPnk(s.to_string()))
    }

    pub fn canonical(&self) -> String {
        match &self.entry_ulid {
            Some(ulid) => format!("pnk:{}/{}/{}", ulid, self.domain, self.slug),
            None => format!("pnk://{}/{}/{}", self.node_id, self.domain, self.slug),
        }
    }
}

impl fmt::Display for PnkUri {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.canonical())
    }
}

pub fn slugify(title: &str) -> String {
    let mut out = String::new();
    let mut last_dash = false;
    for ch in title.to_lowercase().chars() {
        if ch.is_ascii_alphanumeric() {
            out.push(ch);
            last_dash = false;
        } else if !last_dash && !out.is_empty() {
            out.push('-');
            last_dash = true;
        }
    }
    out.trim_matches('-').to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_entry_form() {
        let u = PnkUri::parse("pnk:01HZX0/survival/making-fire").unwrap();
        assert_eq!(u.entry_ulid.as_deref(), Some("01HZX0"));
        assert_eq!(u.domain, "survival");
        assert_eq!(u.slug, "making-fire");
    }

    #[test]
    fn parses_node_form() {
        let u = PnkUri::parse("pnk://node-a/survival/making-fire").unwrap();
        assert_eq!(u.node_id, "node-a");
    }

    #[test]
    fn canonical_round_trips() {
        let u = PnkUri::parse("pnk:01HZX0/survival/making-fire").unwrap();
        assert_eq!(u.canonical(), "pnk:01HZX0/survival/making-fire");
    }

    #[test]
    fn slugify_trims() {
        assert_eq!(slugify("  Making Fire! "), "making-fire");
    }
}
