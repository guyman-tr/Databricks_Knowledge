---
name: databricks-etr-formatting
description: Enforces the eToro DDR date-format invariants when calling or authoring Databricks Unity Catalog stored procedures. Use ANY time the agent is about to (1) write a loop/script that CALLs `main.de_output.sp_ddr_*`, (2) author or modify a `sp_ddr_*` SP DDL, (3) backfill DDR fact / customer-status / periodic-status tables, (4) debug duplicate rows in `ddr_*` tables or "DELETE matched 0 rows" after a backfill, or (5) write any query that filters DDR tables by `etr_ymd`, `etr_ym`, or `etr_y`. Captures the warehouse-wide invariant `etr_ymd = 'yyyy-MM-dd'`, the three distinct SP parameter conventions (INT DateID / STRING 'YYYYMMDD' / DATE), and the exact mismatch that caused the 26.6M duplicate-row MIMO backfill incident.
---

# Databricks DDR etr_* Date Formatting

## The One Invariant

**`etr_ymd` is ALWAYS the string `'yyyy-MM-dd'` (with dashes).**

Same goes for the sibling columns: `etr_y` = `'yyyy'`, `etr_ym` = `'yyyy-MM'`. These three string columns are the warehouse-wide partition convention. Every Synapse → bronze → gold → de_output table that has them obeys this format. Every SP that writes them must derive them via `DATE_FORMAT(<date>, 'yyyy-MM-dd')`. Every query that filters by them must pass a dashed string literal.

If you ever see `etr_ymd = '20260607'` (no dashes) → it's wrong, full stop.

## Why this skill exists — verbatim incident note

> The stored procedures expect `etr_ymd` in `'yyyy-MM-dd'` format, but the previous script was passing `yyyyMMdd` (without dashes). This format mismatch is exactly what caused the **26.6M duplicate rows in the previous MIMO backfill** — the DELETE statements couldn't find matching rows to remove because the date formats didn't align.

The SP parameter format and the internal `etr_ymd` column format are **separate concerns**. The parameter might come in as `'YYYYMMDD'`, but the SP internally must convert it to `'yyyy-MM-dd'` before any DELETE/INSERT that touches the etr columns, or the DELETE/WHERE filter never matches and INSERT silently duplicates.

## The Three SP Parameter Conventions (DBX `main.de_output.*`)

| Convention | Parameter type | Pass as | SPs that use it |
|---|---|---|---|
| **A. INT DateID** | `INT` | `20260607` (bare int, YYYYMMDD) | `sp_ddr_fact_aum`, `sp_ddr_fact_pnl`, `sp_ddr_fact_trading_volumes_and_amounts` |
| **B. STRING YYYYMMDD** | `STRING` | `'20260607'` (quoted, no dashes) | `sp_ddr_fact_mimo_allplatforms`, `sp_ddr_fact_revenue_generating_actions` |
| **C. DATE** | `DATE` | `DATE '2026-06-07'` (must use DATE literal) | `sp_ddr_customer_daily_status` |

Always verify before writing a loop:

```sql
SELECT specific_name, parameter_name, data_type, ordinal_position
FROM   system.information_schema.parameters
WHERE  specific_catalog='main' AND specific_schema='de_output'
   AND specific_name LIKE 'sp_ddr_%'
ORDER  BY specific_name, ordinal_position;
```

**Never guess** the parameter convention from the SP name — the family is heterogeneous and grew organically. Look it up every time.

## Correct CALL-site patterns

```sql
-- A. INT DateID  (sp_ddr_fact_aum)
CALL main.de_output.sp_ddr_fact_aum(20260607);

-- B. STRING YYYYMMDD  (sp_ddr_fact_mimo_allplatforms)
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260607');

-- C. DATE  (sp_ddr_customer_daily_status)
CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-06-07');
```

## Broken CALL-site patterns (these are the bugs)

