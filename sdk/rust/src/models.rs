use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Version {
    pub kb_version: String,
    pub api_version: String,
    pub schema_version: String,
    pub built_at: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SearchResult {
    pub id: String,
    pub title: String,
    pub domain: String,
    pub difficulty: String,
    pub safety: String,
    pub score: f64,
    #[serde(default)]
    pub snippet: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct EntrySummary {
    pub id: String,
    pub title: String,
    pub domain: String,
    pub difficulty: String,
    pub safety: String,
    pub verification_status: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Entry {
    pub id: String,
    pub title: String,
    pub domain: String,
    pub difficulty: String,
    pub safety: String,
    pub verification_status: String,
    #[serde(default)]
    pub tags: Vec<String>,
    #[serde(default)]
    pub body: String,
    #[serde(default)]
    pub metadata: serde_json::Value,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Verification {
    pub entry_id: String,
    pub status: String,
    #[serde(default)]
    pub reviewers: Vec<String>,
    #[serde(default)]
    pub tested_by: Option<String>,
    #[serde(default)]
    pub tested_date: Option<String>,
    #[serde(default)]
    pub tested_location: Option<String>,
    #[serde(default)]
    pub notes: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct VerificationEvent {
    pub entry_id: String,
    pub from_status: String,
    pub to_status: String,
    pub actor: String,
    pub timestamp: String,
    #[serde(default)]
    pub notes: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Stats {
    pub total: u64,
    #[serde(default)]
    pub by_status: HashMap<String, u64>,
    #[serde(default)]
    pub by_domain: HashMap<String, u64>,
    #[serde(default)]
    pub by_safety: HashMap<String, u64>,
    #[serde(default)]
    pub by_difficulty: HashMap<String, u64>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Resolution {
    pub uri: String,
    pub node_id: String,
    pub api_url: String,
    pub entry_id: String,
    pub title: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SearchResponse {
    pub query: String,
    pub results: Vec<SearchResult>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LedgerResponse {
    pub events: Vec<VerificationEvent>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct FieldTestsResponse {
    pub field_tests: Vec<serde_json::Value>,
}
