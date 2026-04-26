# Lineage: BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers

**Writer SP**: `BI_DB_dbo.SP_CMR_Phase2_EU_Outliers`
**Refresh**: Daily (OpsDB Priority 15). Takes @date parameter; processes one date per execution.
**Load Pattern**: DELETE WHERE Date = @date + INSERT (daily full-refresh per date)
**UC Target**: _Not_Migrated

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | ETL parameter | @date | Passthrough of @date parameter | Tier 2 |
| 2 | DateID | ETL-derived | @date | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | Tier 2 |
| 3 | ExcelOrder | ETL-hardcoded | -- | Integer 1-20 (with duplicate 13) hardcoded in SP per metric branch | Tier 2 |
| 4 | Metric | ETL-hardcoded | -- | String label hardcoded in SP per ExcelOrder. Note: two metrics share ExcelOrder 13 ('Over The Weekend Fee' and 'Lost Debt') -- SP defect producing 21 rows per date instead of 20 | Tier 2 |
| 5 | ValidToInvalid | BI_DB_dbo.BI_DB_Outliers_New | (column varies by ExcelOrder) | SUM(CASE WHEN Transition = 'Valid To Invalid' THEN MetricValue ELSE 0 END) -- balance movement for customers transitioning from valid to invalid credit report status | Tier 2 |
| 6 | InvalidToValid | BI_DB_dbo.BI_DB_Outliers_New | (column varies by ExcelOrder) | SUM(CASE WHEN Transition = 'Invalid to Valid' THEN MetricValue ELSE 0 END) -- balance movement for customers transitioning from invalid to valid credit report status | Tier 2 |
| 7 | UpdateDate | ETL-computed | -- | GETDATE() on INSERT | Propagation |

## Metric Reference (ExcelOrder to Metric to BI_DB_Outliers_New Source Column)

| ExcelOrder | Metric | Source Column in BI_DB_Outliers_New |
|---|---|---|
| 1 | Deposit Amounts | [Deposit Amounts] |
| 2 | Compensation Deposit | [Compensation Deposit] |
| 3 | GivenBonus | [GivenBonus] |
| 4 | Compensation | Compensation |
| 5 | Compensation PI | [Compensation PI] |
| 6 | Compensation To Affiliates | [Compensation To Affiliates] |
| 7 | Cashout Amounts | [Cashout Amounts] |
| 8 | Compensation Cashouts | [Compensation Cashouts] |
| 9 | Cashout Fee | [Cashout Fee] |
| 10 | Chargeback | Chargeback |
| 11 | Refund | Refund |
| 12 | ClientBalanceCommission | ClientBalanceCommission |
| 13 | Over The Weekend Fee | [Over The Weekend Fee] (SP defect: shares ExcelOrder 13 with Lost Debt) |
| 13 | Lost Debt | [Lost Debt] (SP defect: shares ExcelOrder 13 with Over The Weekend Fee) |
| 14 | Chargeback Loss | [Chargeback Loss] |
| 15 | Other Negative | [Other Negative] |
| 16 | Foreclosure | Foreclosure |
| 17 | Compensation P&L Adjustment | [Compensation PnL Adjustment] |
| 18 | Compensation DormantFee | [Compensation DormantFee] |
| 19 | ClientBalance Realized PnL | [ClientBalance Realized PnL] |
| 20 | Unrealized Commission Change | [Unrealized Commission Change] |

## Tier Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 2 | 6 | All data columns from BI_DB_Outliers_New or hardcoded in SP |
| Propagation | 1 | UpdateDate (ETL GETDATE() on insert) |

## Source Objects

- `BI_DB_dbo.BI_DB_Outliers_New` -- sole data source; provides balance movement amounts per Transition type (Valid To Invalid / Invalid to Valid) per date

## ETL Pipeline

```
BI_DB_dbo.BI_DB_Outliers_New (DateID = @dateID)
  20 UNION ALL branches (one per metric, with duplicate ExcelOrder 13)
  Inner GROUP BY: Date, DateID, Transition
  Outer pivot: SUM by Transition type into ValidToInvalid / InvalidToValid columns
  GROUP BY ExcelOrder, Metric (21 rows per date)

SP_CMR_Phase2_EU_Outliers(@date) -- daily execution
  DELETE FROM BI_DB_CMR_Phase2_EU_Outliers WHERE Date = @date
  INSERT INTO BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers
      (16,254 rows; 774 dates: 2022-01-02 to 2026-04-07)
  UC: _Not_Migrated
```
