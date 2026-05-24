"""llm_column_audit.py — general LLM-driven semantic audit of named columns.

Walks every wiki under `--scope`, filters rows by `--columns`, and for each
matching row:

 1. resolves the parent column via the existing resolver/source_lookup,
 2. calls the existing LLM judge (`tools/tier1_audit/judge.py`) to compare
    the row description against the parent's description AND against any
    prose in the same wiki that mentions the column,
 3. emits a per-row report with a verdict + proposed corrected description.

The harness is column-agnostic. You pick which columns to audit:

  python -m cleanup_tier1.llm_column_audit \\
      --columns Credit,DocumentStatusID                 \\
      --scope knowledge/synapse/Wiki,knowledge/UC_generated,knowledge/ProdSchemas

Output (CSV + Markdown) lands under `audits/_llm_column_audit_<UTC>/`.

This is a SMALL-SCALE general harness on purpose. It does not bulk-apply
anything; pass `--apply` separately after you've reviewed the report.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'tools'))

from tier1_audit.parser import parse_wiki_columns, ColumnRow, TierTag  # noqa: E402
from tier1_audit.resolver import resolve, REPO as RESOLVER_REPO         # noqa: E402
from tier1_audit.source_lookup import lookup_source_column             # noqa: E402
from tier1_audit.judge import (                                         # noqa: E402
    Judgment, _run_claude, _parse_judge_response, _cache_key, _cache_path,
    _load_from_cache, _save_to_cache, DEFAULT_CACHE_DIR, claude_cli_available,
)


WIKI_ROOTS = [
    REPO / 'knowledge' / 'synapse' / 'Wiki',
    REPO / 'knowledge' / 'UC_generated',
    REPO / 'knowledge' / 'ProdSchemas',
]
SKIP_PATH_FRAGMENTS = ('_discovery/upstream_wikis', '_discovery/column_lineage')
SKIP_SUFFIXES = ('.lineage.md', '.review-needed.md', '.deploy-report.md',
                 '.status.json')


# ---------------------------------------------------------------------------
# Discover rows for the requested columns
# ---------------------------------------------------------------------------
def collect_rows(column_names: set[str], roots: list[Path]) -> list[ColumnRow]:
    rows: list[ColumnRow] = []
    for root in roots:
        if not root.exists():
            continue
        for md in root.rglob('*.md'):
            if any(md.name.endswith(s) for s in SKIP_SUFFIXES):
                continue
            rel = md.relative_to(REPO).as_posix()
            if any(f in rel for f in SKIP_PATH_FRAGMENTS):
                continue
            try:
                parsed = parse_wiki_columns(md)
            except Exception:
                continue
            for r in parsed:
                if r.column_name in column_names:
                    rows.append(r)
    return rows


# ---------------------------------------------------------------------------
# Extract surrounding wiki prose that mentions the column
# ---------------------------------------------------------------------------
def gather_wiki_context(wiki_path: Path, column_name: str, max_chars: int = 2500) -> str:
    """Return all paragraphs / table rows in the wiki that mention the column,
    EXCLUDING the §4 elements row itself. Used by the judge to detect inline
    contradictions between the column comment and surrounding prose."""
    try:
        text = wiki_path.read_text(encoding='utf-8', errors='replace')
    except Exception:
        return ''
    snippets: list[str] = []
    column_re = re.compile(rf'\b{re.escape(column_name)}\b')
    # Walk paragraph by paragraph (blank-line separated)
    for para in re.split(r'\n\s*\n', text):
        if not column_re.search(para):
            continue
        # Skip the §4 Elements row itself (matches "| <n> | <Column> | ...")
        if re.search(rf'^\s*\|\s*\d+\s*\|\s*{re.escape(column_name)}\s*\|', para, re.M):
            # Keep the rest of the paragraph if it has OTHER content
            stripped = re.sub(
                rf'^\s*\|\s*\d+\s*\|\s*{re.escape(column_name)}\s*\|.*?$',
                '', para, flags=re.M,
            ).strip()
            if stripped:
                snippets.append(stripped[:600])
            continue
        snippets.append(para.strip()[:600])
    joined = '\n\n---\n\n'.join(snippets)
    return joined[:max_chars]


# ---------------------------------------------------------------------------
# Find parent column row (via resolver + source_lookup)
# ---------------------------------------------------------------------------
def find_parent(row: ColumnRow) -> tuple[Path | None, ColumnRow | None, str]:
    """Returns (parent_wiki, parent_row, source_text_used). If no tier tag,
    returns (None, None, '')."""
    if not row.tier_tags:
        return None, None, ''
    # Use the OUTERMOST tag (the strongest claim) as the source pointer.
    primary = row.tier_tags[-1]
    res = resolve(primary.source_text)
    if not res.resolved:
        return None, None, primary.source_text
    lookup = lookup_source_column(res, row.column_name)
    if lookup.best_match is None:
        return res.candidate_paths[0], None, primary.source_text
    best = lookup.best_match
    # Parse the parent's row from the matched wiki
    try:
        parent_parsed = parse_wiki_columns(best.source_wiki)
    except Exception:
        return best.source_wiki, None, primary.source_text
    for pr in parent_parsed:
        if pr.column_name == best.matched_column:
            return best.source_wiki, pr, primary.source_text
    return best.source_wiki, None, primary.source_text


# ---------------------------------------------------------------------------
# Judge prompt — extended with body context
# ---------------------------------------------------------------------------
_PROMPT = """\
You are auditing a data dictionary for an analytics warehouse. For the column
named below, judge whether the CURRENT row description (and supporting prose
in the same wiki) tells the truth — given the AUTHORITATIVE source description
from the parent/upstream wiki.