```sql
-- BREAKS: MIMO is STRING-YYYYMMDD, not dashed.
--        CAST('2026-05-22' AS INT) -> NULL, DateID predicate matches nothing,
--        DELETE removes 0 rows, INSERT appends -> duplicates.
CALL main.de_output.sp_ddr_fact_mimo_allplatforms('2026-05-22');

-- BREAKS: Daily_Status is DATE, not STRING. Spark refuses bare quoted text
--        and ANSI implicit cast is not guaranteed -- explicit DATE literal required.
CALL main.de_output.sp_ddr_customer_daily_status('2026-06-07');
CALL main.de_output.sp_ddr_customer_daily_status('20260607');

-- BREAKS: AUM/PnL/Volumes are INT DateID, not string.
CALL main.de_output.sp_ddr_fact_aum('20260607');
```

## Filter-site patterns (querying `etr_*` columns directly)

```sql
-- Correct: dashed string literal for etr_ymd
SELECT * FROM main.bi_db.gold_..._customer_daily_status WHERE etr_ymd = '2026-06-07';

-- Correct: dashed monthly for etr_ym
SELECT * FROM main.bi_db.gold_..._fact_mimo_allplatforms WHERE etr_ym = '2026-06';

-- WRONG: returns 0 rows silently, then you assume the date is empty.
SELECT * FROM main.bi_db.gold_..._customer_daily_status WHERE etr_ymd = '20260607';

-- WRONG: comparing string column to int -> implicit cast loses leading-zero / type semantics.
SELECT * FROM main.bi_db.gold_..._customer_daily_status WHERE etr_ymd = 20260607;
```

If you need an INT day predicate (cheaper and partition-safe), filter by `DateID` (the INT column), not by casting `etr_ymd`:

```sql
WHERE DateID = 20260607          -- good
WHERE etr_ymd = '2026-06-07'     -- also good
WHERE CAST(etr_ymd AS INT) = ... -- bad: defeats partition pruning + risks coercion
```

## Authoring an SP — the required derivation block

Whatever the parameter shape, every DDR SP that writes etr columns must derive **all three** before any DELETE/INSERT:

```sql
-- Pattern C (DATE parameter, e.g. sp_ddr_customer_daily_status)
DECLARE p_date_id INT;
DECLARE p_etr_ymd STRING;
DECLARE p_etr_ym  STRING;
DECLARE p_etr_y   STRING;

SET p_date_id = CAST(DATE_FORMAT(process_date, 'yyyyMMdd') AS INT);
SET p_etr_ymd = DATE_FORMAT(process_date, 'yyyy-MM-dd');
SET p_etr_ym  = DATE_FORMAT(process_date, 'yyyy-MM');
SET p_etr_y   = DATE_FORMAT(process_date, 'yyyy');

DELETE FROM main.bi_db.gold_..._target WHERE etr_ymd = p_etr_ymd;
INSERT INTO main.bi_db.gold_..._target SELECT ..., p_etr_y, p_etr_ym, p_etr_ymd ...;
```

```sql
-- Pattern B (STRING 'YYYYMMDD' parameter, e.g. sp_ddr_fact_mimo_allplatforms)
DECLARE v_date     DATE;
DECLARE v_date_id  INT;
DECLARE v_etr_ymd  STRING;

SET v_date    = TO_DATE(p_date, 'yyyyMMdd');     -- normalize first
SET v_date_id = CAST(p_date AS INT);
SET v_etr_ymd = DATE_FORMAT(v_date, 'yyyy-MM-dd');

DELETE FROM main.bi_db.gold_..._target
WHERE  DateID  = v_date_id              -- INT-keyed delete
   AND etr_ymd = v_etr_ymd;             -- defence in depth on partition column
```

**Defence in depth**: when the partition key is `etr_ymd` (string) but you also have `DateID` (int), filter on **both** in DELETE/UPDATE so any future caller mistake fails loudly (0 rows ≠ rows-by-wrong-format) instead of silently double-inserting.

## Backfill checklist (use every time)

Before running a backfill loop in DBX, confirm in order:

