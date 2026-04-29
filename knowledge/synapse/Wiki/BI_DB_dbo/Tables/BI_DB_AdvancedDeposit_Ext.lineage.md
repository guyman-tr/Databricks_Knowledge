# Column Lineage: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| (unknown — no writer SP found) | — | — | Table is empty (0 rows), no automated ETL writer exists in SSDT repo |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | DepositID | Unknown | — | Likely from Billing.Deposit | Tier 4 |
| 2 | CID | Unknown | — | Customer ID | Tier 4 |
| 3-47 | (all columns) | Unknown | — | No SP to trace | Tier 4 |

## Lineage Notes

- **TABLE IS EMPTY (0 rows)**. No writer SP exists in the SSDT repo.
- Column names suggest this was an extended deposit analysis table combining Billing.Deposit data with customer demographics, channel attribution, credit card details, and payment status lookups.
- A backup cleanup script exists from 2024-11-17, suggesting the table was active before that date.
- The "_Ext" suffix typically indicates an "extended" version with denormalized lookup columns.
