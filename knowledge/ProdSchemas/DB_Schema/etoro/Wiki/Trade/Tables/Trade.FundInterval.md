# Trade.FundInterval

> Time-bounded allocation intervals for CopyFunds/SmartPortfolios, tracking planned vs actual start/end dates and optional credit snapshots for each fund rebalance period.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | FundIntervalID (INT, CLUSTERED PK) |
| **Partition** | MAIN filegroup |
| **Indexes** | 2 active (1 clustered PK, 1 NC) |

---

## 1. Business Meaning

Trade.FundInterval represents a single rebalancing period for a CopyFund/SmartPortfolio fund. Each row is a time interval during which the fund's allocation is active. Intervals are either BackTesting (simulated, for strategy evaluation) or Real (live execution). The table stores planned start/end dates (set when the interval is created from Trade.Fund.RefreshIntervalMonths) and actual start/end dates (filled when the interval executes). Optional StartCredit and EndCredit snapshot the fund's credit at interval boundaries for performance tracking.

This table exists because CopyFunds rebalance on a schedule (monthly, bimonthly, quarterly). The system must track which intervals have been planned, which have run, and their dates. Without it, Trade.FundIntervalAllocation would have no parent, and procedures like Trade.GetFundInfo could not return interval-level allocation history. Backtesting requires separate intervals (FundIntervalType=1) to store simulated allocations without affecting real data.

Data flows through this object as follows: Trade.Job_GenerateFundAllocation creates new rows when a fund has no intervals (first interval) or when the current date is past the last PlannedEnd (extends forward). It INSERTs with FundIntervalType=2 (Real), PlannedStart/ActualStart from registration or previous PlannedEnd, PlannedEnd = start + RefreshIntervalMonths. Trade.GetFundInfo reads intervals JOINed to Trade.Fund for API responses. Trade.DeleteFundAllocationBacktestData and Trade.FundBacktestDataDelete remove backtest intervals (FundIntervalType=1) and their allocations.

---

## 2. Business Logic

### 2.1 Interval Type: Simulated vs Live

**What**: Each interval is classified as backtesting (simulated) or real (live execution).

**Columns/Parameters Involved**: `FundIntervalType`, `PlannedStart`, `ActualStart`, `PlannedEnd`, `ActualEnd`

**Rules**:
- FundIntervalType=1 (BackTesting): Simulated rebalancing interval. Used for strategy evaluation. No real trades. Trade.FundBacktestDataDelete and Trade.DeleteFundAllocationBacktestData target these for cleanup.
- FundIntervalType=2 (Real): Live interval. Job_GenerateFundAllocation creates only Real intervals. ActualStart and ActualEnd may be populated when the interval executes.
- PlannedStart/PlannedEnd: Set at creation. PlannedEnd = PlannedStart + RefreshIntervalMonths (computed from Trade.Fund).
- ActualStart/ActualEnd: NULL until the interval runs. Filled by allocation/rebalancing logic (not visible in Job_GenerateFundAllocation, which sets ActualStart=PlannedStart at creation).

**Diagram**:
```
Trade.Fund (RefreshIntervalMonths)
    |
    v
Trade.FundInterval
    |-- FundIntervalType: 1=BackTesting, 2=Real (Dictionary.FundIntervalType)
    |-- PlannedStart -> PlannedEnd = + RefreshIntervalMonths
    |-- ActualStart, ActualEnd: NULL until executed
    |
    v
Trade.FundIntervalAllocation (allocations per interval)
```

### 2.2 Interval Extension Logic

**What**: Job_GenerateFundAllocation ensures at least one future interval exists so the fund is always "covered" by an active period.

**Columns/Parameters Involved**: `FundID`, `PlannedEnd`, `PlannedStart`, `ActualStart`

