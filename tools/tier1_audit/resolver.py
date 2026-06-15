"""resolver.py — turn a free-form "Tier 1 source" string into a concrete wiki path.

Input examples seen in DWH_dbo wikis:

    "Customer.CustomerStatic"                     (Schema.Table OLTP)
    "BackOffice.Affiliate"                         (Schema.Table OLTP)
    "Function_Population_Funded"                  (TVF)
    "V_Liabilities"                               (bare sibling synapse view)
    "V_Liabilities via Fact_SnapshotEquity"       (primary via secondary)
    "Fact_SnapshotEquity"                         (bare sibling synapse table)
    "DDR_Customer_Daily_Status"                    (bare BI_DB synapse table)
    "Dim_Customer (CID = RealCID)"                (annotation)

Output: a `Resolution` record listing every candidate wiki path discovered,
in priority order. The caller (source_lookup) then walks the candidates to
find the matching column.

The resolver is intentionally permissive — when a name could plausibly route
to several wikis (e.g. an OLTP `Customer.X` exists in both `etoro` and
`UserApiDB`), all candidates are returned so source_lookup can pick the one
whose column actually exists.

Routing data:
  knowledge/synapse/Wiki/_upstream_wiki_routing.json
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[2]
ROUTING_PATH = REPO / "knowledge" / "synapse" / "Wiki" / "_upstream_wiki_routing.json"
SYNAPSE_WIKI = REPO / "knowledge" / "synapse" / "Wiki"
PROD_SCHEMAS = REPO / "knowledge" / "ProdSchemas"
UC_GENERATED = REPO / "knowledge" / "UC_generated"

# Sibling synapse-wiki folders to search when only a bare table/view name is given.
SYNAPSE_DBS = ["DWH_dbo", "BI_DB_dbo", "Dealing_dbo", "eMoney_dbo",
               "EXW_dbo", "EXW_Wallet", "eMoney_Tribe"]


@dataclass
class Resolution:
    raw_source: str                       # the unparsed text inside (Tier 1 -- X)
    primary: str | None = None            # the "primary" if "X via Y" pattern
    secondary: str | None = None          # the "Y" if "X via Y" pattern
    candidate_paths: list[Path] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    @property
    def resolved(self) -> bool:
        return bool(self.candidate_paths)


# ---------------------------------------------------------------------------
# Routing loaders (cached)
# ---------------------------------------------------------------------------
@lru_cache(maxsize=1)
def _load_routing() -> dict:
    if not ROUTING_PATH.exists():
        return {"upstream_databases": {}}
    return json.loads(ROUTING_PATH.read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def _schema_to_databases() -> dict[str, list[str]]:
    """Return a map {schema_name_lower: [db1, db2, ...]} so we can resolve a
    bare `Schema.Table` without knowing which DB it belongs to."""
    routing = _load_routing()
    out: dict[str, list[str]] = {}
    for db, info in routing.get("upstream_databases", {}).items():
        for sd in info.get("schema_details", []):
            name = (sd.get("name") or "").lower()
            if not name:
                continue
            out.setdefault(name, []).append(db)
    return out


@lru_cache(maxsize=1)
def _db_info(db: str) -> dict | None:
    return _load_routing().get("upstream_databases", {}).get(db)


# ---------------------------------------------------------------------------
# Source-text parsing
# ---------------------------------------------------------------------------
_VIA_RE = re.compile(r"\s+via\s+", re.IGNORECASE)
_PAREN_TRAIL_RE = re.compile(r"\s*\([^()]*\)\s*$")
_SCHEMA_TABLE_RE = re.compile(r"^([A-Za-z][A-Za-z0-9_]*)\.([A-Za-z][A-Za-z0-9_]*)$")
_THREE_PART_NAME_RE = re.compile(
    r"^([A-Za-z][A-Za-z0-9_]*)\.([A-Za-z][A-Za-z0-9_]*)\.([A-Za-z][A-Za-z0-9_]*)$"
)
_TVF_PREFIXES = ("function_", "fn_")
# Decoration that follows a name and should be stripped, e.g.
#   "DWH_dbo.V_Liabilities at @DateID"   -> "DWH_dbo.V_Liabilities"
#   "Fact_SnapshotEquity as of TODAY"    -> "Fact_SnapshotEquity"
#   "V_Liabilities on join key X"        -> "V_Liabilities"
_DECORATION_TRAIL_RE = re.compile(
    r"\s+(?:at|as\s+of|on|in|for|using|filtered\s+by|where|when|if)\b.*$",
    re.IGNORECASE,
)
# Leading "via X" (no primary before) — normalize to bare X.
_LEADING_VIA_RE = re.compile(r"^via\s+", re.IGNORECASE)
# Names of synapse "DB folders" that look like Schema.Table tokens but are
# actually <synapse_db_folder>.<Table>. These take precedence over upstream
# Schema.Table lookups since the upstream routing JSON does not include them.
_SYNAPSE_DB_FOLDER_TOKENS = {db.lower() for db in SYNAPSE_DBS}

# Prose patterns observed across DWH_dbo wikis. Order matters: we strip the
# wrapper text and re-feed the inner symbol back through _resolve_single_token.
_INHERITED_FROM_RE = re.compile(
    r"^inherited\s+from\s+(.+?)(?:\s+wiki)?(?:[,;].*)?$",
    re.IGNORECASE,
)
_UPSTREAM_WIKI_COMMA_RE = re.compile(
    r"^upstream\s+wiki[,:]\s*(.+?)(?:\s+wiki)?$",
    re.IGNORECASE,
)
_TRAILING_UPSTREAM_RE = re.compile(
    r"^(.+?)\s+upstream\s+wiki\s*$",
    re.IGNORECASE,
)

# Sentinel strings that explicitly mean "no upstream" — we don't try to
# resolve these, but we tag them with a clear note in the report.
_SENTINEL_NO_SOURCE = {
    "ddl", "view ddl", "manually authored", "expert-reviewed",
}


def _split_via(raw: str) -> tuple[str, str | None]:
    """`X via Y` -> (X, Y). Single token -> (X, None)."""
    parts = _VIA_RE.split(raw, maxsplit=1)
    if len(parts) == 2:
        return parts[0].strip(), parts[1].strip()
    return raw.strip(), None


def _clean_token(tok: str) -> str:
    """Strip surrounding clutter: backticks, quotes, trailing parens,
    trailing temporal/filter decoration, leading "via ", trailing
    punctuation (commas / dots / semicolons)."""
    s = tok.strip()
    # Strip surrounding backticks / single quotes / double quotes
    s = s.strip("`'\"")
    s = _PAREN_TRAIL_RE.sub("", s).strip()
    s = _DECORATION_TRAIL_RE.sub("", s).strip()
    s = _LEADING_VIA_RE.sub("", s).strip()
    # If wrapped in backticks again after first strip (e.g. `X` -> X then
    # trailing decoration leaves "X` at Y"), strip backticks once more
    s = s.strip("`'\"")
    # Strip dangling punctuation left by `via` splitting (e.g. "X, via Y" -> primary="X,")
    s = s.rstrip(",;.")
    return s.strip()


def _resolve_synapse_dbo(folder: str, table: str) -> list[Path]:
    """`DWH_dbo.V_Liabilities` style — `folder` is a synapse DB folder name."""
    base = SYNAPSE_WIKI / folder
    if not base.is_dir():
        # Try matching case-insensitively
        for cand in SYNAPSE_WIKI.iterdir() if SYNAPSE_WIKI.is_dir() else []:
            if cand.is_dir() and cand.name.lower() == folder.lower():
                base = cand
                break
        else:
            return []
    out: list[Path] = []
    for sub in ("Tables", "Views"):
        p = base / sub / f"{table}.md"
        if p.exists():
            out.append(p)
    return out


_GOLD_PREFIX_RE = re.compile(
    r"^gold_sql_dp_prod_we_([a-z][a-z0-9]*(?:_[a-z][a-z0-9]*)*)_dbo_(.+)$",
    re.IGNORECASE,
)


def _resolve_uc_three_part(catalog: str, schema: str, table: str) -> list[Path]:
    """`main.<schema>.<table>` UC-style FQN → UC_generated wiki, with a
    fallback that maps the `gold_sql_dp_prod_we_<db>_dbo_<rest>` Synapse-mirror
    naming convention back to the synapse wiki."""
    if catalog.lower() not in ("main", "hive_metastore"):
        return []
    out: list[Path] = []
    base = UC_GENERATED / schema.lower()
    if not base.is_dir():
        for cand in UC_GENERATED.iterdir() if UC_GENERATED.is_dir() else []:
            if cand.is_dir() and cand.name.lower() == schema.lower():
                base = cand
                break
        else:
            base = None  # type: ignore[assignment]
    if base is not None:
        for sub in ("Tables", "Views"):
            p = base / sub / f"{table.lower()}.md"
            if p.exists():
                out.append(p)
            p2 = base / sub / f"{table}.md"
            if p2.exists() and p2 not in out:
                out.append(p2)
    if out:
        return out
    # Fallback: synapse-mirror naming `gold_sql_dp_prod_we_<db>_dbo_<rest>`
    # (with optional `_masked` / `_v` suffix) → synapse wiki <db>_dbo/<rest>.md
    m = _GOLD_PREFIX_RE.match(table)
    if not m:
        return []
    db_part, rest = m.group(1), m.group(2)
    # Drop any trailing UC-specific suffixes the synapse wiki doesn't use.
    rest_normalised = rest
    for suf in ("_masked", "_v", "_view"):
        if rest_normalised.lower().endswith(suf):
            rest_normalised = rest_normalised[: -len(suf)]
    folder_name = f"{db_part}_dbo"  # e.g. bi_db_dbo
    syn_base: Path | None = None
    for cand in SYNAPSE_WIKI.iterdir() if SYNAPSE_WIKI.is_dir() else []:
        if cand.is_dir() and cand.name.lower() == folder_name.lower():
            syn_base = cand
            break
    if syn_base is None:
        return []
    # Case-insensitive sibling search inside the synapse folder
    candidates = []
    for sub in ("Tables", "Views"):
        d = syn_base / sub
        if not d.is_dir():
            continue
        for p in d.glob("*.md"):
            if p.name.endswith((".lineage.md", ".review-needed.md",
                                 ".deploy-report.md")):
                continue
            stem = p.stem
            if stem.lower() == rest_normalised.lower():
                candidates.append(p)
    return candidates


def _unwrap_prose(tok: str) -> str | None:
    """Reduce verbose prose like "inherited from Foo wiki" or
    "upstream wiki, Bar" down to the actual symbol ("Foo" or "Bar").
    Returns the unwrapped symbol or None if the token isn't a prose wrapper."""
    s = tok.strip()
    if not s:
        return None
    m = _INHERITED_FROM_RE.match(s)
    if m:
        return m.group(1).strip().rstrip(",.;").rstrip()
    m = _UPSTREAM_WIKI_COMMA_RE.match(s)
    if m:
        return m.group(1).strip().rstrip(",.;").rstrip()
    m = _TRAILING_UPSTREAM_RE.match(s)
    if m:
        return m.group(1).strip().rstrip(",.;").rstrip()
    return None


