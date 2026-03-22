# Dealing_dbo.StocksOverrideRateLog

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | StocksOverrideRateLog |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_StocksOverrideRateLog(@Date)` |
| **Refresh** | Daily (Priority 0, SB_Daily) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~6.5M |
| **Date Range** | 2023-08-09 → 2026-03-10 (active ✅) |
| **PII** | None |

---

## 1. Business Meaning

Daily snapshot of all **interest rate override configurations** for stock instruments — both currently active and historical overrides. This table logs which instruments have custom (non-standard) overnight/rollover interest rates applied, distinguishing between:

- **Active overrides**: EndTime sentinel `9999-12-31 23:59:59` → stored as NULL (currently in effect)
- **Historical overrides**: Actual EndTime recorded (previously in effect, now expired)

For each override, the table captures the base interest rate component plus the eToro markup, and computes the total combined rate (Total_Buy/Sell = InterestRate + Markup). Used by Finance and Risk for tracking financing cost configurations, regulatory compliance reporting, and rate change audits.

---

## 2. Grain

One row = one InstrumentID × one override record × one Date. A single instrument may have multiple rows per date if multiple override periods overlap or if both Active and Historical records exist.

---

## 3. Key Columns & Elements

| Column | Type | Description |
|--------|------|-------------|
| `Date` | date | Snapshot date |
| `InstrumentID` | int | Instrument identifier |
| `SymbolFull` | varchar | Full symbol from DWH_dbo.Dim_Instrument |
| `InstrumentDisplayName` | nvarchar | Display name from Dim_Instrument |
| `Exchange` | varchar | Exchange from Dim_Instrument |
| `SellCurrency` | varchar | Instrument's sell currency from Dim_Instrument |
| `InterestRateBuy` | decimal | Base interest rate for buy (long) positions |
| `InterestRateSell` | decimal | Base interest rate for sell (short) positions |
| `MarkupBuy` | decimal | eToro markup added to buy interest rate |
| `MarkupSell` | decimal | eToro markup added to sell interest rate |
| `Total_Buy` | decimal | Combined financing cost for buy: InterestRateBuy + MarkupBuy |
| `Total_Sell` | decimal | Combined financing cost for sell: InterestRateSell + MarkupSell |
| `BeginTime` | datetime | When this override became effective |
| `EndTime` | datetime | When this override expired (NULL = still active; original sentinel '9999-12-31...' converted to NULL) |
| `Status` | varchar(20) | 'Active' or 'Historical' |
| `UpdateDate` | datetime | ETL metadata timestamp |

---

## 4. Common Query Patterns

```sql
-- All currently active overrides (latest date)
SELECT InstrumentID, SymbolFull, InstrumentDisplayName,
       InterestRateBuy, MarkupBuy, Total_Buy,
       InterestRateSell, MarkupSell, Total_Sell,
       BeginTime
FROM Dealing_dbo.StocksOverrideRateLog
WHERE Date = '2026-03-10'
  AND Status = 'Active'
ORDER BY Total_Buy DESC;

-- Rate change history for a specific instrument
SELECT Date, Status, InterestRateBuy, MarkupBuy, Total_Buy, BeginTime, EndTime
FROM Dealing_dbo.StocksOverrideRateLog
WHERE InstrumentID = 1234
ORDER BY Date DESC;

-- Instruments with highest combined financing cost
SELECT SymbolFull, Total_Buy, Total_Sell, BeginTime
FROM Dealing_dbo.StocksOverrideRateLog
WHERE Date = '2026-03-10' AND Status = 'Active'
ORDER BY Total_Buy DESC;
```

---

## 5. Known Issues & Quirks

- **NULL = Active**: `EndTime` is NULL for active overrides (original `9999-12-31 23:59:59.9999999` sentinel is converted to NULL in ETL) — filter `EndTime IS NULL` to get current-only overrides
- **Multiple rows per instrument per date**: An instrument with both an active and a historical override will appear twice on the same Date
- **Source is production eToro Dictionary**: Data comes from `External_Etoro_Dictionary_InterestRateOverride` (active) and `External_Etoro_History_InterestRateOverride` (historical) — reflects real-time production config at time of snapshot

---

## 6. Lineage Summary

Sources: Dealing_staging.External_Etoro_Dictionary_InterestRateOverride (active overrides, EndTime sentinel → NULL) UNION Dealing_staging.External_Etoro_History_InterestRateOverride (historical overrides with actual EndTime) + DWH_dbo.Dim_Instrument (SymbolFull, InstrumentDisplayName, Exchange, SellCurrency). See `.lineage.md` for full column-level map.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_staging.External_Etoro_Dictionary_InterestRateOverride` | Source — active overrides |
| `Dealing_staging.External_Etoro_History_InterestRateOverride` | Source — historical overrides |
| `DWH_dbo.Dim_Instrument` | Instrument metadata enrichment |

---

*Quality score: 8.0/10 — active daily ETL, clear audit-log design, well-structured*
