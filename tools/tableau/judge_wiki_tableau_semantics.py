"""Qualitative semantic uplift for DWH wikis using Tableau extracts.

This is the v2 successor to ``enrich_wiki_with_tableau.py``. Instead of writing
a quantitative usage map (which workbooks reference which columns and how
often), this tool sends the wiki + Tableau extract to a single LLM call and
asks for a discard-by-default verdict: only inject content when Tableau
genuinely encodes business logic the wiki is missing.

When the verdict is ENRICH, two fenced blocks may be injected:

  * Section 2 (Business Logic)  - "Tableau-Discovered Conventions"
                                   (always, when ENRICH)
  * Section 4 (Elements)        - "Tableau-Discovered Column Semantics"
                                   (only when column_findings has any item
                                    that maps to a real wiki column)

Element rows are NEVER modified. The wiki/alter parity validators stay green
because we only ADD content via fenced subsections.

Usage
-----
    python tools/tableau/judge_wiki_tableau_semantics.py \
        --wiki knowledge/synapse/Wiki/BI_DB_dbo/Tables/<Table>.md \
        [--tableau knowledge/tableau/sql_dp_prod_we__BI_DB_dbo/<Table>.md] \
        [--dry-run | --apply | --remove | --judge-only] \
        [--audit-dir audits/tableau-enrichment] \
        [--keep-v1]

By default ``--apply`` also strips the v1 ``TABLEAU-ENRICHMENT-*`` fences,
since v2 supersedes the usage-map content. Pass ``--keep-v1`` to leave them.

The LLM is invoked via the local ``claude`` CLI subprocess, mirroring the
mechanic in ``tools/wiki-auditor/llm_merger.py`` (no SDK dependency, no env
var beyond what the CLI itself needs).
"""

from __future__ import annotations

import argparse
import datetime as dt
import difflib
import glob
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
KNOWLEDGE_TABLEAU = REPO_ROOT / "knowledge" / "tableau"
DEFAULT_AUDIT_DIR = REPO_ROOT / "audits" / "tableau-enrichment"

V2_TABLE_OPEN = "<!-- TABLEAU-SEMANTICS-TABLE v2 -->"
V2_TABLE_CLOSE = "<!-- /TABLEAU-SEMANTICS-TABLE -->"
V2_TABLE_SUBHEADING = "### Tableau-Discovered Conventions"

V2_COLS_OPEN = "<!-- TABLEAU-SEMANTICS-COLS v2 -->"
V2_COLS_CLOSE = "<!-- /TABLEAU-SEMANTICS-COLS -->"
V2_COLS_SUBHEADING = "### Tableau-Discovered Column Semantics"

V1_TABLE_OPEN = "<!-- TABLEAU-ENRICHMENT-TABLE v1 -->"
V1_TABLE_CLOSE = "<!-- /TABLEAU-ENRICHMENT-TABLE -->"
V1_COLS_OPEN = "<!-- TABLEAU-ENRICHMENT-COLS v1 -->"
V1_COLS_CLOSE = "<!-- /TABLEAU-ENRICHMENT-COLS -->"
V1_COLS_SUBHEADING = "### Tableau Usage Notes"

CLAUDE_TIMEOUT_SECONDS = 360
MAX_BUNDLE_BYTES_WARN = 750_000  # ~ 250k tokens; Claude Sonnet 200k context

EXIT_OK = 0
EXIT_USAGE = 2
EXIT_VALIDATION_FAILED = 3


# ---------------------------------------------------------------------------
# Wiki parsing (lifted from enrich_wiki_with_tableau.py - kept self-contained
# so this tool has no intra-tools imports).
# ---------------------------------------------------------------------------
@dataclass
class WikiSection:
    name: str
    number: int
    header_idx: int
    body_start: int
    end_idx: int  # idx of the trailing "---" or fallback to next-header idx


@dataclass
class WikiDoc:
    path: Path
    raw_text: str
    line_ending: str
    lines: List[str]
    sections: Dict[int, WikiSection]
    columns: List[str]
    object_name: str
    db_schema: str  # parsed from path: "BI_DB_dbo", etc.

    @classmethod
    def load(cls, path: Path) -> "WikiDoc":
        raw = path.read_bytes()
        line_ending = "\r\n" if b"\r\n" in raw else "\n"
        text = raw.decode("utf-8")
        normalized = text.replace("\r\n", "\n")
        lines = normalized.split("\n")
        sections = _parse_sections(lines)
        columns = _parse_element_columns(lines, sections.get(4))
        obj_name = _parse_object_name(lines)
        db_schema = _parse_db_schema(path)
        return cls(
            path=path,
            raw_text=text,
            line_ending=line_ending,
            lines=lines,
            sections=sections,
            columns=columns,
            object_name=obj_name,
            db_schema=db_schema,
        )

    def join_lines(self) -> str:
        return self.line_ending.join(self.lines)