Flag any of these problems:
  - Wrong scope: the row implies a narrower or wider subset than the parent
    actually contains (e.g. "Promotional Credit" when parent is just "Credit").
  - Wrong unit / sign / population / aggregation.
  - Fabricated enumeration values (e.g. "1=Foo, 2=Bar" when the upstream
    source actually has different mappings).
  - The same wiki contradicts itself (column comment says X, §1/§3/§8 prose
    says Y).
  - "Direct passthrough" / "verbatim" claims when the parent shows a real
    transformation or different semantics.

If the row description is fine but the SURROUNDING WIKI PROSE contains
contradictory enum values or false claims, set verdict=FAIL and put a
description of the contradiction in `body_contradiction`.

----- INPUT -----

Column:                {column}

Parent / source wiki:  {parent_wiki}
Parent tier:           {parent_tier}
Parent description:
  {parent_desc}

Parent body context (other prose in parent wiki mentioning this column):
  {parent_body}

----- THIS WIKI -----

Wiki path:             {this_wiki}
Current row description:
  {claim_desc}

Same-wiki body context (prose in THIS wiki mentioning this column,
excluding the §4 elements row):
  {this_body}

----- OUTPUT -----

Return EXACTLY one JSON object on a single line. Schema:

  {{"verdict": "PASS" | "FAIL",
    "severity": "LOW" | "MEDIUM" | "HIGH" | null,
    "reason": "<one short sentence>",
    "proposed_fix": "<one-sentence corrected row description, anchored to the
                     parent source, ending with '(Tier N - <source>)' where N
                     is the parent's tier> or null",
    "body_contradiction": "<one short sentence describing any contradiction in
                            the same-wiki body context, or null>"}}

PASS only if the row description AND the same-wiki body are both consistent
with the parent. Set severity null on PASS. Keep proposed_fix under 240 chars.
"""


def _run_judge(*, column: str, parent_wiki: str, parent_tier: str,
               parent_desc: str, parent_body: str, this_wiki: str,
               claim_desc: str, this_body: str,
               cache_dir: Path, model: str | None, timeout_s: int):
    # Cache by everything that affects the answer
    key = _cache_key(
        f'colaudit|{parent_wiki}|{this_wiki}',
        column,
        f'{parent_desc}|||{parent_body}',
        f'{claim_desc}|||{this_body}',
    )
    cached = _load_from_cache(cache_dir, key)
    if cached:
        return cached, ''
    prompt = _PROMPT.format(
        column=column,
        parent_wiki=parent_wiki or '(no parent resolved)',
        parent_tier=parent_tier or 'unknown',
        parent_desc=(parent_desc or '(empty)').strip(),
        parent_body=(parent_body or '(none)').strip()[:2000],
        this_wiki=this_wiki,
        claim_desc=(claim_desc or '(empty)').strip(),
        this_body=(this_body or '(none)').strip()[:2000],
    )
    stdout, err = _run_claude(prompt, model=model, timeout_s=timeout_s)
    if stdout is None:
        return None, err
    j = _parse_judge_response(stdout)
    if j is None:
        # Try to also extract body_contradiction manually
        return None, f'unparseable judge response: {stdout[:200]!r}'
    # Best-effort: parse body_contradiction from raw response
    body_contradiction = None
    m = re.search(r'"body_contradiction"\s*:\s*("(?:[^"\\]|\\.)*"|null)', stdout)
    if m:
        val = m.group(1)
        if val != 'null':
            try:
                body_contradiction = json.loads(val)
            except Exception:
                body_contradiction = val.strip('"')
    j_dict = asdict(j)
    j_dict['body_contradiction'] = body_contradiction
    # Save extended dict
    _save_to_cache(cache_dir, key, j)
    # Persist the body_contradiction alongside (parallel file)
    ext_path = _cache_path(cache_dir, key + '.ext')
    ext_path.parent.mkdir(parents=True, exist_ok=True)
    ext_path.write_text(json.dumps({'body_contradiction': body_contradiction}),
                        encoding='utf-8')
    return j, '' if body_contradiction is None else f'body_contradiction:{body_contradiction}'


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
@dataclass
class AuditResult:
    column_name: str
    wiki_path: str
    line_no: int
    tier_format: str
    current_tier: str
    current_desc: str
    parent_wiki: str
    parent_tier: str
    parent_desc: str
    verdict: str
    severity: str
    reason: str
    proposed_fix: str
    body_contradiction: str
    judge_status: str   # "cached" / "fresh" / "error:<msg>"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--columns', required=True,
                    help='comma-separated column names to audit '
                         '(case-sensitive)')
    ap.add_argument('--scope', default=','.join(str(r.relative_to(REPO))
                                                for r in WIKI_ROOTS),
                    help='comma-separated wiki roots (default: all 3)')
    ap.add_argument('--max-rows', type=int, default=0,
                    help='cap to first N matching rows (smoke test)')
    ap.add_argument('--out',
                    default=f'audits/_llm_column_audit_{time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())}',
                    help='output directory')
    ap.add_argument('--cache-dir', default=str(DEFAULT_CACHE_DIR))
    ap.add_argument('--model', default=None,
                    help='claude --model (default: CLI default)')
    ap.add_argument('--timeout', type=int, default=180)
    ap.add_argument('--no-llm', action='store_true',
                    help='print the discovered rows + parent resolutions and exit '
                         '(no LLM calls)')
    ap.add_argument('--include-untagged', action='store_true',
                    help='include rows that have no tier tag (default: skip — '
                         'nothing to audit against)')
    ap.add_argument('--include-sources', action='store_true',
                    help='include rows under knowledge/ProdSchemas (default: '
                         'skip — these are source-of-truth wikis, not lies)')
    ap.add_argument('--workers', type=int, default=4,
                    help='number of concurrent LLM judge calls (default: 4). '
                         'Set to 1 for strict serial. 8+ may trip rate limits.')
    args = ap.parse_args(argv)

    columns = {c.strip() for c in args.columns.split(',') if c.strip()}
    roots = [REPO / p.strip() for p in args.scope.split(',') if p.strip()]
    cache_dir = Path(args.cache_dir)
    out_dir = REPO / args.out
    out_dir.mkdir(parents=True, exist_ok=True)

    if not args.no_llm and not claude_cli_available():
        print('ERROR: claude CLI not available — install or pass --no-llm',
              file=sys.stderr)
        return 2

    print(f'[1/3] collecting rows for columns: {sorted(columns)}', flush=True)
    rows = collect_rows(columns, roots)
    print(f'      found {len(rows)} matching rows across '
          f'{len({r.wiki_path for r in rows})} wikis')

    if not args.include_sources:
        before = len(rows)
        rows = [r for r in rows
                if 'knowledge/ProdSchemas/' not in r.wiki_path.as_posix()
                and 'knowledge\\ProdSchemas\\' not in str(r.wiki_path)]
        print(f'      filtered out source-of-truth ProdSchemas rows: '
              f'{before - len(rows)} dropped, {len(rows)} remain')
    if not args.include_untagged:
        before = len(rows)
        rows = [r for r in rows if r.tier_tags]
        print(f'      filtered out untagged rows: '
              f'{before - len(rows)} dropped, {len(rows)} remain')
    if args.max_rows and args.max_rows < len(rows):
        rows = rows[: args.max_rows]
        print(f'      capped to first {args.max_rows} (smoke test)')

    if args.no_llm:
        print('[2/3] dry-run (no LLM); printing resolved parents …')
        for r in rows:
            parent_wiki, parent_row, src = find_parent(r)
            label = parent_wiki.relative_to(REPO).as_posix() if parent_wiki else '(unresolved)'
            ptier = ''
            if parent_row and parent_row.tier_tags:
                ptier = parent_row.tier_tags[-1].tier
            print(f"  {r.wiki_path.relative_to(REPO).as_posix()}:{r.line_no}  "
                  f"col={r.column_name} src='{src[:50]}' -> {label} (T{ptier or '?'})")
        return 0

    def _audit_one(r) -> AuditResult:
        parent_wiki_p, parent_row, _src_text = find_parent(r)
        parent_desc = parent_row.description if parent_row else ''
        parent_tier = (parent_row.tier_tags[-1].tier
                       if (parent_row and parent_row.tier_tags) else '')
        parent_wiki_label = (parent_wiki_p.relative_to(REPO).as_posix()
                             if parent_wiki_p else '')
        parent_body = (gather_wiki_context(parent_wiki_p, r.column_name)
                       if parent_wiki_p else '')
        this_body = gather_wiki_context(r.wiki_path, r.column_name)
        cur_tier = r.tier_tags[-1].tier if r.tier_tags else ''
        try:
            j, info = _run_judge(
                column=r.column_name,
                parent_wiki=parent_wiki_label,
                parent_tier=parent_tier,
                parent_desc=parent_desc,
                parent_body=parent_body,
                this_wiki=r.wiki_path.relative_to(REPO).as_posix(),
                claim_desc=r.description,
                this_body=this_body,
                cache_dir=cache_dir,
                model=args.model,
                timeout_s=args.timeout,
            )
        except Exception as e:
            j, info = None, f'exception:{e}'
        base = dict(
            column_name=r.column_name,
            wiki_path=r.wiki_path.relative_to(REPO).as_posix(),
            line_no=r.line_no,
            tier_format=r.tier_format,
            current_tier=cur_tier,
            current_desc=r.description,
            parent_wiki=parent_wiki_label,
            parent_tier=parent_tier,
            parent_desc=parent_desc,
        )
        if j is None:
            return AuditResult(
                **base,
                verdict='ERROR',
                severity='',
                reason=info[:300],
                proposed_fix='',
                body_contradiction='',
                judge_status=f'error:{info[:80]}',
            )
        key = _cache_key(
            f'colaudit|{parent_wiki_label}|{r.wiki_path.relative_to(REPO).as_posix()}',
            r.column_name,
            f'{parent_desc}|||{parent_body}',
            f'{r.description}|||{this_body}',
        )
        ext_p = _cache_path(cache_dir, key + '.ext')
        bc = ''
        if ext_p.exists():
            try:
                bc = json.loads(ext_p.read_text(encoding='utf-8')).get(
                    'body_contradiction') or ''
            except Exception:
                bc = ''
        return AuditResult(
            **base,
            verdict=j.verdict,
            severity=j.severity or '',
            reason=j.reason,
            proposed_fix=j.proposed_fix or '',
            body_contradiction=bc or '',
            judge_status='cached' if j.cached else 'fresh',
        )

    workers = max(1, args.workers)
    print(f'[2/3] auditing each row with LLM judge '
          f'({workers}-way parallel) …', flush=True)
    results: list[AuditResult | None] = [None] * len(rows)
    t0 = time.time()
    verdicts: Counter = Counter()
    lock = threading.Lock()
    done = 0
    with ThreadPoolExecutor(max_workers=workers) as ex:
        fut_to_idx = {ex.submit(_audit_one, r): i for i, r in enumerate(rows)}
        for fut in as_completed(fut_to_idx):
            idx = fut_to_idx[fut]
            try:
                res = fut.result()
            except Exception as e:
                res = AuditResult(
                    column_name=rows[idx].column_name,
                    wiki_path=rows[idx].wiki_path.relative_to(REPO).as_posix(),
                    line_no=rows[idx].line_no,
                    tier_format=rows[idx].tier_format,
                    current_tier='',
                    current_desc=rows[idx].description,
                    parent_wiki='',
                    parent_tier='',
                    parent_desc='',
                    verdict='ERROR',
                    severity='',
                    reason=f'exception in worker: {e}'[:300],
                    proposed_fix='',
                    body_contradiction='',
                    judge_status='error',
                )
            with lock:
                results[idx] = res
                verdicts[res.verdict] += 1
                done += 1
                if done % 5 == 0 or done == len(rows):
                    elapsed = time.time() - t0
                    rate = done / elapsed if elapsed else 0
                    print(f'  {done}/{len(rows)}  elapsed={elapsed:.0f}s  '
                          f'rate={rate:.1f}/s  '
                          f'PASS={verdicts["PASS"]} FAIL={verdicts["FAIL"]} '
                          f'ERROR={verdicts["ERROR"]}', flush=True)
    # Drop the None placeholders (shouldn't happen but be safe)
    results = [r for r in results if r is not None]

    # ---- Phase 3: write outputs ----
    print('[3/3] writing outputs …')
    csv_path = out_dir / 'report.csv'
    with csv_path.open('w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(asdict(results[0]).keys()) if results else [])
        if results:
            w.writeheader()
            for r in results:
                w.writerow(asdict(r))
    print(f'      {csv_path.relative_to(REPO)}')

    md_path = out_dir / 'report.md'
    with md_path.open('w', encoding='utf-8') as f:
        f.write(f'# LLM column audit\n\n')
        f.write(f'Columns: {", ".join(sorted(columns))}\n\n')
        f.write(f'Total rows audited: {len(results)}\n')
        for v, n in verdicts.most_common():
            f.write(f'- **{v}**: {n}\n')
        f.write('\n---\n\n')
        for r in results:
            f.write(f'## {r.column_name}  —  {r.wiki_path}:{r.line_no}\n\n')
            f.write(f'- verdict: **{r.verdict}** ({r.severity})\n')
            f.write(f'- reason: {r.reason}\n')
            if r.body_contradiction:
                f.write(f'- body_contradiction: {r.body_contradiction}\n')
            f.write(f'- parent: `{r.parent_wiki}` (T{r.parent_tier})\n')
            f.write(f'- current desc: {r.current_desc[:400]}\n')
            if r.parent_desc:
                f.write(f'- parent desc:  {r.parent_desc[:400]}\n')
            if r.proposed_fix:
                f.write(f'- **proposed**: {r.proposed_fix[:400]}\n')
            f.write('\n')
    print(f'      {md_path.relative_to(REPO)}')

    print()
    print(f'Done in {time.time() - t0:.0f}s')
    for v, n in verdicts.most_common():
        print(f'  {v}: {n}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
