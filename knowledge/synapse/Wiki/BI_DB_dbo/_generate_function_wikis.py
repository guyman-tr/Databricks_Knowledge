"""
Batch-generate wiki docs for BI_DB_dbo functions from SSDT source.
Traces each output column back to source tables with full expression
lineage, tier classification, and transformation logic.

Usage: python _generate_function_wikis.py [--dry-run]
"""
import os
import re
import sys
from datetime import datetime

SSDT_DIR = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "..", "..", "..",
    "DataPlatform", "SynapseSQLPool1", "sql_dp_prod_we",
    "BI_DB_dbo", "Functions"
))
WIKI_DIR = os.path.join(os.path.dirname(__file__), "Functions")
TIMESTAMP = datetime.now().strftime("%Y-%m-%d")

KNOWN_SCHEMAS = ('bi_db_dbo', 'dwh_dbo', 'dealing_dbo', 'emoney_dbo', 'dbo')
SQL_KEYWORDS = frozenset([
    'SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'ON', 'JOIN', 'LEFT', 'RIGHT',
    'INNER', 'OUTER', 'FULL', 'CROSS', 'AS', 'IS', 'NOT', 'NULL', 'CASE',
    'WHEN', 'THEN', 'ELSE', 'END', 'IN', 'BETWEEN', 'GROUP', 'BY', 'ORDER',
    'HAVING', 'DISTINCT', 'TOP', 'WITH', 'UNION', 'ALL', 'EXISTS', 'LIKE',
    'INTO', 'SET', 'VALUES', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'ALTER',
    'DROP', 'TABLE', 'VIEW', 'FUNCTION', 'RETURN', 'RETURNS', 'BEGIN',
    'DECLARE', 'IF', 'WHILE', 'OVER', 'PARTITION', 'ROW_NUMBER', 'RANK',
    'SUM', 'COUNT', 'MIN', 'MAX', 'AVG', 'ISNULL', 'COALESCE', 'CAST',
    'CONVERT', 'FORMAT', 'GETDATE', 'DATEADD', 'DATEDIFF', 'ABS',
])

# ── helpers ──────────────────────────────────────────────────────────

def strip_comments(sql):
    sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.DOTALL)
    sql = re.sub(r'--[^\n]*', '', sql)
    return sql


def extract_balanced(text, start):
    if start >= len(text) or text[start] != '(':
        return None, start
    depth = 0
    for i in range(start, len(text)):
        if text[i] == '(':
            depth += 1
        elif text[i] == ')':
            depth -= 1
            if depth == 0:
                return text[start + 1:i], i + 1
    return None, start


def strip_outer_parens(text):
    text = text.strip()
    while text.startswith('(') and text.endswith(')'):
        depth = 0
        for i, ch in enumerate(text):
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0 and i < len(text) - 1:
                    return text
        text = text[1:-1].strip()
    return text


# ── body / CTE extraction ───────────────────────────────────────────

def get_return_body(content):
    cleaned = strip_comments(content)
    m = re.search(r'\bRETURN\s*\(', cleaned, re.IGNORECASE)
    if m:
        body = cleaned[m.end():]
        depth = 1
        for i, ch in enumerate(body):
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    return body[:i]
        return body

    m = re.search(r'\bRETURN\s+(SELECT\b)', cleaned, re.IGNORECASE)
    if m:
        body = cleaned[m.start() + len('RETURN'):]
        go_pos = re.search(r'^\s*GO\s*$', body, re.MULTILINE | re.IGNORECASE)
        if go_pos:
            body = body[:go_pos.start()]
        return body.strip()
    return None


def parse_ctes(body):
    ctes = {}
    m = re.match(r'\s*WITH\b', body, re.IGNORECASE)
    if not m:
        return ctes
    pos = m.end()
    while pos < len(body):
        ws = re.match(r'\s*', body[pos:])
        if ws:
            pos += ws.end()
        name_m = re.match(r'["\[]?(\w+)["\]]?\s+AS\s*\(', body[pos:], re.IGNORECASE)
        if not name_m:
            break
        cte_name = name_m.group(1)
        paren_start = pos + name_m.end() - 1
        cte_body, end_pos = extract_balanced(body, paren_start)
        if cte_body is None:
            break
        ctes[cte_name.lower()] = cte_body
        pos = end_pos
        ws = re.match(r'\s*', body[pos:])
        if ws:
            pos += ws.end()
        if pos < len(body) and body[pos] == ',':
            pos += 1
        else:
            break
    return ctes


