"""expand_same_lineage.py — replace "Same lineage as X" / "Same as X" shortcuts
in wiki output-column tables with the actual source string from X.

Mechanical, deterministic, no LLM. The rule is:

    For a row whose Source cell matches "Same (lineage|source|as) (above|<col>)",
    look up the named column in the SAME table, take its Source string, and
    substitute `.X` → `.<current_col>` to produce the expanded source. If the
    Transformation cell on the current row is just "Direct" while X's
    Transformation is more specific, also copy X's Transformation.

Tier cells are NEVER changed (that's a separate tier-reconciliation concern).

Supports transitive resolution up to depth=3 (if X itself points to Y, follow).

Usage:
  python -m cleanup_tier1.expand_same_lineage --file <wiki.md> [--dry-run]
  python -m cleanup_tier1.expand_same_lineage --glob 'knowledge/synapse/Wiki/**/Functions/*.md' [--dry-run]
"""
from __future__ import annotations

import argparse
import glob as _glob
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[2]

# "Same lineage as X" / "Same source as X" / "Same as X above" / "Same as X" /
# "Lineage same as X" / "See X above" — case-insensitive.
_SHORTCUT_RE = re.compile(
    r"""^\s*
        (?:
            same \s+ (?:lineage|source) \s+ as \s+ ([A-Za-z_][A-Za-z0-9_]*) |
            same \s+ as \s+ ([A-Za-z_][A-Za-z0-9_]*) (?:\s+ above)? |
            lineage \s+ same \s+ as \s+ ([A-Za-z_][A-Za-z0-9_]*) |
            see \s+ ([A-Za-z_][A-Za-z0-9_]*) (?:\s+ above)?
        )
        \s* $
    """,
    re.IGNORECASE | re.VERBOSE,
)


@dataclass
class TableRow:
    line_no: int                    # 1-based
    raw_line: str                   # original line (no newline stripping)
    cells: list[str]                # cells (already stripped)
    leading_ws: str
    line_ending: str                # '' or '\n' or '\r\n'


def _split_cells(line: str) -> tuple[list[str], str, str] | None:
    """Return (cells, leading_ws, line_ending) or None if not a table row."""
    if not line.lstrip().startswith('|'):
        return None
    leading_ws_len = len(line) - len(line.lstrip())
    leading_ws = line[:leading_ws_len]
    ending = ''
    if line.endswith('\r\n'):
        ending = '\r\n'
        body = line[:-2]
    elif line.endswith('\n'):
        ending = '\n'
        body = line[:-1]
    else:
        body = line
    body = body.strip()
    if body.startswith('|'):
        body = body[1:]
    if body.endswith('|'):
        body = body[:-1]
    cells = [c.strip() for c in body.split('|')]
    return cells, leading_ws, ending


def _rebuild_line(cells: list[str], leading_ws: str, ending: str) -> str:
    return f"{leading_ws}| {' | '.join(cells)} |{ending}"


def _is_separator(cells: list[str]) -> bool:
    return all(re.fullmatch(r":?-{2,}:?", c.strip()) for c in cells if c.strip())


def _find_tables(lines: list[str]) -> list[tuple[int, int, list[str]]]:
    """Return list of (start_line_no, end_line_no_exclusive, header_cells)
    for every markdown table in the file (1-based line numbers)."""
    tables: list[tuple[int, int, list[str]]] = []
    i = 0
    while i < len(lines):
        s = _split_cells(lines[i])
        if s is None:
            i += 1
            continue
        # look ahead one line for a separator
        if i + 1 >= len(lines):
            i += 1
            continue
        nxt = _split_cells(lines[i + 1])
        if nxt is None or not _is_separator(nxt[0]):
            i += 1
            continue
        header_cells = s[0]
        start = i + 1
        j = i + 2
        while j < len(lines):
            row = _split_cells(lines[j])
            if row is None:
                break
            j += 1
        tables.append((start, j + 1, header_cells))
        i = j
    return tables


def _column_index(header: list[str], candidates: list[str]) -> int | None:
    norm = [h.strip().lower() for h in header]
    for cand in candidates:
        if cand.lower() in norm:
            return norm.index(cand.lower())
    return None


def _try_match_shortcut(text: str) -> str | None:
    m = _SHORTCUT_RE.match(text)
    if not m:
        return None
    for g in m.groups():
        if g:
            return g
    return None


def _substitute_column(source_text: str, old_col: str, new_col: str) -> str:
    """Replace `.old_col` with `.new_col` (word boundary)."""
    # Match `.OldCol` at word boundaries so we don't touch substrings.
    pat = re.compile(rf"\.{re.escape(old_col)}\b")
    return pat.sub(f".{new_col}", source_text)


