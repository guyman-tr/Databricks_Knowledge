#!/usr/bin/env python3
"""Build DAG-driven propagation map for Tier-1 corrections."""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

from cleanup_tier1 import dag
from tier1_audit.parser import find_tier1_claims
from tier1_audit.resolver import resolve

OUT_FIELDS = [
    "correction_id",
    "source_wiki_path",
    "source_column",
    "downstream_object_full_name",
    "downstream_wiki_path",
    "downstream_column",
    "edge_kind",
    "event_count",
    "topological_distance",
    "defer_to_later_layer",
]


def _load_corrections(path: Path) -> list[dict]:
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def _wiki_resolves_to_corrected(resolution, source_wiki_path: str) -> bool:
    src_norm = source_wiki_path.replace("\\", "/").lower()
    for cp in resolution.candidate_paths:
        if str(cp.relative_to(REPO)).replace("\\", "/").lower() == src_norm:
            return True
        if cp.stem.lower() in src_norm:
            return True
    return False


_TIER_TAG_INDEX_CACHE: dict[str, list[tuple[str, str, str, "object"]]] | None = None


def _build_tier_tag_index() -> dict[str, list[tuple[str, str, str, "object"]]]:
    """Pre-parse every synapse wiki ONCE and index claims by the LOWERCASE
    resolved source-object identifier of their Tier 1 tag.

    Returns: index[source_key_lower] -> list of (wiki_path, column, source_text, claim_obj).
    `source_key_lower` is the resolved source's filename stem; if the tag fails
    to resolve, we fall back to the bare source_text.
    """
    global _TIER_TAG_INDEX_CACHE
    if _TIER_TAG_INDEX_CACHE is not None:
        return _TIER_TAG_INDEX_CACHE

    synapse_root = REPO / "knowledge" / "synapse" / "Wiki"
    index: dict[str, list[tuple[str, str, str, "object"]]] = {}

    for wiki in synapse_root.rglob("*.md"):
        wp = str(wiki.relative_to(REPO)).replace("\\", "/")
        # Skip sidecar files (.lineage, .review-needed, .deploy-report, etc.)
        if any(part in wiki.stem.lower() for part in (".lineage", ".review-needed",
                                                       ".deploy-report", ".alter")):
            continue
        try:
            claims = find_tier1_claims(wiki)
        except Exception:
            continue
        for claim in claims:
            tag = claim.primary_tier_tag
            if not tag:
                continue
            keys: set[str] = set()
            # Try resolver
            try:
                res = resolve(tag.source_text)
                for cp in res.candidate_paths:
                    keys.add(cp.stem.lower())
            except Exception:
                pass
            # Fallback: raw source_text tokens
            raw = tag.source_text.lower()
            keys.add(raw)
            # Also add last path component (Schema.Table → Table)
            for tok in raw.replace("via", ",").split(","):
                tok = tok.strip()
                if "." in tok:
                    keys.add(tok.split(".")[-1].strip())
                if tok:
                    keys.add(tok)
            for k in keys:
                if k:
                    index.setdefault(k, []).append((wp, claim.column_name, tag.source_text, claim))
    _TIER_TAG_INDEX_CACHE = index
    return index


def _scan_wiki_inheritance(
    source_wiki_path: str,
    source_object: str,
    source_column: str,
    queue_layers: dict[str, int] | None,
) -> list[dict]:
    """Find downstream wikis whose Tier 1 tag claims THIS source_object AND
    relates to THIS source_column.

    Column-pairing rule (defensive — avoids cross-column cascade):
      • TIGHT match  — the downstream's source_text contains the exact source
        column token (e.g. tag says "Fact_SnapshotEquity.Credit").
      • SAFE match   — the downstream column NAME equals source_column
        (assumes column-name preservation through views, which is the standard
        DWH pattern: views SELECT col AS col).
      • Otherwise → reject the edge. The two-column correction would be wrong.

    Uses the pre-built tier-tag inverted index instead of re-scanning every wiki
    for every correction (was O(corrections × wikis × claims) = ~2M ops).
    """
    rows: list[dict] = []
    source_norm = source_wiki_path.replace("\\", "/").lower()
    index = _build_tier_tag_index()
    key = source_object.lower()
    candidates = index.get(key, [])
    src_col_low = source_column.lower()
    seen: set[tuple[str, str]] = set()
    for wp, col, src_text, _claim in candidates:
        if wp.lower() == source_norm:
            continue
        # Column-pairing constraint
        src_text_low = (src_text or "").lower()
        col_low = (col or "").lower()
        # Token-boundary check for source_column inside source_text.
        import re as _re
        tight = bool(_re.search(rf"\b{_re.escape(src_col_low)}\b", src_text_low))
        safe = col_low == src_col_low
        if not (tight or safe):
            continue
        dedup_key = (wp.lower(), col.lower())
        if dedup_key in seen:
            continue
        seen.add(dedup_key)
        rows.append({
            "downstream_wiki_path": wp,
            "downstream_column": col,
            "edge_kind": "wiki_inheritance",
            "event_count": 0,
            "topological_distance": _layer_distance(wp, source_wiki_path, queue_layers),
        })
    return rows


def _layer_distance(down_wiki: str, up_wiki: str,
                    queue_layers: dict[str, int] | None) -> int:
    if not queue_layers:
        dl = dag.topological_layer_of(down_wiki) or 0
        ul = dag.topological_layer_of(up_wiki) or 0
        return max(0, dl - ul)
    dl = queue_layers.get(down_wiki, dag.topological_layer_of(down_wiki) or 999)
    ul = queue_layers.get(up_wiki, dag.topological_layer_of(up_wiki) or 0)
    return max(0, dl - ul)