def find_final_select(body, ctes):
    if ctes:
        last_cte_end = 0
        for cte_name, cte_body in ctes.items():
            idx = body.lower().find(cte_body.lower()[:50])
            if idx >= 0:
                end = idx + len(cte_body) + 1
                if end > last_cte_end:
                    last_cte_end = end
        remainder = body[last_cte_end:]
    else:
        remainder = body
    select_match = re.search(r'\bSELECT\b', remainder, re.IGNORECASE)
    if not select_match:
        return None
    return remainder[select_match.start():]


# ── global alias -> table map ────────────────────────────────────────

def build_global_table_map(body):
    """Scan ALL FROM/JOIN clauses to build {alias: 'Schema.Table'} for real tables."""
    table_map = {}
    pattern = re.compile(
        r'(?:FROM|JOIN)\s+'
        r'(\[?\w+\]?\.\[?\w+\]?)'
        r'(?:\s*\([^)]*\))?'       # optional function params
        r'(?:\s+(?:AS\s+)?(\w+))?', # optional alias
        re.IGNORECASE
    )
    for m in pattern.finditer(body):
        full_table = m.group(1).replace('[', '').replace(']', '')
        alias = m.group(2)
        parts = full_table.split('.')
        if len(parts) == 2 and parts[0].lower() in KNOWN_SCHEMAS:
            table_short = parts[1]
            if alias:
                table_map[alias.lower()] = (parts[0], table_short)
            else:
                table_map[table_short.lower()] = (parts[0], table_short)
    return table_map


# ── column expression extraction ─────────────────────────────────────

def split_select_exprs(select_text):
    """Split SELECT ... FROM into individual raw expressions."""
    from_pos = find_top_level_from(select_text)
    if from_pos < 0:
        col_part = select_text
    else:
        col_part = select_text[:from_pos]
    col_part = re.sub(r'^\s*SELECT\s+(DISTINCT\s+|TOP\s+\d+\s+)?', '', col_part, flags=re.IGNORECASE).strip()
    items = []
    depth = 0
    current = ''
    for ch in col_part:
        if ch == '(':
            depth += 1
            current += ch
        elif ch == ')':
            depth -= 1
            current += ch
        elif ch == ',' and depth == 0:
            items.append(current.strip())
            current = ''
        else:
            current += ch
    if current.strip():
        items.append(current.strip())
    return items


def find_top_level_from(text):
    """Find FROM at depth 0, ignoring FROM inside subqueries."""
    depth = 0
    for i, ch in enumerate(text):
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        elif depth == 0 and text[i:i + 4].upper() == 'FROM' and (i == 0 or not text[i-1].isalnum()):
            after = i + 4
            if after >= len(text) or not text[after].isalnum():
                return i
    return -1


def expr_to_name(expr):
    """Extract column alias/name from a SELECT expression."""
    expr = expr.strip()
    if not expr:
        return None
    as_match = re.search(r'\bAS\s+\[?(\w+)\]?\s*$', expr, re.IGNORECASE)
    if as_match:
        return as_match.group(1)
    if re.fullmatch(r'\*', expr):
        return '*'
    if re.fullmatch(r'[\w."]+\.\*', expr):
        return expr
    tokens = re.split(r'\s+', expr)
    if len(tokens) >= 2 and re.fullmatch(r'\[?\w+\]?', tokens[-1]):
        candidate = tokens[-1].strip('[]')
        if candidate.upper() not in SQL_KEYWORDS:
            return candidate
    last = tokens[-1].strip('[]')
    if '.' in last:
        last = last.split('.')[-1]
    if re.fullmatch(r'\w+', last) and last.upper() not in SQL_KEYWORDS:
        return last
    return expr[:30]


def extract_column_tuples(select_text):
    """Return [(raw_expr, column_name), ...] from a SELECT block."""
    items = split_select_exprs(select_text)
    result = []
    for item in items:
        name = expr_to_name(item)
        if name:
            result.append((item.strip(), name))
    return result


# ── FROM alias map for a single SELECT ───────────────────────────────

