# Trade.SSRSInstrumentAsync_PositionsOpenAndClose

> SSRS instrument async-migration impact report that compares position open and close volumes per instrument for 90 days before vs. after its migration to asynchronous order processing, expressed as daily rates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - driven by InstrumentAsyncDate Azure source |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When the trading platform migrates an instrument from synchronous to asynchronous order processing (a significant architectural change), this procedure measures whether that migration changed trading volume on that instrument. It compares the average daily opens and closes in the 90 days before `MovedToAsync` against the days after, allowing operations and product teams to answer: "Did going async affect customer activity on this instrument?"

The procedure exists to provide a data-driven impact assessment tool for the async instrument rollout programme. Without it, evaluating each instrument's migration individually would require custom ad-hoc queries. The procedure standardises this analysis across all migrated instruments simultaneously.

Data flows as follows: the list of migrated instruments and their migration dates is pulled from an Azure secondary database (`PositionFailRealAzureSecondary.PositionFailReal.History.InstrumentAsyncDate`). For each instrument, opens (from `Trade.PositionTbl` and `History.Position_Active`) and closes (from `History.Position_Active`) within a 90-day pre-migration window and all post-migration days are counted. The final result normalises these counts to per-day rates for a fair comparison.

---

## 2. Business Logic

### 2.1 Before vs After Async Classification

**What**: Classifies each position as opened/closed before or after its instrument was migrated to async processing.

**Columns/Parameters Involved**: `Occurred` / `OpenOccurred` / `CloseOccurred`, `MovedToAsync`

**Rules**:
- Open positions: if `Occurred >= MovedToAsync` -> 'Open After Async', else 'Open Before Async'.
- Historical positions (opens): if `OpenOccurred >= MovedToAsync` -> 'Open After Async', else 'Open Before Async'.
- Historical positions (closes): if `CloseOccurred >= MovedToAsync` -> 'Closed After Async', else 'Closed Before Async'.
- The 90-day pre-migration window filter (`Occurred > DATEADD(day, -90, MovedToAsync)`) ensures a symmetric comparison basis.

**Diagram**:
```
[MovedToAsync - 90 days] ---|--- [MovedToAsync] ---|--- [Today]
        BEFORE ASYNC window            AFTER ASYNC window
        (fixed 90 days)                (grows daily)

  DaysCountBeforeAsync = 90
  DaysCountAfterAsync  = DATEDIFF(DAY, MovedToAsync, GETDATE())
```

### 2.2 Per-Day Rate Normalisation

**What**: Converts raw counts to per-day averages to allow fair before/after comparison despite different window lengths.

**Columns/Parameters Involved**: `DaysCountBeforeAsync`, `DaysCountAfterAsync`, per-day rate columns

**Rules**:
- Before window: always 90 days (`DaysCountBeforeAsync = DATEDIFF(DAY, dateadd(day,-90,MovedToAsync), MovedToAsync)`).
- After window: variable length (`DaysCountAfterAsync = DATEDIFF(DAY, MovedToAsync, GETDATE())`).
- Per-day rate = `Total * 1.00 / DayCount`. The `* 1.00` ensures decimal division (not integer).
- `ISNULL(..., 0)` guards against NULL when DaysCountAfterAsync is 0 (instrument just migrated).

### 2.3 Data Sources Union (Open and Close)

**What**: Combines live open positions and historical (closed) positions to get a complete activity picture.

**Columns/Parameters Involved**: `Trade.PositionTbl`, `History.Position_Active`

**Rules**:
- Open positions currently active: from `Trade.PositionTbl` using `Occurred` timestamp.
- All positions (open and closed that have moved to history): from `History.Position_Active` using both `OpenOccurred` and `CloseOccurred`.
- Trade.PositionTbl and History.Position_Active are UNION ALL'd for opens, and History.Position_Active is used separately for closes.
- The 90-day window filter applies to both sources.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

This procedure has no input parameters.

