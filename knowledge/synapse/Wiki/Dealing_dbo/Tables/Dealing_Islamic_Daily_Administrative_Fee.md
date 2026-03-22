---
object: Dealing_Islamic_Daily_Administrative_Fee
schema: Dealing_dbo
type: Table
description: Position-level daily Islamic administrative fee ledger. One row per Islamic-eligible open position per day. Captures the fee charged to swap-free (Islamic) account holders using exchange-type-specific day counting (triple-day logic for Wed/Thu/Fri) across Currencies, Commodities, Indices, Stocks, ETFs, and Crypto CFDs. Fee_Type_ID=1.
etl_sp: Dealing_dbo.SP_Islamic_Administrative_Fee
frequency: Daily
status: Active (last: 2026-03-10)
row_count: 17,614,575
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 9.0
---

# Dealing_Islamic_Daily_Administrative_Fee

Position-level administrative fee ledger for Islamic (swap-free) accounts. For each day, captures every Islamic-eligible open position and the fee charged, computed using instrument-type-specific formulas with **triple-day logic** (Wed/Thu/Fri charges cover the upcoming non-trading gap). Companion table `Dealing_Islamic_Daily_Spot_Price_Adjustment` captures the futures roll-cost fee for the same clients (Fee_Type_ID=2).

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Position source | `DWH_dbo.Dim_Position` | Open positions at 22:00 UTC cutoff |
| Customer filter | `DWH_dbo.Dim_Customer` | WeekendFeePrecentage=0 (Islamic accounts), IsValidCustomer=1, CountryID |
| Instrument dim | `DWH_dbo.Dim_Instrument` | InstrumentTypeID, Exchange |
| Exchange dim | `DWH_dbo.Dim_ExchangeInfo` | ExchangeID (day-counting rule selector) |
| Price source | `DWH_dbo.Fact_CurrencyPriceWithSplit` | EOD Bid/Ask prices + ConvertRate for USD_Price |
| Date dim | `DWH_dbo.Dim_Date` | Day-of-week flags for Count_Wed/Thu/Fri/i/All logic |
| Fee config | `Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group` | Admin_Fee_USD, GracePeriod per instrument group |
| Instrument groups | `Dealing_dbo.Dealing_Islamic_Instruments_Groups` | Manual instrument groupings |
| Contract sizes | `Dealing_dbo.Dealing_Islamic_Units_Per_Contract` | Units_per_Contract for Commodities |
| Writer | `Dealing_dbo.SP_Islamic_Administrative_Fee` | Daily, OpsDB Priority 0 |

**Author**: Gili Goldbaum (2024-02-21). Last SR: SR-343388 (2025-11-17, InstrumentID=62 logic).

## 1. Business Purpose

- Islamic accounts (swap-free) do not pay rollover fees; instead they accrue a daily administrative fee
- This table is the **position-level fee ledger** — one row per open position per day
- `Final_Fee` is always ≤ 0 (debit to client); zero on non-charging days
- Triple-day logic: on the last trading day before a 2-day gap, the SP charges for the upcoming gap (up to 3× the daily fee)
- Used by Finance/Compliance to audit Islamic fee collection and by Dealing for regulatory reporting

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| Islamic account | Identified by `WeekendFeePrecentage = 0` in Dim_Customer |
| Fee_Type_ID = 1 | Administrative fee (distinct from Fee_Type_ID=2 in Spot_Price_Adjustment) |
| 22:00 UTC cutoff | Position must be open at 22:00 UTC to accrue the day's fee |
| IsTheDayBefore | 1 if position opened after 22:00 UTC — first full day shifted to next calendar day |
| GracePeriod | Days before fee starts; from Dealing_Islamic_Admin_Fee_Per_Group config |
| Days_Admin_Fee | Days_Open − GracePeriod — net chargeable days |
| Triple-day | On triple-day (Wed/Thu/Fri by exchange), charges 1/2/3× daily rate |

## 3. Day-Counting Rules

| Rule | Instruments | Triple Day |
|------|-------------|-----------|
| Count_Fri | Futures (17,22,339–344) OR ExchangeID≥3 (not 8) | Fridays = 3 days |
| Count_Wed | ExchangeID=1 (not InstrID 62) OR ExchangeID=2 | Wednesdays = 3 days |
| Count_Thu | ExchangeID=1 AND InstrumentID=62 | Thursdays = 3 days |
| Count_All | ExchangeID=8 | Every calendar day |
| Count_i | Default | Mon–Fri only; no triple day |

Weekends (Sat/Sun) never count in any scheme except Count_All.

## 4. Fee Formula by Instrument Type

| InstrumentType | Formula |
|----------------|---------|
| Currencies (1) | `(Units / 100000) × Admin_Fee_USD × Days_To_Charge × -1` |
| Commodities (2) | `(Units / Units_per_Contract) × Admin_Fee_USD × Days_To_Charge × -1` |
| Indices (4) | `Units × Admin_Fee_USD × Days_To_Charge × -1` |
| Stocks (5) / ETF (6) | `((Units × USD_Price) / 10000) × Admin_Fee_USD × Days_To_Charge × -1` |
| Crypto (10) | `((Units × USD_Price) / 10000) × Admin_Fee_USD × Days_To_Charge × -1` |

`Admin_Fee_USD` and `GracePeriod` from `Dealing_Islamic_Admin_Fee_Per_Group`.

## 5. Grain

One row per **Date × PositionID** for each Islamic-eligible position open at 22:00 UTC on Date.

