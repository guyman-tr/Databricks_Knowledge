"""Print skill ids + their trigger lists for a list_skills MCP response."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def main(path: str, needle: str | None = None) -> None:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    skills = data.get("skills") if isinstance(data, dict) else data
    print(f"TOTAL SKILLS: {len(skills)}")
    print()
    for s in sorted(skills, key=lambda x: x.get("id", "")):
        sid = s.get("id", "?")
        triggers = s.get("triggers", []) or []
        desc = (s.get("description", "") or "")[:120].replace("\n", " ")
        if needle is None or needle.lower() in sid.lower() or any(
            needle.lower() in t.lower() for t in triggers
        ) or needle.lower() in desc.lower():
            print(f"- {sid}")
            print(f"    desc: {desc}...")
            if triggers:
                print(f"    triggers ({len(triggers)}): {', '.join(triggers[:8])}{'...' if len(triggers) > 8 else ''}")
            print()


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