def _is_sentinel_no_source(tok: str) -> bool:
    return tok.strip().lower() in _SENTINEL_NO_SOURCE


# ---------------------------------------------------------------------------
# Candidate search
# ---------------------------------------------------------------------------
def _wiki_path_for(db: str, schema: str, table: str) -> list[Path]:
    """Return existing wiki files for {db, schema, table} as table or view."""
    info = _db_info(db)
    if not info:
        return []
    base = REPO / info["wiki_path"]
    candidates = [
        base / schema / "Tables" / f"{schema}.{table}.md",
        base / schema / "Views" / f"{schema}.{table}.md",
        # some repos drop the schema prefix in the filename
        base / schema / "Tables" / f"{table}.md",
        base / schema / "Views" / f"{table}.md",
    ]
    return [p for p in candidates if p.exists()]


def _resolve_schema_table(schema: str, table: str) -> list[Path]:
    """Schema.Table -> wiki paths (across all DBs whose schema list contains it)."""
    found: list[Path] = []
    for db in _schema_to_databases().get(schema.lower(), []):
        # match the schema with whatever casing the routing JSON uses
        info = _db_info(db) or {}
        for sd in info.get("schema_details", []):
            if (sd.get("name") or "").lower() == schema.lower():
                found.extend(_wiki_path_for(db, sd["name"], table))
                break
    return found


