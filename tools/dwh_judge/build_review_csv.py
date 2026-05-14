"""Merge deterministic + LLM verdicts into the central human-review CSV.

Reads:
  knowledge/_dwh_deterministic_violations.csv  (from verify_deterministic.py)
  knowledge/_dwh_llm_judge.csv                 (from llm_judge_prose.py)
  knowledge/_dwh_wiki_claims.csv               (for full description context)

Writes:
  knowledge/_dwh_judge_review.csv

For ``codepoint`` claims the deterministic verifier emits one atomic row per
wrong ``N=Name`` pair (e.g. ``3=RevShare``). That granularity is correct for
the verifier but noisy for human review (a column with 4 wrong codes appears 4
times per file). This script aggregates codepoint atoms per
``(object, column, wiki_file)`` into ONE row that:

* shows the full wiki description text (``wiki_value``)
* shows the corrected description text after applying every code fix
  (``truth_value`` / ``suggested_fix``)
* carries the underlying atomic substitutions in ``substitutions_json`` so the
  applier can still do precise, line-scoped, literal substring replacements.

All other claim types (``type``, ``nullable``, ``default``, ``fk_ref``,
``lineage_tag``, ``description``) pass through as one row per occurrence -- the
extractor already produces them at the right granularity.

Sorting: severity, claim_type, object, column.
"""
from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DET_CSV = REPO / "knowledge" / "_dwh_deterministic_violations.csv"
LLM_CSV = REPO / "knowledge" / "_dwh_llm_judge.csv"
CLAIMS_CSV = REPO / "knowledge" / "_dwh_wiki_claims.csv"
OUT_CSV = REPO / "knowledge" / "_dwh_judge_review.csv"
INFO_CSV = REPO / "knowledge" / "_dwh_judge_informational.csv"

# Claim types where the wiki_value -> truth_value substitution is NOT a clean
# substring patch and the applier must skip with a manual-edit note. These
# rows still show up in the review CSV (aggregated) so the user knows what
# needs fixing, but `apply_approved.py` will not auto-patch them.
NON_APPLIABLE_CLAIM_TYPES = {"type", "nullable", "default", "fk_ref", "lineage_tag"}

REVIEW_FIELDS = [
    "approve_y_n",
    "severity",
    "object",
    "column",
    "claim_type",
    "wiki_value",
    "truth_value",
    "truth_source",
    "wiki_file",
    "wiki_line",
    "suggested_fix",
    "verdict_source",
    "contradicting_fact_verbatim",
    "raw_context",
    "substitutions_json",
]

CLAIM_SORT_ORDER = {
    "codepoint": 0,
    "type": 1,
    "nullable": 2,
    "default": 3,
    "fk_ref": 4,
    "lineage_tag": 5,
    "description": 6,
}


