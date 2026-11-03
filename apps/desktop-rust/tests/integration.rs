//! Integration tests: the app must read a real corpus and behave.
//!
//! Each test builds a small corpus in its own temporary directory, so the
//! tests can run in parallel without interfering with each other.

use std::fs;
use std::path::PathBuf;

fn make_corpus(name: &str) -> PathBuf {
    let base = std::env::temp_dir().join(format!("abook-rust-it-{name}-{}", std::process::id()));
    let _ = fs::remove_dir_all(&base);

    let domain = base.join("sidecars").join("demo");
    fs::create_dir_all(&domain).unwrap();
    fs::create_dir_all(base.join("domains").join("demo")).unwrap();
    fs::create_dir_all(base.join("i18n").join("strings")).unwrap();

    fs::write(
        base.join("manifest.toml"),
        "[project]\nversion = \"2.1.0\"\n\n[domains]\nlist = [\n  \"demo\",\n]\n",
    )
    .unwrap();

    fs::write(
        domain.join("alpha.pnk.yaml"),
        concat!(
            "id: pnk:01ABC/demo/alpha\n",
            "title: Alpha Entry\n",
            "domain: demo\n",
            "tags: [one, two]\n",
            "difficulty: novice\n",
            "safety: green\n",
            "time_to_complete: hours\n",
            "verification:\n",
            "  status: draft\n",
            "sources:\n",
            "  - title: A Public Manual\n",
            "    license: public-domain\n",
        ),
    )
    .unwrap();

    fs::write(
        domain.join("beta.pnk.yaml"),
        concat!(
            "id: pnk:01ABC/demo/beta\n",
            "title: Beta Entry\n",
            "domain: demo\n",
            "tags: [three]\n",
            "difficulty: master\n",
            "safety: red\n",
            "verification:\n",
            "  status: field-tested\n",
        ),
    )
    .unwrap();

    fs::write(
        base.join("domains").join("demo").join("alpha.md"),
        "# Alpha Entry\n\n## Overview\n\nThe alpha body mentions solar power.\n",
    )
    .unwrap();
    fs::write(
        base.join("domains").join("demo").join("beta.md"),
        "# Beta Entry\n\n## Overview\n\nThe beta body mentions fire.\n",
    )
    .unwrap();

    fs::write(
        base.join("i18n").join("strings").join("en.yaml"),
        "domains: Domains\nsearch: Search\n",
    )
    .unwrap();
    fs::write(
        base.join("i18n").join("strings").join("es.yaml"),
        "domains: Dominios\nsearch: Buscar\n",
    )
    .unwrap();

    base
}

#[test]
fn the_corpus_is_read_completely() {
    let base = make_corpus("read");
    let corpus = abook_desktop::corpus::Corpus::load(&base).expect("the corpus loads");

    assert_eq!(corpus.entries.len(), 2);
    assert_eq!(corpus.version, "2.1.0");
    assert_eq!(corpus.domains.len(), 1);
    assert_eq!(corpus.domains[0].slug, "demo");
    assert_eq!(corpus.domains[0].count, 2);

    let alpha = corpus
        .entries
        .iter()
        .find(|entry| entry.title == "Alpha Entry")
        .expect("alpha is loaded");
    assert_eq!(alpha.tags, vec!["one".to_string(), "two".to_string()]);
    assert_eq!(alpha.safety, "green");
    assert_eq!(alpha.time_to_complete, "hours");
    assert!(alpha.body.contains("solar power"));
    assert_eq!(alpha.sources.len(), 1);
    assert_eq!(alpha.sources[0].title, "A Public Manual");
    assert_eq!(alpha.verification.status, "draft");

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn the_search_ranks_a_title_above_a_body() {
    let base = make_corpus("search");
    let corpus = abook_desktop::corpus::Corpus::load(&base).expect("the corpus loads");

    let hits = abook_desktop::search::search(
        &corpus.entries,
        "beta",
        &abook_desktop::search::Filters::default(),
        50,
    );
    assert!(!hits.is_empty());
    assert_eq!(hits[0].entry.title, "Beta Entry");

    let hits = abook_desktop::search::search(
        &corpus.entries,
        "solar",
        &abook_desktop::search::Filters::default(),
        50,
    );
    assert!(!hits.is_empty());
    assert_eq!(hits[0].entry.title, "Alpha Entry");

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn the_filters_are_applied() {
    let base = make_corpus("filters");
    let corpus = abook_desktop::corpus::Corpus::load(&base).expect("the corpus loads");

    let hits = abook_desktop::search::search(
        &corpus.entries,
        "entry",
        &abook_desktop::search::Filters {
            safety: Some("red".to_string()),
            ..Default::default()
        },
        50,
    );
    assert_eq!(hits.len(), 1);
    assert_eq!(hits[0].entry.title, "Beta Entry");

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn the_interface_strings_come_from_the_catalogue() {
    let base = make_corpus("i18n");

    let english = abook_desktop::i18n::Strings::load(&base, "en");
    assert_eq!(english.get("domains"), "Domains");

    let spanish = abook_desktop::i18n::Strings::load(&base, "es");
    assert_eq!(spanish.get("domains"), "Dominios");
    assert_eq!(spanish.get("search"), "Buscar");

    let missing = abook_desktop::i18n::Strings::load(&base, "zz");
    assert_eq!(missing.language, "en");
    assert_eq!(missing.get("domains"), "Domains");

    let languages = abook_desktop::i18n::Strings::available(&base);
    assert_eq!(languages, vec!["en".to_string(), "es".to_string()]);

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn a_missing_corpus_is_an_error_not_a_panic() {
    let missing = std::env::temp_dir().join("abook-rust-it-does-not-exist");
    let _ = fs::remove_dir_all(&missing);
    assert!(abook_desktop::corpus::Corpus::load(&missing).is_err());
}