## 6. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| Date | date | Report date | Tier 2 | Clustered index key |
| DateID | int | YYYYMMDD of Date | Tier 2 | From SP parameter |
| PositionID | bigint | Position identifier | Tier 1 | FK to Dim_Position |
| RealCID | int | Client ID (Islamic account holder) | Tier 1 | From Dim_Customer |
| GCID | int | Global customer ID | Tier 2 | From Dim_Customer |
| UserName | varchar(20) | Client username | Tier 2 | From Dim_Customer |
| CountryID | int | Client country | Tier 1 | Used for German Crypto exclusion (CountryID=79) |
| OpenDateID | int | Date position opened | Tier 1 | From Dim_Position |
| OpenOccurred | datetime | Exact open timestamp | Tier 1 | From Dim_Position |
| NewOpenOccurred | datetime | Open date adjusted for 22:00 cutoff | Tier 2 | Shifted +1 day if opened after 22:00 UTC |
| IsTheDayBefore | int | 1 if position opened after 22:00 UTC | Tier 2 | Cutoff shift flag |
| CloseDateID | int | Date position closed; 0 if still open | Tier 1 | From Dim_Position |
| CloseOccurred | datetime | Exact close timestamp | Tier 1 | From Dim_Position |
| InstrumentTypeID | int | 1=FX, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto | Tier 1 | From Dim_Instrument |
| InstrumentID | int | Instrument identifier | Tier 1 | FK to Dim_Instrument |
| InstrumentGroup | int | Manual Islamic group ID | Tier 4 | From Dealing_Islamic_Instruments_Groups |
| Units_per_Contract | int | Contract size for Commodities | Tier 4 | From Dealing_Islamic_Units_Per_Contract |
| ExchangeID | int | Exchange ID (day-counting rule selector) | Tier 1 | From Dim_ExchangeInfo |
| IsBuy | int | 1=long, 0=short | Tier 1 | From Dim_Position |
| Leverage | int | Position leverage | Tier 1 | From Dim_Position; Stocks/ETF must be >1 |
| USD_Price | money | EOD USD price: Bid×ConvertRate (IsBuy=1) or Ask×ConvertRate (IsBuy=0) | Tier 2 | From Fact_CurrencyPriceWithSplit |
| AmountInUnitsDecimal | decimal(16,6) | Position size in instrument units | Tier 1 | From Dim_Position |
| Admin_Fee_USD | money | Fee rate per unit-equivalent per day | Tier 4 | From Dealing_Islamic_Admin_Fee_Per_Group |
| Days_Open | int | Effective days open using exchange-appropriate counting | Tier 2 | Includes triple-day multiplier |
| GracePeriod | int | Days before fee starts accruing | Tier 4 | From Dealing_Islamic_Admin_Fee_Per_Group |
| Days_Admin_Fee | int | Days_Open − GracePeriod (net chargeable days) | Tier 2 | SP-computed |
| Days_To_Charge | int | Actual multiplier for today's charge: 0/1/2/3 | Tier 2 | Based on day-of-week and instrument |
| Final_Fee | decimal(16,2) | Computed fee in USD; always ≤ 0 | Tier 1 | Range: -2444.12 to 0.00 |
| Fee_Type_ID | int | Always 1 — administrative fee | Tier 2 | Hardcoded; distinguishes from Spot_Price_Adjustment (Type 2) |
| UpdateDate | datetime | ETL metadata: row write timestamp | Tier 1 | ETL metadata (blacklist canonical) |

## 7. Common Query Patterns

```sql
-- Daily Islamic fee total by instrument type
SELECT Date, InstrumentTypeID, COUNT(*) AS Positions,
       SUM(Final_Fee) AS TotalFee
FROM Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee
WHERE Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY Date, InstrumentTypeID
ORDER BY Date DESC, TotalFee;

-- Positions paying the largest cumulative fee
SELECT PositionID, RealCID, InstrumentID,
       SUM(Final_Fee) AS TotalFee, MAX(Days_Admin_Fee) AS MaxDaysOpen
FROM Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee
WHERE Date >= DATEADD(DAY, -90, GETDATE())
GROUP BY PositionID, RealCID, InstrumentID
ORDER BY TotalFee;
```

> **Performance note**: 17.6M rows, ROUND_ROBIN/CI(Date). Filter by Date for best performance. PositionID is not a distribution key.

## 8. Data Quality & Caveats

- **Volume breakdown (as of 2026-03-10)**: Stocks/CFD 7.28M, Crypto 5.21M, Commodities 2.07M, Indices 1.45M, Currencies 1.13M, ETF 0.48M
- 25 suspended instruments excluded via hardcoded blacklist (SR-258928, 2024-06-26)
- German Crypto exclusion: CountryID=79, leverage=1, IsBuy=1 are excluded (BaFin regulatory carve-out)
- Weekend-closed positions (`ClosedOnWeekend=1`) are excluded from stored rows (commented-out code in SP)
- `Admin_Fee_USD` and `GracePeriod` are manually configured — changes require SP updates

## 9. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment` | Companion futures roll-cost fee (Fee_Type_ID=2) |
| `Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group` | Fee rate config (Admin_Fee_USD, GracePeriod) |
| `Dealing_dbo.Dealing_Islamic_Instruments_Groups` | Manual instrument group assignments |
| `Dealing_dbo.Dealing_Islamic_Units_Per_Contract` | Commodity contract sizes |

## 10. Operational Notes

- **ETL**: `SP_Islamic_Administrative_Fee` runs daily (OpsDB Priority 0). DELETE + INSERT for @Date
- **Author**: Gili Goldbaum. Last SR: SR-343388 (2025-11-17)
- **Instrument scope**: Stocks/ETF (leverage>1, long only), Crypto CFDs, + manual Dealing_Islamic_Instruments_Groups

---
*Quality score: 9.0/10 — Comprehensive SP analysis. Day-counting logic fully documented. Triple-day formulas and formula variants by InstrumentType clearly traced.*
