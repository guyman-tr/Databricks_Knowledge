# Lineage: BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints

Generated: 2026-04-22 | Phase 10B

## ETL Pipeline

```
BI_DB_dbo.BI_DB_DepositWithdrawFee (conversion/PIP fees, Deposit+Withdraw transactions)
  + DWH_dbo.Fact_CustomerAction (overnight fees ActionTypeID=35, dividends IsFeeDividend=2,
    rollovers IsFeeDividend=1, SDRT IsFeeDividend=3, admin/spot fees CompensationReasonID 117/118)
  + BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level (commissions by instrument/settlement)
  + BI_DB_dbo.BI_DB_DDR_Daily_Aggregated (cashout fees, dormant fees, transfer coin fees)
  + BI_DB_dbo.BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics (interest fees)
  + BI_DB_dbo.Function_Revenue_TicketFee(@sdateID, @dateID, 0) (fixed ticket fees)
  + BI_DB_dbo.Function_Revenue_TicketFeeByPercent(@sdateID, @dateID, 0) (% ticket fees)
  + BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution (stock margin overnight fees)
  + DWH_dbo.Fact_SnapshotCustomer, Dim_Range, Dim_Country, Dim_PlayerLevel,
    Dim_Regulation, Dim_MifidCategorization, Dim_PlayerStatus, Dim_Instrument (dimension enrichment)
    |-- SP_M_Finance_Audit_Auxillary_Datapoints @date (Monthly, SB_Daily Priority 20) ---|
    |   DELETE WHERE YearMonth = YYYYMM + UNION ALL INSERT (22 metric types)             |
    v
BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints
  (12.9M rows, Jan 2023 – Mar 2026, tall/unpivot format)
  UC Target: Not Migrated
```

## Column Lineage

| # | Column | Source | Transform | Tier |
|---|--------|--------|-----------|------|
| 1 | YearMonth | SP_M_Finance_Audit_Auxillary_Datapoints | convert(VARCHAR(6), @date, 112) — YYYYMM format | Tier 2 |
| 2 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType name; 'NA' for non-instrument metrics (fees, cashout, dormant) | Tier 2 |
| 3 | Regulation | DWH_dbo.Dim_Regulation | Regulation name from dimension | Tier 2 |
| 4 | PlayerLevel | DWH_dbo.Dim_PlayerLevel | Club/PlayerLevel name from dimension | Tier 2 |
| 5 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | PlayerStatus name | Tier 2 |
| 6 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB — GROUP BY passthrough | Tier 1 |
| 7 | MifidCategory | DWH_dbo.Dim_MifidCategorization | MifidCategorization name | Tier 2 |
| 8 | Country | DWH_dbo.Dim_Country | Country name | Tier 2 |
| 9 | Metric | SP_M_Finance_Audit_Auxillary_Datapoints | Hardcoded metric name (UNION ALL branch identifier) | Tier 2 |
| 10 | Amount | Various sources | SUM of metric value from source (sign-flipped for TicketFee/TicketFeeByPercent) | Tier 2 |
| 11 | UpdateDate | SP_M_Finance_Audit_Auxillary_Datapoints | GETDATE() at insert | Tier 2 |
| 12 | IsRealFutures | DWH_dbo.Dim_Instrument | CASE WHEN IsFuture=1 THEN 1 ELSE 0; NULL for non-instrument metrics | Tier 2 |
| 13 | IsSettled | Various sources | Position settlement flag (from Fact_CustomerAction or Commission source); blank '' for non-commission metrics | Tier 2 |

## Metric Catalogue (22 metrics in Metric column)

| Metric | Source | Description |
|--------|--------|-------------|
| TotalCommissionReal | Client_Balance_Breakdown_Instrument_Level | Commission on settled (real/stock) positions |
| TotalCommissionCFD | Client_Balance_Breakdown_Instrument_Level | Commission on open (CFD) positions |
| FullTotalCommissionReal | Client_Balance_Breakdown_Instrument_Level | Full commission including maker/taker on real positions |
| FullTotalCommissionCFD | Client_Balance_Breakdown_Instrument_Level | Full commission on CFD positions |
| RealizedCommissionReal | Client_Balance_Breakdown_Instrument_Level | Realized commission on settled positions |
| RealizedCommissionCFD | Client_Balance_Breakdown_Instrument_Level | Realized commission on open positions |
| UnrealizedCommissionChangeReal | Client_Balance_Breakdown_Instrument_Level | Unrealized commission change on real positions |
| UnrealizedCommissionChangeCFD | Client_Balance_Breakdown_Instrument_Level | Unrealized commission change on CFD positions |
| TotalConversionFees | BI_DB_DepositWithdrawFee | PIP conversion fees on deposits/withdrawals |
| TotalOvernightFee | Fact_CustomerAction (ActionTypeID=35) | Overnight/swap fees |
| DividendPaid | Fact_CustomerAction (IsFeeDividend=2) | Dividends paid to customers |
| RollOverFee | Fact_CustomerAction (IsFeeDividend=1) | Rollover fees charged |
| SDRT | Fact_CustomerAction (IsFeeDividend=3) | Stamp Duty Reserve Tax |
| AdminFee | Fact_CustomerAction (CompensationReasonID=117) | Islamic finance admin fees |
| SpotAdjustFee | Fact_CustomerAction (CompensationReasonID=118) | Spot adjustment fees |
| TotalCashoutFee | BI_DB_DDR_Daily_Aggregated | Cashout processing fees |
| TotalDormantFee | BI_DB_DDR_Daily_Aggregated | Dormant account fees |
| TotalInterestFees | BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics | Interest fees charged |
| TransferCoinFee | BI_DB_DDR_Daily_Aggregated | Crypto transfer fees (InstrumentType='Crypto Currencies') |
| TicketFee | Function_Revenue_TicketFee | Fixed ticket fees (sign-flipped: -SUM) |
| TicketFeeByPercent | Function_Revenue_TicketFeeByPercent | Percentage-based ticket fees (sign-flipped) |
| StockMarginOvernightFee | BI_DB_Fact_Customer_Action_Position_Distribution | Stock margin loan overnight fees (from 2026-02-16) |

## Tier Summary

- **Tier 1**: 1 column (IsCreditReportValidCB — from DWH_dbo.Fact_SnapshotCustomer)
- **Tier 2**: 12 columns (ETL-computed or dimension lookup values)
- **UC Target**: Not Migrated

## Notes

- DDL spells "Auxillary" (double-l), not "Auxiliary". This typo appears in both the table name and SP name.
- TicketFee and TicketFeeByPercent have their signs flipped (-SUM) in the SP — negative amounts in the `Amount` column.
- IsRealFutures is NULL for metrics that don't have instrument breakdown (TotalDormantFee, TotalCashoutFee, TotalInterestFees, TotalConversionFees, TransferCoinFee, DividendPaid, SDRT, TransferCoinFee).
- IsSettled is empty string '' (not NULL) for non-commission metrics.
- BI_DB_DDR_Daily_Aggregated and BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics are blacklisted (deferred) tables but are legitimate inputs to this SP.