### Output Columns (Result Set)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. FK to Trade.InstrumentMetaData.InstrumentID. Each row represents one instrument that has been migrated to async processing. |
| 2 | From Date | DATETIME | NO | - | CODE-BACKED | Start of the pre-async comparison window: MovedToAsync minus 90 days. The 90-day before-async period begins here. |
| 3 | MovedToAsync | DATETIME | NO | - | CODE-BACKED | Timestamp when this instrument was migrated from synchronous to asynchronous order processing. The dividing line between before/after windows. Sourced from PositionFailRealAzureSecondary.History.InstrumentAsyncDate. |
| 4 | DaysCountBeforeAsync | INT | NO | - | CODE-BACKED | Number of days in the before-async comparison window. Always 90 (fixed window). Used as denominator for per-day rate calculations. |
| 5 | DaysCountAfterAsync | INT | NO | - | CODE-BACKED | Number of days since the instrument went async (from MovedToAsync to today). Grows daily. Used as denominator for after-async per-day rates. |
| 6 | Total Open After Async | INT | NO | - | CODE-BACKED | Total positions opened on this instrument after MovedToAsync (all days to present). ISNULL-defaulted to 0. |
| 7 | Total Open Before Async | INT | NO | - | CODE-BACKED | Total positions opened on this instrument in the 90 days before MovedToAsync. ISNULL-defaulted to 0. |
| 8 | Total Closed After Async | INT | NO | - | CODE-BACKED | Total positions closed on this instrument after MovedToAsync. ISNULL-defaulted to 0. |
| 9 | Total Closed Before Async | INT | NO | - | CODE-BACKED | Total positions closed on this instrument in the 90 days before MovedToAsync. ISNULL-defaulted to 0. |
| 10 | Total Open After Async Per Day | DECIMAL | NO | - | CODE-BACKED | Average daily position opens after async migration: Total Open After Async / DaysCountAfterAsync. 0 when DaysCountAfterAsync is 0. Comparable to the Before value. |
| 11 | Total Open Before Async Per Day | DECIMAL | NO | - | CODE-BACKED | Average daily position opens before async migration: Total Open Before Async / 90. Baseline comparison value. |
| 12 | Total Closed After Async Per Day | DECIMAL | NO | - | CODE-BACKED | Average daily position closes after async migration. |
| 13 | Total Closed Before Async Per Day | DECIMAL | NO | - | CODE-BACKED | Average daily position closes in the 90-day pre-async window. Baseline comparison value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID, MovedToAsync | PositionFailRealAzureSecondary.History.InstrumentAsyncDate | Lookup (cross-DB READ) | Master list of instruments migrated to async and their migration timestamps |
| InstrumentID | Trade.PositionTbl | Lookup (INNER JOIN) | Open position counts per instrument (90-day window around MovedToAsync) |
| InstrumentID | History.Position_Active | Lookup (INNER JOIN) | Historical position counts for both opens and closes per instrument |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called directly from SSRS report server.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SSRSInstrumentAsync_PositionsOpenAndClose (procedure)
├── PositionFailRealAzureSecondary.PositionFailReal.History.InstrumentAsyncDate (table - cross-database Azure)
├── Trade.PositionTbl (table)
└── History.Position_Active (view - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| PositionFailRealAzureSecondary.History.InstrumentAsyncDate | Table (cross-database, Azure) | Source of instruments and their async migration dates |
| Trade.PositionTbl | Table | Position opens for async impact counting |
| History.Position_Active | View (cross-schema) | Historical position opens and closes for async impact counting |

### 6.2 Objects That Depend On This

No dependents found. Called directly from SSRS report server.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Temp table indexes:
- #InstrumentAsyncDate: UNIQUE CLUSTERED on InstrumentID, NONCLUSTERED IX_MovedToAsync on MovedToAsync.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run async impact report for all migrated instruments

```sql
EXEC Trade.SSRSInstrumentAsync_PositionsOpenAndClose
```

### 8.2 Directly check which instruments have been moved to async

```sql
SELECT TOP 20
    InstrumentID,
    MovedToAsync
FROM PositionFailRealAzureSecondary.PositionFailReal.History.InstrumentAsyncDate WITH (NOLOCK)
ORDER BY MovedToAsync DESC
```

### 8.3 Preview open count comparison for a specific instrument

```sql
SELECT
    COUNT(CASE WHEN p.Occurred >= i.MovedToAsync THEN 1 END) AS OpenAfterAsync,
    COUNT(CASE WHEN p.Occurred < i.MovedToAsync THEN 1 END) AS OpenBeforeAsync
FROM Trade.PositionTbl p WITH (NOLOCK)
INNER JOIN PositionFailRealAzureSecondary.PositionFailReal.History.InstrumentAsyncDate i WITH (NOLOCK)
    ON p.InstrumentID = i.InstrumentID
WHERE p.InstrumentID = 7  -- e.g., EUR/USD
    AND p.Occurred > DATEADD(day, -90, i.MovedToAsync)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SSRSInstrumentAsync_PositionsOpenAndClose | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SSRSInstrumentAsync_PositionsOpenAndClose.sql*