def build_select_alias_map(select_text):
    """Build {alias: ('__cte__'|'__subquery__', ref)} from a SELECT's FROM clause."""
    amap = {}
    from_pos = find_top_level_from(select_text)
    if from_pos < 0:
        return amap
    from_clause = select_text[from_pos + 4:]
    depth = 0
    cut = len(from_clause)
    for i, ch in enumerate(from_clause):
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        elif depth == 0:
            rest = from_clause[i:i+6].upper()
            if rest.startswith('WHERE') or rest.startswith('GROUP') or rest.startswith('ORDER'):
                cut = i
                break
    from_clause = from_clause[:cut]
    pos = 0
    max_iter = len(from_clause) + 10
    it = 0
    while pos < len(from_clause) and it < max_iter:
        it += 1
        ws = re.match(r'\s+', from_clause[pos:])
        if ws:
            pos += ws.end()
        if pos >= len(from_clause):
            break
        if from_clause[pos] == '(':
            subq_body, end_pos = extract_balanced(from_clause, pos)
            if end_pos <= pos:
                pos += 1
                continue
            pos = end_pos
            alias_m = re.match(r'\s+(?:AS\s+)?["\[]?(\w+)["\]]?', from_clause[pos:], re.IGNORECASE)
            if alias_m and subq_body:
                amap[alias_m.group(1).lower()] = ('__subquery__', subq_body)
                pos += alias_m.end()
        else:
            name_m = re.match(r'["\[]?(\w+)["\]]?(?:\.\[?\w+\]?)?(?:\s*\([^)]*\))?(?:\s+(?:AS\s+)?["\[]?(\w+)["\]]?)?',
                              from_clause[pos:], re.IGNORECASE)
            if name_m:
                src = name_m.group(1)
                alias = name_m.group(2)
                skip = ('JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 'FULL', 'CROSS',
                        'ON', 'AND', 'OR', 'WHERE', 'GROUP', 'ORDER', 'HAVING', 'NOT', 'IN')
                if src.upper() in skip:
                    pos += len(src)
                    continue
                if alias and alias.upper() not in skip:
                    amap[alias.lower()] = ('__cte__', src)
                elif src.upper() not in skip and src.lower() not in amap:
                    amap[src.lower()] = ('__cte__', src)
                pos += name_m.end()
            else:
                pos += 1
    return amap


# ── expression-aware wildcard resolution ─────────────────────────────

def resolve_expr_tuples(tuples, ctes, select_ctx, depth=0):
    """Resolve * and alias.* in [(expr, name)] tuples, preserving expressions."""
    if depth > 5:
        return tuples
    resolved = []
    for expr, name in tuples:
        if name == '*' or name.endswith('.*'):
            alias = name.replace('.*', '').strip('"[]').split('.')[-1] if name != '*' else None
            star_tuples = _resolve_star(alias, ctes, select_ctx, depth)
            extra_expr = expr.replace(name, '').strip().strip(',').strip()
            resolved.extend(star_tuples)
        else:
            resolved.append((expr, name))
    return resolved


def _resolve_star(alias, ctes, select_ctx, depth):
    if depth > 5:
        return [('*', alias + '.*' if alias else '*')]

    amap = build_select_alias_map(select_ctx) if select_ctx else {}

    def resolve_from_cte(cte_key):
        if cte_key in ctes:
            cte_body = ctes[cte_key]
            inner = extract_column_tuples(cte_body)
            return resolve_expr_tuples(inner, ctes, cte_body, depth + 1)
        return None

    def resolve_from_subquery(subq):
        subq = strip_outer_parens(subq)
        inner = extract_column_tuples(subq)
        sub_ctes = parse_ctes(subq)
        return resolve_expr_tuples(inner, sub_ctes or ctes, subq, depth + 1)

    if alias:
        al = alias.lower()
        if al in amap:
            kind, ref = amap[al]
            if kind == '__subquery__':
                return resolve_from_subquery(ref)
            elif kind == '__cte__':
                result = resolve_from_cte(ref.lower())
                if result:
                    return result
        result = resolve_from_cte(al)
        if result:
            return result
        return [(alias + '.*', alias + '.*')]

    else:
        for src_name in amap:
            kind, ref = amap[src_name]
            if kind == '__subquery__':
                result = resolve_from_subquery(ref)
                if result and not any(n == '*' for _, n in result):
                    return result
            elif kind == '__cte__':
                result = resolve_from_cte(ref.lower())
                if result:
                    return result

        if select_ctx:
            from_pos = find_top_level_from(select_ctx)
            if from_pos >= 0:
                after = select_ctx[from_pos + 4:].strip()
                bare_m = re.match(r'["\[]?(\w+)["\]]?', after)
                if bare_m:
                    result = resolve_from_cte(bare_m.group(1).lower())
                    if result:
                        return result

        cte_names = list(ctes.keys())
        if len(cte_names) == 1:
            result = resolve_from_cte(cte_names[0])
            if result:
                return result

        return [('*', '*')]


