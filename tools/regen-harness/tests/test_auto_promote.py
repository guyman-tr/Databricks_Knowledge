"""
Regression suite for auto_promote.ps1.

Drives the PowerShell script via subprocess against tmp_path fixtures that
mirror the real audits/regen-sample/ + knowledge/synapse/Wiki/ layouts.
Each test pairs one decision-tree branch with the expected exit code +
expected file-system effects (or absence thereof).

Exit code reference (from auto_promote.ps1):
    0 = promoted (live tree updated, .bak sidecar created if pre-existing)
    1 = score below threshold OR judge verdict missing/unparseable
    2 = no live wiki found
    3 = regen/final dir or wiki .md missing
    4 = hard error
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
AUTO_PROMOTE = HARNESS_ROOT / "auto_promote.ps1"
SCHEMA = "BI_DB_dbo"
OBJ = "BI_DB_TestObj"


def _make_repo(tmp_path: Path) -> dict:
    """Build a repo-shaped tmp tree with both audit + live wiki dirs.

    Returns a dict of paths and a runner that invokes auto_promote.ps1
    with a remapped repoRoot via env var (the script computes repoRoot
    from its own location, so we instead drop a copy of the script into
    the tmp tree at the right relative depth).
    """
    audit_root = tmp_path / "audits" / "regen-sample" / SCHEMA / OBJ
    final_dir = audit_root / "regen" / "final"
    live_dir = tmp_path / "knowledge" / "synapse" / "Wiki" / SCHEMA / "Tables"
    final_dir.mkdir(parents=True)
    live_dir.mkdir(parents=True)

    # Drop a copy of auto_promote.ps1 at tmp/tools/regen-harness/ so its
    # relative-path repoRoot calculation lands on tmp_path.
    fake_harness = tmp_path / "tools" / "regen-harness"
    fake_harness.mkdir(parents=True)
    shutil.copy(AUTO_PROMOTE, fake_harness / "auto_promote.ps1")
    fake_script = fake_harness / "auto_promote.ps1"

    return {
        "tmp": tmp_path,
        "audit_root": audit_root,
        "final_dir": final_dir,
        "live_dir": live_dir,
        "live_wiki": live_dir / f"{OBJ}.md",
        "final_wiki": final_dir / f"{OBJ}.md",
        "verdict_path": final_dir / "judge_verdict.json",
        "log_path": audit_root / "auto_promote_log.json",
        "script": fake_script,
    }


def _write_verdict(path: Path, score: float, verdict: str = "PASS",
                   auto_verified: bool = False) -> None:
    payload = {
        "verdict": {
            "verdict": verdict,
            "weighted_score": score,
        },
    }
    if auto_verified:
        payload["verdict"]["auto_verified"] = True
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload), encoding="utf-8")


def _run(script: Path, schema: str = SCHEMA, obj: str = OBJ,
         min_score: Optional[float] = None,
         require_pass: Optional[bool] = None) -> subprocess.CompletedProcess:
    cmd = ["powershell", "-NoProfile", "-File", str(script),
           "-Schema", schema, "-ObjectName", obj]
    if min_score is not None:
        cmd += ["-MinScore", str(min_score)]
    if require_pass is False:
        cmd += ["-RequirePassVerdict", "$false"]
    return subprocess.run(cmd, capture_output=True, text=True)


# ────────────────────────────── happy path ────────────────────────────────


def test_promotes_on_pass_with_high_score(tmp_path):
    """PASS verdict + score 9.5 + live wiki exists -> exit 0, files written, .bak created."""
    fx = _make_repo(tmp_path)
    fx["live_wiki"].write_text("# OLD live wiki\n", encoding="utf-8")
    fx["final_wiki"].write_text("# NEW regen wiki\n", encoding="utf-8")
    _write_verdict(fx["verdict_path"], 9.5, "PASS")

    r = _run(fx["script"])
    assert r.returncode == 0, f"stdout: {r.stdout}\nstderr: {r.stderr}"
    assert fx["live_wiki"].read_text() == "# NEW regen wiki\n"
    backups = list(fx["live_dir"].glob(f"{OBJ}.md.bak.*"))
    assert len(backups) == 1
    assert backups[0].read_text() == "# OLD live wiki\n"
    assert fx["log_path"].exists()
    log = json.loads(fx["log_path"].read_text())
    assert log["score"] == 9.5
    assert log["verdict"] == "PASS"
    assert len(log["promoted_files"]) == 1
    assert len(log["backups_created"]) == 1


def test_promotes_includes_lineage_and_review_sidecars(tmp_path):
    """All three sidecar files (md, lineage.md, review-needed.md) get promoted."""
    fx = _make_repo(tmp_path)
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")
    fx["final_wiki"].write_text("# new\n", encoding="utf-8")
    (fx["final_dir"] / f"{OBJ}.lineage.md").write_text("lineage\n", encoding="utf-8")
    (fx["final_dir"] / f"{OBJ}.review-needed.md").write_text("review\n", encoding="utf-8")
    (fx["live_dir"] / f"{OBJ}.lineage.md").write_text("old lineage\n", encoding="utf-8")
    _write_verdict(fx["verdict_path"], 9.2, "PASS")

    r = _run(fx["script"])
    assert r.returncode == 0
    assert (fx["live_dir"] / f"{OBJ}.lineage.md").read_text() == "lineage\n"
    assert (fx["live_dir"] / f"{OBJ}.review-needed.md").read_text() == "review\n"
    log = json.loads(fx["log_path"].read_text())
    assert len(log["promoted_files"]) == 3
    # lineage had a pre-existing live file -> backed up; review-needed is new -> not backed up
    assert len(log["backups_created"]) == 2


def test_promotes_when_no_pre_existing_backup_needed(tmp_path):
    """Live wiki exists but no .lineage.md -> promotes only existing sources, no spurious backup."""
    fx = _make_repo(tmp_path)
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")
    fx["final_wiki"].write_text("# new\n", encoding="utf-8")
    # Note: only the .md is in regen/final, no sidecars
    _write_verdict(fx["verdict_path"], 9.0, "PASS")

    r = _run(fx["script"])
    assert r.returncode == 0
    log = json.loads(fx["log_path"].read_text())
    assert len(log["promoted_files"]) == 1
    assert len(log["backups_created"]) == 1


# ─────────────────────── score / verdict gating (exit 1) ──────────────────


def test_skips_when_score_below_threshold(tmp_path):
    """Score 8.5 < default threshold 9.0 -> exit 1, no writes, no backup."""
    fx = _make_repo(tmp_path)
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")
    fx["final_wiki"].write_text("# new\n", encoding="utf-8")
    _write_verdict(fx["verdict_path"], 8.5, "PASS")

    r = _run(fx["script"])
    assert r.returncode == 1, f"stdout: {r.stdout}"
    assert fx["live_wiki"].read_text() == "# old\n"  # unchanged
    assert not fx["log_path"].exists()
    assert list(fx["live_dir"].glob(f"{OBJ}.md.bak.*")) == []


def test_skips_when_verdict_is_fail(tmp_path):
    """Even score 9.5 must be skipped if verdict.verdict != PASS (require-pass on)."""
    fx = _make_repo(tmp_path)
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")
    fx["final_wiki"].write_text("# new\n", encoding="utf-8")
    _write_verdict(fx["verdict_path"], 9.5, "FAIL")

    r = _run(fx["script"])
    assert r.returncode == 1
    assert fx["live_wiki"].read_text() == "# old\n"


def test_skips_when_verdict_missing(tmp_path):
    """No judge_verdict.json -> exit 1, no writes."""
    fx = _make_repo(tmp_path)
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")
    fx["final_wiki"].write_text("# new\n", encoding="utf-8")
    # no verdict file written

    r = _run(fx["script"])
    assert r.returncode == 1
    assert fx["live_wiki"].read_text() == "# old\n"


def test_skips_when_verdict_unparseable(tmp_path):
    """Malformed JSON in verdict -> exit 1, no writes."""
    fx = _make_repo(tmp_path)
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")
    fx["final_wiki"].write_text("# new\n", encoding="utf-8")
    fx["verdict_path"].write_text("{ this is not json", encoding="utf-8")

    r = _run(fx["script"])
    assert r.returncode == 1


def test_promotes_synthetic_auto_verified_pass_at_default_threshold(tmp_path):
    """auto_verify writes weighted_score=8.5 + auto_verified=true. Default threshold
    of 9.0 SHOULD reject it (we want a higher-confidence score to auto-promote
    synthetic verdicts). Doc-tests the contract."""
    fx = _make_repo(tmp_path)
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")
    fx["final_wiki"].write_text("# new\n", encoding="utf-8")
    _write_verdict(fx["verdict_path"], 8.5, "PASS", auto_verified=True)

    r = _run(fx["script"])
    assert r.returncode == 1, "auto_verify's 8.5 score must NOT auto-promote at default 9.0 threshold"


def test_promotes_synthetic_auto_verified_pass_at_lower_threshold(tmp_path):
    """When threshold is lowered to 8.0, auto_verify's 8.5 PASS DOES promote."""
    fx = _make_repo(tmp_path)
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")
    fx["final_wiki"].write_text("# new\n", encoding="utf-8")
    _write_verdict(fx["verdict_path"], 8.5, "PASS", auto_verified=True)

    r = _run(fx["script"], min_score=8.0)
    assert r.returncode == 0
    log = json.loads(fx["log_path"].read_text())
    assert log["auto_verified"] is True


