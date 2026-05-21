"""Shared DAG querying utility — the only allowed entry point for lineage/ordering."""
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Iterator

REPO = Path(__file__).resolve().parents[2]
UC_GENERATED = REPO / "knowledge" / "UC_generated"
DAG_PATH = UC_GENERATED / "_dag.json"
WIKI_INDEX_PATH = UC_GENERATED / "_upstream_wiki_index.json"

_loaded = False
_nodes: dict[str, dict] = {}
_wiki_by_full: dict[str, dict] = {}      # mirrors disk _upstream_wiki_index.json
_extra_wikis: dict[str, dict] = {}       # in-memory only: UC_generated wikis we discover
_full_by_wiki: dict[str, str] = {}
_lineage_index: dict[tuple[str, str], list[dict]] | None = None
# Fuzzy index keyed by (canonical_table_name, column_lower) — fallback when wiki_index
# full_names and lineage source_table_full_names disagree on underscoring / _masked
# suffix.
_lineage_index_canon: dict[tuple[str, str], list[dict]] | None = None
# Reverse map: canonical table name -> list of (wiki_path, uc_full_name) so we can
# resolve a lineage downstream source back to a wiki.
_canon_to_wiki: dict[str, list[tuple[str, str]]] = {}


_GOLD_PREFIX_RE = re.compile(r"^gold_sql_dp_prod_we_[a-z0-9_]+?_dbo_")
_BRONZE_PREFIX_RE = re.compile(r"^bronze_etoro_")
_MASK_SUFFIX_RE = re.compile(r"(_masked|_pii|_unmasked|_test|_dev)+$")


def _canon_table_name(name: str) -> str:
    """Return a canonical slug suitable for fuzzy matching between wiki_index
    full_names (with doubled underscores from CamelCase splits) and lineage
    source_table_full_names (with `_masked` suffixes etc.)."""
    n = (name or "").lower()
    n = _GOLD_PREFIX_RE.sub("", n)
    n = _BRONZE_PREFIX_RE.sub("", n)
    # Apply mask suffix repeatedly in case of stacked suffixes
    prev = None
    while prev != n:
        prev = n
        n = _MASK_SUFFIX_RE.sub("", n)
    n = n.replace("_", "")
    return n


def canon_full_name(full_name: str) -> str:
    """Canonicalize the table portion of a UC full_name (catalog.schema.table)."""
    if not full_name:
        return ""
    parts = full_name.split(".")
    table = parts[-1] if parts else full_name
    return _canon_table_name(table)


@dataclass(frozen=True)
class DownstreamColumn:
    downstream_full_name: str
    downstream_column: str
    event_count: int
    entity_type: str | None


def load_dag() -> None:
    global _loaded, _nodes, _wiki_by_full, _full_by_wiki, _extra_wikis
    global _lineage_index, _lineage_index_canon, _canon_to_wiki
    if _loaded:
        return

    if DAG_PATH.exists():
        dag = json.loads(DAG_PATH.read_text(encoding="utf-8"))
        for node in dag.get("nodes", []):
            fn = node.get("full_name")
            if fn:
                _nodes[fn] = node

    if WIKI_INDEX_PATH.exists():
        idx = json.loads(WIKI_INDEX_PATH.read_text(encoding="utf-8"))
        for fn, info in idx.get("wikis", {}).items():
            _wiki_by_full[fn] = info
            wp = info.get("wiki_path", "")
            if wp:
                _full_by_wiki[_norm_path(wp)] = fn
            canon = canon_full_name(fn)
            if canon and wp:
                _canon_to_wiki.setdefault(canon, []).append((wp, fn))

    # ALSO scan UC_generated/<schema>/<Tables|Views>/<obj>.md so downstream
    # consumer wikis (which are NOT in _upstream_wiki_index.json) are routable
    # via full_name. This is required for cascade-uc-generated.
    _index_uc_generated_wikis()

    _lineage_index, _lineage_index_canon = _build_lineage_index()
    _loaded = True


def _index_uc_generated_wikis() -> None:
    """Scan UC_generated/<schema>/<Tables|Views>/<obj>.md and populate the
    in-memory _extra_wikis store WITHOUT touching _wiki_by_full (the disk
    mirror). This lets wiki_for() resolve downstream consumers that aren't in
    _upstream_wiki_index.json, but save_wiki_index() will not persist these
    runtime-only entries.
    """
    if not UC_GENERATED.exists():
        return
    for node in _nodes.values():
        fn = node.get("full_name")
        if not fn:
            continue
        schema = node.get("schema") or ""
        table_type = (node.get("table_type") or "").upper()
        if not schema:
            continue
        obj = fn.split(".")[-1]
        folder = "Views" if table_type == "VIEW" else "Tables"
        wiki_path = UC_GENERATED / schema / folder / f"{obj}.md"
        if not wiki_path.exists():
            continue
        rel = str(wiki_path.relative_to(REPO)).replace("\\", "/")
        if fn not in _wiki_by_full and fn not in _extra_wikis:
            _extra_wikis[fn] = {
                "full_name": fn,
                "wiki_path": rel,
                "wiki_kind": "uc_generated",
                "schema": schema,
                "uc_folder": folder,
                "column_count": node.get("column_count"),
            }
        _full_by_wiki[_norm_path(rel)] = fn
        canon = canon_full_name(fn)
        if canon:
            _canon_to_wiki.setdefault(canon, []).append((rel, fn))


