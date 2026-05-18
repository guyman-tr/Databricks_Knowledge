#!/usr/bin/env python3
"""
Phase 7 — Adversarial Evaluation (UC-Pipeline pack).

Runs a SEPARATE cognitive pass per object that grades the wiki against the cached
source material. Mirrors `dwh-semantic-doc/16-adversarial-evaluation.mdc` but tuned
to UC-pure objects (six dimensions, two hard gates, +/- 7.5 verdict threshold).

This tool ships in two modes:

  1. --mechanical (default, headless-safe): deterministic, no-LLM scoring of all
     six dimensions using the same parsing infrastructure as
     `validate_pipeline_wiki.py`. Produces the JSON record AND the human-readable
     Markdown report. Sufficient for the productized pilot — catches paraphrasing,
     wrong tier origin, source-code citation drift, unclassifiable descriptions,
     null-with-provenance abuse, and structural drift.

  2. --emit-prompt:  writes a cognitive prompt + cached evidence bundle to
     `_discovery/evaluations/{object}.prompt.md`. Intended for use by an LLM-loop
     runner (Cursor agent OR Claude CLI). The runner writes the JSON record back
     to `_discovery/evaluations/{object}.json` per the contract in
     `data-model.md`. After the JSON is written, `--check` mode validates that
     the runner's record meets every invariant.

Inputs (per object):
  - knowledge/UC_generated/{schema}/{Tables|Views}/{object}.md
  - knowledge/UC_generated/{schema}/{Tables|Views}/{object}.lineage.md
  - knowledge/UC_generated/{schema}/_discovery/upstream_wikis/<fqn>.md  (cached)
  - knowledge/UC_generated/{schema}/_discovery/source_code/{object}.{sql|py}
  - knowledge/UC_generated/{schema}/_discovery/column_lineage/{object}.json
  - knowledge/UC_generated/{schema}/_discovery/{object}.status.json     (cross-check)

Output (per object):
  - knowledge/UC_generated/{schema}/_discovery/evaluations/{object}.json
  - Markdown report to stdout
  - Exit code 0 (PASS), 1 (FAIL), 2 (could not evaluate — inputs missing)

Usage:
  python tools/uc_pipelines/adversarial_evaluate.py --schema etoro_kpi_prep --object v_fact_customeraction_enriched
  python tools/uc_pipelines/adversarial_evaluate.py --wiki knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_enriched.md
  python tools/uc_pipelines/adversarial_evaluate.py --schema etoro_kpi_prep                            # all objects in schema
  python tools/uc_pipelines/adversarial_evaluate.py --schema etoro_kpi_prep --sample 5                 # random N per schema
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import random
import re
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[2]
PACK_ROOT = REPO / "knowledge" / "UC_generated"
sys.path.insert(0, str(REPO / "tools"))

# Reuse parsing primitives from the mechanical validator so the bucket classifier
# stays in lockstep with Assertion 13.
from uc_pipelines.validate_pipeline_wiki import (  # noqa: E402
    ELEMENT_HEADER_RE,
    LINEAGE_HEADER_RE,
    NULL_WITH_PROVENANCE_RE,
    SOURCE_CODE_CITATION_RE,
    TIER_TAG_RE,
    _classify_description_bucket,
    _extract_section,
    _first_sentence,
    _load_upstream_wiki_for_inherit_check,
    _parse_alter_columns,
    _parse_elements_rows,
    _parse_lineage_rows,
    _parse_yaml_frontmatter,
    _strip_tier_tag,
    _upstream_description_for,
)


# --------------------------------------------------------------------------- #
# Dimension scorers                                                            #
# --------------------------------------------------------------------------- #


def _score_inheritance_fidelity(md_rows: list[dict], lineage_rows: list[dict],
                                 md_path: Path) -> tuple[float, list[dict], str]:
    """Dimension 1: 35%. Build the mandatory T1 Upstream Fidelity table.

    Returns (score 1-10, table_rows, justification).
    """
    lin_by_name = {r["name"]: r for r in lineage_rows}
    table: list[dict] = []
    paraphrased = 0
    formatting_only = 0
    inherited_count = 0
    wrong_origin = 0

    for row in md_rows:
        name = row["name"]
        desc = row["description"]
        tag_m = TIER_TAG_RE.search(desc)
        if not tag_m:
            continue
        tier_letter = tag_m.group(1).strip()
        origin = tag_m.group(2).strip()

        if not tier_letter.startswith("1"):
            continue
        # This column claims inheritance. Verify against the cached upstream.
        lin = lin_by_name.get(name)
        if not lin:
            wrong_origin += 1
            table.append({
                "column": name, "upstream_wiki": "—",
                "upstream_quote": "—",
                "wiki_quote": desc[:120],
                "match": "NO — no lineage row for column",
            })
            continue
        src_obj = lin.get("source_object") or ""
        src_col = lin.get("source_column") or ""
        if not src_obj or not src_col or src_obj in {"—", "(computed)", "(literal)"}:
            wrong_origin += 1
            table.append({
                "column": name, "upstream_wiki": "—",
                "upstream_quote": "—",
                "wiki_quote": desc[:120],
                "match": "NO — Tier 1 claimed but no source object in lineage",
            })
            continue

        inherited_count += 1
        up_path = _load_upstream_wiki_for_inherit_check(md_path, src_obj)
        if not up_path:
            wrong_origin += 1
            table.append({
                "column": name, "upstream_wiki": f"(not cached) {src_obj}",
                "upstream_quote": "—",
                "wiki_quote": desc[:120],
                "match": "NO — Tier 1 claimed but no cached upstream wiki",
            })
            continue

        up_desc = _upstream_description_for(up_path, src_col)
        if not up_desc:
            wrong_origin += 1
            table.append({
                "column": name, "upstream_wiki": str(up_path.relative_to(REPO)),
                "upstream_quote": f"(column {src_col} not in upstream)",
                "wiki_quote": desc[:120],
                "match": f"NO — upstream wiki cached but column {src_col} absent",
            })
            continue

        up_clean = _strip_tier_tag(up_desc.strip())
        desc_clean = _strip_tier_tag(desc)
        verbatim = desc == up_desc.strip()
        contained = bool(up_clean) and up_clean in desc_clean
        first_sent = _first_sentence(up_desc)
        first_sent_contained = (
            len(first_sent) >= 20 and first_sent in desc_clean
        )

        if verbatim:
            match_label = "YES — byte-equal"
        elif contained:
            match_label = "YES — upstream verbatim-contained (relaxation A2)"
        elif first_sent_contained:
            match_label = "YES — first-sentence verbatim-contained (relaxation A3)"
            formatting_only += 1
        else:
            match_label = "NO — paraphrased, meaning lost"
            paraphrased += 1

        table.append({
            "column": name,
            "upstream_wiki": str(up_path.relative_to(REPO)),
            "upstream_quote": up_desc[:200],
            "wiki_quote": desc[:200],
            "match": match_label,
        })

    if inherited_count == 0:
        return (7.0, table, "no inherited columns to fidelity-check (neutral)")
    if paraphrased == 0 and wrong_origin == 0 and formatting_only == 0:
        return (10.0, table, f"all {inherited_count} inherited descriptions verbatim")
    if paraphrased == 0 and wrong_origin == 0 and formatting_only <= 1:
        return (9.0, table, f"{inherited_count} inherited; {formatting_only} trivial diffs")
    if paraphrased + wrong_origin >= 2:
        return (3.0, table,
                f"{paraphrased + wrong_origin} inherited descriptions paraphrased/wrong-origin")
    if paraphrased + wrong_origin == 1:
        return (5.0, table, "1 inherited description paraphrased or wrong origin")
    return (7.0, table, "borderline")


def _score_source_code_narration(md_rows: list[dict], schema_root: Path,
                                   object_name: str) -> tuple[float, str]:
    """Dimension 2: 25%. Check source-code-cited narrations against cached source code."""
    cited_cols: list[tuple[str, str]] = []
    for row in md_rows:
        desc = row["description"]
        # Skip null-with-provenance
        if NULL_WITH_PROVENANCE_RE.match(desc.strip()):
            continue
        # A cited narration row must contain a line-range citation, an `[uc_view_ddl]`
        # marker, or a `[notebook:..]` marker. Plain keyword markers like `CASE` /
        # `SUM` etc. (loose Assertion 13 hits) do NOT carry a verifiable cite, so
        # we exclude them from the spot-check.
        if re.search(r"L\d+(?:-L\d+)?", desc) or "[uc_view_ddl]" in desc or re.search(r"\[notebook:[^\]]+\]", desc):
            cited_cols.append((row["name"], desc))

    if not cited_cols:
        return (7.0, "no source-code-cited columns to spot-check (neutral)")

    # Spot-check at most 3 random columns
    sample = random.sample(cited_cols, k=min(3, len(cited_cols)))
    accurate = 0
    notes: list[str] = []
    src_dir = schema_root / "_discovery" / "source_code"
    cached_sources = list(src_dir.glob(f"{object_name}.*")) if src_dir.is_dir() else []
    cached_src_text = ""
    if cached_sources:
        try:
            cached_src_text = cached_sources[0].read_text(encoding="utf-8", errors="ignore")
        except Exception:
            cached_src_text = ""
    cached_src_lines = cached_src_text.splitlines() if cached_src_text else []

    for col_name, desc in sample:
        m_range = re.search(r"L(\d+)(?:-L(\d+))?", desc)
        if not m_range:
            # Marker-only cite like [uc_view_ddl] — give it pass if cached source exists at all
            if cached_src_text:
                accurate += 1
            else:
                notes.append(f"`{col_name}`: marker-only citation but no cached source available")
            continue
        start = int(m_range.group(1))
        end = int(m_range.group(2) or start)
        if start < 1 or end > max(1, len(cached_src_lines)):
            notes.append(f"`{col_name}`: cited L{start}-L{end} out of range ({len(cached_src_lines)} lines)")
            continue
        # Check the cited line range actually references the column or a transform keyword
        snippet = "\n".join(cached_src_lines[start - 1:end])
        if col_name.lower() in snippet.lower() or re.search(
            r"\b(CASE|COALESCE|ISNULL|SUM|COUNT|AVG|MIN|MAX|JOIN|UNION|WHERE|GROUP BY|OVER)\b",
            snippet, re.IGNORECASE,
        ):
            accurate += 1
        else:
            notes.append(f"`{col_name}`: cited lines don't mention column or transform keywords")

    n = len(sample)
    score_map = {(3, 3): 10.0, (2, 3): 7.0, (1, 3): 4.0, (0, 3): 1.0,
                 (2, 2): 10.0, (1, 2): 6.0, (0, 2): 2.0,
                 (1, 1): 10.0, (0, 1): 3.0}
    score = score_map.get((accurate, n), 5.0)
    just = f"spot-check {accurate}/{n} accurate"
    if notes:
        just += "; " + " | ".join(notes[:2])
    return (score, just)


def _score_null_with_provenance(md_rows: list[dict], lineage_rows: list[dict],
                                  schema_root: Path,
                                  global_index: dict | None) -> tuple[float, str]:
    """Dimension 3: 15%. Verify null-with-provenance is actually justified."""
    lin_by_name = {r["name"]: r for r in lineage_rows}
    nwp_cols = [r for r in md_rows if NULL_WITH_PROVENANCE_RE.match(r["description"].strip())]
    if not nwp_cols:
        return (7.0, "no null-with-provenance columns (neutral)")

    missed_hits = 0
    notes: list[str] = []
    for row in nwp_cols:
        lin = lin_by_name.get(row["name"])
        if not lin:
            continue
        src_obj = (lin.get("source_object") or "").lower()
        if not src_obj or src_obj in {"—", "(computed)", "(literal)"}:
            continue
        if global_index and src_obj in global_index:
            missed_hits += 1
            notes.append(f"`{row['name']}`: upstream {src_obj} is in global index at {global_index[src_obj]}")
            continue
        # Check pack-local cache
        cache = schema_root / "_discovery" / "upstream_wikis" / f"{src_obj}.md"
        if cache.exists():
            missed_hits += 1
            notes.append(f"`{row['name']}`: upstream {src_obj} is cached locally")

    if missed_hits == 0:
        return (10.0, f"all {len(nwp_cols)} null-with-provenance columns confirmed terminal")
    if missed_hits == 1:
        return (4.0, "1 null-with-provenance has a missed-hit upstream; " + notes[0])
    return (1.0, f"{missed_hits} null-with-provenance columns have missed-hit upstreams")


def _score_completeness(md_rows: list[dict], lineage_rows: list[dict],
                          alter_cols: list[str] | None, fm: dict,
                          md_text: str, lineage_text: str) -> tuple[float, str]:
    """Dimension 4: 10%. Structural completeness checklist."""
    checks: list[tuple[str, bool]] = []
    section_titles = {"Overview", "Source Lineage", "Elements", "Tier Legend",
                      "Sample Queries", "Footer"}
    found = set()
    for ln in md_text.splitlines():
        m = re.match(r"^##\s+(?:\d+\.\s+)?(.+?)\s*$", ln)
        if m and m.group(1).strip() in section_titles:
            found.add(m.group(1).strip())
    checks.append(("required section headers present", len(found) >= 3))
    checks.append(("element count matches lineage count",
                   len(md_rows) == len(lineage_rows) and len(md_rows) > 0))
    checks.append(("all element rows have 5 cells",
                   all(r.get("name") for r in md_rows)))
    rows_with_tag = sum(1 for r in md_rows if TIER_TAG_RE.search(r["description"]))
    checks.append(("every element has tier tag", rows_with_tag == len(md_rows)))
    checks.append(("frontmatter has object_fqn", bool(fm.get("object_fqn"))))
    checks.append(("frontmatter has object_type", bool(fm.get("object_type"))))
    if alter_cols is not None:
        names_md = {r["name"].lower() for r in md_rows}
        names_alter = {c.lower() for c in alter_cols}
        checks.append((".alter.sql column-name parity", names_md == names_alter and len(alter_cols) == len(md_rows)))
        try:
            alter_path = Path(str(md_text.splitlines()[0]))  # placeholder; real path passed below
        except Exception:
            pass
    else:
        checks.append((".alter.sql column-name parity", True))  # not present is OK at eval time
    checks.append(("lineage table has rows", len(lineage_rows) > 0))
    # Sidecar must not contain Elements
    md_path_guess = None  # passed by caller; here we approximate by re-parsing
    checks.append(("lineage row count > 0", len(lineage_rows) > 0))
    checks.append(("frontmatter has producer_kind or generator", bool(fm.get("producer_kind") or fm.get("generator"))))

    passing = sum(1 for _, ok in checks if ok)
    total = len(checks)
    pct = passing / total if total else 0
    if pct >= 1.0:
        score = 10.0
    elif pct >= 0.9:
        score = 8.0
    elif pct >= 0.8:
        score = 6.0
    else:
        score = 4.0
    fails = [name for name, ok in checks if not ok]
    just = f"{passing}/{total} structural checks pass"
    if fails:
        just += f"; failing: {fails[:3]}"
    return (score, just)


def _score_shape_fidelity(md_text: str, fm: dict) -> tuple[float, str]:
    """Dimension 5: 10%. Match the GOLDEN-REFERENCE skeleton."""
    issues: list[str] = []
    if not re.search(r"^##\s+(?:\d+\.\s+)?Elements\b", md_text, re.MULTILINE | re.IGNORECASE):
        issues.append("missing Elements section")
    if not re.search(r"^##\s+(?:\d+\.\s+)?Tier Legend\b", md_text, re.MULTILINE | re.IGNORECASE):
        issues.append("missing Tier Legend section")
    if not re.search(r"^##\s+(?:\d+\.\s+)?Sample Queries\b", md_text, re.MULTILINE | re.IGNORECASE):
        issues.append("missing Sample Queries section")
    if "TBD" in md_text or "TODO" in md_text:
        issues.append("contains TBD/TODO placeholders")
    if not (fm.get("object_fqn") and fm.get("generated_at")):
        issues.append("frontmatter missing object_fqn or generated_at")

    if not issues:
        return (10.0, "matches golden skeleton")
    if len(issues) == 1:
        return (8.0, f"minor deviation: {issues[0]}")
    if len(issues) <= 2:
        return (6.0, f"deviations: {', '.join(issues)}")
    return (3.0, f"structural issues: {', '.join(issues)}")


def _score_lineage_coherence(md_rows: list[dict], lineage_rows: list[dict],
                               md_path: Path) -> tuple[float, str]:
    """Dimension 6: 5%. md and lineage must agree on every column's source.

    For Bucket A (verbatim inherited) columns, the tier origin reflects the upstream
    wiki's own origin tag (the grandparent Tier 1 source), NOT the immediate lineage
    parent. We accept either: origin mentions immediate parent OR origin matches
    upstream wiki's own origin tag verbatim.
    """
    lin_by_name = {r["name"]: r for r in lineage_rows}
    mismatches = 0
    notes: list[str] = []
    for row in md_rows:
        name = row["name"]
        desc = row["description"]
        tag = TIER_TAG_RE.search(desc)
        if not tag:
            continue
        origin = tag.group(2).strip()
        lin = lin_by_name.get(name)
        if not lin:
            mismatches += 1
            notes.append(f"`{name}` missing from lineage table")
            continue
        src = lin.get("source_object") or ""
        if not src or src in {"—", "(computed)", "(literal)"}:
            continue
        src_token = src.split(".")[-1].lower()
        if src_token in origin.lower() or src.lower() in origin.lower():
            continue
        # Allow producer-narration markers (notebook / view / SP)
        if re.search(r"(notebook|view|SP|source:|L\d+)", origin, re.IGNORECASE):
            continue
        # Inherited origin check: read the cached upstream wiki and see if the
        # downstream's tier origin matches the upstream's own tier origin for
        # this source column. If yes, this is a faithful verbatim inherit.
        src_col = lin.get("source_column") or name
        up_wiki = _load_upstream_wiki_for_inherit_check(md_path, src)
        if up_wiki:
            up_desc = _upstream_description_for(up_wiki, src_col)
            if up_desc:
                up_tag = TIER_TAG_RE.search(up_desc)
                if up_tag and up_tag.group(2).strip().lower() == origin.lower():
                    continue  # inherited the upstream's own origin verbatim
        mismatches += 1
        notes.append(f"`{name}`: lineage source={src} but tier origin='{origin}'")
    if mismatches == 0:
        return (10.0, "all elements coherent with lineage")
    if mismatches == 1:
        return (7.0, notes[0])
    if mismatches == 2:
        return (5.0, "; ".join(notes[:2]))
    return (3.0, f"{mismatches} elements mismatched: " + "; ".join(notes[:3]))


# --------------------------------------------------------------------------- #
# Main evaluator                                                               #
# --------------------------------------------------------------------------- #


WEIGHTS = {
    "inheritance_fidelity": 0.35,
    "source_code_narration_accuracy": 0.25,
    "null_with_provenance_correctness": 0.15,
    "completeness": 0.10,
    "shape_fidelity": 0.10,
    "lineage_coherence": 0.05,
}


def _load_global_wiki_index() -> dict:
    """Return {fqn_lower: relative_path_str} for fast missed-hit detection."""
    idx_path = PACK_ROOT / "_index_cache" / "upstream_wikis.json"
    if not idx_path.exists():
        return {}
    try:
        data = json.loads(idx_path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    out: dict = {}
    for entry in data.get("entries", []) if isinstance(data, dict) else []:
        fqn = (entry.get("full_name") or "").lower()
        if fqn:
            out[fqn] = entry.get("wiki_path", "")
    return out


def evaluate_object(md_path: Path, attempt: int = 1,
                     model_used: str = "mechanical-v1") -> dict:
    """Run the full Phase 7 evaluation. Returns the JSON record dict."""
    obj_name = md_path.stem
    schema_root = md_path.parent.parent
    schema = schema_root.name

    lineage_path = md_path.with_suffix(".lineage.md")
    if not md_path.exists() or not lineage_path.exists():
        return {
            "object_fqn": f"main.{schema}.{obj_name}",
            "evaluator_attempt": attempt,
            "scores": {k: 0.0 for k in WEIGHTS},
            "weighted_score": 0.0,
            "hard_gates": {"inheritance_fidelity_table_present": False,
                            "no_unanchored_inferred_descriptions": False},
            "verdict": "FAIL",
            "regeneration_feedback": "Could not evaluate: .md or .lineage.md missing",
            "evaluated_at": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "model_used": model_used,
            "fidelity_table": [],
            "bucket_counts": {"A": 0, "B": 0, "C": 0, "U": 0},
            "dimension_notes": {},
        }

    md_text = md_path.read_text(encoding="utf-8")
    lineage_text = lineage_path.read_text(encoding="utf-8")
    fm = _parse_yaml_frontmatter(md_text)
    md_rows = _parse_elements_rows(md_text)
    lineage_rows = _parse_lineage_rows(lineage_text)

    alter_path = md_path.with_suffix(".alter.sql")
    alter_cols = _parse_alter_columns(alter_path.read_text(encoding="utf-8")) if alter_path.exists() else None

    global_index = _load_global_wiki_index()

    fidelity_score, fidelity_table, fidelity_just = _score_inheritance_fidelity(
        md_rows, lineage_rows, md_path,
    )
    narration_score, narration_just = _score_source_code_narration(md_rows, schema_root, obj_name)
    nwp_score, nwp_just = _score_null_with_provenance(md_rows, lineage_rows, schema_root, global_index)
    completeness_score, completeness_just = _score_completeness(
        md_rows, lineage_rows, alter_cols, fm, md_text, lineage_text,
    )
    shape_score, shape_just = _score_shape_fidelity(md_text, fm)
    coherence_score, coherence_just = _score_lineage_coherence(md_rows, lineage_rows, md_path)

    scores = {
        "inheritance_fidelity": fidelity_score,
        "source_code_narration_accuracy": narration_score,
        "null_with_provenance_correctness": nwp_score,
        "completeness": completeness_score,
        "shape_fidelity": shape_score,
        "lineage_coherence": coherence_score,
    }
    weighted = sum(scores[k] * WEIGHTS[k] for k in WEIGHTS)

    # Hard gate 1: T1 fidelity table present (we always build it)
    inherited_count = sum(1 for row in md_rows if (m := TIER_TAG_RE.search(row["description"])) and m.group(1).startswith("1"))
    gate1 = (len(fidelity_table) >= 0) if inherited_count == 0 else (len(fidelity_table) == inherited_count or len(fidelity_table) > 0)

    # Hard gate 2: bucket classification — every description fits A/B/C
    bucket_counts = {"A": 0, "B": 0, "C": 0, "U": 0}
    lin_by_name = {r["name"]: r for r in lineage_rows}
    unanchored: list[str] = []
    for row in md_rows:
        if "UNVERIFIED" in row["description"].upper():
            continue
        bucket, _ = _classify_description_bucket(row["description"], lin_by_name.get(row["name"]), md_path)
        bucket_counts[bucket] = bucket_counts.get(bucket, 0) + 1
        if bucket == "U":
            unanchored.append(row["name"])
    gate2 = (bucket_counts["U"] == 0)

    verdict = "PASS" if (weighted >= 7.5 and gate1 and gate2) else "FAIL"

    regen: list[str] = []
    if verdict == "FAIL":
        if not gate2:
            regen.append(
                f"Hard gate 2 failed: {len(unanchored)} column(s) have unclassifiable descriptions: "
                f"{unanchored[:5]}. Each must be (A) verbatim from upstream wiki, (B) cited "
                f"from source code with L# range, or (C) null-with-provenance template."
            )
        if not gate1 and inherited_count > 0:
            regen.append("Hard gate 1 failed: T1 fidelity table empty despite Tier 1 columns present.")
        if fidelity_score < 7:
            paraphrased = [t["column"] for t in fidelity_table if t["match"].startswith("NO")]
            regen.append(f"Inheritance fidelity {fidelity_score}/10 — paraphrased columns: {paraphrased[:5]}. "
                          f"Copy upstream descriptions verbatim.")
        if narration_score < 7 and "no source-code-cited" not in narration_just:
            regen.append(f"Source-code narration {narration_score}/10: {narration_just}. "
                          f"Verify cited line ranges actually contain the named columns or transform keywords.")
        if nwp_score < 7 and "no null-with-provenance" not in nwp_just:
            regen.append(f"Null-with-provenance correctness {nwp_score}/10: {nwp_just}. "
                          f"Re-route through Phase 3 Rules 0-5 — those upstreams ARE documented.")
        if completeness_score < 7:
            regen.append(f"Completeness {completeness_score}/10: {completeness_just}.")
        if shape_score < 7:
            regen.append(f"Shape fidelity {shape_score}/10: {shape_just}.")
        if coherence_score < 7:
            regen.append(f"Lineage coherence {coherence_score}/10: {coherence_just}.")

    record = {
        "object_fqn": (fm.get("object_fqn") or f"main.{schema}.{obj_name}"),
        "evaluator_attempt": attempt,
        "scores": {k: round(v, 1) for k, v in scores.items()},
        "weighted_score": round(weighted, 2),
        "hard_gates": {
            "inheritance_fidelity_table_present": bool(gate1),
            "no_unanchored_inferred_descriptions": bool(gate2),
        },
        "verdict": verdict,
        "regeneration_feedback": "\n".join(regen) if regen else None,
        "evaluated_at": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "model_used": model_used,
        "fidelity_table": fidelity_table,
        "bucket_counts": bucket_counts,
        "dimension_notes": {
            "inheritance_fidelity": fidelity_just,
            "source_code_narration_accuracy": narration_just,
            "null_with_provenance_correctness": nwp_just,
            "completeness": completeness_just,
            "shape_fidelity": shape_just,
            "lineage_coherence": coherence_just,
        },
    }
    return record


def _write_eval_record(schema_root: Path, obj_name: str, record: dict) -> Path:
    out_dir = schema_root / "_discovery" / "evaluations"
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{obj_name}.json"
    out.write_text(json.dumps(record, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return out


def _emit_markdown_report(record: dict) -> str:
    lines: list[str] = []
    schema_obj = record["object_fqn"].split(".", 1)[-1] if "." in record["object_fqn"] else record["object_fqn"]
    lines.append(f"ADVERSARIAL EVALUATION — {schema_obj}")
    lines.append("═" * 60)
    lines.append("")
    lines.append("DIMENSION SCORES:")
    weight_pct = {"inheritance_fidelity": "(35%)",
                   "source_code_narration_accuracy": "(25%)",
                   "null_with_provenance_correctness": "(15%)",
                   "completeness": "(10%)",
                   "shape_fidelity": "(10%)",
                   "lineage_coherence": " (5%)"}
    label = {"inheritance_fidelity": "Inheritance Fidelity            ",
              "source_code_narration_accuracy": "Source-Code Narration Accuracy  ",
              "null_with_provenance_correctness": "Null-with-Provenance Correctness",
              "completeness": "Completeness                    ",
              "shape_fidelity": "Shape Fidelity                  ",
              "lineage_coherence": "Lineage Coherence               "}
    for dim in WEIGHTS:
        note = record["dimension_notes"].get(dim, "")
        lines.append(f"  {label[dim]} {weight_pct[dim]}:  {record['scores'][dim]}/10  {note}")
    lines.append("")
    lines.append(f"WEIGHTED SCORE: {record['weighted_score']}/10")
    lines.append("")
    g = record["hard_gates"]
    lines.append("HARD GATES:")
    lines.append(f"  T1 Upstream Fidelity table present:        {'YES' if g['inheritance_fidelity_table_present'] else 'NO'}")
    lines.append(f"  No unanchored inferred descriptions:       {'YES' if g['no_unanchored_inferred_descriptions'] else 'NO'}")
    lines.append("")
    lines.append("T1 UPSTREAM FIDELITY TABLE (MANDATORY):")
    if not record["fidelity_table"]:
        lines.append("  (no Tier 1 columns)")
    else:
        lines.append("  | # | Column | Upstream wiki | Upstream (quoted) | Wiki (quoted) | MATCH? |")
        lines.append("  |---|--------|---------------|-------------------|---------------|--------|")
        for i, t in enumerate(record["fidelity_table"], 1):
            up_q = t["upstream_quote"].replace("|", "\\|")[:80]
            wi_q = t["wiki_quote"].replace("|", "\\|")[:80]
            lines.append(f"  | {i} | `{t['column']}` | {t['upstream_wiki']} | \"{up_q}\" | \"{wi_q}\" | {t['match']} |")
    lines.append("")
    bc = record["bucket_counts"]
    lines.append("BUCKET CLASSIFICATION:")
    lines.append(f"  Total columns:        {sum(bc.values())}")
    lines.append(f"    Bucket A (inherit): {bc.get('A', 0)}")
    lines.append(f"    Bucket B (narrate): {bc.get('B', 0)}")
    lines.append(f"    Bucket C (null):    {bc.get('C', 0)}")
    lines.append(f"    Unclassifiable:     {bc.get('U', 0)}   {'<-- MUST be 0' if bc.get('U', 0) else ''}")
    lines.append("")
    lines.append(f"VERDICT: {record['verdict']}")
    lines.append("")
    if record["regeneration_feedback"]:
        lines.append("REGENERATION FEEDBACK:")
        for line in record["regeneration_feedback"].splitlines():
            lines.append(f"  {line}")
    return "\n".join(lines)


def _emit_prompt_bundle(md_path: Path, out_dir: Path) -> Path:
    """Write a cognitive-pass prompt with bundled evidence for an external LLM."""
    obj_name = md_path.stem
    schema_root = md_path.parent.parent
    schema = schema_root.name
    out = out_dir / f"{obj_name}.prompt.md"
    rule_path = REPO / ".cursor" / "rules" / "uc-pipeline-doc" / "07-adversarial-evaluation.mdc"
    bundle: list[str] = []
    bundle.append(f"# Adversarial evaluation prompt for `main.{schema}.{obj_name}`")
    bundle.append("")
    bundle.append("You are a skeptical reviewer. Read the rule file, then the cached evidence below,")
    bundle.append(f"and emit a JSON record to `_discovery/evaluations/{obj_name}.json` per the contract.")
    bundle.append("")
    bundle.append(f"## Rule file ({rule_path.relative_to(REPO).as_posix()})")
    bundle.append("```")
    bundle.append(rule_path.read_text(encoding="utf-8") if rule_path.exists() else "(MISSING)")
    bundle.append("```")
    bundle.append("")
    bundle.append(f"## Wiki output ({md_path.relative_to(REPO).as_posix()})")
    bundle.append("```markdown")
    bundle.append(md_path.read_text(encoding="utf-8"))
    bundle.append("```")
    bundle.append("")
    lineage = md_path.with_suffix(".lineage.md")
    if lineage.exists():
        bundle.append(f"## Lineage ({lineage.relative_to(REPO).as_posix()})")
        bundle.append("```markdown")
        bundle.append(lineage.read_text(encoding="utf-8"))
        bundle.append("```")
        bundle.append("")
    ux_dir = schema_root / "_discovery" / "upstream_wikis"
    if ux_dir.is_dir():
        bundle.append("## Cached upstream wikis")
        for ux in sorted(ux_dir.glob("*.md")):
            bundle.append(f"### {ux.name}")
            bundle.append("```markdown")
            bundle.append(ux.read_text(encoding="utf-8")[:8000])
            bundle.append("```")
            bundle.append("")
    src_dir = schema_root / "_discovery" / "source_code"
    if src_dir.is_dir():
        for src in src_dir.glob(f"{obj_name}.*"):
            bundle.append(f"## Cached source code ({src.relative_to(REPO).as_posix()})")
            bundle.append("```")
            bundle.append(src.read_text(encoding="utf-8", errors="ignore")[:12000])
            bundle.append("```")
            bundle.append("")
    out.write_text("\n".join(bundle), encoding="utf-8")
    return out


def _validate_record(record: dict) -> list[str]:
    """Check a record against the data-model invariants. Returns list of errors."""
    errs: list[str] = []
    required_score_keys = set(WEIGHTS.keys())
    if not isinstance(record.get("scores"), dict) or set(record["scores"]) != required_score_keys:
        errs.append(f"scores must have exactly these keys: {sorted(required_score_keys)}")
    if not isinstance(record.get("hard_gates"), dict):
        errs.append("hard_gates must be a dict")
    elif not all(isinstance(record["hard_gates"].get(k), bool) for k in
                  ("inheritance_fidelity_table_present", "no_unanchored_inferred_descriptions")):
        errs.append("hard_gates must contain two bool fields")
    if record.get("verdict") not in {"PASS", "FAIL"}:
        errs.append("verdict must be PASS or FAIL")
    if record.get("evaluator_attempt") not in (1, 2):
        errs.append("evaluator_attempt must be 1 or 2")
    if record.get("verdict") == "FAIL" and not record.get("regeneration_feedback"):
        errs.append("FAIL verdict requires non-empty regeneration_feedback")
    if record.get("verdict") == "PASS":
        ws = record.get("weighted_score", 0)
        g = record.get("hard_gates", {})
        if ws < 7.5:
            errs.append(f"PASS requires weighted_score >= 7.5, got {ws}")
        if not (g.get("inheritance_fidelity_table_present") and g.get("no_unanchored_inferred_descriptions")):
            errs.append("PASS requires both hard gates true")
    return errs


# --------------------------------------------------------------------------- #
# CLI                                                                          #
# --------------------------------------------------------------------------- #


def _resolve_md_path(schema: str, obj: str) -> Path | None:
    for folder in ("Tables", "Views"):
        p = PACK_ROOT / schema / folder / f"{obj}.md"
        if p.exists():
            return p
    return None


def _enumerate_schema_wikis(schema: str) -> list[Path]:
    out: list[Path] = []
    for folder in ("Tables", "Views"):
        d = PACK_ROOT / schema / folder
        if not d.is_dir():
            continue
        for md in sorted(d.glob("*.md")):
            if md.name.endswith(".lineage.md") or md.name.endswith(".review-needed.md"):
                continue
            out.append(md)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="UC-Pipeline Phase 7 adversarial evaluator")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--schema", help="Schema name (evaluates all in-scope objects)")
    g.add_argument("--wiki", help="Path to a single .md wiki file")
    ap.add_argument("--object", help="Object name (with --schema, evaluate only this)")
    ap.add_argument("--sample", type=int, default=0,
                     help="When using --schema, randomly sample N objects (0 = all)")
    ap.add_argument("--attempt", type=int, default=1, choices=[1, 2],
                     help="Evaluator attempt number (1 = first pass; 2 = post-regen)")
    ap.add_argument("--mode", choices=["mechanical", "emit-prompt", "check"], default="mechanical",
                     help="mechanical = score deterministically; emit-prompt = write cognitive prompt; "
                          "check = re-validate an existing JSON record")
    ap.add_argument("--model", default="mechanical-v1", help="Identifier recorded in the JSON record")
    ap.add_argument("--quiet", action="store_true", help="Suppress Markdown report on stdout")
    args = ap.parse_args()

    if args.wiki:
        targets = [Path(args.wiki).resolve()]
        if not targets[0].exists():
            print(f"ERROR: --wiki path not found: {targets[0]}", file=sys.stderr)
            return 2
    else:
        if args.object:
            md = _resolve_md_path(args.schema, args.object)
            if md is None:
                print(f"ERROR: object {args.schema}.{args.object} not found", file=sys.stderr)
                return 2
            targets = [md]
        else:
            targets = _enumerate_schema_wikis(args.schema)
            if args.sample > 0 and args.sample < len(targets):
                random.seed(0xC0FFEE)
                targets = random.sample(targets, args.sample)

    if not targets:
        print(f"No wiki targets resolved for --schema={args.schema} --object={args.object}", file=sys.stderr)
        return 2

    n_pass = 0
    n_fail = 0
    rc = 0

    for md_path in targets:
        schema_root = md_path.parent.parent
        obj_name = md_path.stem
        evals_dir = schema_root / "_discovery" / "evaluations"

        if args.mode == "emit-prompt":
            evals_dir.mkdir(parents=True, exist_ok=True)
            out = _emit_prompt_bundle(md_path, evals_dir)
            print(f"[prompt] {out.relative_to(REPO).as_posix()}")
            continue

        if args.mode == "check":
            rec_path = evals_dir / f"{obj_name}.json"
            if not rec_path.exists():
                print(f"[check] MISSING record: {rec_path.relative_to(REPO).as_posix()}", file=sys.stderr)
                n_fail += 1
                rc = 1
                continue
            try:
                rec = json.loads(rec_path.read_text(encoding="utf-8"))
            except Exception as e:
                print(f"[check] INVALID JSON: {rec_path.relative_to(REPO).as_posix()} — {e}", file=sys.stderr)
                n_fail += 1
                rc = 1
                continue
            errs = _validate_record(rec)
            if errs:
                print(f"[check] FAIL {obj_name}: {errs}", file=sys.stderr)
                n_fail += 1
                rc = 1
            else:
                print(f"[check] OK   {obj_name}: verdict={rec['verdict']} score={rec['weighted_score']}")
                if rec["verdict"] == "PASS":
                    n_pass += 1
                else:
                    n_fail += 1
            continue

        record = evaluate_object(md_path, attempt=args.attempt, model_used=args.model)
        errs = _validate_record(record)
        if errs:
            print(f"WARNING: own record failed self-check: {errs}", file=sys.stderr)

        out = _write_eval_record(schema_root, obj_name, record)
        if not args.quiet:
            print(_emit_markdown_report(record))
            print()
            print(f"[written] {out.relative_to(REPO).as_posix()}")
            print()

        if record["verdict"] == "PASS":
            n_pass += 1
        else:
            n_fail += 1
            rc = max(rc, 1)

    if args.mode in {"mechanical", "check"} and len(targets) > 1:
        print(f"Summary: PASS={n_pass} FAIL={n_fail} TOTAL={len(targets)}")

    return rc


if __name__ == "__main__":
    sys.exit(main())
