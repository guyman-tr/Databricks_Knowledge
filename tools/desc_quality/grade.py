"""
Grade every §4 row in every Synapse-mirror wiki against the description-quality goal.

Usage:
    python tools/desc_quality/grade.py                                          # full corpus
    python tools/desc_quality/grade.py --wiki knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md
    python tools/desc_quality/grade.py --glob "knowledge/synapse/Wiki/DWH_dbo/**/*.md"
    python tools/desc_quality/grade.py --out audits/_desc_quality_<name>/

Outputs:
    {out}/report.csv  - one row per (wiki, column) with verdict
    {out}/wikis.csv   - one row per wiki with aggregate counts and pct_passing
    {out}/report.md   - top-N worst offenders by trivial count
"""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

# Add the repo's tools dir to sys.path so we can import as a package
_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.desc_quality.classify import Verdict, classify  # noqa: E402
from tools.desc_quality.wiki_parse import parse_wiki  # noqa: E402


WIKI_GLOB_DEFAULT = "knowledge/synapse/Wiki/**/*.md"


def _resolve_wikis(args: argparse.Namespace) -> list[Path]:
    if args.wiki:
        return [Path(p).resolve() for p in args.wiki]
    pattern = args.glob or WIKI_GLOB_DEFAULT
    return sorted(_REPO_ROOT.glob(pattern))