1. **Parameter type per SP** — look it up in `system.information_schema.parameters`. Do not infer from the SP name.
2. **Date literal matches the parameter type** — see the "Correct CALL-site patterns" table above.
3. **Idempotency check** — open the SP body with `DESCRIBE PROCEDURE EXTENDED` and confirm the first writes to the target are `DELETE FROM ... WHERE <partition key>`. If not, the loop is not safe to re-run.
4. **Confirm the DELETE predicate uses the same format the parameter derives** — e.g. SP takes `DATE`, sets `p_etr_ymd = DATE_FORMAT(...,'yyyy-MM-dd')`, and DELETE uses `WHERE etr_ymd = p_etr_ymd`. If you see a DELETE comparing `etr_ymd` to a `yyyyMMdd` string, **stop and patch the SP first**.
5. **Run for ONE date end-to-end** before launching the multi-day loop. Then:

```sql
-- Sanity: did the single-date run produce exactly the rows you expect, and only those?
SELECT etr_ymd, COUNT(*) AS rows
FROM   main.bi_db.gold_..._target
WHERE  etr_ymd = '<dashed date you backfilled>'
GROUP  BY etr_ymd;
```

6. **Watch for duplicates** after each chunk:

```sql
SELECT etr_ymd, DateID, COUNT(*) AS total_rows,
       COUNT(*) - COUNT(DISTINCT <pk_or_natural_key>) AS dup_rows
FROM   main.bi_db.gold_..._target
WHERE  etr_ymd BETWEEN '<start>' AND '<end>'
GROUP  BY etr_ymd, DateID
HAVING COUNT(*) > COUNT(DISTINCT <pk_or_natural_key>);
```

Any non-zero `dup_rows` row means the DELETE didn't match — stop the loop, find the format mismatch, **TRUNCATE or selectively DELETE the duplicates**, then resume.

## Duplicate-row debug recipe (when it has already happened)

1. **Confirm the column format you actually wrote**:
   ```sql
   SELECT DISTINCT etr_ymd FROM main.bi_db.gold_..._target ORDER BY etr_ymd DESC LIMIT 30;
   ```
   Every value should match `^\d{4}-\d{2}-\d{2}$`. Any `'YYYYMMDD'` value here is contamination from a buggy caller.

2. **Quantify the duplication scope**:
   ```sql
   SELECT etr_ymd, COUNT(*) - COUNT(DISTINCT <key>) AS dup_rows
   FROM   main.bi_db.gold_..._target
   GROUP  BY etr_ymd
   HAVING COUNT(*) <> COUNT(DISTINCT <key>)
   ORDER  BY dup_rows DESC;
   ```

3. **Clean per-date**:
   ```sql
   DELETE FROM main.bi_db.gold_..._target
   WHERE  etr_ymd = '<bad_date_with_dashes>';
   -- (then re-run the SP for that date with the correct parameter format)
   ```

4. **Patch the caller** (the loop / job that injected the wrong format) — fixing the data without fixing the caller guarantees a re-occurrence on the next nightly.

## Cross-stack note (Synapse vs DBX)

The same invariant applies in Synapse:

- Synapse `BI_DB_DDR_*` tables also use `etr_ymd CHAR(10) = 'yyyy-MM-dd'`.
- Synapse SPs take `DATE` parameters and internally derive `etr_ymd` via `CONVERT(CHAR(10), @date, 23)` or `FORMAT(@date, 'yyyy-MM-dd')`.
- The exact same dup-row failure mode exists on Synapse — if you pass `'20260607'` to a Synapse DELETE on `etr_ymd`, you match 0 rows.

When backfilling **both** stacks, write one Synapse loop using `DATE` literals and one DBX loop using whichever of A / B / C matches each SP. Do not assume the same parameter shape across stacks.

## Quick reference card

```
INVARIANT:        etr_ymd column == 'yyyy-MM-dd'  (always, everywhere)

CALL formats:
  Pattern A INT:    CALL sp(20260607)
  Pattern B STRING: CALL sp('20260607')
  Pattern C DATE:   CALL sp(DATE '2026-06-07')

FILTER format:    WHERE etr_ymd = '2026-06-07'   (string, dashed)

SP authoring:     SET p_etr_ymd = DATE_FORMAT(<date>, 'yyyy-MM-dd');
                  DELETE ... WHERE etr_ymd = p_etr_ymd;

PRE-FLIGHT:       1. look up parameter type
                  2. CALL with matching literal
                  3. single-date dry-run + dup check
                  4. then loop
```
