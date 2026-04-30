# Hedge.HedgeCostReportHistory

> Historical version of Hedge.HedgeCostReport that reads from the History schema instead of the live Hedge schema, enabling hedge cost analysis over archived data beyond the live tables' retention window.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate + @EndDate + optional @HedgeServerID + @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.HedgeCostReportHistory` is the long-range historical variant of `Hedge.HedgeCostReport`. It applies the same four-source daily aggregation and delta pipeline, but reads from `History.CustomerClosedPositions`, `History.CustomerOpenPositions`, `History.AccountClosedPositions`, and `History.AccountOpenPositions` instead of the live `Hedge.*` tables.

This separation allows the hedge cost report to work across two data horizons:
- **Recent data (last N days)**: call `Hedge.HedgeCostReport` - reads from live operational tables
- **Historical data (older than retention window)**: call `Hedge.HedgeCostReportHistory` - reads from archived History schema tables

The History schema tables are the archival destination for the live Hedge tables after data is aged out or bulk-archived (typically by `Hedge.ArchiveHedgeTables` or `Hedge.ArchiveHedgeTables_SS`).

There are three important behavioral differences from `Hedge.HedgeCostReport`:

1. **Commission ISNULL wrapping**: CommissionOnClose and CommissionOnOpen are wrapped in `ISNULL(..., 0.00)` in the computed table, providing explicit NULL-safe handling. The live version omits this wrapper.

2. **Unrealized hedge cost formula uses UnrealizedPL (not UnrealizedZeroPL)**: The History version computes `[Hedge Cost - Unrealized] = ISNULL(UnrealizedPL, 0) - ISNULL(UnrealizedNetPL, 0)`, using customer actual P&L rather than zero-cost P&L as the baseline. The live version uses `UnrealizedZeroPL`. This is a meaningful semantic difference - results from the two procedures are not directly comparable on the unrealized component.

3. **Division-by-zero protection on percentage columns**: The History version wraps all percentage calculations in `CASE WHEN commission=0 THEN '--' ELSE CAST(value AS varchar) END`, returning '--' when commission is zero. The percentage columns therefore return `varchar` type. The live version returns `decimal` type and does not protect against division by zero.

---

## 2. Business Logic

### 2.1 Four-Source Historical Pipeline (History Schema)

**What**: Identical to Hedge.HedgeCostReport but sourcing from History.* tables. All four temp tables are populated with historical data using the same aggregation and delta logic.

**Sources**:
1. `History.CustomerClosedPositions` -> `#Hedge_Cost_Report_CustomerClosedPositions`: Daily SUM of NetPL, CommissionOnClose, ZeroPL for historically closed customer positions
2. `History.CustomerOpenPositions` -> `#Hedge_Cost_Report_CustomerOpenPositions`: Day-over-day DELTA of UnrealizedPL, CommissionOnOpen, UnrealizedZeroPL
3. `History.AccountClosedPositions` -> `#Hedge_Cost_Report_AccountClosedPositions`: Daily SUM of NetPL for historically closed LP account positions
4. `History.AccountOpenPositions` -> `#Hedge_Cost_Report_AccountOpenPositions`: Day-over-day DELTA of UnrealizedNetPL

**Rules** (identical to live version):
- Saturday exclusion: `DATENAME(dw, OccurredAt) != 'Saturday'`
- @EndDate adjusted: `SET @EndDate = DATEADD(dd, 1, @EndDate)` (exclusive upper bound)
- Open position delta reads from DATEADD(DAY, -1, @StartDate) for baseline
- Zero-fill safety: Trade.HedgeServer FULL JOIN Trade.Instrument on 1=1 when no data

### 2.2 Key Formula Difference: UnrealizedPL vs UnrealizedZeroPL in Hedge Cost

**What**: The unrealized hedge cost uses `UnrealizedPL` (customer actual unrealized P&L) as the customer baseline, NOT `UnrealizedZeroPL` as in the live version.

**Columns/Parameters Involved**: `UnrealizedPL`, `UnrealizedZeroPL`, `UnrealizedNetPL`

**Rules**:
- History version: `[Hedge Cost - Unrealized] = ISNULL(b1.UnrealizedPL, 0) - ISNULL(d1.UnrealizedNetPL, 0)`
  - Uses actual customer P&L (includes spread/rollover effects)
- Live version: `[Hedge Cost - Unrealized] = b1.UnrealizedZeroPL - d1.UnrealizedNetPL`
  - Uses theoretical zero-cost customer P&L (excludes spread/rollover)
