# DDR parity fixes — deployment summary

**Date:** 2026-05-31
**Operator:** Guy M
**Audit context:** [`audits/ddr_parity_20260420/investigation.md`](./investigation.md)
**Patch DDLs:** [`patch_1_v_mimo_allplatforms.sql`](./patch_1_v_mimo_allplatforms.sql), [`patch_2_sp_ddr_customer_daily_status.sql`](./patch_2_sp_ddr_customer_daily_status.sql)

## Scope

Two fixes deployed to Unity Catalog `main` for the 2026-04-20 parity drift identified vs. Synapse production:

| # | Defect | Magnitude | Fix |
|---|---|---:|---|
| 1 | MIMO MoneyFarm `AmountOrigCurrency` carrying USD-equivalent instead of unknown-GBP | +$4.66M phantom in the orig-currency leg | View `main.etoro_kpi_prep.v_mimo_allplatforms` — `moneyfarm_ftds` CTE emits `CAST(NULL AS DECIMAL(38,4))` |
| 2 | `IsDepositorGlobal` undercount from `LEAST`-of-4-FTDs spine missing depositors with no platform-FTD row | -5.6M (94%) vs. Synapse | SP `main.de_output.sp_ddr_customer_daily_status` — spine on `bs.IsDepositor = true` OR `Options_FTD_DateID IS NOT NULL` OR `MoneyFarm_FTD_DateID IS NOT NULL` |

## What was deployed

| Object | Action | Statement |
|---|---|---|
| `main.etoro_kpi_prep.v_mimo_allplatforms` | `CREATE OR REPLACE VIEW` (body + all 21 column comments) | `01f15cfb-f4d8-1ecd-857b-658e5234b155` |
| `main.de_output.sp_ddr_customer_daily_status` | `CREATE OR REPLACE PROCEDURE` (full SP body) | (succeeded inline) |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` @ 20260420 | DELETE + INSERT via `CALL main.de_output.sp_ddr_fact_mimo_allplatforms('20260420')` | Delta version 1503 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` @ 20260420 | DELETE + INSERT via `CALL main.de_output.sp_ddr_customer_daily_status(DATE '2026-04-20')` | Delta version 472 |

## Verification — DateID = 20260420

### MIMO `AmountOrigCurrency`

| MIMOPlatform | rows | sum_usd | sum_orig | non_null_orig |
|---|---:|---:|---:|---:|
| MoneyFarm | 121 | 4,656,221.24 | **NULL** | **0** ✓ |
| Options | 267 | 163,198.69 | 163,198.69 | 267 |
| TradingPlatform | 93,090 | 74,682,069.51 | 51,199,540.00 | 93,090 |
| eMoney | 91,255 | 68,319,574.71 | 56,206,580.25 | 91,255 |

### `IsDepositorGlobal` vs Synapse

| Metric | DBX (after fix) | Synapse | Delta |
|---|---:|---:|---:|
| rows | 6,808,575 | 6,807,394 | +1,181 (SCD lag, known) |
| `IsDepositor` (FSC) | 5,894,818 | 5,894,818 | **0** ✓ |
| `IsDepositorGlobal` | 5,894,819 | 5,895,044 | -225 (0.004%) |

The 5.6M undercount is **resolved**. The 225-row residual is the Options/MoneyFarm FTD-view coverage gap (`v_mimo_first_deposit_all_platforms`) — same root cause as the Options `Deposited`/`ReDeposited` finding in the original audit. Out of scope for this deployment.

## Important: notebook persistence risk

`main.de_output.sp_ddr_customer_daily_status` is **re-created from an inline notebook in the prod ETL job** (confirmed during the earlier `DATATYPE_MISMATCH` investigation). The UC `CREATE OR REPLACE PROCEDURE` deployed here will be **overwritten on the next prod job run** unless the notebook source is patched.

### Notebook patch instructions

Locate the cell that runs `spark.sql("CREATE OR REPLACE PROCEDURE main.de_output.sp_ddr_customer_daily_status ...")` (it's the same notebook that historically had the `IsDepositor = 1` bug). Apply both of these edits:

1. **`WHERE IsDepositor = 1` → `WHERE IsDepositor`** (BOOLEAN vs INT — `DATATYPE_MISMATCH` guard; identified earlier, still present in the live SP we re-pulled today, suggesting the notebook is also still un-patched on this point).

2. **`IsDepositorGlobal` CASE** — replace the existing `LEAST`-of-4-FTDs expression with:

```sql
CASE WHEN bs.IsDepositor = true
      OR ft.Options_FTD_DateID  IS NOT NULL
      OR ft.MoneyFarm_FTD_DateID IS NOT NULL
     THEN 1 ELSE 0 END AS IsDepositorGlobal,
```

Until the notebook is patched, the UC SP fix only survives until the next prod run of that job.

## Out of scope / follow-ups

- **Historical backfill of MoneyFarm `AmountOrigCurrency`** — only DateID=20260420 was reloaded today. Other dates in the MIMO fact still carry USD-equivalent for MoneyFarm rows. Decide whether to backfill the full historical window or leave as-is and apply forward-only.
- **`v_mimo_first_deposit_all_platforms` coverage gap** — would lift the residual 225-row `IsDepositorGlobal` gap and the 18-row Options re-depositor anomaly. Separate ticket.
- **`de_output.de_output_ddr_fact_mimo_allplatforms`** — EXTERNAL table separate from the bi_db copy. Confirm sync path / whether the AmountOrigCurrency NULL flows through to its consumers.
- **MIMO SP param convention** — `sp_ddr_fact_mimo_allplatforms(p_date STRING)` expects `'20260420'` (yyyymmdd), not `'2026-04-20'`. `CAST('2026-04-20' AS INT)` returns NULL silently → DELETE/INSERT 0 rows. Easy footgun. Consider tightening to `DATE` parameter or adding a validator.