def _parse_object_name(lines: List[str]) -> str:
    for line in lines[:5]:
        m = re.match(r"^#\s+(.+?)\s*$", line)
        if m:
            full = m.group(1).strip()
            return full.split(".")[-1]
    return ""


def _parse_db_schema(path: Path) -> str:
    parts = path.parts
    try:
        i = parts.index("Wiki")
        if i + 1 < len(parts):
            return parts[i + 1]
    except ValueError:
        pass
    return path.parent.parent.name if path.parent.parent.name else ""


def _parse_sections(lines: List[str]) -> Dict[int, WikiSection]:
    headers: List[Tuple[int, int, str]] = []
    pat = re.compile(r"^##\s+(\d+)\.\s+(.+?)\s*$")
    for i, line in enumerate(lines):
        m = pat.match(line)
        if m:
            headers.append((i, int(m.group(1)), m.group(2)))

    out: Dict[int, WikiSection] = {}
    for idx, (header_idx, num, name) in enumerate(headers):
        body_start = header_idx + 1
        next_header_idx = headers[idx + 1][0] if idx + 1 < len(headers) else len(lines)
        end_idx = -1
        for j in range(next_header_idx - 1, header_idx, -1):
            stripped = lines[j].strip()
            if stripped == "---":
                end_idx = j
                break
            if stripped:
                break
        if end_idx == -1:
            end_idx = next_header_idx
        out[num] = WikiSection(
            name=name, number=num, header_idx=header_idx,
            body_start=body_start, end_idx=end_idx,
        )
    return out


def _parse_element_columns(lines: List[str], section: Optional[WikiSection]) -> List[str]:
    if section is None:
        return []
    columns: List[str] = []
    in_table = False
    seen_header = False
    for i in range(section.body_start, section.end_idx):
        line = lines[i]
        if not seen_header and re.match(r"^\|\s*#\s*\|\s*Element\s*\|", line):
            seen_header = True
            in_table = True
            continue
        if in_table:
            if re.match(r"^\|[\s:|-]+\|\s*$", line):
                continue
            if not line.startswith("|"):
                break
            cells = [c.strip() for c in line.split("|")]
            if len(cells) >= 4:
                col = cells[2].strip("`").strip()
                if col:
                    columns.append(col)
    return columns


# ---------------------------------------------------------------------------
# Path resolution
# ---------------------------------------------------------------------------
def auto_resolve_tableau(wiki: WikiDoc) -> Optional[Path]:
    """Glob knowledge/tableau/*<db_schema>/<TableName>.md, prefer prod prefix."""
    if not wiki.object_name:
        return None
    pat = f"*__{wiki.db_schema}/{wiki.object_name}.md" if wiki.db_schema else f"*/{wiki.object_name}.md"
    matches = sorted(KNOWLEDGE_TABLEAU.glob(pat))
    if not matches:
        # Fallback: any directory containing a file with that table name
        matches = sorted(KNOWLEDGE_TABLEAU.glob(f"*/{wiki.object_name}.md"))
    if not matches:
        return None
    # Prefer prod prefix
    prod = [m for m in matches if m.parent.name.startswith("sql_dp_prod_we__")]
    return prod[0] if prod else matches[0]


# ---------------------------------------------------------------------------
# LLM invocation - mirrors tools/wiki-auditor/llm_merger.py
# ---------------------------------------------------------------------------
def _resolve_claude_cli() -> Optional[str]:
    override = os.environ.get("WIKI_AUDITOR_CLAUDE")
    if override and Path(override).exists():
        return override
    for cand in [
        Path(os.environ.get("APPDATA", "")) / "npm" / "claude.cmd",
        Path(os.environ.get("APPDATA", "")) / "npm" / "claude",
    ]:
        if cand.exists():
            return str(cand)
    return shutil.which("claude")


def _run_claude(prompt: str, timeout_s: int = CLAUDE_TIMEOUT_SECONDS,
                model: Optional[str] = None) -> Tuple[Optional[str], str]:
    """Invoke claude --print and pipe the prompt through stdin.

    Returns (stdout_text_or_None, error_message). On success error_message is "".
    """
    cli = _resolve_claude_cli()
    if not cli:
        return None, (
            "claude CLI not found. Install via npm i -g @anthropic-ai/claude-code "
            "or set $WIKI_AUDITOR_CLAUDE to its path."
        )
    args = [cli, "--print", "--output-format", "text"]
    if model:
        args += ["--model", model]
    try:
        proc = subprocess.run(
            args,
            input=prompt,
            capture_output=True,
            text=True,
            timeout=timeout_s,
            encoding="utf-8",
            errors="replace",
        )
    except subprocess.TimeoutExpired:
        return None, f"claude CLI timed out after {timeout_s}s"
    except (FileNotFoundError, OSError) as exc:
        return None, f"failed to launch claude CLI: {exc}"
    if proc.returncode != 0:
        return None, (
            f"claude CLI exited {proc.returncode}. stderr (head):\n"
            f"{(proc.stderr or '')[:600]}"
        )
    out = proc.stdout or ""
    if not out.strip():
        return None, "claude CLI returned empty stdout"
    return out, ""


