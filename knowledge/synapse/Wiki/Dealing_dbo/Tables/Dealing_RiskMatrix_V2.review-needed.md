# Review Notes — Dealing_dbo.Dealing_RiskMatrix_V2

**Status**: ⚠️ STALE — single snapshot 2024-06-02; no active ETL

## Items Requiring Human Review

1. **No writer SP found**: The ETL source for this table is unknown. Identify who created the table and whether there is a Databricks notebook, Python script, or ad-hoc query that populated it.

2. **One-time or intended periodic?**: Confirm whether this was a one-time analytical run or a table that was supposed to be refreshed daily/weekly. If periodic, a writer SP needs to be created.

3. **HEAP storage**: Unusual for a production table. If intended as ongoing, should be migrated to a CLUSTERED INDEX (likely on PositionsTime).

4. **Scenario column quoting**: Column names include special characters (`[UnitsNOP+1%]`, `[UnitsNOP-100%]` etc.). Confirm all consumers bracket-quote these columns correctly.

5. **Table retention decision**: Given 9+ months of staleness and unknown ETL, confirm whether this table should be decommissioned or if a refresh is planned.