**Rules**:
- If no intervals exist for the fund: INSERT first interval from fund registration date (or @Registered).
- While getdate() >= max(PlannedEnd) for the fund: INSERT next interval with PlannedStart = max(PlannedEnd), PlannedEnd = PlannedStart + RefreshIntervalMonths.
- Each new row gets ActualStart = PlannedStart at creation (Real intervals).
- Index IDX_Trade_FundInterval_FundID_PlannedEnd supports "max(PlannedEnd) where FundID=@FundID" and "getdate() < PlannedEnd" lookups.

---

## 3. Data Overview

| FundIntervalID | FundID | FundIntervalType | PlannedStart | PlannedEnd | ActualEnd | StartCredit | EndCredit | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 1 | 2017-01-10 | 2018-01-09 | NULL | NULL | NULL | BackTesting interval for fund BitcoinWorldWide. One-year simulated period. ActualEnd, StartCredit, EndCredit not populated - typical for backtest intervals that are not fully processed or are cleanup candidates. |

**Selection criteria for the 5 rows:**
- Table has 1 row. Single row included to show structure. In production, multiple rows per FundID with mix of BackTesting (1) and Real (2) intervals would exist. This sample demonstrates a backtest interval with planned dates but no actual end or credit snapshots.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundIntervalID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate identifier for the interval. Referenced by Trade.FundIntervalAllocation.FundIntervalID. NOT FOR REPLICATION. |
| 2 | FundID | int | NO | - | CODE-BACKED | FK to Trade.Fund. The fund this interval belongs to. Job_GenerateFundAllocation creates intervals per fund; GetFundInfo JOINs Fund to FundInterval by FundID. |
| 3 | FundIntervalType | tinyint | NO | - | VERIFIED | FK to Dictionary.FundIntervalType. 1=BackTesting (simulated), 2=Real (live execution). Job_GenerateFundAllocation inserts 2; backtest procedures create 1. DeleteFundAllocationBacktestData and FundBacktestDataDelete target FundIntervalType=1. |
| 4 | PlannedStart | datetime | NO | - | CODE-BACKED | Planned start of the rebalance period. Set at creation. For first interval: fund registration date. For subsequent: previous PlannedEnd. |
| 5 | ActualStart | datetime | YES | - | CODE-BACKED | Actual start when the interval began execution. Job_GenerateFundAllocation sets it equal to PlannedStart at INSERT. May remain NULL for backtest intervals. |
| 6 | PlannedEnd | datetime | NO | - | CODE-BACKED | Planned end of the period. Computed as PlannedStart + Trade.Fund.RefreshIntervalMonths. Job_GenerateFundAllocation uses format yyyy-MM-01 for end-of-month alignment. Used in "getdate() < PlannedEnd" to detect if more intervals are needed. |
| 7 | ActualEnd | datetime | YES | - | CODE-BACKED | Actual end when the interval completed. Populated by allocation/rebalancing logic. NULL in sample - typical for backtest or in-progress intervals. |
| 8 | StartCredit | money | YES | - | CODE-BACKED | Snapshot of fund credit at interval start. Used for performance/NAV tracking. NULL when not populated. |
| 9 | EndCredit | money | YES | - | CODE-BACKED | Snapshot of fund credit at interval end. Used for performance/NAV tracking. NULL when not populated. |
| 10 | CreateDate | datetime | NO | getdate() | CODE-BACKED | When the interval row was created. Default getdate(). |
| 11 | LastUpdateDate | datetime | NO | - | CODE-BACKED | Last modification timestamp. Set at INSERT by Job_GenerateFundAllocation. Updated when interval or allocation data changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundID | Trade.Fund | FK (FK_TF_FundID) | Parent fund; each interval belongs to one fund |
| FundIntervalType | Dictionary.FundIntervalType | FK (FK_TF_FundIntervalType) | Classifies interval as BackTesting (1) or Real (2) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FundIntervalAllocation | FundIntervalID | FK | Allocations belong to intervals |
| Trade.GetFundInfo | - | JOIN | Reads intervals by FundAccountID for API |
| Trade.Job_GenerateFundAllocation | - | Writer | INSERTs new intervals; extends forward when getdate() >= max(PlannedEnd) |
| Trade.DeleteFundAllocationBacktestData | FundIntervalID | JOIN | Deletes allocations for backtest intervals (FundIntervalType=1) by FundAccountID |
| Trade.FundBacktestDataDelete | FundIntervalID | Read/Delete | Deletes backtest intervals and their allocations by FundID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FundInterval (table)
```
Tables have no code-level dependencies. FK targets (Trade.Fund, Dictionary.FundIntervalType) are structural dependencies only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Fund | Table | FK target for FundID |
| Dictionary.FundIntervalType | Table | FK target for FundIntervalType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FundIntervalAllocation | Table | FK from FundIntervalID |
| Trade.GetFundInfo | Procedure | JOINs Fund to FundInterval for interval and allocation data |
| Trade.Job_GenerateFundAllocation | Procedure | INSERTs intervals; reads max(PlannedEnd) to extend |
| Trade.DeleteFundAllocationBacktestData | Procedure | JOINs FundIntervalAllocation to FundInterval for backtest cleanup |
| Trade.FundBacktestDataDelete | Procedure | SELECTs FundIntervalID for backtest intervals; deletes allocations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeFundInterval | CLUSTERED PK | FundIntervalID ASC | - | - | Active |
| IDX_Trade_FundInterval_FundID_PlannedEnd | NC | FundID ASC, PlannedEnd ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeFundInterval | PRIMARY KEY | Unique interval identifier |
| DF_TradeFundInterval_CreateDate | DEFAULT | getdate() for CreateDate |
| FK_TF_FundID | FOREIGN KEY | FundID -> Trade.Fund.FundID |
| FK_TF_FundIntervalType | FOREIGN KEY | FundIntervalType -> Dictionary.FundIntervalType.FundIntervalType |

---

## 8. Sample Queries

### 8.1 List intervals for a fund with type description
```sql
SELECT  fi.FundIntervalID,
        fi.FundID,
        fit.FundIntervalTypeDesc,
        fi.PlannedStart,
        fi.PlannedEnd,
        fi.ActualStart,
        fi.ActualEnd
