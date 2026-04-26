# BI_DB_dbo.BI_DB_DDR_CID_Level_Auxiliary_Metrics — Column Lineage

Generated: 2026-04-21 | Pipeline: Phase 10B

## Source Objects

| Source Type | Object | Role |
|-------------|--------|------|
| DWH Fact Table | DWH_dbo.Fact_SnapshotCustomer | Customer attributes, regulatory segments, flags (IsBlocked, IsCreditReportValidCB, IsValidCustomer, IsGermanBaFin, VerificationLevelID) for @dateID |
| DWH Dimension | DWH_dbo.Dim_Regulation | Resolves Regulation name |
| DWH Dimension | DWH_dbo.Dim_Country | Resolves Country name and MarketingRegionManualName (Region) |
| DWH Dimension | DWH_dbo.Dim_Label | Resolves Label name |
| DWH Dimension | DWH_dbo.Dim_PlayerLevel | Resolves PlayerLevel name |
| DWH Dimension | DWH_dbo.Dim_PlayerStatus | Resolves PlayerStatus name |
| DWH Dimension | DWH_dbo.Dim_MifidCategorization | Resolves MifidCategory name |
| DWH View | DWH_dbo.V_GermanBaFin | IsGermanBaFin flag |
| DWH Fact Table | DWH_dbo.Fact_CustomerAction | DormantFee (ActionTypeID=36 CompensationReasonID=30), SDRT (ActionTypeID=35 IsFeeDividend=3), TradingFees + TicketFees (ActionTypeID=35 IsFeeDividend=4, ActionTypeID=36 CompensationReasonID IN (117,118)) |
| DWH Fact Table | DWH_dbo.Fact_FirstCustomerAction | First action metadata per CID (FirstActionType, FirstDepositDate, FirstDepositDateID) |
| DWH Dimension | DWH_dbo.Dim_Position | Position details for first trade |
| DWH Dimension | DWH_dbo.Dim_Instrument | InstrumentTypeID for first trade (classifies Forex/Stocks/Crypto) |
| DWH Dimension | DWH_dbo.Dim_Mirror | MirrorTypeID for first copy action (classifies Copy vs CopyFund) |
| DWH Dimension | DWH_dbo.Dim_Customer | FirstDepositDate for FTDCurrentYear computation |
| BI_DB Table | BI_DB_dbo.BI_DB_DepositWithdrawFee | ConversionFees — SUM(PIPsCalculation) WHERE Date = @date |
| BI_DB Table | BI_DB_dbo.BI_DB_Daily_CreditLine | InterestFees — SUM(DailyFee) WHERE DateID = @dateID |
| ETL Writer | BI_DB_dbo.SP_DDR_Auxiliary_Metrics | Computes all auxiliary metrics and loads table via DELETE+INSERT per @dateID |

## Column Lineage

