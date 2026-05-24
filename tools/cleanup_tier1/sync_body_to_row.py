"""sync_body_to_row.py — general repair for wikis where the body prose
contradicts the §4 column description.

Algorithm (column-agnostic):

  1. Parse the wiki to find the §4 elements row for the target column.
  2. Extract the canonical enum mapping from the row description by matching
     `\\d+=Word` patterns.
  3. Walk every paragraph in the body (sections 1, 2, 3, 5, 6, 7, 8) and find
     paragraphs that:
        (a) mention the column by name, AND
        (b) contain at least one  `\\d+=Word`  or  `\\bID\\s*=\\s*\\d+`  or
            `\\(?ID\\s*\\d+\\)?` numeric reference, AND
        (c) contain at least one numeric value or name that DIFFERS from the
            canonical enum.
  4. For each such paragraph, call the LLM to rewrite it using the canonical
     enum verbatim, preserving everything else (structure, surrounding prose,
     code fences, links).
  5. Replace those paragraphs in-place.

Inputs:
  --wiki         path to the .md to repair
  --column       column name (e.g. DocumentStatusID)

This is a focused tool: one wiki, one column. Call it as many times as you
have body lies. Cached LLM calls are free on re-runs.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'tools'))

from tier1_audit.judge import _run_claude, claude_cli_available  # noqa: E402


# --------------------------------------------------------------------------
# 1. Extract canonical enum from the §4 row description
# --------------------------------------------------------------------------
_ROW_RE = re.compile(r"^\s*\|\s*(?:\d+\s*\|\s*)?([A-Za-z][A-Za-z0-9_]*)\s*\|")
_ENUM_RE = re.compile(r"\b(\d+)\s*=\s*([A-Za-z][A-Za-z0-9 ]*?)(?=[,.;)]|\s+\d+=|$)")


def _extract_row_description(text: str, column: str) -> tuple[int, str] | None:
    """Return (line_no, description) for the §4 row of `column`, or None."""
    for i, line in enumerate(text.splitlines(), 1):
        m = _ROW_RE.match(line)
        if not m or m.group(1) != column:
            continue
        # description is the last `|`-delimited cell
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not cells:
            continue
        return i, cells[-1]
    return None


def _extract_enum(desc: str) -> list[tuple[int, str]]:
    """Return list of (id, name) tuples found in the description text."""
    out = []
    for m in _ENUM_RE.finditer(desc):
        out.append((int(m.group(1)), m.group(2).strip()))
    return out


# --------------------------------------------------------------------------
# 2. Locate body paragraphs to rewrite
# --------------------------------------------------------------------------
_NUMERIC_REF_RE = re.compile(
    r"(\b\d+\s*=\s*[A-Za-z]"          # 1=Foo
    r"|\bID\s*=\s*\d+"                # ID=1, ID = 1
    r"|\(ID\s*=?\s*\d+"               # (ID=1, (ID 1)
    r"|\bWHERE\s+\w+\s+IN\s*\([^)]*\)" # WHERE col IN (1,2,3)
    r")",
    re.IGNORECASE,
)


_NUM_WORD = {
    "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
    "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
}


def _enum_violations(paragraph: str, canonical: list[tuple[int, str]]) -> list[str]:
    """Return list of <id=word> / cardinality / unknown-enum tokens that
    don't match the canonical enum. Empty list = no violation."""
    canonical_map = {idx: name.lower() for idx, name in canonical}
    canonical_count = len(canonical)
    violations = []

    # Enum id-mismatch
    for m in _ENUM_RE.finditer(paragraph):
        idx, name = int(m.group(1)), m.group(2).strip()
        expected = canonical_map.get(idx)
        if expected and expected != name.lower():
            violations.append(f"{idx}={name} (canonical: {idx}={canonical_map[idx]})")
        elif idx not in canonical_map:
            violations.append(f"{idx}={name} (canonical has no {idx})")

    # Unknown enum names — quick heuristic for common fabrications
    for m in re.finditer(r"\b(POIApproved|POAApproved|New\s+Upload|Reviewed|Accepted|Rejected|None)\b",
                         paragraph):
        word = m.group(1).replace(" ", "").lower()
        if word not in {n.lower().replace(" ", "") for _, n in canonical}:
            violations.append(f"unknown enum name {m.group(1)!r}")

    # Cardinality references — `N states` / `N rows` / number-word states
    for m in re.finditer(r"(\d+)\s+(?:states?|rows?|values?|entries?)\b",
                         paragraph, re.IGNORECASE):
        n = int(m.group(1))
        if n != canonical_count:
            violations.append(f"cardinality '{m.group(0)}' (canonical has {canonical_count})")
    for m in re.finditer(r"\b(two|three|four|five|six|seven|eight|nine|ten|"
                         r"eleven|twelve)\s+(states?|rows?|values?|entries?)\b",
                         paragraph, re.IGNORECASE):
        n = _NUM_WORD[m.group(1).lower()]
        if n != canonical_count:
            violations.append(f"cardinality '{m.group(0)}' (canonical has {canonical_count})")

    return violations


