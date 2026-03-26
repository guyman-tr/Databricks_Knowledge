# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Sources** | 16+ `Function_Revenue_*` TVFs (FullCommissions, Commissions, RolloverFee, CashoutFee_ExcludeRedeem, ConversionFee, DormantFee, InterestFee, SDRT, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee, Dividend, Share_Lending, CryptoToFiat_C2F, StakingFee, OptionsPlatform) |
| **ETL SP** | `SP_DDR_Fact_Revenue_Generating_Actions` |
| **Secondary Sources** | `DWH_dbo.Dim_ActionType`, `DWH_dbo.Dim_Instrument`, `BI_DB_dbo.Dim_Revenue_Metrics`, `BI_DB_dbo.BI_DB_CopyFund_Positions`, `BI_DB_dbo.V_C2P_Positions`, `DWH_dbo.Dim_Position`, `External_*_parquet` tables |
| **Generated** | 2026-03-26 |

## Lineage Chain

```
16+ Function_Revenue_* TVFs (each reads position/transaction/fee tables)
  + BI_DB_CopyFund_Positions (IsCopyFund enrichment)
  + V_C2P_Positions (IsC2P enrichment)
  + External_*_parquet (IsOpenedFromIBAN, IsClosedToIBAN, IsRecurring)
  + Dim_Position (date filtering for IBAN/closed positions)
  + Dim_ActionType (ActionType name resolution)
  + Dim_Instrument (IsFuture for AdminFee/SpotAdjust)
  + Dim_Revenue_Metrics (RevenueMetricID + CategoryID + IncludedInTotalRevenue)
  |
  |-- SP_DDR_Fact_Revenue_Generating_Actions(@date):
  |     1. Build enrichment temp tables (#c2p, #openedFromIban, #closedToIban, #isRecurring)
  |     2. Extract position-level overnight fees (Rollover, Dividend, SDRT, TicketFee, TicketFeeByPercent) → #overnights
  |     3. Extract position-level trading fees (FullCommission, Commission) → #fullcommissions, #commissions
  |     4. Extract account-level fees (AdminFee, SpotAdjust, CashoutFee, ConversionFee, DormantFee, InterestFee)
  |     5. Extract crypto fees (TransferCoinFee, C2F, Staking)
  |     6. Extract platform fees (ShareLending, Options_PFOF)
  |     7. UNION ALL → #revenue (17 streams)
  |     8. Post-UNION UPDATEs for C2F/Dividend/SDRT null handling
  |     9. DELETE/INSERT by DateID, joined to Dim_Revenue_Metrics
  |    10. DELETE/re-INSERT Options (RevenueMetricID=18, full history)
  |    11. DELETE/re-INSERT Staking (RevenueMetricID=12, current month)
  v
BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions (3.1B rows, CID × Metric × flags grain)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from revenue function |
| **ETL-computed** | Derived/calculated by SP logic |
| **join-enriched** | Joined from secondary source during ETL |
| **coerce** | ISNULL null-to-sentinel coercion applied |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| DateID | Revenue functions | DateID | passthrough | Direct (except Staking: DATEADD(MONTH,1,...)) | DELETE key |
| Date | — | — | ETL-computed | `@date` parameter (main); computed from DateID (staking) | |
| RealCID | Revenue functions | RealCID/CID | passthrough | Direct | Distribution key; some functions use CID |
| ActionTypeID | Revenue functions / literal | ActionTypeID | passthrough+coerce | From functions for trading fees; NULL/-1 for non-trading fees; `ISNULL(...,-1)` | -1 = not applicable |
| ActionType | Dim_ActionType / literal | Name | join-enriched/ETL-computed | `dat.Name` for commissions; literal for others ('Rollover','SDRT','TicketFee','Dividends','CashoutFeeExclRedeem','ConversionFee','DormantFee','InterestFee','Redeem','C2F','Staking','ShareLending','AdminFee','SpotPriceAdjustment') | |
| InstrumentTypeID | Revenue functions | InstrumentTypeID | passthrough+coerce | Direct from functions; NULL/-1 for account-level fees; `ISNULL(...,-1)` | -1 = not applicable |
| IsSettled | Revenue functions | IsSettled | passthrough+coerce | Direct; NULL/-1 for account-level fees; `ISNULL(...,-1)` | |
| IsCopy | Revenue functions | MirrorID | ETL-computed+coerce | `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END`; NULL/-1 for account-level fees; `ISNULL(...,-1)` | |
| Metric | — | — | ETL-computed | Literal per revenue stream: 'FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','TicketFeeByPercent','CashoutFeeExclRedeem','ConversionFee','DormantFee','InterestFee','TransferCoinFee','AdminFee','SpotPriceAdjustment','ShareLending','CryptoToFiatFee','StakingLagOneMonth','Options_PFOF' | Key discriminator |
| Amount | Revenue functions | Various fee columns | ETL-computed | `SUM(frfc.TotalFullCommission)`, `SUM(frrf.RolloverFee)`, `SUM(frcf.ConversionFee)`, etc. per stream | Aggregated per group |
| CountTransactions | — | — | ETL-computed+coerce | `COUNT(RealCID)` or `SUM(CountTransactions)`; `ISNULL(...,0)`; NULL for ShareLending/Staking | |
| IncludedInTotalRevenue | Dim_Revenue_Metrics / literal | IncludedInTotalRevenue | join-enriched | From `Dim_Revenue_Metrics` for main INSERT; literal for Options/Staking; SDRT forced to 0 | Key filter for total revenue |
| CountAsActiveTrade | — | — | ETL-computed+coerce | `CASE WHEN ActionTypeID IN (1,39) AND ISNULL(IsAirDrop,0) = 0 THEN 1 ELSE 0 END` for commissions; 0 for all others; `ISNULL(...,0)` | Only Open/Close non-airdrop trades |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL timestamp |
| IsBuy | Revenue functions | IsBuy | passthrough+coerce | Direct; NULL/-1 for non-position fees; `ISNULL(...,-1)`; Dividends: override 1 if Amount>0, 0 if Amount<0; C2F: forced -1 | |
| IsLeveraged | Revenue functions | Leverage | ETL-computed+coerce | `CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`; NULL/-1 for non-position fees; `ISNULL(...,-1)` | |
| IsFuture | Revenue functions / Dim_Instrument | IsFuture | passthrough+coerce | Direct from functions or `di.IsFuture` for AdminFee/SpotAdjust; `ISNULL(...,-1)` | |
| IsCopyFund | BI_DB_CopyFund_Positions | PositionID | join-enriched+coerce | `CASE WHEN bdcfp.PositionID IS NOT NULL THEN 1 ELSE 0 END`; `ISNULL(...,-1)` | |
| IsOpenedFromIBAN | External_*_opened_from_iban_parquet | PositionID | join-enriched+coerce | UPDATE SET 1 when matched by PositionID; filtered by OpenDateID <= @dateID; `ISNULL(...,-1)` | |
| IsClosedToIBAN | External_*_closed_to_iban_parquet | PositionID | join-enriched+coerce | UPDATE SET 1 when matched by PositionID; filtered by CloseDateID <= @dateID; `ISNULL(...,-1)` | |
| IsRecurring | External_bi_db_recurringinvestment_positions_parquet | PositionID | join-enriched+coerce | UPDATE SET 1 when matched by PositionID; `ISNULL(...,-1)` | |
| IsAirDrop | Revenue functions | IsAirDrop | passthrough+coerce | Direct; `ISNULL(...,-1)` | |
| IsSQF | Revenue functions / Function_Instrument_Snapshot_Enriched | IsSQF | passthrough+coerce | Direct from functions; join-enriched for Dividends; NULL for SDRT; `ISNULL(...,-1)` | |
| RevenueMetricID | Dim_Revenue_Metrics | RevenueMetricID | join-enriched | `drm.RevenueMetricID` via Metric text match; 12=Staking, 18=Options | Enables ID-based querying |
| RevenueMetricCategoryID | Dim_Revenue_Metrics | RevenueMetricCategoryID | join-enriched | `drm.RevenueMetricCategoryID` via Metric text match; 4=Staking, 5=Options | Revenue category grouping |
| IsMarginTrade | Revenue functions | IsMarginTrade | passthrough+coerce | Direct; `ISNULL(...,-1)`; forced 0 for SDRT and Options_PFOF | |
| IsC2P | V_C2P_Positions | PositionID | join-enriched+coerce | `CASE WHEN c.PositionID IS NOT NULL THEN 1 ELSE 0 END`; `ISNULL(...,-1)` | Copy-to-Portfolio flag |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough+coerce** | 5 |
| **ETL-computed** | 5 |
| **ETL-computed+coerce** | 5 |
| **Join-enriched** | 4 |
| **Join-enriched+coerce** | 7 |
| **Passthrough** | 1 |
| **Total** | 27 |
