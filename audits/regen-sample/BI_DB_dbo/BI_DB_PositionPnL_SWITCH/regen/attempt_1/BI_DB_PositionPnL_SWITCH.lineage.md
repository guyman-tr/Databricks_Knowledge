# Lineage: BI_DB_dbo.BI_DB_PositionPnL_SWITCH

## Source Objects

| Source Object | Role | Wiki |
|--------------|------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Schema source (created as empty clone via SELECT TOP 0) | [BI_DB_PositionPnL.md](../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_PositionPnL.md) |
| BI_DB_dbo.SP_PositionPnL | Creator SP (drops and recreates this table each run) | SP code in SSDT |
| BI_DB_dbo.SP_BI_DB_PositionPnL_SWITCH | Consumer SP (partition swap mechanism) | SP code in SSDT |

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | BI_DB_dbo.BI_DB_PositionPnL | CID | Schema clone (no data flows through) | Tier 2 |
| 2 | PositionID | BI_DB_dbo.BI_DB_PositionPnL | PositionID | Schema clone (no data flows through) | Tier 2 |
| 3 | InstrumentID | BI_DB_dbo.BI_DB_PositionPnL | InstrumentID | Schema clone (no data flows through) | Tier 2 |
| 4 | MirrorID | BI_DB_dbo.BI_DB_PositionPnL | MirrorID | Schema clone (no data flows through) | Tier 2 |
| 5 | Commission | BI_DB_dbo.BI_DB_PositionPnL | Commission | Schema clone (no data flows through) | Tier 2 |
| 6 | InitForexRate | BI_DB_dbo.BI_DB_PositionPnL | InitForexRate | Schema clone (no data flows through) | Tier 2 |
| 7 | SpreadedPipBid | BI_DB_dbo.BI_DB_PositionPnL | SpreadedPipBid | Schema clone (no data flows through) | Tier 2 |
| 8 | SpreadedPipAsk | BI_DB_dbo.BI_DB_PositionPnL | SpreadedPipAsk | Schema clone (no data flows through) | Tier 2 |
| 9 | PositionPnL | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | Schema clone (no data flows through) | Tier 2 |
| 10 | Price | BI_DB_dbo.BI_DB_PositionPnL | Price | Schema clone (no data flows through) | Tier 2 |
| 11 | HedgeServerID | BI_DB_dbo.BI_DB_PositionPnL | HedgeServerID | Schema clone (no data flows through) | Tier 2 |
| 12 | Amount | BI_DB_dbo.BI_DB_PositionPnL | Amount | Schema clone (no data flows through) | Tier 2 |
| 13 | AmountInUnitsDecimal | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | Schema clone (no data flows through) | Tier 2 |
| 14 | LimitRate | BI_DB_dbo.BI_DB_PositionPnL | LimitRate | Schema clone (no data flows through) | Tier 2 |
| 15 | StopRate | BI_DB_dbo.BI_DB_PositionPnL | StopRate | Schema clone (no data flows through) | Tier 2 |
| 16 | IsBuy | BI_DB_dbo.BI_DB_PositionPnL | IsBuy | Schema clone (no data flows through) | Tier 2 |
| 17 | Occurred | BI_DB_dbo.BI_DB_PositionPnL | Occurred | Schema clone (no data flows through) | Tier 2 |
| 18 | Date | BI_DB_dbo.BI_DB_PositionPnL | Date | Schema clone (no data flows through) | Tier 2 |
| 19 | DateID | BI_DB_dbo.BI_DB_PositionPnL | DateID | Schema clone (no data flows through) | Tier 2 |
| 20 | UpdateDate | BI_DB_dbo.BI_DB_PositionPnL | UpdateDate | Schema clone (no data flows through) | Tier 2 |
| 21 | IsSettled | BI_DB_dbo.BI_DB_PositionPnL | IsSettled | Schema clone (no data flows through) | Tier 2 |
| 22 | NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | Schema clone (no data flows through) | Tier 2 |
| 23 | DailyPnL | BI_DB_dbo.BI_DB_PositionPnL | DailyPnL | Schema clone (no data flows through) | Tier 2 |
| 24 | Leverage | BI_DB_dbo.BI_DB_PositionPnL | Leverage | Schema clone (no data flows through) | Tier 2 |
| 25 | RateBid | BI_DB_dbo.BI_DB_PositionPnL | RateBid | Schema clone (no data flows through) | Tier 2 |
| 26 | RateAsk | BI_DB_dbo.BI_DB_PositionPnL | RateAsk | Schema clone (no data flows through) | Tier 2 |
| 27 | USD_CR | BI_DB_dbo.BI_DB_PositionPnL | USD_CR | Schema clone (no data flows through) | Tier 2 |
| 28 | SettlementTypeID | BI_DB_dbo.BI_DB_PositionPnL | SettlementTypeID | Schema clone (no data flows through) | Tier 2 |
| 29 | EstimateCloseFeeForCFD | BI_DB_dbo.BI_DB_PositionPnL | EstimateCloseFeeForCFD | Schema clone (no data flows through) | Tier 2 |
| 30 | EstimateCloseFeeOnOpenByUnits | BI_DB_dbo.BI_DB_PositionPnL | EstimateCloseFeeOnOpenByUnits | Schema clone (no data flows through) | Tier 2 |
| 31 | EstimateCloseFeeOnOpen | BI_DB_dbo.BI_DB_PositionPnL | EstimateCloseFeeOnOpen | Schema clone (no data flows through) | Tier 2 |
| 32 | Close_PnLInDollars | BI_DB_dbo.BI_DB_PositionPnL | Close_PnLInDollars | Schema clone (no data flows through) | Tier 2 |
| 33 | Close_CalculationRate | BI_DB_dbo.BI_DB_PositionPnL | Close_CalculationRate | Schema clone (no data flows through) | Tier 2 |
| 34 | Close_ConversionRate | BI_DB_dbo.BI_DB_PositionPnL | Close_ConversionRate | Schema clone (no data flows through) | Tier 2 |
| 35 | Close_PriceType | BI_DB_dbo.BI_DB_PositionPnL | Close_PriceType | Schema clone (no data flows through) | Tier 2 |
| 36 | CurrentCalculationRate | BI_DB_dbo.BI_DB_PositionPnL | CurrentCalculationRate | Schema clone (no data flows through) | Tier 2 |
| 37 | CurrentConversionRate | BI_DB_dbo.BI_DB_PositionPnL | CurrentConversionRate | Schema clone (no data flows through) | Tier 2 |
| 38 | Close_NOP | BI_DB_dbo.BI_DB_PositionPnL | Close_NOP | Schema clone (no data flows through) | Tier 2 |
| 39 | Current_NOP | BI_DB_dbo.BI_DB_PositionPnL | Current_NOP | Schema clone (no data flows through) | Tier 2 |

## Notes

This table is a **transient shadow table** used exclusively by the partition-switching mechanism in `SP_BI_DB_PositionPnL_SWITCH`. It is:

1. **Created** by `SP_PositionPnL` as an empty schema clone of `BI_DB_PositionPnL` (via `SELECT TOP 0 *`)
2. **Used** by `SP_BI_DB_PositionPnL_SWITCH` to temporarily receive old partition data during the swap
3. **Truncated** at the end of every switch operation

The table is always empty after ETL completes. No data persists. Column descriptions inherit from `BI_DB_PositionPnL` since the schema is identical.
