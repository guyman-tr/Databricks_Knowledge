# BI_DB_dbo.BI_DB_DailyCopyRevenue — Column Lineage

**Generated**: 2026-04-22 | **Writer SP**: SP_CID_DailyCopyRevenue | **Batch**: 20

## Summary

Daily DELETE+INSERT copy trading revenue aggregated at Date × ParentCID (Popular Investor) grain.
Population = valid depositor copiers (Fact_SnapshotCustomer IsDepositor=1, IsValidCustomer=1 at @date). Revenue attributed to the ParentCID (Guru) being copied.
Commission uses a 3-case UNION logic based on position open/close dates relative to @date; rollover fees from Fact_CustomerAction ActionTypeID=35.
Crypto TicketFeeByPercent added 2025-10-26 via Function_Revenue_TicketFeeByPercent.
Sources: DWH_dbo.Fact_SnapshotCustomer (population), DWH_dbo.Dim_Mirror (copier→guru mapping),
DWH_dbo.Dim_Position (commissions), DWH_dbo.Fact_CustomerAction (rollover), DWH_dbo.Dim_Instrument (type classification),
BI_DB_dbo.Function_Revenue_TicketFeeByPercent (crypto ticket fees).

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | @date parameter | — | Direct assignment of SP input parameter (the reporting date). | Tier 2 — SP_CID_DailyCopyRevenue |
| 2 | DateID | @date parameter | — | CAST(CONVERT(VARCHAR(8), @BeginOfDay, 112) AS INT) — YYYYMMDD integer of @date. Clustering key for DELETE+INSERT pattern. | Tier 2 — SP_CID_DailyCopyRevenue |
| 3 | ParentCID | DWH_dbo.Dim_Mirror | ParentCID | dm.ParentCID — the Popular Investor (Guru) being copied. Groups all copier-side activity by the PI they follow on @date. | Tier 2 — SP_CID_DailyCopyRevenue |
| 4 | GuruStatusID | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | fsc.GuruStatusID at @date via #CIDs0 → final JOIN on c0.CID=ParentCID. Raw dimension ID; join to Dim_GuruStatus for label. | Tier 3 — DWH_dbo.Fact_SnapshotCustomer |
| 5 | CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | fsc.CountryID at @date via #CIDs0. Raw dimension ID; join to Dim_Country for country name. | Tier 3 — DWH_dbo.Fact_SnapshotCustomer |
| 6 | AccountTypeID | DWH_dbo.Fact_SnapshotCustomer | AccountTypeID | fsc.AccountTypeID at @date via #CIDs0. Raw dimension ID; join to Dim_AccountType for label (e.g., Retail, Professional). | Tier 3 — DWH_dbo.Fact_SnapshotCustomer |
| 7 | Revenue_Copy | DWH_dbo.Dim_Position + DWH_dbo.Fact_CustomerAction + BI_DB_dbo.Function_Revenue_TicketFeeByPercent | FullCommissionOnClose, FullCommissionByUnits, Amount, TicketFeeByPercent | SUM(FullCommission_Copy) + SUM(RollOverFee) + SUM(TicketFeeByPercent_Real_Crypto) + SUM(TicketFeeByPercent_CFD_Crypto). Total copy trading revenue per ParentCID per day. Equals sum of all instrument-type Revenue_* columns. Commission uses 3-case UNION logic (see wiki §2.2). | Tier 2 — SP_CID_DailyCopyRevenue |
| 8 | Revenue_Real_Stocks | DWH_dbo.Dim_Position + DWH_dbo.Fact_CustomerAction | FullCommissionOnClose, FullCommissionByUnits, Amount | SUM(FullCommission_Real_Stocks_Lev1) + SUM(RollOverFee_Real_Stocks). InstrumentTypeID IN (5,6), Leverage=1, IsBuy=1 (long real stock positions). | Tier 2 — SP_CID_DailyCopyRevenue |
| 9 | Revenue_CFD_Stocks | DWH_dbo.Dim_Position + DWH_dbo.Fact_CustomerAction | FullCommissionOnClose, FullCommissionByUnits, Amount | SUM(FullCommission_CFD_Stocks_LevCFD) + SUM(RollOverFee_CFD_Stocks). InstrumentTypeID IN (5,6), (Leverage>1 OR IsBuy=0) (leveraged or short stock positions). | Tier 2 — SP_CID_DailyCopyRevenue |
| 10 | Revenue_Real_Crypto | DWH_dbo.Dim_Position + DWH_dbo.Fact_CustomerAction + BI_DB_dbo.Function_Revenue_TicketFeeByPercent | FullCommissionOnClose, FullCommissionByUnits, Amount, TicketFeeByPercent | SUM(FullCommission_Real_Crypto) + SUM(RollOverFee_Real_Crypto) + SUM(TicketFeeByPercent_Real_Crypto). InstrumentTypeID=10, IsSettled=1. TicketFeeByPercent added 2025-10-26. | Tier 2 — SP_CID_DailyCopyRevenue |
| 11 | Revenue_CFD_Crypto | DWH_dbo.Dim_Position + DWH_dbo.Fact_CustomerAction + BI_DB_dbo.Function_Revenue_TicketFeeByPercent | FullCommissionOnClose, FullCommissionByUnits, Amount, TicketFeeByPercent | SUM(FullCommission_CFD_Crypto) + SUM(RollOverFee_CFD_Crypto) + SUM(TicketFeeByPercent_CFD_Crypto). InstrumentTypeID=10, IsSettled=0. TicketFeeByPercent added 2025-10-26. | Tier 2 — SP_CID_DailyCopyRevenue |
| 12 | Revenue_FX | DWH_dbo.Dim_Position + DWH_dbo.Fact_CustomerAction | FullCommissionOnClose, FullCommissionByUnits, Amount | SUM(FullCommission_FX) + SUM(RollOverFee_FX). InstrumentTypeID=1 (FX pairs). | Tier 2 — SP_CID_DailyCopyRevenue |
| 13 | Revenue_Comm | DWH_dbo.Dim_Position + DWH_dbo.Fact_CustomerAction | FullCommissionOnClose, FullCommissionByUnits, Amount | SUM(FullCommission_Comm) + SUM(RollOverFee_Comm). InstrumentTypeID=2 (commodities). | Tier 2 — SP_CID_DailyCopyRevenue |
| 14 | Revenue_Ind | DWH_dbo.Dim_Position + DWH_dbo.Fact_CustomerAction | FullCommissionOnClose, FullCommissionByUnits, Amount | SUM(FullCommission_Ind) + SUM(RollOverFee_Ind). InstrumentTypeID=4 (indices). | Tier 2 — SP_CID_DailyCopyRevenue |
| 15 | UpdateDate | — | — | GETDATE() at ETL execution time. | Tier 2 — SP_CID_DailyCopyRevenue |

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (IsDepositor=1, IsValidCustomer=1 at @date) → #CIDs0/#CIDs (copier population)
DWH_dbo.Dim_Mirror (OpenDateID<=@date, CloseDateID=0 or >=@date) → #mirror (copier→guru mapping)
DWH_dbo.Dim_Position (MirrorID!=0, open or closed on @date) → #pos (copy positions)
BI_DB_dbo.Function_Revenue_TicketFeeByPercent(@startDateINT,@endDateINT,1) → #tfbp (crypto ticket fees)
DWH_dbo.Dim_Instrument → #All_Positions (classify by InstrumentTypeID)
DWH_dbo.Fact_CustomerAction (ActionTypeID=35, IsFeeDividend=1 → rollover fees)
  |
  |-- 3-case UNION commission logic:
  |   Case 1: Opened+closed on @date → FullCommissionOnClose
  |   Case 2: Opened before, closed on @date → FullCommissionOnClose - FullCommissionByUnits
  |   Case 3: Opened on @date, still open → FullCommissionByUnits
  |   + Rollover → UNION ALL with -fca.Amount (ActionTypeID=35)
  |
  v
#CopyTotalRevenue (aggregated by ParentCID)
  JOIN #CIDs0 (c0.CID = ParentCID → GuruStatusID, CountryID, AccountTypeID)
  |
  |-- SP_CID_DailyCopyRevenue @date
  |     DELETE WHERE DateID=@startDateINT
  |     + INSERT
  v
BI_DB_dbo.BI_DB_DailyCopyRevenue (7.2M rows, 2020-01-01 to 2026-04-12, 2,294 dates, 58,592 distinct PIs)
  |-- UC Target: _Not_Migrated ---|
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 12 | Date, DateID, ParentCID, Revenue_Copy, Revenue_Real_Stocks, Revenue_CFD_Stocks, Revenue_Real_Crypto, Revenue_CFD_Crypto, Revenue_FX, Revenue_Comm, Revenue_Ind, UpdateDate |
| Tier 3 | 3 | GuruStatusID, CountryID, AccountTypeID |
| Tier 4 | 0 | — |
