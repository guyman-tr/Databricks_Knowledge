"""
Regression suite for auto_verify.py.

Pins the contracts of the trivially-simple-skip path so we don't accidentally
let a fabricated-Tier-1 wiki sneak past the LLM judge. Each test pairs one
known failure pattern with the expected exit code, then verifies the
synthetic verdict is only written when ALL gates pass.

Exit code reference (from auto_verify.main):
    0 = AUTO-PASS issued (synthetic judge_verdict.json written)
    1 = mechanical check failed (defer to LLM judge)
    2 = triviality gate failed (defer to LLM judge)
    3 = writer outputs missing
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

HARNESS_ROOT = Path(__file__).resolve().parent.parent
AUTO_VERIFY = HARNESS_ROOT / "auto_verify.py"


def _make_ddl(path: Path, schema: str, table: str, columns: list[str]) -> Path:
    body_lines = [f"    [{c}] [int] NOT NULL," for c in columns[:-1]]
    body_lines.append(f"    [{columns[-1]}] [int] NOT NULL")
    txt = (
        f"CREATE TABLE [{schema}].[{table}]\n(\n"
        + "\n".join(body_lines)
        + f"\n)\nWITH (DISTRIBUTION = HASH ([{columns[0]}]));\n"
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(txt, encoding="utf-8")
    return path


def _make_resolution(path: Path, mirrors: list[str], synapse: list[str] = ()) -> Path:
    payload = {
        "candidates_found": len(mirrors) + len(synapse),
        "resolved_synapse": list(synapse),
        "resolved_remote": [],
        "resolved_sps": [],
        "migration_mirrors_discovered": list(mirrors),
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def _make_bundle(path: Path, body: str = "") -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body or "## upstream bundle stub\n", encoding="utf-8")
    return path


def _make_wiki(path: Path, schema: str, table: str, element_rows: list[tuple[str, str]],
               include_all_sections: bool = True, include_footer: bool = True,
               tier_counts: tuple = None) -> Path:
    """Build a minimal wiki .md that the parser will accept.

    element_rows: list of (column_name, description_with_tier_suffix)
    tier_counts:  (t1, t2, t3, t4)  -- written into footer if include_footer
    """
    sections = [
        "## 1. Business Meaning",
        "Stub paragraph.",
        "",
        "## 2. Business Logic",
        "Stub.",
        "",
        "## 3. Operational Profile",
        "Stub.",
        "",
        "## 4. Elements",
        "",
        "| Element | Type | Description |",
        "|---|---|---|",
    ]
    for name, desc in element_rows:
        sections.append(f"| {name} | int | {desc} |")
    sections.append("")
    sections.append("## 5. Lineage Summary")
    sections.append("Stub.")
    sections.append("")
    sections.append("## 6. Relationships")
    sections.append("Stub.")
    sections.append("")
    sections.append("## 7. Sample Queries")
    sections.append("Stub.")
    sections.append("")
    sections.append("## 8. Atlassian Knowledge Inventory")
    sections.append("Stub.")
    sections.append("")
    if include_footer:
        if tier_counts is None:
            t1 = sum(1 for _, d in element_rows if "Tier 1" in d)
            t2 = sum(1 for _, d in element_rows if "Tier 2" in d)
            t3 = sum(1 for _, d in element_rows if "Tier 3" in d)
            t4 = sum(1 for _, d in element_rows if "Tier 4" in d)
        else:
            t1, t2, t3, t4 = tier_counts
        sections.append(
            f"---\nTier1: {t1}  Tier2: {t2}  Tier3: {t3}  Tier4: {t4}\n"
        )
    if not include_all_sections:
        sections = [s for s in sections if not s.startswith("## 7.") and not s.startswith("## 8.")]

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(sections), encoding="utf-8")
    return path


@pytest.fixture
def setup(tmp_path):
    """Build a self-contained fixture tree and return paths + a runner."""
    schema = "BI_DB_dbo"
    obj = "BI_DB_TestObj"
    regen_dir = tmp_path / "regen" / "attempt_1"
    regen_dir.mkdir(parents=True)
    ddl = _make_ddl(tmp_path / "ssdt" / f"{schema}.{obj}.sql", schema, obj,
                    ["A", "B", "C", "D"])
    bundle = _make_bundle(tmp_path / "regen" / "_upstream_bundle.md",
                          "# Upstream wikis\n- Dealing_dbo.Dealing_TestObj\n")
    resolution = _make_resolution(tmp_path / "regen" / "_upstream_resolution.json",
                                  mirrors=["Dealing_dbo.Dealing_TestObj"])

    def run(extra_args: list[str] = None) -> subprocess.CompletedProcess:
        cmd = [sys.executable, str(AUTO_VERIFY),
               "--regen-dir", str(regen_dir),
               "--ddl-path", str(ddl),
               "--upstream-bundle", str(bundle),
               "--upstream-resolution", str(resolution),
               "--object-name", obj,
               "--schema", schema]
        if extra_args:
            cmd += extra_args
        return subprocess.run(cmd, capture_output=True, text=True)

    return {
        "tmp": tmp_path,
        "schema": schema,
        "obj": obj,
        "regen_dir": regen_dir,
        "ddl": ddl,
        "bundle": bundle,
        "resolution": resolution,
        "wiki_path": regen_dir / f"{obj}.md",
        "lineage_path": regen_dir / f"{obj}.lineage.md",
        "verdict_path": regen_dir / "judge_verdict.json",
        "log_path": regen_dir / "auto_verify_log.md",
        "run": run,
    }


# ────────────────────────────── happy path ───────────────────────────────


def test_auto_pass_when_trivial_and_clean(setup):
    """4 cols, all Tier 1 from the migration mirror, footer arithmetic OK,
    every Tier 1 source resolves to the upstream bundle -> AUTO-PASS."""
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"], [
        ("A", "Field A. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("B", "Field B. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("C", "Field C. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("D", "Field D. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
    ])
    setup["lineage_path"].write_text("# stub lineage\n", encoding="utf-8")

    r = setup["run"]()
    assert r.returncode == 0, f"expected AUTO-PASS, got {r.returncode}; log:\n{setup['log_path'].read_text() if setup['log_path'].exists() else '(no log)'}"
    assert setup["verdict_path"].exists()
    verdict = json.loads(setup["verdict_path"].read_text())
    assert verdict["judge_skipped"] is True
    assert verdict["verdict"]["verdict"] == "PASS"
    assert verdict["verdict"]["weighted_score"] == 8.5
    assert verdict["verdict"]["auto_verified"] is True


# ───────────────────────── triviality gate (exit 2) ───────────────────────


def test_skip_when_too_many_columns(setup, tmp_path):
    """6-col DDL exceeds default trivial threshold of 5 -> defer to LLM judge."""
    big_ddl = _make_ddl(tmp_path / "ssdt" / f"{setup['schema']}.BigObj.sql",
                        setup["schema"], "BigObj",
                        ["A", "B", "C", "D", "E", "F"])
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"],
               [(c, f"Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)") for c in "ABCDEF"])
    setup["lineage_path"].write_text("# stub", encoding="utf-8")
    r = setup["run"](["--ddl-path", str(big_ddl)])
    assert r.returncode == 2
    assert not setup["verdict_path"].exists(), "should NOT issue synthetic verdict on triviality skip"


def test_skip_when_no_upstream_marker_in_bundle(setup):
    """Bundle says NO UPSTREAM -> never auto-pass (the fabricated-Tier-1 trap)."""
    setup["bundle"].write_text(
        "# upstream bundle\n**NO UPSTREAM WIKI** could be located.\n",
        encoding="utf-8",
    )
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"], [
        ("A", "Field. (Tier 2 — SP_X)"),
        ("B", "Field. (Tier 2 — SP_X)"),
        ("C", "Field. (Tier 2 — SP_X)"),
        ("D", "Field. (Tier 2 — SP_X)"),
    ])
    setup["lineage_path"].write_text("# stub", encoding="utf-8")
    r = setup["run"]()
    assert r.returncode == 2
    assert not setup["verdict_path"].exists()


def test_skip_when_not_all_passthrough(setup):
    """Mixed Tier 1 + Tier 2 -> defer to LLM (subtle ETL drift outside our scope)."""
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"], [
        ("A", "Field A. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("B", "Field B. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("C", "Computed. (Tier 2 — SP_Compute)"),
        ("D", "Field D. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
    ])
    setup["lineage_path"].write_text("# stub", encoding="utf-8")
    r = setup["run"]()
    assert r.returncode == 2
    assert not setup["verdict_path"].exists()


def test_skip_when_no_upstreams_resolved(setup):
    """_upstream_resolution.json shows zero resolved sources -> skip."""
    _make_resolution(setup["resolution"], mirrors=[])
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"], [
        ("A", "Field. (Tier 1 — somewhere)"),
        ("B", "Field. (Tier 1 — somewhere)"),
        ("C", "Field. (Tier 1 — somewhere)"),
        ("D", "Field. (Tier 1 — somewhere)"),
    ])
    setup["lineage_path"].write_text("# stub", encoding="utf-8")
    r = setup["run"]()
    assert r.returncode == 2
    assert not setup["verdict_path"].exists()


# ───────────────────────── mechanical fail (exit 1) ────────────────────────


def test_fail_when_row_count_mismatches_ddl(setup):
    """4 DDL cols but only 3 element rows -> mechanical fail."""
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"], [
        ("A", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("B", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("C", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
    ])
    setup["lineage_path"].write_text("# stub", encoding="utf-8")
    r = setup["run"]()
    assert r.returncode == 1
    assert not setup["verdict_path"].exists()


def test_fail_when_tier1_source_not_in_upstream(setup):
    """Writer cited Imaginary_dbo.WhereverTable for Tier 1, but it's not in
    the upstream resolution -> the smoking-gun fabricated-Tier-1 case."""
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"], [
        ("A", "Field. (Tier 1 — Imaginary_dbo.WhereverTable)"),
        ("B", "Field. (Tier 1 — Imaginary_dbo.WhereverTable)"),
        ("C", "Field. (Tier 1 — Imaginary_dbo.WhereverTable)"),
        ("D", "Field. (Tier 1 — Imaginary_dbo.WhereverTable)"),
    ])
    setup["lineage_path"].write_text("# stub", encoding="utf-8")
    r = setup["run"]()
    assert r.returncode == 1, f"fabricated Tier 1 must NOT auto-pass; got {r.returncode}"
    assert not setup["verdict_path"].exists()


def test_fail_when_hybrid_tier_label(setup):
    """`(Tier 1 — X, Tier 2 in source: Y)` hybrid -> mechanical fail."""
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"], [
        ("A", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("B", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj, Tier 2 in source: SP_X)"),
        ("C", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("D", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
    ], tier_counts=(4, 0, 0, 0))
    setup["lineage_path"].write_text("# stub", encoding="utf-8")
    r = setup["run"]()
    assert r.returncode == 1
    assert not setup["verdict_path"].exists()


def test_fail_when_section_missing(setup):
    """Wiki missing Section 7 + 8 -> section_presence fails."""
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"], [
        ("A", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("B", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("C", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("D", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
    ], include_all_sections=False)
    setup["lineage_path"].write_text("# stub", encoding="utf-8")
    r = setup["run"]()
    assert r.returncode == 1


def test_fail_when_footer_arithmetic_wrong(setup):
    """Footer claims Tier1=3 but DDL has 4 cols -> mechanical fail."""
    _make_wiki(setup["wiki_path"], setup["schema"], setup["obj"], [
        ("A", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("B", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("C", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
        ("D", "Field. (Tier 1 — Dealing_dbo.Dealing_TestObj)"),
    ], tier_counts=(3, 0, 0, 0))
    setup["lineage_path"].write_text("# stub", encoding="utf-8")
    r = setup["run"]()
    assert r.returncode == 1


# ─────────────────────────── missing files (exit 3) ────────────────────────


def test_missing_writer_outputs_returns_3(setup):
    """No wiki .md / lineage .md -> exit 3 (writer didn't produce, judge will see same)."""
    r = setup["run"]()
    assert r.returncode == 3
    assert not setup["verdict_path"].exists()
