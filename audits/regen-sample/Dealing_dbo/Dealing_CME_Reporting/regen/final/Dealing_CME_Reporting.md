# Dealing_dbo.Dealing_CME_Reporting

> 712-row monthly aggregation table tracking CME (Chicago Mercantile Exchange) reporting obligations for eToro -- recording distinct valid customer counts and total trading volume per CME-reportable instrument per calendar month, from July 2023 to present. Populated by SP_M_CME_Reporting on a monthly cadence.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Aggregated from DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument via SP_M_CME_Reporting |
| **Refresh** | Monthly (SP_M_CME_Reporting @Date, DELETE+INSERT for the reporting month) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | Synapse-only reporting table |

---

## 1. Business Meaning

`Dealing_dbo.Dealing_CME_Reporting` is a regulatory reporting table that supports eToro's CME (Chicago Mercantile Exchange) reporting obligations. Each row represents one CME-reportable instrument's monthly summary: how many distinct valid customers traded it and what total volume was generated across all open and close events during that calendar month.

The table covers 46 distinct instrument display names across 33 months (2023-07-31 to 2026-03-31), with typically 19-22 instruments reported per month. The instrument universe includes commodity futures (Crude Oil, Natural Gas, Copper, Wheat, Corn, Soybeans, etc.), financial futures (Treasury bonds), and index products (NASDAQ100, SPX500, DJ30, JPN225) -- all instruments listed on or related to CME Group exchanges.

**ETL pattern**: SP_M_CME_Reporting runs monthly with `@Date` = the last day of the previous month. It:
1. Builds a hardcoded instrument filter (24 specific InstrumentIDs + any instrument with "crude oil" in the display name)
2. Collects all open and close positions from Dim_Position for the month, joined to Dim_Customer (IsValidCustomer=1)
3. DELETEs existing rows for the reporting month-end date
4. INSERTs aggregated rows: COUNT(DISTINCT CID) and SUM(Volume) per instrument, with crude oil variants consolidated under 'Crude Oil Future'

**Service request history**: Created 2024-01-01 (SR-225467, Sarah Benchitrit). Updated 2024-07-14 (SR-261943, crude oil instrument name changes). Updated 2025-03-05 (SR-303463, 3 instruments added).

---

## 2. Business Logic

### 2.1 Instrument Selection

**What**: A hardcoded list of CME-reportable instruments defines which positions are included in the report.

**Columns Involved**: `InstrumentDisplayName`

**Rules**:
- 24 specific InstrumentIDs are hardcoded in the SP: 21, 22, 27, 28, 29, 36, 91, 97, 312, 313, 314, 317, 318, 324, 325, 331, 332, 335, 336, 337, 338, 380, 381, 382
- Any instrument where `LOWER(InstrumentDisplayName) LIKE '%crude oil%' AND LOWER(InstrumentDisplayName) LIKE '%future%'` is also included
- The instrument list is resolved via `DWH_dbo.Dim_Instrument`
- As of 2026-03-31, 46 distinct instrument display names appear (some IDs map to both expiring and non-expiring variants)

### 2.2 Crude Oil Consolidation

**What**: Multiple crude oil instrument variants are consolidated into a single 'Crude Oil Future' display name.

**Columns Involved**: `InstrumentDisplayName`

**Rules**:
- CASE expression in the final INSERT: `WHEN LOWER(p.InstrumentDisplayName) LIKE '%crude oil%' THEN 'Crude Oil Future' ELSE p.InstrumentDisplayName END`
- This means all crude oil futures (different expiries, WTI variants) appear as one row per month
- CID_Count and Monthly_Volume are aggregated across all crude oil variants

### 2.3 Volume Calculation

**What**: Monthly_Volume combines both open-side and close-side volume for each instrument.

**Columns Involved**: `Monthly_Volume`, `CID_Count`