def _split_paragraphs(text: str) -> list[tuple[int, int, str]]:
    """Return (start_line_idx, end_line_idx_exclusive, paragraph_text)."""
    lines = text.splitlines(keepends=True)
    out = []
    cur_start = 0
    in_para = False
    for i, ln in enumerate(lines):
        is_blank = (ln.strip() == "")
        if not in_para and not is_blank:
            cur_start = i
            in_para = True
        elif in_para and is_blank:
            out.append((cur_start, i, ''.join(lines[cur_start:i])))
            in_para = False
    if in_para:
        out.append((cur_start, len(lines), ''.join(lines[cur_start:])))
    return out


# --------------------------------------------------------------------------
# 3. LLM rewrite prompt
# --------------------------------------------------------------------------
_REWRITE_PROMPT = """\
You are repairing a data dictionary wiki. The §4 column comment for the
column below is the ONLY source of truth. The body paragraph that follows
contains numeric/state references that contradict the §4 column comment.

Rewrite the paragraph so EVERY  `<n>=<Name>`  or  `(ID=<n>)`  or
`ID <n>`  or any other numeric/state reference uses the canonical enum
verbatim. Preserve everything else: structure, surrounding prose, code
fences, markdown headers, lists, tables, links. Do NOT add new enum values.
Do NOT remove non-enum prose. If a paragraph mentions a state name that is
not in the canonical enum AT ALL, drop that name entirely and rephrase
around it.

Column:            {column}
Canonical enum (from §4):
{canonical}

Violations detected in this paragraph:
{violations}

Paragraph to rewrite (between the BEGIN/END markers):
BEGIN
{paragraph}
END

Return EXACTLY the rewritten paragraph, no commentary, no markdown code
fences around the result. The rewritten paragraph must keep the same
markdown-level structure (same headers, same bullet style, same line
breaks). If the input begins with a header line like `### X`, keep that
exact header.
"""


def _llm_rewrite(column: str, canonical: list[tuple[int, str]],
                 violations: list[str], paragraph: str,
                 *, model: str | None, timeout_s: int) -> str | None:
    canonical_str = "\n".join(f"  {idx} = {name}" for idx, name in canonical)
    violations_str = "\n".join(f"  - {v}" for v in violations) or "  (auto-detected)"
    prompt = _REWRITE_PROMPT.format(
        column=column,
        canonical=canonical_str,
        violations=violations_str,
        paragraph=paragraph.rstrip("\n"),
    )
    stdout, err = _run_claude(prompt, model=model, timeout_s=timeout_s)
    if stdout is None:
        print(f'    LLM error: {err}', file=sys.stderr)
        return None
    # Strip ``` code fences if the model wrapped them
    out = stdout.strip()
    if out.startswith("```"):
        out = out.strip("`")
        if "\n" in out:
            out = out.split("\n", 1)[1]
        out = out.rstrip("`").strip()
    return out


