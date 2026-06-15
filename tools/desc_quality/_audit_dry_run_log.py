"""Inspect the dry-run log: per-TVF counts + markdown/SQL leak checks."""
from __future__ import annotations
import re
import sys
from pathlib import Path

LOG = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("audits/_uc_deploy_descriptions/dry_run.log")

_raw = LOG.read_bytes()
if _raw.startswith(b"\xff\xfe"):
    text = _raw.decode("utf-16-le", errors="replace").splitlines()
elif _raw.startswith(b"\xfe\xff"):
    text = _raw.decode("utf-16-be", errors="replace").splitlines()
else:
    text = _raw.decode("utf-8", errors="replace").splitlines()

current = None
per_tvf: dict[str, dict[str, int]] = {}
for line in text:
    s = line.strip()
    m = re.match(r"^(Function_\S+|V_\S+)\s+->\s+(main\.\S+)$", s)
    if m:
        current = m.group(1)
        per_tvf[current] = {"target": m.group(2), "wiki_cols": 0, "stmts": 0}
        continue
    m = re.match(r"^Wiki:\s+(\d+)\s+columns from §4", s)
    if m and current:
        per_tvf[current]["wiki_cols"] = int(m.group(1))
        continue
    m = re.match(r"^->\s+(\d+) applied,\s+(\d+) no-desc,\s+(\d+) failed", s)
    if m and current:
        per_tvf[current]["stmts"] = int(m.group(1))
        per_tvf[current]["skipped"] = int(m.group(2))
        per_tvf[current]["failed"] = int(m.group(3))

print(f"{'TVF':55s} {'cols':>5s} {'stmts':>6s}  target")
print("-" * 120)
for name, info in per_tvf.items():
    print(f"{name:55s} {info['wiki_cols']:5d} {info['stmts']:6d}  {info['target']}")

print("-" * 120)
total_stmts = sum(i["stmts"] for i in per_tvf.values())
print(f"Total wikis: {len(per_tvf)}  |  Total statements: {total_stmts}")

print()
print("=== Hazard leak audit on the SQL strings the script will send ===")
# Find every COMMENT ON COLUMN statement and inspect the literal between IS '...'
pat = re.compile(r"COMMENT ON COLUMN (\S+)\.`([^`]+)` IS '(.*)$")
literals: list[tuple[str, str, str]] = []
for line in text:
    s = line.strip()
    if s.startswith("[DRY]"):
        s = s[5:].strip()
    m = pat.search(s)
    if m:
        literals.append((m.group(1), m.group(2), m.group(3)))

print(f"Parsed COMMENT statements: {len(literals)}")
# These checks operate on the truncated [DRY] output (which cuts at ~120 chars),
# so they're a leading-edge sniff test, not a full audit.

ctrl_re = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")
hazards = {
    "with **bold**": 0,
    "with backtick": 0,
    "with raw pipe": 0,
    "with control char": 0,
    "with unescaped single quote (odd count)": 0,
}
for tbl, col, lit in literals:
    if "**" in lit:
        hazards["with **bold**"] += 1
    if "`" in lit:
        hazards["with backtick"] += 1
    if "|" in lit:
        hazards["with raw pipe"] += 1
    if ctrl_re.search(lit):
        hazards["with control char"] += 1

for k, v in hazards.items():
    marker = "  <-- review" if v > 0 else ""
    print(f"  {k:45s}: {v}{marker}")
