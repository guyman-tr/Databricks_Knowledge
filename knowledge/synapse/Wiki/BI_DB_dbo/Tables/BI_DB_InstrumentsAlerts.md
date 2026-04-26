---
object: BI_DB_dbo.BI_DB_InstrumentsAlerts
type: table
schema: BI_DB_dbo
status: documented
quality: 8.7
batch: 27
documented_by: claude-sonnet-4-6
documented_date: 2026-04-22
---

# BI_DB_dbo.BI_DB_InstrumentsAlerts

## 1. Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Incremental Daily) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX (FullDate ASC) |
| **Column Count** | 14 |
| **Row Count** | ~642,210 |
| **Grain** | One row per (FullDate, FirstAction, FirstInstrument) |
| **Refresh Pattern** | DELETE WHERE FullDate=@Date + INSERT (date-keyed incremental) |
| **Writer SP** | `SP_InstrumentsAlerts` |
| **Author** | Not documented in SP header |
| **Date Range** | 2019-12-02 — 2026-04-12 |
| **Unique Instruments** | ~11,653 InstrumentIDs |
| **Unique Dates** | 2,090 |
| **UC Target** | Not Migrated |

---

## 2. Business Meaning

**BI_DB_InstrumentsAlerts** is the daily instrument activity alert feed. It tracks how many **first trading actions** customers took on each instrument per day, and provides rolling historical averages (7-day, 14-day, 30-day) to surface instruments with unusual or notable activity spikes.

**Primary use case**: Operations and trading desk monitoring — identify which instruments are experiencing abnormally high first-action activity compared to their recent baseline, triggering review or alert workflows.

**Grain**: One row per (FullDate, FirstAction, FirstInstrument). Activity is split by asset class (`FirstAction`): Stocks/ETFs (66%), Copy (15%), Crypto (10%), FX/Commodities/Indices (7%), Copy Fund (2%).

**Data source**: `BI_DB_First5Actions` — the customer first-action ledger. Only actions that are a customer's "first action" in a new instrument are counted.

**Business Tier column (`[Tier]`)**: Each row is assigned a 0–4 importance tier based on the instrument's prominence within its asset class (see §5.3). This is a business ranking field — it is NOT related to wiki documentation confidence tiers.

---

## 3. Key Gotchas

### 3.1 Column Named `[Tier]` — Not a Documentation Tier
The DDL column `[Tier]` (tinyint) is a **business domain field** ranking instrument importance (0=Copy Fund baseline, 1=most prominent, 4=least prominent). It has no relationship to wiki documentation confidence tiers. Do not confuse the two.

### 3.2 Copy Rows — InstrumentID Contains Popular Investor RealCID
For `FirstAction='Copy'` rows, `FirstInstrument` is the popular investor's `UserName` (not a ticker). `InstrumentID` is resolved as `ISNULL(Dim_Instrument.InstrumentID, Dim_Customer.RealCID)` — since usernames don't match Dim_Instrument.Name, InstrumentID falls back to the popular investor's `RealCID`. This means `InstrumentID` for Copy rows is a customer ID, not an instrument ID.

### 3.3 Non-Crypto Uses Weekdays Only; Crypto Uses All Days
The non-Crypto rolling average scaffold (`#Instrument_dist_date`) uses `Dim_Date WHERE IsWeekend='N'` — only business days count toward the rolling window. The Crypto scaffold includes weekends, since crypto markets operate continuously.

### 3.4 FULL OUTER JOIN on 1=1 — Cartesian Design Pattern
The SP creates date-instrument grids via `FULL OUTER JOIN ON 1=1` between Dim_Date (all dates in window) and the current-day instrument set. This is intentional to create a zero-padded scaffold for window function computation. Only rows where `FullDate=@Date` are inserted.

### 3.5 Exchange Name Normalization
Five exchange names are normalized in the CASE expression: NASDAQ→Nasdaq, Bolsa De Madrid→Bolsa de Madrid, HEL→Helsinki Stock Exchange, OSE→Oslo Stock Exchange, STO→Stockholm Stock Exchange. Queries must use the normalized forms (e.g., 'Nasdaq' not 'NASDAQ').