FROM    Trade.FundInterval fi WITH (NOLOCK)
JOIN    Dictionary.FundIntervalType fit WITH (NOLOCK)
        ON fi.FundIntervalType = fit.FundIntervalType
WHERE   fi.FundID = 1
ORDER BY fi.PlannedStart;
```

### 8.2 Find active (future) intervals by fund account
```sql
SELECT  f.FundName,
        fi.FundIntervalID,
        fi.PlannedStart,
        fi.PlannedEnd,
        fit.FundIntervalTypeDesc
FROM    Trade.Fund f WITH (NOLOCK)
JOIN    Trade.FundInterval fi WITH (NOLOCK)
        ON f.FundID = fi.FundID
JOIN    Dictionary.FundIntervalType fit WITH (NOLOCK)
        ON fi.FundIntervalType = fit.FundIntervalType
WHERE   f.FundAccountID = 341479
        AND fi.PlannedEnd > GETDATE()
ORDER BY fi.PlannedStart;
```

### 8.3 Count intervals by fund and type
```sql
SELECT  f.FundName,
        fit.FundIntervalTypeDesc,
        COUNT(*) AS IntervalCount
FROM    Trade.Fund f WITH (NOLOCK)
JOIN    Trade.FundInterval fi WITH (NOLOCK)
        ON f.FundID = fi.FundID
JOIN    Dictionary.FundIntervalType fit WITH (NOLOCK)
        ON fi.FundIntervalType = fit.FundIntervalType
GROUP BY f.FundName,
         fit.FundIntervalTypeDesc
ORDER BY f.FundName,
         fit.FundIntervalTypeDesc;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FundInterval | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.FundInterval.sql*
