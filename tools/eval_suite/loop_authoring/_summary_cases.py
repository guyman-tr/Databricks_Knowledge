"""Print a summary of all DDR eval cases."""
import yaml, glob
from collections import Counter

files = sorted(glob.glob('tools/eval_suite/cases/ddr/*.yaml'))
print(f'{len(files)} eval cases:\n')
print(f'  {"id":<48} {"sheet":<48} {"GT value":>20} {"diff %":>9}')
print('-' * 134)

tag_counter = Counter()
for f in files:
    d = yaml.safe_load(open(f, encoding='utf-8'))
    sheet = d.get('provenance', {}).get('sheet', '')[:46]
    gt = d.get('ground_truth', {}).get('value', 0)
    par = d.get('parity', {})
    pct = par.get('diff_pct', 0.0)
    tags = d.get('tags', [])
    for t in tags:
        tag_counter[t] += 1
    print(f'  {d["id"]:<48} {sheet:<48} {float(gt):>20,.4f} {float(pct):>+9.4f}%')

print('\nTag distribution:')
for tag, n in tag_counter.most_common():
    print(f'  {tag:<25} {n}')