**Rules**:
- Open positions: `CAST(dp.OpenOccurred AS date)` as the Date, `dp.Volume` as the volume metric, filtered by `OpenDateID BETWEEN @StartOfMonthID AND @EndOfMonthID`
- Close positions: `CAST(dp.CloseOccurred AS date)` as the Date, `dp.VolumeOnClose` as the volume metric, filtered by `CloseDateID BETWEEN @StartOfMonthID AND @EndOfMonthID`
- The two sets are UNION ALL'd, then aggregated: `COUNT(DISTINCT CID)` and `SUM(CAST(Volume AS bigint))`
- Only valid customers are included: `LEFT JOIN Dim_Customer dc ON dc.RealCID = dp.CID WHERE dc.IsValidCustomer = 1`
- A customer who both opens and closes positions in the same month is counted once (DISTINCT)

### 2.4 Monthly Cadence and Date Semantics

**What**: The Date column always holds the last calendar day of the reporting month.

**Columns Involved**: `Date`

**Rules**:
- `@Date` parameter = yesterday (end of previous month)
- `@FirstOfMonth = DATEADD(day, 1, @Date)` = first day of current month
- `@EndOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FirstOfMonth), -1)` = last day of previous month
- DELETE + INSERT pattern ensures idempotency: re-running for the same month replaces the data

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution: rows spread evenly across compute nodes with no affinity. Suitable for this small table (712 rows). CLUSTERED INDEX on `Date ASC` supports date-range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get latest month's report | `WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_CME_Reporting)` |
| Monthly trend for one instrument | `WHERE InstrumentDisplayName = 'NASDAQ100 Index (Non Expiry)' ORDER BY Date` |
| Top instruments by customer count | `WHERE Date = '2026-03-31' ORDER BY CID_Count DESC` |
| Year-over-year volume comparison | Compare `WHERE Date = '2025-03-31'` vs `WHERE Date = '2026-03-31'` |
| All crude oil data | `WHERE InstrumentDisplayName = 'Crude Oil Future'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON Dim_Instrument.InstrumentDisplayName = Dealing_CME_Reporting.InstrumentDisplayName | Resolve instrument metadata (InstrumentID, type, ISIN). Note: crude oil consolidated name won't match individual instruments. |

### 3.4 Gotchas

- **Date is always month-end**: The Date column holds the last calendar day of the reporting month (e.g., 2026-03-31), not an arbitrary date. Do not filter with arbitrary date ranges expecting daily granularity.
- **Crude oil consolidation**: All crude oil futures variants are merged into 'Crude Oil Future'. You cannot break out individual crude oil contracts from this table.
- **Volume is bidirectional**: Monthly_Volume includes BOTH open-side volume (Volume from Dim_Position) and close-side volume (VolumeOnClose). It is NOT a net or one-directional figure.
- **CID_Count is deduplicated**: A customer who opens and closes positions on the same instrument in the same month is counted only once (COUNT DISTINCT across the UNION ALL).
- **Instrument list changes over time**: The SP's hardcoded instrument list has been updated twice (SR-261943, SR-303463). Historical months reflect the instrument list at the time of execution. Re-running with a newer SP version would change the instrument coverage for historical months.
- **Valid customers only**: The report filters on `Dim_Customer.IsValidCustomer = 1`. Demo accounts, internal accounts, and other non-valid customers are excluded.
- **No UC migration**: This table is Synapse-only (`_Not_Migrated`). Query it directly on Synapse.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 -- Synapse SP code | (Tier 2 -- SP_M_CME_Reporting) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Last calendar day of the reporting month. ETL-computed: @EndOfMonth derived from @Date parameter via DATEADD(MONTH, DATEDIFF(MONTH, 0, @FirstOfMonth), -1). E.g., 2026-03-31 for the March 2026 report. (Tier 2 -- SP_M_CME_Reporting) |
| 2 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name from Dim_Instrument.InstrumentDisplayName. CASE-transformed: all instruments where LOWER(name) LIKE '%crude oil%' are consolidated into 'Crude Oil Future'; all others pass through as-is. 46 distinct values as of 2026-03-31. (Tier 2 -- SP_M_CME_Reporting) |
| 3 | CID_Count | int | YES | Count of distinct valid customers (IsValidCustomer=1) who opened or closed positions on this instrument during the reporting month. Computed as COUNT(DISTINCT CID) across a UNION ALL of open-side and close-side position records from Dim_Position. (Tier 2 -- SP_M_CME_Reporting) |
| 4 | Monthly_Volume | bigint | YES | Total trading volume for the instrument during the reporting month. Computed as SUM(CAST(Volume AS bigint)) where Volume = Dim_Position.Volume for open-side positions and Dim_Position.VolumeOnClose for close-side positions, combined via UNION ALL. Values range from ~52K to ~72B. (Tier 2 -- SP_M_CME_Reporting) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at insert time by SP_M_CME_Reporting. Does NOT reflect a business event date. (Tier 2 -- SP_M_CME_Reporting) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | ETL-computed | — | @EndOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FirstOfMonth), -1) |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | CASE: crude oil variants → 'Crude Oil Future', else passthrough |
| CID_Count | DWH_dbo.Dim_Position | CID | COUNT(DISTINCT CID) from open + close positions |
| Monthly_Volume | DWH_dbo.Dim_Position | Volume, VolumeOnClose | SUM(CAST(Volume AS bigint)) from UNION ALL of open + close |
| UpdateDate | ETL-computed | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Instrument (15,707 rows, REPLICATE)
  |-- #Ins: filter to 24 hardcoded IDs + crude oil futures --|
  v
DWH_dbo.Dim_Position (billions of rows, HASH(PositionID))
  |-- JOIN #Ins ON InstrumentID
  |-- LEFT JOIN DWH_dbo.Dim_Customer ON RealCID = CID (WHERE IsValidCustomer = 1)
  |-- WHERE OpenDateID / CloseDateID BETWEEN @StartOfMonthID AND @EndOfMonthID
  v
#Positions (open + close UNION ALL)
  |-- GROUP BY InstrumentDisplayName (crude oil CASE)
  |-- COUNT(DISTINCT CID), SUM(CAST(Volume AS bigint))
  v
SP_M_CME_Reporting (DELETE @EndOfMonth + INSERT)
  v
Dealing_dbo.Dealing_CME_Reporting (712 rows, ROUND_ROBIN)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | Display name sourced from Dim_Instrument, with crude oil consolidation |
| CID_Count | DWH_dbo.Dim_Position | Aggregated from Dim_Position.CID (distinct valid customers) |
| Monthly_Volume | DWH_dbo.Dim_Position | Aggregated from Dim_Position.Volume and VolumeOnClose |

### 6.2 Referenced By (other objects point to this)

No downstream consumers found. This table is a terminal reporting artifact.

---

## 7. Sample Queries

### 7.1 Latest Month CME Report Summary

```sql
SELECT InstrumentDisplayName,
       CID_Count,
       Monthly_Volume,
       UpdateDate
