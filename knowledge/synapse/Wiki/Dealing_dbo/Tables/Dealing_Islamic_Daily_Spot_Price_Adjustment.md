---
object: Dealing_Islamic_Daily_Spot_Price_Adjustment
schema: Dealing_dbo
type: Table
description: Position-level daily futures roll-cost adjustment for Islamic (swap-free) accounts. One row per futures-eligible open position per weekday. Computes the implicit daily cost of rolling from the front contract to the next using Fivetran futures prices. Fee can be positive (backwardation) or negative (contango). Fee_Type_ID=2.
etl_sp: Dealing_dbo.SP_Islamic_Spot_Price_Adjustment
frequency: Daily (weekdays only)
status: Active (last: 2026-03-09)
row_count: 392,100
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.5
---

# Dealing_Islamic_Daily_Spot_Price_Adjustment

Daily futures roll-cost adjustment for Islamic (swap-free) accounts. Covers 7 futures-based CFD instruments (WTI Oil, Natural Gas, Brent Oil, plus 4 industrial metals). The fee represents the **implicit daily cost of rolling** the front futures contract to the next, allocated per position per day. Unlike the companion `Dealing_Islamic_Daily_Administrative_Fee` (always a debit), this fee can be **positive or negative** depending on market structure (contango vs backwardation).

Companion table: `Dealing_Islamic_Daily_Administrative_Fee` (Fee_Type_ID=1) charges all Islamic instrument types. This table (Fee_Type_ID=2) exclusively covers the 7 futures instruments and the two may both apply to the same position on the same day.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Position source | `DWH_dbo.Dim_Position` | Open Islamic positions at 22:00 UTC, InstrumentID IN (17,22,339,340,341,343,344) |
| Customer filter | `DWH_dbo.Dim_Customer` | WeekendFeePrecentage=0 (Islamic), IsValidCustomer=1 |
| Instrument dim | `DWH_dbo.Dim_Instrument` | InstrumentTypeID, InstrumentType, Exchange |
| Date dim | `DWH_dbo.Dim_Date` | Day-of-week for Count_Fri rule |
| Futures prices | `Dealing_staging.External_Fivetran_dealing_overnight_fees` | Front/Next contract close prices, Days_Between_Expiration |
| Alert table | `Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment_Email` | Written when Fivetran data missing on non-weekend/non-Friday |
| Writer | `Dealing_dbo.SP_Islamic_Spot_Price_Adjustment` | Daily (weekdays only), OpsDB Priority 0 |

**Author**: Gili Goldbaum (2024-03-07). Active since 2024-03-08.

## 1. Business Purpose

- Futures-based CFDs have a cost (or benefit) from rolling to the next contract at expiry — this table makes it explicit
- Islamic clients don't pay rollover; instead they pay/receive this forward price adjustment daily
- `Final_Fee > 0`: client **benefits** (market in backwardation — front > next price)
- `Final_Fee < 0`: client **pays** (market in contango — front < next price)
- Used by Finance for Islamic client billing and by Dealing for fee reconciliation

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| Front / Next | Front = nearest futures expiry; Next = the following contract |
| Contango | Front < Next — long clients pay (cost to roll forward) |
| Backwardation | Front > Next — long clients benefit (receive roll credit) |
| Days_Between_Expiration | Days until front contract expires; used to amortize roll cost daily |
| Fee_Type_ID = 2 | Spot price adjustment (vs Fee_Type_ID=1 for admin fee) |
| Fivetran dependency | Entire SP skipped if External_Fivetran data missing; email alert triggered |

## 3. Fee Calculation

```
Final_Fee = direction × ((Next - Front) / Days_Between_Expiration) × AmountInUnitsDecimal × Days_To_Charge

where direction = -1 for long (IsBuy=1), +1 for short (IsBuy=0)
```

| Day of Week | Days_To_Charge |
|-------------|----------------|
| Friday | 3 (covers Sat+Sun gap) |
| Mon – Thu | 1 |
| Sat / Sun | 0 (SP skips entirely) |

Always uses **Count_Fri** rule. No Wed/Thu triple-day variants.

## 4. Instrument Coverage

| Instrument | InstrumentID | Rows (2024–2026) | Avg Fee (USD) |
|------------|-------------|-----------------|--------------|
| XTI/USD (WTI Oil) | 17 | 209,351 | +2.03 |
| XNG/USD (Natural Gas) | 22 | 160,467 | -3.62 |
| EuroOIL/USD (Brent) | 341 | 19,055 | +2.18 |
| Nickel/USD | 343 | 1,930 | -0.42 |
| ZINC/USD | 340 | 647 | -0.02 |
| Aluminum/USD | 344 | 367 | -0.08 |
| LEAD/USD | 339 | 283 | -0.26 |

## 5. Grain

One row per **Date × PositionID** for each Islamic-eligible futures position open at 22:00 UTC on a weekday.

