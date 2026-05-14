"""Extract structured claims from every DWH_dbo wiki file for the LLM judge.

Inputs (DWH_dbo only):
  knowledge/synapse/Wiki/DWH_dbo/Tables/*.md
  knowledge/synapse/Wiki/DWH_dbo/Views/*.md
  knowledge/synapse/Wiki/DWH_dbo/Tables/*.alter.sql
  knowledge/synapse/Wiki/DWH_dbo/Views/*.alter.sql

Outputs (one file):
  knowledge/_dwh_wiki_claims.csv

Each row is a single assertion the wiki makes about a column or a table.
Columns:
  wiki_file       relative path
  wiki_line       1-indexed line within wiki_file
  object          DWH_dbo table/view name (e.g. Dim_Customer)
  column          column name; empty string when claim is at table scope
  claim_type      one of {type, nullable, default, fk_ref, codepoint,
                  lineage_tag, description, tbl_description}
  claim_value     the verbatim value extracted (e.g. "int", "YES", "0",
                  "Dim_Customer.PlayerLevelID", "4=Internal",
                  "Tier 1 - upstream wiki, Dictionary.PlayerStatus")
  raw_context     a short slice of the original cell / body for traceability

Scope rules:
  - Only canonical wiki files are parsed: `<Object>.md` and `<Object>.alter.sql`.
    `.lineage.md`, `.review-needed.md`, and other suffixed variants are skipped
    (they are derived artifacts).
  - Only the first element table after the `## ? Elements` heading is parsed
    as the column-level descriptor. Sub-element tables that some wikis use to
    describe sub-objects are not yet emitted; the LLM judge ignores them.

This script is read-only -- it never edits wiki files or deploys anything.

Usage:
    python tools/dwh_judge/extract_wiki_claims.py
"""
from __future__ import annotations

import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))

WIKI_DIR = REPO / "knowledge" / "synapse" / "Wiki" / "DWH_dbo"
OUT_CSV = REPO / "knowledge" / "_dwh_wiki_claims.csv"

# ---------------------------------------------------------------------------
# Codepoint extraction reuses the tightened regex from the prior pipeline
# (same patterns as tools/audit_codepoint_claims.py). We do NOT re-import to
# keep this script free of optional pyodbc deps; the regex strings are
# copied verbatim.
# ---------------------------------------------------------------------------

_LABEL_TOKEN = r"[A-Z][\w'&+/\-]*"
_LABEL_CONT = r"(?:[ \t]+[A-Z0-9&/+'\-][\w'&+/\-]*){0,4}"
_LABEL_END = r"(?=[,;.)\]\[]|[ \t]*\(|[ \t]+\d+\s*=|[ \t]*\[UNVERIFIED|[ \t]*$)"
ENUM_NEQ = re.compile(
    r"\b(?P<n>\d{1,4})\s*=\s*(?P<label>" + _LABEL_TOKEN + _LABEL_CONT + r")" + _LABEL_END
)
ENUM_PAREN = re.compile(
    r"\((?P<n>\d{1,4})\)\s+(?P<label>" + _LABEL_TOKEN + _LABEL_CONT + r")" + _LABEL_END
)

# Tier-N parenthetical at end of a description, e.g.
#   "(Tier 1 - upstream wiki, Dictionary.PlayerStatus)"
#   "(Tier 2 - SP_Dictionaries_DL_To_Synapse)"
TIER_TAG = re.compile(
    r"\(Tier\s+(?P<tier>[0-9]+(?:\s*[A-Z])?)\s*[-—]\s*(?P<body>[^()]+?)\)",
    re.IGNORECASE,
)

# Default value claims in descriptions: "Default=0", "Default = newid()", etc.
# Avoid capturing trailing sentence punctuation; allow a single (..) function
# call form at the end.
DEFAULT_CLAIM = re.compile(
    r"\bDefault\s*[:=]\s*(?P<val>"
    r"[A-Za-z0-9_'\-]+(?:\s*\([^)]*\))?"
    r")",
    re.IGNORECASE,
)

# FK claims: "FK from X.Y", "FK to X.Y", "References X.Y", "Foreign key to X.Y"
FK_CLAIM = re.compile(
    r"\b(?:FK(?:\s+from|\s+to)?|References?|Foreign\s+key(?:\s+to)?)\s+"
    r"(?P<ref>[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*){0,2})",
    re.IGNORECASE,
)

# ALTER TABLE ... ALTER COLUMN ... COMMENT '...'   (UC-style ALTER)
ALTER_COL_RE = re.compile(
    r"ALTER\s+(?:TABLE|VIEW)\s+(?P<uc>[\w.`]+)\s+ALTER\s+COLUMN\s+`?(?P<col>[A-Za-z_][\w]*)`?"
    r"\s+COMMENT\s+'(?P<body>(?:[^']|'')*)'\s*;",
    re.IGNORECASE,
)
# TBLPROPERTIES ('comment' = '...')
TBL_COMMENT_RE = re.compile(
    r"SET\s+TBLPROPERTIES\s*\(\s*'comment'\s*=\s*'(?P<body>(?:[^']|'')*)'\s*\)",
    re.IGNORECASE,
)

