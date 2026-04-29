# Review Needed: BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks

**Generated**: 2026-04-28 | **Regen attempt**: 2

## Items for Human Review

### R1 — Dormant status confirmation

The table's last data row is 2024-02-09. The `_no_upstream_found.txt` marker confirms dormant status. A human should confirm whether this table is formally deprecated or whether it will resume being loaded from `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`.

### R2 — Migration provenance

BI_DB_DailyZeroPnL_Stocks was migrated from Dealing_dbo via script `2024_09_16_17_30_56_BI_DB_Migration.BI_DB_DailyZeroPnL_Stocks.sql`. The JUNK migration script (`2024_09_22_17_11_39_BI_DB_Migration.JUNK_BI_DB_DailyZeroPnL_Stocks.sql`) suggests the migration may have been aborted. Confirm whether BI_DB schema is the intended long-term home for this data.

### R3 — UC target still active?

The Generic Pipeline mapping shows `copy_strategy = Append` with `frequency_minutes = 1440` but data has not advanced past 2024-02-09. Confirm whether the Generic Pipeline export to `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks` is still running and if so why rows are not advancing.

### R4 — OpenPositions column type

`OpenPositions` is typed as `money` in DDL but semantically represents a count of positions. This is inherited from the Dealing schema design. Reviewers should confirm whether this is intentional or a type mismatch.
