# Column Lineage — eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap

Generated: 2026-04-21

## Source Objects

| Object | Type | Role |
|--------|------|------|
| `eMoney_dbo.eMoneyClientBalance` | Table | Source — CheckCalc column aggregated by BalanceDateID |
| `eMoney_dbo.SP_eMoney_Client_Balance_Check_Exceptions_Gap` | Stored Procedure | ETL writer (TRUNCATE + INSERT) |
| `eMoney_dbo.SP_eMoney_ClientBalance` | Stored Procedure | Orchestrator — calls writer SP at end of daily balance check run |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | Date | eMoneyClientBalance | BalanceDateID | `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), BalanceDateID)) AS DATE)` — converts integer date key to date | 2 |
| 2 | Exceptions_Gap | eMoneyClientBalance | CheckCalc | `SUM(CheckCalc) GROUP BY BalanceDateID HAVING SUM(CheckCalc) <> 0` — CheckCalc = ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO − ClosingBalanceBO | 2 |
| 3 | UpdateDate | SP parameter | @Date | Passthrough of the @Date input parameter to the SP | 2 |

## External Lineage (UC)

UC Target: `_Not_Migrated`

This table has no Unity Catalog target. It is an operational data quality check result table, not included in the Databricks Gold layer.

## Notes

- Table is currently empty (0 rows). This is the expected state when no reconciliation exceptions are found.
- Rows appear only when `SUM(CheckCalc) <> 0` for a given BalanceDateID — i.e., when the DWH balance reconciliation detects a discrepancy.
- CheckCalc formula: `ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO`. A non-zero sum means the calculated closing balance does not equal the back-office closing balance.