# --------------------------------------------------------------------------
# 4. Main
# --------------------------------------------------------------------------
def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--wiki', required=True, help='path to .md wiki to repair')
    ap.add_argument('--column', required=True,
                    help='column name (e.g. DocumentStatusID)')
    ap.add_argument('--dry-run', action='store_true',
                    help='print proposed rewrites without writing')
    ap.add_argument('--model', default=None)
    ap.add_argument('--timeout', type=int, default=180)
    args = ap.parse_args(argv)

    wiki = Path(args.wiki)
    if not wiki.is_absolute():
        wiki = REPO / wiki
    if not wiki.exists():
        print(f"ERROR: wiki not found: {wiki}", file=sys.stderr)
        return 2
    if not claude_cli_available() and not args.dry_run:
        print("ERROR: claude CLI not available", file=sys.stderr)
        return 2

    text = wiki.read_text(encoding='utf-8')
    row = _extract_row_description(text, args.column)
    if not row:
        print(f"ERROR: §4 row for column {args.column!r} not found in {wiki}", file=sys.stderr)
        return 2
    row_line, row_desc = row
    canonical = _extract_enum(row_desc)
    if not canonical:
        print(f"NOTE: §4 row description does not contain any `<n>=<Name>` enum;"
              f" nothing to sync. Description: {row_desc[:200]!r}", file=sys.stderr)
        return 0
    print(f"Canonical enum from {wiki.name}:{row_line} ({args.column}):")
    for idx, name in canonical:
        print(f"  {idx} = {name}")
    print()

    paragraphs = _split_paragraphs(text)
    # Find paragraphs that mention the column AND have at least one violation.
    targets = []
    # Compose the table-name (filename stem) so cardinality references like
    # "the 7 rows of Dim_DocumentStatus" can be picked up by name OR table.
    table_stem = wiki.stem
    _cardinality_re = re.compile(
        r"(?:\b\d+|\b(?:two|three|four|five|six|seven|eight|nine|ten|"
        r"eleven|twelve))\s+(?:states?|rows?|values?|entries?)\b",
        re.IGNORECASE,
    )
    # Skip the §4 row paragraph itself
    for start, end, p in paragraphs:
        # Skip the §4 elements table (containing the row line)
        if start <= row_line - 1 < end:
            continue
        if not (re.search(rf"\b{re.escape(args.column)}\b", p)
                or re.search(rf"\b{re.escape(table_stem)}\b", p, re.IGNORECASE)
                or _ENUM_RE.search(p)
                or _cardinality_re.search(p)
                or 'POIApproved' in p or 'POAApproved' in p):
            continue
        violations = _enum_violations(p, canonical)
        if violations:
            targets.append((start, end, p, violations))

    if not targets:
        print("No body paragraphs to repair — wiki is consistent.")
        return 0

    print(f"Paragraphs to repair: {len(targets)}")
    print()

    lines = text.splitlines(keepends=True)
    # Process from bottom to top so line indices stay valid as we rewrite
    targets.sort(key=lambda t: t[0], reverse=True)
    changes = 0
    for start, end, p, violations in targets:
        print(f"--- paragraph lines {start + 1}..{end} ({len(violations)} violations) ---")
        for v in violations:
            print(f"  violation: {v}")
        print("  ORIG:")
        for ln in p.splitlines()[:6]:
            print(f"    {ln}")
        if len(p.splitlines()) > 6:
            print(f"    … (+{len(p.splitlines()) - 6} more lines)")
        if args.dry_run:
            print("  [dry-run] skipping LLM call")
            continue
        rewritten = _llm_rewrite(args.column, canonical, violations, p,
                                  model=args.model, timeout_s=args.timeout)
        if rewritten is None:
            print("  LLM rewrite failed; skipping")
            continue
        # Preserve trailing newline behavior
        if not rewritten.endswith("\n"):
            rewritten += "\n"
        # Re-split into lines
        new_lines = rewritten.splitlines(keepends=True)
        print("  NEW:")
        for ln in new_lines[:6]:
            print(f"    {ln.rstrip()}")
        if len(new_lines) > 6:
            print(f"    … (+{len(new_lines) - 6} more lines)")
        # Splice into the buffer
        lines[start:end] = new_lines
        changes += 1
        print()

    if not args.dry_run and changes:
        wiki.write_text(''.join(lines), encoding='utf-8')
        print(f"Wrote {changes} paragraph(s) to {wiki.relative_to(REPO).as_posix()}")
    elif args.dry_run:
        print(f"DRY-RUN: would write {len(targets)} paragraph(s)")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
