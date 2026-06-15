import csv, re
from collections import Counter

rows = [r for r in csv.DictReader(
    open('bulk_fix_deploy_report.csv', encoding='utf-8')
) if r['status'] == 'error']


def fp(e: str) -> str:
    e = e or ''
    m = re.search(r"near '([^']*)'", e)
    near = m.group(1) if m else '?'
    if "extra input" in e:
        return f"extra input near {near!r}"
    if "missing" in e:
        return f"missing X near {near!r}"
    if "end of input" in e:
        return "unexpected end of input"
    return f"other near {near!r}"


c = Counter(fp(r['error']) for r in rows)
for k, n in c.most_common():
    print(f'{n:3d}  {k}')
print(f'Total fail: {len(rows)}')

# Sample one example per top bucket.
print('\n--- examples ---')
seen: set[str] = set()
for r in rows:
    b = fp(r['error'])
    if b in seen:
        continue
    seen.add(b)
    print(f"\n[{b}]  {r['rel']}")
    print('  ' + (r['error'] or '')[:240])