### 3.6 Blank Industry and Exchange
~17% of rows have a blank Exchange (empty string, not NULL) — these are instrument types where Dim_Instrument does not carry an exchange code (e.g., certain CFDs, Copy instruments). Similarly, Industry may be blank for some instrument types.

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | FullDate | date | YES | Date of the instrument activity alert. Derived from BI_DB_First5Actions.FirstActionDate cast to DATE. Clustered index key. (Tier 2 — SP_InstrumentsAlerts) |
| 2 | DayNumberOfWeek_Sun_Start | tinyint | YES | Day of week number with Sunday=1, Saturday=7. Sourced from Dim_Date. Used for day-of-week filtering in downstream reports. (Tier 2 — SP_InstrumentsAlerts) |
| 3 | FirstAction | varchar(22) | YES | Asset class of the customer's first trading action on this instrument. Values: 'Stocks/ETFs', 'Copy', 'Crypto', 'FX/Commodities/Indices', 'Copy Fund'. Sourced from BI_DB_First5Actions. (Tier 2 — SP_InstrumentsAlerts) |
| 4 | FirstInstrument | varchar(50) | YES | Instrument identifier string. For Stocks/ETFs/Crypto/FX: the instrument ticker (e.g., 'BTC/USD', 'AAPL'). For Copy: the Popular Investor's UserName. Sourced from BI_DB_First5Actions. (Tier 2 — SP_InstrumentsAlerts) |
| 5 | InstrumentDisplayName | varchar(100) | YES | Human-readable instrument name from Dim_Instrument (e.g., 'Bitcoin', 'Apple Inc'). NULL for Copy rows where FirstInstrument is a username with no Dim_Instrument match. (Tier 2 — SP_InstrumentsAlerts) |
| 6 | InstrumentID | int | YES | Numeric instrument identifier. For standard instruments: Dim_Instrument.InstrumentID. For Copy rows where no Dim_Instrument match exists: Dim_Customer.RealCID of the Popular Investor. Not a pure FK to Dim_Instrument for Copy rows. (Tier 2 — SP_InstrumentsAlerts) |
| 7 | Industry | varchar(max) | YES | Industry/sector classification from Dim_Instrument.Industry. Blank for Copy, Copy Fund, and instruments without an industry code in Dim_Instrument. (Tier 2 — SP_InstrumentsAlerts) |
| 8 | Exchange | varchar(max) | YES | Trading exchange from Dim_Instrument, with name normalization applied. Top values: NYSE, Nasdaq, Digital Currency, LSE, FRA, Euronext Paris, FX, Commodity. ~17% blank (no exchange on record). (Tier 2 — SP_InstrumentsAlerts) |
| 9 | Actions | int | YES | Count of first-action events for this instrument on FullDate, across all customers. Derived from COUNT(*) in BI_DB_First5Actions grouped by (Date, FirstAction, FirstInstrument, InstrumentID, Industry, Exchange). (Tier 2 — SP_InstrumentsAlerts) |
| 10 | avg7d_past | numeric(38,1) | YES | Rolling 7-day average of Actions over the 7 preceding business days (excluding FullDate itself). NULL for the first 7 rows of each instrument's history. Crypto window includes weekends; non-Crypto weekdays only. (Tier 2 — SP_InstrumentsAlerts) |
| 11 | avg14d_past | numeric(38,1) | YES | Rolling 14-day average of Actions over the 14 preceding trading days, same window semantics as avg7d_past. (Tier 2 — SP_InstrumentsAlerts) |
| 12 | avg30d_past | numeric(38,1) | YES | Rolling 30-day average of Actions over the 30 preceding trading days, same window semantics. (Tier 2 — SP_InstrumentsAlerts) |
| 13 | UpdateDate | datetime | YES | ETL run timestamp. Set to GETDATE() at INSERT time. (Tier 3 — SP_InstrumentsAlerts) |
| 14 | Tier | tinyint | YES | **Business importance ranking** (0–4) of this instrument within its asset class. 0=Copy Fund baseline; 1=most prominent; 4=least prominent. Ranked by exchange prestige (Stocks), InstrumentID list (Crypto/FX), or GuruStatusID (Copy). See §5.3 for full mapping. This is a business domain field — unrelated to wiki documentation confidence. (Tier 2 — SP_InstrumentsAlerts) |

---

## 5. Business Logic

### 5.1 Two Parallel Pipelines (Non-Crypto and Crypto)

The SP runs two identical pipelines that differ only in:
- **Non-Crypto**: filters `FirstAction <> 'Crypto'`; uses `Dim_Date WHERE IsWeekend='N'` for weekday-only rolling window
- **Crypto**: filters `FirstAction = 'Crypto'`; uses `Dim_Date` without weekend filter (all days)

