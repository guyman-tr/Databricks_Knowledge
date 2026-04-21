# Column Lineage — eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance

Generated: 2026-04-21

## Source Objects

| Object | Type | Role |
|--------|------|------|
| `eMoney_dbo.eMoneyClientBalance` | Table | Source — OpeningBalanceGAP column aggregated by BalanceDateID |
| `eMoney_dbo.SP_eMoney_Client_Balance_Check_Opening_Balance` | Stored Procedure | ETL writer (TRUNCATE + INSERT) |
| `eMoney_dbo.SP_eMoney_ClientBalance` | Stored Procedure | Orchestrator — calls writer SP at end of daily balance check run |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | Date | eMoneyClientBalance | BalanceDateID | `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), BalanceDateID)) AS DATE)` — converts integer date key to date | 2 |
| 2 | Openning_Balance_Gap | eMoneyClientBalance | OpeningBalanceGAP | `SUM(OpeningBalanceGAP) GROUP BY BalanceDateID HAVING SUM(OpeningBalanceGAP) <> 0` — OpeningBalanceGAP = CASE WHEN oc.AccountId IS NULL THEN 0 ELSE (oc.OpeningBalanceByCB − b.OpeningBalance) END | 2 |
| 3 | UpdateDate | SP parameter | @Date | Passthrough of the @Date input parameter to the SP | 2 |

## External Lineage (UC)

UC Target: `_Not_Migrated`

This table has no Unity Catalog target. It is an operational data quality check result table, not included in the Databricks Gold layer.

## Notes

- Table is currently empty (0 rows). This is the expected state when no opening balance discrepancies are detected.
- Rows appear only when `SUM(OpeningBalanceGAP) <> 0` for a given BalanceDateID.
- OpeningBalanceGAP formula: `OpeningBalanceByCB − OpeningBalance` per account. When the currency-balance system's opening balance disagrees with the BO opening balance, a non-zero gap exists.
- Column name `Openning_Balance_Gap` contains a spelling error (double 'n' in "Openning") — preserved as-is from the DDL and SP.
