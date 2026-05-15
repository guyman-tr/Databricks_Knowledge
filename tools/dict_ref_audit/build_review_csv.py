"""Aggregate validated candidates into the user-facing review CSV.

One row per `(column_name, target_dim)` decision. Each row lists how many
wiki files are affected and a concrete suggested replacement (verbose enum
stripped, `FK to Dim_X.` injected) using one example as the template.

The user then marks each row APPROVE / SKIP / MODIFY (with optional
`override_text` for MODIFY) and feeds it to apply_approved.py.
"""
from __future__ import annotations

import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def _strip_enum_block(desc: str, enum_block: str, target_dim: str) -> str:
    """Strip the verbose enum slice and inject `FK to <target_dim>.`."""
    if not enum_block:
        return desc
    idx = desc.find(enum_block)
    if idx < 0:
        return desc
    before = desc[:idx].rstrip()
    after = desc[idx + len(enum_block):].lstrip()
    # Remove a leading delimiter from `after` (the comma/semicolon that
    # separated the enum from the next sentence).
    after = re.sub(r"^[,;:.\s]+", "", after)
    # Trim trailing junk from `before` (e.g. "Values:" or "Codes:")
    before = re.sub(r"(?:\s*[:.]?\s*(?:Values?|Codes?|Mapping|Enum|Lookup|Where|Codepoints?))\s*$", "", before, flags=re.IGNORECASE).rstrip()
    # Also drop trailing dangling delimiters/whitespace
    before = re.sub(r"[\s,;:.]*$", "", before)
    fk_ref = ""
    if target_dim:
        if target_dim.startswith("Dim_"):
            fk_ref = f"FK to {target_dim}."
        elif target_dim.startswith("Dictionary."):
            fk_ref = f"FK to {target_dim}."
        else:
            fk_ref = f"FK to {target_dim}."
    # Reconstruct: <before>. <fk_ref> <after>
    parts = []
    if before:
        parts.append(before)
        if not before.endswith("."):
            parts.append(".")
        parts.append(" ")
    if fk_ref:
        parts.append(fk_ref)
        parts.append(" ")
    if after:
        parts.append(after)
    out = "".join(parts)
    out = re.sub(r"\s+", " ", out).strip()
    # Cleanup duplicate periods, dangling commas
    out = re.sub(r"\.\s*\.", ".", out)
    out = re.sub(r"\s+,", ",", out)
    out = re.sub(r"\s+\.", ".", out)
    return out


def main() -> int:
    src = REPO / "knowledge" / "_dict_ref_validated.csv"
    out = REPO / "knowledge" / "_dict_ref_audit_review.csv"
    rows_in = list(csv.DictReader(src.open(encoding="utf-8")))

    groups: dict[tuple, list] = defaultdict(list)
    for r in rows_in:
        key = (r["column_name"], r["target_dim"])
        groups[key].append(r)

    # Build canonical-aware status priority for aggregation (worst wins).
    STATUS_RANK = {
        "delusional": 0,
        "mismatched_labels": 1,
        "partial": 2,
        "unverifiable": 3,
        "no_target": 4,
        "clean": 5,
    }

    out_rows = []
    for (col, tgt), members in sorted(groups.items()):
        rep = members[0]
        # Pick the worst (lowest-rank) status
        agg_status = min((m["validation_status"] for m in members),
                          key=lambda s: STATUS_RANK.get(s, 99))

        # Build a representative suggested replacement.
        if tgt:
            suggested = _strip_enum_block(
                rep["current_desc"], rep["enum_block"], tgt)
        else:
            suggested = "(no_target - manual decision required; leave as-is or rewrite)"

        affected = [
            {"wiki_md": m["wiki_md"],
             "line_no": int(m["line_no"]),
             "claimed_pairs": m["claimed_pairs"]}
            for m in members
        ]

        # Aggregate delusional / mismatched / missing across all members
        all_delusional: list[int] = []
        all_mismatched = []
        all_missing: list[int] = []
        for m in members:
            try:
                all_delusional.extend(json.loads(m["delusional_ids"]))
            except (ValueError, KeyError):
                pass
            try:
                all_mismatched.extend(json.loads(m["mismatched_labels"]))
            except (ValueError, KeyError):
                pass
            try:
                all_missing.extend(json.loads(m["missing_ids"]))
            except (ValueError, KeyError):
                pass
        all_delusional = sorted(set(all_delusional))
        all_missing = sorted(set(all_missing))

        decision_id = f"{col}__{tgt}" if tgt else f"{col}__NO_TARGET"

        out_rows.append({
            "decision_id": decision_id,
            "column_name": col,
            "target_dim": tgt,
            "validation_status": agg_status,
            "n_affected": len(members),
            "claimed_enum_block_example": rep["enum_block"][:500],
            "current_desc_example": rep["current_desc"][:800],
            "suggested_replacement": suggested[:800],
            "delusional_ids": json.dumps(all_delusional),
            "mismatched_labels": json.dumps(all_mismatched, ensure_ascii=False)[:600],
            "missing_ids_from_canonical": json.dumps(all_missing),
            "target_dim_md": rep["target_dim_md"],
            "resolution_strategy": rep["resolution_strategy"],
            "affected_targets_json": json.dumps(affected, ensure_ascii=False),
            "notes": "",
            "decision": "",
            "override_text": "",
        })

    # Sort: worst-status first, then by impact (n_affected desc), then col
    out_rows.sort(key=lambda r: (STATUS_RANK.get(r["validation_status"], 99),
                                   -r["n_affected"], r["column_name"]))

    fnames = [
        "decision_id", "column_name", "target_dim", "validation_status",
        "n_affected", "claimed_enum_block_example", "current_desc_example",
        "suggested_replacement", "delusional_ids", "mismatched_labels",
        "missing_ids_from_canonical", "target_dim_md", "resolution_strategy",
        "affected_targets_json", "notes", "decision", "override_text",
    ]
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fnames)
        w.writeheader()
        for r in out_rows:
            w.writerow(r)

    print(f"Wrote {out.relative_to(REPO).as_posix()}: {len(out_rows)} unique decisions")
    # Breakdown
    from collections import Counter
    by_status = Counter(r["validation_status"] for r in out_rows)
    total_lines_affected = sum(r["n_affected"] for r in out_rows)
    print(f"  Total wiki lines affected if all approved: {total_lines_affected}")
    print(f"\n  By status:")
    for s, n in sorted(by_status.items(), key=lambda kv: -kv[1]):
        n_lines = sum(r["n_affected"] for r in out_rows if r["validation_status"] == s)
        print(f"    {n:>3} decisions  /  {n_lines:>4} lines  {s}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
