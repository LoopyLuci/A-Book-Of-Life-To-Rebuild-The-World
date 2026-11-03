//! A native, offline desktop reader for the *A Book Of Life To Rebuild The
//! World* knowledge base.
//!
//! The whole interface is Rust. There is no web view, no embedded HTML and
//! no JavaScript: the app is a native window that draws its own widgets.
//!
//! The crate is split so that the logic can be tested without a display:
//!
//! - [`corpus`] reads the repository's sidecars and Markdown bodies.
//! - [`search`] ranks the entries.
//! - [`i18n`] reads the interface strings.
//! - [`settings`] keeps the reader's preferences.
//! - [`ui`] draws the window.

#![forbid(unsafe_code)]
#![warn(missing_docs)]

pub mod corpus;
pub mod i18n;
pub mod search;
pub mod settings;
pub mod ui;