Both pipelines are then `UNION`'d into a single INSERT for @Date.

### 5.2 Rolling Average Computation

```
Step 1: Count daily actions per instrument in [dateadd(m,-1,@Date), @Date+1day]
Step 2: Create date-instrument scaffold via Dim_Date FULL OUTER JOIN × @Date instruments (ON 1=1)
        → Zero-pad missing dates (ISNULL(Actions, 0))
Step 3: Window AVG over scaffold:
        ROWS BETWEEN N PRECEDING AND 1 PRECEDING (excludes current date)
Step 4: Insert only WHERE FullDate=@Date
```

The rolling averages reflect what the instrument's activity was in the N days **before** FullDate — the current day's Actions is not included in its own averages.

### 5.3 Tier Ranking Logic (business `[Tier]` column)

| FirstAction | Tier=1 | Tier=2 | Tier=3 | Tier=4 |
|-------------|--------|--------|--------|--------|
| **Stocks/ETFs** | Nasdaq, NYSE | Euronext Paris, FRA, LSE | Hong Kong Exchanges, Borsa Italiana, SIX, Euronext Amsterdam | All other exchanges |
| **Crypto** | BTC/ETH/XRP (IDs: 100000,100001,100003) | 6 major coins | 7 mid-tier coins | All others |
| **FX/Commodities/Indices** | Gold, Silver (IDs: 17,18) | 8 major FX pairs/indices | 15 mid-tier instruments | All others |
| **Copy** | GuruStatusID=5 (Elite Popular Investor) | GuruStatusID=2/3/4 | — | All others |
| **Copy Fund** | — | — | — | 0 (ELSE branch — all Copy Fund rows) |

### 5.4 Copy Instrument Resolution
For `FirstAction='Copy'`, the popular investor's UserName is the instrument identifier. The SP joins `Dim_Customer ON UserName = FirstInstrument WHERE IsDepositor=1 AND IsValidCustomer=1 AND GuruStatusID>=1` to retrieve `GuruStatusID` (for Tier CASE) and `RealCID` (as InstrumentID fallback).

---

## 6. Data Evidence

| Metric | Value | Source |
|--------|-------|--------|
| Total rows | 642,210 | COUNT(*) live |
| Unique InstrumentIDs | 11,653 | COUNT(DISTINCT) |
| Unique dates | 2,090 | COUNT(DISTINCT FullDate) |
| Date range | 2019-12-02 — 2026-04-12 | MIN/MAX |
| Last SP run | 2026-04-13 | MAX(UpdateDate) |
| FirstAction distribution | Stocks/ETFs 66.0%, Copy 15.2%, Crypto 10.2%, FX 6.7%, Copy Fund 1.8% | GROUP BY |
| Tier distribution | 0=1.8%, 1=46.0%, 2=25.6%, 3=8.2%, 4=18.4% | GROUP BY |
| Top exchanges | NYSE 22.8%, Nasdaq 18.4%, blank 17.1%, Digital Currency 10.2%, LSE 6.5% | GROUP BY TOP 10 |
| Null avg7/14/30d_past | 0 | COUNT check |

---

## 7. Source Objects

| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_First5Actions | Activity source — customer first-action events per instrument |
| DWH_dbo.Dim_Date | Date scaffold for rolling average window |
| DWH_dbo.Dim_Instrument | Instrument metadata (InstrumentDisplayName, InstrumentID, Industry, Exchange) |
| DWH_dbo.Dim_Customer | Popular Investor lookup for Copy rows (UserName, GuruStatusID, RealCID) |

---

## 8. Dependencies & Usage

**Upstream dependencies**: `BI_DB_First5Actions` must be populated for @Date before `SP_InstrumentsAlerts` runs. `Dim_Instrument` must be current.

**Typical query pattern**:
```sql
-- Instruments with today's Actions > 2x the 30-day average (spike detection)
SELECT FirstAction, FirstInstrument, InstrumentDisplayName, Actions,
       avg30d_past, Actions / NULLIF(avg30d_past, 0) AS spike_ratio
FROM BI_DB_dbo.BI_DB_InstrumentsAlerts
WHERE FullDate = CAST(GETDATE() AS DATE)
  AND avg30d_past > 0
  AND Actions > 2 * avg30d_past
ORDER BY spike_ratio DESC;
```
