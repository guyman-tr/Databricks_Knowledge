"""Deterministic verifier for the DWH judge.

Reads the structured claims emitted by extract_wiki_claims.py and compares each
one to the truth snapshot produced by fetch_truth_snapshot.py. Emits violations
to ``knowledge/_dwh_deterministic_violations.csv``.

Verifiable claim types:
  type        Wiki cell says ``int`` etc.; DDL gives ``data_type``.
  nullable    Wiki cell says YES/NO; DDL gives ``is_nullable``.
  default     Wiki prose ``Default=X``; DDL gives ``column_default``.
  fk_ref      Wiki prose ``FK to Dim_X.Y``; DDL must contain Dim_X and column Y.
  codepoint   Wiki prose ``N=Label``; resolved via ``_dictionary_truth.json``.
  lineage_tag Wiki tag ``Tier 1 - X``; X must resolve to a real object
              (DWH table, SP body, or upstream wiki file).

All other claim types (``description``, ``tbl_description``) are not
deterministically verifiable and are punted to the LLM stage.

Every emitted violation row carries:
  object, column, claim_type, wiki_value, truth_value, truth_source,
  wiki_file, wiki_line, verdict_source='deterministic', verdict='WRONG',
  raw_context.

Usage:
    python tools/dwh_judge/verify_deterministic.py
"""
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SNAP = REPO / "knowledge" / "_dwh_truth_snapshot"
CLAIMS_CSV = REPO / "knowledge" / "_dwh_wiki_claims.csv"
DICT_TRUTH = REPO / "knowledge" / "_dictionary_truth.json"
OUT_CSV = REPO / "knowledge" / "_dwh_deterministic_violations.csv"