def _norm_path(p: str) -> str:
    return p.replace("\\", "/").lower()


def _build_lineage_index() -> tuple[dict[tuple[str, str], list[dict]],
                                     dict[tuple[str, str], list[dict]]]:
    index: dict[tuple[str, str], list[dict]] = {}
    canon_index: dict[tuple[str, str], list[dict]] = {}
    if not UC_GENERATED.exists():
        return index, canon_index
    for cl_file in UC_GENERATED.glob("*/_discovery/column_lineage/*.json"):
        try:
            data = json.loads(cl_file.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        target_obj = data.get("object", "")
        for row in data.get("rows", []):
            src_table = row.get("source_table_full_name", "")
            src_col = row.get("source_column_name", "")
            if not src_table or not src_col:
                continue
            key = (src_table.lower(), src_col.lower())
            entry = {
                "downstream_full_name": target_obj,
                "downstream_column": row.get("target_column_name", ""),
                "event_count": row.get("event_count", 0) or 0,
                "entity_type": row.get("entity_type"),
                "source_table_full_name": src_table,
            }
            index.setdefault(key, []).append(entry)
            canon = canon_full_name(src_table)
            if canon:
                ckey = (canon, src_col.lower())
                canon_index.setdefault(ckey, []).append(entry)
    return index, canon_index


def get_node(full_name: str) -> dict | None:
    load_dag()
    return _nodes.get(full_name)


def wiki_for(full_name: str) -> Path | None:
    """Return the wiki file for a UC full_name. Tries exact match in
    _wiki_by_full (disk index), then _extra_wikis (UC_generated discovered at
    load-time), then falls back to canonical-name fuzzy match (resolves
    lineage source names like `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
    to the corresponding wiki even though wiki_index uses `dim__customer`)."""
    load_dag()
    info = _wiki_by_full.get(full_name) or _extra_wikis.get(full_name)
    if not info:
        canon = canon_full_name(full_name)
        candidates = _canon_to_wiki.get(canon, []) if canon else []
        if candidates:
            wp = candidates[0][0]
            return REPO / wp
        return None
    wp = info.get("wiki_path")
    if not wp:
        return None
    return REPO / wp


def full_names_for_canon(uc_full_name: str) -> list[str]:
    """Return all UC full_names (wiki_index keys) that canonicalize to the
    same slug as the given UC full_name. Useful when iterating downstream
    consumers — a lineage source like `…_masked` resolves to its wiki via
    canonical match."""
    load_dag()
    canon = canon_full_name(uc_full_name)
    if not canon:
        return []
    return [fn for (_, fn) in _canon_to_wiki.get(canon, [])]


def full_name_for(wiki_path: str | Path) -> str | None:
    load_dag()
    return _full_by_wiki.get(_norm_path(str(wiki_path)))


def synapse_schema_of(wiki_path: str | Path) -> str | None:
    load_dag()
    fn = full_name_for(wiki_path)
    if fn and fn in _wiki_by_full:
        return _wiki_by_full[fn].get("synapse_schema")
    # Fallback: parse from path
    parts = _norm_path(str(wiki_path)).split("/")
    for i, p in enumerate(parts):
        if p == "wiki" and i + 1 < len(parts):
            return parts[i + 1]
    return None


def topological_layer_of(wiki_path: str | Path) -> int | None:
    load_dag()
    fn = full_name_for(wiki_path)
    if not fn:
        return None
    node = _nodes.get(fn)
    if not node:
        return None
    return node.get("topological_layer")


def downstream_columns_of(
    uc_full_name: str,
    source_column: str,
) -> list[DownstreamColumn]:
    """Return real lineage downstream consumers for the given source column.

    Tries exact full_name match first, then falls back to canonical-name fuzzy
    match (handles wiki_index `dim__customer` ↔ lineage `dim_customer_masked`).
    """
    load_dag()
    assert _lineage_index is not None
    assert _lineage_index_canon is not None
    key = (uc_full_name.lower(), source_column.lower())
    hits = list(_lineage_index.get(key, []))
    if not hits:
        canon = canon_full_name(uc_full_name)
        if canon:
            ckey = (canon, source_column.lower())
            hits = list(_lineage_index_canon.get(ckey, []))
    best: dict[tuple[str, str], DownstreamColumn] = {}
    for h in hits:
        dk = (h["downstream_full_name"], h["downstream_column"])
        ec = h["event_count"]
        if dk not in best or ec > best[dk].event_count:
            best[dk] = DownstreamColumn(
                downstream_full_name=h["downstream_full_name"],
                downstream_column=h["downstream_column"],
                event_count=ec,
                entity_type=h["entity_type"],
            )
    return sorted(best.values(), key=lambda x: (-x.event_count, x.downstream_full_name))


def downstream_objects_of(uc_full_name: str) -> list[tuple[str, int]]:
    """Return all downstream objects regardless of source column.

    Exact full_name lookup first, canonical fallback if empty.
    """
    load_dag()
    assert _lineage_index is not None
    assert _lineage_index_canon is not None
    counts: dict[str, int] = {}
    needle = uc_full_name.lower()
    for (src_table, _), entries in _lineage_index.items():
        if src_table != needle:
            continue
        for e in entries:
            dn = e["downstream_full_name"]
            counts[dn] = counts.get(dn, 0) + e["event_count"]
    if not counts:
        canon = canon_full_name(uc_full_name)
        if canon:
            for (src_canon, _), entries in _lineage_index_canon.items():
                if src_canon != canon:
                    continue
                for e in entries:
                    dn = e["downstream_full_name"]
                    counts[dn] = counts.get(dn, 0) + e["event_count"]
    return sorted(counts.items(), key=lambda x: -x[1])


def all_in_scope_wikis_with_tier1_tags() -> list[tuple[str, str, int, int]]:
    """Return (wiki_path, uc_full_name, topological_layer, tier1_count)."""
    import sys
    sys.path.insert(0, str(REPO / "tools"))
    from tier1_audit.parser import find_tier1_claims

    load_dag()
    out: list[tuple[str, str, int, int]] = []
    seen: set[str] = set()

    for fn, info in _wiki_by_full.items():
        node = _nodes.get(fn)
        if node and node.get("wiki_status") == "out_of_scope":
            continue
        wp = info.get("wiki_path", "")
        if not wp or wp in seen:
            continue
        path = REPO / wp
        if not path.exists():
            continue
        claims = find_tier1_claims(path)
        if not claims:
            continue
        layer = node.get("topological_layer", 999) if node else 999
        out.append((wp, fn, layer, len(claims)))
        seen.add(wp)

    return sorted(out, key=lambda x: (x[2], -x[3], x[0]))


def register_wiki_mapping(full_name: str, wiki_path: str, **extra) -> None:
    """Append/update a wiki entry in the disk-backed index (for tvf_view_match).

    Only TVF (Function_*) entries should land here — UC_generated wiki discovery
    happens in _extra_wikis and is not persisted to disk.
    """
    load_dag()
    info = {
        "full_name": full_name,
        "wiki_path": wiki_path,
        "wiki_kind": extra.get("wiki_kind", "synapse_tvf_view"),
        "synapse_schema": extra.get("synapse_schema", ""),
        "synapse_object": extra.get("synapse_object", ""),
        "synapse_folder": extra.get("synapse_folder", "Functions"),
        "column_count": extra.get("column_count"),
    }
    _wiki_by_full[full_name] = info
    _full_by_wiki[_norm_path(wiki_path)] = full_name


def save_wiki_index() -> None:
    """Persist _upstream_wiki_index.json. Only writes disk-mirrored entries
    (_wiki_by_full); runtime-only UC_generated discoveries in _extra_wikis are
    not persisted."""
    load_dag()
    # Preserve original file's top-level fields if present
    existing: dict = {}
    if WIKI_INDEX_PATH.exists():
        try:
            existing = json.loads(WIKI_INDEX_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            existing = {}
    data = {
        "framework": existing.get("framework", "uc-pipeline-doc"),
        "generated_at": __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "wikis": _wiki_by_full,
    }
    if "stats" in existing:
        data["stats"] = existing["stats"]
    if "duplicates" in existing:
        data["duplicates"] = existing["duplicates"]
    WIKI_INDEX_PATH.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def _pascal_to_snake(name: str) -> str:
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", name)
    s = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", s)
    return s.lower()


def iter_uc_view_names(schemas: list[str] | None = None) -> Iterator[tuple[str, str]]:
    """Yield (full_name, object_name) for UC views in given schemas."""
    load_dag()
    schemas = schemas or ["etoro_kpi_prep", "etoro_kpi"]
    schema_set = {s.lower() for s in schemas}
    for fn, node in _nodes.items():
        if node.get("table_type", "").upper() != "VIEW":
            continue
        schema = node.get("schema", "").lower()
        if schema not in schema_set:
            continue
        parts = fn.split(".")
        obj = parts[-1] if parts else fn
        yield fn, obj
