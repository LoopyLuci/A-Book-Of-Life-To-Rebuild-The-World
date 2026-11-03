use crate::error::{ABookError, Result};
use crate::models::*;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, USER_AGENT};
use url::Url;

#[derive(Debug, Clone, Default)]
pub struct ClientOptions {
    pub api_key: Option<String>,
    pub timeout_seconds: Option<u64>,
}

#[derive(Debug, Clone, Default)]
pub struct SearchOptions {
    pub domain: Option<String>,
    pub difficulty: Option<String>,
    pub safety: Option<String>,
    pub language: Option<String>,
    pub limit: Option<u32>,
}

pub struct Client {
    base_url: Url,
    http: reqwest::Client,
}

impl Client {
    pub fn new(base_url: &str) -> Result<Self> {
        Self::with_options(base_url, ClientOptions::default())
    }

    pub fn with_options(base_url: &str, opts: ClientOptions) -> Result<Self> {
        let base_url = Url::parse(base_url)
            .map_err(ABookError::Url)?;

        let mut headers = HeaderMap::new();
        headers.insert(USER_AGENT, HeaderValue::from_static("abook-rust-sdk/1.0"));
        if let Some(key) = &opts.api_key {
            let value = HeaderValue::from_str(&format!("Bearer {}", key))
                .map_err(ABookError::Header)?;
            headers.insert(AUTHORIZATION, value);
        }

        let mut builder = reqwest::Client::builder().default_headers(headers);
        if let Some(secs) = opts.timeout_seconds {
            builder = builder.timeout(std::time::Duration::from_secs(secs));
        }
        let http = builder
            .build()
            .map_err(ABookError::Network)?;

        Ok(Self { base_url, http })
    }

    // -- internal ---------------------------------------------------------

    async fn get_json<T: serde::de::DeserializeOwned>(
        &self,
        path: &str,
        params: &[(&str, Option<String>)],
    ) -> Result<T> {
        let mut url = self.base_url.join(path.trim_start_matches('/'))
            .map_err(ABookError::Url)?;
        {
            let mut qp = url.query_pairs_mut();
            for (k, v) in params {
                if let Some(val) = v {
                    qp.append_pair(k, val);
                }
            }
        }

        let res = self.http.get(url).send().await?;
        let status = res.status();

        if status.is_success() {
            let data = res.json::<T>().await?;
            return Ok(data);
        }

        let text = res.text().await.unwrap_or_default();
        let detail = serde_json::from_str::<serde_json::Value>(&text)
            .ok()
            .and_then(|v| v.get("detail").and_then(|d| d.as_str()).map(String::from))
            .unwrap_or_else(|| text.clone());

        match status.as_u16() {
            404 => Err(ABookError::NotFound(detail)),
            400 | 422 => Err(ABookError::Validation(detail)),
            429 => Err(ABookError::RateLimited(detail)),
            _ => Err(ABookError::Server {
                status: status.as_u16(),
                message: detail,
            }),
        }
    }

    // -- system -----------------------------------------------------------

    pub async fn version(&self) -> Result<Version> {
        self.get_json("/version", &[]).await
    }

    pub async fn stats(&self) -> Result<Stats> {
        self.get_json("/stats", &[]).await
    }

    // -- search -----------------------------------------------------------

    pub async fn search(&self, query: &str, opts: SearchOptions) -> Result<Vec<SearchResult>> {
        let limit = opts.limit.unwrap_or(20).to_string();
        let language = opts.language.unwrap_or_else(|| "en".to_string());
        let params = vec![
            ("q", Some(query.to_string())),
            ("limit", Some(limit)),
            ("language", Some(language)),
            ("domain", opts.domain),
            ("difficulty", opts.difficulty),
            ("safety", opts.safety),
        ];
        let resp: SearchResponse = self.get_json("/search", &params).await?;
        Ok(resp.results)
    }

    // -- entries ----------------------------------------------------------

    pub async fn get_entry(&self, entry_id: &str) -> Result<Entry> {
        let path = format!("/entries/{}", urlencoding(entry_id));
        self.get_json(&path, &[]).await
    }

    // -- verification -----------------------------------------------------

    pub async fn get_verification(&self, entry_id: &str) -> Result<Verification> {
        let path = format!("/verification/{}", urlencoding(entry_id));
        self.get_json(&path, &[]).await
    }

    pub async fn get_ledger(&self, limit: Option<u32>) -> Result<Vec<VerificationEvent>> {
        let params = vec![("limit", limit.map(|l| l.to_string()))];
        let resp: LedgerResponse = self.get_json("/verification/ledger", &params).await?;
        Ok(resp.events)
    }

    pub async fn get_field_tests(&self) -> Result<Vec<serde_json::Value>> {
        let resp: FieldTestsResponse = self.get_json("/verification/field-tests", &[]).await?;
        Ok(resp.field_tests)
    }

    // -- federation -------------------------------------------------------

    pub async fn resolve(&self, uri: &str) -> Result<Resolution> {
        let params = vec![("uri", Some(uri.to_string()))];
        self.get_json("/federation/resolve", &params).await
    }
}

fn urlencoding(s: &str) -> String {
    s.replace(':', "%3A").replace('/', "%2F")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn constructs_client() {
        let c = Client::new("http://localhost:8080/v1").unwrap();
        assert_eq!(c.base_url.as_str(), "http://localhost:8080/v1");
    }
}
