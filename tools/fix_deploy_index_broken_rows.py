"""Fix _deploy-index.md rows where Failed status spilled across lines."""
from pathlib import Path

p = Path(__file__).resolve().parents[1] / "knowledge/synapse/Wiki/DWH_dbo/_deploy-index.md"
lines = p.read_text(encoding="utf-8").splitlines()
out = []
i = 0
while i < len(lines):
    line = lines[i]
    if "Failed (deploy Batch 2)" in line and not line.rstrip().endswith("|"):
        link = line.split("| Failed")[0].rstrip() + "|"
        out.append(
            f"{link} Failed (deploy Batch 2) — PARSE/UC error (fix .alter.sql or UC mapping) |"
        )
        i += 1
        while i < len(lines):
            nxt = lines[i].strip()
            if nxt.startswith("| [DWH_dbo.") and nxt.count("|") >= 2:
                break
            i += 1
        continue
    out.append(line)
    i += 1

text = "\n".join(out)
if p.read_text(encoding="utf-8").endswith("\n"):
    text += "\n"
p.write_text(text, encoding="utf-8")
print("Fixed", sum(1 for l in lines if "Failed (deploy Batch 2)" in l and not l.rstrip().endswith("|")), "broken rows")