# Markdown element-table header detection. We only care about tables that have
# a "Description" column -- those are the per-column descriptors.
ELEMENT_HEADER_RE = re.compile(r"^\|\s*#\s*\|(?P<rest>.+?)\|\s*$")
DIVIDER_RE = re.compile(r"^\|\s*-+\s*\|.*\|\s*$")


@dataclass
class Claim:
    wiki_file: str
    wiki_line: int
    object: str
    column: str
    claim_type: str
    claim_value: str
    raw_context: str


def _object_name_for_md(p: Path) -> str | None:
    """Return the canonical object name for a wiki .md file, or None if it
    is a derived artifact (.lineage.md, .review-needed.md, etc.)."""
    name = p.name
    if not name.endswith(".md"):
        return None
    base = name[:-3]
    if "." in base:  # any sub-suffix -> derived artifact
        return None
    if base.startswith("_"):  # _index.md, _deploy-index.md
        return None
    return base


def _object_name_for_alter(p: Path) -> str | None:
    name = p.name
    if not name.endswith(".alter.sql"):
        return None
    base = name[: -len(".alter.sql")]
    if "." in base:  # X.lineage etc. — derived artifacts
        return None
    return base


def _normalise_cell(s: str) -> str:
    return s.strip().strip("`").strip()


def _parse_header_columns(header_line: str) -> list[str]:
    """Return list of column headers (without the leading '#' column)."""
    parts = [c.strip() for c in header_line.strip().split("|")]
    parts = [c for c in parts if c != ""]
    # parts[0] is "#"; drop it
    if parts and parts[0] == "#":
        parts = parts[1:]
    return parts


def _emit_codepoints(body: str, claim_factory):
    seen: set[tuple[str, str]] = set()
    for m in ENUM_NEQ.finditer(body):
        n, label = m.group("n"), m.group("label").strip()
        if (n, label) in seen:
            continue
        seen.add((n, label))
        claim_factory("codepoint", f"{n}={label}", body[max(0, m.start()-20):m.end()+20])
    for m in ENUM_PAREN.finditer(body):
        n, label = m.group("n"), m.group("label").strip()
        if (n, label) in seen:
            continue
        seen.add((n, label))
        claim_factory("codepoint", f"({n}) {label}", body[max(0, m.start()-20):m.end()+20])


def _emit_tier_tags(body: str, claim_factory):
    for m in TIER_TAG.finditer(body):
        claim_factory(
            "lineage_tag",
            f"Tier {m.group('tier').strip()} - {m.group('body').strip()}",
            body[max(0, m.start() - 5):m.end() + 5],
        )


def _emit_defaults(body: str, claim_factory):
    for m in DEFAULT_CLAIM.finditer(body):
        claim_factory("default", m.group("val").strip(),
                      body[max(0, m.start() - 10):m.end() + 10])


def _emit_fks(body: str, claim_factory):
    for m in FK_CLAIM.finditer(body):
        ref = m.group("ref").strip()
        if "." not in ref:
            continue  # FK without a table qualifier is not actionable
        claim_factory("fk_ref", ref,
                      body[max(0, m.start() - 5):m.end() + 5])