def _scan_skill_embeds(source_object: str, source_column: str) -> list[dict]:
    rows: list[dict] = []
    for pattern in (".cursor/skills/**/*.md", ".cursor/rules/**/*.mdc"):
        for fpath in REPO.glob(pattern):
            try:
                text = fpath.read_text(encoding="utf-8")
            except OSError:
                continue
            if source_object in text and source_column in text:
                rows.append({
                    "downstream_wiki_path": str(fpath.relative_to(REPO)).replace("\\", "/"),
                    "downstream_column": source_column,
                    "edge_kind": "skill_embedded",
                    "event_count": 0,
                    "topological_distance": 0,
                })
    return rows


def build_propagation_map(
    corrections_path: Path,
    out_path: Path,
    queue_path: Path | None = None,
    max_layer: int | None = None,
) -> int:
    dag.load_dag()
    corrections = _load_corrections(corrections_path)
    queue_layers: dict[str, int] | None = None
    if queue_path and queue_path.exists():
        queue_layers = {}
        with queue_path.open(encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                queue_layers[row["wiki_path"]] = int(row.get("topological_layer", 999))

    all_rows: list[dict] = []
    seen: set[tuple] = set()

    for corr in corrections:
        cid = corr["correction_id"]
        wiki_path = corr["wiki_path"]
        col = corr["column_name"]
        obj = corr["wiki_object"]
        uc_fn = dag.full_name_for(wiki_path) if wiki_path else None

        if uc_fn:
            for dc in dag.downstream_columns_of(uc_fn, col):
                dwiki = dag.wiki_for(dc.downstream_full_name)
                dwp = str(dwiki.relative_to(REPO)).replace("\\", "/") if dwiki else ""
                dist = _layer_distance(dwp, wiki_path, queue_layers) if dwp else 0
                defer = bool(max_layer is not None and dist > 0
                             and queue_layers and dwp in queue_layers
                             and queue_layers[dwp] > (max_layer or 0))
                key = (cid, dc.downstream_full_name, dc.downstream_column, "column_lineage")
                if key in seen:
                    continue
                seen.add(key)
                all_rows.append({
                    "correction_id": cid,
                    "source_wiki_path": wiki_path,
                    "source_column": col,
                    "downstream_object_full_name": dc.downstream_full_name,
                    "downstream_wiki_path": dwp,
                    "downstream_column": dc.downstream_column,
                    "edge_kind": "column_lineage",
                    "event_count": dc.event_count,
                    "topological_distance": dist,
                    "defer_to_later_layer": "TRUE" if defer else "FALSE",
                })
        else:
            key = (cid, "", col, "wiki_only")
            if key not in seen:
                seen.add(key)
                all_rows.append({
                    "correction_id": cid,
                    "source_wiki_path": wiki_path,
                    "source_column": col,
                    "downstream_object_full_name": "",
                    "downstream_wiki_path": "",
                    "downstream_column": "",
                    "edge_kind": "wiki_only",
                    "event_count": 0,
                    "topological_distance": 0,
                    "defer_to_later_layer": "FALSE",
                })

        for inh in _scan_wiki_inheritance(wiki_path, obj, col, queue_layers):
            key = (cid, inh["downstream_wiki_path"], inh["downstream_column"], "wiki_inheritance")
            if key in seen:
                continue
            seen.add(key)
            defer = bool(max_layer is not None and queue_layers
                         and inh["downstream_wiki_path"] in queue_layers
                         and queue_layers[inh["downstream_wiki_path"]] > (max_layer or 0))
            all_rows.append({
                "correction_id": cid,
                "source_wiki_path": wiki_path,
                "source_column": col,
                "downstream_object_full_name": dag.full_name_for(inh["downstream_wiki_path"]) or "",
                "downstream_wiki_path": inh["downstream_wiki_path"],
                "downstream_column": inh["downstream_column"],
                "edge_kind": "wiki_inheritance",
                "event_count": 0,
                "topological_distance": inh["topological_distance"],
                "defer_to_later_layer": "TRUE" if defer else "FALSE",
            })

        for sk in _scan_skill_embeds(obj, col):
            key = (cid, sk["downstream_wiki_path"], sk["downstream_column"], "skill_embedded")
            if key in seen:
                continue
            seen.add(key)
            all_rows.append({
                "correction_id": cid,
                "source_wiki_path": wiki_path,
                "source_column": col,
                "downstream_object_full_name": "",
                "downstream_wiki_path": sk["downstream_wiki_path"],
                "downstream_column": sk["downstream_column"],
                "edge_kind": "skill_embedded",
                "event_count": 0,
                "topological_distance": 0,
                "defer_to_later_layer": "FALSE",
            })

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=OUT_FIELDS)
        w.writeheader()
        for row in all_rows:
            w.writerow(row)
    return len(all_rows)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--corrections",
                    default=str(REPO / "knowledge" / "_tier1_truth_corrections.csv"))
    ap.add_argument("--out", default=str(REPO / "knowledge" / "_tier1_propagation_map.csv"))
    ap.add_argument("--queue", default="")
    ap.add_argument("--max-layer", type=int, default=None)
    args = ap.parse_args()

    count = build_propagation_map(
        Path(args.corrections),
        Path(args.out),
        Path(args.queue) if args.queue else None,
        args.max_layer,
    )
    print(f"Wrote {count} propagation edges → {args.out}")


if __name__ == "__main__":
    main()
