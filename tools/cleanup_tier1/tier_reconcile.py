"""tier_reconcile.py — mechanical, no-LLM, DAG-driven Tier reconciliation.

Goal: every wiki column that claims a Tier must claim a tier number no lower
(== no stronger) than its parent's claimed tier. If it does (a "promotion lie"),
emit a downgrade. We iterate until no more downgrades fire (parents may have
been downgraded themselves in the same pass).

This pass is fully mechanical:
  - reads only the wikis themselves (both inline-tag and tier-column dialects)
  - resolves parent references via simple text-pattern matching
  - never invokes an LLM

Output:
  knowledge/_tier_reconciliation_plan.csv — one row per downgrade to apply

Usage:
  python -m cleanup_tier1.tier_reconcile               # build plan
  python -m cleanup_tier1.tier_reconcile --apply       # build plan + apply
  python -m cleanup_tier1.tier_reconcile --report-only # also print summary
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'tools'))

from tier1_audit.parser import parse_wiki_columns, ColumnRow, TierTag  # noqa: E402

# --- Tier ordering -----------------------------------------------------------
# Lower number == stronger claim. So a child must have tier_num >= parent_num.
TIER_NUM = {"0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "N": 9, "U": 9}

# Wikis we treat as sources of column metadata.
WIKI_ROOTS = [
    REPO / 'knowledge' / 'synapse' / 'Wiki',
    REPO / 'knowledge' / 'UC_generated',
]

# Sub-paths we ignore (discovery artifacts, mirrors).
SKIP_PATH_FRAGMENTS = ("_discovery/upstream_wikis", "_discovery/column_lineage")


# --- Helpers -----------------------------------------------------------------
def _norm(s: str) -> str:
    return re.sub(r"[^A-Za-z0-9]", "", s).lower()


@dataclass
class WikiObject:
    """A parsed wiki indexed by every alias we may need to look it up by."""
    wiki_path: Path
    columns: dict[str, ColumnRow] = field(default_factory=dict)   # col-name → row
    aliases: set[str] = field(default_factory=set)                # normalised


def _aliases_for_path(p: Path) -> set[str]:
    """Derive every name a wiki file may be referenced by from source-text.
    Always includes the stem; UC-style names get aggressive
    prefix/suffix stripping plus progressive tail-of-underscore-split aliases
    so a synapse wiki `BI_DB_CIDFirstDates` matches a UC reference
    `gold_sql_..._bi_db_dbo_bi_db_cidfirstdates_masked`.
    """
    stem = p.stem
    aliases = {stem, stem.lower()}
    stripped = stem
    for prefix in (
        'gold_sql_dp_prod_we_', 'gold_sql_dp_prod_us_', 'gold_sql_dp_prod_eu_',
        'gold_sql_dp_prod_', 'gold_sql_', 'silver_sql_', 'bronze_sql_',
        'gold_', 'silver_', 'bronze_',
    ):
        if stripped.lower().startswith(prefix):
            stripped = stripped[len(prefix):]
            break
    for suffix in ('_masked', '_v', '_view'):
        if stripped.lower().endswith(suffix):
            stripped = stripped[: -len(suffix)]
            break
    aliases.add(stripped)
    # Progressive tail aliases: drop one underscore-segment at a time from the
    # FRONT (covers the common `<db>_<schema>_<obj>` nestings). To avoid
    # bridging unrelated wikis through a generic 1-word tail ("Status",
    # "Type", "Level", "Date"…) we only emit tails that either contain an
    # underscore themselves or are at least 10 chars long.
    parts = stripped.split('_')
    for i in range(1, min(len(parts), 5)):
        tail = '_'.join(parts[i:])
        if '_' in tail or len(tail) >= 10:
            aliases.add(tail)
    return {_norm(a) for a in aliases if a}


def _collect_wikis() -> list[Path]:
    out: list[Path] = []
    for root in WIKI_ROOTS:
        if not root.exists():
            continue
        for md in root.rglob('*.md'):
            rel = md.relative_to(REPO).as_posix()
            if md.name.endswith('.lineage.md'):
                continue
            if any(frag in rel for frag in SKIP_PATH_FRAGMENTS):
                continue
            if '.review-needed.' in md.name:
                continue
            out.append(md)
    return out


def build_index() -> tuple[dict[str, WikiObject], dict[str, set[str]]]:
    """Return:
       - objects: alias-norm → WikiObject
       - column_index: alias-norm → set of column names known on that object
    """
    objects: dict[str, WikiObject] = {}
    paths = _collect_wikis()
    for p in paths:
        try:
            rows = parse_wiki_columns(p)
        except Exception as e:  # parser bugs shouldn't kill the sweep
            print(f'  parser error on {p}: {e}', file=sys.stderr)
            continue
        if not rows:
            continue
        wobj = WikiObject(wiki_path=p, aliases=_aliases_for_path(p))
        for r in rows:
            # If a column appears twice (multiple tables), prefer the one with
            # a Tier claim. Otherwise keep first.
            existing = wobj.columns.get(r.column_name)
            if existing and not existing.tier_tags and r.tier_tags:
                wobj.columns[r.column_name] = r
            elif not existing:
                wobj.columns[r.column_name] = r
        for a in wobj.aliases:
            # collisions: keep the more "main" one (shorter path wins as tiebreaker)
            if a in objects:
                prev = objects[a]
                if len(str(p)) < len(str(prev.wiki_path)):
                    objects[a] = wobj
            else:
                objects[a] = wobj
    column_index = {a: set(o.columns.keys()) for a, o in objects.items()}
    return objects, column_index


# --- Source-text resolution --------------------------------------------------
_SRC_STRIP_PREFIXES = (
    'inherited from ', 'derived from ', 'inheriting from ',
    'via ', 'from ', 'see ',
)
_SRC_STRIP_SUFFIXES = (
    ' wiki', ' table', ' view', ' (table)', ' (view)', ' fn', ' function',
)


def _cleanup_cosmetic_dash(wiki_roots: Iterable[Path]) -> int:
    """Sweep wikis for the cosmetic `(Tier N — - text)` leak left by an
    earlier regex that half-matched `--`. Idempotent + safe."""
    pat = re.compile(r"(\(\s*Tier\s+[0-9NUu]\s*(?:--|[-–—])\s*)-+\s*")
    fixed_files = 0
    for root in wiki_roots:
        if not root.exists():
            continue
        for md in root.rglob('*.md'):
            if md.name.endswith('.lineage.md'):
                continue
            rel = md.relative_to(REPO).as_posix()
            if any(f in rel for f in SKIP_PATH_FRAGMENTS):
                continue
            try:
                txt = md.read_text(encoding='utf-8')
            except Exception:
                continue
            new = pat.sub(lambda m: m.group(1), txt)
            if new != txt:
                md.write_text(new, encoding='utf-8')
                fixed_files += 1
    return fixed_files


def _candidate_object_names(source_text: str) -> list[str]:
    """Return possible parent-object names extracted from a tier-tag source.

    Examples (input → output):
      'SP_Fact_SnapshotEquity'                          → []  (SP, no wiki)
      'via Fact_SnapshotEquity'                         → ['Fact_SnapshotEquity']
      'V_Liabilities via Fact_SnapshotEquity'           → ['V_Liabilities', 'Fact_SnapshotEquity']
      'Fact_SnapshotEquity.Credit'                      → ['Fact_SnapshotEquity']
      'inherited from main.bi_db.gold_sql_..._cidfirstdates_masked'
                                                        → ['gold_sql_..._cidfirstdates_masked',
                                                           'gold_sql_..._cidfirstdates',
                                                           'bi_db_cidfirstdates', ...]
      'Dictionary.CreditType'                           → ['CreditType', 'Dictionary']
    """
    s = (source_text or '').strip().strip('()')
    if not s:
        return []
    # Strip leading verbs/prepositions
    low = s.lower()
    for pfx in _SRC_STRIP_PREFIXES:
        if low.startswith(pfx):
            s = s[len(pfx):]
            low = s.lower()
            break
    # Strip trailing nouns
    for sfx in _SRC_STRIP_SUFFIXES:
        if low.endswith(sfx):
            s = s[: -len(sfx)]
            low = s.lower()
            break
    s = s.strip()
    if not s:
        return []
    # Reject SP/UDF references at any segment boundary — they don't have a
    # column-grid wiki we can validate against. (`SP_M_EmployeesProgram`,
    # `BI_DB_dbo.SP_DDR_Customer_Periodic_Status`, `fn_FullDate`, …)
    if re.search(r'(?:^|[._\s])sp_', s, re.I):
        return []
    if re.search(r'(?:^|[._\s])fn_', s, re.I):
        return []

    # If "X via Y" or "X, via Y" — keep both, X first (closer hop)
    candidates: list[str] = []
    via_parts = re.split(r'\s+via\s+|\s*,\s*via\s+', s, flags=re.I)
    via_parts = [p.strip() for p in via_parts if p.strip()]

    for part in via_parts:
        # Drop column refs: "Foo.Bar" → "Foo" but keep both
        if '.' in part:
            segs = [seg.strip() for seg in part.split('.') if seg.strip()]
            # UC-style "main.bi_db.<obj>" → last segment is the object
            if len(segs) >= 3 and segs[0].lower() == 'main':
                candidates.append(segs[-1])
            else:
                candidates.append(segs[0])  # "Table.Column" → "Table"
                candidates.append(segs[-1])  # also try last segment
        else:
            candidates.append(part)

    # Deduplicate preserving order
    seen = set()
    out: list[str] = []
    for c in candidates:
        c = c.strip().strip('`"\'')
        if not c or c.lower() in seen:
            continue
        seen.add(c.lower())
        out.append(c)
    return out


def _resolve_parent(
    source_text: str,
    child_column: str,
    objects: dict[str, WikiObject],
) -> tuple[WikiObject | None, str | None]:
    """Pick a parent WikiObject + parent-column-name from a source_text string.
    Tries direct alias lookup, then `_masked`-stripped, then progressive tails
    of the underscore-split name (so `gold_sql_..._bi_db_cidfirstdates_masked`
    resolves to the synapse wiki `BI_DB_CIDFirstDates`)."""
    cands = _candidate_object_names(source_text)
    if not cands:
        return None, None
    for cand in cands:
        variants = {cand, re.sub(r'_masked$', '', cand, flags=re.I)}
        # progressive tails — drop leading underscore-segments. Same
        # uniqueness guard as `_aliases_for_path` to avoid generic 1-word
        # bridges. Walk the whole split (UC names can have 10+ segments).
        parts = re.sub(r'_masked$', '', cand, flags=re.I).split('_')
        for i in range(1, len(parts)):
            tail = '_'.join(parts[i:])
            if '_' in tail or len(tail) >= 10:
                variants.add(tail)
        for alias in variants:
            key = _norm(alias)
            if not key or key not in objects:
                continue
            obj = objects[key]
            pcol = child_column
            m = re.search(r'([A-Za-z0-9_]+)\s*\.\s*([A-Za-z0-9_]+)', source_text)
            if m and _norm(m.group(1)) == key:
                candidate_col = m.group(2)
                if candidate_col in obj.columns:
                    pcol = candidate_col
            if pcol not in obj.columns:
                if child_column in obj.columns:
                    pcol = child_column
                else:
                    continue
            return obj, pcol
    return None, None


# --- Reconciliation pass -----------------------------------------------------
@dataclass
class Downgrade:
    wiki_path: Path
    line_no: int
    column_name: str
    tag_index: int              # which tag_tags[i] entry to downgrade
    old_tier: str
    new_tier: str
    parent_wiki: str
    parent_tier: str
    source_text: str
    format: str                 # 'inline' or 'column'
    reason: str


def reconcile(objects: dict[str, WikiObject], verbose: bool = False) -> list[Downgrade]:
    """Iterate until no more downgrades fire."""
    plan: list[Downgrade] = []
    pass_no = 0
    # Snapshot of current tier per (alias, column). We mutate this between
    # passes (in-memory) so multi-hop propagation converges.
    while True:
        pass_no += 1
        fired = 0
        for wobj in objects.values():
            for col_name, row in wobj.columns.items():
                if not row.tier_tags:
                    continue
                for idx, tag in enumerate(row.tier_tags):
                    child_num = TIER_NUM.get(tag.tier, 9)
                    parent_obj, parent_col = _resolve_parent(
                        tag.source_text, col_name, objects
                    )
                    if parent_obj is None or parent_col is None:
                        continue
                    prow = parent_obj.columns.get(parent_col)
                    if not prow or not prow.tier_tags:
                        continue
                    # Parent's effective tier == lowest-number among its own tags
                    parent_num = min(TIER_NUM.get(t.tier, 9) for t in prow.tier_tags)
                    parent_tier_letter = min(
                        prow.tier_tags, key=lambda t: TIER_NUM.get(t.tier, 9)
                    ).tier
                    if child_num >= parent_num:
                        continue
                    # Promotion lie: child claims stronger than parent
                    new_letter = parent_tier_letter
                    # In-memory mutate so subsequent passes see the change
                    row.tier_tags[idx] = TierTag(tier=new_letter, source_text=tag.source_text)
                    plan.append(Downgrade(
                        wiki_path=row.wiki_path,
                        line_no=row.line_no,
                        column_name=col_name,
                        tag_index=idx,
                        old_tier=tag.tier,
                        new_tier=new_letter,
                        parent_wiki=str(parent_obj.wiki_path.relative_to(REPO)).replace('\\', '/'),
                        parent_tier=parent_tier_letter,
                        source_text=tag.source_text,
                        format=row.tier_format,
                        reason=f'parent {parent_obj.wiki_path.stem}.{parent_col} is T{parent_tier_letter}',
                    ))
                    fired += 1
        if verbose:
            print(f'  pass {pass_no}: {fired} downgrades')
        if fired == 0:
            break
        if pass_no > 12:
            print('  ! convergence cap hit (12 passes) — bailing', file=sys.stderr)
            break
    return plan


# --- Apply -------------------------------------------------------------------
def apply_plan(plan: list[Downgrade], dry_run: bool = True) -> dict[str, int]:
    """Rewrite each line in each wiki:
       - inline-tag: change `(Tier <old> ...)` to `(Tier <new> ...)`
       - column-tier: change the `| T<old> |` cell to `| T<new> |`
    """
    # Group by wiki+line: a single line may carry multiple tag downgrades
    grouped: dict[tuple[str, int], list[Downgrade]] = defaultdict(list)
    for d in plan:
        rel = str(d.wiki_path.relative_to(REPO)).replace('\\', '/')
        grouped[(rel, d.line_no)].append(d)

    stats = {'lines_changed': 0, 'wikis_changed': 0, 'tags_changed': 0, 'skipped': 0}
    by_wiki: dict[str, list[tuple[int, list[Downgrade]]]] = defaultdict(list)
    for (rel, ln), ds in grouped.items():
        by_wiki[rel].append((ln, ds))

    for rel, lines_changes in by_wiki.items():
        path = REPO / rel
        try:
            text_lines = path.read_text(encoding='utf-8').splitlines(keepends=True)
        except Exception as e:
            print(f'  ! cannot read {rel}: {e}', file=sys.stderr)
            stats['skipped'] += len(lines_changes)
            continue

        touched = False
        for line_no, ds in lines_changes:
            if line_no < 1 or line_no > len(text_lines):
                stats['skipped'] += len(ds)
                continue
            orig = text_lines[line_no - 1]
            new_line = orig
            for d in ds:
                if d.format == 'inline':
                    new_line = _rewrite_inline_tag(new_line, d)
                else:
                    new_line = _rewrite_tier_cell(new_line, d)
            if new_line != orig:
                text_lines[line_no - 1] = new_line
                touched = True
                stats['lines_changed'] += 1
                stats['tags_changed'] += len(ds)
        if touched:
            stats['wikis_changed'] += 1
            if not dry_run:
                path.write_text(''.join(text_lines), encoding='utf-8')

    return stats


def _rewrite_inline_tag(line: str, d: Downgrade) -> str:
    """Replace the first matching `(Tier <old> [-–—] <source>)` in line.
    Uses the source_text snippet to disambiguate when multiple tags exist."""
    pat = re.compile(
        r"\(\s*Tier\s+" + re.escape(d.old_tier) +
        r"\s*(?:[-–—]|--)\s*([^()]+?)\s*\)",
        re.IGNORECASE,
    )
    src_norm = _norm(d.source_text)

    def _sub(m: re.Match) -> str:
        if _norm(m.group(1)) != src_norm:
            return m.group(0)
        return f"(Tier {d.new_tier} — {m.group(1)})"

    return pat.sub(_sub, line, count=1)


def _rewrite_tier_cell(line: str, d: Downgrade) -> str:
    """Replace the last `| T<old> |` (cells are separated by pipes)."""
    # cell pattern: pipe, whitespace, T<old>, whitespace, pipe (or end)
    pat = re.compile(r'(\|\s*)T' + re.escape(d.old_tier) + r'(\s*\|)', re.IGNORECASE)
    return pat.sub(lambda m: m.group(1) + f"T{d.new_tier}" + m.group(2), line, count=1)


# --- Entry point -------------------------------------------------------------
def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true',
                    help='actually rewrite wikis (default: dry-run)')
    ap.add_argument('--out',
                    default='knowledge/_tier_reconciliation_plan.csv',
                    help='output CSV of every planned downgrade')
    ap.add_argument('--verbose', action='store_true')
    args = ap.parse_args(argv)

    print('[0/3] cosmetic cleanup (stripping `— -` leak from earlier passes)…')
    n_cleaned = _cleanup_cosmetic_dash(WIKI_ROOTS)
    print(f'    cleaned {n_cleaned} files')

    print('[1/3] building wiki index …')
    objects, _ = build_index()
    n_aliases = len(objects)
    n_wikis = len({id(o) for o in objects.values()})
    n_cols = sum(len(o.columns) for o in {id(o): o for o in objects.values()}.values())
    print(f'    indexed {n_wikis} wikis ({n_aliases} aliases), {n_cols} columns total')

    print('[2/3] reconciling tier claims …')
    plan = reconcile(objects, verbose=True)
    print(f'    {len(plan)} downgrades planned')

    out_path = REPO / args.out
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open('w', encoding='utf-8', newline='') as f:
        w = csv.writer(f)
        w.writerow([
            'wiki_path', 'line_no', 'column_name', 'format',
            'old_tier', 'new_tier', 'source_text', 'parent_wiki', 'parent_tier', 'reason',
        ])
        for d in plan:
            w.writerow([
                str(d.wiki_path.relative_to(REPO)).replace('\\', '/'),
                d.line_no, d.column_name, d.format,
                d.old_tier, d.new_tier, d.source_text,
                d.parent_wiki, d.parent_tier, d.reason,
            ])
    print(f'    plan written: {out_path.relative_to(REPO)}')

    print('[3/3] ' + ('applying …' if args.apply else 'dry-run …'))
    stats = apply_plan(plan, dry_run=not args.apply)
    print(f'    wikis touched: {stats["wikis_changed"]}, lines: {stats["lines_changed"]}, '
          f'tags rewritten: {stats["tags_changed"]}, skipped: {stats["skipped"]}')
    if not args.apply:
        print('    (dry-run — pass --apply to write changes)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
