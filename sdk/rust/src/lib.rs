//! Rust SDK for A Book Of Life To Rebuild The World.
//!
//! ```no_run
//! use abook::Client;
//!
//! #[tokio::main]
//! async fn main() -> Result<(), Box<dyn std::error::Error>> {
//!     let client = Client::new("http://localhost:8080/v1")?;
//!     let results = client.search("making fire", Default::default()).await?;
//!     for r in results {
//!         println!("{} — {}", r.title, r.id);
//!     }
//!     Ok(())
//! }
//! ```

pub mod client;
pub mod error;
pub mod models;
pub mod pnk;

pub use client::{Client, ClientOptions, SearchOptions};
pub use error::{ABookError, Result};
pub use models::*;
pub use pnk::PnkUri;