def _sibling_synapse_search(name: str) -> list[Path]:
    """Search across all DWH synapse wiki folders for a bare table/view name."""
    out: list[Path] = []
    for db_dir in SYNAPSE_DBS:
        base = SYNAPSE_WIKI / db_dir
        if not base.is_dir():
            continue
        for sub in ("Tables", "Views"):
            cand = base / sub / f"{name}.md"
            if cand.exists():
                out.append(cand)
    return out


def _tvf_search(name: str) -> list[Path]:
    """Look for a TVF wiki. We expect to find these under UC_generated/
    etoro_kpi_prep / Views (since most TVFs were materialised as views) and
    sometimes under db_schema/etoro/Wiki/.../Functions/."""
    out: list[Path] = []
    # Reject tokens with glob metacharacters or path separators — they're not
    # valid object names and would corrupt the glob pattern.
    if not name or any(c in name for c in '*?[]/\\\n\r\t'):
        return out
    name_lower = name.lower()
    # UC_generated/etoro_kpi_prep/Views/{name}.md (may be lower-cased)
    cand1 = UC_GENERATED / "etoro_kpi_prep" / "Views" / f"{name_lower}.md"
    if cand1.exists():
        out.append(cand1)
    cand2 = UC_GENERATED / "etoro_kpi_prep" / "Views" / f"{name}.md"
    if cand2.exists() and cand2 not in out:
        out.append(cand2)
    # db_schema functions
    fn_root = PROD_SCHEMAS / "DB_Schema" / "etoro" / "Wiki"
    if fn_root.is_dir():
        # Use rglob — pathlib's glob() rejects '**' mixed with other chars in
        # the same path component on Python < 3.13.
        for cand in fn_root.rglob(f"*{name}*.md"):
            if "function" in cand.parent.name.lower() and cand not in out:
                out.append(cand)
    return out


