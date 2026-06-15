"""Find the staking backdating logic in Synapse SP and check what's in UC SP."""
from __future__ import annotations
import os, sys, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synapse

# Pull Synapse SP body
r = synapse.run("""
SELECT m.definition
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'SP_DDR_Fact_Revenue_Generating_Actions'
""")
syn = r.rows[0][0]

print("=" * 70)
print("SYNAPSE SP — search for backdating / 2nd-pass / comp / airdrop / staking-month logic")
print("=" * 70)

# search for keywords
keywords = [
    r'backdate',
    r'staking',
    r'StakingMonth',
    r'AirDrop',
    r'Compensation',
    r'NotEligible',
    r'IsEligible',
    r'Etoro_Amount',
    r'USD_Compensation',
    r'comp',
    r'previous',
    r'first.run',
    r'second.pass',
    r'reduce',
    r'subtract',
    r'#staking',
]

# Find every line that mentions any of the staking-related keywords (case-insensitive)
syn_lines = syn.splitlines()
hits = set()
for i, ln in enumerate(syn_lines):
    for kw in keywords:
        if re.search(kw, ln, re.IGNORECASE):
            hits.add(i)
            break

# Print windows around hit clusters
print(f"  {len(hits)} matching lines. Printing in windowed clusters...")
sorted_hits = sorted(hits)
clusters = []
cur = []
for h in sorted_hits:
    if cur and h - cur[-1] > 8:
        clusters.append(cur)
        cur = []
    cur.append(h)
if cur:
    clusters.append(cur)

for cluster in clusters:
    start = max(0, cluster[0] - 2)
    end = min(len(syn_lines), cluster[-1] + 3)
    print(f"\n  --- L{start+1}..L{end} ---")
    for i in range(start, end):
        marker = ">>>" if i in hits else "   "
        print(f"  {marker} L{i+1:4d}: {syn_lines[i].rstrip()}")
