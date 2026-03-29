# Dealing_dbo.Dealing_MCS_Model_Report

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_MCS_Model_Report |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_MCS_Model_Report(@dd)` |
| **Refresh** | Daily (Priority 0, SB_Daily) |
| **Distribution** | HASH(`PositionID`) |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~1.116B |
| **Date Range** | 2023-09-01 → 2026-03-10 (active ✅) |
| **PII** | None |

---

## 1. Business Meaning

Daily position-level report for Real Stocks and ETFs, used to validate the MCS (Market Coverage Score) model. Each row represents one position on one date, capturing position metadata, volume (in USD), and click counts (open/close events). The table enables analysis of how stock and ETF positions contribute to daily trading activity, supporting model validation for position management and risk coverage.

"MCS Model" likely refers to an internal risk or market coverage model. The table tracks each position's contribution to daily volume and click activity separately from their aggregate totals — enabling both individual position analysis and day-level aggregation.

---

## 2. Grain

One row = one position (`PositionID`) on one `Date`. A position that was both opened and closed on the same day appears once with combined open+close click/volume counts.

---

## 3. Key Columns & Elements

| Column | Type | Description |
|--------|------|-------------|
| `Date` | date | Report date |
| `PositionID` | bigint | Position identifier — HASH distribution key |
| `CID` | int | Client identifier |
| `InstrumentID` | int | Instrument identifier |
| `InstrumentTypeID` | int | 5=Real Stocks, 6=ETFs (only values in this table) |
| `InstrumentType` | varchar(50) | 'Stock' or 'ETF' |
| `Name` | nvarchar(255) | Instrument name (from Dim_Instrument.Name — full legal name) |
| `Symbol` | varchar(100) | Ticker symbol |
| `CountryID` | int | Client's country ID |
| `Country_Name` | varchar(50) | Client's country name (denormalized) |
| `OpenDateID` | int | Position open date as integer (YYYYMMDD) |
| `CloseDateID` | int | Position close date (0 if still open) |
| `OpenOccurred` | datetime | Exact open timestamp |
| `CloseOccurred` | datetime | Exact close timestamp |
| `Leverage` | int | Position leverage |
| `IsSettled` | int | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| `IsBuy` | bit | 1=Long, 0=Short |
| `Units` | decimal(16,6) | Position size in units (AmountInUnitsDecimal) |
| `Commission` | money | Full commission charged (FullCommission) |
| `Volume` | int | USD volume at open price |
| `VolumeOnClose` | int | USD volume at close price |
| `Volume_Open_Position` | int | Volume contribution from opening (Volume if OpenDateID=Date, else 0) |
| `Volume_Close_Position` | int | Volume contribution from closing (VolumeOnClose if CloseDateID=Date, else 0) |
| `Total_daily_Volume` | int | Total daily volume contribution (open+close for the day) |
| `Click_Open_Position` | int | 1 if opened today, 0 if pre-existing |
| `Click_Close_Position` | int | 1 if closed today, 0 if still open |
| `Total_daily_clicks` | int | Total click count (1 for open-only, 1 for close-only, 2 for same-day) |
| `UpdateDate` | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline |

---

## 4. Common Query Patterns

```sql
-- Daily stock/ETF activity summary
SELECT Date, InstrumentType,
       COUNT(DISTINCT PositionID) AS Positions,
       SUM(Total_daily_Volume) AS TotalVolume,
       SUM(Total_daily_clicks) AS TotalClicks
FROM Dealing_dbo.Dealing_MCS_Model_Report
WHERE Date = '2026-03-10'
GROUP BY Date, InstrumentType;

-- High-volume positions on a date
SELECT PositionID, CID, Name, Symbol, IsBuy, Units, Volume, Total_daily_Volume
FROM Dealing_dbo.Dealing_MCS_Model_Report
WHERE Date = '2026-03-10'
ORDER BY Total_daily_Volume DESC;
```

> ⚠️ **1.116B rows** — always use Date filter. COUNT(*) requires `COUNT_BIG(*)`.

---

## 5. Known Issues & Quirks

- **Volume_Open_Position logic**: For positions that were both opened and closed on the same day, both Volume_Open_Position and Volume_Close_Position are populated (sum = Total_daily_Volume)
- **Scope**: InstrumentTypeID IN (5,6) only — no CFD stocks, no crypto, no FX/commodities
- **IsValidCustomer=1**: Filters out eToro employees and test accounts
- **HASH(PositionID)**: Good for position-keyed joins; can cause skew for queries by Date without a range filter

---

## 6. Lineage Summary

Sources: DWH_dbo.Dim_Position + Dim_Instrument + Dim_Customer + Dim_Country. No production database ingestion — reads DWH dimensions. See `.lineage.md` for full column-level map.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `DWH_dbo.Dim_Position` | Primary source — position data |
| `DWH_dbo.Dim_Instrument` | Instrument metadata (InstrumentTypeID IN 5,6 filter) |
| `DWH_dbo.Dim_Customer` | Client country, IsValidCustomer filter |

---

*Quality score: 8.0/10 — active, well-structured, large table*