def _load_json(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------
# Type normalisation
# ---------------------------------------------------------------------------

TYPE_PAREN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\((.+?)\)\s*$")
_TYPE_ALIASES = {
    "integer": "int",
    "bool": "bit",
    "boolean": "bit",
    "datetime2": "datetime2",
    "smalldatetime": "smalldatetime",
}


def _norm_type(raw: str) -> str:
    s = raw.strip().lower()
    s = s.replace("`", "")
    s = _TYPE_ALIASES.get(s, s)
    return s


_TYPES_WITH_IMPLICIT_DEFAULT_PRECISION = {
    # INFORMATION_SCHEMA returns just "datetime2" / "time" / "datetimeoffset"
    # even though the SQL Server default precision is 7. Wiki commonly writes
    # the explicit "(7)" form.
    "datetime2", "time", "datetimeoffset",
}


def _type_matches(wiki_raw: str, ddl_col: dict) -> tuple[bool, str]:
    """Return (matches, ddl_pretty). Compares wiki type cell to DDL spec."""
    ddl_type = (ddl_col["data_type"] or "").lower()
    char_max = ddl_col.get("char_max_len")
    num_prec = ddl_col.get("numeric_precision")
    num_scale = ddl_col.get("numeric_scale")

    if ddl_type in {"varchar", "char", "nvarchar", "nchar", "varbinary", "binary"} and char_max is not None:
        if char_max == -1:
            ddl_pretty = f"{ddl_type}(max)"
        else:
            ddl_pretty = f"{ddl_type}({char_max})"
    elif ddl_type in {"decimal", "numeric"} and num_prec is not None:
        ddl_pretty = f"{ddl_type}({num_prec},{num_scale or 0})"
    else:
        ddl_pretty = ddl_type

    wiki_norm = _norm_type(wiki_raw)

    # Accept either short form (no length) or full form.
    if wiki_norm == ddl_type:
        return True, ddl_pretty
    if wiki_norm == ddl_pretty:
        return True, ddl_pretty
    m_wiki = TYPE_PAREN.match(wiki_norm)
    if m_wiki and m_wiki.group(1) == ddl_type:
        wiki_paren = wiki_norm
        if wiki_paren == ddl_pretty:
            return True, ddl_pretty
        # Implicit-default precision types: "datetime2(7)" == "datetime2".
        if ddl_type in _TYPES_WITH_IMPLICIT_DEFAULT_PRECISION:
            return True, ddl_pretty
    return False, ddl_pretty


# ---------------------------------------------------------------------------
# Default normalisation
# ---------------------------------------------------------------------------

_DEFAULT_PAREN = re.compile(r"^\(+(.+?)\)+$")


def _norm_default(raw: str | None) -> str:
    if raw is None:
        return ""
    s = raw.strip().rstrip(".,;:")
    while True:
        m = _DEFAULT_PAREN.match(s)
        if not m:
            break
        s = m.group(1).strip()
    # Strip wrapping quotes
    if (s.startswith("'") and s.endswith("'")) or (s.startswith('"') and s.endswith('"')):
        s = s[1:-1]
    return s.lower()


def _default_matches(wiki_value: str, ddl_default: str | None) -> tuple[bool, str]:
    norm_wiki = _norm_default(wiki_value)
    norm_ddl = _norm_default(ddl_default)
    if norm_ddl == "":
        return False, "(no default in DDL)"
    if norm_wiki == norm_ddl:
        return True, ddl_default or ""
    if norm_wiki in norm_ddl or norm_ddl in norm_wiki:
        return True, ddl_default or ""
    return False, ddl_default or ""


# ---------------------------------------------------------------------------
# FK reference resolution
# ---------------------------------------------------------------------------

FK_REF_RE = re.compile(r"^([A-Za-z_][\w]*)(?:\.([A-Za-z_][\w]*))?(?:\.([A-Za-z_][\w]*))?$")


def _fk_resolves(ref: str, ddl: dict, prod_tables: dict) -> tuple[str, str, str]:
    """Verify ``X.Y`` or ``Schema.X.Y`` resolves either to a DWH_dbo object
    or to an upstream production wiki we have on file.

    Returns ``(verdict, truth_value, truth_source)`` where verdict is one of
    {MATCH, UNVERIFIABLE, WRONG}. UNVERIFIABLE is used when the reference is
    syntactically valid but we have no Tier-1 source to check against -- the
    LLM stage will look at it.
    """
    m = FK_REF_RE.match(ref)
    if not m:
        return "WRONG", "(unparseable FK ref)", ""
    parts = [p for p in m.groups() if p]
    if len(parts) == 3:
        schema, tbl, col = parts
    elif len(parts) == 2:
        schema, tbl, col = None, parts[0], parts[1]
    else:
        schema, tbl, col = None, parts[0], None

    # Case 1: explicit DWH_dbo qualifier.
    if schema == "DWH_dbo":
        if tbl not in ddl:
            return "WRONG", f"(no such object in DWH_dbo: {tbl})", "INFORMATION_SCHEMA.TABLES"
        if col is None:
            return "MATCH", tbl, f"DWH_dbo.{tbl}"
        cols = {c["name"] for c in ddl[tbl]["columns"]}
        if col not in cols:
            return "WRONG", f"(no such column: DWH_dbo.{tbl}.{col})", \
                f"INFORMATION_SCHEMA.COLUMNS[{tbl}]"
        return "MATCH", f"{tbl}.{col}", f"DWH_dbo.{tbl}.{col}"

    # Case 2: explicit non-DWH schema (Dictionary.X, Customer.X, etc.).
    if schema is not None:
        key = f"{schema}.{tbl}"
        if key in prod_tables:
            return "MATCH", key, prod_tables[key]
        return "UNVERIFIABLE", f"(no upstream wiki for {key})", ""

    # Case 3: unqualified reference (no schema). Try DWH_dbo first, then any
    # production schema.
    if tbl in ddl:
        if col is None:
            return "MATCH", tbl, f"DWH_dbo.{tbl}"
        cols = {c["name"] for c in ddl[tbl]["columns"]}
        if col not in cols:
            return "WRONG", f"(no such column: DWH_dbo.{tbl}.{col})", \
                f"INFORMATION_SCHEMA.COLUMNS[{tbl}]"
        return "MATCH", f"{tbl}.{col}", f"DWH_dbo.{tbl}.{col}"

    for key, rel in prod_tables.items():
        if key.endswith(f".{tbl}"):
            return "MATCH", key, rel

    return "UNVERIFIABLE", f"(no DWH or upstream object: {ref})", ""


# ---------------------------------------------------------------------------
# Codepoint verification (lean reuse -- the previous remediation pipeline
# applied the heavy guards already).
# ---------------------------------------------------------------------------

def _normalize_label(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip().lower())


def _resolve_truth_key(column: str, dict_truth: dict, wiki_file: str) -> dict | None:
    """Same heuristics as tools/audit_codepoint_claims.py:
    1) Try column verbatim.
    2) Try column with ID stripped if it ends with 'ID'.
    3) Try schema-scoped variants (@eMoney / @EXW) -- not applicable here
       since DWH_dbo lives in the DWH bucket only.
    """
    candidates = [column]
    if column.endswith("ID") and len(column) > 2:
        candidates.append(column[:-2])
    for k in candidates:
        if k in dict_truth:
            entry = dict_truth[k]
            if entry.get("alias_of"):
                aliased = dict_truth.get(entry["alias_of"])
                if aliased:
                    return aliased
            return entry
    return None


def _codepoint_verdict(column: str, codepoint: str, claimed_label: str, dict_truth: dict, wiki_file: str) -> tuple[str, str, str]:
    """Returns (verdict, truth_value, truth_source).

    verdict in {MATCH, MISMATCH, UNKNOWN_CODEPOINT, UNRESOLVED_DICTIONARY}.
    """
    entry = _resolve_truth_key(column, dict_truth, wiki_file)
    if entry is None:
        return "UNRESOLVED_DICTIONARY", "", "(no dictionary for column)"

    rows = entry.get("rows", {})
    src = f"{entry.get('schema', '?')}.{entry.get('table', '?')}.{entry.get('name_col', 'Name')}"

    truth_label = rows.get(str(codepoint))
    if truth_label is None:
        return "UNKNOWN_CODEPOINT", "(codepoint not in dictionary)", src

    claim_norm = _normalize_label(claimed_label)
    truth_norm = _normalize_label(truth_label)
    if claim_norm == truth_norm:
        return "MATCH", truth_label, src
    # Tolerate when wiki value is a clean prefix of truth, e.g. "Stop Loss"
    # vs "Stop Loss (via trade server)".
    if truth_norm.startswith(claim_norm + " ") or truth_norm.startswith(claim_norm + "("):
        return "MATCH", truth_label, src
    return "MISMATCH", truth_label, src


# ---------------------------------------------------------------------------
# Lineage-tag verification
# ---------------------------------------------------------------------------

LINEAGE_DIM_RE = re.compile(r"\b(Dim_[A-Za-z0-9_]+)\b")
LINEAGE_SP_RE = re.compile(r"\b(SP_[A-Za-z0-9_]+)\b")
LINEAGE_DICT_RE = re.compile(r"\bDictionary\.([A-Za-z0-9_]+)\b")
LINEAGE_TABLE_RE = re.compile(r"\b([A-Z][A-Za-z0-9_]+)\.([A-Za-z][A-Za-z0-9_]+)\b")


_TIER_TOLERATE_PREFIXES = (
    "tier 3", "tier 4", "tier 5",
    "tier 2b", "tier 3b",
)
# Synapse schemas we do NOT snapshot but recognise as legitimate.
_KNOWN_STAGING_PREFIXES = (
    "DWH_staging.", "DWH_Migration.", "DWH_arc.", "DWH_DataMart.",
    "DataLake.", "ExternalTables.", "Stage.", "Stg.",
)


def _lineage_verdict(tag_value: str, ddl: dict, sp_code: dict, upstream: dict) -> tuple[str, str, str]:
    """Try to resolve a Tier-N lineage tag to a real DWH or upstream object.

    Strategy: collect every SPECIFIC reference in the tag (Dim_X, SP_X, or
    qualified <Sch>.<Tbl>). If at least one resolves -> MATCH. If specific
    refs exist but NONE resolves -> WRONG. If no specific refs exist at all
    (free-form prose like "Tier 2 - SP passthrough") -> TOLERATED; the LLM
    judge can take it from there.

    Tier 3+ tags are TOLERATED by definition (Tier 1/2 is the verifiable
    truth bar; Tier 3+ is annotation / speculation).
    """
    prod_tables = upstream.get("prod_tables", {})

    low = tag_value.lower()
    if any(low.startswith(p) for p in _TIER_TOLERATE_PREFIXES):
        return "TOLERATED", tag_value, "(Tier 3+ annotation)"

    # If the tag references a staging schema we don't snapshot, tolerate.
    if any(prefix in tag_value for prefix in _KNOWN_STAGING_PREFIXES):
        return "TOLERATED", tag_value, "(non-snapshot Synapse schema)"

    # Pull every candidate reference out of the tag.
    specific_refs: list[tuple[str, str]] = []   # (kind, value)
    for d in LINEAGE_DIM_RE.findall(tag_value):
        specific_refs.append(("dim", d))
    for sp in LINEAGE_SP_RE.findall(tag_value):
        specific_refs.append(("sp", sp))
    for sch, obj in LINEAGE_TABLE_RE.findall(tag_value):
        if sch.lower() in {"tier"} or sch.startswith("Dim_") or sch.startswith("SP_"):
            continue
        # If <sch> is itself a DWH_dbo object, treat the pair as
        # "DWH object.column" not "Schema.Table".
        if sch in ddl:
            specific_refs.append(("dwh_col", f"{sch}.{obj}"))
        else:
            specific_refs.append(("qualified", f"{sch}.{obj}"))

    if not specific_refs:
        return "TOLERATED", tag_value, "(free-form Tier-N annotation)"

    sp_names = list(sp_code.keys())
    for kind, val in specific_refs:
        if kind == "dim" and val in ddl:
            return "MATCH", val, f"DWH_dbo.{val}"
        if kind == "sp":
            if val in sp_code:
                return "MATCH", val, f"DWH_dbo.{val}"
            # Tolerate the family-of-SPs shorthand
            # (e.g. "SP_Dim_Position" -> SP_Dim_Position_DL_To_Synapse).
            for sp in sp_names:
                if sp.startswith(val + "_"):
                    return "MATCH", sp, f"DWH_dbo.{sp}"
        if kind == "qualified" and val in prod_tables:
            return "MATCH", val, prod_tables[val]
        if kind == "qualified":
            sch, _, obj = val.partition(".")
            if sch == "DWH_dbo" and obj in ddl:
                return "MATCH", val, f"DWH_dbo.{obj}"
        if kind == "dwh_col":
            tbl, _, col = val.partition(".")
            cols = {c["name"] for c in ddl[tbl]["columns"]}
            if col in cols:
                return "MATCH", val, f"DWH_dbo.{tbl}.{col}"

    pretty = ", ".join(v for _, v in specific_refs)
    return "WRONG", pretty, "(no Dim_/SP_/upstream resolves)"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print("Loading snapshot & claims...", flush=True)
    ddl = _load_json(SNAP / "ddl.json")
    sp_code = _load_json(SNAP / "sp_code.json")
    fks = _load_json(SNAP / "fks.json")
    upstream = _load_json(SNAP / "upstream_index.json")
    dict_truth = _load_json(DICT_TRUTH)

    rows_in = list(csv.DictReader(CLAIMS_CSV.open(encoding="utf-8")))
    print(f"  ddl: {len(ddl)} objects, {sum(len(v['columns']) for v in ddl.values())} cols",
          flush=True)
    print(f"  sp_code: {len(sp_code)}, upstream files: {len(upstream.get('files', {}))}",
          flush=True)
    print(f"  claims: {len(rows_in)}", flush=True)

    violations: list[dict] = []
    counters = {"type": [0, 0], "nullable": [0, 0], "default": [0, 0],
                "fk_ref": [0, 0], "codepoint": [0, 0], "lineage_tag": [0, 0]}

    for r in rows_in:
        ct = r["claim_type"]
        if ct not in counters:
            continue  # description / tbl_description -> LLM stage
        counters[ct][0] += 1
        obj = r["object"]
        col = r["column"]
        wiki_value = r["claim_value"]
        wiki_file = r["wiki_file"]
        wiki_line = int(r["wiki_line"])
        raw_ctx = r["raw_context"]

        ddl_obj = ddl.get(obj)
        ddl_col = None
        if ddl_obj is not None and col:
            for c in ddl_obj["columns"]:
                if c["name"] == col:
                    ddl_col = c
                    break

        verdict = None
        truth_value = ""
        truth_source = ""

        if ct == "type":
            if ddl_col is None:
                if ddl_obj is None:
                    verdict = "WRONG"
                    truth_value = "(no such object in DWH_dbo)"
                    truth_source = "INFORMATION_SCHEMA.TABLES"
                else:
                    verdict = "WRONG"
                    truth_value = "(no such column in object)"
                    truth_source = f"INFORMATION_SCHEMA.COLUMNS[{obj}]"
            else:
                ok, ddl_pretty = _type_matches(wiki_value, ddl_col)
                if not ok:
                    verdict = "WRONG"
                    truth_value = ddl_pretty
                    truth_source = f"INFORMATION_SCHEMA.COLUMNS[{obj}.{col}].DATA_TYPE"

        elif ct == "nullable":
            if ddl_col is None:
                if ddl_obj is None:
                    verdict = "WRONG"
                    truth_value = "(no such object in DWH_dbo)"
                    truth_source = "INFORMATION_SCHEMA.TABLES"
                else:
                    verdict = "WRONG"
                    truth_value = "(no such column in object)"
                    truth_source = f"INFORMATION_SCHEMA.COLUMNS[{obj}]"
            else:
                wiki_yes = wiki_value.upper().startswith("Y")
                if wiki_yes != ddl_col["is_nullable"]:
                    verdict = "WRONG"
                    truth_value = "YES" if ddl_col["is_nullable"] else "NO"
                    truth_source = f"INFORMATION_SCHEMA.COLUMNS[{obj}.{col}].IS_NULLABLE"

        elif ct == "default":
            if ddl_col is None:
                # If column doesn't exist we already complain elsewhere; skip
                # to avoid duplicate noise.
                pass
            else:
                ok, ddl_pretty = _default_matches(wiki_value, ddl_col.get("column_default"))
                if not ok:
                    verdict = "WRONG"
                    truth_value = ddl_pretty or "(no default in DDL)"
                    truth_source = f"INFORMATION_SCHEMA.COLUMNS[{obj}.{col}].COLUMN_DEFAULT"

        elif ct == "fk_ref":
            v, tv, src = _fk_resolves(wiki_value, ddl, upstream.get("prod_tables", {}))
            if v == "WRONG":
                verdict = "WRONG"
                truth_value = tv
                truth_source = src or "INFORMATION_SCHEMA.COLUMNS"
            # UNVERIFIABLE / MATCH -> no flag

        elif ct == "codepoint":
            # Codepoint claim_value is "N=Label" or "(N) Label"
            m = re.match(r"^\(?(\d{1,4})\)?\s*=?\s*(.+)$", wiki_value)
            if not m:
                continue
            n, claimed = m.group(1), m.group(2).strip()
            v, truth_label, src = _codepoint_verdict(col, n, claimed, dict_truth, wiki_file)
            if v == "MISMATCH":
                verdict = "WRONG"
                truth_value = f"{n}={truth_label}"
                truth_source = src
            elif v == "UNKNOWN_CODEPOINT":
                verdict = "WRONG"
                truth_value = truth_label
                truth_source = src
            # UNRESOLVED_DICTIONARY -> not flagged (no Tier-1 truth available)

        elif ct == "lineage_tag":
            v, tv, src = _lineage_verdict(wiki_value, ddl, sp_code, upstream)
            if v == "WRONG":
                verdict = "WRONG"
                truth_value = tv
                truth_source = src

        if verdict == "WRONG":
            counters[ct][1] += 1
            violations.append({
                "object": obj,
                "column": col,
                "claim_type": ct,
                "wiki_value": wiki_value,
                "truth_value": truth_value,
                "truth_source": truth_source,
                "wiki_file": wiki_file,
                "wiki_line": wiki_line,
                "verdict_source": "deterministic",
                "verdict": "WRONG",
                "raw_context": raw_ctx,
            })

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "object", "column", "claim_type", "wiki_value", "truth_value",
            "truth_source", "wiki_file", "wiki_line", "verdict_source",
            "verdict", "raw_context",
        ])
        w.writeheader()
        for v in violations:
            w.writerow(v)

    print(f"\nDeterministic verifier results:")
    for ct, (total, wrong) in counters.items():
        print(f"  {ct:<14} checked={total:<6} WRONG={wrong}")
    print(f"\nWrote {OUT_CSV.relative_to(REPO)} ({len(violations)} rows)")


if __name__ == "__main__":
    main()
