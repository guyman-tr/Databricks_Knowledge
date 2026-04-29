"""
preload_upstream.py

Deterministic upstream wiki resolution. Runs BEFORE the writer claude process.
Reads the current .lineage.md and DDL for the target object, extracts every
candidate source table, resolves each against:
  1) local Synapse wiki (knowledge/synapse/Wiki/{Schema}/Tables|Views/{Object}.md)
  2) production wiki repos via _upstream_wiki_routing.json

Concatenates all found upstream wikis into:
  audits/regen-sample/{Schema}/{Object}/regen/_upstream_bundle.md

Also writes:
  audits/regen-sample/{Schema}/{Object}/regen/_upstream_resolution.json
  (machine-readable record of what was searched, found, missed)

If nothing resolves, writes:
  audits/regen-sample/{Schema}/{Object}/regen/_no_upstream_found.txt

Per-upstream content is capped to MAX_BYTES_PER_UPSTREAM to keep the writer's
context window manageable. Truncation is annotated inline.

Usage:
  python preload_upstream.py --schema BI_DB_dbo --object BI_DB_AdvancedDeposit_Ext
  python preload_upstream.py --all          # process every row in manifest.csv
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
WIKI_ROOT = REPO_ROOT / "knowledge" / "synapse" / "Wiki"
ROUTING_JSON = WIKI_ROOT / "_upstream_wiki_routing.json"
DATAPLATFORM = Path(r"c:\Users\guyman\Documents\github\DataPlatform")
SSDT_ROOT = DATAPLATFORM / "SynapseSQLPool1" / "sql_dp_prod_we"
TARGET_ROOT = REPO_ROOT / "audits" / "regen-sample"

MAX_BYTES_PER_UPSTREAM = 30 * 1024  # 30 KB per upstream wiki, truncate beyond

# Synapse schemas we treat as "local Synapse-resident" upstreams.
LOCAL_SYNAPSE_SCHEMAS = {
    "BI_DB_dbo",
    "DWH_dbo",
    "Dealing_dbo",
    "eMoney_dbo",
    "EXW_dbo",
    "CryptoDB_dbo",
    "DE_dbo",
    "Schemas",
}

# Per-schema table-name prefixes used by the migration-mirror discovery step.
# Most eToro Synapse schemas namespace their tables with a fixed prefix
# (BI_DB_dbo.BI_DB_X, Dealing_dbo.Dealing_X, eMoney_dbo.eMoney_X, etc.). We use
# this to strip a "base name" from the target object and re-construct candidate
# mirror names in OTHER schemas. Schemas with no consistent prefix (DWH_dbo,
# Schemas) are NOT in this map; they're handled separately if needed.
SCHEMA_TABLE_PREFIXES: Dict[str, List[str]] = {
    "BI_DB_dbo":    ["BI_DB_"],
    "Dealing_dbo":  ["Dealing_"],
    "eMoney_dbo":   ["eMoney_"],
    "EXW_dbo":      ["EXW_"],
    "CryptoDB_dbo": ["CryptoDB_"],
    "DE_dbo":       ["DE_"],
}

# Tokens that indicate "no source" rather than a real table name.
NULL_SOURCE_TOKENS = {
    "unknown",
    "n/a",
    "na",
    "-",
    "—",
    "?",
    "tbd",
    "various",
    "none",
    "",
}

# Words that frequently appear as table-cell labels but never as source-object
# identifiers. Filtered out before resolution.
NOISE_LABELS = {
    "property", "value", "primary source", "secondary sources", "generated",
    "transform", "meaning", "source", "type", "etl sp", "dwh table",
    "uc target", "passthrough", "rename", "computed", "derived",
    "source table", "source object", "source column", "synapse column",
    "tier", "description", "key", "column", "notes", "note",
}

# Identifier shape: at least one dot, no whitespace, alnum/underscore/dot only.
# (Allows backticks/brackets which we strip elsewhere.)
IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*){1,2}$")


@dataclass
class ResolvedUpstream:
    raw_name: str            # how it appeared in the lineage
    db: Optional[str]        # production DB if 3-part identifier (etoro, WalletDB)
    schema: Optional[str]    # source schema
    object: Optional[str]    # source object name
    kind: str                # "synapse" | "production" | "synapse_sp" | "unresolved"
    wiki_path: Optional[str] = None  # absolute path of the upstream wiki .md
    sp_path: Optional[str] = None    # absolute path of writer/source SP .sql
    bytes_read: int = 0
    truncated: bool = False
    note: str = ""


def looks_like_sp(name: str) -> bool:
    if not name:
        return False
    n = name.lower()
    return (
        n.startswith("sp_")
        or n.startswith("usp_")
        or n.startswith("proc_")
        or n.startswith("uspup_")
    )


def find_synapse_sp(schema: str, sp_name: str) -> Optional[Path]:
    if not (schema and sp_name):
        return None
    candidates = [
        SSDT_ROOT / schema / "Stored Procedures" / f"{schema}.{sp_name}.sql",
        SSDT_ROOT / schema / "StoredProcedures" / f"{schema}.{sp_name}.sql",
    ]
    for c in candidates:
        if c.exists():
            return c
    return None


# Patterns for the writer-SP discovery step. We accept any of:
#   INSERT INTO [schema].[obj] / INSERT INTO obj
#   MERGE INTO [schema].[obj] / MERGE [schema].[obj]
#   TRUNCATE TABLE [schema].[obj]
#   DROP TABLE [schema].[obj]   (often paired with CTAS)
#   CTAS:  CREATE TABLE [schema].[obj] WITH (DISTRIBUTION ...) AS SELECT
def _write_target_regex(schema: str, obj: str) -> re.Pattern:
    s = re.escape(schema)
    o = re.escape(obj)
    qualifier = rf"(?:\[?{s}\]?\s*\.\s*)?\[?{o}\]?"
    return re.compile(
        rf"(?:INSERT\s+INTO\s+|MERGE\s+(?:INTO\s+)?|TRUNCATE\s+TABLE\s+|DROP\s+TABLE\s+(?:IF\s+EXISTS\s+)?|CREATE\s+TABLE\s+){qualifier}\b",
        re.IGNORECASE,
    )


def discover_writer_sps(schema: str, obj: str) -> List[Path]:
    """Scan SSDT Stored Procedures and return any SP that writes to {schema}.{obj}.

    This is the bridge that breaks the slop cycle: even when the current
    .lineage.md is empty (every slop wiki), we can still discover the writer
    SP and from there the upstream tables it joins to.
    """
    rx = _write_target_regex(schema, obj)
    out: List[Path] = []
    target_lower = obj.lower()
    sp_dir_candidates = [
        SSDT_ROOT / schema / "Stored Procedures",
        SSDT_ROOT / schema / "StoredProcedures",
    ]
    for sp_dir in sp_dir_candidates:
        if not sp_dir.exists():
            continue
        for sp_path in sp_dir.glob("*.sql"):
            try:
                text = sp_path.read_text(encoding="utf-8", errors="replace")
                # Cheap pre-filter to avoid running the regex on every SP body
                if target_lower not in text.lower():
                    continue
                if rx.search(text):
                    out.append(sp_path)
            except Exception:
                continue
    return out


_FROM_JOIN_RE = re.compile(
    r"\b(?:FROM|JOIN)\s+"
    r"(\[?[A-Za-z_]\w*\]?\.\[?[A-Za-z_]\w*\]?(?:\.\[?[A-Za-z_]\w*\]?)?)",
    re.IGNORECASE,
)
_TEMP_OR_VAR_RE = re.compile(r"^[#@]")


def parse_sp_join_sources(sp_path: Path) -> List[str]:
    """Extract every multi-part identifier following FROM / JOIN in an SP.

    Strips brackets and skips temp tables (#tmp), table variables (@tvp),
    and CTE-style aliases that look like identifiers but aren't tables.
    """
    text = sp_path.read_text(encoding="utf-8", errors="replace")
    # Strip line-level and block comments to avoid pulling identifiers out of
    # documentation. Cheap, not airtight.
    text = re.sub(r"--[^\n]*", "", text)
    text = re.sub(r"/\*[\s\S]*?\*/", "", text)
    out: List[str] = []
    for m in _FROM_JOIN_RE.finditer(text):
        ident = m.group(1).replace("[", "").replace("]", "")
        if _TEMP_OR_VAR_RE.match(ident):
            continue
        out.append(ident)
    return out


def load_routing() -> Dict:
    if not ROUTING_JSON.exists():
        return {}
    return json.loads(ROUTING_JSON.read_text(encoding="utf-8"))


def parse_lineage_sources(lineage_path: Path) -> List[str]:
    """Return raw source identifiers found in the lineage file's tables.

    Looks at:
      - the "Source Objects" table (column 1 of each row)
      - the "Column Lineage" table (the Source Table / Source Object column)
    """
    if not lineage_path.exists():
        return []
    text = lineage_path.read_text(encoding="utf-8")
    sources: List[str] = []
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        parts = [p.strip() for p in line.split("|")[1:-1]]
        if len(parts) < 2:
            continue
        # Skip header rows (where parts contain "Source Table" etc) and
        # divider rows (where parts are dashes only).
        if any("---" in p for p in parts):
            continue
        first = parts[0].lower()
        if first in {"source table", "source object", "synapse column", "#"}:
            continue
        # Source Objects table: column 1 IS the source identifier
        # Column Lineage table: column 2 is the Source Table / Source Object
        # We collect candidates from BOTH columns 0 and 1.
        for candidate in (parts[0], parts[1] if len(parts) > 1 else ""):
            candidate = candidate.strip().strip("`*")
            if not candidate:
                continue
            if candidate.lower() in NULL_SOURCE_TOKENS:
                continue
            # Strip trailing parenthetical comments
            candidate = re.sub(r"\s*\(.*?\)\s*$", "", candidate).strip()
            # Strip leading "Function_" / "View_" labels we don't care about
            sources.append(candidate)
    # Dedup preserving order
    seen: Set[str] = set()
    out: List[str] = []
    for s in sources:
        if s.lower() in seen:
            continue
        seen.add(s.lower())
        out.append(s)
    return out


def parse_ddl_sources(ddl_path: Path) -> List[str]:
    """Try to extract source object hints from DDL (FK comments, column
    descriptions referencing tables). Best-effort, low precision but free.
    """
    if not ddl_path.exists():
        return []
    text = ddl_path.read_text(encoding="utf-8", errors="replace")
    out: List[str] = []
    # FK-style comments like "-- FK to DWH_dbo.Dim_Customer.CID"
    for m in re.finditer(
        r"(?:FK\s*to|references?|from)\s+([A-Za-z][A-Za-z0-9_]*\.[A-Za-z][A-Za-z0-9_.]+)",
        text,
        flags=re.IGNORECASE,
    ):
        out.append(m.group(1))
    # FOREIGN KEY ... REFERENCES Schema.Table
    for m in re.finditer(
        r"REFERENCES\s+(\[?\w+\]?\.\[?\w+\]?(?:\.\[?\w+\]?)?)",
        text,
        flags=re.IGNORECASE,
    ):
        out.append(m.group(1).replace("[", "").replace("]", ""))
    seen: Set[str] = set()
    dedup: List[str] = []
    for s in out:
        if s.lower() in seen:
            continue
        seen.add(s.lower())
        dedup.append(s)
    return dedup


def split_identifier(raw: str) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    """Split a source identifier into (db, schema, object).
    1-part: (None, None, name)
    2-part: (None, schema, name)
    3-part: (db, schema, name)
    """
    s = raw.strip().strip("`*").strip("[]").replace("[", "").replace("]", "")
    parts = [p.strip() for p in s.split(".") if p.strip()]
    if len(parts) == 3:
        return (parts[0], parts[1], parts[2])
    if len(parts) == 2:
        # If the first part looks like a Synapse schema, treat as schema.object;
        # otherwise treat as db.object with unknown schema.
        first_lower = parts[0].lower()
        if (
            parts[0] in LOCAL_SYNAPSE_SCHEMAS
            or first_lower.endswith("_dbo")
            or first_lower.endswith("_dictionary")
            or first_lower in {"dbo"}
        ):
            return (None, parts[0], parts[1])
        # Could be "Customer.CustomerStatic" (etoro DB schema.table without DB prefix)
        return (None, parts[0], parts[1])
    if len(parts) == 1:
        return (None, None, parts[0])
    return (None, None, None)


def find_synapse_wiki(schema: str, name: str) -> Optional[Path]:
    if not schema or not name:
        return None
    for sub in ("Tables", "Views", "Functions"):
        cand = WIKI_ROOT / schema / sub / f"{name}.md"
        if cand.exists():
            return cand
    return None


def find_production_wiki(
    routing: Dict, db: Optional[str], schema: Optional[str], name: Optional[str]
) -> Tuple[Optional[Path], Optional[str]]:
    """Return (wiki_path, matched_db) using the routing JSON."""
    if not name:
        return (None, None)
    upstream_dbs = routing.get("upstream_databases", {}) or {}
    candidates: List[str] = []
    if db and db in upstream_dbs:
        candidates.append(db)
    else:
        # Try every DB whose schema list contains our schema
        for d, info in upstream_dbs.items():
            sch_list = (info or {}).get("schemas") or []
            if schema and schema in sch_list:
                candidates.append(d)
        # Also try every DB as a fallback (cheap on disk)
        for d in upstream_dbs:
            if d not in candidates:
                candidates.append(d)
    for d in candidates:
        info = upstream_dbs.get(d) or {}
        repo_path = info.get("repo_path") or ""
        wiki_path = info.get("wiki_path") or ""
        if not (repo_path and wiki_path):
            continue
        for sch in [schema] if schema else (info.get("schemas") or []):
            if not sch:
                continue
            for sub in ("Tables", "Views", "Functions"):
                cand = (
                    Path(repo_path) / wiki_path / sch / sub / f"{sch}.{name}.md"
                )
                if cand.exists():
                    return (cand, d)
                # Some repos use just `{name}.md` not `{sch}.{name}.md`
                cand2 = Path(repo_path) / wiki_path / sch / sub / f"{name}.md"
                if cand2.exists():
                    return (cand2, d)
    return (None, None)


def resolve_one(raw: str, routing: Dict) -> ResolvedUpstream:
    db, sch, obj = split_identifier(raw)
    if not obj:
        return ResolvedUpstream(
            raw_name=raw,
            db=db,
            schema=sch,
            object=obj,
            kind="unresolved",
            note="could not parse identifier",
        )
    # SP-shaped reference: include SP source code if found in SSDT
    if looks_like_sp(obj) and sch:
        sp_path = find_synapse_sp(sch, obj)
        if sp_path:
            return ResolvedUpstream(
                raw_name=raw,
                db=None,
                schema=sch,
                object=obj,
                kind="synapse_sp",
                sp_path=str(sp_path),
            )
    # Try synapse-local first
    if sch and sch in LOCAL_SYNAPSE_SCHEMAS:
        path = find_synapse_wiki(sch, obj)
        if path:
            return ResolvedUpstream(
                raw_name=raw,
                db=None,
                schema=sch,
                object=obj,
                kind="synapse",
                wiki_path=str(path),
            )
    # Without a schema, try every Synapse schema
    if not sch:
        for cand_schema in LOCAL_SYNAPSE_SCHEMAS:
            path = find_synapse_wiki(cand_schema, obj)
            if path:
                return ResolvedUpstream(
                    raw_name=raw,
                    db=None,
                    schema=cand_schema,
                    object=obj,
                    kind="synapse",
                    wiki_path=str(path),
                    note="schema inferred from search",
                )
    # Production
    path, matched_db = find_production_wiki(routing, db, sch, obj)
    if path:
        return ResolvedUpstream(
            raw_name=raw,
            db=matched_db,
            schema=sch,
            object=obj,
            kind="production",
            wiki_path=str(path),
        )
    return ResolvedUpstream(
        raw_name=raw,
        db=db,
        schema=sch,
        object=obj,
        kind="unresolved",
        note="no wiki found in local Synapse or production routing",
    )


def truncate(text: str, limit: int) -> Tuple[str, bool]:
    if len(text.encode("utf-8")) <= limit:
        return (text, False)
    cut = text.encode("utf-8")[:limit].decode("utf-8", errors="ignore")
    return (cut, True)


def build_bundle(
    schema: str,
    obj: str,
    ddl_path: Optional[Path],
    resolved: List[ResolvedUpstream],
) -> str:
    out: List[str] = []
    out.append(f"# Pre-Resolved Upstream Bundle for `{schema}.{obj}`\n")
    out.append(
        "This bundle was assembled deterministically by the regen harness "
        "BEFORE the writer claude process started. Use this as your AUTHORITATIVE "
        "Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream "
        "wikis below for any column that is a passthrough or rename of an upstream "
        "column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop "
        "NULL semantics.\n"
    )
    out.append("---\n")

    # DDL section
    if ddl_path and ddl_path.exists():
        ddl = ddl_path.read_text(encoding="utf-8", errors="replace")
        ddl, was_trunc = truncate(ddl, 50 * 1024)
        out.append(f"## Source DDL — `{ddl_path.name}`")
        out.append("")
        out.append("```sql")
        out.append(ddl)
        out.append("```")
        if was_trunc:
            out.append("\n*[DDL truncated to 50 KB]*")
        out.append("")
    else:
        out.append("## Source DDL")
        out.append("")
        out.append("(DDL not located in DataPlatform SSDT — table may be dormant or dropped.)")
        out.append("")

    # Upstream wikis
    out.append("---\n")
    out.append("## Upstream Wikis Found\n")
    found_wikis = [r for r in resolved if r.kind in ("synapse", "production")]
    found_sps = [r for r in resolved if r.kind == "synapse_sp"]
    if not found_wikis:
        out.append(
            "**NO UPSTREAM WIKI** was resolvable for any source listed in "
            "the lineage. Use the DDL above and the writer SP source below "
            "(if any) to ground every column description.\n"
        )
    else:
        out.append(f"Found {len(found_wikis)} upstream wiki(s). Read EACH one in full.\n")
        for r in found_wikis:
            wp = Path(r.wiki_path) if r.wiki_path else None
            if not wp or not wp.exists():
                continue
            text = wp.read_text(encoding="utf-8", errors="replace")
            text, was_trunc = truncate(text, MAX_BYTES_PER_UPSTREAM)
            r.bytes_read = len(text.encode("utf-8"))
            r.truncated = was_trunc
            out.append("")
            out.append(f"### Upstream `{r.raw_name}` — {r.kind}")
            schema_part = r.schema or "?"
            db_part = f"{r.db}." if r.db else ""
            out.append(f"- **Resolved as**: `{db_part}{schema_part}.{r.object}`")
            out.append(f"- **Wiki path**: `{r.wiki_path}`")
            out.append("")
            out.append(text)
            if was_trunc:
                out.append(
                    f"\n*[Upstream wiki truncated to {MAX_BYTES_PER_UPSTREAM // 1024} KB. "
                    "Open the file directly if you need more context.]*"
                )

    # Writer / source SP source code
    if found_sps:
        out.append("\n---\n")
        out.append("## Writer / Source SP Code\n")
        out.append(
            "These are stored procedures referenced in the lineage. Their "
            "source is included verbatim so the writer can ground column "
            "transformations and computed values directly without re-reading "
            "the SSDT.\n"
        )
        for r in found_sps:
            sp_p = Path(r.sp_path) if r.sp_path else None
            if not sp_p or not sp_p.exists():
                continue
            text = sp_p.read_text(encoding="utf-8", errors="replace")
            text, was_trunc = truncate(text, 80 * 1024)
            r.bytes_read = len(text.encode("utf-8"))
            r.truncated = was_trunc
            out.append("")
            out.append(f"### SP `{r.raw_name}`")
            out.append(f"- **Path**: `{r.sp_path}`")
            out.append("")
            out.append("```sql")
            out.append(text)
            out.append("```")
            if was_trunc:
                out.append("\n*[SP source truncated to 80 KB.]*")

    out.append("\n---\n")
    out.append("## Resolution Summary\n")
    out.append("| Raw source | Kind | Schema | Object | Resolved path |")
    out.append("|---|---|---|---|---|")
    for r in resolved:
        path_disp = r.wiki_path or r.sp_path or "—"
        out.append(
            f"| `{r.raw_name}` | {r.kind} | {r.schema or '—'} | "
            f"{r.object or '—'} | `{path_disp}` |"
        )
    out.append("")
    return "\n".join(out)


_DDL_COLUMNS_BLOCK_RE = re.compile(
    r"CREATE\s+TABLE[^\(]+\((.*?)\)\s*(?:WITH\b|\Z)",
    re.IGNORECASE | re.DOTALL,
)
_DDL_NON_COLUMN_PREFIXES = (
    "CONSTRAINT", "PRIMARY KEY", "FOREIGN KEY", "INDEX", "UNIQUE",
    "CHECK", "WITH", "DISTRIBUTION", "CLUSTERED",
)


def _extract_ddl_columns(ddl_path: Optional[Path]) -> Set[str]:
    """Best-effort: pull the column-name set out of a CREATE TABLE statement.

    Used by `find_migration_mirrors` to verify that two same-base-named tables
    in different schemas really are mirrors (not just lexical coincidences).
    """
    if not ddl_path or not ddl_path.exists():
        return set()
    text = ddl_path.read_text(encoding="utf-8", errors="replace")
    text = re.sub(r"--[^\n]*", "", text)
    text = re.sub(r"/\*[\s\S]*?\*/", "", text)
    m = _DDL_COLUMNS_BLOCK_RE.search(text)
    if not m:
        return set()
    body = m.group(1)
    cols: Set[str] = set()
    for line in body.split("\n"):
        s = line.strip().rstrip(",")
        if not s:
            continue
        if s.upper().startswith(_DDL_NON_COLUMN_PREFIXES):
            continue
        first = s.split()[0].strip("[]`\"")
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", first):
            cols.add(first.lower())
    return cols


def find_migration_mirrors(schema: str, obj: str) -> List[str]:
    """Discover sibling wikis in OTHER Synapse schemas that look like migration
    mirrors of `{schema}.{obj}`.

    Pattern: many eToro tables exist as 1:1 column-identical copies across
    schemas (BI_DB_X mirrors Dealing_X, eMoney_X mirrors EXW_X, etc.). The
    SP-based upstream discovery often misses this relationship because the
    writer SP lives in a different schema or uses dynamic SQL. When that
    happens the mirror's wiki — which has the canonical column descriptions —
    never reaches the writer and tier accuracy collapses.

    Algorithm:
      1. Strip the object's known schema-prefix to get a base name.
         BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks -> base = "DailyZeroPnL_Stocks".
      2. For every other schema in SCHEMA_TABLE_PREFIXES, build the candidate
         mirror name "{other_prefix}{base}" and look up its wiki.
      3. Verify with column-name overlap >= 70% of the smaller column set.
         If the DDL can't be read (e.g. mirror is a view with no SSDT entry),
         accept on name match alone.

    Returns the verified mirrors as fully-qualified identifiers, e.g.
    ["Dealing_dbo.Dealing_DailyZeroPnL_Stocks"]. The caller appends these to
    the candidates list so they flow through `resolve_one` like any other
    upstream and land in the bundle.
    """
    self_prefixes = SCHEMA_TABLE_PREFIXES.get(schema, [])
    base = obj
    for p in self_prefixes:
        if obj.lower().startswith(p.lower()):
            base = obj[len(p):]
            break
    if not base or len(base) < 3:
        return []

    self_ddl: Optional[Path] = None
    for sub in ("Tables", "Views"):
        cand = SSDT_ROOT / schema / sub / f"{schema}.{obj}.sql"
        if cand.exists():
            self_ddl = cand
            break
    self_cols = _extract_ddl_columns(self_ddl)
    # Need at least 3 columns for the overlap check to be meaningful. If we
    # can't read the self-DDL we still proceed but rely on name match alone.
    have_self_cols = len(self_cols) >= 3

    out: List[str] = []
    for other_schema, other_prefixes in SCHEMA_TABLE_PREFIXES.items():
        if other_schema == schema:
            continue
        for op in other_prefixes:
            cand_obj = f"{op}{base}"
            cand_wiki = find_synapse_wiki(other_schema, cand_obj)
            if not cand_wiki:
                continue
            # Verify column overlap when both DDLs are readable. This guards
            # against lexical coincidences (different tables that happen to
            # share a base name).
            verified = True
            if have_self_cols:
                other_ddl: Optional[Path] = None
                for sub in ("Tables", "Views"):
                    cand_ddl = SSDT_ROOT / other_schema / sub / f"{other_schema}.{cand_obj}.sql"
                    if cand_ddl.exists():
                        other_ddl = cand_ddl
                        break
                other_cols = _extract_ddl_columns(other_ddl)
                if other_cols:
                    overlap = len(self_cols & other_cols)
                    smaller = min(len(self_cols), len(other_cols))
                    if smaller == 0 or overlap / smaller < 0.7:
                        verified = False
            if verified:
                out.append(f"{other_schema}.{cand_obj}")
    return out


def process_one(schema: str, obj: str, routing: Dict, verbose: bool = False) -> Dict:
    target_dir = TARGET_ROOT / schema / obj
    if not target_dir.exists():
        return {
            "schema": schema,
            "object": obj,
            "ok": False,
            "error": "side-folder missing - run pick_sample.py first",
        }

    regen_dir = target_dir / "regen"
    regen_dir.mkdir(parents=True, exist_ok=True)

    # Source identifiers from existing lineage and DDL
    lineage = target_dir / "current" / f"{obj}.lineage.md"
    ddl_paths = [
        SSDT_ROOT / schema / "Tables" / f"{schema}.{obj}.sql",
        SSDT_ROOT / schema / "Views" / f"{schema}.{obj}.sql",
        SSDT_ROOT / schema / "Functions" / f"{schema}.{obj}.sql",
    ]
    ddl_path = next((p for p in ddl_paths if p.exists()), None)

    candidates = parse_lineage_sources(lineage)
    candidates.extend(parse_ddl_sources(ddl_path) if ddl_path else [])

    # Walk the writer-SP join graph. This is the fix for the "slop cycle":
    # when the existing lineage is empty (every slop wiki), we still find
    # candidates by scanning SSDT for any SP that writes to the target and
    # extracting FROM / JOIN identifiers from each. This typically surfaces
    # ~10-30 sibling Dim_X / Fact_X / Dictionary tables whose wikis already
    # exist in knowledge/synapse/Wiki/ and the writer was previously skipping.
    writer_sps = discover_writer_sps(schema, obj)
    sp_join_candidates: List[str] = []
    for sp in writer_sps:
        # Add the SP itself so its source code is bundled (writer can ground
        # transformations directly).
        sp_name = sp.stem  # e.g. "BI_DB_dbo.SP_H_Deposits"
        if sp_name.lower().startswith(f"{schema.lower()}."):
            sp_name = sp_name[len(schema) + 1:]
        candidates.append(f"{schema}.{sp_name}")
        sp_join_candidates.extend(parse_sp_join_sources(sp))
    candidates.extend(sp_join_candidates)

    # Migration-mirror discovery: BI_DB_X often mirrors Dealing_X / eMoney_X
    # column-for-column. The mirror's wiki carries the canonical descriptions
    # the writer needs to assign Tier 1, but cross-schema SP routing or
    # dynamic SQL can hide the relationship from `discover_writer_sps`. We
    # always include verified mirrors as candidates so they flow through
    # `resolve_one` and land in the upstream bundle alongside any SP-derived
    # candidates. Verification is name + DDL column-overlap (>= 70%).
    mirror_candidates = find_migration_mirrors(schema, obj)
    candidates.extend(mirror_candidates)

    # Drop self-references, obvious noise, and anything that doesn't look
    # like a 2- or 3-part SQL identifier.
    cleaned: List[str] = []
    seen: Set[str] = set()
    for c in candidates:
        c_norm = c.strip().strip("`*")
        if not c_norm or c_norm.lower() in NULL_SOURCE_TOKENS:
            continue
        if c_norm.lower() in NOISE_LABELS:
            continue
        # Strip surrounding brackets/backticks again after split
        c_norm = c_norm.replace("[", "").replace("]", "").rstrip("`")
        if not IDENT_RE.match(c_norm):
            continue
        # Skip if this is the target object itself
        if c_norm.lower().endswith(f".{obj.lower()}") or c_norm.lower() == obj.lower():
            continue
        key = c_norm.lower()
        if key in seen:
            continue
        seen.add(key)
        cleaned.append(c_norm)

    resolved = [resolve_one(c, routing) for c in cleaned]
    found = [r for r in resolved if r.kind in ("synapse", "production")]

    bundle = build_bundle(schema, obj, ddl_path, resolved)
    bundle_path = regen_dir / "_upstream_bundle.md"
    bundle_path.write_text(bundle, encoding="utf-8")

    res_summary = {
        "schema": schema,
        "object": obj,
        "ddl_path": str(ddl_path) if ddl_path else None,
        "lineage_path": str(lineage) if lineage.exists() else None,
        "writer_sps_discovered": [str(p) for p in writer_sps],
        "migration_mirrors_discovered": mirror_candidates,
        "candidates_found": len(cleaned),
        "resolved_synapse": sum(1 for r in resolved if r.kind == "synapse"),
        "resolved_production": sum(1 for r in resolved if r.kind == "production"),
        "resolved_sp": sum(1 for r in resolved if r.kind == "synapse_sp"),
        "unresolved": sum(1 for r in resolved if r.kind == "unresolved"),
        "bundle_path": str(bundle_path),
        "bundle_size_bytes": bundle_path.stat().st_size,
        "resolutions": [asdict(r) for r in resolved],
    }
    (regen_dir / "_upstream_resolution.json").write_text(
        json.dumps(res_summary, indent=2), encoding="utf-8"
    )

    found_any_wiki = any(r.kind in ("synapse", "production") for r in resolved)
    if not found_any_wiki and not (ddl_path and ddl_path.exists()):
        (regen_dir / "_no_upstream_found.txt").write_text(
            "No DDL in DataPlatform SSDT and no upstream wiki resolvable. "
            "Object is dormant / dropped / never landed.\n",
            encoding="utf-8",
        )
    elif not found_any_wiki:
        (regen_dir / "_no_upstream_found.txt").write_text(
            "No upstream wiki resolvable, but DDL exists. Writer must rely on "
            "DDL + SP code (Phase 9) + JOIN inference (Phase 5).\n",
            encoding="utf-8",
        )

    if verbose:
        print(
            f"  {schema}/{obj}: writer_sps={len(writer_sps)}  "
            f"candidates={len(cleaned)}  "
            f"synapse={res_summary['resolved_synapse']}  "
            f"prod={res_summary['resolved_production']}  "
            f"sp={res_summary['resolved_sp']}  "
            f"unresolved={res_summary['unresolved']}  "
            f"bundle={res_summary['bundle_size_bytes']:,}B"
        )

    return {**res_summary, "ok": True}


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--schema")
    p.add_argument("--object", dest="obj")
    p.add_argument("--all", action="store_true", help="process every row in manifest.csv")
    p.add_argument("--verbose", action="store_true", default=True)
    args = p.parse_args()

    routing = load_routing()

    if args.all:
        manifest = TARGET_ROOT / "manifest.csv"
        if not manifest.exists():
            print(f"ERROR: {manifest} not found. Run pick_sample.py first.")
            return 1
        rows = list(csv.DictReader(manifest.open("r", encoding="utf-8-sig")))
        print(f"Processing {len(rows)} objects...")
        print()
        for r in rows:
            process_one(r["Schema"], r["Object"], routing, verbose=True)
        return 0

    if not (args.schema and args.obj):
        p.error("--schema and --object are required (or use --all)")

    result = process_one(args.schema, args.obj, routing, verbose=True)
    if not result.get("ok"):
        print("ERROR:", result.get("error"))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
