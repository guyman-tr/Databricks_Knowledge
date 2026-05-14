"""
Residual PI-slop sweep: catch paraphrased "Popular Investor" claims that the
narrow regex patterns in audit_pi_label_slop.py missed.

Approach: scan every ALTER ... ALTER COLUMN ... COMMENT and COMMENT ON COLUMN
statement in knowledge/synapse/Wiki/. Flag any whose comment body mentions
"Popular Investor" UNLESS the column is one where PI is a legitimate concept
(GuruStatus, IsPI, IsPopularInvestor, NumOfGurus, NumOfCopiers, etc.).

Remediation is surgical text substitution:
  "Popular Investor"   -> "Internal"
  "popular investor"   -> "Internal"
The original surrounding logic gates (PlayerLevelID=4 etc.) stay intact and
become correctly labeled as "Internal".

Writes:
  knowledge/_pi_residue_audit.csv
  knowledge/_pi_residue_remediation.alter.sql

By default rewrites wiki source files in place (--audit-only to skip).
"""
from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"

AUDIT_CSV = REPO / "knowledge" / "_pi_residue_audit.csv"
REMEDIATION_SQL = REPO / "knowledge" / "_pi_residue_remediation.alter.sql"

# Only these columns are *definitively* slop-prone when they mention "Popular
# Investor". Every other column in the wiki that mentions "Popular Investor"
# is treated as legitimate (PI compensation columns, copier lineage columns,
# guru-status columns, etc.) and left untouched.

# Logic-gate columns: surgical "Popular Investor" -> "Internal" fix is enough
# because the rest of the gate ("PlayerLevelID != 4", "label 30/26", etc.) is
# already correct.
SURGICAL_COLS = {
    "IsValidCustomer", "IsCreditReportValidCB", "IsValidETM",
}

# PlayerLevel-family columns: surgical fix is NOT enough because the wider
# codepoint enumeration is wrong too (e.g. "1=Standard; 4=Popular Investor;
# 7=VIP" -> the correct values are 1=Bronze, 4=Internal, 7=Diamond). Use a
# full canonical rewrite.
CANONICAL_COLS = {
    "PlayerLevelID", "Club", "ClubID", "PlayerLevel", "Tier", "CurrentTier",
}

CANONICAL_PLAYERLEVEL = (
    "Customer player-level tier. FK to DWH_dbo.Dim_PlayerLevel. "
    "Per dictionary (verified 2026-05-13): 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, "
    "4=Internal (in-house / eToro-employee accounts), 5=Silver, 6=Platinum Plus, "
    "7=Diamond. NOT a Popular Investor signal (PI is tracked by GuruStatusID). "
    "NOT a demo flag (demo is AccountTypeID=2). Default=0. "
    "(Tier 2 - DWH_dbo.Dim_PlayerLevel)"
)

# ALTER TABLE / ALTER VIEW with ALTER COLUMN <col> COMMENT '...';
ALTER_RE = re.compile(
    r"^(?P<head>(?:ALTER\s+TABLE|ALTER\s+VIEW)\s+(?P<uc>[\w.`]+)\s+"
    r"ALTER\s+COLUMN\s+`?(?P<col>\w+)`?\s+COMMENT\s+')"
    r"(?P<body>(?:[^']|'')*)"
    r"(?P<tail>'\s*;\s*)$",
    re.IGNORECASE,
)

# COMMENT ON COLUMN ...
COMMENT_RE = re.compile(
    r"^(?P<head>COMMENT\s+ON\s+COLUMN\s+(?P<uc>[\w.`]+)\.`?(?P<col>\w+)`?\s+IS\s+')"
    r"(?P<body>(?:[^']|'')*)"
    r"(?P<tail>'\s*;\s*)$",
    re.IGNORECASE,
)

PI_PHRASE = re.compile(r"Popular[\s\-]+Investor", re.IGNORECASE)


def _classify_column(column: str) -> str | None:
    """Return 'surgical' for IsValid*-family slop, 'canonical' for PlayerLevel-
    family slop, None for everything else (legitimate PI mention -- leave it
    alone)."""
    if column in SURGICAL_COLS:
        return "surgical"
    if column in CANONICAL_COLS:
        return "canonical"
    return None


# If the body already contains one of these canonical disclaimer markers, the
# comment was already corrected by the earlier PI audit and any further
# substitution would CORRUPT the meaning (it would turn the correct disclaimer
# "Popular Investors are tracked by GuruStatusID and are NOT excluded by this
# flag" into "Internals are tracked..." which is the opposite of the truth).
ALREADY_CORRECT_MARKERS = (
    "tracked by GuruStatusID",
    "PI is tracked by GuruStatusID",
)


def _already_correct(body: str) -> bool:
    return any(marker in body for marker in ALREADY_CORRECT_MARKERS)


def _surgical_fix(body: str) -> str:
    return PI_PHRASE.sub("Internal", body)


