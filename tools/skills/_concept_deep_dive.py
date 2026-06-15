"""
For a list of concept seeds (substrings), produce a deep-dive analysis from
the cached queries.json:
  - Tables touched (with query count + unique users)
  - Users querying the concept
  - Genie spaces touching it
  - Vocabulary (column tokens used)
  - Current skill ownership (which skill .md files mention each table)

Usage:
  python tools/skills/_concept_deep_dive.py audits/_usage_trigger_xref_<ts>/queries.json crm mixpanel ftd negative_market
"""
from __future__ import annotations
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "knowledge" / "skills"

TABLE_FQN_RE = re.compile(r"\bmain\.([a-z0-9_]+)\.([a-z0-9_]+)\b", re.IGNORECASE)
TOKEN_RE = re.compile(r"\b[a-zA-Z_][a-zA-Z_0-9]{3,}\b")


def index_skills() -> dict[str, list[str]]:
    """Return {table_fqn: [skill_id, ...]} from all skill frontmatters."""
    idx: dict[str, list[str]] = defaultdict(list)
    try:
        import yaml
    except ImportError:
        return idx
    for p in SKILLS.rglob("*.md"):
        if p.name.startswith("_"):
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
        if not m:
            continue
        try:
            fm = yaml.safe_load(m.group(1)) or {}
        except Exception:
            continue
        sid = str(fm.get("id", ""))
        for t in fm.get("required_tables") or []:
            idx[str(t).lower()].append(sid)
    return idx


def index_genie_spaces() -> dict[str, str]:
    """{space_id: title}"""
    p = SKILLS / "_genie_spaces_index.json"
    if not p.exists():
        return {}
    out = {}
    for sp in json.loads(p.read_text(encoding="utf-8")):
        out[sp.get("space_id", "")] = sp.get("title") or "(anonymous)"
    return out


def analyze_concept(rows: list[dict], concept: str, skill_idx: dict, genie_titles: dict):
    c = concept.lower()
    matched_tables: Counter = Counter()
    matched_table_users: dict[str, set[str]] = defaultdict(set)
    matched_users: Counter = Counter()
    matched_spaces: Counter = Counter()
    matched_tokens: Counter = Counter()
    matched_table_columns: dict[str, Counter] = defaultdict(Counter)

    for r in rows:
        sql = (r.get("statement_text") or "")
        if not sql:
            continue
        sql_lc = sql.lower()
        # Match any FQN whose name contains the concept, OR any SQL where the
        # concept appears as an identifier substring
        sql_clean = sql.replace("`", "")
        tables_in_sql = {f"main.{m.group(1).lower()}.{m.group(2).lower()}" for m in TABLE_FQN_RE.finditer(sql_clean)}
        matching_tables = {t for t in tables_in_sql if c in t}
        concept_appears_in_sql = c in sql_lc

        if not matching_tables and not concept_appears_in_sql:
            continue

        user = (r.get("executed_by") or "").lower()
        space = r.get("genie_space_id") or ""

        # Attribute to ALL tables in the SQL (because user is "doing the concept")
        for t in matching_tables or tables_in_sql:
            matched_tables[t] += 1
            if user:
                matched_table_users[t].add(user)
        if user:
            matched_users[user] += 1
        if space:
            matched_spaces[space] += 1

        # Column tokens around the concept
        for m in TOKEN_RE.finditer(sql_clean):
            tok = m.group(0).lower()
            if c in tok and tok != c and len(tok) >= len(c):
                matched_tokens[tok] += 1

    if not matched_tables and not matched_users:
        return None

    out_lines = [f"\n{'='*78}", f"CONCEPT: {concept}", f"{'='*78}"]
    out_lines.append(f"  Distinct queries:  {sum(matched_tables.values())}")
    out_lines.append(f"  Distinct users:    {len(matched_users)}")
    out_lines.append(f"  Distinct spaces:   {len(matched_spaces)}")
    out_lines.append(f"  Distinct tables:   {len(matched_tables)}")
    out_lines.append(f"  Distinct tokens:   {len(matched_tokens)}")

    out_lines.append("\n  TOP TABLES (concept-matching FQNs, with current skill ownership):")
    out_lines.append(f"    {'Queries':>7}  {'Users':>5}  {'Skill':32}  Table")
    out_lines.append(f"    {'-'*7}  {'-'*5}  {'-'*32}  {'-'*60}")
    concept_tables = [t for t in matched_tables if c in t]
    concept_tables.sort(key=lambda t: -matched_tables[t])
    for t in concept_tables[:15]:
        owners = skill_idx.get(t, [])
        owner_str = ", ".join(owners[:2]) if owners else "** NO SKILL OWNER **"
        qc = matched_tables[t]
        usr = len(matched_table_users[t])
        out_lines.append(f"    {qc:7d}  {usr:5d}  {owner_str[:32]:32}  {t}")
    if len(concept_tables) > 15:
        out_lines.append(f"    ... + {len(concept_tables) - 15} more concept-tables")

    out_lines.append("\n  TOP GENIE SPACES touching the concept:")
    for sid, n in matched_spaces.most_common(8):
        title = genie_titles.get(sid, "(unknown)")
        out_lines.append(f"    {n:5d}  {sid}  {title}")

    out_lines.append("\n  CONCEPT VOCABULARY (column tokens containing the concept, top 25):")
    cols = ", ".join(f"{t}({c})" for t, c in matched_tokens.most_common(25))
    out_lines.append(f"    {cols}")

    # Coverage: are these tables owned by ANY skill?
    owned = sum(1 for t in concept_tables if skill_idx.get(t))
    out_lines.append(f"\n  OWNERSHIP COVERAGE: {owned} / {len(concept_tables)} concept-matching tables documented in ANY skill")
    return "\n".join(out_lines)


def main():
    if len(sys.argv) < 3:
        print("usage: _concept_deep_dive.py <queries.json> <concept1> [concept2 ...]", file=sys.stderr)
        sys.exit(2)
    rows = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    skill_idx = index_skills()
    genie_titles = index_genie_spaces()
    print(f"# Deep-dive analysis from {sys.argv[1]}")
    print(f"# Skills with required_tables: {len(skill_idx)} table FQNs indexed")
    print(f"# Total ad-hoc queries:        {len(rows)}")
    for concept in sys.argv[2:]:
        result = analyze_concept(rows, concept, skill_idx, genie_titles)
        if result:
            print(result)
        else:
            print(f"\n=== {concept}: no matches ===")


if __name__ == "__main__":
    main()
