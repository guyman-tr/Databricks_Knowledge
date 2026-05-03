import re
from pathlib import Path

print(f"{'DB':<25} {'total':>5} {'gen':>5} {'dep':>5} {'fail':>5} {'stub':>5} updated")
for p in sorted(Path('knowledge/ProdSchemas').rglob('_deploy-index.md')):
    text = p.read_text(encoding='utf-8')
    db = p.parent.name
    def find(pat, t=text):
        m = re.search(pat, t, re.MULTILINE)
        return m.group(1) if m else '?'
    total = find(r'^total_deployable:\s*(\d+)')
    gen = find(r'^generated:\s*(\d+)')
    dep = find(r'^deployed:\s*(\d+)')
    fail = find(r'^failed:\s*(\d+)')
    stub = find(r'^stub_only:\s*(\d+)')
    upd = find(r'^last_updated:\s*"?([0-9-]+)')
    print(f"{db:<25} {total:>5} {gen:>5} {dep:>5} {fail:>5} {stub:>5} {upd}")
