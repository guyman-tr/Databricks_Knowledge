# Dealing_dbo.Dealing_RolloverCommissionSplit

## 1. Overview
Position-level breakdown of overnight rollover fees into two components: the "pure" LP cost (interest rate spread paid to the liquidity provider) and eToro's commission (the markup eToro adds). Currently limited to index instruments NSDQ100 (InstrumentID=17) and SPX500 (InstrumentID=22).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (Date ASC) |
| **Row Count** | ~28.3M |
| **Date Range** | 2022-09-06 → present |
| **Grain** | One row per Date × PositionID |
| **Refresh** | Daily, via SP_RolloverCommissionSplit |

## 2. Business Context
Overnight fees (rollover fees) are charged daily for holding CFD positions. These fees have two components: 1) the base interest rate cost (what the LP charges), and 2) eToro's markup (the eToro Commission). This table decomposes each position's overnight fee into these components, enabling analysis of how much overnight fee revenue is "pure" LP cost vs eToro's revenue. The eToro commission is calculated as 5% yearly / 365 days × price (as of SR-233814, changed from 2.5% to 5%). Islamic (swap-free) accounts are identified via `WeekendFeePrecentage = 0`.

**Author**: Sarah Benchitrit (created 2023-07-01). Daylight savings adjustments applied multiple times.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Business date | T2 | SP_RolloverCommissionSplit: `@Date` |
| DateID | int | Yes | Business date as YYYYMMDD integer | T2 | SP_RolloverCommissionSplit: `DateToDateID(@Date)` |
| InstrumentID | int | NOT NULL | Instrument identifier — currently only 17 (NSDQ100) and 22 (SPX500) | T2 | SP_RolloverCommissionSplit: hardcoded `IN (22,17)` |
| PositionID | bigint | Yes | Client position identifier | T2 | SP_RolloverCommissionSplit: from History_Credit.PositionID |
| hour | datetime | Yes | Hour at which the rollover was applied | T2 | SP_RolloverCommissionSplit: `DATEADD(hour, DATEDIFF(hour,0,Occurred), 0)` |
| Amount | money | NOT NULL | Total rollover fee amount (in position currency). Formula: `ISNULL(TotalCashChange, 0)` from History_Credit where CreditTypeID=14 | T2 | SP_RolloverCommissionSplit |
| Units | numeric(38,15) | Yes | Position size in units. Formula: `Amount / NonLeveragedOverNightFee` (buy or sell rate based on IsBuy) | T2 | SP_RolloverCommissionSplit |
| IsBuy | bit | NOT NULL | 1=long position, 0=short position | T2 | SP_RolloverCommissionSplit: from Dim_Position |
| NonLeveragedSellOverNightFee | numeric(16,8) | NOT NULL | LP overnight fee rate for sell (short) positions. From InstrumentToFeeConfig | T2 | SP_RolloverCommissionSplit |
| NonLeveragedBuyOverNightFee | numeric(16,8) | NOT NULL | LP overnight fee rate for buy (long) positions | T2 | SP_RolloverCommissionSplit |
| AskLast | numeric(36,12) | Yes | End-of-day ask price from 60-min candle | T2 | SP_RolloverCommissionSplit: from Dim_GetSpreadedPriceCandle60MinSplitted |
| BidLast | numeric(36,12) | Yes | End-of-day bid price | T2 | SP_RolloverCommissionSplit |
| eToroCommissionAsk | numeric(38,13) | Yes | eToro's overnight fee commission rate (ask side). Formula: `AskLast * 0.05 / 365` (5% annual rate) | T2 | SP_RolloverCommissionSplit |
| eToroCommissionBid | numeric(38,13) | Yes | eToro's overnight fee commission rate (bid side). Formula: `BidLast * 0.05 / 365` | T2 | SP_RolloverCommissionSplit |
| PureROSellRate | numeric(38,13) | Yes | Pure LP rollover rate for sells. Formula: `NonLeveragedSellOverNightFee - eToroCommissionAsk` | T2 | SP_RolloverCommissionSplit |
| PureROBuyRate | numeric(38,13) | Yes | Pure LP rollover rate for buys. Formula: `NonLeveragedBuyOverNightFee - eToroCommissionAsk` | T2 | SP_RolloverCommissionSplit |
| PureROBuy | numeric(38,6) | Yes | Pure LP cost for buy positions. Formula: `CASE WHEN IsBuy=1 THEN PureROBuyRate * Units ELSE 0 END` | T2 | SP_RolloverCommissionSplit |
| PureROSell | numeric(38,6) | Yes | Pure LP cost for sell positions. Formula: `CASE WHEN IsBuy=0 THEN PureROSellRate * Units ELSE 0 END` | T2 | SP_RolloverCommissionSplit |
| PureEtoroFeeBuy | numeric(38,6) | Yes | eToro markup for buy positions. Formula: `CASE WHEN IsBuy=1 THEN eToroCommissionAsk * Units ELSE 0 END` | T2 | SP_RolloverCommissionSplit |
| PureEtoroFeeSell | numeric(38,6) | Yes | eToro markup for sell positions. Formula: `CASE WHEN IsBuy=0 THEN eToroCommissionAsk * Units ELSE 0 END` | T2 | SP_RolloverCommissionSplit |
| IsIslamic | varchar(50) | Yes | Whether the account is Islamic/swap-free. Values: 'Islamic' or 'Not Islamic'. Formula: `CASE WHEN WeekendFeePrecentage=0 THEN 'Islamic' ELSE 'Not Islamic' END` | T2 | SP_RolloverCommissionSplit |
| HedgeServerID | int | Yes | Hedge server for the position. Added SR-227505 (2024-01-22) | T2 | SP_RolloverCommissionSplit: from Dim_Position |
| UpdateDate | datetime | Yes | Row write timestamp | T2 | SP_RolloverCommissionSplit: `GETDATE()` |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| CopyFromLake.etoro_History_Credit | Rollover transactions | CreditTypeID=14, non-dividend, date range |
| DWH_dbo.Dim_Position | Position metadata | PositionID, InstrumentID IN (22,17) |
| DWH_dbo.Dim_Customer | Customer validation + Islamic flag | RealCID, IsValidCustomer=1, WeekendFeePrecentage |
| CopyFromLake.etoro_Trade_InstrumentToFeeConfig | Fee configuration rates | InstrumentID, Occurred BETWEEN BeginTime AND EndTime |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | End-of-day candle prices | InstrumentID IN (22,17), latest DateTo per instrument |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_RolloverCommissionSplit` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | DELETE + INSERT for @Date |
| **Dependencies** | Calls `CopyFromLake.SP_Copy_Temporary_Data` for InstrumentToFeeConfig and History_Credit |
| **Candle selection** | Handles daylight savings: weekday=23:00 (winter) or 22:00, Friday=21:00, Saturday=previous Friday 21:00. As of SR-342083, uses MAX(DateTo) per instrument to auto-handle DST |

## 6. Data Lifecycle
- **Retention**: No automated cleanup
- **Volume**: ~20K positions/day for 2 instruments

## 7. Known Gaps
- Limited to InstrumentID IN (17, 22) — other instruments not covered
- The 5% annual rate is hardcoded — was 2.5% before SR-233814 (2024-02-19)
- Atlassian confirms overnight fees have been unified across categories

## 8. Quality Score
**8.0/10** — Detailed position-level fee decomposition with clear formulas. Daylight savings handling is complex but well-documented through SR history. Islamic account identification is straightforward.