# ---------------------------------------------------------------------------
# Prompt construction
# ---------------------------------------------------------------------------
_SYSTEM_POLICY = """You are a senior data semantics analyst. You will receive
two markdown documents:

  1. The CURRENT WIKI for a Synapse / SQL Server table (8 fixed sections,
     including a Section 4 Elements table that lists every column with a
     description and a tier suffix).
  2. A TABLEAU EXTRACT for the same table, listing every custom SQL query
     and every downstream calculated field that touches it.

Your job is to decide whether the Tableau side encodes any business logic
that adds NON-TRIVIAL semantic value to the wiki. Be ruthless. The default
should be DISCARD; only return ENRICH when there is genuine semantic uplift.

DISCARD (do NOT emit findings for):

  * Pure aggregations: SUM / COUNT / AVG / MIN / MAX / TOTAL of a single
    column.
  * Renames: ``[X]`` aliased to ``Y`` with no transformation.
  * Simple arithmetic of two columns: ``[X]+[Y]``, ``[X]-[Y]``, ``[X]/[Y]``.
  * Custom SQL that is just SELECT with WHERE / GROUP BY / ORDER BY (those
    are query patterns, not semantic logic).
  * Date / number / string formatting (DATETRUNC, STR, ROUND, etc.).
  * NULL handling that adds no business meaning (IFNULL/ISNULL with a literal).
  * Concepts the wiki ALREADY documents at equal or better fidelity. If the
    wiki Section 2 / Section 4 already explains the rule, do not re-emit it.
  * Calc fields whose name is identical (case-insensitive) to a wiki column
    AND whose formula is just ``[<that column>]``.

KEEP (emit a finding for):

  * CASE / IF / IIF expressions that map raw codes to business categories
    (e.g. mapping IDs to "Retail" vs "Professional").
  * Sign conventions (e.g. deposits add, withdrawals subtract).
  * Eligibility predicates / segmentation rules using more than one column.
  * KPI definitions composed of multiple measures (e.g. a ratio with a
    domain-specific filter, or a cohort-style numerator/denominator).
  * Cross-column derived attributes that encode a real business rule
    (e.g. "Active customer = HasDeposit AND NotChurned").
  * Custom SQL fragments that contain non-trivial JOIN/CASE business logic
    (NOT simple pass-through SELECTs).

Each finding is classified as one of:

  * ``table_findings``  - the rule shapes how the table is consumed as a
                          whole (e.g. a sign convention used across
                          dashboards, or a multi-column KPI definition).
  * ``column_findings`` - the rule enriches the meaning of one specific
                          wiki column. The ``column`` field MUST exactly
                          match a column name from the wiki Section 4
                          Elements table (case- and underscore-sensitive).

Output STRICT JSON only, with no prose, no markdown fences, no comments:

{
  "verdict": "ENRICH" | "DISCARD",
  "rationale": "1-3 sentences explaining the verdict",
  "table_findings": [
    {
      "name":     "<calc field name or short concept name>",
      "summary":  "<1-2 sentences in plain English>",
      "formula":  "<the formula, compactly quoted>",
      "source_workbooks": ["<workbook name>", ...]
    }
  ],
  "column_findings": [
    {
      "column":   "<exact wiki column name>",
      "name":     "<calc field name>",
      "summary":  "<1-2 sentences in plain English>",
      "formula":  "<the formula, compactly quoted>",
      "source_workbook": "<workbook name>"
    }
  ]
}

If verdict is DISCARD, both arrays MUST be empty. If verdict is ENRICH, at
least one of the two arrays must contain at least one item.
"""


def build_prompt(wiki_text: str, tableau_text: str, columns: List[str]) -> str:
    columns_block = "\n".join(f"  - {c}" for c in columns) if columns else "  (none parsed)"
    return (
        _SYSTEM_POLICY
        + "\n\nWIKI COLUMN NAMES (use exactly these in column_findings.column):\n"
        + columns_block
        + "\n\n=== CURRENT WIKI ===\n"
        + wiki_text
        + "\n\n=== TABLEAU EXTRACT ===\n"
        + tableau_text
        + "\n\nReturn ONLY the JSON object. No prose.\n"
    )


# ---------------------------------------------------------------------------
# JSON extraction (object-shaped, mirrors llm_merger.py array variant)
# ---------------------------------------------------------------------------
_JSON_FENCE_RE = re.compile(r"```(?:json)?\s*(.*?)```", re.DOTALL | re.IGNORECASE)