| # | Synapse Column | Source Table(s) | Source Column(s) | Transform | Tier |
|---|---------------|-----------------|------------------|-----------|------|
| 1 | CID | Fact_CustomerAction + BI_DB_DepositWithdrawFee + BI_DB_Daily_CreditLine | RealCID / CID | UNION of distinct CIDs from #fca (DormantFee), #conversionFees, #IneterstFees, #SDRT, #TradingFees, #TicketFees — assembled in #allUsers | Tier 2 |
| 2 | DateID | SP_DDR_Auxiliary_Metrics parameter | @date | CAST(CONVERT(varchar(8), @date, 112) AS INT) — YYYYMMDD int | Tier 2 |
| 3 | Regulation | Fact_SnapshotCustomer + Dim_Regulation | RegulationID | Dim name resolved via #fsc JOIN for @dateID | Tier 2 |
| 4 | IsBlocked | Fact_SnapshotCustomer | PlayerStatusID | CASE WHEN PlayerStatusID NOT IN (1,3,5,7) THEN 1 ELSE 0 | Tier 2 |
| 5 | IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough flag from #fsc | Tier 2 |
| 6 | IsGermanBaFin | V_GermanBaFin | CID | LEFT JOIN; 1 if CID appears in V_GermanBaFin for @dateID, else 0 | Tier 2 |
| 7 | IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | Passthrough flag from #fsc | Tier 2 |
| 8 | MifidCategory | Fact_SnapshotCustomer + Dim_MifidCategorization | MifidCategorizationID | Dim name resolved via #fsc JOIN | Tier 2 |
| 9 | PlayerLevel | Fact_SnapshotCustomer + Dim_PlayerLevel | PlayerLevelID | Dim name resolved via #fsc JOIN | Tier 2 |
| 10 | PlayerStatus | Fact_SnapshotCustomer + Dim_PlayerStatus | PlayerStatusID | Dim name resolved via #fsc JOIN | Tier 2 |
| 11 | FirstActionType | Fact_FirstCustomerAction + Dim_Position + Dim_Instrument + Dim_Mirror | ActionTypeID / InstrumentTypeID / MirrorTypeID | CASE: 'Forex' (ActionTypeID IN (1,39) AND InstrumentTypeID IN (1,2,4)), 'Stocks' (InstrumentTypeID IN (5,6)), 'Crypto' (InstrumentTypeID=10), 'CopyFund' (ActionTypeID=17 + MirrorTypeID=4), 'Copy' (ActionTypeID=17 no CopyFund), else 'NoAction' | Tier 2 |
| 12 | Region | Fact_SnapshotCustomer + Dim_Country | CountryID | Dim_Country.MarketingRegionManualName resolved via #fsc JOIN | Tier 2 |
| 13 | Country | Fact_SnapshotCustomer + Dim_Country | CountryID | Dim_Country.Name resolved via #fsc JOIN | Tier 2 |
| 14 | Label | Fact_SnapshotCustomer + Dim_Label | LabelID | Dim_Label.Name resolved via #fsc JOIN | Tier 2 |
| 15 | FTDCurrentYear | Dim_Customer | FirstDepositDate | CASE WHEN FirstDepositDate >= DATEADD(yy, DATEDIFF(yy, 0, @date), 0) THEN 1 ELSE 0 — 1 if FTD occurred in the same calendar year as @date | Tier 2 |
| 16 | DormantFee | Fact_CustomerAction | Amount | SUM(-Amount) WHERE ActionTypeID=36 AND CompensationReasonID=30 for @dateID. Sign negated because dormant fees are recorded as negative amounts in Fact_CustomerAction | Tier 2 |
| 17 | ConversionFees | BI_DB_DepositWithdrawFee | PIPsCalculation | SUM(PIPsCalculation) WHERE Date = @date (currency conversion fees on deposits/withdrawals) | Tier 2 |
| 18 | WalletBalanceUSD | — | — | NULL — hardcoded. Wallet balance feature was planned but commented out in SP_DDR_Auxiliary_Metrics. Always NULL in production. | Tier 2 |
| 19 | InterestFees | BI_DB_Daily_CreditLine | DailyFee | SUM(DailyFee) WHERE DateID = @dateID per CID (daily interest charged on credit line usage) | Tier 2 |
| 20 | UpdateDate | SP_DDR_Auxiliary_Metrics | — | GETDATE() at INSERT time — ETL run timestamp, not a business date. Note: DDL type is date (not datetime) | Tier 2 |
| 21 | SDRT | Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=35 AND IsFeeDividend=3 — Stamp Duty Reserve Tax, a UK regulatory tax on stock purchases | Tier 2 |
| 22 | TradingFees | Fact_CustomerAction | Amount | SUM(Amount) WHERE (ActionTypeID=35 AND IsFeeDividend=4) OR (ActionTypeID=36 AND CompensationReasonID IN (117,118)) — includes both ticket fees (stock trades) and Islamic account fees | Tier 2 |
| 23 | TicketFees | Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=35 AND IsFeeDividend=4 only — ticket fee component of TradingFees, excluding Islamic fees (CompensationReasonID 117/118). Subset of TradingFees. | Tier 2 |

## CID Universe Note

The CID universe for `BI_DB_DDR_CID_Level_Auxiliary_Metrics` differs from `BI_DB_DDR_CID_Level`:
- **SP_DDR** (#allUsers): UNION of Fact_CustomerAction (all action types) + BI_DB_Client_Balance_CID_Level_New
- **SP_DDR_Auxiliary_Metrics** (#allUsers): UNION of only the 5 specific fee actions (DormantFee, ConversionFees, InterestFees, SDRT, TradingFees, TicketFees)

This means a CID row exists in the Auxiliary table ONLY if the customer incurred at least one of these fee types on @date. Customers with zero fee activity on a given day will not appear — unlike the main DDR which includes all active customers.

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_* ───────────→ #fsc (customer attributes for @dateID)
DWH_dbo.Fact_CustomerAction (ActionTypeID=36 CR=30) → #fcaprep → #fca (DormantFee)
DWH_dbo.Fact_CustomerAction (ActionTypeID=35 IFD=3) → #SDRT_prep → #SDRT
DWH_dbo.Fact_CustomerAction (35/IFD=4, 36/CR=117-118)→ #TradingFees_prep → #TradingFees
DWH_dbo.Fact_CustomerAction (ActionTypeID=35 IFD=4) → #TicketFees_prep → #TicketFees
BI_DB_DepositWithdrawFee ────────────────────────→ #conversionFees
BI_DB_Daily_CreditLine ──────────────────────────→ #IneterstFees

UNION of all CIDs → #allUsers (fee-incurring CIDs only)

DWH_dbo.Fact_FirstCustomerAction + Dim_Position + Dim_Instrument + Dim_Mirror
  → #allDepositors → #firstActions → #CF_mirrors → #FirstActionsFinal (FirstActionType)
DWH_dbo.Dim_Customer → FTDCurrentYear computation

#allUsers LEFT JOIN all temp tables → #CIDAgg

DELETE FROM BI_DB_DDR_CID_Level_Auxiliary_Metrics WHERE DateID = @dateID
INSERT INTO BI_DB_DDR_CID_Level_Auxiliary_Metrics SELECT FROM #CIDAgg

GROUP BY #CIDAgg → #RegAgg

DELETE FROM BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics WHERE DateID = @dateID
INSERT INTO BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics SELECT FROM #RegAgg
```

## UC External Lineage

UC Target: Not in generic pipeline mapping. No Databricks Gold layer target identified.