def _expand_table(lines: list[str], header_line_idx: int,
                  end_line_exclusive: int) -> tuple[int, list[tuple[int, str, str]]]:
    """
    Expand shortcuts in one table. Returns (n_changes, change_log).
    Modifies `lines` in place.
    change_log is a list of (line_no_1based, before, after) for reporting.
    """
    header_cells_pack = _split_cells(lines[header_line_idx - 1])
    if header_cells_pack is None:
        return 0, []
    header_cells = header_cells_pack[0]

    name_idx = _column_index(header_cells,
                             ['Column', 'Element', 'Name', 'Field'])
    src_idx = _column_index(header_cells, ['Source', 'Lineage', 'Origin'])
    if name_idx is None or src_idx is None:
        return 0, []
    trans_idx = _column_index(header_cells,
                              ['Transformation', 'Formula', 'Derivation', 'Logic'])

    # First pass: index every row's column-name -> (cells, line_no_1based)
    rows_by_name: dict[str, tuple[list[str], int]] = {}
    data_start = header_line_idx + 2  # skip header + separator
    for li in range(data_start - 1, end_line_exclusive - 1):
        s = _split_cells(lines[li])
        if s is None:
            continue
        cells, _, _ = s
        if name_idx >= len(cells) or src_idx >= len(cells):
            continue
        col_name = cells[name_idx].strip()
        if col_name and not col_name.startswith('-'):
            rows_by_name[col_name] = (cells, li + 1)

    # Second pass: expand shortcuts
    changes: list[tuple[int, str, str]] = []
    for li in range(data_start - 1, end_line_exclusive - 1):
        s = _split_cells(lines[li])
        if s is None:
            continue
        cells, leading_ws, ending = s
        if name_idx >= len(cells) or src_idx >= len(cells):
            continue
        cur_name = cells[name_idx].strip()
        cur_src = cells[src_idx]
        target = _try_match_shortcut(cur_src)
        if target is None:
            continue
        # Resolve target, transitively up to 3 hops.
        seen = {cur_name}
        ref_name = target
        ref_cells = None
        for _ in range(3):
            if ref_name in seen or ref_name not in rows_by_name:
                break
            seen.add(ref_name)
            ref_cells, _ = rows_by_name[ref_name]
            ref_src = ref_cells[src_idx]
            nxt = _try_match_shortcut(ref_src)
            if nxt is None:
                break
            ref_name = nxt
            ref_cells = None
        if ref_cells is None and ref_name in rows_by_name:
            ref_cells, _ = rows_by_name[ref_name]
        if ref_cells is None:
            continue  # couldn't resolve

        # Build the new source by substituting the *target column name* in the
        # ref source string with the current column name.
        new_src = _substitute_column(ref_cells[src_idx], target, cur_name)
        before_line = lines[li]
        new_cells = list(cells)
        new_cells[src_idx] = new_src
        # If current Transformation is empty / dash / 'Direct' and the ref
        # has a more informative one, copy it.
        if trans_idx is not None and trans_idx < len(cells) \
                and trans_idx < len(ref_cells):
            cur_t = new_cells[trans_idx].strip()
            ref_t = ref_cells[trans_idx].strip()
            if (not cur_t or cur_t in {'-', '—', 'Direct'}) \
                    and ref_t and ref_t not in {'-', '—', 'Direct'}:
                new_cells[trans_idx] = ref_t
        new_line = _rebuild_line(new_cells, leading_ws, ending)
        if new_line != before_line:
            lines[li] = new_line
            changes.append((li + 1, before_line.rstrip('\r\n'),
                            new_line.rstrip('\r\n')))
    return len(changes), changes


def process_file(path: Path, dry_run: bool) -> tuple[int, list[tuple[int, str, str]]]:
    text = path.read_text(encoding='utf-8')
    # Preserve line endings — splitlines(keepends=True) keeps them.
    lines = text.splitlines(keepends=True)
    tables = _find_tables(lines)
    total = 0
    all_changes: list[tuple[int, str, str]] = []
    for header_idx, end_idx, _ in tables:
        n, changes = _expand_table(lines, header_idx, end_idx)
        total += n
        all_changes.extend(changes)
    if total and not dry_run:
        path.write_text(''.join(lines), encoding='utf-8')
    return total, all_changes


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--file', help='single wiki file (.md)')
    g.add_argument('--glob', help='glob over wiki files, e.g. '
                                  '"knowledge/synapse/Wiki/**/Functions/*.md"')
    ap.add_argument('--dry-run', action='store_true',
                    help='print diffs but do not write files')
    args = ap.parse_args(argv)

    files: list[Path] = []
    if args.file:
        p = Path(args.file)
        if not p.is_absolute():
            p = REPO / p
        files = [p]
    else:
        files = [Path(p) for p in _glob.glob(args.glob, recursive=True)]
        files = [p if p.is_absolute() else REPO / p for p in files]

    if not files:
        print('No files matched.', file=sys.stderr)
        return 2

    total = 0
    files_touched = 0
    for f in files:
        if not f.exists():
            print(f'  [skip] not found: {f}')
            continue
        n, changes = process_file(f, dry_run=args.dry_run)
        if n == 0:
            continue
        files_touched += 1
        total += n
        rel = f.relative_to(REPO).as_posix()
        tag = '[DRY]' if args.dry_run else '[OK]'
        print(f'{tag} {rel}  —  {n} expansion(s)')
        for line_no, before, after in changes:
            print(f'    line {line_no}:')
            print(f'      -  {before.strip()}')
            print(f'      +  {after.strip()}')

    print('---')
    verb = 'would change' if args.dry_run else 'changed'
    print(f'{verb} {total} row(s) across {files_touched} file(s)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
