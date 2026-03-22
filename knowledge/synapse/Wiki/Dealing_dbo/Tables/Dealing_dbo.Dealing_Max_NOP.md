# Dealing_dbo.Dealing_Max_NOP

## 1. Overview
Daily maximum Net Open Position (NOP) in USD for each instrument per liquidity account. The SP loops hourly through a day, reconstructing LP netting positions at each hour-end using temporal netting tables, joining to hourly candle prices, converting to USD, and then taking the MAX absolute NOP across all hours.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (Date ASC) |
| **Row Count** | ~8.1M |
| **Date Range** | 2021-05-01 → 2024-06-02 (appears inactive) |
| **Grain** | One row per Date × InstrumentID × LiquidityAccountID |
| **Refresh** | Daily, via SP_Max_NOP (inactive since June 2024) |

## 2. Business Context
Tracks the peak intraday NOP exposure per instrument per LP account. This metric is important for LP risk management — it shows the maximum hedging exposure eToro reached during any given hour of the trading day. The table appears to have stopped updating in June 2024.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | datetime | Yes | Business date (cast to DATE in the INSERT). Date range loops hourly throughout the day | T2 | SP_Max_NOP: `CAST(@Date AS DATE)` |
| InstrumentID | int | Yes | eToro instrument identifier | T2 | SP_Max_NOP: from netting tables joined to Dim_Instrument |
| InstrumentDisplayName | varchar(100) | Yes | Client-facing instrument name | T2 | SP_Max_NOP: `di.InstrumentDisplayName` |
| InstrumentType | varchar(50) | Yes | Asset class name | T2 | SP_Max_NOP: `di.InstrumentType` |
| LiquidityAccountID | int | Yes | LP account identifier | T2 | SP_Max_NOP: from netting tables |
| LiquidityAccountName | varchar(100) | Yes | LP account display name | T2 | SP_Max_NOP: from `etoro_Trade_LiquidityAccounts` |
| SellCurrency | varchar(20) | Yes | Instrument denomination currency | T2 | SP_Max_NOP: `di.SellCurrency` |
| Units | decimal(32,8) | Yes | Maximum units held across all hours. Formula: `MAX(Units)` | T2 | SP_Max_NOP |
| Name | varchar(100) | Yes | Internal instrument name | T2 | SP_Max_NOP: `di.Name` |
| MAX_NOP_USD | decimal(16,6) | Yes | Maximum absolute NOP in USD across all hourly snapshots. Formula: `MAX(ABS(LocalAmount * FX_Rate))` where LocalAmount uses IsBuy-dependent pricing with multi-step FX conversion | T2 | SP_Max_NOP |
| UpdateDate | datetime | Yes | Row write timestamp | T2 | SP_Max_NOP: `GETDATE()` |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| Dealing_staging.etoro_Hedge_Netting | LP current positions | InstrumentID, SysStartTime temporal |
| Dealing_staging.etoro_History_Netting_History | LP historical positions | InstrumentID, SysStartTime/SysEndTime temporal |
| DWH_dbo.Dim_Instrument | Instrument metadata | InstrumentID |
| BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted | Hourly candle prices | InstrumentID, DateTo=EndDateTime |
| DWH_dbo.Fact_CurrencyPriceWithSplit | FX rates for USD conversion | InstrumentID, OccurredDateID |
| Dealing_staging.etoro_Trade_LiquidityAccounts | LP account name lookup | LiquidityAccountID |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_Max_NOP` |
| **Parameters** | `@Date DATETIME` |
| **Load Pattern** | DELETE + INSERT for @Date |
| **Key Logic** | 1) WHILE loop: iterate each hour from @Date to @Date+1. 2) For each hour: UNION current + history netting, dedup by ROW_NUMBER PARTITION BY (InstrumentID, LiquidityAccountID) ORDER BY SysEndTime DESC. 3) Join to hourly candle prices (BI_DB_SpreadedPriceCandle60MinSplitted). 4) Compute LocalAmount = `CASE WHEN IsBuy=1 THEN Units*BidLast ELSE -Units*AskLast END`. 5) Multi-step FX to USD. 6) GROUP BY instrument+LP account, take MAX(Units) and MAX(ABS(NOP_USD)). |
| **Special Note** | Uses GBP pence handling: `SellCurrencyID=666 → LocalAmount/100` |

## 6. Data Lifecycle
- **Status**: Appears inactive since June 2024
- **Retention**: No automated cleanup

## 7. Known Gaps
- The WHILE loop (hourly) is unusual for a Synapse SP and may cause performance issues
- GBP pence conversion (CurrencyID=666) is a hardcoded special case
- Table stopped updating in June 2024 — may be deprecated

## 8. Quality Score
**7.0/10** — Complex hourly-loop SP with temporal netting reconstruction. Some uncertainty about whether the table is still active. Multi-step FX conversion logic is well-traced but complex.