def _resolve_single_token(tok: str) -> tuple[list[Path], list[str]]:
    """Resolve a single token (no 'via') and return (paths, notes)."""
    notes: list[str] = []
    tok = _clean_token(tok)
    if not tok:
        return [], ["empty source token"]
    # Sentinel: explicit no-upstream markers
    if _is_sentinel_no_source(tok):
        return [], [f"sentinel {tok!r}: explicitly declares no upstream wiki"]
    # Verbose prose wrappers — strip them and recurse with the inner symbol.
    inner = _unwrap_prose(tok)
    if inner is not None and inner != tok:
        paths, sub_notes = _resolve_single_token(inner)
        return paths, [f"unwrapped prose {tok!r} -> {inner!r}: {n}" for n in sub_notes]
    # 3-part name `A.B.C` — try several interpretations:
    #   * UC FQN  `main.schema.table`  →  UC_generated/<schema>/[Tables|Views]/<table>.md
    #   * Synapse `DWH_dbo.Schema.Table` (rare; routes via folder)
    #   * Schema.Table.<Column>  → drop trailing column segment and retry as A.B
    m3 = _THREE_PART_NAME_RE.match(tok)
    if m3:
        a, b, c = m3.group(1), m3.group(2), m3.group(3)
        uc_paths = _resolve_uc_three_part(a, b, c)
        if uc_paths:
            return uc_paths, [f"matched UC 3-part {a}.{b}.{c} → {len(uc_paths)} candidate(s)"]
        # Synapse folder.Schema.Table — folder is in known list
        if a.lower() in _SYNAPSE_DB_FOLDER_TOKENS:
            sp = _resolve_synapse_dbo(a, b)  # b is the table name, c is likely column
            if sp:
                return sp, [f"matched synapse {a}.{b} (dropped .{c} suffix) → {len(sp)} candidate(s)"]
        # Drop the trailing segment (likely a column name) and recurse as A.B
        paths_2, notes_2 = _resolve_single_token(f"{a}.{b}")
        if paths_2:
            return paths_2, [f"3-part {a}.{b}.{c}: dropped trailing .{c} → "] + notes_2
        notes.append(f"3-part name {a}.{b}.{c} unresolved")

    # Schema.Table OLTP / synapse-dbo / sibling
    m = _SCHEMA_TABLE_RE.match(tok)
    if m:
        schema, table = m.group(1), m.group(2)
        # First: is this a synapse DB folder (DWH_dbo, BI_DB_dbo, Dealing_dbo,
        # etc.)? If so, route directly to that folder.
        if schema.lower() in _SYNAPSE_DB_FOLDER_TOKENS:
            sp = _resolve_synapse_dbo(schema, table)
            if sp:
                return sp, [f"matched synapse-dbo {schema}.{table} → {len(sp)} candidate(s)"]
            notes.append(f"synapse folder {schema} known but {table}.md not found")
        # Upstream Schema.Table OLTP
        paths = _resolve_schema_table(schema, table)
        if paths:
            return paths, [f"matched Schema.Table → {len(paths)} candidate(s)"]
        # Sibling search by table name as a last resort
        sib = _sibling_synapse_search(table)
        if sib:
            return sib, notes + [f"fallback sibling-search hit by table name → {len(sib)}"]
        # Fallback: the FIRST segment may itself be a sibling table/view name,
        # and the SECOND segment is a column qualifier. Try `schema` as a
        # bare name (e.g. `Fact_SnapshotEquity.Credit` → Fact_SnapshotEquity).
        sib2 = _sibling_synapse_search(schema)
        if sib2:
            return sib2, notes + [
                f"fallback: treated {schema}.{table} as table.column, "
                f"matched {schema} → {len(sib2)} candidate(s)"
            ]
        return [], notes + [f"Schema.Table {schema}.{table} unresolved"]
    # TVF
    if tok.lower().startswith(_TVF_PREFIXES):
        paths = _tvf_search(tok)
        if paths:
            return paths, [f"matched TVF → {len(paths)} candidate(s)"]
        return [], [f"TVF {tok} not found in UC_generated/etoro_kpi_prep or db_schema functions"]
    # Bare name → sibling synapse search
    paths = _sibling_synapse_search(tok)
    if paths:
        return paths, [f"matched sibling synapse wiki → {len(paths)} candidate(s)"]
    return [], [f"bare name {tok!r} not found in sibling synapse wikis"]


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
def resolve(raw_source: str) -> Resolution:
    """Resolve a `(Tier 1 -- X)` source text to one or more wiki paths."""
    res = Resolution(raw_source=raw_source)
    primary, secondary = _split_via(raw_source)
    res.primary = primary
    res.secondary = secondary

    # 1. Try the primary first
    paths, notes = _resolve_single_token(primary)
    res.candidate_paths.extend(paths)
    res.notes.extend([f"primary={primary!r}: {n}" for n in notes])

    # 2. If primary failed AND we have a secondary, try it.
    if not paths and secondary:
        paths2, notes2 = _resolve_single_token(secondary)
        if paths2:
            res.candidate_paths.extend(paths2)
            res.notes.extend([f"secondary={secondary!r}: {n}" for n in notes2])
        else:
            res.notes.extend([f"secondary={secondary!r}: {n}" for n in notes2])

    # 3. Also add the secondary as additional candidates (some claims like
    #    "V_Liabilities via Fact_SnapshotEquity" are *deliberately* asserting
    #    that the column passes through both; we want to inspect both).
    if secondary and paths:
        paths2, notes2 = _resolve_single_token(secondary)
        for p in paths2:
            if p not in res.candidate_paths:
                res.candidate_paths.append(p)
        if paths2:
            res.notes.extend([f"secondary={secondary!r} (added as additional): {n}" for n in notes2])
    return res


def is_oltp_path(p: Path) -> bool:
    """A wiki under ProdSchemas/ is treated as an OLTP source-of-truth."""
    try:
        p.relative_to(PROD_SCHEMAS)
        return True
    except ValueError:
        return False


def is_uc_generated_path(p: Path) -> bool:
    try:
        p.relative_to(UC_GENERATED)
        return True
    except ValueError:
        return False


def is_synapse_path(p: Path) -> bool:
    try:
        p.relative_to(SYNAPSE_WIKI)
        return True
    except ValueError:
        return False
