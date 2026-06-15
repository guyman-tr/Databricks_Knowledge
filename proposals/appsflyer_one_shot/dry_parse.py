"""Parse all four ALTER files via deploy.parse_statements WITHOUT connecting to UC."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from deploy import ALTER_FILES, parse_statements, label_for

grand = 0
for f in ALTER_FILES:
    if not f.exists():
        print(f"MISSING {f}")
        continue
    raw = f.read_text(encoding="utf-8")
    stmts = parse_statements(raw)
    print(f"{f.name}: {len(stmts)} statements")
    grand += len(stmts)
    # First and last 3 statements for sanity
    for i, s in enumerate(stmts[:3]):
        print(f"  [{i+1:3d}] {label_for(s)} | {s.splitlines()[0][:90]}")
    if len(stmts) > 6:
        print(f"  ...")
        for i, s in enumerate(stmts[-3:]):
            print(f"  [{len(stmts)-2+i:3d}] {label_for(s)} | {s.splitlines()[0][:90]}")
    print()
print(f"GRAND TOTAL statements queued: {grand}")
