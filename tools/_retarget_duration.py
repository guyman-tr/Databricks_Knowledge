import json
from pathlib import Path
REPO = Path(__file__).resolve().parents[1]
allt = json.loads((REPO / "tools/lakebridge/bare_43_targets.json").read_text(encoding="utf-8"))
sub = [t for t in allt if t["uc_target"].endswith("dictionary_duration")]
out = REPO / "tools/lakebridge/_duration_retarget.json"
out.write_text(json.dumps(sub, indent=2), encoding="utf-8")
print(f"Wrote {out.relative_to(REPO).as_posix()} ({len(sub)})")
