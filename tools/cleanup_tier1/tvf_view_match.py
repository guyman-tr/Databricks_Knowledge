#!/usr/bin/env python3
"""Match Synapse Function_* TVF wikis to UC views in etoro_kpi[_prep]."""
from __future__ import annotations

import argparse
import csv
import re
from datetime import datetime, timezone
from pathlib import Path

from . import dag

REPO = Path(__file__).resolve().parents[2]
SYNAPSE_WIKI = REPO / "knowledge" / "synapse" / "Wiki"
TARGET_SCHEMAS = ["etoro_kpi_prep", "etoro_kpi"]


def _pascal_to_snake(name: str) -> str:
    s = re.sub(r"^Function_", "", name)
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s)
    s = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", s)
    return s.lower()


def _candidates_from_wiki_stem(stem: str) -> list[str]:
    # Original underscores in synapse name = "major boundary"; camel-case
    # transitions inside a word = "minor boundary". UC views collapse the
    # minor boundaries about half the time, so we try both.
    raw = re.sub(r"^Function_", "", stem)
    snake = _pascal_to_snake(stem)
    # major-boundary form: keep original "_" boundaries, lowercase each word
    parts = raw.split("_")
    no_camel_split = "_".join(p.lower() for p in parts if p)
    cands = [
        snake, f"v_{snake}",
        no_camel_split, f"v_{no_camel_split}",
        raw.lower(), f"v_{raw.lower()}",
    ]
    # Trailing "fee" sometimes dropped (Function_Revenue_RolloverFee -> v_revenue_rollover)
    if no_camel_split.endswith("fee"):
        trimmed = no_camel_split[:-3].rstrip("_")
        cands += [trimmed, f"v_{trimmed}"]
    if no_camel_split.endswith("commissions"):
        sing = no_camel_split[:-1]  # "commissions" -> "commission"
        cands += [sing, f"v_{sing}"]
    return list(dict.fromkeys([c for c in cands if c]))


def _build_uc_lookup() -> dict[str, str]:
    lookup: dict[str, str] = {}
    for full_name, obj in dag.iter_uc_view_names(TARGET_SCHEMAS):
        lookup[obj.lower()] = full_name
    return lookup


def match_tvf_views(dry_run: bool = False) -> list[dict]:
    dag.load_dag()
    uc_lookup = _build_uc_lookup()
    rows: list[dict] = []

    for schema_dir in sorted(SYNAPSE_WIKI.iterdir()):
        func_dir = schema_dir / "Functions"
        if not func_dir.is_dir():
            continue
        synapse_schema = schema_dir.name
        for wiki in sorted(func_dir.glob("*.md")):
            if wiki.suffix != ".md":
                continue
            stem = wiki.stem
            # Skip sidecar files (lineage, review-needed, deploy-report, alter, etc.)
            if "." in stem:
                continue
            wiki_path = str(wiki.relative_to(REPO)).replace("\\", "/")
            cands = _candidates_from_wiki_stem(stem)
            matched_fn = ""
            confidence = "none"
            for c in cands:
                if c in uc_lookup:
                    matched_fn = uc_lookup[c]
                    confidence = "exact" if c == stem.lower() else "fuzzy"
                    break
            if not matched_fn:
                # fuzzy: partial match
                stem_lower = _pascal_to_snake(stem)
                for obj_lower, fn in uc_lookup.items():
                    if stem_lower in obj_lower or obj_lower in stem_lower:
                        matched_fn = fn
                        confidence = "fuzzy"
                        break

            rows.append({
                "wiki_path": wiki_path,
                "synapse_schema": synapse_schema,
                "wiki_stem": stem,
                "matched_uc_full_name": matched_fn,
                "match_confidence": confidence,
            })

            if matched_fn and confidence != "none" and not dry_run:
                dag.register_wiki_mapping(
                    matched_fn,
                    wiki_path,
                    synapse_schema=synapse_schema,
                    synapse_object=stem,
                    synapse_folder="Functions",
                    wiki_kind="synapse_tvf_view",
                )

    if not dry_run:
        dag.save_wiki_index()
    return rows


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--out-dir", default=str(REPO / "audits"))
    args = ap.parse_args()

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")
    rows = match_tvf_views(dry_run=args.dry_run)
    out_path = Path(args.out_dir) / f"_tvf_view_match_{ts}.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "wiki_path", "synapse_schema", "wiki_stem",
            "matched_uc_full_name", "match_confidence",
        ])
        w.writeheader()
        w.writerows(rows)

    matched = sum(1 for r in rows if r["match_confidence"] != "none")
    print(f"Matched {matched}/{len(rows)} TVF wikis → {out_path}")


if __name__ == "__main__":
    main()
