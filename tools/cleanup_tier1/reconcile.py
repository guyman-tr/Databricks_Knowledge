#!/usr/bin/env python3
"""Merge new audit report(s) + old LLM judge cache into canonical corrections CSV."""
from __future__ import annotations

import argparse
import csv
import difflib
import json
import re
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

OUT_FIELDS = [
    "correction_id",
    "wiki_path",
    "wiki_object",
    "column_name",
    "current_desc",
    "source_wiki",
    "source_desc",
    "new_audit_verdict",
    "new_audit_severity",
    "new_audit_layer",
    "new_audit_proposed_fix",
    "old_judge_verdict",
    "old_judge_contradicting_fact",
    "old_judge_suggested_rewrite",
    "conflict_flag",
    "final_proposed_fix",
    "narrative_review_needed",
    "notes",
]


@dataclass
class AuditFail:
    wiki_path: str
    wiki_object: str
    column_name: str
    current_desc: str
    source_wiki: str
    source_desc: str
    source_tier: str
    verdict: str
    severity: str
    layer: str
    proposed_fix: str
    notes: str


@dataclass
class JudgeWrong:
    wiki_object: str
    column_name: str
    wiki_description: str
    contradicting_fact: str
    suggested_rewrite: str


def _norm(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "").strip().lower())


def _substantively_different(a: str, b: str, threshold: float = 0.85) -> bool:
    if not a or not b:
        return bool(a) != bool(b)
    if _norm(a) == _norm(b):
        return False
    ratio = difflib.SequenceMatcher(None, _norm(a), _norm(b)).ratio()
    return ratio < threshold


def _cites_source_verbatim(proposed: str, source_desc: str) -> bool:
    if not proposed or not source_desc:
        return False
    # Heuristic: first 60 chars of source appear in proposed
    snippet = _norm(source_desc)[:60]
    return snippet and snippet in _norm(proposed)


