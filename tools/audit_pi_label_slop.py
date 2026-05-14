"""
Audit and remediate the PI/Internal/BonusOnly/ILQ/Dealing codepoint-label slop.

Background
----------
A wrong column COMMENT was authored in knowledge/synapse/Wiki/DWH_dbo/Tables/
Dim_Customer.alter.sql claiming PlayerLevelID=4 means "Popular Investor" and
LabelID=26 means "BonusOnly". Per the live DWH_dbo.Dim_PlayerLevel and Dim_Label
dictionaries (verified 2026-05-13):
  PlayerLevelID:  0=N/A, 1=Bronze, 2=Platinum, 3=Gold, 4=Internal,
                  5=Silver, 6=Platinum Plus, 7=Diamond.
  LabelID 26 = ILQ. LabelID 30 = Dealing.
Popular Investors are tracked by GuruStatusID (FK to Dictionary.GuruStatus),
NOT by PlayerLevelID. PIs ARE valid customers.

The slop ended up in many UC column COMMENTs via individual .alter.sql wiki
files.

What this script does
---------------------
Pass 1 (audit, --audit-only):
  Walk knowledge/synapse/Wiki/ and find every COMMENT that contains the slop
  signatures. Emit knowledge/_pi_label_slop_audit.csv with one row per match:
    file, line, schema, table, column, slop_kind, current_comment,
    proposed_comment, target_uc_object.

Pass 2 (remediate, default):
  In addition to the audit, rewrite the wiki source files in place (so future
  regen does not re-introduce slop) AND emit a single standalone deployable
  remediation script: knowledge/_pi_label_slop_remediation.alter.sql
  That file contains ONE corrected ALTER ... COMMENT ... statement per match.
  It can be run via tools/run_alter_file.py (see --emit-deploy-helper) or via
  any direct databricks.sql executor.

Usage
-----
  python tools/audit_pi_label_slop.py --audit-only
  python tools/audit_pi_label_slop.py            # audit + rewrite + emit
  python tools/audit_pi_label_slop.py --dry-run  # show counts only

Output files
------------
  knowledge/_pi_label_slop_audit.csv               (always)
  knowledge/_pi_label_slop_remediation.alter.sql   (unless --audit-only)
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"

AUDIT_CSV = REPO / "knowledge" / "_pi_label_slop_audit.csv"
REMEDIATION_SQL = REPO / "knowledge" / "_pi_label_slop_remediation.alter.sql"

VERIFIED_DATE = "2026-05-13"

CANONICAL_PLAYERLEVEL = (
    "Customer player-level tier. FK to DWH_dbo.Dim_PlayerLevel. "
    "Per dictionary (verified " + VERIFIED_DATE + "): 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, "
    "4=Internal (in-house / eToro-employee accounts), 5=Silver, 6=Platinum Plus, 7=Diamond. "
    "NOT a Popular Investor signal (PI is tracked by GuruStatusID). "
    "NOT a demo flag (demo is AccountTypeID=2). Default=0. (Tier 2 - DWH_dbo.Dim_PlayerLevel)"
)

CANONICAL_LABELID = (
    "Customer-segment label. FK to DWH_dbo.Dim_Label. "
    "Per dictionary (verified " + VERIFIED_DATE + "): 26=ILQ, 30=Dealing -- both excluded by "
    "IsValidCustomer and used in the BackOffice IsHedged trigger (along with "
    "BackOffice.BonusOnlyCustomers, which is a SEPARATE table-based list, not the same "
    "as LabelID=26). Many other labels exist; query Dim_Label for the full map. "
    "Default=0. (Tier 1 - Customer.CustomerStatic)"
)

CANONICAL_ISVALID = (
    "DWH-computed in SP_Dim_Customer: 1 when PlayerLevelID<>4 AND LabelID NOT IN (30,26) "
    "AND CountryID<>250. Dictionary lookups (verified " + VERIFIED_DATE + "): PlayerLevelID=4 "
    "is Dim_PlayerLevel.Name='Internal' (in-house/employee level); LabelID=30 is "
    "Dim_Label.Name='Dealing' (dealing-desk operational accounts); LabelID=26 is "
    "Dim_Label.Name='ILQ'; CountryID=250 is Dim_Country.Name='eToro' (internal "
    "pseudo-jurisdiction, Abbreviation='ZZ'). Popular Investors are tracked by "
    "GuruStatusID and are NOT excluded by this flag. (Tier 2 - SP_Dim_Customer)"
)

CANONICAL_CREDITCB = (
    "DWH-computed in SP_Dim_Customer: 1 when NOT (PlayerLevelID=4 AND AccountTypeID<>2) "
    "AND LabelID NOT IN (26,30) AND NOT (CountryID=250 AND CID NOT IN "
    "(3400616,10526243,10842855,11464063,21547142,34537826)). Same "
    "Internal/Dealing/ILQ exclusions as IsValidCustomer, PLUS demo-account exclusion "
    "(AccountTypeID<>2), with six hard-coded subsidiary-broker CIDs under "
    "CountryID=250 re-included. Popular Investors are tracked by GuruStatusID and are "
    "NOT excluded by this flag. (Tier 2 - SP_Dim_Customer)"
)


# ---------------------------------------------------------------------------
# Slop signatures
# ---------------------------------------------------------------------------
# Each signature is (slop_kind, column_name_in_comment, regex_on_comment_body).
# The regex matches a portion of the comment that we'll replace with the
# canonical text for that column. We deliberately match on highly specific
# phrases so we don't sweep up legitimate Popular-Investor references in
# unrelated columns (e.g., GuruStatusID/NumOfGurus comments are correct
# and stay untouched).

SLOP_PATTERNS = [
    # PlayerLevelID — Variant A: "1=Standard (94%); 4=Popular Investor; 7=VIP"
    (
        "playerlevelid_v1",
        "PlayerLevelID",
        re.compile(
            r"Customer experience/permission level\. FK to Dictionary\.PlayerLevel\. "
            r"1=Standard \(94%\); 4=Popular Investor; 7=VIP\. Determines available features "
            r"and risk limits\. Default=0\. \(Tier 1 - Customer\.CustomerStatic\)"
        ),
        CANONICAL_PLAYERLEVEL,
    ),
    # PlayerLevelID — Variant B: "Account tier: 4=demo, other values=real tiers"
    (
        "playerlevelid_v2_demo",
        "PlayerLevelID",
        re.compile(
            r"Account tier: 4=demo, other values=real tiers\. DEFAULT 0\. "
            r"Source: Ext_FSC_Real_Customer_Customer\.PlayerLevelID \(CC\)\. "
            r"FK to Dim_PlayerLevel\. Critical for IsValidCustomer \(PlayerLevelID=4 "
            r"excluded\)\. \(Tier 2 - SP_Fact_SnapshotCustomer\)"
        ),
        CANONICAL_PLAYERLEVEL,
    ),
    # LabelID
    (
        "labelid_bonusonly",
        "LabelID",
        re.compile(
            r"Internal segment label\. FK to Dictionary\.Label\. "
            r"LabelID=26 = BonusOnly customer \(triggers IsHedged=0\)\. "
            r"Default=0\. \(Tier 1 - Customer\.CustomerStatic\)"
        ),
        CANONICAL_LABELID,
    ),
    # IsValidCustomer (the original propagated slop)
    (
        "isvalidcustomer_pi",
        "IsValidCustomer",
        re.compile(
            r"DWH-computed: 1 when not Popular Investor \(PlayerLevelID != 4\), "
            r"not label 30/26, and not CountryID=250\. Used in reporting to filter "
            r"out non-standard customers\. \(Tier 2 - SP_Dim_Customer\)"
        ),
        CANONICAL_ISVALID,
    ),
    # IsCreditReportValidCB (the original propagated slop)
    (
        "iscreditreportvalidcb_pi",
        "IsCreditReportValidCB",
        re.compile(
            r"DWH-computed: similar to IsValidCustomer but with additional "
            r"AccountTypeID != 2 exclusion and specific CID exceptions for "
            r"CountryID=250\. \(Tier 2 - SP_Dim_Customer\)"
        ),
        CANONICAL_CREDITCB,
    ),
]


# Regex for an ALTER ... ALTER COLUMN <col> COMMENT '...';
ALTER_LINE = re.compile(
    r"^(?P<head>(?:ALTER TABLE|ALTER VIEW)\s+(?P<uc>[\w.]+)\s+ALTER COLUMN\s+`?(?P<col>\w+)`?\s+COMMENT\s+')"
    r"(?P<body>(?:[^']|'')*)"
    r"(?P<tail>'\s*;\s*)$"
)

# Regex for COMMENT ON COLUMN main.<...>.col IS '...';
COMMENT_ON = re.compile(
    r"^(?P<head>COMMENT\s+ON\s+COLUMN\s+(?P<uc>[\w.]+)\.`?(?P<col>\w+)`?\s+IS\s+')"
    r"(?P<body>(?:[^']|'')*)"
    r"(?P<tail>'\s*;\s*)$"
)


@dataclass
class Match:
    file: Path
    line_no: int  # 1-indexed
    slop_kind: str
    uc_object: str  # e.g. main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_xxx
    column: str
    statement_kind: str  # "ALTER" or "COMMENT_ON"
    old_line: str
    new_line: str


def _find_slop_in_line(line: str) -> tuple[str, str, str] | None:
    """Return (slop_kind, expected_column, canonical_text) if the line body matches
    one of our slop signatures, else None."""
    for slop_kind, col_hint, regex, canonical in SLOP_PATTERNS:
        if regex.search(line):
            return slop_kind, col_hint, canonical
    return None


def scan_file(p: Path) -> list[Match]:
    out: list[Match] = []
    try:
        text = p.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return out
    # Some .alter.sql files have multi-line ALTER statements (split across lines).
    # We normalize by treating each ALTER/COMMENT statement as a single logical
    # line. Statements are terminated by `;`.
    # For our slop, every offending statement appears as ONE physical line in
    # the curated files we saw — but we still handle multi-line just in case.

    # Combine multi-line statements: split on lines ending with `;`.
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        raw = lines[i]
        line_no = i + 1
        # Gather until `;` if the statement opens an ALTER/COMMENT but doesn't terminate.
        stripped = raw.strip()
        is_open = stripped.startswith(("ALTER TABLE", "ALTER VIEW", "COMMENT ON COLUMN"))
        if is_open and not stripped.rstrip().endswith(";"):
            buf = [raw]
            j = i + 1
            while j < len(lines):
                buf.append(lines[j])
                if lines[j].rstrip().endswith(";"):
                    break
                j += 1
            combined = " ".join(b.strip() for b in buf)
            advance = j - i + 1
            phys_line = line_no
        else:
            combined = raw
            advance = 1
            phys_line = line_no

        slop = _find_slop_in_line(combined)
        if slop:
            slop_kind, expected_col, canonical = slop
            m = ALTER_LINE.match(combined) or COMMENT_ON.match(combined)
            if m:
                uc = m.group("uc")
                col = m.group("col")
                stmt_kind = "ALTER" if combined.strip().upper().startswith("ALTER") else "COMMENT_ON"
                # Build the new line — keep `head` and `tail`, replace `body` with
                # the canonical text. Escape any single quotes in canonical.
                canonical_sql = canonical.replace("'", "''")
                new_line = m.group("head") + canonical_sql + m.group("tail").rstrip()
                if not new_line.endswith(";"):
                    new_line += ";"
                out.append(
                    Match(
                        file=p,
                        line_no=phys_line,
                        slop_kind=slop_kind,
                        uc_object=uc,
                        column=col,
                        statement_kind=stmt_kind,
                        old_line=combined.strip(),
                        new_line=new_line.strip(),
                    )
                )
        i += advance
    return out


def collect_all_matches() -> list[Match]:
    matches: list[Match] = []
    for p in WIKI.rglob("*.alter.sql"):
        matches.extend(scan_file(p))
    return matches


def write_audit_csv(matches: list[Match]) -> None:
    AUDIT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with AUDIT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "file_relpath", "line", "slop_kind", "uc_object", "column",
            "statement_kind", "current_statement", "corrected_statement",
        ])
        for m in matches:
            w.writerow([
                str(m.file.relative_to(REPO)).replace("\\", "/"),
                m.line_no,
                m.slop_kind,
                m.uc_object,
                m.column,
                m.statement_kind,
                m.old_line,
                m.new_line,
            ])


def write_remediation_sql(matches: list[Match]) -> None:
    # Group by UC object → dedup column-level corrections. Within the same run
    # we may have BOTH the per-table .alter.sql AND the master propagation file
    # asserting the same wrong comment on the same column; we only emit ONE
    # corrected statement per (uc_object, column) pair.
    seen: set[tuple[str, str]] = set()
    lines: list[str] = []
    lines.append(
        "-- =============================================================================\n"
        "-- PI / Internal / BonusOnly / ILQ / Dealing codepoint-label slop remediation\n"
        f"-- Generated by tools/audit_pi_label_slop.py\n"
        f"-- Per dictionaries verified {VERIFIED_DATE}: PlayerLevelID 4 = 'Internal' (not\n"
        "-- Popular Investor and not demo); LabelID 26 = 'ILQ' (not BonusOnly); LabelID\n"
        "-- 30 = 'Dealing' (not generic 'internal'). Popular Investors are tracked by\n"
        "-- GuruStatusID and are valid customers.\n"
        "-- =============================================================================\n"
    )

    # Stable ordering: by UC object then column.
    matches_sorted = sorted(matches, key=lambda m: (m.uc_object.lower(), m.column.lower()))
    for m in matches_sorted:
        key = (m.uc_object.lower(), m.column.lower())
        if key in seen:
            continue
        seen.add(key)
        lines.append(m.new_line)

    REMEDIATION_SQL.parent.mkdir(parents=True, exist_ok=True)
    REMEDIATION_SQL.write_text("\n".join(lines) + "\n", encoding="utf-8")


def patch_wiki_files_in_place(matches: list[Match]) -> int:
    """Rewrite each wiki source file in place, replacing the slop body in every
    matched ALTER/COMMENT statement with the canonical text. Returns # files patched."""
    by_file: dict[Path, list[Match]] = {}
    for m in matches:
        by_file.setdefault(m.file, []).append(m)

    n_files = 0
    for path, file_matches in by_file.items():
        text = path.read_text(encoding="utf-8")
        new_text = text
        # Replace each old_line with its new_line. old_line is the trimmed,
        # multi-line-collapsed statement; the file's actual representation
        # might preserve whitespace. We handle both single-line statements
        # (just substring replace) and multi-line statements (replace the
        # collapsed form's regex equivalent).
        for m in file_matches:
            if m.old_line in new_text:
                new_text = new_text.replace(m.old_line, m.new_line)
            else:
                # Multi-line statement: build a regex that allows any
                # whitespace between original tokens.
                pat = re.escape(m.old_line)
                pat = re.sub(r"\\ ", r"\\s+", pat)
                new_text = re.sub(pat, m.new_line.replace("\\", "\\\\"), new_text, count=1)
        if new_text != text:
            path.write_text(new_text, encoding="utf-8")
            n_files += 1
    return n_files


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--audit-only", action="store_true",
                    help="Write the CSV but don't patch wiki files or emit remediation SQL.")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print summary; write nothing.")
    args = ap.parse_args()

    matches = collect_all_matches()
    if not matches:
        print("No slop signatures found. Nothing to do.")
        return

    # Summary table
    by_kind: dict[str, int] = {}
    by_catalog: dict[str, int] = {}
    files = set()
    uc_objects = set()
    for m in matches:
        by_kind[m.slop_kind] = by_kind.get(m.slop_kind, 0) + 1
        cat = m.uc_object.split(".", 1)[0]
        by_catalog[cat] = by_catalog.get(cat, 0) + 1
        files.add(m.file)
        uc_objects.add(m.uc_object)

    print(f"Total slop matches:          {len(matches)}")
    print(f"Wiki files affected:         {len(files)}")
    print(f"Distinct UC objects:         {len(uc_objects)}")
    print()
    print("By slop_kind:")
    for k, v in sorted(by_kind.items(), key=lambda kv: -kv[1]):
        print(f"  {k:<32} {v}")
    print()
    print("By UC catalog:")
    for c, v in sorted(by_catalog.items(), key=lambda kv: -kv[1]):
        print(f"  {c:<16} {v}")

    if args.dry_run:
        print("\n[dry-run] No files written.")
        return

    write_audit_csv(matches)
    print(f"\nWrote audit CSV: {AUDIT_CSV.relative_to(REPO)}")

    if not args.audit_only:
        write_remediation_sql(matches)
        n_patched = patch_wiki_files_in_place(matches)
        print(f"Wrote remediation SQL: {REMEDIATION_SQL.relative_to(REPO)}")
        print(f"Patched wiki source files in place: {n_patched}")
        print(
            "\nNext steps:\n"
            "  1. Review the audit CSV.\n"
            f"  2. Deploy {REMEDIATION_SQL.relative_to(REPO)} against UC via your "
            "preferred runner (any databricks.sql executor; the file is just a\n"
            "     bag of ALTER ... COMMENT statements, one per line).\n"
            "  3. Commit the patched wiki files so future regen doesn't re-introduce slop."
        )


if __name__ == "__main__":
    main()
