"""sql_locator.py — given a wiki path, locate the producing SQL file(s).

Pure resolution layer. No LLM, no parsing of SELECT lists. Just file-system
routing with a fail-soft `unresolved` outcome when we can't be confident.

Routing strategy:
- Views/Functions/Stored Procedures: direct file mapping (wiki path -> SSDT
  `.sql` file).
- Tables: writer-SP resolution via a fallback chain:
    1. Read `.lineage.md` sidecar in the wiki dir; extract `**ETL SP**` field.
    2. Look up `.specify/Configs/opsdb-objects-status.json` by TableName.
    3. Name match: try `SP_<TableName>` and `SP_<TableName without BI_DB_>`.
    4. Grep `INSERT INTO <schema>.<TableName>` across the schema's SP folder.
    5. Mark `unresolved_writer`.

Returns a structured `SqlLocation` so the downstream extractor + audit driver
can fail-soft instead of guessing.

Usage as a module:
    from cleanup_tier1.sql_locator import locate_sql
    loc = locate_sql(Path("knowledge/synapse/Wiki/BI_DB_dbo/Tables/X.md"))
    # loc.object_kind, loc.sql_paths, loc.confidence, loc.notes

CLI:
    python -m cleanup_tier1.sql_locator --wiki <wiki.md>
    python -m cleanup_tier1.sql_locator --glob 'knowledge/synapse/Wiki/**/*.md'
"""
from __future__ import annotations

import argparse
import functools
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[2]
DATAPLATFORM = Path(r"C:\Users\guyman\Documents\github\DataPlatform")
SSDT_ROOT = DATAPLATFORM / "SynapseSQLPool1" / "sql_dp_prod_we"
OPSDB_CONFIG = REPO / ".specify" / "Configs" / "opsdb-objects-status.json"

WIKI_SYNAPSE = REPO / "knowledge" / "synapse" / "Wiki"


@dataclass
class SqlLocation:
    wiki_path: Path
    schema: str = ""               # e.g. "BI_DB_dbo"
    object_name: str = ""          # bare name, no schema
    object_kind: str = "unknown"   # view | function | stored_procedure | table | external_table | unknown
    sql_paths: list[Path] = field(default_factory=list)
    confidence: str = "unresolved" # direct | sidecar | opsdb | name_match | grep_match | unresolved
    notes: list[str] = field(default_factory=list)

    @property
    def resolved(self) -> bool:
        return bool(self.sql_paths)

    def to_dict(self) -> dict:
        return {
            "wiki_path": self.wiki_path.relative_to(REPO).as_posix()
                if self.wiki_path.is_absolute() and REPO in self.wiki_path.parents
                else str(self.wiki_path),
            "schema": self.schema,
            "object_name": self.object_name,
            "object_kind": self.object_kind,
            "sql_paths": [
                str(p.relative_to(DATAPLATFORM)) if DATAPLATFORM in p.parents else str(p)
                for p in self.sql_paths
            ],
            "confidence": self.confidence,
            "notes": self.notes,
        }


# ---------------------------------------------------------------------------
# Wiki path -> (schema, object kind, bare name)
# ---------------------------------------------------------------------------

# Wiki kind folder name -> SSDT folder name (different casing/spacing).
_KIND_TO_SSDT = {
    "Views": ("Views", "view"),
    "Functions": ("Functions", "function"),
    "Stored Procedures": ("Stored Procedures", "stored_procedure"),
    "Tables": ("Tables", "table"),
    "External Tables": ("External Tables", "external_table"),
}


def _identify_from_path(wiki_path: Path) -> tuple[str, str, str]:
    """Return (schema, object_kind_label, bare_name) from wiki_path,
    or ('','unknown','') if unrecognizable."""
    parts = wiki_path.parts
    # Look for ".../Wiki/<schema>/<KindFolder>/<Name>.md"
    if "Wiki" not in parts:
        return "", "unknown", ""
    i = parts.index("Wiki")
    if i + 3 >= len(parts):
        return "", "unknown", ""
    schema = parts[i + 1]
    kind_folder = parts[i + 2]
    bare = parts[i + 3]
    # strip suffixes
    for sfx in (".lineage.md", ".review-needed.md", ".deploy-report.md",
                ".alter.sql", ".md"):
        if bare.endswith(sfx):
            bare = bare[: -len(sfx)]
            break
    kind_info = _KIND_TO_SSDT.get(kind_folder)
    if kind_info is None:
        return schema, "unknown", bare
    return schema, kind_info[1], bare


# ---------------------------------------------------------------------------
# SSDT path resolution
# ---------------------------------------------------------------------------

def _ssdt_file_for(schema: str, kind_label: str, bare_name: str) -> Path | None:
    """Return the SSDT .sql file path for a non-table object."""
    kind_to_folder = {
        "view": "Views",
        "function": "Functions",
        "stored_procedure": "Stored Procedures",
        "external_table": "External Tables",
        "table": "Tables",  # for DDL-only inspection
    }
    folder = kind_to_folder.get(kind_label)
    if folder is None:
        return None
    p = SSDT_ROOT / schema / folder / f"{schema}.{bare_name}.sql"
    return p if p.exists() else None