# ───────────────────────── live-wiki gating (exit 2) ──────────────────────


def test_refuses_to_create_new_live_wiki(tmp_path):
    """No pre-existing live wiki -> exit 2 (not the auto-promoter's job to create new objects)."""
    fx = _make_repo(tmp_path)
    fx["final_wiki"].write_text("# new\n", encoding="utf-8")
    _write_verdict(fx["verdict_path"], 9.5, "PASS")
    # Note: fx["live_wiki"] intentionally NOT created

    r = _run(fx["script"])
    assert r.returncode == 2, f"stdout: {r.stdout}"
    assert not fx["live_wiki"].exists()
    assert not fx["log_path"].exists()


# ─────────────────────── regen-final gating (exit 3) ──────────────────────


def test_skips_when_regen_final_dir_missing(tmp_path):
    """No regen/final at all -> exit 3."""
    fx = _make_repo(tmp_path)
    shutil.rmtree(fx["final_dir"])
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")

    r = _run(fx["script"])
    assert r.returncode == 3
    assert fx["live_wiki"].read_text() == "# old\n"


def test_skips_when_final_wiki_missing(tmp_path):
    """regen/final exists but no {Object}.md inside -> exit 3."""
    fx = _make_repo(tmp_path)
    # final_dir created by fixture, but we don't write fx["final_wiki"]
    fx["live_wiki"].write_text("# old\n", encoding="utf-8")
    _write_verdict(fx["verdict_path"], 9.5, "PASS")

    r = _run(fx["script"])
    assert r.returncode == 3
