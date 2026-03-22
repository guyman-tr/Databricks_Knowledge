# Dealing_dbo.Dealing_GS_Credit_Risk

## 1. Overview
Daily credit risk exposure report for stocks/ETFs hedged through Goldman Sachs (HedgeServerID=101). Calculates client vs LP net exposure per instrument and models potential losses under 10 price-drop/rise scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (Date ASC) |
| **Row Count** | ~1.1M |
| **Date Range** | 2021-02-23 → present |
| **Grain** | One row per Date × InstrumentID |
| **Refresh** | Daily, via SP_GS_Credit_Risk |

## 2. Business Context
Goldman Sachs is one of eToro's liquidity providers for CFD Stocks and ETFs. This table quantifies the daily credit risk exposure to GS by comparing client-side open positions (NOP) against LP-side hedged positions, calculating net exposure and stress-testing under scenarios ranging from ±15% to ±50% price moves. The "Buffer" columns measure how far the weighted-average effective leverage is from each scenario threshold — if the buffer exceeds the scenario percentage, the scenario loss is zero.

**Author**: Adar Cahlon (created 2021-04-13).

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Business date for the risk snapshot | T2 | SP_GS_Credit_Risk: `@Date` parameter |
| InstrumentID | int | Yes | eToro instrument identifier | T2 | SP_GS_Credit_Risk: from Dim_Instrument via netting join |
| InstrumentType | varchar(20) | Yes | Asset class (Stocks or ETF) — filtered to InstrumentTypeID IN (5,6) | T2 | SP_GS_Credit_Risk: `di.InstrumentType` |
| InstrumentName | varchar(max) | Yes | Internal instrument name | T2 | SP_GS_Credit_Risk: `di.Name` |
| InstrumentDisplayName | varchar(max) | Yes | Client-facing display name | T2 | SP_GS_Credit_Risk: `di.InstrumentDisplayName` |
| OPLong | money | Yes | Total client open position value (USD) for long (IsBuy=1) positions. Formula: `SUM(CASE WHEN IsBuy=1 THEN ABS(Clients_NOP) ELSE 0 END)` | T2 | SP_GS_Credit_Risk |
| EffLevLong | decimal(16,6) | Yes | Weighted-average effective leverage for long positions. Formula: `SUM(ABS(NOP)*EffLev) / SUM(ABS(NOP))` for IsBuy=1 | T2 | SP_GS_Credit_Risk |
| OPShort | money | Yes | Total client open position value (USD) for short (IsBuy=0) positions. Formula: `SUM(CASE WHEN IsBuy=0 THEN ABS(Clients_NOP) ELSE 0 END)` | T2 | SP_GS_Credit_Risk |
| EffLevShort | decimal(16,6) | Yes | Weighted-average effective leverage for short positions | T2 | SP_GS_Credit_Risk |
| Clients_NOP | money | Yes | Net client open position in USD (signed). Formula: `SUM(Clients_NOP)` — positive=net long, negative=net short | T2 | SP_GS_Credit_Risk |
| LP_NOP | money | Yes | Goldman Sachs LP net open position in USD (signed). Formula: `Units*(IsBuy?Bid:Ask)*(2*IsBuy-1)*FX_Rate` from netting tables, filtered to HedgeServerID=101 | T2 | SP_GS_Credit_Risk |
| NetExposure(Clients-LP) | money | Yes | Unhedged exposure gap. Formula: `Clients_NOP - LP_NOP` | T2 | SP_GS_Credit_Risk |
| Buffer_Long | decimal(16,6) | Yes | Inverse of weighted-average effective leverage for longs. Formula: `1 / EffLevLong`. Represents the price-drop percentage the position can absorb before margin call | T2 | SP_GS_Credit_Risk |
| Buffer_Short | decimal(16,6) | Yes | Inverse of weighted-average effective leverage for shorts. Formula: `1 / EffLevShort` | T2 | SP_GS_Credit_Risk |
| Scenario_1_-15% | money | Yes | Estimated loss if price drops 15% for longs. Formula: `CASE WHEN Buffer_Long>0.15 THEN 0 ELSE OPLong*(0.15-Buffer_Long) END` | T2 | SP_GS_Credit_Risk |
| Scenario_2_-20% | money | Yes | Estimated loss if price drops 20% for longs | T2 | SP_GS_Credit_Risk |
| Scenario_3_-25% | money | Yes | Estimated loss if price drops 25% for longs | T2 | SP_GS_Credit_Risk |
| Scenario_4_-30% | money | Yes | Estimated loss if price drops 30% for longs | T2 | SP_GS_Credit_Risk |
| Scenario_5_15% | money | Yes | Estimated loss if price rises 15% for shorts | T2 | SP_GS_Credit_Risk |
| Scenario_6_20% | money | Yes | Estimated loss if price rises 20% for shorts | T2 | SP_GS_Credit_Risk |
| Scenario_7_25% | money | Yes | Estimated loss if price rises 25% for shorts | T2 | SP_GS_Credit_Risk |
| Scenario_8_30% | money | Yes | Estimated loss if price rises 30% for shorts | T2 | SP_GS_Credit_Risk |
| UpdateDate | datetime | Yes | Row write timestamp. Formula: `GETDATE()` | T2 | SP_GS_Credit_Risk |
| Scenario_9_-50% | money | Yes | Estimated loss if price drops 50% for longs | T2 | SP_GS_Credit_Risk |
| Scenario_10_50% | money | Yes | Estimated loss if price rises 50% for shorts | T2 | SP_GS_Credit_Risk |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| DWH_dbo.Dim_Instrument | Lookup | InstrumentID — filtered to InstrumentTypeID IN (5,6) |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Price source | InstrumentID, OccurredDateID=@DateID |
| BI_DB_dbo.BI_DB_PositionPnL | Client positions | InstrumentID, DateID, IsSettled=0, HedgeServerID=101 |
| Dealing_staging.etoro_History_Netting_History | LP positions (historical) | HedgeServerID=101 |
| Dealing_staging.etoro_Hedge_Netting | LP positions (current) | HedgeServerID=101 |
| Dealing_dbo.Dealing_CFDs_Stocks_Credit_Risk | Sibling table | Same pattern but covers ALL hedge servers, not just GS |
| Dealing_dbo.Dealing_JP_Credit_Risk | Sibling table | Same pattern for JP Morgan hedge servers |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_GS_Credit_Risk` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | DELETE + INSERT for @Date |
| **Key Logic** | 1) Build price table from Fact_CurrencyPriceWithSplit. 2) Reconstruct LP positions from netting history (UNION current + history, ROW_NUMBER dedup). 3) Calculate LP NOP with multi-step FX conversion. 4) Calculate client NOP from BI_DB_PositionPnL for valid customers, CFD only (IsSettled=0). 5) Compute per-position effective leverage = ABS(NOP)/(Amount+PositionPnL). 6) Aggregate to instrument level. 7) Compute buffer = 1/EffLev. 8) Run 10 scenario stress tests. |

## 6. Data Lifecycle
- **Retention**: No automated cleanup
- **Partitioning**: None

## 7. Known Gaps
- HedgeServerID=101 is hardcoded — if GS gets additional hedge servers, the SP must be updated
- The table structure matches Dealing_CFDs_Stocks_Credit_Risk exactly except it lacks HedgeServerID column

## 8. Quality Score
**7.5/10** — Strong SP code analysis with complete column lineage. GS-specific credit risk variant well documented. Structurally identical to the already-documented Dealing_CFDs_Stocks_Credit_Risk pattern.