# ── column lineage classification ────────────────────────────────────

TRANSFORM_MARKERS = re.compile(
    r'\bCASE\b|\bISNULL\b|\bCOALESCE\b|\bSUM\b|\bCOUNT\b|\bMIN\b|\bMAX\b'
    r'|\bAVG\b|\bCAST\b|\bCONVERT\b|\bROW_NUMBER\b|\bRANK\b|\bDENSE_RANK\b'
    r'|\bDATEADD\b|\bDATEDIFF\b|\bFORMAT\b|\bABS\b|\bLEN\b|\bTRIM\b'
    r'|\bCEILING\b|\bFLOOR\b|\bROUND\b|\bIIF\b|\bNULLIF\b|\bLEAD\b|\bLAG\b'
    r'|\bOVER\b|\bPARTITION\b'
    r'|\+|\-(?!\-)|\/(?!\/)', re.IGNORECASE)


def _get_from_tables(select_text, table_map):
    """Get real table names from a SELECT's FROM clause."""
    tables = []
    from_pos = find_top_level_from(select_text)
    if from_pos < 0:
        return tables
    from_clause = select_text[from_pos:]
    for m in re.finditer(r'(?:FROM|JOIN)\s+\[?(\w+)\]?\.\[?(\w+)\]?', from_clause, re.IGNORECASE):
        schema, table = m.group(1), m.group(2)
        if schema.lower() in KNOWN_SCHEMAS:
            tables.append(table)
    return tables


def trace_column_source(col_name, cte_body, ctes, table_map, depth=0):
    """Recursively trace a column through CTE chain to its real source table."""
    if depth > 6:
        return None, None, None

    tuples = extract_column_tuples(cte_body)
    local_amap = build_select_alias_map(cte_body)

    target_expr = None
    for expr, name in tuples:
        if name.lower().strip('[]" ') == col_name.lower():
            target_expr = expr
            break

    if target_expr is None:
        has_star = any(n == '*' or n.endswith('.*') for _, n in tuples)
        if has_star:
            for al_key, (kind, ref) in local_amap.items():
                if kind == '__cte__':
                    if ref.lower() in table_map:
                        schema, table = table_map[ref.lower()]
                        return f"{table}.{col_name}", "Direct", "T1"
                    if ref.lower() in ctes:
                        result = trace_column_source(col_name, ctes[ref.lower()], ctes, table_map, depth + 1)
                        if result[0] is not None:
                            return result
            from_tables = _get_from_tables(cte_body, table_map)
            if len(from_tables) == 1:
                return f"{from_tables[0]}.{col_name}", "Direct", "T1"
        return None, None, None

    def resolve_alias(alias):
        al = alias.lower()
        if al in table_map:
            return ('table', table_map[al][0], table_map[al][1])
        if al in local_amap:
            kind, ref = local_amap[al]
            if kind == '__cte__' and ref.lower() in ctes:
                return ('cte', ref.lower())
            if kind == '__cte__' and ref.lower() in table_map:
                return ('table', table_map[ref.lower()][0], table_map[ref.lower()][1])
        if al in ctes:
            return ('cte', al)
        return None

    alias_col = re.fullmatch(r'(\w+)\.(\w+)', target_expr.strip('[]" '))
    if alias_col:
        alias, col = alias_col.group(1), alias_col.group(2)
        resolved = resolve_alias(alias)
        if resolved:
            if resolved[0] == 'table':
                return f"{resolved[2]}.{col}", "Direct", "T1"
            else:
                return trace_column_source(col, ctes[resolved[1]], ctes, table_map, depth + 1)
        return f"{alias}.{col}", "Direct", "T1"

    just_col = re.fullmatch(r'\[?(\w+)\]?', target_expr.strip())
    if just_col:
        bare = just_col.group(1)
        for al_key, (kind, ref) in local_amap.items():
            if kind == '__cte__':
                if ref.lower() in table_map:
                    schema, table = table_map[ref.lower()]
                    return f"{table}.{bare}", "Direct", "T1"
                if ref.lower() in ctes:
                    result = trace_column_source(bare, ctes[ref.lower()], ctes, table_map, depth + 1)
                    if result[0] is not None:
                        return result
        from_tables = _get_from_tables(cte_body, table_map)
        if len(from_tables) == 1:
            return f"{from_tables[0]}.{bare}", "Direct", "T1"
        elif from_tables:
            return ', '.join(from_tables), "Direct", "T1"
        return "", "Direct", "T1"

    sources = set()
    for m in re.finditer(r'(\w+)\.(\w+)', target_expr):
        alias, col = m.group(1), m.group(2)
        resolved = resolve_alias(alias)
        if resolved:
            if resolved[0] == 'table':
                sources.add(resolved[2])
            else:
                inner = trace_column_source(col, ctes[resolved[1]], ctes, table_map, depth + 1)
                if inner[0]:
                    tbl = inner[0].split('.')[0] if '.' in inner[0] else inner[0]
                    sources.add(tbl)

    if not sources:
        from_tables = _get_from_tables(cte_body, table_map)
        sources.update(from_tables)

    clean_expr = re.sub(r'(\w+)\.', '', target_expr)
    clean_expr = re.sub(r'\s+', ' ', clean_expr).strip()
    as_match = re.search(r'\bAS\s+\[?\w+\]?\s*$', clean_expr, re.IGNORECASE)
    if as_match:
        clean_expr = clean_expr[:as_match.start()].strip()

    source_str = ', '.join(sorted(sources)) if sources else ''
    return source_str, clean_expr, "T2"