## 6. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| Date | date | Report date; Sunday input → Friday's date | Tier 2 | Clustered index key |
| DateID | int | YYYYMMDD of Date | Tier 2 | SP-computed |
| PositionID | bigint | Position identifier | Tier 1 | FK to Dim_Position |
| RealCID | int | Client ID (Islamic account holder) | Tier 1 | From Dim_Customer |
| GCID | int | Global customer ID | Tier 2 | From Dim_Customer |
| UserName | varchar(20) | Client username | Tier 2 | From Dim_Customer |
| OpenDateID | int | Date position opened | Tier 1 | From Dim_Position |
| OpenOccurred | datetime | Exact open timestamp | Tier 1 | From Dim_Position |
| NewOpenOccurred | datetime | Open date adjusted for 22:00 UTC cutoff | Tier 2 | +1 day if opened after 22:00 |
| IsTheDayBefore | int | 1 if position opened after 22:00 UTC | Tier 2 | Cutoff shift flag |
| CloseDateID | int | Date position closed; 0 if open | Tier 1 | From Dim_Position |
| CloseOccurred | datetime | Exact close timestamp | Tier 1 | From Dim_Position |
| InstrumentTypeID | int | Instrument type ID | Tier 1 | From Dim_Instrument |
| InstrumentType | varchar(50) | Instrument type name | Tier 1 | From Dim_Instrument |
| InstrumentID | int | One of: 17, 22, 339, 340, 341, 343, 344 | Tier 1 | Hardcoded scope in SP |
| InstrumentName | varchar(50) | Instrument display name | Tier 1 | From Dim_Instrument |
| Exchange | varchar(80) | Exchange name | Tier 1 | From Dim_Instrument |
| ExchangeID | int | Always 0 — not used in this SP | Tier 2 | Hardcoded; no ExchangeInfo join |
| IsBuy | int | 1=long, 0=short | Tier 1 | From Dim_Position |
| Leverage | int | Position leverage | Tier 1 | From Dim_Position |
| IsSettled | int | 0 for CFD positions | Tier 1 | From Dim_Position |
| AmountInUnitsDecimal | decimal(16,6) | Position size in instrument units | Tier 1 | From Dim_Position |
| Days_Open | int | Effective days open (Count_Fri rule) | Tier 2 | SP-computed from Dim_Date |
| Days_To_Charge | int | 3 on Fri, 1 on Mon–Thu, 0 weekend | Tier 2 | SP-computed |
| Front | float | Front contract close price from Fivetran | Tier 4 | From External_Fivetran_dealing_overnight_fees |
| Next | float | Next contract close price from Fivetran | Tier 4 | From External_Fivetran_dealing_overnight_fees |
| Days_Between_Expiration | int | Days until front contract expires | Tier 4 | From External_Fivetran_dealing_overnight_fees |
| Final_Fee | decimal(16,2) | Roll-cost fee in USD; positive or negative | Tier 1 | Range: -6823.10 to +13089.85 |
| Fee_Type_ID | int | Always 2 — spot price adjustment | Tier 2 | Hardcoded; distinguishes from Admin Fee (Type 1) |
| UpdateDate | datetime | ETL metadata: row write timestamp | Tier 1 | ETL metadata (blacklist canonical) |

## 7. Common Query Patterns

```sql
-- Daily spot adjustment total by instrument
SELECT Date, InstrumentName, COUNT(*) AS Positions,
       SUM(Final_Fee) AS TotalAdjustment,
       AVG(Front) AS AvgFront, AVG(Next) AS AvgNext
FROM Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment
WHERE Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY Date, InstrumentName
ORDER BY Date DESC;

-- Combined Islamic fee (Admin + Spot) per client
SELECT a.Date, a.RealCID,
       SUM(a.Final_Fee) AS AdminFee,
       SUM(ISNULL(s.Final_Fee, 0)) AS SpotFee,
       SUM(a.Final_Fee) + SUM(ISNULL(s.Final_Fee, 0)) AS TotalFee
FROM Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee a
LEFT JOIN Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment s
  ON a.Date = s.Date AND a.PositionID = s.PositionID
WHERE a.Date = CAST(GETDATE()-1 AS DATE)
GROUP BY a.Date, a.RealCID;
```

## 8. Data Quality & Caveats

- Active since 2024-03-08 — no data before that date (new SP, not backfilled)
- SP skips entirely on weekends — no rows for Sat/Sun
- Sunday input uses Friday's date (potential duplicate risk if SP runs on both Sat and Mon)
- Fivetran missing-data: entire day skipped with email alert; no backfill mechanism
- 7 hardcoded futures instruments in SP — new instruments require SP code change
- ExchangeID is always 0 (not joined from Dim_ExchangeInfo)

## 9. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee` | Companion admin fee (Fee_Type_ID=1); same positions may appear in both |
| `Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment_Email` | Alert table written when Fivetran data missing |
| `Dealing_staging.External_Fivetran_dealing_overnight_fees` | Fivetran futures price feed (Front/Next/Days_Between_Expiration) |

## 10. Operational Notes

- **ETL**: `SP_Islamic_Spot_Price_Adjustment` runs daily (weekdays only). DELETE + INSERT for @Date
- **Author**: Gili Goldbaum (2024-03-07)
- **Weekend handling**: SP skips Sat/Sun; Sunday input → Friday used

---
*Quality score: 8.5/10 — Well-documented roll-cost logic. Fivetran dependency is the key operational risk. Instrument scope hardcoded.*