def _read_csv(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8") as f:
        return list(csv.DictReader(f))


def _to_review_row(r: dict) -> dict:
    verdict_source = r.get("verdict_source", "")
    return {
        "approve_y_n": "",
        "severity": r.get("verdict", "WRONG"),
        "object": r.get("object", ""),
        "column": r.get("column", ""),
        "claim_type": r.get("claim_type", ""),
        "wiki_value": r.get("wiki_value", ""),
        "truth_value": r.get("truth_value", ""),
        "truth_source": r.get("truth_source", ""),
        "wiki_file": r.get("wiki_file", ""),
        "wiki_line": r.get("wiki_line", ""),
        "suggested_fix": r.get("truth_value", ""),
        "verdict_source": verdict_source,
        "contradicting_fact_verbatim": r.get("contradicting_fact_verbatim", ""),
        "raw_context": r.get("raw_context", ""),
        "substitutions_json": "",
    }


def _load_descriptions() -> dict[tuple[str, str, str], tuple[str, str]]:
    """(object, column, wiki_file) -> (full_description_text, wiki_line)."""
    out: dict[tuple[str, str, str], tuple[str, str]] = {}
    if not CLAIMS_CSV.exists():
        return out
    with CLAIMS_CSV.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r.get("claim_type") != "description":
                continue
            key = (r["object"], r["column"], r["wiki_file"])
            # Keep the longest variant (alter.sql often has the canonical form).
            existing = out.get(key)
            if existing is None or len(r["claim_value"]) > len(existing[0]):
                out[key] = (r["claim_value"], r.get("wiki_line", ""))
    return out


def _is_informational_default(r: dict) -> bool:
    """A `default` violation where the DDL has NO default but the wiki claims
    one is usually documenting an SP/ETL-populated value, not making a DDL
    claim. These are demoted out of the main review CSV."""
    return (
        r.get("claim_type") == "default"
        and r.get("verdict") == "WRONG"
        and "no default in DDL" in r.get("truth_value", "")
    )


def _aggregate_structural(det_rows: list[dict]) -> list[dict]:
    """Aggregate non-codepoint deterministic violations across files.

    Grouped by (object, column, claim_type, wiki_value, truth_value).
    A column wrongly declared `int` in both .md and dual-target .alter.sql
    yields ONE row, with the three file:line pairs listed together.
    """
    groups: dict[tuple, list[dict]] = defaultdict(list)
    for r in det_rows:
        key = (
            r.get("object", ""),
            r.get("column", ""),
            r.get("claim_type", ""),
            r.get("wiki_value", ""),
            r.get("truth_value", ""),
        )
        groups[key].append(r)

    out: list[dict] = []
    for key, atoms in groups.items():
        obj, col, ct, wiki_value, truth_value = key
        atoms_sorted = sorted(
            atoms,
            key=lambda a: (a.get("wiki_file", ""),
                           int(a.get("wiki_line") or 0)),
        )
        file_lines: list[str] = []
        files_set: list[str] = []
        truth_sources: list[str] = []
        raw_contexts: list[str] = []
        for a in atoms_sorted:
            wf = a.get("wiki_file", "")
            wl = a.get("wiki_line", "")
            if wf and wf not in files_set:
                files_set.append(wf)
            tag = f"{wf}:{wl}" if wf and wl else (wf or wl)
            if tag and tag not in file_lines:
                file_lines.append(tag)
            ts = a.get("truth_source", "")
            if ts and ts not in truth_sources:
                truth_sources.append(ts)
            rc = a.get("raw_context", "")
            if rc and rc not in raw_contexts:
                raw_contexts.append(rc)

        applier_note = (
            "manual-edit"
            if ct in NON_APPLIABLE_CLAIM_TYPES
            else ""
        )
        out.append({
            "approve_y_n": "",
            "severity": "WRONG",
            "object": obj,
            "column": col,
            "claim_type": ct,
            "wiki_value": wiki_value,
            "truth_value": truth_value,
            "truth_source": "; ".join(truth_sources),
            "wiki_file": " | ".join(files_set),
            "wiki_line": " | ".join(file_lines),
            "suggested_fix": truth_value if not applier_note else "",
            "verdict_source": "deterministic",
            "contradicting_fact_verbatim": "",
            "raw_context": " || ".join(raw_contexts)[:600],
            "substitutions_json": json.dumps(
                {"applier_strategy": applier_note,
                 "occurrences": [{"wiki_file": a.get("wiki_file", ""),
                                  "wiki_line": a.get("wiki_line", "")}
                                 for a in atoms_sorted]},
                ensure_ascii=False,
            ) if applier_note else "",
        })
    return out


def _aggregate_codepoints(det_rows: list[dict]) -> tuple[list[dict], list[dict]]:
    """Split deterministic rows into (codepoint_atoms, everything_else) then
    fold codepoint_atoms per (object, column, wiki_file) into single rows that
    show full description text + parsable substitutions_json.
    Returns (aggregated_codepoint_rows, non_codepoint_rows).
    """
    descriptions = _load_descriptions()

    cp_groups: dict[tuple[str, str, str], list[dict]] = defaultdict(list)
    other_rows: list[dict] = []
    for r in det_rows:
        if r.get("claim_type") == "codepoint" and r.get("verdict") == "WRONG":
            cp_groups[(r["object"], r["column"], r["wiki_file"])].append(r)
        else:
            other_rows.append(r)

    aggregated: list[dict] = []
    for (obj, col, wiki_file), atoms in cp_groups.items():
        atoms_sorted = sorted(
            atoms,
            key=lambda a: (a.get("wiki_line", ""), a.get("wiki_value", "")),
        )
        subs = []
        seen_pairs: set[tuple[str, str]] = set()
        wiki_lines: list[str] = []
        truth_sources: list[str] = []
        for a in atoms_sorted:
            old = a.get("wiki_value", "")
            new = a.get("truth_value", "")
            pair = (old, new)
            if pair not in seen_pairs:
                subs.append({"old": old, "new": new})
                seen_pairs.add(pair)
            ln = a.get("wiki_line", "")
            if ln and ln not in wiki_lines:
                wiki_lines.append(ln)
            ts = a.get("truth_source", "")
            if ts and ts not in truth_sources:
                truth_sources.append(ts)

        desc_text, desc_line = descriptions.get(
            (obj, col, wiki_file), ("", wiki_lines[0] if wiki_lines else "")
        )
        if desc_text:
            full_old = desc_text
            full_new = desc_text
            for s in subs:
                if s["old"] and s["old"] in full_new:
                    full_new = full_new.replace(s["old"], s["new"])
        else:
            # Fallback: pipe-joined pairs.
            full_old = " | ".join(s["old"] for s in subs)
            full_new = " | ".join(s["new"] for s in subs)

        aggregated.append({
            "approve_y_n": "",
            "severity": "WRONG",
            "object": obj,
            "column": col,
            "claim_type": "codepoint",
            "wiki_value": full_old,
            "truth_value": full_new,
            "truth_source": "; ".join(truth_sources),
            "wiki_file": wiki_file,
            "wiki_line": ", ".join(wiki_lines),
            "suggested_fix": full_new,
            "verdict_source": "deterministic",
            "contradicting_fact_verbatim": "",
            "raw_context": (
                f"{len(subs)} wrong code(s): "
                + ", ".join(f"{s['old']} -> {s['new']}" for s in subs)
            ),
            "substitutions_json": json.dumps(subs, ensure_ascii=False),
        })
    return aggregated, other_rows


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--include-sloppy", action="store_true",
                    help="Keep SLOPPY rows (defaults off -- only WRONG ships).")
    args = ap.parse_args()

    det = _read_csv(DET_CSV)
    llm = _read_csv(LLM_CSV)
    print(f"deterministic rows: {len(det)}")
    print(f"LLM rows:           {len(llm)}")

    # Split deterministic rows into three buckets.
    det_codepoint = [r for r in det if r.get("claim_type") == "codepoint"
                     and r.get("verdict") == "WRONG"]
    det_informational = [r for r in det if _is_informational_default(r)]
    det_structural = [
        r for r in det
        if r.get("verdict") == "WRONG"
        and r.get("claim_type") != "codepoint"
        and not _is_informational_default(r)
    ]
    cp_aggregated, _unused = _aggregate_codepoints(det_codepoint)
    structural_aggregated = _aggregate_structural(det_structural)

    print(f"  codepoint atoms:     {len(det_codepoint)} -> "
          f"{len(cp_aggregated)} aggregated rows")
    print(f"  structural atoms:    {len(det_structural)} -> "
          f"{len(structural_aggregated)} aggregated rows")
    print(f"  informational rows (demoted): {len(det_informational)}")

    merged: list[dict] = []
    for r in llm:
        sev = r.get("verdict", "")
        if sev != "WRONG" and not args.include_sloppy:
            continue
        merged.append(_to_review_row(r))
    merged.extend(cp_aggregated)
    merged.extend(structural_aggregated)

    def sort_key(row: dict):
        return (
            row.get("severity", ""),
            CLAIM_SORT_ORDER.get(row.get("claim_type", ""), 99),
            row.get("object", ""),
            row.get("column", ""),
            row.get("verdict_source", ""),
        )

    merged.sort(key=sort_key)

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=REVIEW_FIELDS)
        w.writeheader()
        for r in merged:
            w.writerow(r)

    # Informational CSV (demoted default-vs-no-DDL rows). Aggregated the same
    # way so each (object, column) shows up at most once.
    info_aggregated = _aggregate_structural(det_informational)
    with INFO_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=REVIEW_FIELDS)
        w.writeheader()
        for r in info_aggregated:
            w.writerow(r)
    print(f"\nWrote {INFO_CSV.relative_to(REPO)} "
          f"({len(info_aggregated)} demoted informational rows)")

    by_type: dict[str, int] = {}
    by_source: dict[str, int] = {}
    for r in merged:
        by_type[r["claim_type"]] = by_type.get(r["claim_type"], 0) + 1
        by_source[r["verdict_source"]] = by_source.get(r["verdict_source"], 0) + 1

    print(f"\nWrote {OUT_CSV.relative_to(REPO)} ({len(merged)} rows)")
    print("\nBy claim_type:")
    for k in sorted(by_type, key=lambda x: CLAIM_SORT_ORDER.get(x, 99)):
        print(f"  {k:<14} {by_type[k]}")
    print("\nBy verdict_source:")
    for k in sorted(by_source):
        print(f"  {k:<14} {by_source[k]}")
    print("\nReview workflow:")
    print(f"  1. Open {OUT_CSV.relative_to(REPO)} in a spreadsheet.")
    print(f"  2. Sort/filter as you like; the file is sorted by "
          f"(severity, claim_type, object, column).")
    print(f"  3. For each row you want to apply, fill `approve_y_n = Y`.")
    print(f"  4. Run python tools/dwh_judge/apply_approved.py to patch the wikis.")


if __name__ == "__main__":
    main()