def classify_expr(raw_expr, table_map, ctes=None, select_ctx=None):
    """Classify with recursive CTE-aware resolution."""
    expr = raw_expr.strip()
    if ctes is None:
        ctes = {}
    final_amap = build_select_alias_map(select_ctx) if select_ctx else {}

    def resolve_alias(alias):
        al = alias.lower()
        if al in table_map:
            return ('table', table_map[al][0], table_map[al][1])
        if al in final_amap:
            kind, ref = final_amap[al]
            if kind == '__cte__' and ref.lower() in ctes:
                return ('cte', ref.lower())
            if kind == '__cte__' and ref.lower() in table_map:
                return ('table', table_map[ref.lower()][0], table_map[ref.lower()][1])
        if al in ctes:
            return ('cte', al)
        for cte_name, cte_body in ctes.items():
            cte_amap = build_select_alias_map(cte_body)
            if al in cte_amap:
                kind, ref = cte_amap[al]
                if kind == '__cte__' and ref.lower() in ctes:
                    return ('cte', ref.lower())
                if kind == '__cte__' and ref.lower() in table_map:
                    return ('table', table_map[ref.lower()][0], table_map[ref.lower()][1])
        return None

    alias_col_match = re.fullmatch(r'(\w+)\.(\w+)', expr.strip('[]" '))
    if alias_col_match:
        alias, col = alias_col_match.group(1), alias_col_match.group(2)
        resolved = resolve_alias(alias)
        if resolved:
            if resolved[0] == 'table':
                return f"{resolved[2]}.{col}", "Direct", "T1"
            else:
                result = trace_column_source(col, ctes[resolved[1]], ctes, table_map)
                if result[0] is not None:
                    return result
        return f"{alias}.{col}", "Direct", "T1"

    just_col = re.fullmatch(r'\[?(\w+)\]?', expr)
    if just_col:
        return "", "Direct", "T1"

    if TRANSFORM_MARKERS.search(expr) or re.match(r'@\w+', expr) or re.match(r"'[^']*'", expr) or re.fullmatch(r'\d+', expr):
        sources = set()
        for m in re.finditer(r'(\w+)\.(\w+)', expr):
            alias, col = m.group(1), m.group(2)
            resolved = resolve_alias(alias)
            if resolved:
                if resolved[0] == 'table':
                    sources.add(resolved[2])
                else:
                    inner = trace_column_source(col, ctes[resolved[1]], ctes, table_map)
                    if inner[0]:
                        tbl = inner[0].split('.')[0] if '.' in inner[0] else inner[0]
                        sources.add(tbl)

        clean_expr = re.sub(r'(\w+)\.', '', expr)
        clean_expr = re.sub(r'\s+', ' ', clean_expr).strip()
        as_match = re.search(r'\bAS\s+\[?\w+\]?\s*$', clean_expr, re.IGNORECASE)
        if as_match:
            clean_expr = clean_expr[:as_match.start()].strip()

        source_str = ', '.join(sorted(sources)) if sources else ''
        return source_str, clean_expr, "T2"

    sources = set()
    for m in re.finditer(r'(\w+)\.(\w+)', expr):
        alias, col = m.group(1), m.group(2)
        resolved = resolve_alias(alias)
        if resolved:
            if resolved[0] == 'table':
                sources.add(resolved[2])
            else:
                inner = trace_column_source(col, ctes[resolved[1]], ctes, table_map)
                if inner[0]:
                    tbl = inner[0].split('.')[0] if '.' in inner[0] else inner[0]
                    sources.add(tbl)

    clean_expr = re.sub(r'(\w+)\.', '', expr)
    clean_expr = re.sub(r'\s+', ' ', clean_expr).strip()
    as_match = re.search(r'\bAS\s+\[?\w+\]?\s*$', clean_expr, re.IGNORECASE)
    if as_match:
        clean_expr = clean_expr[:as_match.start()].strip()

    source_str = ', '.join(sorted(sources)) if sources else ''
    if source_str and clean_expr.replace('[', '').replace(']', '').replace('"', '') == expr_to_name(expr):
        return source_str, "Direct", "T1"
    if source_str:
        return source_str, clean_expr, "T2"
    return "", clean_expr or "Direct", "T1"