# ---------------------------------------------------------------------------
# Table -> writer-SP resolution
# ---------------------------------------------------------------------------

# `**ETL SP** | `schema.SP_Name(...)` |
_ETL_SP_RE = re.compile(
    r"\|\s*\*\*ETL SP\*\*\s*\|\s*`([^`]+)`",
    re.IGNORECASE,
)
# fallback: bare procedure refs in the sidecar text
_SP_REF_RE = re.compile(
    r"`(?P<schema>[A-Za-z_][A-Za-z0-9_]*)\.(?P<sp>SP_[A-Za-z0-9_]+)`",
)


def _extract_writer_sp_from_sidecar(wiki_path: Path) -> list[tuple[str, str]]:
    """Return list of (schema, sp_name) candidates from <wiki>.lineage.md."""
    side = wiki_path.with_suffix("").with_name(
        wiki_path.with_suffix("").name + ".lineage.md"
    )
    if not side.exists():
        return []
    text = side.read_text(encoding="utf-8", errors="ignore")
    out: list[tuple[str, str]] = []
    m = _ETL_SP_RE.search(text)
    if m:
        ref = m.group(1).strip()
        # ref may look like "BI_DB_dbo.SP_DDR_Fact_..._And_Amounts(@date DATE)"
        ref_clean = re.sub(r"\(.*\)$", "", ref).strip()
        if "." in ref_clean:
            schema, sp = ref_clean.split(".", 1)
            if sp.upper().startswith("SP_"):
                out.append((schema, sp))
    # also collect any bare `Schema.SP_*` references as weaker candidates
    for mm in _SP_REF_RE.finditer(text):
        cand = (mm.group("schema"), mm.group("sp"))
        if cand not in out:
            out.append(cand)
    return out


@functools.lru_cache(maxsize=1)
def _opsdb_index() -> dict[str, str]:
    """Return TableName(lower) -> ProcedureName mapping from opsdb json."""
    if not OPSDB_CONFIG.exists():
        return {}
    try:
        data = json.loads(OPSDB_CONFIG.read_text(encoding="utf-8"))
    except Exception:
        return {}
    idx: dict[str, str] = {}
    for row in data:
        t = (row.get("TableName") or "").lower()
        p = row.get("ProcedureName") or ""
        if t and p:
            idx[t] = p
    return idx


def _ssdt_sp_path(schema: str, sp_name: str) -> Path | None:
    p = SSDT_ROOT / schema / "Stored Procedures" / f"{schema}.{sp_name}.sql"
    return p if p.exists() else None


def _try_name_match(schema: str, table_name: str) -> list[Path]:
    """Try a few naming conventions for the writer SP."""
    candidates: list[str] = []
    # Direct
    candidates.append(f"SP_{table_name}")
    # Drop common table prefixes like BI_DB_, then `SP_<rest>`
    for pfx in ("BI_DB_", "DWH_", "Dim_", "Fact_", "AML_", "BIO_"):
        if table_name.startswith(pfx):
            candidates.append(f"SP_{table_name[len(pfx):]}")
    # Also `SP_M_<...>` and `SP_DDR_<...>` style
    for token in ("M_", "DDR_"):
        if table_name.startswith(token):
            candidates.append(f"SP_{table_name}")
    out: list[Path] = []
    sp_dir = SSDT_ROOT / schema / "Stored Procedures"
    if not sp_dir.is_dir():
        return out
    for sp in candidates:
        p = sp_dir / f"{schema}.{sp}.sql"
        if p.exists() and p not in out:
            out.append(p)
    return out