def extract_json_object(text: str) -> Optional[dict]:
    if not text:
        return None
    fence = _JSON_FENCE_RE.search(text)
    body = fence.group(1).strip() if fence else text.strip()
    start = body.find("{")
    if start < 0:
        return None
    depth = 0
    end = -1
    in_str = False
    esc = False
    for i in range(start, len(body)):
        ch = body[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if end < 0:
        return None
    blob = body[start:end]
    try:
        parsed = json.loads(blob)
    except json.JSONDecodeError:
        return None
    if not isinstance(parsed, dict):
        return None
    return parsed


# ---------------------------------------------------------------------------
# Verdict normalization + column hallucination guard
# ---------------------------------------------------------------------------
@dataclass
class Verdict:
    verdict: str  # "ENRICH" | "DISCARD"
    rationale: str
    table_findings: List[dict] = field(default_factory=list)
    column_findings: List[dict] = field(default_factory=list)
    dropped_unknown_columns: List[dict] = field(default_factory=list)


def normalize_verdict(parsed: dict, columns: List[str]) -> Verdict:
    verdict = (parsed.get("verdict") or "").strip().upper()
    if verdict not in {"ENRICH", "DISCARD"}:
        verdict = "DISCARD"
    rationale = (parsed.get("rationale") or "").strip()

    raw_table = parsed.get("table_findings") or []
    raw_cols = parsed.get("column_findings") or []
    if not isinstance(raw_table, list):
        raw_table = []
    if not isinstance(raw_cols, list):
        raw_cols = []

    table_findings: List[dict] = []
    for f in raw_table:
        if not isinstance(f, dict):
            continue
        name = (f.get("name") or "").strip()
        summary = (f.get("summary") or "").strip()
        formula = (f.get("formula") or "").strip()
        wbs = f.get("source_workbooks") or []
        if not isinstance(wbs, list):
            wbs = [str(wbs)]
        wbs = [str(w).strip() for w in wbs if str(w).strip()]
        if not (name and summary):
            continue
        table_findings.append({
            "name": name,
            "summary": summary,
            "formula": formula,
            "source_workbooks": wbs,
        })

    columns_set = set(columns)
    column_findings: List[dict] = []
    dropped: List[dict] = []
    for f in raw_cols:
        if not isinstance(f, dict):
            continue
        col = (f.get("column") or "").strip()
        name = (f.get("name") or "").strip()
        summary = (f.get("summary") or "").strip()
        formula = (f.get("formula") or "").strip()
        workbook = (f.get("source_workbook") or "").strip()
        if not (col and summary):
            continue
        record = {
            "column": col,
            "name": name,
            "summary": summary,
            "formula": formula,
            "source_workbook": workbook,
        }
        if col not in columns_set:
            dropped.append(record)
            continue
        column_findings.append(record)

    if verdict == "ENRICH" and not (table_findings or column_findings):
        verdict = "DISCARD"

    return Verdict(
        verdict=verdict,
        rationale=rationale,
        table_findings=table_findings,
        column_findings=column_findings,
        dropped_unknown_columns=dropped,
    )


# ---------------------------------------------------------------------------
# Block builders
# ---------------------------------------------------------------------------
def _format_formula_for_md(formula: str) -> str:
    if not formula:
        return ""
    one_line = re.sub(r"\s+", " ", formula).strip()
    if len(one_line) > 240:
        one_line = one_line[:237] + "..."
    return one_line.replace("`", "'")


def build_v2_table_block(findings: List[dict]) -> List[str]:
    block: List[str] = []
    block.append(V2_TABLE_OPEN)
    block.append(V2_TABLE_SUBHEADING)
    block.append("")
    block.append(
        "> _LLM-curated business definitions extracted from downstream Tableau "
        "calculated fields. Discard-by-default; only definitions that add semantic "
        "value beyond the existing wiki are kept._"
    )
    block.append("")
    for f in findings:
        wbs = f.get("source_workbooks") or []
        wb_str = ", ".join(f"*{w}*" for w in wbs[:3])
        if len(wbs) > 3:
            wb_str += f" (+{len(wbs) - 3} more)"
        block.append(f"- **{f['name']}** - {f['summary']}")
        if f.get("formula"):
            block.append(f"  Formula: `{_format_formula_for_md(f['formula'])}`")
        if wb_str:
            block.append(f"  Workbook(s): {wb_str}")
    block.append("")
    block.append(
        "_(auto-generated by `tools/tableau/judge_wiki_tableau_semantics.py`; "
        "safe to delete - regenerable)_"
    )
    block.append(V2_TABLE_CLOSE)
    return block


def build_v2_cols_block(findings: List[dict]) -> List[str]:
    block: List[str] = []
    block.append(V2_COLS_OPEN)
    block.append(V2_COLS_SUBHEADING)
    block.append("")
    block.append(
        "_LLM-curated definitions extracted from downstream Tableau calc fields, "
        "mapped to specific wiki columns. Each item is a Tableau-side rule that "
        "adds semantic context to the column above; the wiki Element row itself "
        "is unchanged._"
    )
    block.append("")
    by_col: Dict[str, List[dict]] = {}
    for f in findings:
        by_col.setdefault(f["column"], []).append(f)
    for col, items in by_col.items():
        for f in items:
            wb = f.get("source_workbook")
            wb_clause = f" Workbook: *{wb}*." if wb else ""
            name_clause = f" (`{f['name']}`)" if f.get("name") else ""
            formula_clause = ""
            if f.get("formula"):
                formula_clause = f" Formula: `{_format_formula_for_md(f['formula'])}`."
            block.append(
                f"- **`{col}`**{name_clause} - {f['summary']}{formula_clause}{wb_clause}"
            )
    block.append("")
    block.append(
        "_(auto-generated by `tools/tableau/judge_wiki_tableau_semantics.py`; "
        "safe to delete - regenerable)_"
    )
    block.append(V2_COLS_CLOSE)
    return block


# ---------------------------------------------------------------------------
# Wiki mutation - strip + insert
# ---------------------------------------------------------------------------
def _strip_block(lines: List[str], open_marker: str, close_marker: str,
                 also_strip_subheading: Optional[str] = None) -> List[str]:
    out = list(lines)
    open_idx = next((i for i, l in enumerate(out) if l.strip() == open_marker), -1)
    if open_idx == -1:
        return out
    close_idx = next(
        (j for j in range(open_idx + 1, len(out)) if out[j].strip() == close_marker), -1
    )
    if close_idx == -1:
        return out

    start = open_idx
    end = close_idx
    if end + 1 < len(out) and out[end + 1].strip() == "":
        end += 1
    if start - 1 >= 0 and out[start - 1].strip() == "":
        start -= 1

    if also_strip_subheading is not None:
        sh_idx = -1
        for j in range(start - 1, max(start - 4, -1), -1):
            if out[j].strip() == also_strip_subheading.strip():
                sh_idx = j
                break
        if sh_idx >= 0:
            new_start = sh_idx
            if new_start - 1 >= 0 and out[new_start - 1].strip() == "":
                new_start -= 1
            start = new_start

    return out[:start] + out[end + 1:]


def _strip_v2_combined(lines: List[str]) -> List[str]:
    """Strip v2 blocks (subheading lives INSIDE the fence, no extra strip needed)."""
    out = _strip_block(lines, V2_TABLE_OPEN, V2_TABLE_CLOSE)
    out = _strip_block(out, V2_COLS_OPEN, V2_COLS_CLOSE)
    return out


def _strip_v1_combined(lines: List[str]) -> List[str]:
    out = _strip_block(lines, V1_TABLE_OPEN, V1_TABLE_CLOSE)
    out = _strip_block(
        out, V1_COLS_OPEN, V1_COLS_CLOSE,
        also_strip_subheading=V1_COLS_SUBHEADING,
    )
    return out


def _insert_block(lines: List[str], section: WikiSection,
                  block_lines: List[str]) -> List[str]:
    out = list(lines)
    insert_at = section.end_idx
    while insert_at - 1 > section.body_start and out[insert_at - 1].strip() == "":
        insert_at -= 1
    payload = [""] + block_lines + [""]
    out[insert_at:insert_at] = payload
    return out


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------
def remove_blocks(doc: WikiDoc, *, keep_v1: bool) -> str:
    new_lines = _strip_v2_combined(doc.lines)
    if not keep_v1:
        new_lines = _strip_v1_combined(new_lines)
    return doc.line_ending.join(new_lines)


def apply_blocks(doc: WikiDoc, verdict: Verdict, *, keep_v1: bool) -> str:
    # 1. Start from a baseline with all v2 + (optionally) v1 fences stripped.
    new_lines = _strip_v2_combined(doc.lines)
    if not keep_v1:
        new_lines = _strip_v1_combined(new_lines)

    if verdict.verdict != "ENRICH":
        return doc.line_ending.join(new_lines)

    # 2. Insert in REVERSE order (Section 4 first) so earlier indices stay valid.
    sections = _parse_sections(new_lines)
    if verdict.column_findings and 4 in sections:
        cols_block = build_v2_cols_block(verdict.column_findings)
        new_lines = _insert_block(new_lines, sections[4], cols_block)
        sections = _parse_sections(new_lines)

    if verdict.table_findings and 2 in sections:
        table_block = build_v2_table_block(verdict.table_findings)
        new_lines = _insert_block(new_lines, sections[2], table_block)

    return doc.line_ending.join(new_lines)


# ---------------------------------------------------------------------------
# Validation post-apply
# ---------------------------------------------------------------------------
def validate_post_apply(new_text: str, doc: WikiDoc, verdict: Verdict,
                        *, keep_v1: bool) -> List[str]:
    errors: List[str] = []
    new_lines = new_text.split(doc.line_ending)

    section_headers = [l for l in new_lines if re.match(r"^##\s+\d+\.\s", l)]
    if len(section_headers) != 8:
        errors.append(
            f"section count drift: expected 8, got {len(section_headers)}"
        )

    pre_rows = _count_element_rows(doc.lines)
    post_rows = _count_element_rows(new_lines)
    if pre_rows != post_rows:
        errors.append(
            f"element row count changed: pre={pre_rows}, post={post_rows}"
        )

    for open_m, close_m in [
        (V2_TABLE_OPEN, V2_TABLE_CLOSE),
        (V2_COLS_OPEN, V2_COLS_CLOSE),
    ]:
        opens = sum(1 for l in new_lines if l.strip() == open_m)
        closes = sum(1 for l in new_lines if l.strip() == close_m)
        if opens != closes:
            errors.append(f"unmatched {open_m}: opens={opens}, closes={closes}")

    if not keep_v1:
        for m in [V1_TABLE_OPEN, V1_TABLE_CLOSE, V1_COLS_OPEN, V1_COLS_CLOSE]:
            if any(l.strip() == m for l in new_lines):
                errors.append(f"v1 marker still present after strip: {m}")

    return errors


def _count_element_rows(lines: List[str]) -> int:
    sections = _parse_sections(lines)
    sec4 = sections.get(4)
    if sec4 is None:
        return -1
    return len(_parse_element_columns(lines, sec4))


# ---------------------------------------------------------------------------
# Sidecar writers
# ---------------------------------------------------------------------------
def _audit_dir_for(audit_root: Path, db_schema: str, table_name: str) -> Path:
    folder = f"{db_schema}__{table_name}" if db_schema else table_name
    return audit_root / folder


def write_sidecars(
    audit_root: Path,
    doc: WikiDoc,
    tableau_path: Path,
    prompt: str,
    raw_output: Optional[str],
    parsed: Optional[dict],
    verdict: Optional[Verdict],
    error_message: str,
    new_text: Optional[str],
    mode: str,
    *,
    wiki_sha_before: str,
    wiki_sha_after: str,
) -> Path:
    folder = _audit_dir_for(audit_root, doc.db_schema, doc.object_name)
    folder.mkdir(parents=True, exist_ok=True)

    (folder / "judge_prompt.txt").write_text(prompt, encoding="utf-8")

    verdict_payload = {
        "ts": dt.datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "wiki": str(doc.path.relative_to(REPO_ROOT)) if doc.path.is_absolute() else str(doc.path),
        "tableau": str(tableau_path.relative_to(REPO_ROOT)) if tableau_path.is_absolute() else str(tableau_path),
        "mode": mode,
        "raw_output": raw_output,
        "parsed": parsed,
        "verdict_normalized": (
            {
                "verdict": verdict.verdict,
                "rationale": verdict.rationale,
                "table_findings": verdict.table_findings,
                "column_findings": verdict.column_findings,
                "dropped_unknown_columns": verdict.dropped_unknown_columns,
            }
            if verdict is not None
            else None
        ),
        "error": error_message or None,
    }
    (folder / "judge_verdict.json").write_text(
        json.dumps(verdict_payload, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    applied_md = ["# applied_blocks", "", f"_mode={mode}_", ""]
    if verdict is None or verdict.verdict != "ENRICH" or mode in {"remove", "judge-only"}:
        applied_md.append(f"_no blocks injected ({mode})_")
    else:
        if verdict.table_findings:
            applied_md += ["## Section 2 block", "", "```"]
            applied_md += build_v2_table_block(verdict.table_findings)
            applied_md += ["```", ""]
        if verdict.column_findings:
            applied_md += ["## Section 4 block", "", "```"]
            applied_md += build_v2_cols_block(verdict.column_findings)
            applied_md += ["```", ""]
        if not (verdict.table_findings or verdict.column_findings):
            applied_md.append("_ENRICH but no findings survived hallucination guard_")
    (folder / "applied_blocks.md").write_text("\n".join(applied_md), encoding="utf-8")

    log_line = {
        "ts": verdict_payload["ts"],
        "wiki": verdict_payload["wiki"],
        "mode": mode,
        "verdict": verdict.verdict if verdict else "ERROR",
        "n_table": len(verdict.table_findings) if verdict else 0,
        "n_col": len(verdict.column_findings) if verdict else 0,
        "n_dropped_cols": len(verdict.dropped_unknown_columns) if verdict else 0,
        "wiki_sha_before": wiki_sha_before,
        "wiki_sha_after": wiki_sha_after,
        "error": error_message or None,
    }
    audit_root.mkdir(parents=True, exist_ok=True)
    with (audit_root / "run_log.jsonl").open("a", encoding="utf-8") as f:
        f.write(json.dumps(log_line, ensure_ascii=False) + "\n")
    return folder


# ---------------------------------------------------------------------------
# Diff helpers
# ---------------------------------------------------------------------------
def make_diff(before: str, after: str, label: str) -> str:
    return "".join(
        difflib.unified_diff(
            before.splitlines(keepends=True),
            after.splitlines(keepends=True),
            fromfile=f"{label} (before)",
            tofile=f"{label} (after)",
            n=3,
        )
    )


def _sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------
def run(
    *,
    wiki_path: Path,
    tableau_path_explicit: Optional[Path],
    mode: str,
    audit_root: Path,
    keep_v1: bool,
    model: Optional[str],
) -> int:
    if not wiki_path.exists():
        print(f"ERR  wiki not found: {wiki_path}", file=sys.stderr)
        return EXIT_USAGE

    doc = WikiDoc.load(wiki_path)
    wiki_sha_before = _sha(doc.raw_text)

    # ---- remove path: no LLM needed, no tableau needed --------------------
    if mode == "remove":
        new_text = remove_blocks(doc, keep_v1=keep_v1)
        baseline = doc.raw_text.replace("\r\n", "\n").replace("\n", doc.line_ending)
        if new_text == baseline:
            print(f"OK   {doc.object_name}: no v2 (or v1) fences present, nothing to strip")
            return EXIT_OK
        diff = make_diff(doc.raw_text, new_text, str(wiki_path))
        wiki_path.write_bytes(new_text.encode("utf-8"))
        print(f"OK   {doc.object_name}: stripped fences -> {wiki_path}")
        if diff:
            print()
            print("--- DIFF ---")
            print(diff)
        return EXIT_OK

    # ---- need a tableau extract for judge / dry-run / apply ---------------
    tableau_path = tableau_path_explicit or auto_resolve_tableau(doc)
    if tableau_path is None or not tableau_path.exists():
        print(
            f"OK   {doc.object_name}: no Tableau extract available "
            f"(looked for knowledge/tableau/*__{doc.db_schema}/{doc.object_name}.md). "
            "Nothing to do.",
        )
        return EXIT_OK

    tableau_text = tableau_path.read_text(encoding="utf-8")
    bundle_size = len(doc.raw_text.encode("utf-8")) + len(tableau_text.encode("utf-8"))
    if bundle_size > MAX_BUNDLE_BYTES_WARN:
        print(
            f"WARN bundle size {bundle_size:,} bytes (~{bundle_size // 4:,} tokens). "
            "May approach Claude context limit.",
            file=sys.stderr,
        )

    # ---- 1. Build prompt --------------------------------------------------
    prompt = build_prompt(doc.raw_text, tableau_text, doc.columns)

    # ---- 2. Run claude ---------------------------------------------------
    raw_output, err = _run_claude(prompt, model=model)
    parsed: Optional[dict] = None
    verdict: Optional[Verdict] = None
    if raw_output:
        parsed = extract_json_object(raw_output)
        if parsed is None:
            err = "could not parse JSON object from claude stdout"

    if parsed is not None:
        verdict = normalize_verdict(parsed, doc.columns)

    if verdict is None:
        # LLM failed - write sidecars, exit with usage error
        write_sidecars(
            audit_root, doc, tableau_path, prompt, raw_output, parsed, verdict,
            err, None, mode,
            wiki_sha_before=wiki_sha_before, wiki_sha_after=wiki_sha_before,
        )
        print(f"ERR  {doc.object_name}: LLM judge failed: {err}", file=sys.stderr)
        return EXIT_USAGE

    # ---- 3. Branch on mode -----------------------------------------------
    if mode == "judge-only":
        write_sidecars(
            audit_root, doc, tableau_path, prompt, raw_output, parsed, verdict,
            "", None, mode,
            wiki_sha_before=wiki_sha_before, wiki_sha_after=wiki_sha_before,
        )
        print(
            f"OK   {doc.object_name}: verdict={verdict.verdict} "
            f"(table={len(verdict.table_findings)}, "
            f"cols={len(verdict.column_findings)}, "
            f"dropped={len(verdict.dropped_unknown_columns)})"
        )
        print(f"     rationale: {verdict.rationale}")
        return EXIT_OK

    if verdict.verdict == "DISCARD":
        # Wiki untouched, sidecar written, done.
        write_sidecars(
            audit_root, doc, tableau_path, prompt, raw_output, parsed, verdict,
            "", None, mode,
            wiki_sha_before=wiki_sha_before, wiki_sha_after=wiki_sha_before,
        )
        print(
            f"OK   {doc.object_name}: DISCARD - wiki untouched. "
            f"rationale: {verdict.rationale}"
        )
        return EXIT_OK

    # ENRICH path -----------------------------------------------------------
    new_text = apply_blocks(doc, verdict, keep_v1=keep_v1)
    diff = make_diff(doc.raw_text, new_text, str(wiki_path))
    wiki_sha_after = _sha(new_text)

    # Validate
    errors = validate_post_apply(new_text, doc, verdict, keep_v1=keep_v1)
    if errors:
        write_sidecars(
            audit_root, doc, tableau_path, prompt, raw_output, parsed, verdict,
            "validation failed: " + "; ".join(errors), None, mode,
            wiki_sha_before=wiki_sha_before, wiki_sha_after=wiki_sha_before,
        )
        print(
            f"ERR  {doc.object_name}: post-apply validation failed:",
            file=sys.stderr,
        )
        for e in errors:
            print(f"       - {e}", file=sys.stderr)
        return EXIT_VALIDATION_FAILED

    if mode == "apply":
        wiki_path.write_bytes(new_text.encode("utf-8"))
        write_sidecars(
            audit_root, doc, tableau_path, prompt, raw_output, parsed, verdict,
            "", new_text, mode,
            wiki_sha_before=wiki_sha_before, wiki_sha_after=wiki_sha_after,
        )
        print(
            f"OK   {doc.object_name}: ENRICH applied "
            f"(table_findings={len(verdict.table_findings)}, "
            f"column_findings={len(verdict.column_findings)}, "
            f"dropped={len(verdict.dropped_unknown_columns)})"
        )
        print(f"     rationale: {verdict.rationale}")
        return EXIT_OK

    # dry-run
    preview_path = wiki_path.with_suffix(wiki_path.suffix + ".tableau-semantics-preview.md")
    preview_path.write_bytes(new_text.encode("utf-8"))
    write_sidecars(
        audit_root, doc, tableau_path, prompt, raw_output, parsed, verdict,
        "", new_text, mode,
        wiki_sha_before=wiki_sha_before, wiki_sha_after=wiki_sha_after,
    )
    print(
        f"OK   {doc.object_name}: DRY-RUN preview -> {preview_path.name} "
        f"(table_findings={len(verdict.table_findings)}, "
        f"column_findings={len(verdict.column_findings)}, "
        f"dropped={len(verdict.dropped_unknown_columns)})"
    )
    print(f"     rationale: {verdict.rationale}")
    if diff:
        print()
        print("--- DIFF ---")
        print(diff)
    return EXIT_OK


def main() -> int:
    p = argparse.ArgumentParser(
        description="LLM-judged semantic uplift for DWH wikis using Tableau extracts."
    )
    p.add_argument("--wiki", required=True, help="Path to a single wiki .md file.")
    p.add_argument("--tableau", default="",
                   help="Optional Tableau extract path. Auto-resolved if omitted.")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--dry-run", action="store_true",
                   help="Default. Write preview file + show diff, no in-place write.")
    g.add_argument("--apply", action="store_true",
                   help="Apply ENRICH verdict in place; DISCARD leaves wiki untouched.")
    g.add_argument("--remove", action="store_true",
                   help="Strip v2 fences (and v1 unless --keep-v1) without calling LLM.")
    g.add_argument("--judge-only", action="store_true",
                   help="Run LLM, write sidecars, never touch wiki.")
    p.add_argument("--audit-dir", default=str(DEFAULT_AUDIT_DIR),
                   help="Sidecar root (default: audits/tableau-enrichment).")
    p.add_argument("--model", default="",
                   help="Optional claude model override (passes --model to CLI).")
    p.add_argument("--keep-v1", action="store_true",
                   help="Do NOT strip v1 TABLEAU-ENRICHMENT-* fences when applying v2.")
    args = p.parse_args()

    if args.apply:
        mode = "apply"
    elif args.remove:
        mode = "remove"
    elif args.judge_only:
        mode = "judge-only"
    else:
        mode = "dry-run"

    wiki_path = Path(args.wiki)
    if not wiki_path.is_absolute():
        wiki_path = (REPO_ROOT / wiki_path).resolve()
    else:
        wiki_path = wiki_path.resolve()

    tableau_explicit: Optional[Path] = None
    if args.tableau:
        tp = Path(args.tableau)
        if not tp.is_absolute():
            tp = (REPO_ROOT / tp).resolve()
        else:
            tp = tp.resolve()
        tableau_explicit = tp

    audit_root = Path(args.audit_dir)
    if not audit_root.is_absolute():
        audit_root = (REPO_ROOT / audit_root).resolve()

    return run(
        wiki_path=wiki_path,
        tableau_path_explicit=tableau_explicit,
        mode=mode,
        audit_root=audit_root,
        keep_v1=args.keep_v1,
        model=args.model or None,
    )


if __name__ == "__main__":
    sys.exit(main())