- Impact: The History version will show higher hedge cost when customers have negative unrealized P&L from spread/rollover, since the actual P&L (worse) vs zero-cost P&L (better) produces a larger gap vs LP account P&L.

### 2.3 Division-by-Zero Protection on Percentage Columns

**What**: All three percentage columns in the History version use CASE WHEN to return '--' when total commission is zero, preventing arithmetic errors on zero-commission periods.

**Rules**:
- `CASE WHEN [Etoro Commission - Realized] + [Etoro Commission - Unrealized] = 0 THEN '--' ELSE CAST(value AS varchar) END`
- This makes percentage output columns **varchar** type (not decimal as in the live version)
- The live version would produce a divide-by-zero error for zero-commission periods

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | YES | '2010-01-01' | VERIFIED | Start of the historical reporting period. Baseline day is @StartDate-1 for open position deltas. |
| 2 | @EndDate | datetime | YES | '2010-01-01' | VERIFIED | End of the reporting period (inclusive). Internally adjusted to @EndDate+1 day (exclusive BETWEEN upper bound). |
| 3 | @isDetailed | bit | YES | 1 | VERIFIED | Vestigial parameter - defined but never used in the procedure body. Identical behavior to Hedge.HedgeCostReport. |
| 4 | @HedgeServerID | int | YES | 0 | VERIFIED | Filter to specific hedge server. 0=all servers. Applies to all four History sources. |
| 5 | @InstrumentID | int | YES | 0 | VERIFIED | Filter to specific instrument. 0=all instruments. Applies to all four History sources. |

