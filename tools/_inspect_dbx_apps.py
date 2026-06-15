"""Inspect Databricks Apps list output for skills/mcp apps."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def main(path: str, needle: str = "skills") -> None:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    apps = data if isinstance(data, list) else data.get("apps", [])
    print(f"TOTAL APPS: {len(apps)}")
    print()
    matches = [
        a
        for a in apps
        if needle.lower() in (a.get("name", "") or "").lower()
        or "mcp" in (a.get("name", "") or "").lower()
    ]
    print(f"MATCHING ({len(matches)}):")
    for a in matches:
        print(f"--- {a.get('name')} ---")
        for k in ("name", "description", "url", "status", "compute_status"):
            v = a.get(k)
            if v:
                print(f"  {k}: {v}")
        print()


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "skills")