# ── full column lineage extraction ───────────────────────────────────

def parse_output_columns(content):
    """Parse output columns with full lineage: [(name, source, expression, tier)]."""
    body = get_return_body(content)
    if not body:
        return []

    table_map = build_global_table_map(body)
    ctes = parse_ctes(body)

    final_select = find_final_select(body, ctes)
    if not final_select:
        if not ctes:
            select_match = re.search(r'\bSELECT\b', body, re.IGNORECASE)
            if select_match:
                final_select = body[select_match.start():]
            else:
                return []
        else:
            return []

    raw_tuples = extract_column_tuples(final_select)

    outer_exprs = []
    for expr, name in raw_tuples:
        if name == '*' or name.endswith('.*'):
            star_alias = name.replace('.*', '').strip('"[]').split('.')[-1] if name != '*' else None
            resolved_inner = _resolve_star(star_alias, ctes, final_select, 0)
            for inner_expr, inner_name in resolved_inner:
                outer_exprs.append((inner_expr, inner_name))
        else:
            outer_exprs.append((expr, name))

    result = []
    for raw_expr, col_name in outer_exprs:
        col_name = col_name.strip('[]" ')
        if not col_name or col_name.upper() in ('', 'NULL') or col_name == '*':
            continue
        source, transformation, tier = classify_expr(raw_expr, table_map, ctes, final_select)
        result.append((col_name, source, transformation, tier))

    return result


# ── function metadata extraction ─────────────────────────────────────