def parse_md(path: Path, rel: str) -> list[Claim]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    object_name = _object_name_for_md(path)
    if object_name is None:
        return []
    claims: list[Claim] = []

    # First, locate the first element table whose header includes "Description".
    # We accept multiple table shapes; the column-of-interest map is built per
    # table from its header.
    i = 0
    table_seen = False
    while i < len(lines):
        line = lines[i]
        m = ELEMENT_HEADER_RE.match(line)
        if not m:
            i += 1
            continue
        headers = _parse_header_columns(line)
        # Find indices we care about (element/column, type, nullable, description).
        try:
            div_line = lines[i + 1]
        except IndexError:
            i += 1
            continue
        if not DIVIDER_RE.match(div_line):
            i += 1
            continue
        lower = [h.lower() for h in headers]
        col_idx = None
        for cand in ("element", "column"):
            if cand in lower:
                col_idx = lower.index(cand)
                break
        if col_idx is None:
            i += 2
            continue
        if "description" not in lower:
            i += 2
            continue
        type_idx = lower.index("type") if "type" in lower else None
        null_idx = lower.index("nullable") if "nullable" in lower else None
        desc_idx = lower.index("description")
        if table_seen:
            # Sub-tables (split per group within one wiki) -- still parse them.
            pass

        # Read table rows until a non-pipe line.
        i += 2
        while i < len(lines) and lines[i].lstrip().startswith("|"):
            row_line = lines[i]
            cells = [c.strip() for c in row_line.split("|")]
            cells = [c for c in cells if c != ""]
            # cells[0] is the row number, then the rest.
            if not cells or not cells[0].strip().rstrip(".").isdigit():
                break
            data_cells = cells[1:]
            if len(data_cells) < len(headers):
                # Padding for safety -- skip malformed
                i += 1
                continue
            column_name = _normalise_cell(data_cells[col_idx])
            type_value = _normalise_cell(data_cells[type_idx]) if type_idx is not None else ""
            null_value = _normalise_cell(data_cells[null_idx]) if null_idx is not None else ""
            desc_value = data_cells[desc_idx].strip()

            def _factory(ct, cv, ctx, _col=column_name, _line=i + 1):
                claims.append(
                    Claim(
                        wiki_file=rel,
                        wiki_line=_line,
                        object=object_name,
                        column=_col,
                        claim_type=ct,
                        claim_value=cv,
                        raw_context=ctx[:200],
                    )
                )

            if type_value:
                _factory("type", type_value, type_value)
            if null_value and null_value.upper() in {"YES", "NO", "Y", "N"}:
                norm = "YES" if null_value.upper().startswith("Y") else "NO"
                _factory("nullable", norm, null_value)
            if desc_value:
                _factory("description", desc_value, desc_value)
                _emit_codepoints(desc_value, _factory)
                _emit_tier_tags(desc_value, _factory)
                _emit_defaults(desc_value, _factory)
                _emit_fks(desc_value, _factory)
            i += 1
        table_seen = True
        # Don't break -- some wikis (Dim_Position) have many sub-tables we want
        # to scoop too. Continue scanning for more headers.
        continue
    return claims


def parse_alter(path: Path, rel: str) -> list[Claim]:
    text = path.read_text(encoding="utf-8")
    object_name = _object_name_for_alter(path)
    if object_name is None:
        return []
    claims: list[Claim] = []

    def _line_of(offset: int) -> int:
        return text.count("\n", 0, offset) + 1

    for m in ALTER_COL_RE.finditer(text):
        column = m.group("col")
        body = m.group("body").replace("''", "'")
        line = _line_of(m.start())
        column_name = column

        def _factory(ct, cv, ctx, _col=column_name, _line=line):
            claims.append(
                Claim(
                    wiki_file=rel,
                    wiki_line=_line,
                    object=object_name,
                    column=_col,
                    claim_type=ct,
                    claim_value=cv,
                    raw_context=ctx[:200],
                )
            )

        _factory("description", body, body)
        _emit_codepoints(body, _factory)
        _emit_tier_tags(body, _factory)
        _emit_defaults(body, _factory)
        _emit_fks(body, _factory)

    for m in TBL_COMMENT_RE.finditer(text):
        body = m.group("body").replace("''", "'")
        line = _line_of(m.start())
        claims.append(
            Claim(
                wiki_file=rel,
                wiki_line=line,
                object=object_name,
                column="",
                claim_type="tbl_description",
                claim_value=body,
                raw_context=body[:200],
            )
        )

    return claims


def main() -> None:
    print(f"Scanning {WIKI_DIR.relative_to(REPO)}/ ...", flush=True)
    all_claims: list[Claim] = []
    md_count = alter_count = skipped = 0
    for sub in ("Tables", "Views"):
        d = WIKI_DIR / sub
        if not d.exists():
            continue
        for p in sorted(d.glob("*.md")):
            obj = _object_name_for_md(p)
            if obj is None:
                skipped += 1
                continue
            rel = str(p.relative_to(REPO)).replace("\\", "/")
            claims = parse_md(p, rel)
            all_claims.extend(claims)
            md_count += 1
        for p in sorted(d.glob("*.alter.sql")):
            obj = _object_name_for_alter(p)
            if obj is None:
                skipped += 1
                continue
            rel = str(p.relative_to(REPO)).replace("\\", "/")
            claims = parse_alter(p, rel)
            all_claims.extend(claims)
            alter_count += 1

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
        w.writerow(["wiki_file", "wiki_line", "object", "column",
                    "claim_type", "claim_value", "raw_context"])
        for c in all_claims:
            w.writerow([c.wiki_file, c.wiki_line, c.object, c.column,
                        c.claim_type, c.claim_value, c.raw_context])

    by_type: dict[str, int] = {}
    for c in all_claims:
        by_type[c.claim_type] = by_type.get(c.claim_type, 0) + 1

    print(f"Parsed {md_count} .md + {alter_count} .alter.sql files "
          f"({skipped} derived artifacts skipped).")
    print(f"Total claims: {len(all_claims)}")
    for t in sorted(by_type):
        print(f"  {t:<18} {by_type[t]}")
    print(f"\nWrote {OUT_CSV.relative_to(REPO)}")


if __name__ == "__main__":
    main()