def main() -> int:
    ap = argparse.ArgumentParser(description="Grade wiki §4 rows for description quality")
    ap.add_argument("--wiki", nargs="*", help="Specific wiki path(s) to grade")
    ap.add_argument("--glob", help=f"Glob (default: {WIKI_GLOB_DEFAULT})")
    ap.add_argument("--out", default="audits/_desc_quality", help="Output directory")
    ap.add_argument("--top", type=int, default=30, help="Top-N worst offenders in report.md")
    args = ap.parse_args()

    out_dir = (_REPO_ROOT / args.out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    wikis = _resolve_wikis(args)
    if not wikis:
        print(f"No wikis matched pattern.", file=sys.stderr)
        return 2

    rows_csv_path = out_dir / "report.csv"
    wikis_csv_path = out_dir / "wikis.csv"
    md_path = out_dir / "report.md"

    per_wiki_stats: list[dict] = []
    total_trivial = total_trans = total_sem = total_skipped = 0

    with rows_csv_path.open("w", newline="", encoding="utf-8") as fcsv:
        w = csv.writer(fcsv)
        w.writerow(
            [
                "wiki_path",
                "section_4_title",
                "semantic_header",
                "idx",
                "column",
                "source",
                "semantic_cell",
                "verdict",
                "signal",
            ]
        )
        for wp in wikis:
            try:
                tbl = parse_wiki(wp)
            except Exception as exc:  # noqa: BLE001
                per_wiki_stats.append(
                    {
                        "wiki_path": str(wp.relative_to(_REPO_ROOT)).replace("\\", "/"),
                        "total": 0,
                        "n_trans": 0,
                        "n_sem": 0,
                        "n_trivial": 0,
                        "pct_passing": 0.0,
                        "has_source_column": False,
                        "skipped_reason": f"parse_error: {exc}",
                        "semantic_header": "",
                        "section_4_title": "",
                    }
                )
                total_skipped += 1
                continue
            if tbl.skipped_reason and not tbl.rows:
                per_wiki_stats.append(
                    {
                        "wiki_path": str(wp.relative_to(_REPO_ROOT)).replace("\\", "/"),
                        "total": 0,
                        "n_trans": 0,
                        "n_sem": 0,
                        "n_trivial": 0,
                        "pct_passing": 0.0,
                        "has_source_column": tbl.has_source_column,
                        "skipped_reason": tbl.skipped_reason,
                        "semantic_header": tbl.semantic_header_used or "",
                        "section_4_title": tbl.section_4_title,
                    }
                )
                total_skipped += 1
                continue

            n_trans = n_sem = n_trivial = 0
            for r in tbl.rows:
                verdict, signal = classify(r.semantic_cell)
                if verdict == Verdict.TRIVIAL:
                    n_trivial += 1
                elif verdict == Verdict.HAS_TRANSFORMATION:
                    n_trans += 1
                elif verdict == Verdict.HAS_SEMANTIC:
                    n_sem += 1
                w.writerow(
                    [
                        str(wp.relative_to(_REPO_ROOT)).replace("\\", "/"),
                        tbl.section_4_title,
                        tbl.semantic_header_used or "",
                        r.idx,
                        r.column,
                        r.source,
                        r.semantic_cell,
                        verdict.value,
                        signal or "",
                    ]
                )
            total = n_trans + n_sem + n_trivial
            pct = (n_trans + n_sem) / total * 100.0 if total else 0.0
            per_wiki_stats.append(
                {
                    "wiki_path": str(wp.relative_to(_REPO_ROOT)).replace("\\", "/"),
                    "total": total,
                    "n_trans": n_trans,
                    "n_sem": n_sem,
                    "n_trivial": n_trivial,
                    "pct_passing": round(pct, 1),
                    "has_source_column": tbl.has_source_column,
                    "skipped_reason": "",
                    "semantic_header": tbl.semantic_header_used or "",
                    "section_4_title": tbl.section_4_title,
                }
            )
            total_trans += n_trans
            total_sem += n_sem
            total_trivial += n_trivial

    with wikis_csv_path.open("w", newline="", encoding="utf-8") as fcsv:
        w = csv.writer(fcsv)
        w.writerow(
            [
                "wiki_path",
                "section_4_title",
                "semantic_header",
                "has_source_column",
                "total",
                "n_transformation",
                "n_semantic",
                "n_trivial",
                "pct_passing",
                "skipped_reason",
            ]
        )
        for s in per_wiki_stats:
            w.writerow(
                [
                    s["wiki_path"],
                    s["section_4_title"],
                    s["semantic_header"],
                    s["has_source_column"],
                    s["total"],
                    s["n_trans"],
                    s["n_sem"],
                    s["n_trivial"],
                    s["pct_passing"],
                    s["skipped_reason"],
                ]
            )

    # Markdown summary
    graded = [s for s in per_wiki_stats if s["total"] > 0]
    skipped = [s for s in per_wiki_stats if s["total"] == 0]
    worst = sorted(graded, key=lambda x: (-x["n_trivial"], -x["total"]))[: args.top]

    total_rows_graded = total_trans + total_sem + total_trivial
    pct_overall = (
        (total_trans + total_sem) / total_rows_graded * 100.0 if total_rows_graded else 0.0
    )

    with md_path.open("w", encoding="utf-8") as fmd:
        fmd.write("# Description Quality — Grader Report\n\n")
        fmd.write(f"- Wikis examined: **{len(per_wiki_stats)}**\n")
        fmd.write(f"- Wikis graded: **{len(graded)}**\n")
        fmd.write(f"- Wikis skipped: **{len(skipped)}**\n")
        fmd.write(f"- Total rows graded: **{total_rows_graded}**\n")
        fmd.write(f"  - HAS_TRANSFORMATION: **{total_trans}**\n")
        fmd.write(f"  - HAS_SEMANTIC: **{total_sem}**\n")
        fmd.write(f"  - TRIVIAL: **{total_trivial}**\n")
        fmd.write(f"- Overall pass rate: **{pct_overall:.1f}%**\n\n")

        fmd.write(f"## Worst {args.top} offenders (most TRIVIAL rows)\n\n")
        fmd.write("| Wiki | Total | Trans | Sem | Trivial | Pass % | HasSource | Header |\n")
        fmd.write("|------|------:|------:|----:|--------:|-------:|:---------:|:-------|\n")
        for s in worst:
            fmd.write(
                f"| `{s['wiki_path']}` | {s['total']} | {s['n_trans']} | {s['n_sem']} | "
                f"**{s['n_trivial']}** | {s['pct_passing']:.1f}% | "
                f"{'Y' if s['has_source_column'] else 'N'} | {s['semantic_header']} |\n"
            )

        if skipped:
            fmd.write(f"\n## Skipped wikis ({len(skipped)})\n\n")
            fmd.write("| Wiki | Reason |\n|------|--------|\n")
            for s in sorted(skipped, key=lambda x: x["wiki_path"]):
                fmd.write(f"| `{s['wiki_path']}` | {s['skipped_reason']} |\n")

    print(f"Graded {len(graded)} wikis, skipped {len(skipped)}.")
    print(f"  Rows: {total_trans} transformation / {total_sem} semantic / {total_trivial} trivial")
    print(f"  Overall pass rate: {pct_overall:.1f}%")
    print(f"  Output: {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
