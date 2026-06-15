"""Ad-hoc inspector for a saved MCP skills_find_skills response payload.

Usage: python tools/_inspect_mcp_response.py <path-to-json>
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def main(path: str) -> None:
    data = json.loads(Path(path).read_text(encoding="utf-8"))

    print("=== TOP-LEVEL META ===")
    for k in (
        "top_score",
        "effective_top_score",
        "sub_skill_top_score",
        "match_quality_hint",
        "all_below_floor",
        "filtered_count",
        "advisory",
    ):
        print(f"  {k}: {data.get(k)!r}")

    print()
    print("=== SKILLS RETURNED (top to bottom) ===")
    for i, s in enumerate(data["skills"]):
        sid = s.get("id", "?")
        name = s.get("name", "?")
        score = s.get("score")
        eff = s.get("effective_score")
        body_len = len(s.get("body_markdown") or "")
        subs = s.get("sub_skills") or []
        matched = s.get("matched_sub_skills") or []
        print(f"  [{i}] {sid}")
        print(f"      name: {name}")
        print(f"      score: {score!r}  effective: {eff!r}")
        print(f"      body_markdown: {body_len} chars")
        print(f"      sub_skills: {len(subs)} total, {len(matched)} matched-by-query")
        for j, m in enumerate(matched):
            mid = m.get("id", "?")
            mscore = m.get("score")
            mlen = len(m.get("body_markdown") or "")
            print(f"        matched[{j}] = {mid}  score={mscore!r}  body={mlen} chars")
        for j, sub in enumerate(subs[:10]):
            sname = sub.get("id") or sub.get("name") or "?"
            sscore = sub.get("score", "-")
            slen = len(sub.get("body_markdown") or "")
            print(f"        sub[{j}] = {sname}  score={sscore}  body={slen} chars")
        print()


if __name__ == "__main__":
    main(sys.argv[1])
