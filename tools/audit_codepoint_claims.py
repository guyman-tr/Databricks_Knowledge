"""
Tier-1 vs Tier > 1 judge for codepoint-to-name claims in UC column COMMENTs.

What it does
------------
1) Discovery: walks every .alter.sql in knowledge/synapse/Wiki/. Extracts each
   (file, line, uc_object, column, comment_body) tuple. From the comment body
   it pulls every codepoint-to-name claim that looks like:
       "<digits>=<Word>"        e.g. "1=Bronze"   "26=ILQ"
       "(<digits>) <Word>"      e.g. "(4) Internal"
2) Truth fetch: for each column whose name ends in "ID", maps to the
   DWH_dbo.Dim_<X> dictionary (X = column name minus trailing "ID"). When the
   table exists, fetches every (key, Name) row from live Synapse via MCP-style
   pyodbc connection (or, in --no-db mode, reads from a pre-cached
   knowledge/_dictionary_truth.json). Persists truth to that JSON.
3) Verdict: for each discovered claim, classifies as:
       MATCH                  - claim matches dictionary Name (case-insensitive,
                                with light normalization)
       MISMATCH               - codepoint exists in dictionary, but the asserted
                                label is something else
       UNKNOWN_CODEPOINT      - codepoint not in dictionary
       UNRESOLVED_DICTIONARY  - couldn't find a Dim_<X> table for this column
       SUSPECT_HEURISTIC      - regex hit was clearly garbage (e.g. "100%" or
                                a year); kept for transparency, ignored downstream
4) Output: knowledge/_codepoint_claims_audit.csv with full per-claim rows, plus
   knowledge/_codepoint_claims_summary.csv with one row per
   (column, codepoint, claimed_label) tuple and its global verdict.

This tool does NOT modify wikis or deploy anything. It only writes the two
CSVs and (optionally) refreshes the dictionary cache. A separate stage will
generate the remediation .alter.sql once the user has reviewed the CSVs.

Usage
-----
  # Full live run (queries Synapse via pyodbc); writes audit + summary + truth cache
  python tools/audit_codepoint_claims.py --refresh-truth

  # Use cached truth, skip the DB query
  python tools/audit_codepoint_claims.py --no-db

  # Limit to a subset of columns (useful for spot-checking)
  python tools/audit_codepoint_claims.py --columns PlayerLevelID,RegulationID,LabelID
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"
AUDIT_CSV = REPO / "knowledge" / "_codepoint_claims_audit.csv"
SUMMARY_CSV = REPO / "knowledge" / "_codepoint_claims_summary.csv"
TRUTH_JSON = REPO / "knowledge" / "_dictionary_truth.json"

# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

COMMENT_STMT = re.compile(
    r"(?:ALTER (?:TABLE|VIEW)\s+(?P<uc1>[\w.]+)\s+ALTER COLUMN\s+`?(?P<col1>\w+)`?\s+COMMENT\s+'(?P<body1>(?:[^']|'')*)')"
    r"|"
    r"(?:COMMENT\s+ON\s+COLUMN\s+(?P<uc2>[\w.`]+)\s+IS\s+'(?P<body2>(?:[^']|'')*)')",
    re.IGNORECASE,
)

# Codepoint claim regex. The label is captured as the dictionary-name fragment
# only -- typically 1-5 whitespace-separated tokens whose first token must start
# with an uppercase letter. Each continuation token must also start with an
# uppercase letter, digit, or a structural glyph (&, /, +, -, '). The label
# terminates on:
#   - punctuation [,;.)\]\[]
#   - an opening paren ( e.g. "(Tier 1 - ...)" or "(DWH placeholder)" )
#   - the start of another codepoint claim (whitespace + digits + '=')
#   - the start of a UNVERIFIED tag
#   - end of input
# This avoids the 40-char prose over-capture bug where "7=VIP. Determines
# available features and ri" was previously captured as the label.
_LABEL_TOKEN = r"[A-Z][\w'&+/\-]*"
_LABEL_CONT = r"(?:[ \t]+[A-Z0-9&/+'\-][\w'&+/\-]*){0,4}"
_LABEL_END = r"(?=[,;.)\]\[]|[ \t]*\(|[ \t]+\d+\s*=|[ \t]*\[UNVERIFIED|[ \t]*$)"
ENUM_NEQ = re.compile(
    r"\b(?P<n>\d{1,4})\s*=\s*(?P<label>" + _LABEL_TOKEN + _LABEL_CONT + r")" + _LABEL_END
)
ENUM_PAREN = re.compile(
    r"\((?P<n>\d{1,4})\)\s+(?P<label>" + _LABEL_TOKEN + _LABEL_CONT + r")" + _LABEL_END
)

# Phrases the discovery should ignore if they're not real codepoint claims.
NOISE_LABELS = {
    "year", "default", "id", "name", "year-to-date", "from", "to", "n",
    "tier", "tiers", "type", "types", "code", "codes", "by",
}


@dataclass
class Claim:
    file_relpath: str
    line: int          # 1-indexed start line of the statement
    uc_object: str     # main.<cat>.<schema>.<name>
    column: str
    codepoint: str     # asserted ID (string, may have leading zeros)
    claimed_label: str  # raw label from the comment
    raw_comment: str


def _find_line(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def _trim_label(s: str) -> str:
    s = s.strip().rstrip(".;:,)")
    # Drop trailing parentheticals like "Bronze (94%)" -> "Bronze"
    s = re.sub(r"\s*\([^)]*\)\s*$", "", s).strip()
    # Drop trailing " - explanation" or " — explanation"
    s = re.split(r"\s+[-\u2013\u2014]\s+", s, maxsplit=1)[0].strip()
    return s


def _uc_clean(uc: str) -> str:
    return uc.replace("`", "")


def discover() -> list[Claim]:
    claims: list[Claim] = []
    files = sorted(WIKI.rglob("*.alter.sql"))
    for f in files:
        try:
            text = f.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        rel = str(f.relative_to(REPO)).replace("\\", "/")
        for m in COMMENT_STMT.finditer(text):
            body = (m.group("body1") or m.group("body2") or "").replace("''", "'")
            col = m.group("col1") or _extract_col_from_uc(m.group("uc2") or "")
            uc = _uc_clean(m.group("uc1") or m.group("uc2") or "")
            # If COMMENT ON COLUMN, uc includes the column at the tail; strip it.
            if m.group("uc2"):
                parts = _uc_clean(m.group("uc2")).split(".")
                if len(parts) >= 4:
                    uc = ".".join(parts[:3])
            line = _find_line(text, m.start())
            had_claim = False
            for em in ENUM_NEQ.finditer(body):
                lbl = _trim_label(em.group("label"))
                if lbl.lower() in NOISE_LABELS or not lbl:
                    continue
                claims.append(Claim(rel, line, uc, col or "?", em.group("n"), lbl, body))
                had_claim = True
            for em in ENUM_PAREN.finditer(body):
                lbl = _trim_label(em.group("label"))
                if lbl.lower() in NOISE_LABELS or not lbl:
                    continue
                claims.append(Claim(rel, line, uc, col or "?", em.group("n"), lbl, body))
                had_claim = True
    return claims


def _extract_col_from_uc(uc_with_col: str) -> str:
    parts = _uc_clean(uc_with_col).split(".")
    return parts[-1] if len(parts) >= 4 else ""


# ---------------------------------------------------------------------------
# Truth fetch
# ---------------------------------------------------------------------------

def _connect_synapse():
    import pyodbc
    server = os.environ.get("SYNAPSE_SERVER")
    database = os.environ.get("SYNAPSE_DATABASE")
    username = os.environ.get("SYNAPSE_USERNAME")
    password = os.environ.get("SYNAPSE_PASSWORD")
    if not all([server, database, username, password]):
        raise RuntimeError(
            "Set SYNAPSE_SERVER / SYNAPSE_DATABASE / SYNAPSE_USERNAME / SYNAPSE_PASSWORD "
            "to refresh the truth cache from live Synapse. Alternatively run with --no-db "
            "to use the existing cache at knowledge/_dictionary_truth.json."
        )
    cn = pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};SERVER=" + server +
        ";DATABASE=" + database + ";UID=" + username + ";PWD=" + password +
        ";Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30"
    )
    return cn


def _dim_table_for_column(col: str, known: set[str]) -> str | None:
    """Map a column name to a DWH_dbo.Dim_<X> table if it exists."""
    if not col.lower().endswith("id"):
        return None
    base = col[:-2]
    candidates = [f"Dim_{base}", f"Dim_{base}s"]
    for c in candidates:
        if c in known:
            return c
    return None


def _detect_id_name_columns(cn, dim: str) -> tuple[str, str] | None:
    cur = cn.cursor()
    cur.execute(
        "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS "
        "WHERE TABLE_SCHEMA='DWH_dbo' AND TABLE_NAME=? ORDER BY ORDINAL_POSITION",
        dim,
    )
    cols = [(r[0], r[1]) for r in cur.fetchall()]
    if not cols:
        return None
    int_types = {"int", "bigint", "smallint", "tinyint"}
    name_priority = ["Name", "DisplayName", "Description", "Title", f"{dim[4:]}Name"]
    id_col = None
    for n, t in cols:
        if n.lower() == f"{dim[4:].lower()}id":
            id_col = n
            break
    if not id_col:
        for n, t in cols:
            if n.lower() == "id" and t.lower() in int_types:
                id_col = n
                break
    if not id_col:
        for n, t in cols:
            if t.lower() in int_types:
                id_col = n
                break
    if not id_col:
        return None
    name_col = None
    for cand in name_priority:
        for n, _ in cols:
            if n.lower() == cand.lower():
                name_col = n
                break
        if name_col:
            break
    if not name_col:
        for n, t in cols:
            if t.lower() in {"varchar", "nvarchar", "char", "nchar"} and n != id_col:
                name_col = n
                break
    if not name_col:
        return None
    return id_col, name_col


def fetch_truth(columns_in_scope: set[str], cn) -> dict[str, dict]:
    """Build truth cache: {column_name: {"dim": "Dim_X", "id_col": "...", "name_col": "...", "rows": {"4": "Internal", ...}}}"""
    truth: dict[str, dict] = {}
    cur = cn.cursor()
    cur.execute(
        "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES "
        "WHERE TABLE_SCHEMA='DWH_dbo' AND TABLE_NAME LIKE 'Dim[_]%'"
    )
    known_dims = {r[0] for r in cur.fetchall()}
    for col in sorted(columns_in_scope):
        dim = _dim_table_for_column(col, known_dims)
        if not dim:
            truth[col] = {"dim": None}
            continue
        detected = _detect_id_name_columns(cn, dim)
        if not detected:
            truth[col] = {"dim": dim, "id_col": None, "name_col": None, "rows": {}}
            continue
        id_col, name_col = detected
        try:
            cur.execute(f"SELECT [{id_col}], [{name_col}] FROM DWH_dbo.[{dim}]")
            rows = {str(r[0]): (r[1] or "").strip() for r in cur.fetchall()}
        except Exception as e:
            truth[col] = {"dim": dim, "id_col": id_col, "name_col": name_col, "rows": {}, "error": str(e)[:300]}
            continue
        truth[col] = {"dim": dim, "id_col": id_col, "name_col": name_col, "rows": rows}
    return truth


# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------

def _normalize(s: str) -> str:
    s = s.lower().strip()
    s = re.sub(r"[\s\-_/+]+", " ", s)
    s = re.sub(r"[^a-z0-9 ]", "", s)
    return s.strip()


def _schema_context(file_relpath: str) -> str | None:
    """Return 'eMoney' or 'EXW' if the wiki file lives under those source
    schemas, else None (defaults to DWH-style lookup)."""
    parts = file_relpath.replace("\\", "/").split("/")
    for p in parts:
        pl = p.lower()
        if pl.startswith("emoney_"):
            return "eMoney"
        if pl.startswith("exw_") or pl.startswith("exw_wallet"):
            return "EXW"
    return None


def _resolve_truth_key(column: str, file_relpath: str, truth: dict) -> str | None:
    """Pick the right truth-cache key for a (column, file) pair.

    Priority:
      1) "<column>@<schema_context>"   — most specific (e.g. TransactionTypeID@EXW)
      2) "<column>"                    — default (typically DWH_dbo)
    """
    ctx = _schema_context(file_relpath)
    # Priority order:
    #   1) <col>@<schema>                     -- most specific
    #   2) <col>ID@<schema>                   -- decoded sibling for schema
    #   3) <col>                              -- DWH default
    #   4) <col>ID                            -- decoded sibling for DWH default
    candidates: list[str] = []
    if ctx:
        candidates.append(f"{column}@{ctx}")
        if not column.endswith("ID"):
            candidates.append(f"{column}ID@{ctx}")
    candidates.append(column)
    if not column.endswith("ID"):
        candidates.append(f"{column}ID")
    for key in candidates:
        if key in truth and truth[key].get("rows"):
            return key
    return None


def verdict(claim: Claim, truth: dict) -> tuple[str, str, str]:
    """Return (verdict, truth_name, dictionary_table)."""
    key = _resolve_truth_key(claim.column, claim.file_relpath, truth)
    if key is None:
        return "UNRESOLVED_DICTIONARY", "", ""
    t = truth[key]
    rows: dict[str, str] = t.get("rows") or {}
    dim = t.get("dim") or ""
    if not rows:
        return "UNRESOLVED_DICTIONARY", "", dim
    truth_name = rows.get(claim.codepoint)
    if truth_name is None:
        return "UNKNOWN_CODEPOINT", "", dim
    nc = _normalize(claim.claimed_label)
    nt = _normalize(truth_name)
    if nc == nt:
        return "MATCH", truth_name, dim
    # Tolerate the claim being a clean prefix of the dictionary truth name
    # at a word boundary -- e.g., claim "Stop Loss" vs truth "Stop Loss
    # (via trade server)" or claim "Blocked - Under Investigation" vs truth
    # "Blocked - Under Investigation - VIP". The wiki author wrote the canonical
    # short label; the dictionary appends bracketed/qualifying context. Both
    # refer to the same codepoint.
    if nc and nt.startswith(nc + " "):
        return "MATCH", truth_name, dim
    return "MISMATCH", truth_name, dim


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--refresh-truth", action="store_true",
                    help="Connect to live Synapse and rebuild knowledge/_dictionary_truth.json.")
    ap.add_argument("--no-db", action="store_true",
                    help="Use the cached truth JSON; do not connect to Synapse.")
    ap.add_argument("--columns", default="",
                    help="Comma-separated subset of columns to fetch truth for; default = all "
                         "columns seen in discovery.")
    args = ap.parse_args()

    print("Stage 0 \u2014 Discovery", flush=True)
    claims = discover()
    cols_in_scope = sorted({c.column for c in claims if c.column != "?"})
    print(f"  Claims: {len(claims)}")
    print(f"  Distinct columns: {len(cols_in_scope)}")

    if args.columns:
        wanted = {c.strip() for c in args.columns.split(",") if c.strip()}
        cols_in_scope = [c for c in cols_in_scope if c in wanted]

    print("\nStage 1 \u2014 Truth fetch", flush=True)
    if args.refresh_truth and not args.no_db:
        cn = _connect_synapse()
        truth = fetch_truth(set(cols_in_scope), cn)
        cn.close()
        TRUTH_JSON.parent.mkdir(parents=True, exist_ok=True)
        TRUTH_JSON.write_text(json.dumps(truth, indent=2, sort_keys=True), encoding="utf-8")
        print(f"  Wrote truth cache: {TRUTH_JSON.relative_to(REPO)}")
    else:
        if TRUTH_JSON.is_file():
            truth = json.loads(TRUTH_JSON.read_text(encoding="utf-8"))
            print(f"  Loaded truth cache: {TRUTH_JSON.relative_to(REPO)}  "
                  f"({len(truth)} columns)")
        else:
            truth = {}
            print("  No truth cache and --no-db requested; all verdicts will be UNRESOLVED.")

    print("\nStage 2 \u2014 Verdict", flush=True)
    per_claim: list[tuple[Claim, str, str, str]] = []
    for c in claims:
        v, truth_name, dim = verdict(c, truth)
        per_claim.append((c, v, truth_name, dim))

    AUDIT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with AUDIT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "file_relpath", "line", "uc_object", "column", "codepoint",
            "claimed_label", "verdict", "tier1_truth_name",
            "dictionary_table", "raw_comment",
        ])
        for c, v, truth_name, dim in per_claim:
            w.writerow([
                c.file_relpath, c.line, c.uc_object, c.column, c.codepoint,
                c.claimed_label, v, truth_name, dim, c.raw_comment[:400],
            ])
    print(f"  Wrote per-claim audit: {AUDIT_CSV.relative_to(REPO)}")

    # Summary by (column, codepoint, claimed_label_normalized)
    grouped: dict[tuple[str, str, str, str, str, str], int] = defaultdict(int)
    for c, v, truth_name, _dim in per_claim:
        key = (c.column, c.codepoint, _normalize(c.claimed_label),
               c.claimed_label, v, truth_name)
        grouped[key] += 1

    with SUMMARY_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "column", "codepoint", "claimed_label", "verdict",
            "tier1_truth_name", "occurrences", "claimed_label_normalized",
        ])
        for (col, dig, norm, lbl, v, truth_name), n in sorted(
            grouped.items(),
            key=lambda kv: (
                {"MISMATCH": 0, "UNKNOWN_CODEPOINT": 1, "UNRESOLVED_DICTIONARY": 2, "MATCH": 3}
                .get(kv[0][4], 9),
                -kv[1],
                kv[0][0],
                kv[0][1],
            ),
        ):
            w.writerow([col, dig, lbl, v, truth_name, n, norm])
    print(f"  Wrote summary: {SUMMARY_CSV.relative_to(REPO)}")

    # Final summary table
    print("\nVerdict counts:", flush=True)
    counts: dict[str, int] = defaultdict(int)
    for _, v, _t, _d in per_claim:
        counts[v] += 1
    for v in ("MISMATCH", "UNKNOWN_CODEPOINT", "MATCH", "UNRESOLVED_DICTIONARY"):
        print(f"  {v:<22} {counts.get(v, 0)}")


if __name__ == "__main__":
    main()