def _load_audit_fails(paths: list[Path]) -> dict[tuple[str, str], AuditFail]:
    out: dict[tuple[str, str], AuditFail] = {}
    for path in paths:
        with path.open(encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                if row.get("verdict") != "FAIL":
                    continue
                key = (row["dwh_object"], row["column_name"])
                out[key] = AuditFail(
                    wiki_path=row["dwh_wiki"],
                    wiki_object=row["dwh_object"],
                    column_name=row["column_name"],
                    current_desc=row.get("current_desc", ""),
                    source_wiki=row.get("source_wiki", ""),
                    source_desc=row.get("source_desc", ""),
                    source_tier=row.get("source_tier", ""),
                    verdict=row.get("verdict", ""),
                    severity=row.get("severity", ""),
                    layer=row.get("layer", ""),
                    proposed_fix=row.get("proposed_fix", ""),
                    notes=row.get("notes", ""),
                )
    return out


def _load_judge_cache(cache_dir: Path) -> dict[tuple[str, str], JudgeWrong]:
    out: dict[tuple[str, str], JudgeWrong] = {}
    if not cache_dir.exists():
        return out
    for jf in sorted(cache_dir.glob("*.json")):
        obj = jf.stem
        try:
            data = json.loads(jf.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        raw = data.get("response", "")
        if not raw:
            continue
        try:
            entries = json.loads(raw) if isinstance(raw, str) else raw
        except json.JSONDecodeError:
            continue
        if not isinstance(entries, list):
            continue
        for entry in entries:
            if entry.get("verdict") != "WRONG":
                continue
            col = entry.get("column", "")
            key = (obj, col)
            # Keep first WRONG per column (dedupe claim_id variants)
            if key in out:
                continue
            out[key] = JudgeWrong(
                wiki_object=obj,
                column_name=col,
                wiki_description=entry.get("wiki_description", ""),
                contradicting_fact=entry.get("contradicting_fact_verbatim", ""),
                suggested_rewrite=entry.get("suggested_rewrite", ""),
            )
    return out


def _resolve_wiki_path(wiki_object: str, audit: AuditFail | None,
                       scope_root: Path) -> str:
    if audit and audit.wiki_path:
        return audit.wiki_path
    for folder in ("Tables", "Views", "Functions"):
        candidate = scope_root / folder / f"{wiki_object}.md"
        if candidate.exists():
            return str(candidate.relative_to(REPO)).replace("\\", "/")
    return ""


def _l1_structural_fix(audit: AuditFail) -> str:
    """Rebuild the canonical L1-structural fix from source_desc + new tier tag.

    The audit tool's `proposed_fix` is truncated to ~500 chars; the source_desc
    field carries the full upstream description, which is what should land in
    the wiki. The tier tag must downgrade Tier 1 → the source's actual tier
    (typically Tier 2), with `via <source_object_stem>` for traceability.
    """
    if not audit.source_desc:
        return audit.proposed_fix
    source_stem = ""
    if audit.source_wiki:
        source_stem = Path(audit.source_wiki).stem
    # Source tier defaults to 2 (Tier 2 == DWH/intermediate truth)
    src_tier = (audit.source_tier or "2").strip()
    # Normalize "OLTP-truth" → tier 1 (canonical OLTP source)
    if src_tier.lower() in ("oltp-truth", "oltp_truth", "oltp"):
        src_tier = "1"
    # If the source IS Tier 1 (true OLTP), tag should reflect that; otherwise
    # downgrade to the source's tier.
    tag = f"(Tier {src_tier} — via {source_stem})" if source_stem else f"(Tier {src_tier})"
    desc = audit.source_desc.strip()
    # Don't double-stamp if source_desc already ends in a tier tag
    if desc.endswith(")") and "Tier " in desc[-80:]:
        return desc
    # Sentence-terminate the source text before the tag if needed
    if desc and desc[-1] not in ".!?":
        desc = desc + "."
    return f"{desc} {tag}"


def _pick_final_fix(
    audit: AuditFail | None,
    judge: JudgeWrong | None,
) -> tuple[str, bool, str]:
    """Return (final_proposed_fix, conflict_flag, notes)."""
    notes: list[str] = []
    audit_fix = audit.proposed_fix if audit else ""
    judge_fix = judge.suggested_rewrite if judge else ""
    source_desc = audit.source_desc if audit else ""

    if audit and audit.layer == "L1-structural":
        # Reconstruct from source_desc + new tier tag (handles truncated audit
        # proposed_fix).
        rebuilt = _l1_structural_fix(audit)
        if rebuilt:
            return rebuilt, False, "L1-structural: source_desc + downgraded tier tag"
        if audit_fix:
            return audit_fix, False, ""

    if audit and audit.layer == "L2-semantic" and audit_fix:
        if judge_fix and _substantively_different(audit_fix, judge_fix):
            if _cites_source_verbatim(judge_fix, source_desc):
                notes.append("prefer old judge (cites source verbatim)")
                return judge_fix, True, "; ".join(notes)
            return audit_fix, True, "audit vs judge disagree"
        if judge_fix and not audit_fix:
            return judge_fix, False, "judge only"
        return audit_fix, False, ""

    if judge_fix and not audit:
        return judge_fix, False, "judge only (no new audit hit)"

    if judge_fix and audit:
        if _substantively_different(audit_fix, judge_fix):
            if _cites_source_verbatim(judge_fix, source_desc):
                return judge_fix, True, "prefer old judge (cites source verbatim)"
            return audit_fix or judge_fix, True, "audit vs judge disagree"
        return audit_fix or judge_fix, False, ""

    if audit_fix:
        return audit_fix, False, audit.notes if audit else ""

    return "", False, ""


def reconcile(
    audit_paths: list[Path],
    cache_dir: Path,
    scope_root: Path,
    out_path: Path,
    append: bool = False,
) -> int:
    audit_fails = _load_audit_fails(audit_paths)
    judge_wrongs = _load_judge_cache(cache_dir)

    all_keys = set(audit_fails.keys()) | set(judge_wrongs.keys())
    rows: list[dict] = []

    for key in sorted(all_keys):
        obj, col = key
        audit = audit_fails.get(key)
        judge = judge_wrongs.get(key)
        wiki_path = _resolve_wiki_path(obj, audit, scope_root)
        current_desc = (audit.current_desc if audit
                        else judge.wiki_description if judge else "")
        source_wiki = audit.source_wiki if audit else ""
        source_desc = audit.source_desc if audit else ""

        final_fix, conflict, notes = _pick_final_fix(audit, judge)
        if not final_fix:
            continue

        corr_id = f"{obj}.{col}"
        rows.append({
            "correction_id": corr_id,
            "wiki_path": wiki_path,
            "wiki_object": obj,
            "column_name": col,
            "current_desc": current_desc,
            "source_wiki": source_wiki,
            "source_desc": source_desc,
            "new_audit_verdict": audit.verdict if audit else "",
            "new_audit_severity": audit.severity if audit else "",
            "new_audit_layer": audit.layer if audit else "",
            "new_audit_proposed_fix": audit.proposed_fix if audit else "",
            "old_judge_verdict": "WRONG" if judge else "",
            "old_judge_contradicting_fact": judge.contradicting_fact if judge else "",
            "old_judge_suggested_rewrite": judge.suggested_rewrite if judge else "",
            "conflict_flag": "TRUE" if conflict else "FALSE",
            "final_proposed_fix": final_fix,
            "narrative_review_needed": "FALSE",
            "notes": notes,
        })

    existing: dict[str, dict] = {}
    if append and out_path.exists():
        with out_path.open(encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                existing[row["correction_id"]] = row

    for row in rows:
        existing[row["correction_id"]] = row

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=OUT_FIELDS)
        w.writeheader()
        for row in sorted(existing.values(), key=lambda r: r["correction_id"]):
            w.writerow(row)

    # Manual review CSV for conflicts
    conflicts = [r for r in existing.values() if r.get("conflict_flag") == "TRUE"]
    if conflicts:
        manual_path = out_path.parent / "_tier1_corrections_manual_review.csv"
        with manual_path.open("w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=OUT_FIELDS)
            w.writeheader()
            for row in conflicts:
                w.writerow(row)

    return len(rows)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--new-audit", action="append", required=True,
                    help="Path to report.csv (repeatable)")
    ap.add_argument("--old-cache", default=str(REPO / "knowledge" / "_dwh_llm_judge_cache"),
                    help="Old LLM judge cache dir")
    ap.add_argument("--scope-root", default=str(REPO / "knowledge" / "synapse" / "Wiki" / "DWH_dbo"))
    ap.add_argument("--out", default=str(REPO / "knowledge" / "_tier1_truth_corrections.csv"))
    ap.add_argument("--append", action="store_true",
                    help="Append/merge with existing corrections file")
    args = ap.parse_args()

    audit_paths = [Path(p) for p in args.new_audit]
    count = reconcile(
        audit_paths=audit_paths,
        cache_dir=Path(args.old_cache),
        scope_root=Path(args.scope_root),
        out_path=Path(args.out),
        append=args.append,
    )
    print(f"Wrote {count} corrections → {args.out}")


if __name__ == "__main__":
    main()
