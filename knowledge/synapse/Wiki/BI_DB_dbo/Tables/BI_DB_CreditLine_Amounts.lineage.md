# BI_DB_dbo.BI_DB_CreditLine_Amounts — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|---------------|-------------|--------------|----------|
| 1 | BI_DB_dbo.SP_Daily_CreditLine | Stored Procedure | Reader — LEFT JOINs this table to look up Cost by CreditLine amount | SP code line 144: `LEFT JOIN BI_DB_dbo.BI_DB_CreditLine_Amounts t ON a.TotalCLAmount = t.CreditLine` |
| 2 | BI_DB_dbo.BI_DB_Daily_CreditLine | Table | Downstream consumer — receives `t.Cost AS MonthlyTableFeeCost` via SP_Daily_CreditLine | SP code line 137: `t.Cost AS MonthlyTableFeeCost` |

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CreditLine | — | — | Static reference data. No SP populates this table; manually maintained lookup key. | Tier 3 |
| 2 | Cost | — | — | Static reference data. No SP populates this table; manually maintained fee amount. | Tier 3 |
| 3 | UpdateDate | — | — | Static reference data. No SP populates this table; placeholder timestamp (all NULL). | Tier 3 |

## Notes

- This table is a **static reference/lookup** with 13 manually maintained rows.
- No stored procedure writes to this table (confirmed: no INSERT/UPDATE statements found targeting BI_DB_CreditLine_Amounts in the entire SSDT project).
- SP_Daily_CreditLine is the only consumer, using it as a fee schedule to map credit line amounts to monthly costs.
- The commented-out code in SP_Daily_CreditLine (lines 74–88) shows these values were originally hardcoded in a table variable `@Tablefee`.
