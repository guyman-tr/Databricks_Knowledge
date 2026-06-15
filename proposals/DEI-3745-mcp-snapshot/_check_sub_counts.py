"""Print sub-skill attachment counts per hub using the DEI-3745 validator."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from validate_skills import validate_dir  # noqa: E402

if __name__ == "__main__":
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("skills")
    skills, errors, warnings = validate_dir(target)
    total = 0
    for s in sorted(skills, key=lambda x: getattr(x, "name", "") or ""):
        n = len(s.sub_skills)
        total += n
        name = getattr(s, "name", None) or "?"
        print(f"  {name:40s}  sub_skills={n}")
        for sub in s.sub_skills:
            desc = (sub.description or "")[:55].replace("\n", " ")
            print(f"      - {sub.id:50s}  {desc}")
    print(
        f"TOTAL: {len(skills)} hubs, {total} sub-skills, "
        f"{len(errors)} errors, {len(warnings)} warnings"
    )