FROM Dealing_dbo.Dealing_CME_Reporting
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_CME_Reporting)
ORDER BY CID_Count DESC;
```

### 7.2 Monthly Trend for a Specific Instrument

```sql
SELECT Date,
       CID_Count,
       Monthly_Volume
FROM Dealing_dbo.Dealing_CME_Reporting
WHERE InstrumentDisplayName = 'NASDAQ100 Index (Non Expiry)'
ORDER BY Date;
```

### 7.3 Year-over-Year Comparison

```sql
SELECT a.InstrumentDisplayName,
       a.CID_Count AS CID_2025,
       b.CID_Count AS CID_2026,
       a.Monthly_Volume AS Vol_2025,
       b.Monthly_Volume AS Vol_2026
FROM Dealing_dbo.Dealing_CME_Reporting a
JOIN Dealing_dbo.Dealing_CME_Reporting b
  ON a.InstrumentDisplayName = b.InstrumentDisplayName
WHERE a.Date = '2025-03-31'
  AND b.Date = '2026-03-31'
ORDER BY b.CID_Count DESC;
```

---

## 8. Atlassian Knowledge Sources

- **SR-225467**: Initial creation of CME Reporting obligation (Sarah Benchitrit, 2024-01-01)
- **SR-261943**: Updated crude oil instruments based on new naming convention (Sarah, 2024-07-14)
- **SR-303463**: Added 3 instruments to the CME-reportable list (Sarah, 2025-03-05)

---

*Generated: 2026-04-27 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 8/10, Lineage: 8/10*
*Object: Dealing_dbo.Dealing_CME_Reporting | Type: Table | Production Source: DWH_dbo.Dim_Position + Dim_Instrument via SP_M_CME_Reporting*