def _walk_statements(text: str):
    """Yield (start_line, end_line, raw_text, is_multi) for each statement."""
    lines = text.splitlines(keepends=False)
    i = 0
    while i < len(lines):
        s = lines[i].lstrip()
        upper = s.upper()
        is_open = (upper.startswith("ALTER TABLE") or upper.startswith("ALTER VIEW")
                   or upper.startswith("COMMENT ON COLUMN"))
        if not is_open:
            i += 1
            continue
        # Gather until ';' that closes the statement
        buf = [lines[i]]
        j = i
        while not buf[-1].rstrip().endswith(";") and j + 1 < len(lines):
            j += 1
            buf.append(lines[j])
        combined = "\n".join(buf)
        yield (i + 1, j + 1, combined)
        i = j + 1


def scan_file(p: Path) -> list[dict]:
    text = p.read_text(encoding="utf-8", errors="ignore")
    hits: list[dict] = []
    for start, _end, raw in _walk_statements(text):
        # Collapse newlines+indent into single spaces to match the single-line regex
        compact = re.sub(r"\s+", " ", raw).strip()
        m = ALTER_RE.match(compact) or COMMENT_RE.match(compact)
        if not m:
            continue
        body = m.group("body")
        if not PI_PHRASE.search(body):
            continue
        col = m.group("col")
        kind = _classify_column(col)
        if kind is None:
            continue
        if _already_correct(body):
            continue
        if kind == "surgical":
            new_body = _surgical_fix(body)
        else:  # canonical
            new_body = CANONICAL_PLAYERLEVEL.replace("'", "''")
        if new_body == body:
            continue
        new_stmt = m.group("head") + new_body + m.group("tail").rstrip()
        if not new_stmt.endswith(";"):
            new_stmt += ";"
        hits.append({
            "file_relpath": str(p.relative_to(REPO)).replace("\\", "/"),
            "line": start,
            "uc_object": m.group("uc").strip("`"),
            "column": col,
            "fix_kind": kind,
            "original_body": body,
            "new_body": new_body,
            "original_statement": compact,
            "new_statement": new_stmt,
            "raw_statement_in_file": raw,
        })
    return hits


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--audit-only", action="store_true")
    args = ap.parse_args()

    hits: list[dict] = []
    for p in WIKI.rglob("*.alter.sql"):
        hits.extend(scan_file(p))

    if not hits:
        print("No residual PI slop found.")
        return

    files = {h["file_relpath"] for h in hits}
    uc_objs = {h["uc_object"] for h in hits}
    cols = {h["column"] for h in hits}
    print(f"Residual PI-slop hits:        {len(hits)}")
    print(f"Wiki files affected:          {len(files)}")
    print(f"Distinct UC objects:          {len(uc_objs)}")
    print(f"Distinct columns affected:    {len(cols)}")
    print()
    print("By column:")
    by_col: dict[str, int] = {}
    for h in hits:
        by_col[h["column"]] = by_col.get(h["column"], 0) + 1
    for c, n in sorted(by_col.items(), key=lambda kv: -kv[1]):
        print(f"  {c:<36} {n}")

    AUDIT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with AUDIT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "file_relpath", "line", "uc_object", "column", "fix_kind",
            "original_body", "new_body", "new_statement",
        ])
        for h in hits:
            w.writerow([
                h["file_relpath"], h["line"], h["uc_object"], h["column"],
                h["fix_kind"], h["original_body"][:600],
                h["new_body"][:600], h["new_statement"][:1200],
            ])
    print(f"\nWrote audit: {AUDIT_CSV.relative_to(REPO)}")

    # Emit deployable SQL (deduped per (uc_object, column)).
    seen: set[tuple[str, str]] = set()
    sql_lines = [
        "-- =============================================================================\n"
        "-- Residual PI-slop remediation (paraphrased 'Popular Investor' surgical fix)\n"
        "-- Generated by tools/audit_pi_residual.py\n"
        "-- Replaces 'Popular Investor' with 'Internal' in column COMMENTs of columns\n"
        "-- that are NOT about PI (i.e. NOT GuruStatusID / IsPI / NumOfGurus / etc.).\n"
        "-- =============================================================================\n"
    ]
    for h in hits:
        k = (h["uc_object"].lower(), h["column"].lower())
        if k in seen:
            continue
        seen.add(k)
        sql_lines.append(h["new_statement"])
    REMEDIATION_SQL.write_text("\n".join(sql_lines) + "\n", encoding="utf-8")
    print(f"Wrote remediation SQL: {REMEDIATION_SQL.relative_to(REPO)}  "
          f"({len(seen)} unique ALTERs)")

    if args.audit_only:
        print("\n[--audit-only] wiki files not patched.")
        return

    # Patch wiki files in place
    by_file: dict[str, list[dict]] = {}
    for h in hits:
        by_file.setdefault(h["file_relpath"], []).append(h)
    n_patched = 0
    for fr, items in by_file.items():
        p = REPO / fr
        text = p.read_text(encoding="utf-8")
        new_text = text
        for h in items:
            if h["raw_statement_in_file"] in new_text:
                new_text = new_text.replace(h["raw_statement_in_file"],
                                            h["new_statement"], 1)
        if new_text != text:
            p.write_text(new_text, encoding="utf-8")
            n_patched += 1
    print(f"Patched {n_patched} wiki file(s) in place.")


if __name__ == "__main__":
    main()
