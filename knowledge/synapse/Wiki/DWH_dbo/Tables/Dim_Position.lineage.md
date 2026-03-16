# Column Lineage: DWH_dbo.Dim_Position

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Position` |
| **UC Target** | `main.dwh.dim_position` |
| **Primary Source** | `Trade.PositionTbl` (etoro) |
| **ETL SP** | `SP_Dim_Position_Populate` |
| **Secondary Sources** | `Trade.PositionTreeInfo`, `Trade.OpenPositionEndOfDay`, `Trade.PositionAirdropLog`, `BackOffice.Customer`, `PriceLog`, `Trade.HBCExecutionLog`, `History.Cost` |
| **Generic Pipeline** | NOT in mapping view — uses custom DWH-to-UC pipeline |
| **Generated** | 2026-03-08 | Updated: 2026-03-13 |

## Lineage Chain

```
Production                    Generic Pipeline           Synapse DWH
───────────────────────       ──────────────────         ──────────────────
Trade.PositionTbl        ──►  bronze_etoro_trade_        SP_Dim_Position_
Trade.PositionTreeInfo        positiontbl           ──►  Populate        ──►  Dim_Position
Trade.OpenPositionEndOfDay    (Override, daily)          + ReOpen
BackOffice.Customer                                     + PartialClose
PriceLog snapshots                                      + IsPartialCloseParent
Trade.HBCExecutionLog                                   + IsCopyFundPosition
Trade.PositionAirdropLog
History.Cost
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source. Same name, same value. |
| **rename** | Column copied as-is but with a different name in DWH. |
| **cast/convert** | Type conversion only (e.g., cents→dollars, datetime→int). |
| **ETL-computed** | Value derived or calculated by the ETL SP. Not in any single source. |
| **join-enriched** | Value joined from a secondary source table during ETL. |
| **SP-adjusted** | Value starts as passthrough but is modified by a post-load SP. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PositionID | Trade.PositionTbl | PositionID | passthrough | PK + HASH distribution key |
| CID | Trade.PositionTbl | CID | passthrough | |
| CurrencyID | Trade.PositionTbl | CurrencyID | passthrough | Always 1 (USD) |
| ProviderID | Trade.PositionTbl | ProviderID | passthrough | Always 1 |
| InstrumentID | Trade.PositionTbl | InstrumentID | passthrough | |
| HedgeID | Trade.PositionTbl | HedgeID | passthrough | |
| HedgeServerID | Trade.PositionTbl | HedgeServerID | passthrough | |
| Leverage | Trade.PositionTbl | Leverage | passthrough | |
| Amount | Trade.PositionTbl | Amount | SP-adjusted | Updated by SP_Dim_Position_PartialCloseChild on partial close |
| AmountInUnitsDecimal | Trade.PositionTbl | AmountInUnitsDecimal | SP-adjusted | Updated by SP_Dim_Position_PartialCloseChild |
| LotCountDecimal | Trade.PositionTbl | LotCountDecimal | SP-adjusted | Updated by SP_Dim_Position_PartialCloseChild |
| UnitMargin | Trade.PositionTbl | UnitMargin | passthrough | |
| InitForexRate | Trade.PositionTbl | InitForexRate | passthrough | |
| NetProfit | Trade.PositionTbl | NetProfit | cast/convert | ROUND(value / 100, 2) — cents to USD |
| SpreadedPipBid | Trade.PositionTbl | SpreadedPipBid | passthrough | |
| SpreadedPipAsk | Trade.PositionTbl | SpreadedPipAsk | passthrough | |
| IsBuy | Trade.PositionTbl | IsBuy | passthrough | |
| CloseOnEndOfWeek | Trade.PositionTreeInfo | CloseOnEndOfWeek | join-enriched | Joined via PositionID |
| EndOfWeekFee | Trade.PositionTbl | EndOfWeekFee | SP-adjusted | Reduced on partial close |
| Commission | Trade.PositionTbl | Commission | passthrough | |
| CommissionOnClose | Trade.PositionTbl | CommissionOnClose | SP-adjusted | Adjusted by SP_Dim_Position_ReOpen for reopened positions |
| OpenOccurred | Trade.PositionTbl | Occurred | rename | Production column named "Occurred" |
| CloseOccurred | Trade.PositionTbl | CloseOccurred | passthrough | 1900-01-01 sentinel for open positions |
| ParentPositionID | Trade.PositionTbl | ParentPositionID | passthrough | Sentinel 1 = independent |
| OrigParentPositionID | Trade.PositionTbl | OrigParentPositionID | passthrough | |
| MirrorID | Trade.PositionTbl | MirrorID | passthrough | |
| IsOpenOpen | Trade.PositionTbl | IsOpenOpen | passthrough | |
| OpenDateID | — | — | ETL-computed | CONVERT(int, CONVERT(varchar, OpenOccurred, 112)) |
| CloseDateID | — | — | ETL-computed | CONVERT(int, CONVERT(varchar, CloseOccurred, 112)); 0 if open |
| RegulationIDOnOpen | BackOffice.Customer | RegulationID | join-enriched | Joined via CID at ETL time |
| PlatformTypeID | Trade.PositionTbl | PlatformTypeID | passthrough | Always NULL in DWH |
| PositionSegment | Trade.PositionTbl | PositionSegment | passthrough | Always NULL in DWH |
| Volume | — | — | ETL-computed | ROUND(Units * Price * ConversionRate). Pro-rated on partial close |
| UpdateDate | — | — | ETL-computed | GETUTCDATE() at ETL run time |
| OpenInd | Trade.PositionTbl | OpenInd | passthrough | |
| SpreadedCommission | Trade.PositionTbl | SpreadedCommission | passthrough | |
| EndForexRate | Trade.PositionTbl | EndForexRate | passthrough | |
| LastOpConversionRate | Trade.PositionTbl | LastOpConversionRate | passthrough | |
| LimitRate | Trade.PositionTreeInfo | LimitRate | join-enriched | Joined via PositionID |
| StopRate | Trade.PositionTreeInfo | StopRate | join-enriched | Joined via PositionID |
| ClosePositionReasonID | Trade.PositionTbl | ClosePositionReasonID | passthrough | |
| TreeID | Trade.PositionTbl | TreeID | passthrough | |
| FullCommission | Trade.PositionTbl | FullCommission | passthrough | |
| FullCommissionOnClose | Trade.PositionTbl | FullCommissionOnClose | SP-adjusted | Adjusted by SP_Dim_Position_ReOpen |
| IsComputeForHedge | Trade.PositionTbl | IsComputeForHedge | passthrough | |
| InitialAmountCents | Trade.PositionTbl | InitialAmountCents | passthrough | Never updated |
| RedeemStatus | Trade.PositionTbl | RedeemStatus | passthrough | |
| RedeemID | Trade.PositionTbl | RedeemID | passthrough | |
| ReopenForPositionID | — | — | ETL-computed | Set by SP_Dim_Position_ReOpen |
| IsReOpen | — | — | ETL-computed | Set by SP_Dim_Position_ReOpen. Default 0 |
| CommissionOnCloseOrig | — | — | ETL-computed | Original CommissionOnClose before reopen adjustment |
| FullCommissionOnCloseOrig | — | — | ETL-computed | Original FullCommissionOnClose before reopen adjustment |
| OriginalPositionID | — | — | ETL-computed | Set by SP_Dim_Position_PartialCloseChild |
| IsPartialCloseParent | — | — | ETL-computed | Set by SP_Dim_Position_IsPartialCloseParent |
| IsPartialCloseChild | — | — | ETL-computed | Set by SP_Dim_Position_PartialCloseChild |
| InitialUnits | Trade.PositionTbl | InitialUnits | passthrough | Never updated |
| IsPartialCloseChildFromReOpen | — | — | ETL-computed | Set by SP_Dim_Position_ReOpen |
| IsDiscounted | Trade.PositionTreeInfo | IsDiscounted | join-enriched | Joined via PositionID |
| IsSettled | Trade.PositionTbl | IsSettled | passthrough | Legacy flag |
| VolumeOnClose | — | — | ETL-computed | Same as Volume but at close-time values |
| CommissionByUnits | — | — | ETL-computed | (AmountInUnitsDecimal/InitialUnits)*Commission |
| FullCommissionByUnits | — | — | ETL-computed | (AmountInUnitsDecimal/InitialUnits)*FullCommission |
| IsCopyFundPosition | — | — | ETL-computed | Set by SP_Dim_Position_IsCopyFundPosition |
| LastOpPriceRateID | Trade.PositionTbl | LastOpPriceRateID | passthrough | |
| IsAirDrop | Trade.PositionAirdropLog | — | join-enriched | EXISTS check against PositionAirdropLog |
| InitForexPriceRateID | Trade.PositionTbl | InitForexPriceRateID | passthrough | |
| EndForexPriceRateID | Trade.PositionTbl | EndForexPriceRateID | passthrough | |
| InitForex_Ask | PriceLog | Ask | join-enriched | Joined via InitForexPriceRateID |
| InitForex_Bid | PriceLog | Bid | join-enriched | Joined via InitForexPriceRateID |
| InitForex_AskSpreaded | PriceLog | AskSpreaded | join-enriched | Joined via InitForexPriceRateID |
| InitForex_BidSpreaded | PriceLog | BidSpreaded | join-enriched | Joined via InitForexPriceRateID |
| InitForex_USDConversionRate | PriceLog | USDConversionRate | join-enriched | Joined via InitForexPriceRateID |
| EndForex_Ask | PriceLog | Ask | join-enriched | Joined via EndForexPriceRateID |
| EndForex_Bid | PriceLog | Bid | join-enriched | Joined via EndForexPriceRateID |
| EndForex_AskSpreaded | PriceLog | AskSpreaded | join-enriched | Joined via EndForexPriceRateID |
| EndForex_BidSpreaded | PriceLog | BidSpreaded | join-enriched | Joined via EndForexPriceRateID |
| EndForex_USDConversionRate | PriceLog | USDConversionRate | join-enriched | Joined via EndForexPriceRateID |
| InitExecutionID | Trade.PositionTbl | InitExecutionID | passthrough | |
| EndExecutionID | Trade.PositionTbl | EndExecutionID | passthrough | |
| InitConversionRate | Trade.PositionTbl | InitConversionRate | passthrough | |
| InitConversionRateID | Trade.PositionTbl | InitConversionRateID | passthrough | |
| CloseMarketPriceRateID | Trade.PositionTbl | CloseMarketPriceRateID | passthrough | |
| InitHedgeType | Trade.HBCExecutionLog | — | join-enriched | CBH vs HBC determined from HBCExecutionLog match on InitExecutionID |
| EndHedgeType | Trade.HBCExecutionLog | — | join-enriched | CBH vs HBC from HBCExecutionLog match on EndExecutionID |
| OrderID | Trade.PositionTbl | OrderID | passthrough | |
| ExitOrderID | Trade.PositionTbl | ExitOrderID | passthrough | |
| IsSettledOnOpen | Trade.PositionTbl | IsSettledOnOpen | passthrough | |
| StopRateOnOpen | Trade.PositionTreeInfo | StopRate | join-enriched | StopRate value captured at open time |
| LimitRateOnOpen | Trade.PositionTreeInfo | LimitRate | join-enriched | LimitRate value captured at open time |
| LastOpPriceRate | Trade.PositionTbl | LastOpPriceRate | passthrough | |
| SettlementTypeID | Trade.PositionTbl | SettlementTypeID | passthrough | |
| OpenMarketPriceRateID | Trade.PositionTbl | OpenMarketPriceRateID | passthrough | |
| OpenMarket_Ask | PriceLog | Ask | join-enriched | Joined via OpenMarketPriceRateID |
| OpenMarket_Bid | PriceLog | Bid | join-enriched | Joined via OpenMarketPriceRateID |
| OpenMarket_AskSpreaded | PriceLog | AskSpreaded | join-enriched | Joined via OpenMarketPriceRateID |
| OpenMarket_BidSpreaded | PriceLog | BidSpreaded | join-enriched | Joined via OpenMarketPriceRateID |
| OpenMarketCoversionRateBidSpreaded | PriceLog | ConversionRateBidSpreaded | join-enriched | Joined via OpenMarketPriceRateID. Typo in column name |
| OpenMarketCoversionRateAskSpreaded | PriceLog | ConversionRateAskSpreaded | join-enriched | Joined via OpenMarketPriceRateID. Typo in column name |
| CloseMarket_AskSpreaded | PriceLog | AskSpreaded | join-enriched | Joined via CloseMarketPriceRateID |
| CloseMarket_BidSpreaded | PriceLog | BidSpreaded | join-enriched | Joined via CloseMarketPriceRateID |
| CloseMarket_Ask | PriceLog | Ask | join-enriched | Joined via CloseMarketPriceRateID |
| CloseMarket_Bid | PriceLog | Bid | join-enriched | Joined via CloseMarketPriceRateID |
| CloseMarketCoversionRateBidSpreaded | PriceLog | ConversionRateBidSpreaded | join-enriched | Joined via CloseMarketPriceRateID. Typo in column name |
| CloseMarketCoversionRateAskSpreaded | PriceLog | ConversionRateAskSpreaded | join-enriched | Joined via CloseMarketPriceRateID. Typo in column name |
| RequestOpenOccurred | Trade.PositionTbl | RequestOccurred | rename | Production column named "RequestOccurred" |
| RequestCloseOccurred | Trade.PositionTbl | RequestCloseOccurred | passthrough | |
| OrderType | Trade.PositionTbl | OrderType | passthrough | |
| PnLVersion | Trade.PositionTbl | PnLVersion | passthrough | |
| PnLInDollars | Trade.OpenPositionEndOfDay | PnLInDollars | join-enriched | End-of-day snapshot |
| OpenMarketSpread | — | — | ETL-computed | Ask - Bid at open market snapshot |
| CloseMarketSpread | — | — | ETL-computed | Ask - Bid at close market snapshot |
| CloseMarkupOnOpen | Trade.PositionTbl | CloseMarkupOnOpen | passthrough | |
| OpenMarkup | Trade.PositionTbl | OpenMarkup | passthrough | |
| CloseMarkup | Trade.PositionTbl | CloseMarkup | passthrough | |
| DLTOpen | Trade.PositionTbl | DLTOpen | passthrough | |
| DLTClose | Trade.PositionTbl | DLTClose | passthrough | |
| OpenMarkupByUnits | — | — | ETL-computed | OpenMarkup * AmountInUnitsDecimal / InitialUnits |
| CommissionVersion | Trade.PositionTbl | CommissionVersion | passthrough | |
| ExitOrderType | Trade.PositionTbl | ExitOrderType | passthrough | |
| OpenPositionReasonID | Trade.PositionTbl | OpenActionType | rename | Production column named "OpenActionType" |
| OpenTotalTaxes | Trade.PositionTbl | OpenTotalTaxes | passthrough | |
| CloseTotalTaxes | Trade.PositionTbl | CloseTotalTaxes | passthrough | |
| OpenTotalFees | History.Cost | — | join-enriched | Aggregated from History.Cost records at open |
| CloseTotalFees | History.Cost | — | join-enriched | Aggregated from History.Cost records at close |
| EstimateCloseFeeForCFD | Trade.OpenPositionEndOfDay | EstimateCloseFeeForCFD | join-enriched | End-of-day snapshot |
| EstimateCloseFeeOnOpenByUnits | — | — | ETL-computed | Estimated close fee at open, per unit |
| EstimateCloseFeeOnOpen | Trade.PositionTbl | EstimateCloseFeeOnOpen | passthrough | |
| Close_PnLInDollars | Trade.OpenPositionEndOfDay | Close_PnLInDollars | join-enriched | Close-price-based PnL |
| Close_CalculationRate | Trade.OpenPositionEndOfDay | Close_CalculationRate | join-enriched | |
| Close_ConversionRate | Trade.OpenPositionEndOfDay | Close_ConversionRate | join-enriched | |
| Close_PriceType | Trade.OpenPositionEndOfDay | Close_PriceType | join-enriched | |
| CurrentCalculationRate | Trade.OpenPositionEndOfDay | CurrentCalculationRate | join-enriched | |
| CurrentConversionRate | Trade.OpenPositionEndOfDay | CurrentConversionRate | join-enriched | |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 53 |
| **Rename** | 3 |
| **Cast/Convert** | 1 |
| **Join-Enriched** | 33 |
| **ETL-Computed** | 18 |
| **SP-Adjusted** | 5 |
| **Total** | 113 |