**Output columns** (same names as Hedge.HedgeCostReport but with type differences on percentage columns):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | Date | datetime | NO | - | VERIFIED | Reporting day. Totals row: MAX(Date) + 1 minute. |
| 7 | Hedge Server ID | int | YES | - | VERIFIED | Hedge server ID. Totals row: @HedgeServerID parameter value. |
| 8 | Instrument | int | YES | - | VERIFIED | Instrument ID. Totals row: @InstrumentID parameter value. |
| 9 | Clients P&L - Realized | decimal | NO | 0 | VERIFIED | Daily SUM NetPL from History.CustomerClosedPositions. |
| 10 | Etoro Commission - Realized | decimal | NO | 0 | VERIFIED | Daily SUM CommissionOnClose (ISNULL-wrapped). Zero-safe. |
| 11 | Etoro Zero | decimal | YES | - | VERIFIED | Daily SUM ZeroPL from History.CustomerClosedPositions. |
| 12 | Clients P&L - Unrealized | decimal | YES | - | VERIFIED | Daily DELTA UnrealizedPL from History.CustomerOpenPositions. |
| 13 | Etoro Commission - Unrealized | decimal | NO | 0 | VERIFIED | Daily DELTA CommissionOnOpen (ISNULL-wrapped). Zero-safe. |
| 14 | Etoro Zero - Unrealized | decimal | YES | - | VERIFIED | Daily DELTA UnrealizedZeroPL from History.CustomerOpenPositions. Present in output but NOT used in hedge cost formula (unlike live version). |
| 15 | Account Diff - Realized | decimal | YES | - | VERIFIED | Daily SUM NetPL from History.AccountClosedPositions. |
| 16 | Account P&L - Unrealized | decimal | YES | - | VERIFIED | Daily DELTA UnrealizedNetPL from History.AccountOpenPositions. |
| 17 | Rebate | decimal | NO | 0 | VERIFIED | Hardcoded 0. Same as live version. |
| 18 | Hedge Cost - Realized | decimal | NO | 0 | VERIFIED | Realized hedge cost: ISNULL(ZeroPL,0) - ISNULL(AccountNetPL,0). Explicit NULL-safe formula (unlike live version). |
| 19 | Hedge Cost - Unrealized | decimal | NO | 0 | VERIFIED | Unrealized hedge cost: ISNULL(UnrealizedPL,0) - ISNULL(UnrealizedNetPL,0). Uses actual UnrealizedPL (NOT ZeroPL), differing from the live version. |
| 20 | Total Hedge Cost | decimal | NO | 0 | VERIFIED | Sum of realized and unrealized hedge cost. |
| 21 | Total Hedge Cost % | varchar | YES | '--' | VERIFIED | Hedge cost as % of commission. Returns '--' when commission=0 (division-by-zero protection). VARCHAR type (unlike decimal in live version). |
| 22 | Hedge Cost with Rebate % | varchar | YES | '--' | VERIFIED | Hedge cost (minus rebate) as % of commission. VARCHAR type with '--' protection. |
| 23 | Overall H.C Contribution % | varchar | YES | '--' | VERIFIED | Row's hedge cost as % of total period commission. VARCHAR type with '--' protection. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | History.CustomerClosedPositions | SELECT (temp #1) | Archived historical customer realized P&L. Archive destination from Hedge.CustomerClosedPositions. |
| (reads) | History.CustomerOpenPositions | SELECT (temp #2 delta) | Archived historical customer unrealized P&L time-series. |
| (reads) | History.AccountClosedPositions | SELECT (temp #3) | Archived historical LP account realized P&L. |
| (reads) | History.AccountOpenPositions | SELECT (temp #4 delta) | Archived historical LP account unrealized P&L time-series. |
| (zero-fill) | Trade.HedgeServer | FULL JOIN (zero-fill) | Provides HedgeServerID list when History sources are empty for the period. |
| (zero-fill) | Trade.Instrument | FULL JOIN (zero-fill) | Provides InstrumentID list when History sources are empty for the period. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge reporting application / BI | - | Caller | Called for long-range historical hedge cost analysis beyond the live tables' retention window. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeCostReportHistory (procedure)
├── History.CustomerClosedPositions (table) [cross-schema]
├── History.CustomerOpenPositions (table) [cross-schema]
├── History.AccountClosedPositions (table) [cross-schema]
├── History.AccountOpenPositions (table) [cross-schema]
├── Trade.HedgeServer (table) [cross-schema, zero-fill only]
└── Trade.Instrument (table) [cross-schema, zero-fill only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CustomerClosedPositions | Table | Temp #1: historical archived customer realized P&L |
| History.CustomerOpenPositions | Table | Temp #2: historical archived customer unrealized P&L delta |
| History.AccountClosedPositions | Table | Temp #3: historical archived LP account realized P&L |
| History.AccountOpenPositions | Table | Temp #4: historical archived LP account unrealized P&L delta |
| Trade.HedgeServer | Table | Zero-fill safety - provides server list when no historical data exists |
| Trade.Instrument | Table | Zero-fill safety - provides instrument list when no historical data exists |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge reporting / BI tools | External | READER - long-range historical hedge cost analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Same temp table pattern and delta computation as Hedge.HedgeCostReport. Performance for historical queries over large History schema tables can be significantly higher than live queries - History tables may contain years of data. Appropriate date range filtering and History table indexes on (HedgeServerID, InstrumentID, OccurredAt) are essential for acceptable query time.

### 7.2 Constraints

N/A for Stored Procedure. Critical behavioral differences vs Hedge.HedgeCostReport (see Section 1):
1. Unrealized hedge cost uses `UnrealizedPL` (not `UnrealizedZeroPL`) - results not directly comparable with live report
2. Percentage columns return varchar (not decimal) - downstream consumers must handle '--' values
3. Commission columns are ISNULL-wrapped - NULL-safe behavior in History version
4. Division-by-zero protection present in History version; live version would error on zero-commission periods

---

## 8. Sample Queries

### 8.1 Run historical hedge cost report for a date range
```sql
EXEC [Hedge].[HedgeCostReportHistory]
    @StartDate     = '2025-01-01',
    @EndDate       = '2025-12-31',
    @isDetailed    = 1,
    @HedgeServerID = 0,
    @InstrumentID  = 0;
```

### 8.2 Historical report for a specific server and instrument
```sql
EXEC [Hedge].[HedgeCostReportHistory]
    @StartDate     = '2025-06-01',
    @EndDate       = '2025-06-30',
    @isDetailed    = 1,
    @HedgeServerID = 1,
    @InstrumentID  = 1;
```

### 8.3 Combine live and historical hedge cost reports
```sql
-- Recent (live):
EXEC [Hedge].[HedgeCostReport]
    @StartDate = '2026-01-01', @EndDate = '2026-03-18',
    @isDetailed = 1, @HedgeServerID = 0, @InstrumentID = 0;

-- Historical (archived):
EXEC [Hedge].[HedgeCostReportHistory]
    @StartDate = '2024-01-01', @EndDate = '2025-12-31',
    @isDetailed = 1, @HedgeServerID = 0, @InstrumentID = 0;
-- NOTE: Unrealized hedge cost is computed differently between the two - compare carefully
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeCostReportHistory | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.HedgeCostReportHistory.sql*
