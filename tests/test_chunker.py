from scripts.chunker import chunk_markdown


def test_single_section():
    md = "Just a paragraph."
    chunks = list(chunk_markdown(md))
    assert len(chunks) == 1
    assert chunks[0][1] == "Just a paragraph."


def test_headings_split():
    md = "# A\n\nfirst\n\n# B\n\nsecond"
    chunks = list(chunk_markdown(md))
    assert len(chunks) == 2
    assert chunks[0] == ("A", "first")
    assert chunks[1] == ("B", "second")


def test_long_section_splits():
    md = "# A\n\n" + " ".join(["word"] * 1000)
    chunks = list(chunk_markdown(md))
    assert len(chunks) > 1
