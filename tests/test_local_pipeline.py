"""Structural checks on the local pipeline's stage table.

The pipeline is the gate every change goes through, so its own wiring gets
tested rather than trusted: unique names, declared dependencies that exist, and
an artifact stage that always says which files it writes.
"""

from __future__ import annotations

from scripts import local_pipeline


def _stages():
    return local_pipeline.build_stages()


def test_stage_names_are_unique():
    names = [stage.name for stage in _stages()]
    assert len(names) == len(set(names))


def test_every_dependency_names_a_real_stage():
    names = {stage.name for stage in _stages()}
    for stage in _stages():
        unknown = set(stage.requires) - names
        assert not unknown, f"{stage.name} requires unknown stages: {sorted(unknown)}"


def test_cached_artifact_stages_declare_their_outputs():
    for stage in _stages():
        if stage.cacheable:
            assert stage.outputs, f"{stage.name} is cacheable but declares no outputs"


def test_artifact_stages_are_the_only_cacheable_stages():
    artifact_stages = {"index", "media", "models", "variants", "bundle"}
    cacheable = {stage.name for stage in _stages() if stage.cacheable}
    assert cacheable == artifact_stages


def test_end_to_end_tests_wait_for_the_index_and_the_bundle():
    tests = next(stage for stage in _stages() if stage.name == "tests")
    assert "index" in tests.requires
    assert "bundle" in tests.requires


def test_preflight_is_first_and_runs_alone():
    stages = _stages()
    assert stages[0].name == "preflight"
    assert stages[0].group == "preflight"
    assert all(stage.group != "preflight" for stage in stages[1:])
