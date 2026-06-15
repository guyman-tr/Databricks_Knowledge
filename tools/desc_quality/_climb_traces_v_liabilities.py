"""
Phase C inspection script: print climb traces for all trivial rows in V_Liabilities.
This is exit-deliverable for Phase C.
"""
from __future__ import annotations

import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.desc_quality.classify import Verdict, classify  # noqa: E402
from tools.desc_quality.upstream_climber import climb_upstream, format_terminal_cell  # noqa: E402
from tools.desc_quality.wiki_parse import parse_wiki  # noqa: E402


def main(argv: list[str]) -> int:
    target = argv[1] if len(argv) > 1 else "knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md"
    wiki = (_REPO_ROOT / target).resolve()
    tbl = parse_wiki(wiki)
    obj_name = wiki.stem

    trivial_rows = [r for r in tbl.rows if classify(r.semantic_cell)[0] == Verdict.TRIVIAL]
    print(f"Wiki: {target}")
    print(f"Object: {obj_name}")
    print(f"Trivial rows: {len(trivial_rows)}")
    print()

    found_count = 0
    exhausted_count = 0
    reason_counter: dict[str, int] = {}

    for r in trivial_rows:
        res = climb_upstream(obj_name, r.column)
        status = "FOUND" if res.terminal_text else f"EXHAUSTED ({res.exhausted_reason})"
        if res.terminal_text:
            found_count += 1
        else:
            exhausted_count += 1
            reason_counter[res.exhausted_reason or "?"] = (
                reason_counter.get(res.exhausted_reason or "?", 0) + 1
            )
        print(f"--- #{r.idx} {r.column} ({status}, {len(res.hops)} hops) ---")
        print(f"  was: {r.semantic_cell}")
        for h in res.hops:
            cell_preview = (h.semantic_cell or "").replace("\n", " ")
            if len(cell_preview) > 140:
                cell_preview = cell_preview[:137] + "..."
            note = f"  [{h.note}]" if h.note else ""
            print(f"    -> {h.object_name}.{h.column_name}  {h.verdict}{note}")
            if cell_preview:
                print(f"       {cell_preview}")
        rendered = format_terminal_cell(res)
        if len(rendered) > 220:
            rendered = rendered[:217] + "..."
        print(f"  new: {rendered}")
        print()

    print("=" * 70)
    print(f"Summary: {found_count} FOUND / {exhausted_count} EXHAUSTED  ({len(trivial_rows)} total)")
    if reason_counter:
        print("Exhausted reasons:")
        for k, v in sorted(reason_counter.items(), key=lambda x: -x[1]):
            print(f"  {v:>4}  {k}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
