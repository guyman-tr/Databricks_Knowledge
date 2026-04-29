"""
Regression suite for compact_audits.py.

Builds a tmp_path fixture mimicking audits/regen-sample/{Schema}/{Object}/
layouts and exercises every gate + every drop/keep decision. The critical
properties under test:
  - DRY-RUN by default; nothing is deleted unless --apply is passed
  - completed-only policy refuses to touch FAIL or missing-verdict objects
  - regen/final/ deliverables (.md/.lineage.md/.review-needed.md/judge_verdict.json/
    judge_log.md/writer_log.md) are NEVER deleted
  - current/ + current_judge/ + compare.md are NEVER touched
  - --keep-attempts retains attempt_*/ dirs even when --apply is on
  - any-final policy can compact FAIL objects
  - per-object _compaction_log.json is written on apply
"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional

import pytest

HARNESS_ROOT = Path(__file__).resolve().parent.parent
COMPACT_TOOL = HARNESS_ROOT / "compact_audits.py"

SCHEMA = "BI_DB_dbo"
OBJ = "BI_DB_TestObj"


def _make_object_tree(audit_root: Path, schema: str, obj: str,
                      verdict: str = "PASS", score: float = 9.5,
                      n_attempts: int = 2) -> Path:
    """Build a realistic regen-sample dir layout for a single object."""
    od = audit_root / schema / obj
    od.mkdir(parents=True)

    # current/ baseline
    cur = od / "current"
    cur.mkdir()
    (cur / f"{obj}.md").write_text("# baseline wiki\n", encoding="utf-8")
    (cur / f"{obj}.lineage.md").write_text("baseline lineage\n", encoding="utf-8")
    (cur / "meta.json").write_text("{}", encoding="utf-8")

    # current_judge/
    cj = od / "current_judge"
    cj.mkdir()
    (cj / "judge_verdict.json").write_text('{"verdict": {"verdict": "FAIL", "weighted_score": 6.0}}',
                                           encoding="utf-8")
    (cj / "judge_log.md").write_text("baseline judge log\n", encoding="utf-8")
    (cj / "judge_raw_stream.jsonl").write_text("x" * 5000, encoding="utf-8")

    # compare.md
    (od / "compare.md").write_text("# compare\n", encoding="utf-8")

    # regen/
    rg = od / "regen"
    rg.mkdir()
    (rg / "regen_summary.json").write_text(
        json.dumps({"best_attempt": n_attempts, "best_score": score}),
        encoding="utf-8",
    )
    (rg / "_upstream_resolution.json").write_text(
        json.dumps({"resolved_synapse": [], "candidates_found": 0}),
        encoding="utf-8",
    )
    (rg / "_upstream_bundle.md").write_text("UPSTREAM\n" + ("x" * 50_000),
                                            encoding="utf-8")  # ~50KB

    # regen/attempt_N/ (the heavy stuff)
    for n in range(1, n_attempts + 1):
        a = rg / f"attempt_{n}"
        a.mkdir()
        (a / f"{obj}.md").write_text("# wiki\n", encoding="utf-8")
        (a / f"{obj}.lineage.md").write_text("lineage\n", encoding="utf-8")
        (a / f"{obj}.review-needed.md").write_text("review\n", encoding="utf-8")
        (a / "writer_log.md").write_text("writer log\n", encoding="utf-8")
        (a / "writer_prompt.md").write_text("prompt " * 1000, encoding="utf-8")  # ~7KB
        (a / "writer_summary.json").write_text("{}", encoding="utf-8")
        (a / "writer_raw_stream.jsonl").write_text("y" * 250_000, encoding="utf-8")  # ~250KB
        (a / "writer_stderr.tmp").write_text("", encoding="utf-8")
        (a / "judge_log.md").write_text("judge log\n", encoding="utf-8")
        (a / "judge_raw_stream.jsonl").write_text("z" * 35_000, encoding="utf-8")  # ~35KB
        (a / "judge_verdict.json").write_text(
            json.dumps({"verdict": {"verdict": verdict, "weighted_score": score}}),
            encoding="utf-8",
        )

    # regen/final/ = copy of best attempt
    final = rg / "final"
    final.mkdir()
    (final / f"{obj}.md").write_text("# wiki\n", encoding="utf-8")
    (final / f"{obj}.lineage.md").write_text("lineage\n", encoding="utf-8")
    (final / f"{obj}.review-needed.md").write_text("review\n", encoding="utf-8")
    (final / "writer_log.md").write_text("writer log\n", encoding="utf-8")
    (final / "writer_prompt.md").write_text("prompt " * 1000, encoding="utf-8")
    (final / "writer_summary.json").write_text("{}", encoding="utf-8")
    (final / "writer_raw_stream.jsonl").write_text("y" * 250_000, encoding="utf-8")
    (final / "writer_stderr.tmp").write_text("", encoding="utf-8")
    (final / "judge_log.md").write_text("judge log\n", encoding="utf-8")
    (final / "judge_raw_stream.jsonl").write_text("z" * 35_000, encoding="utf-8")
    (final / "judge_verdict.json").write_text(
        json.dumps({"verdict": {"verdict": verdict, "weighted_score": score}}),
        encoding="utf-8",
    )
    return od


def _run(audit_root: Path, *args) -> subprocess.CompletedProcess:
    cmd = [sys.executable, str(COMPACT_TOOL),
           "--audit-root", str(audit_root)] + list(args)
    return subprocess.run(cmd, capture_output=True, text=True)


def _file_count(d: Path) -> int:
    return sum(1 for _ in d.rglob("*") if _.is_file())


def _bytes(d: Path) -> int:
    return sum(p.stat().st_size for p in d.rglob("*") if p.is_file())


# ────────────────────────────── safety: dry-run ────────────────────────────


def test_dry_run_writes_nothing(tmp_path):
    """Default invocation deletes nothing on disk."""
    aud = tmp_path / "audits" / "regen-sample"
    od = _make_object_tree(aud, SCHEMA, OBJ, verdict="PASS")
    files_before = _file_count(od)
    bytes_before = _bytes(od)

    r = _run(aud, "--schema", SCHEMA)
    assert r.returncode == 0
    assert _file_count(od) == files_before
    assert _bytes(od) == bytes_before
    assert "DRY-RUN" in r.stdout
    assert not (od / "regen" / "_compaction_log.json").exists()


def test_dry_run_reports_estimated_freed_bytes(tmp_path):
    """Dry-run shows a per-object freed-bytes line."""
    aud = tmp_path / "audits" / "regen-sample"
    _make_object_tree(aud, SCHEMA, OBJ, verdict="PASS")
    r = _run(aud, "--schema", SCHEMA)
    assert "WOULD-FREE" in r.stdout
    assert OBJ in r.stdout


# ────────────────────────────── apply: happy path ──────────────────────────


def test_apply_drops_attempts_and_heavy_files(tmp_path):
    """--apply removes attempt_N/, _upstream_bundle.md, raw streams, prompts."""
    aud = tmp_path / "audits" / "regen-sample"
    od = _make_object_tree(aud, SCHEMA, OBJ, verdict="PASS", n_attempts=2)
    bytes_before = _bytes(od)

    r = _run(aud, "--schema", SCHEMA, "--apply")
    assert r.returncode == 0

    # attempt_*/ gone
    assert not (od / "regen" / "attempt_1").exists()
    assert not (od / "regen" / "attempt_2").exists()
    # heavy files gone
    assert not (od / "regen" / "_upstream_bundle.md").exists()
    assert not (od / "regen" / "final" / "writer_raw_stream.jsonl").exists()
    assert not (od / "regen" / "final" / "judge_raw_stream.jsonl").exists()
    assert not (od / "regen" / "final" / "writer_prompt.md").exists()
    assert not (od / "regen" / "final" / "writer_summary.json").exists()
    assert not (od / "regen" / "final" / "writer_stderr.tmp").exists()
    # significantly smaller
    bytes_after = _bytes(od)
    assert bytes_after < bytes_before * 0.3, \
        f"expected >70% reduction; before={bytes_before} after={bytes_after}"


def test_apply_keeps_deliverables_and_baselines(tmp_path):
    """The actual wiki files + baseline + compare.md must survive."""
    aud = tmp_path / "audits" / "regen-sample"
    od = _make_object_tree(aud, SCHEMA, OBJ, verdict="PASS")
    _run(aud, "--schema", SCHEMA, "--apply")

    # Deliverables
    assert (od / "regen" / "final" / f"{OBJ}.md").exists()
    assert (od / "regen" / "final" / f"{OBJ}.lineage.md").exists()
    assert (od / "regen" / "final" / f"{OBJ}.review-needed.md").exists()
    assert (od / "regen" / "final" / "judge_verdict.json").exists()
    assert (od / "regen" / "final" / "judge_log.md").exists()
    assert (od / "regen" / "final" / "writer_log.md").exists()
    # Baselines (NEVER touched)
    assert (od / "current" / f"{OBJ}.md").exists()
    assert (od / "current_judge" / "judge_verdict.json").exists()
    assert (od / "current_judge" / "judge_raw_stream.jsonl").exists(), \
        "current_judge raw stream is baseline data and must NOT be deleted"
    assert (od / "compare.md").exists()
    # Useful regen-level summaries
    assert (od / "regen" / "regen_summary.json").exists()
    assert (od / "regen" / "_upstream_resolution.json").exists()
    # Compaction log written
    assert (od / "regen" / "_compaction_log.json").exists()


def test_compaction_log_records_deletions(tmp_path):
    aud = tmp_path / "audits" / "regen-sample"
    od = _make_object_tree(aud, SCHEMA, OBJ, verdict="PASS", n_attempts=2)
    _run(aud, "--schema", SCHEMA, "--apply")
    log = json.loads((od / "regen" / "_compaction_log.json").read_text())
    assert log["verdict"] == "PASS"
    assert log["score"] == 9.5
    assert log["files_deleted"] > 0
    assert log["bytes_freed"] > 100_000  # at least the writer raw stream
    deleted_paths = [d["path"] for d in log["deleted_paths"]]
    assert any("attempt_1" in p for p in deleted_paths)
    assert any("attempt_2" in p for p in deleted_paths)
    assert any("writer_raw_stream.jsonl" in p for p in deleted_paths)


# ────────────────────────────── policy: completed-only ─────────────────────


def test_completed_only_skips_fail_verdict(tmp_path):
    """Default policy refuses to compact a FAIL object (forensic data preserved)."""
    aud = tmp_path / "audits" / "regen-sample"
    od = _make_object_tree(aud, SCHEMA, OBJ, verdict="FAIL", score=6.0)
    bytes_before = _bytes(od)

    r = _run(aud, "--schema", SCHEMA, "--apply")
    assert r.returncode == 0
    assert "SKIP" in r.stdout
    assert _bytes(od) == bytes_before, "FAIL object must not be touched under completed-only"
    assert not (od / "regen" / "_compaction_log.json").exists()


def test_completed_only_skips_missing_verdict(tmp_path):
    """No final judge_verdict.json -> skip even with --apply."""
    aud = tmp_path / "audits" / "regen-sample"
    od = _make_object_tree(aud, SCHEMA, OBJ, verdict="PASS")
    (od / "regen" / "final" / "judge_verdict.json").unlink()
    bytes_before = _bytes(od)
    r = _run(aud, "--schema", SCHEMA, "--apply")
    assert r.returncode == 0
    assert "SKIP" in r.stdout
    assert _bytes(od) == bytes_before


# ────────────────────────────── policy: any-final ──────────────────────────


def test_any_final_compacts_fail_objects(tmp_path):
    """any-final policy compacts FAIL objects too (regen/final/judge_verdict.json present)."""
    aud = tmp_path / "audits" / "regen-sample"
    od = _make_object_tree(aud, SCHEMA, OBJ, verdict="FAIL", score=6.0)
    bytes_before = _bytes(od)
    r = _run(aud, "--schema", SCHEMA, "--apply", "--policy", "any-final")
    assert r.returncode == 0
    assert "SKIP" not in r.stdout
    assert _bytes(od) < bytes_before * 0.3
    assert (od / "regen" / "_compaction_log.json").exists()


# ────────────────────────────── --keep-attempts ────────────────────────────


def test_keep_attempts_retains_attempt_dirs(tmp_path):
    """--keep-attempts means attempt_*/ stay even when --apply runs."""
    aud = tmp_path / "audits" / "regen-sample"
    od = _make_object_tree(aud, SCHEMA, OBJ, verdict="PASS", n_attempts=2)
    r = _run(aud, "--schema", SCHEMA, "--apply", "--keep-attempts")
    assert r.returncode == 0
    assert (od / "regen" / "attempt_1").exists()
    assert (od / "regen" / "attempt_2").exists()
    # ... but heavy files at regen/ + regen/final/ are still gone
    assert not (od / "regen" / "_upstream_bundle.md").exists()
    assert not (od / "regen" / "final" / "writer_raw_stream.jsonl").exists()


# ────────────────────────────── single-object filter ───────────────────────


def test_single_object_only_touches_that_object(tmp_path):
    """--object X means only X is compacted; siblings are left alone."""
    aud = tmp_path / "audits" / "regen-sample"
    a = _make_object_tree(aud, SCHEMA, "BI_DB_A", verdict="PASS")
    b = _make_object_tree(aud, SCHEMA, "BI_DB_B", verdict="PASS")
    bytes_b_before = _bytes(b)

    r = _run(aud, "--schema", SCHEMA, "--object", "BI_DB_A", "--apply")
    assert r.returncode == 0
    assert not (a / "regen" / "attempt_1").exists()
    assert _bytes(b) == bytes_b_before, "sibling object must not be touched"


def test_object_without_schema_errors(tmp_path):
    aud = tmp_path / "audits" / "regen-sample"
    aud.mkdir(parents=True)
    r = _run(aud, "--object", "anything")
    assert r.returncode != 0
    assert "--object requires --schema" in (r.stderr + r.stdout)


# ────────────────────────────── walk-all ───────────────────────────────────


def test_walks_all_schemas_when_no_schema_passed(tmp_path):
    """No --schema -> walk every schema in audit_root."""
    aud = tmp_path / "audits" / "regen-sample"
    a = _make_object_tree(aud, "BI_DB_dbo", "BI_DB_A", verdict="PASS")
    b = _make_object_tree(aud, "Dealing_dbo", "Dealing_B", verdict="PASS")
    r = _run(aud, "--apply")
    assert r.returncode == 0
    assert not (a / "regen" / "attempt_1").exists()
    assert not (b / "regen" / "attempt_1").exists()


def test_no_objects_returns_nonzero(tmp_path):
    aud = tmp_path / "audits" / "regen-sample"
    aud.mkdir(parents=True)  # empty
    r = _run(aud)
    assert r.returncode == 1
