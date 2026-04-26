# Lineage: BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance

**Writer SP**: `BI_DB_dbo.SP_CMR_Phase2_ClientBalance`
**Refresh**: Daily (OpsDB Priority 15). Takes @date parameter; processes one date per execution.
**Load Pattern**: DELETE WHERE Date = @date + INSERT (daily full-refresh per date)
**UC Target**: _Not_Migrated

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Date | Passthrough from CBCAN group key | Tier 2 |
| 2 | DateID | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | DateID | Passthrough from CBCAN group key; derived as CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | Tier 2 |
| 3 | ExcelOrder | ETL-hardcoded | — | Integer 1-34 hardcoded in SP per metric type; controls report row ordering for Excel-style output | Tier 2 |
| 4 | Metric | ETL-hardcoded | — | String label hardcoded in SP per ExcelOrder (e.g., 'Opening Balace', 'Deposit Amounts', ... 'Gap'). Note: 'Opening Balace' and 'Closing Balace' are SP-level typos (missing second 'n') | Tier 2 |
| 5 | MetricValue | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | (column varies by ExcelOrder) | SUM(ISNULL(source_column, 0)) aggregated by Regulation, PlayerStatus, IsCreditReportValidCB, AccountType, IsEtoroTradingCID. Each Metric maps to one CBCAN column. Rows 33 (Cycle Calculation) and 34 (Gap) are computed. | Tier 2 |
| 6 | UpdateDate | ETL-computed | — | GETDATE() on INSERT | Propagation |
| 7 | Regulation | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Regulation | Passthrough from CBCAN; regulatory entity name string | Tier 2 |
| 8 | PlayerStatus | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | PlayerStatus | Passthrough from CBCAN; customer account status string | Tier 2 |
| 9 | IsCreditReportValidCB | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | IsCreditReportValidCB | Passthrough from CBCAN; 0 or 1 | Tier 2 |
| 10 | AccountType | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | AccountType | Passthrough from CBCAN; customer account type string | Tier 2 |
| 11 | IsEtoroTradingCID | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | IsEtoroTradingCID | Passthrough from CBCAN; 0 or 1 | Tier 2 |

## Metric Reference (ExcelOrder to Metric to CBCAN Source Column)

| ExcelOrder | Metric (stored value) | CBCAN Source Column | Notes |
|---|---|---|---|
| 1 | Opening Balace | OpeningBalance | SP typo: missing second n in Balance |
| 2 | Deposit Amounts | Deposits | |
| 3 | Compensation Deposit | CompensationDeposit | |
| 4 | UsedBonus | UsedBonus | |
| 5 | Compensation | Compensation | |
| 6 | Compensation PI | CompensationPI | Popular Investor compensation |
| 7 | Compensation To Affiliates | CompensationToAffiliate | |
| 8 | NWA Adjustment | NWAAdjustment | Net Worth Adjustment |
| 9 | Negative Refill Compensation | NegativeRefill | |
| 10 | Cashout Amount | Cashouts | |
| 11 | Transfer Coins | TransferCoins | |
| 12 | Transfer coins Fee | TransferCoinFees | |
| 13 | Compensation Cashouts | CompensationCashouts | |
| 14 | Cashout Fee | CashoutFee | |
| 15 | Chargeback | Chargeback | |
| 16 | Refund | Refund | |
| 17 | ClientBalanceCommission | ClientBalanceCommission | |
| 18 | Overnight Fees | OvernightFee | |
| 19 | DividendsPaid | DividendsPaid | |
| 20 | Lost Debt | LostDebt | |
| 21 | Chargeback Loss | ChargebackLoss | |
| 22 | Other Negative | OtherNegatives | |
| 23 | Foreclosure | Foreclosure | |
| 24 | Compensation P&L Adjustment | CompensationPnLAdjustments | |
| 25 | Compensation DormantFee | CompensationDormantFee | |
| 26 | ClientBalance Realized PnL | ClientBalanceRealizedPnL | |
| 27 | Unrealized Commission Change | UnrealizedCommissionChange | |
| 28 | Unrealized P&L Change | UnrealizedPnLChange | |
| 29 | NetActualNWATransfer | NetTransfersNWA | |
| 30 | NetLiabilityTransfer | NetTransfersLiability | |
| 31 | NetUnRelizedPnLTransfer | NetTransfersUnrealizedPnL | |
| 32 | Closing Balace | ClosingBalance | SP typo: missing second n in Balance |
| 33 | Cycle Calculation | (computed) | SUM of all inflow/outflow components; derived in SP |
| 34 | Gap | (computed) | ClosingBalance minus Cycle Calculation; reconciliation check (should = 0) |

## Tier Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 2 | 10 | All columns from CBCAN (passthrough group keys or SUM aggregations of CBCAN columns) |
| Propagation | 1 | UpdateDate (ETL GETDATE() on insert) |

## Source Objects

- `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` - sole data source; provides all balance component columns and dimension keys

## ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New (CBCAN, DateID = @dateID)
  |-- 34 UNION ALL branches, each selecting one metric row per dimension group --|
  v
#cb (temp table: Date, DateID, ExcelOrder, Metric, MetricValue,
                 Regulation, PlayerStatus, IsCreditReportValidCB, AccountType, IsEtoroTradingCID)
  Note: Club from CBCAN used in inner GROUP BY but dropped in outer GROUP BY

SP_CMR_Phase2_ClientBalance(@date) -- daily execution
  DELETE FROM BI_DB_CMR_Phase2_ClientBalance WHERE Date = @date
  INSERT INTO BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance
      (19.5M rows; 1564 dates: 2021-08-13 to 2026-04-12)
  UC: _Not_Migrated
```
