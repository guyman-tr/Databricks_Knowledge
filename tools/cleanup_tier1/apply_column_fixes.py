"""apply_column_fixes.py — apply proposed_fix descriptions from
`llm_column_audit.py`'s report.csv back into the wiki files.

For every FAIL row with a non-empty proposed_fix, find the §4 elements row
matching (line_no, column_name) and rewrite the Description cell. Preserves
all other cells (#, Element, Type, Nullable, [Confidence,] [Default]).

Usage:
  python -m cleanup_tier1.apply_column_fixes \\
      --report audits/_llm_column_audit_<UTC>/report.csv \\
      [--dry-run]
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def _split_table_row(line: str) -> list[str] | None:
    """Return cells of a markdown table row, or None if not a table row.
    Strips leading/trailing pipe and edge whitespace from each cell."""
    s = line.rstrip('\r\n')
    if not s.lstrip().startswith('|'):
        return None
    # Trim leading pipe; trim trailing pipe (if any)
    inner = s.strip()
    if inner.startswith('|'):
        inner = inner[1:]
    if inner.endswith('|'):
        inner = inner[:-1]
    return [c.strip() for c in inner.split('|')]


def _rebuild_table_row(cells: list[str], leading_ws: str = '') -> str:
    return leading_ws + '| ' + ' | '.join(cells) + ' |'


def _replace_description(line: str, new_desc: str, column_name: str) -> str | None:
    """Return the rewritten line, or None if the row doesn't match column_name.

    The element-column may be at index 0 (no `#` column) or index 1 (with `#`).
    We accept either; the description is always the LAST cell."""
    cells = _split_table_row(line)
    if not cells or len(cells) < 3:
        return None
    # Find which cell holds the column name. Must be one of the first three
    # cells (typical layouts: [name, ...], [#, name, ...]).
    name_idx = None
    for i in range(min(3, len(cells))):
        if cells[i].strip() == column_name:
            name_idx = i
            break
    if name_idx is None:
        return None
    cells[-1] = new_desc.strip()
    leading_ws = line[: len(line) - len(line.lstrip())]
    return _rebuild_table_row(cells, leading_ws=leading_ws) + ('\n' if line.endswith('\n') else '')


def apply_one(wiki_path: Path, line_no: int, column_name: str, new_desc: str,
              dry_run: bool) -> tuple[bool, str]:
    """Returns (changed, message)."""
    try:
        lines = wiki_path.read_text(encoding='utf-8').splitlines(keepends=True)
    except FileNotFoundError:
        return False, f'file not found: {wiki_path}'
    if line_no < 1 or line_no > len(lines):
        return False, f'line {line_no} out of range (1..{len(lines)})'
    line = lines[line_no - 1]
    new_line = _replace_description(line, new_desc, column_name)
    if new_line is None:
        return False, f'line {line_no} does not match column {column_name!r}'
    if new_line == line:
        return False, 'no-op (already matches proposed fix)'
    if dry_run:
        return True, 'would change'
    lines[line_no - 1] = new_line
    wiki_path.write_text(''.join(lines), encoding='utf-8')
    return True, 'changed'


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--report', required=True,
                    help='path to report.csv from llm_column_audit.py')
    ap.add_argument('--dry-run', action='store_true',
                    help='print planned changes without writing files')
    args = ap.parse_args(argv)

    report = Path(args.report)
    if not report.is_absolute():
        report = REPO / report
    if not report.exists():
        print(f'ERROR: report not found: {report}', file=sys.stderr)
        return 2

    with report.open(encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    applied = 0
    skipped = 0
    errors = 0
    print(f'reading {report.relative_to(REPO).as_posix()}')
    print(f'rows: {len(rows)}')

    by_wiki = defaultdict(list)
    for r in rows:
        if r.get('verdict') != 'FAIL':
            continue
        if not r.get('proposed_fix'):
            continue
        by_wiki[r['wiki_path']].append(r)

    print(f'wikis with applicable fixes: {len(by_wiki)}')
    print('---')
    # Process each wiki — sort by line_no DESC so earlier line numbers stay
    # stable while we rewrite (we only edit one line each anyway, but be safe).
    for wiki_path_rel, group in by_wiki.items():
        wiki_path = REPO / wiki_path_rel
        group.sort(key=lambda r: int(r['line_no']), reverse=True)
        for r in group:
            line_no = int(r['line_no'])
            col = r['column_name']
            new_desc = r['proposed_fix']
            changed, msg = apply_one(wiki_path, line_no, col, new_desc,
                                     dry_run=args.dry_run)
            tag = '[DRY]' if args.dry_run else ('[OK]' if changed else '[skip]')
            print(f'{tag} {wiki_path_rel}:{line_no}  {col}')
            if not changed:
                print(f'        {msg}')
                if 'not found' in msg or 'out of range' in msg or 'does not match' in msg:
                    errors += 1
                else:
                    skipped += 1
                continue
            print(f'        old line was rewritten with {len(new_desc)} chars of new desc')
            applied += 1

    print('---')
    print(f'applied: {applied}')
    print(f'skipped: {skipped}')
    print(f'errors:  {errors}')
    return 0 if errors == 0 else 1


if __name__ == '__main__':
    raise SystemExit(main())