# Cache the grep results per (schema, table) to avoid re-scanning.
@functools.lru_cache(maxsize=2048)
def _grep_writer_sp(schema: str, table_name: str) -> tuple[Path, ...]:
    """Scan the schema's SP folder for 'INSERT INTO <schema>.<table>' or
    'MERGE <schema>.<table>'. Returns matching SP paths."""
    sp_dir = SSDT_ROOT / schema / "Stored Procedures"
    if not sp_dir.is_dir():
        return tuple()
    fq = f"{schema}.{table_name}".lower()
    bare = table_name.lower()
    pat_insert = re.compile(rf"\binsert\s+into\s+(?:\[?{re.escape(schema)}\]?\.)?\[?{re.escape(table_name)}\]?\b",
                            re.IGNORECASE)
    pat_merge = re.compile(rf"\bmerge\s+(?:into\s+)?(?:\[?{re.escape(schema)}\]?\.)?\[?{re.escape(table_name)}\]?\b",
                           re.IGNORECASE)
    pat_select_into = re.compile(rf"\bselect\s+.*?\binto\s+(?:\[?{re.escape(schema)}\]?\.)?\[?{re.escape(table_name)}\]?\b",
                                 re.IGNORECASE | re.DOTALL)
    out: list[Path] = []
    for f in sp_dir.glob("*.sql"):
        try:
            t = f.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        if pat_insert.search(t) or pat_merge.search(t) or pat_select_into.search(t):
            out.append(f)
    return tuple(out)


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def locate_sql(wiki_path: Path) -> SqlLocation:
    """Locate the producing SQL file(s) for the object documented by
    `wiki_path`. Returns a structured SqlLocation."""
    wp = wiki_path if wiki_path.is_absolute() else (REPO / wiki_path)
    schema, kind, bare = _identify_from_path(wp)
    loc = SqlLocation(wiki_path=wp, schema=schema, object_kind=kind, object_name=bare)

    if kind == "unknown":
        loc.confidence = "unresolved"
        loc.notes.append("could not classify object kind from wiki path")
        return loc

    if kind in ("view", "function", "stored_procedure", "external_table"):
        p = _ssdt_file_for(schema, kind, bare)
        if p:
            loc.sql_paths = [p]
            loc.confidence = "direct"
            return loc
        loc.confidence = "unresolved"
        loc.notes.append(f"no SSDT file at expected path for {kind}")
        return loc

    if kind != "table":
        loc.confidence = "unresolved"
        loc.notes.append(f"unhandled object kind: {kind}")
        return loc

    # ---- table writer-SP resolution ----
    # 1. sidecar
    side_cands = _extract_writer_sp_from_sidecar(wp)
    if side_cands:
        for sch, sp in side_cands:
            p = _ssdt_sp_path(sch, sp)
            if p:
                loc.sql_paths = [p]
                loc.confidence = "sidecar"
                loc.notes.append(f"sidecar ETL SP: {sch}.{sp}")
                return loc
        loc.notes.append(f"sidecar cited SP(s) {side_cands} but file not on disk")

    # 2. opsdb
    opsdb = _opsdb_index()
    key = f"{schema}.{bare}".lower()
    sp_qualname = opsdb.get(key)
    if sp_qualname and "." in sp_qualname:
        sch, sp = sp_qualname.split(".", 1)
        p = _ssdt_sp_path(sch, sp)
        if p:
            loc.sql_paths = [p]
            loc.confidence = "opsdb"
            loc.notes.append(f"opsdb writer SP: {sp_qualname}")
            return loc
        loc.notes.append(f"opsdb cited {sp_qualname} but file not on disk")

    # 3. name match
    cands = _try_name_match(schema, bare)
    if cands:
        loc.sql_paths = list(cands)
        loc.confidence = "name_match"
        loc.notes.append(f"matched by name convention: {[p.name for p in cands]}")
        return loc

    # 4. grep
    grep_hits = _grep_writer_sp(schema, bare)
    if grep_hits:
        loc.sql_paths = list(grep_hits)
        loc.confidence = "grep_match"
        loc.notes.append(f"grep matched INSERT/MERGE in {len(grep_hits)} SP(s)")
        return loc

    loc.confidence = "unresolved"
    loc.notes.append("no writer SP located after sidecar/opsdb/name-match/grep")
    return loc


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _iter_glob(pattern: str) -> Iterable[Path]:
    import glob as _glob
    for s in _glob.glob(pattern, recursive=True):
        p = Path(s)
        if not p.is_absolute():
            p = REPO / p
        # skip sidecars / artifacts
        if any(p.name.endswith(sfx) for sfx in
               (".lineage.md", ".review-needed.md", ".deploy-report.md")):
            continue
        if p.suffix == ".md":
            yield p


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--wiki", help="single wiki .md")
    g.add_argument("--glob", help="glob over wikis")
    ap.add_argument("--json", action="store_true",
                    help="print one JSON per line")
    args = ap.parse_args(argv)

    files: list[Path]
    if args.wiki:
        p = Path(args.wiki)
        if not p.is_absolute():
            p = REPO / p
        files = [p]
    else:
        files = list(_iter_glob(args.glob))

    counts: dict[str, int] = {}
    for f in files:
        loc = locate_sql(f)
        counts[loc.confidence] = counts.get(loc.confidence, 0) + 1
        if args.json:
            print(json.dumps(loc.to_dict()))
        else:
            rel = f.relative_to(REPO).as_posix() if REPO in f.parents else str(f)
            paths = ", ".join(p.name for p in loc.sql_paths) or "(none)"
            print(f"{loc.confidence:11s} {loc.object_kind:18s} {rel}  ->  {paths}")
            for n in loc.notes:
                print(f"    note: {n}")

    if not args.json:
        print("---")
        total = sum(counts.values())
        for k, v in sorted(counts.items(), key=lambda kv: -kv[1]):
            print(f"  {k:11s} {v}  ({100*v/max(total,1):.1f}%)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
