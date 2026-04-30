# Trade.GetFundInfo

> Returns comprehensive fund information across 3 result sets: fund metadata, fund intervals, and fund interval allocations. Supports date range filtering. Created 15-09-2016 by Yitzchak Wahnon.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundAccountID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns full fund information for a fund account: metadata (name, flags, min copy amount), intervals (planned/actual start and end, credit at boundaries), and allocations per interval (instrument, parent CID, allocation percentages, stop-loss/take-profit, open/close orders, position/mirror IDs). It supports optional date range filtering via @startTime and @endTime.

The procedure exists to centralize fund info for fund administration UIs, reporting, and API consumers. Without it, each consumer would need to join Trade.Fund, Trade.FundInterval, and Trade.FundIntervalAllocation with varying filters.

Data flow: Defaults @startTime to 3 years ago if NULL. Result set 1 delegates to Trade.GetFundMetaData. Result set 2 queries Trade.FundInterval joined to Trade.Fund. Result set 3 queries Trade.FundIntervalAllocation filtered by the same interval IDs. All filtered by date range when provided.

---

## 2. Business Logic

### 2.1 Date Range Defaulting

**What**: @startTime defaults to 3 years ago when NULL. @endTime stays NULL if not provided.

**Columns/Parameters Involved**: `@startTime`, `@endTime`

**Rules**:
- If @startTime IS NULL: set to DATEADD(YEAR, -3, GETDATE())
- @endTime: no default, used as upper bound when provided
- Date range filters FundInterval rows (PlannedStart, ActualStart, PlannedEnd, ActualEnd)

### 2.2 Three Result Sets Assembly

**What**: Three coordinated result sets - metadata, intervals, allocations.

**Columns/Parameters Involved**: `@FundAccountID`, `FundIntervalID`, `FundIntervalAllocationID`

**Rules**:
- Result Set 1: EXEC Trade.GetFundMetaData @FundAccountID (FundName, IsPublic, HasCrypto, MinCopyAmount, RefreshIntervalMonths)
- Result Set 2: Fund intervals with FundIntervalID, FundIntervalType, PlannedStart, ActualStart, PlannedEnd, ActualEnd, StartCredit, EndCredit - filtered by date range
- Result Set 3: Fund interval allocations with FundIntervalAllocationID, FundIntervalID, AllocationType, InstrumentID, ParentCID, InvestmentPct, StopLossPct, TakeProfitPct, OpenOpen, IsBuy, Leverage, EntryOrderID, ExitOrderID, PositionID, MirrorID - for intervals from result set 2

**Diagram**:
```
Result Set 1: Fund Metadata (single row)
Result Set 2: Fund Intervals (N rows, date-filtered)
  +-- FundIntervalID links to
Result Set 3: Fund Interval Allocations (M rows per interval)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundAccountID | INT | NO | - | CODE-BACKED | Fund account identifier. Primary key of Trade.Fund |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Start of date range for intervals. Defaults to 3 years ago when NULL |
| 3 | @endTime | DATETIME | YES | NULL | CODE-BACKED | End of date range for intervals. No default |
| 4 | (Result Set 1) | - | - | - | CODE-BACKED | Fund metadata via Trade.GetFundMetaData |
| 5 | FundIntervalID | INT | NO | - | CODE-BACKED | Interval identifier (Result Set 2) |
| 6 | FundIntervalType | - | - | - | CODE-BACKED | Interval type (Result Set 2) |
| 7 | PlannedStart, ActualStart, PlannedEnd, ActualEnd | DATETIME | - | - | CODE-BACKED | Interval boundaries (Result Set 2) |
| 8 | StartCredit, EndCredit | MONEY | - | - | CODE-BACKED | Credit at interval start/end (Result Set 2) |
| 9 | FundIntervalAllocationID | INT | NO | - | CODE-BACKED | Allocation identifier (Result Set 3) |
| 10 | AllocationType, InstrumentID, ParentCID | - | - | - | CODE-BACKED | Allocation details (Result Set 3) |
| 11 | InvestmentPct, StopLossPct, TakeProfitPct | - | - | - | CODE-BACKED | Allocation percentages (Result Set 3) |
| 12 | OpenOpen, IsBuy, Leverage | - | - | - | CODE-BACKED | Position attributes (Result Set 3) |
| 13 | EntryOrderID, ExitOrderID, PositionID, MirrorID | - | - | - | CODE-BACKED | Linked orders and positions (Result Set 3) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | Trade.GetFundMetaData | Call | Fund metadata |
| FROM | Trade.Fund | Table | Fund intervals joined to fund |
| FROM | Trade.FundInterval | Table | Interval data |
| FROM | Trade.FundIntervalAllocation | Table | Allocations per interval |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Fund administration / API | Caller | Call | Full fund info retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetFundInfo (procedure)
+-- Trade.GetFundMetaData (procedure)
       +-- Trade.Fund (table)
+-- Trade.Fund (table)
+-- Trade.FundInterval (table)
+-- Trade.FundIntervalAllocation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetFundMetaData | Procedure | EXEC - result set 1 |
| Trade.Fund | Table | JOIN - fund intervals |
| Trade.FundInterval | Table | FROM - result set 2 |
| Trade.FundIntervalAllocation | Table | FROM - result set 3 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Fund admin / API | Consumer | Calls for full fund info |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Created: 15-09-2016 by Yitzchak Wahnon
- Date default: 3 years ago for @startTime when NULL

---

## 8. Sample Queries

### 8.1 Full fund info with default date range

```sql
EXEC Trade.GetFundInfo @FundAccountID = 5001;
```

### 8.2 Fund info for specific date range

```sql
EXEC Trade.GetFundInfo
    @FundAccountID = 5001,
    @startTime = '2024-01-01',
    @endTime = '2025-12-31';
```

### 8.3 Query intervals and allocations directly

```sql
SELECT fi.FundIntervalID, fi.FundIntervalType, fi.PlannedStart, fi.ActualStart,
       fi.PlannedEnd, fi.ActualEnd, fi.StartCredit, fi.EndCredit
FROM Trade.FundInterval fi WITH (NOLOCK)
INNER JOIN Trade.Fund f WITH (NOLOCK) ON f.FundAccountID = fi.FundAccountID
WHERE f.FundAccountID = 5001
  AND fi.PlannedStart >= DATEADD(YEAR, -3, GETDATE());

SELECT fia.*
FROM Trade.FundIntervalAllocation fia WITH (NOLOCK)
WHERE fia.FundIntervalID IN (
    SELECT FundIntervalID FROM Trade.FundInterval fi WITH (NOLOCK)
    INNER JOIN Trade.Fund f WITH (NOLOCK) ON f.FundAccountID = fi.FundAccountID
    WHERE f.FundAccountID = 5001
);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetFundInfo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetFundInfo.sql*
