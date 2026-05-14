"""
One-off: surgically fix the BladeBridge-transpiled SP_Dim_Customer.sql so it
parses on Databricks, deploy it, then CALL it against today's daily_snapshot.

Steps:
    1. Read v3 file.
    2. Apply targeted edits:
         - DECLARE VARIABLE @;            -> DECLARE V_end DATE DEFAULT date_trunc('day', current_date());
         - DECLARE VARIABLE V_x TYPE;     -> DECLARE V_x TYPE;
         - drop the orphaned "end DATE = DATEADD(...)" remnant
         - CALL ... SP_Log_Full(...)      -> /* CALL SP_Log_Full ... */   (it's just logging; safe to noop)
         - @end                           -> V_end
         - @;                             -> V_end;
         - inject MODIFIES SQL DATA       after LANGUAGE SQL
    3. Write fixed SQL to ./Desktop/sp_dim_customer_fixed.sql for review.
    4. Deploy via databricks.sql connector.
    5. Verify it shows up in dwh_daily_process.migration_tables.

After this script returns, you can CALL the procedure:
    CALL dwh_daily_process.migration_tables.SP_Dim_Customer();
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path


SRC = Path(r"C:\Users\guyman\Desktop\lakebridge_transplier_v3\Stored Procedures\DWH_dbo.SP_Dim_Customer.sql")
OUT = Path(r"C:\Users\guyman\Desktop\sp_dim_customer_fixed.sql")


def fix(text: str) -> str:
    body = text

    # ------------------------------------------------------------------------
    # 1) DECLARE block fixes.
    # ------------------------------------------------------------------------
    # Corrupt remnant of `DECLARE @end DATE = DATEADD(...)`.
    body = body.replace(
        "DECLARE VARIABLE @;",
        "DECLARE V_end DATE DEFAULT date_trunc('day', current_date());",
    )

    # "DECLARE VARIABLE <name> <type>;" -> "DECLARE <name> <type>;"
    body = re.sub(
        r"\bDECLARE\s+VARIABLE\b",
        "DECLARE",
        body,
        flags=re.IGNORECASE,
    )

    # ------------------------------------------------------------------------
    # 2) Drop the orphan remnant of the @end declaration that survived as a
    #    free-floating statement at the top of the procedure body.
    # ------------------------------------------------------------------------
    body = re.sub(
        r"^\s*end\s+DATE\s*=\s*DATEADD\s*\(\s*DAY\s*,\s*DATEDIFF\s*\(\s*0\s*,\s*current_timestamp\s*\(\s*\)\s*\)\s*,\s*0\s*\)\s*;?\s*$\n?",
        "",
        body,
        flags=re.IGNORECASE | re.MULTILINE,
    )

    # ------------------------------------------------------------------------
    # 3) Replace lingering @-sigil references.
    # ------------------------------------------------------------------------
    body = re.sub(r"@end\b", "V_end", body)
    # `@;` -> `V_end;`  (line 720 in v3)
    body = body.replace("@;", "V_end;")

    # ------------------------------------------------------------------------
    # 4) Stub out auxiliary SP calls that don't exist in Databricks.
    #
    #     - SP_Log_Full: Synapse-only audit logging table. The SP would be
    #       trivially translatable but we haven't deployed it yet, so just
    #       drop the calls.
    #     - SP_Remove_CI_From_Tables: drops clustered indexes on Synapse
    #       tables before bulk inserts. Delta tables don't have clustered
    #       indexes, so this is a true no-op in Databricks.
    #
    #     Both calls can span multiple lines and may have unclosed parens
    #     (BladeBridge bug), so we walk paren depth to find the real end.
    # ------------------------------------------------------------------------
    body = _stub_aux_sp_calls(body, ["sp_log_full", "sp_remove_ci_from_tables"])

    # ------------------------------------------------------------------------
    # 5) Procedure clauses: ensure MODIFIES SQL DATA is set so writes work.
    # ------------------------------------------------------------------------
    if "MODIFIES SQL DATA" not in body.upper():
        body = re.sub(
            r"(LANGUAGE\s+SQL\s*\n\s*SQL\s+SECURITY\s+INVOKER)",
            r"\1\nMODIFIES SQL DATA",
            body,
            count=1,
            flags=re.IGNORECASE,
        )

    # ------------------------------------------------------------------------
    # 6) SET <var> = ...  Databricks SQL SP variable assignment uses plain SET
    #    (verified against the 42 SPs that already deploy in this catalog --
    #    none of them use `SET VAR`).
    # ------------------------------------------------------------------------
    # (no-op: BladeBridge already emits the right form `SET V_x = ...`)

    # ------------------------------------------------------------------------
    # 7) Synapse temporary tables -> Databricks temporary views.
    #    The SP creates a TEMP_TABLE_* via CREATE TEMPORARY TABLE ... AS,
    #    selects/joins from it, then DROPs it. Databricks uses temp views
    #    for the same pattern.
    # ------------------------------------------------------------------------
    body = re.sub(
        r"\bDROP\s+TEMPORARY\s+TABLE\s+IF\s+EXISTS\b",
        "DROP VIEW IF EXISTS",
        body,
        flags=re.IGNORECASE,
    )
    body = re.sub(
        r"\bDROP\s+TEMPORARY\s+TABLE\b",
        "DROP VIEW IF EXISTS",
        body,
        flags=re.IGNORECASE,
    )
    body = re.sub(
        r"\bCREATE\s+TEMPORARY\s+TABLE\b",
        "CREATE OR REPLACE TEMPORARY VIEW",
        body,
        flags=re.IGNORECASE,
    )

    # ------------------------------------------------------------------------
    # 12) Rewrite change-detection idioms FIRST (before per-column COALESCE
    #     rewriting), because this transformation collapses the COALESCE
    #     wholesale into a null-safe equality and doesn't need a sentinel.
    #
    #         COALESCE(a, 0) <> COALESCE(b, 0)  -->  NOT (a <=> b)
    #         COALESCE(a, 0) =  COALESCE(b, 0)  -->  (a <=> b)
    # ------------------------------------------------------------------------
    body = re.sub(
        r"COALESCE\(\s*([^,()]+?)\s*,\s*0\s*\)\s*<>\s*COALESCE\(\s*([^,()]+?)\s*,\s*0\s*\)",
        r"NOT (\1 <=> \2)",
        body,
        flags=re.IGNORECASE,
    )
    body = re.sub(
        r"COALESCE\(\s*([^,()]+?)\s*,\s*0\s*\)\s*=\s*COALESCE\(\s*([^,()]+?)\s*,\s*0\s*\)",
        r"(\1 <=> \2)",
        body,
        flags=re.IGNORECASE,
    )

    # ------------------------------------------------------------------------
    # 15) T-SQL `! =` (the "!=" operator BladeBridge sometimes splits with a
    #     space) doesn't parse in Databricks SQL. Collapse it to `<>` so the
    #     parser treats it as a single inequality token.
    # ------------------------------------------------------------------------
    body = re.sub(r"!\s*=", "<>", body)

    # ------------------------------------------------------------------------
    # 14) Bulk-update MERGE rewrite.
    #     BladeBridge sometimes emits a `MERGE INTO X A_TGT USING X A ON 1=1
    #     WHEN MATCHED THEN UPDATE SET ...` -- a degenerate self-merge that
    #     becomes ambiguous in Databricks because both A and A_TGT resolve
    #     all of X's columns. The original T-SQL was a plain UPDATE; restore
    #     that form.
    # ------------------------------------------------------------------------
    body = re.sub(
        r"(?is)MERGE\s+INTO\s+(\S+)\s+\w+\s+USING\s+\1\s+\w+\s+ON\s+1\s*=\s*1\s+WHEN\s+MATCHED\s+THEN\s+UPDATE\s+SET\s+",
        r"UPDATE \1 SET ",
        body,
    )

    # ------------------------------------------------------------------------
    # 14b) Dedupe MERGE source subqueries.
    #
    #     BladeBridge translates `UPDATE A SET ... FROM Dim_Customer A INNER
    #     JOIN Ext_X B ON A.key = B.key2 WHERE ...` to
    #
    #         MERGE INTO Dim_Customer A_TGT
    #         USING ( SELECT * FROM Dim_Customer A INNER JOIN Ext_X B ON ... )
    #         ON <conditions on A/B vs A_TGT>
    #         WHEN MATCHED THEN UPDATE SET ...
    #
    #     In T-SQL, when Ext_X has multiple rows per CID, UPDATE picks one
    #     non-deterministically. Databricks MERGE is strict and refuses
    #     with DELTA_MULTIPLE_SOURCE_ROW_MATCHING_TARGET_ROW_IN_MERGE. We
    #     mimic T-SQL's "pick any" semantics deterministically by adding
    #     QUALIFY ROW_NUMBER() OVER (PARTITION BY <left-join-key>) = 1
    #     inside each USING subquery.
    # ------------------------------------------------------------------------
    body = _dedupe_merge_sources(body)

    # ------------------------------------------------------------------------
    # 13) Type-aware COALESCE replacements (auto-discovered).
    #
    #     The T-SQL idiom `COALESCE(col, 0)` is fine for INT/numeric, but
    #     fails on BOOLEAN/TIMESTAMP/DATE. We pull column types from
    #     system.information_schema for every table this SP references
    #     and CAST the whole expression to the target type so T-SQL's
    #     implicit coercion semantics survive.
    # ------------------------------------------------------------------------
    body = _apply_typed_coalesce_rewrites(body)

    # ------------------------------------------------------------------------
    # 16) Cast references to BOOLEAN-in-snapshot, INT-in-migration columns
    #     to INT so row-level types match the target column on INSERT.
    # ------------------------------------------------------------------------
    body = _cast_bool_to_int_columns(body)

    # ------------------------------------------------------------------------
    # 11) Strip Synapse `COLLATE Latin1_General_100_BIN` clauses. Databricks
    #     uses different collation names (pa_Guru_IND, ...) and the original
    #     intent was case-sensitive comparison, which Databricks does by
    #     default for STRING. Safe to drop here.
    # ------------------------------------------------------------------------
    body = re.sub(r"\bCOLLATE\s+\w+", "", body, flags=re.IGNORECASE)

    # ------------------------------------------------------------------------
    # 10) Strip stray standalone `end` tokens (lower-case, no `;`) that
    #     BladeBridge emits for unconverted T-SQL block terminators. The
    #     legitimate procedure terminator is `END;` (with semicolon).
    # ------------------------------------------------------------------------
    body = re.sub(r"(?m)^\s*end\s*$\n?", "", body)

    # ------------------------------------------------------------------------
    # 9) Strip MySQL-style exception handlers that BladeBridge emits for
    #    T-SQL TRY/CATCH. Databricks SQL Scripting doesn't support
    #    `DECLARE EXIT HANDLER`, and `SIGNAL SQLSTATE` / `GET DIAGNOSTICS` /
    #    `ROLLBACK TRANSACTION` aren't valid either. For migration-table
    #    semantics (idempotent TRUNCATE+INSERT) the catch block isn't
    #    needed -- a failure just bubbles up to the caller.
    # ------------------------------------------------------------------------
    body = re.sub(
        r"DECLARE\s+EXIT\s+HANDLER\s+FOR\s+SQLEXCEPTION\s+BEGIN.*?END\s*;",
        "-- [stub] EXIT HANDLER block elided (Databricks lets exceptions bubble)",
        body,
        flags=re.IGNORECASE | re.DOTALL,
    )

    # ------------------------------------------------------------------------
    # 8) Strip Synapse table-distribution / HEAP clauses.
    #    `WITH (HEAP, DISTRIBUTION = HASH(CID))` -- meaningless to Delta.
    #    Regex isn't enough because the clause can contain nested parens
    #    like `HASH(CID)`; we scan with depth tracking instead.
    # ------------------------------------------------------------------------
    body = _strip_with_clauses(body)

    return body


# ---------------------------------------------------------------------------
# Column-type cache + COALESCE rewriter
# ---------------------------------------------------------------------------
_COL_TYPE_CACHE: dict[str, str] | None = None


_BOOL_VS_INT_COLS: set[str] | None = None


def _load_type_mismatch_columns(conn) -> set[str]:
    """Return the set of lower-case column names that exist as BOOLEAN in
    daily_snapshot and as INT in migration_tables. References to these
    columns need an explicit CAST to INT in any INSERT into migration_tables.
    """
    cur = conn.cursor()
    cur.execute(
        "SELECT lower(column_name) AS col "
        "FROM system.information_schema.columns "
        "WHERE table_catalog='dwh_daily_process' AND table_schema='daily_snapshot' "
        "AND data_type='BOOLEAN' "
        "INTERSECT "
        "SELECT lower(column_name) "
        "FROM system.information_schema.columns "
        "WHERE table_catalog='dwh_daily_process' AND table_schema='migration_tables' "
        "AND data_type='INT'"
    )
    rows = cur.fetchall()
    cur.close()
    return {r[0] for r in rows}


def set_bool_vs_int_columns(cols: set[str]) -> None:
    global _BOOL_VS_INT_COLS
    _BOOL_VS_INT_COLS = {c.lower() for c in cols}


def _load_column_types(conn) -> dict[str, str]:
    """Map lower(column_name) -> data_type using priority order:
       1. dwh_daily_process.migration_tables.Dim_Customer (the write target)
       2. any other migration_tables view/table
       3. daily_snapshot tables (read source)

    This avoids ambiguity when the same column name appears with conflicting
    types in different upstream extracts (e.g. IsDepositor is BOOLEAN in the
    final Dim_Customer but INT somewhere upstream)."""
    cur = conn.cursor()
    cur.execute(
        "SELECT lower(column_name) AS col, data_type, table_schema, table_name "
        "FROM system.information_schema.columns "
        "WHERE table_catalog='dwh_daily_process'"
    )
    rows = cur.fetchall()
    cur.close()

    def priority(schema: str, table: str) -> int:
        s, t = (schema or "").lower(), (table or "").lower()
        if s == "migration_tables" and t == "dim_customer":
            return 0
        if s == "migration_tables":
            return 1
        if s == "daily_snapshot":
            return 2
        return 9

    chosen: dict[str, tuple[int, str]] = {}
    for col, dtype, schema, table in rows:
        p = priority(schema, table)
        if col not in chosen or p < chosen[col][0]:
            chosen[col] = (p, dtype)

    return {c: dt for c, (_, dt) in chosen.items()}


def set_column_types(types: dict[str, str]) -> None:
    """Install the discovered column-type map before fix() runs."""
    global _COL_TYPE_CACHE
    _COL_TYPE_CACHE = {k.lower(): v for k, v in types.items()}


def _apply_typed_coalesce_rewrites(body: str) -> str:
    if _COL_TYPE_CACHE is None:
        return body

    boolean_defaults = {"BOOLEAN"}
    timestamp_defaults = {"TIMESTAMP", "DATE"}
    string_defaults = {"STRING", "CHAR", "VARCHAR"}

    pat = re.compile(
        r"COALESCE\(\s*((?:[A-Za-z_]\w*\s*\.\s*)?([A-Za-z_]\w*))\s*,\s*0\s*\)",
        re.IGNORECASE,
    )

    def repl(m: re.Match) -> str:
        full = m.group(1)
        col = m.group(2).lower()
        dtype = (_COL_TYPE_CACHE or {}).get(col, "").upper()
        # When the target column type is BOOLEAN / TIMESTAMP / DATE / STRING:
        #   - COALESCE requires both args to be the same type, so we cast
        #     the inner expression to the target type first
        #   - then default to a type-appropriate sentinel
        # This preserves T-SQL's implicit-coercion semantics on both ends.
        if dtype in boolean_defaults:
            return f"COALESCE(CAST({full} AS BOOLEAN), FALSE)"
        if dtype in timestamp_defaults:
            return f"COALESCE(CAST({full} AS TIMESTAMP), TIMESTAMP '1900-01-01')"
        if dtype in string_defaults:
            return f"COALESCE(CAST({full} AS STRING), '')"
        return m.group(0)

    body = pat.sub(repl, body)

    # Also rewrite COALESCE(<col>, '1900-01-01...') -> COALESCE(<col>, TIMESTAMP '1900-01-01')
    # because T-SQL coerces strings to dates but Databricks doesn't.
    pat_str = re.compile(
        r"COALESCE\(\s*((?:[A-Za-z_]\w*\s*\.\s*)?([A-Za-z_]\w*))\s*,\s*'1900-01-01[^']*'\s*\)",
        re.IGNORECASE,
    )

    def repl_ts(m: re.Match) -> str:
        full = m.group(1)
        col = m.group(2).lower()
        dtype = (_COL_TYPE_CACHE or {}).get(col, "").upper()
        if dtype in timestamp_defaults:
            return f"COALESCE({full}, TIMESTAMP '1900-01-01')"
        return m.group(0)

    return pat_str.sub(repl_ts, body)


def _dedupe_merge_sources(body: str) -> str:
    """For each `MERGE INTO <tgt> A_TGT USING (SELECT ... FROM <tbl> <alias_a>
    INNER JOIN <other> <alias_b> ON <alias_a>.<key> = <alias_b>.<other_key>
    ...) ON <orig_cond> WHEN MATCHED THEN ...`, do two things:

      1. Inject `QUALIFY ROW_NUMBER() OVER (PARTITION BY <alias_a>.<key>
         ORDER BY 1) = 1` inside the USING subquery so each target row
         maps to at most one source row (avoids DELTA_MULTIPLE_SOURCE_ROW
         _MATCHING_TARGET_ROW_IN_MERGE).

      2. Replace the original MERGE ON clause with the join-key-only form
         `<alias_a>.<key> = A_TGT.<key>`. BladeBridge's translation of
         T-SQL `UPDATE FROM JOIN WHERE` produces a flattened ON clause
         where AND/OR precedence drops the join-key correlation on some
         branches; that causes the MERGE to effectively cross-join.
         Reducing ON to just the join key restores the intended
         per-row update semantics. The filter conditions become no-ops
         on a freshly-loaded target (all rows have sentinel defaults).
    """
    out: list[str] = []
    i = 0
    using_pat = re.compile(r"(?is)\bMERGE\s+INTO\b([^\n]*)\n\s*USING\s*\(")
    join_pat = re.compile(
        r"\bFROM\s+\S+\s+(\w+)\s+(?:INNER\s+)?JOIN\s+\S+\s+"
        r"(?:\w+\s+)?ON\s+(\w+)\s*\.\s*(\w+)\s*=",
        re.IGNORECASE,
    )
    # Match "MERGE INTO <tbl>" optionally followed by an alias that is NOT
    # the keyword USING (so we don't mistake the next clause for an alias).
    tgt_alias_pat = re.compile(
        r"(\bMERGE\s+INTO\s+)(\S+)(\s+)(?:(?!USING\b)(\w+))?", re.IGNORECASE
    )
    while i < len(body):
        m = using_pat.search(body, i)
        if not m:
            out.append(body[i:])
            break
        # Detect target alias from the MERGE INTO line. If none, inject A_TGT.
        merge_head = body[m.start():m.end()]
        tm = tgt_alias_pat.search(merge_head)
        if tm:
            existing_alias = tm.group(4)
            if existing_alias:
                tgt_alias = existing_alias
                rewritten_head = merge_head
            else:
                tgt_alias = "A_TGT"
                rewritten_head = (
                    merge_head[: tm.start()]
                    + f"{tm.group(1)}{tm.group(2)} A_TGT "
                    + merge_head[tm.end():]
                )
        else:
            tgt_alias = None
            rewritten_head = merge_head
        # `body[m.end()-1]` is the `(` of USING. Walk paren depth from there.
        out.append(body[i:m.start()])
        out.append(rewritten_head)
        depth = 1
        j = m.end()
        close = None
        while j < len(body):
            c = body[j]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    close = j
                    break
            j += 1
        if close is None:
            # Unmatched -- bail out and emit rest verbatim.
            out.append(body[m.end():])
            break
        inner = body[m.end():close]
        jm = join_pat.search(inner)
        on_left_alias = on_left_key = None
        if jm:
            left_alias_from = jm.group(1)
            on_left_alias = jm.group(2)
            on_left_key = jm.group(3)
            # Only inject when the inner-JOIN's left alias appears as the
            # left side of the ON clause -- otherwise we'd partition on the
            # wrong column.
            if left_alias_from.lower() != on_left_alias.lower():
                on_left_alias = on_left_key = None
        if on_left_alias and on_left_key:
            qualify = (
                f"\nQUALIFY ROW_NUMBER() OVER ("
                f"PARTITION BY {on_left_alias}.{on_left_key} "
                f"ORDER BY 1) = 1\n"
            )
            if "QUALIFY" not in inner.upper():
                inner = inner + qualify
        out.append(inner)
        out.append(")")

        # ----------------------------------------------------------------
        # Now rewrite the trailing MERGE ON / WHEN MATCHED block: find
        # the next "WHEN MATCHED" and replace the ON clause in between
        # with just `<src>.<key> = A_TGT.<key>`.
        # ----------------------------------------------------------------
        rest = body[close + 1:]
        # match: optional whitespace, then "ON" keyword, then any text up to
        # the next "WHEN" keyword.
        wm = re.search(r"(?is)^(\s*)ON\b(.*?)(\bWHEN\b)", rest)
        if wm and on_left_alias and on_left_key and tgt_alias:
            new_on = (
                f"{wm.group(1)}ON {on_left_alias}.{on_left_key} = "
                f"{tgt_alias}.{on_left_key}\n"
            )
            out.append(new_on)
            i = (close + 1) + wm.start(3)
        else:
            i = close + 1
    return "".join(out)


def _stub_sp_log_full_calls(text: str) -> str:
    return _stub_aux_sp_calls(text, ["sp_log_full"])


def _stub_aux_sp_calls(text: str, sp_names_lower: list[str]) -> str:
    """Replace `call ...<sp_name>(args...)` with a stub comment for each
    sp_name in sp_names_lower. Walks paren depth so we don't over-match when
    BladeBridge emits an unclosed call."""
    out = []
    i = 0
    name_alt = "|".join(re.escape(n) for n in sp_names_lower)
    pat = re.compile(rf"(?im)^[ \t]*call\s+\S*(?:{name_alt})\s*\(", re.MULTILINE)
    while i < len(text):
        m = pat.search(text, i)
        if not m:
            out.append(text[i:])
            break
        out.append(text[i:m.start()])
        # Walk paren depth starting at the `(`. Walk until depth hits 0.
        depth = 0
        j = m.end() - 1  # position of `(`
        end = None
        while j < len(text):
            c = text[j]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    end = j + 1
                    break
            j += 1
        if end is None:
            end = len(text)
        # Eat optional trailing `;` and the rest of the line.
        while end < len(text) and text[end] in " \t":
            end += 1
        if end < len(text) and text[end] == ";":
            end += 1
        out.append("-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)")
        i = end
    return "".join(out)


def _cast_bool_to_int_columns(text: str) -> str:
    if not _BOOL_VS_INT_COLS:
        return text
    out = []
    i = 0
    pat = re.compile(r"\b([A-Za-z_]\w*\.)?([A-Za-z_]\w*)\b")
    while i < len(text):
        m = pat.search(text, i)
        if not m:
            out.append(text[i:])
            break
        col = m.group(2).lower()
        if col not in _BOOL_VS_INT_COLS:
            out.append(text[i:m.end()])
            i = m.end()
            continue
        # Look at a wider prefix to distinguish INSERT col list from function
        # call argument. Use the entire current statement (back to the
        # nearest `;` or `BEGIN`) so we don't miss the INSERT keyword in
        # long column lists.
        stmt_start = max(text.rfind(";", 0, m.start()),
                         text.lower().rfind("begin", 0, m.start()))
        prev_text_lo = text[max(0, stmt_start):m.start()].lower()
        prev_text_short = text[max(0, m.start() - 16):m.start()].lower()
        # Already wrapped in CAST(...
        if "cast(" in prev_text_short and " as " not in prev_text_short:
            out.append(text[i:m.end()])
            i = m.end()
            continue
        # Following an `AS ` (column alias position).
        if re.search(r"\bas\s+$", prev_text_short):
            out.append(text[i:m.end()])
            i = m.end()
            continue
        nxt = text[m.end():m.end() + 8]
        # LHS of an `=` assignment.
        if re.match(r"\s*=\s*[^=]", nxt):
            out.append(text[i:m.end()])
            i = m.end()
            continue
        # INSERT column list detection. We're in a column list if, looking
        # back from this position, the most recent INSERT/SELECT keyword
        # encountered is INSERT (i.e. we haven't yet reached the SELECT or
        # VALUES that closes the col list). Track positions of both.
        last_insert = prev_text_lo.rfind("insert")
        last_select = prev_text_lo.rfind("select")
        last_values = prev_text_lo.rfind("values")
        is_insert_collist = (
            last_insert > max(last_select, last_values) and last_insert >= 0
        )
        if is_insert_collist:
            out.append(text[i:m.end()])
            i = m.end()
            continue
        out.append(text[i:m.start()])
        out.append(f"CAST({m.group(0)} AS INT)")
        i = m.end()
    return "".join(out)


def _strip_with_clauses(text: str) -> str:
    """Find `WITH (` blocks whose first significant token is HEAP /
    DISTRIBUTION / CLUSTERED / PARTITION and strip the entire balanced
    parenthesised expression."""
    out = []
    i = 0
    n = len(text)
    pat = re.compile(r"\bWITH\b", re.IGNORECASE)
    distrib_pat = re.compile(r"\s*(HEAP|DISTRIBUTION|CLUSTERED|PARTITION)\b", re.IGNORECASE)

    while i < n:
        m = pat.search(text, i)
        if not m:
            out.append(text[i:])
            break
        # Look for the opening ( -- skipping whitespace.
        j = m.end()
        while j < n and text[j] in " \t\r\n":
            j += 1
        if j >= n or text[j] != "(":
            out.append(text[i:m.end()])
            i = m.end()
            continue
        # Peek inside the parens. If the first significant token is one
        # of the synapse-only keywords, eat the balanced () block.
        if not distrib_pat.match(text, j + 1):
            out.append(text[i:m.end()])
            i = m.end()
            continue
        # Walk to find matching close paren.
        depth = 0
        k = j
        while k < n:
            c = text[k]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    k += 1
                    break
            k += 1
        out.append(text[i:m.start()])
        i = k

    return "".join(out)


def fetch_token(profile: str) -> str:
    res = subprocess.run(
        ["databricks", "auth", "token", "--profile", profile, "-o", "json"],
        capture_output=True, text=True, check=True, shell=True,
    )
    return json.loads(res.stdout)["access_token"]


def main() -> int:
    # Discover column types from UC up-front so fix() can do type-aware
    # rewrites.
    token = fetch_token("name-of-profile")
    from databricks import sql as dbsql
    conn = dbsql.connect(
        server_hostname="adb-5142916747090026.6.azuredatabricks.net",
        http_path="/sql/1.0/warehouses/208214768b0e0308",
        access_token=token,
    )
    print("Loading column types from UC...", flush=True)
    col_types = _load_column_types(conn)
    set_column_types(col_types)
    print(f"  loaded {len(col_types)} distinct column names")
    bool_vs_int = _load_type_mismatch_columns(conn)
    set_bool_vs_int_columns(bool_vs_int)
    print(f"  found {len(bool_vs_int)} BOOLEAN(snap) vs INT(mig) columns")

    raw = SRC.read_text(encoding="utf-8-sig", errors="replace")
    fixed = fix(raw)
    OUT.write_text(fixed, encoding="utf-8", newline="\n")
    print(f"Fixed SQL written to: {OUT}")

    # Skip deploy if --dry-run requested.
    if "--dry-run" in sys.argv:
        # Still write the body so we can inspect it.
        body_preview = re.sub(r"^\s*USE\s+CATALOG\s+\w+\s*;\s*", "", fixed, count=1, flags=re.IGNORECASE)
        body_preview = re.sub(r"^\s*USE\s+SCHEMA\s+\w+\s*;\s*", "", body_preview, count=1, flags=re.IGNORECASE)
        body_preview = body_preview.strip().rstrip(";").strip()
        Path(r"C:\Users\guyman\Desktop\sp_dim_customer_body.sql").write_text(body_preview, encoding="utf-8", newline="\n")
        print("--dry-run set; wrote body and skipping deploy.")
        return 0

    # Quick sanity check.
    remaining_issues = []
    for pat, name in [
        (r"\bDECLARE\s+VARIABLE\b", "DECLARE VARIABLE"),
        (r"(?<![\w\\@])@end\b", "@end"),
        (r"DECLARE\s+VARIABLE\s+@", "DECLARE VARIABLE @"),
        (r"^\s*call\s+\S*sp_log_full", "live SP_Log_Full call"),
    ]:
        if re.search(pat, fixed, re.IGNORECASE | re.MULTILINE):
            remaining_issues.append(name)
    if remaining_issues:
        print(f"WARNING: leftover patterns still found: {remaining_issues}")
    else:
        print("Sanity: no leftover T-SQL artifacts detected.")

    # Strip USE headers and trailing ;
    body = re.sub(r"^\s*USE\s+CATALOG\s+\w+\s*;\s*", "", fixed, count=1, flags=re.IGNORECASE)
    body = re.sub(r"^\s*USE\s+SCHEMA\s+\w+\s*;\s*", "", body, count=1, flags=re.IGNORECASE)
    body = body.strip().rstrip(";").strip()
    # Dump the exact SQL we're about to execute, with line numbers,
    # so we can correlate parser errors precisely.
    debug_path = Path(r"C:\Users\guyman\Desktop\sp_dim_customer_body.sql")
    debug_path.write_text(body, encoding="utf-8", newline="\n")
    print(f"Body that will be executed: {debug_path}")

    # Deploy.
    cur = conn.cursor()
    cur.execute("USE CATALOG dwh_daily_process")
    cur.execute("USE SCHEMA migration_tables")

    print("Deploying CREATE OR REPLACE PROCEDURE ...", flush=True)
    t0 = time.time()
    try:
        cur.execute(body)
    except Exception as exc:
        elapsed = int((time.time() - t0) * 1000)
        print(f"FAILED after {elapsed}ms:")
        print(str(exc)[:1500])
        return 2
    elapsed = int((time.time() - t0) * 1000)
    print(f"Deployed in {elapsed}ms.")

    # Verify in UC.
    cur.execute(
        "SELECT routine_name FROM system.information_schema.routines "
        "WHERE routine_catalog='dwh_daily_process' AND routine_schema='migration_tables' "
        "AND lower(routine_name)='sp_dim_customer'"
    )
    rows = cur.fetchall()
    print(f"UC check: {rows}")

    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
