import os, re, sys
roots = [
    'knowledge/skills/domain-revenue-and-fees',
    'knowledge/skills/domain-trading',
    'knowledge/skills/domain-customer-and-identity',
    'knowledge/skills/domain-payments',
    'knowledge/skills/domain-cross',
]
for r in roots:
    if not os.path.isdir(r):
        continue
    print(f'=== {r} ===')
    for f in sorted(os.listdir(r)):
        if not f.endswith('.md'):
            continue
        p = os.path.join(r, f)
        with open(p, encoding='utf-8') as fh:
            t = fh.read()
        ver = re.search(r'^version:\s*(\d+)', t, re.M)
        lines = t.count('\n') + 1
        lv = re.search(r'^last_validated_at:\s*"?([0-9-]+)', t, re.M)
        v = ver.group(1) if ver else '?'
        d = lv.group(1) if lv else '?'
        print(f'  {f:55s}  v{v:3s}  lines={lines:4d}  lv={d}')