def parse_function_sql(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    result = {}
    sig_match = re.search(
        r'(?:CREATE|ALTER)\s+FUNCTION\s+\[?\w+\]?\.\[?(\w+)\]?\s*\(([^)]*)\)\s*\n?\s*RETURNS\s+(\w+)',
        content, re.IGNORECASE
    )
    if not sig_match:
        return None

    result['name'] = sig_match.group(1)
    raw_params = sig_match.group(2).strip()
    result['return_type'] = sig_match.group(3).upper()

    params = []
    if raw_params:
        for p in raw_params.split(','):
            p = p.strip()
            parts = p.split()
            if len(parts) >= 2:
                pname = parts[0].strip('[]@')
                ptype = ' '.join(parts[1:]).strip('[]')
                params.append((pname, ptype))
    result['params'] = params

    desc_match = re.search(r'Description:\s*(.+?)(?:\n|\*)', content)
    result['description'] = desc_match.group(1).strip() if desc_match else ''

    author_match = re.search(r'Author:\s*(.+?)(?:\n)', content)
    result['author'] = author_match.group(1).strip() if author_match else ''

    changes = []
    change_block = re.search(
        r'\*\*\s*Change\s*History\s*\*\*(.*?)(?:\*{4,}|End\s+Main|----)',
        content, re.DOTALL | re.IGNORECASE
    )
    if change_block:
        for line in change_block.group(1).split('\n'):
            line = line.strip().strip('*').strip('-').strip()
            m = re.match(r'(\d{4}-?\d{2}-?\d{2})\s+(\w[\w\s]*?)\s{2,}(.+)', line)
            if m:
                changes.append((m.group(1), m.group(2).strip(), m.group(3).strip()))
    result['changes'] = changes

    if result['return_type'] == 'TABLE':
        result['output_columns'] = parse_output_columns(content)
    else:
        result['output_columns'] = []

    refs = set()
    body_start = content.find('RETURN')
    if body_start > 0:
        body = content[body_start:]
        for m in re.finditer(r'(?:FROM|JOIN)\s+(\w+\.\w+)', body, re.IGNORECASE):
            ref = m.group(1)
            parts = ref.split('.')
            if parts[0].lower() in KNOWN_SCHEMAS:
                refs.add(ref)
        for m in re.finditer(r'(\w+\.\w+)\s*\(', body, re.IGNORECASE):
            ref = m.group(1)
            parts = ref.split('.')
            if parts[0].lower() in KNOWN_SCHEMAS:
                refs.add(ref)
    result['references'] = sorted(refs)

    return result


# ── wiki generation ──────────────────────────────────────────────────

def classify_function(name):
    n = name.lower()
    if 'revenue' in n: return 'Revenue'
    if 'ddr' in n: return 'DDR (Daily Dashboard Report)'
    if 'population' in n: return 'Population / Cohort'
    if 'trading_volume' in n: return 'Trading Volume'
    if 'mimo' in n: return 'MIMO (Money In / Money Out)'
    if 'pnl' in n: return 'PnL (Profit and Loss)'
    if 'aum' in n: return 'AUM (Assets Under Management)'
    if 'instrument' in n: return 'Instrument'
    if 'search' in n: return 'Utility'
    if 'date' in n: return 'Utility'
    return 'General'


def infer_param_description(name, ptype):
    n = name.lower()
    if n in ('sdateint', 'sdate'): return 'Start date (YYYYMMDD integer format)'
    if n in ('edateint', 'edate'): return 'End date (YYYYMMDD integer format)'
    if n in ('dateid', 'dateint'): return 'Date (YYYYMMDD integer format)'
    if n == 'onlyvalidcustomers': return '0 = all customers, 1 = valid customers only'
    if n == 'isdepositor': return '0 = all, 1 = depositors only'
    return ''


def escape_pipe(text):
    return text.replace('|', '\\|') if text else text


def generate_wiki(func_data):
    name = func_data['name']
    domain = classify_function(name)
    desc = func_data['description'] if func_data['description'] and func_data['description'] != 'Bla' else ''
    author = func_data['author']
    params = func_data['params']
    return_type = func_data['return_type']
    refs = func_data['references']
    changes = func_data['changes']
    output_cols = func_data['output_columns']

    if not desc:
        desc = f"{domain} function"

    t1_count = sum(1 for _, _, _, t in output_cols if t == 'T1')
    t2_count = sum(1 for _, _, _, t in output_cols if t == 'T2')

    lines = []
    lines.append(f"# {name}")
    lines.append("")
    lines.append("## Properties")
    lines.append("")
    lines.append("| Property | Value |")
    lines.append("|----------|-------|")
    lines.append("| **Schema** | BI_DB_dbo |")
    lines.append("| **Object Type** | Function (TVF) |" if return_type == 'TABLE' else "| **Object Type** | Function (Scalar) |")
    lines.append(f"| **Domain** | {domain} |")
    lines.append("| **UC Target** | `_Not_Migrated` |")
    if author:
        lines.append(f"| **Author** | {author} |")
    if output_cols:
        lines.append(f"| **Output Columns** | {len(output_cols)} (T1: {t1_count}, T2: {t2_count}) |")
    lines.append(f"| **Generated** | {TIMESTAMP} |")
    lines.append("")

    lines.append("## 1. Business Meaning")
    lines.append("")
    lines.append(f"{desc}")
    lines.append("")

    lines.append("## 2. Parameters")
    lines.append("")
    if params:
        lines.append("| Parameter | Type | Description |")
        lines.append("|-----------|------|-------------|")
        for pname, ptype in params:
            pdesc = infer_param_description(pname, ptype)
            lines.append(f"| @{pname} | {ptype} | {pdesc} |")
    else:
        lines.append("No parameters.")
    lines.append("")

    lines.append("## 3. Source Objects")
    lines.append("")
    if refs:
        lines.append("| Object | Schema |")
        lines.append("|--------|--------|")
        for ref in refs:
            parts = ref.split('.')
            if len(parts) == 2:
                lines.append(f"| {parts[1]} | {parts[0]} |")
            else:
                lines.append(f"| {ref} | - |")
    else:
        lines.append("No external references detected.")
    lines.append("")

    lines.append("## 4. Output Columns")
    lines.append("")
    if output_cols:
        lines.append("| # | Column | Source | Transformation | Tier |")
        lines.append("|---|--------|--------|----------------|------|")
        for i, (col_name, source, transformation, tier) in enumerate(output_cols, 1):
            lines.append(f"| {i} | {escape_pipe(col_name)} | {escape_pipe(source)} | {escape_pipe(transformation)} | {tier} |")
    else:
        if return_type == 'TABLE':
            lines.append("Output columns could not be parsed from SQL.")
        else:
            lines.append(f"Returns scalar: **{return_type}**")
    lines.append("")

    if changes:
        lines.append("## 5. Change History")
        lines.append("")
        lines.append("| Date | Author | Description |")
        lines.append("|------|--------|-------------|")
        for date, auth, desc_ch in changes:
            lines.append(f"| {date} | {auth} | {desc_ch} |")
        lines.append("")

    lines.append("---")
    lines.append(f"*Auto-generated from SSDT source on {TIMESTAMP}. Knowledge-only -- not migrated to Unity Catalog.*")
    lines.append("")

    return '\n'.join(lines)


# ── main ─────────────────────────────────────────────────────────────

def main():
    dry_run = '--dry-run' in sys.argv
    exclude_explain = True

    if not os.path.isdir(SSDT_DIR):
        print(f"ERROR: SSDT directory not found: {SSDT_DIR}")
        sys.exit(1)

    os.makedirs(WIKI_DIR, exist_ok=True)

    sql_files = sorted([
        f for f in os.listdir(SSDT_DIR)
        if f.endswith('.sql')
        and (not exclude_explain or '_Explain' not in f)
    ])

    print(f"Found {len(sql_files)} non-explain function SQL files")
    print(f"Output: {WIKI_DIR}")
    print(f"Mode: {'DRY RUN' if dry_run else 'WRITE'}")
    print("=" * 60)

    success = 0
    failed = 0
    total_cols = 0
    total_t1 = 0
    total_t2 = 0

    for sql_file in sql_files:
        filepath = os.path.join(SSDT_DIR, sql_file)
        func_data = parse_function_sql(filepath)

        if not func_data:
            print(f"  SKIP (parse failed): {sql_file}")
            failed += 1
            continue

        wiki_content = generate_wiki(func_data)
        wiki_filename = f"{func_data['name']}.md"
        wiki_path = os.path.join(WIKI_DIR, wiki_filename)
        ncols = len(func_data['output_columns'])
        nt1 = sum(1 for _, _, _, t in func_data['output_columns'] if t == 'T1')
        nt2 = ncols - nt1
        total_cols += ncols
        total_t1 += nt1
        total_t2 += nt2

        if dry_run:
            print(f"  [DRY] {func_data['name']}: {ncols} cols (T1:{nt1} T2:{nt2}), "
                  f"{len(func_data['params'])} params, {len(func_data['references'])} refs")
        else:
            with open(wiki_path, 'w', encoding='utf-8') as f:
                f.write(wiki_content)
            print(f"  OK {func_data['name']}: {ncols} cols (T1:{nt1} T2:{nt2}), "
                  f"{len(func_data['params'])} params, {len(func_data['references'])} refs")
        success += 1

    print("=" * 60)
    print(f"Done: {success} wikis {'would be' if dry_run else ''} generated, {failed} failed")
    print(f"Total: {total_cols} columns (T1: {total_t1}, T2: {total_t2})")


if __name__ == "__main__":
    main()
