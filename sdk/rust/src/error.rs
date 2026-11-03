use thiserror::Error;

#[derive(Debug, Error)]
pub enum ABookError {
    #[error("network error: {0}")]
    Network(#[from] reqwest::Error),

    #[error("url error: {0}")]
    Url(#[from] url::ParseError),

    #[error("header error: {0}")]
    Header(#[from] reqwest::header::InvalidHeaderValue),

    #[error("not found: {0}")]
    NotFound(String),

    #[error("validation error: {0}")]
    Validation(String),

    #[error("rate limited: {0}")]
    RateLimited(String),

    #[error("server error ({status}): {message}")]
    Server { status: u16, message: String },

    #[error("invalid pnk uri: {0}")]
    InvalidPnk(String),

    #[error("json error: {0}")]
    Json(#[from] serde_json::Error),
}

pub type Result<T> = std::result::Result<T, ABookError>;
