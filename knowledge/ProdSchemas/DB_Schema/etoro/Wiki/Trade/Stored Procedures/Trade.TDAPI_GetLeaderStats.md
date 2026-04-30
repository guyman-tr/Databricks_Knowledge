# Trade.TDAPI_GetLeaderStats

> Returns four aggregated statistics for a Popular Investor's copy program: average copy amount, average copy duration, percentage of copiers who were profitable, and net cash flow change - computed from etoroGeneral_Copiers_DATA snapshots, History.Mirror operations, and Trade.Mirror live data, with @MinCopiersForStatsCalc privacy threshold.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT (PI aggregate stats, privacy-guarded, 4 metrics) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the summary statistics panel on a Popular Investor's profile dashboard. It provides four high-level metrics that summarize how effective and stable a PI's copy program is:

1. **AveragreCopyAmount**: The typical amount copiers invest when they start copying this PI - indicates PI's "price point" for copiers
2. **AveragreCopyDurationInDays**: How long copiers typically stay - indicates PI program loyalty/stickiness
3. **ProfitableCopiersChangePercentage**: What percentage of copiers (active + those who left) were profitable - indicates PI's ability to generate returns
4. **NetCashFlowChange**: Change in total copier AUM (Cash+Investment) from start date to most recent snapshot - indicates whether the PI is growing or losing AUM

All four metrics have privacy guards: if the copier count is below `@MinCopiersForStatsCalc` (default 20), the metric is returned as 0 to prevent reverse-engineering individual copier data. The procedure also exits early if no historical snapshots exist for the PI.

Note: The output column names contain typos: "Averagre" (should be "Average") - these are in the procedure code and output as-is.

---

## 2. Business Logic

### 2.1 Date Window

- `@OneYearBackDate = CAST(DATEADD(year,-1,GETUTCDATE()) AS DATE)`
- `@StartDate = ISNULL(@StartDate, DATEADD(month,-1,GETUTCDATE()))` - defaults to 1 month ago
- Hard cap: `CASE WHEN @StartDate < @OneYearBackDate THEN @OneYearBackDate ELSE @StartDate END`
- History.Mirror filter: `ModificationDate >= @StartDate AND >= @OneYearBackDate AND < @MostRecentSnapShotDate`

### 2.2 Most Recent Snapshot (etoroGeneral_Copiers_DATA)

```sql
SELECT TOP 1
    @MostRecentSnapShotDate = cd.DateModified,
    @MostRecentSnapShotNumberOfCopiers = ISNULL(NumOfCopiers,0),
    @MostRecentSnapShotNumberOfProfitableCopiers = ISNULL(NumProfitableMirrors,0),
    @MostRecentSnapShotTotalRealized = ISNULL(Cash,0)+ISNULL(Investment,0)
FROM [dbo].[etoroGeneral_Copiers_DATA] cd
WHERE CID = @CID AND DateModified >= @OneYearBackDate
ORDER BY DateModified DESC
```
- **Early exit**: `IF @@ROWCOUNT = 0 RETURN` - if no snapshot exists, nothing is returned
- @MostRecentSnapShotTotalRealized = Cash + Investment (NOT PnL; only realized cash and invested amounts)

### 2.3 Start Date Snapshot (etoroGeneral_Copiers_DATA)

```sql
SELECT TOP 1 @StartDateSnapShotTotalRealized = ISNULL(Cash,0)+ISNULL(Investment,0)
FROM [dbo].[etoroGeneral_Copiers_DATA]
WHERE CID = @CID AND DateModified < @StartDate
ORDER BY DateModified DESC
```
- Gets the most recent snapshot BEFORE the start date - used as the baseline for NetCashFlowChange

### 2.4 History.Mirror Aggregation

```sql
SELECT
    @RegisterMirrorCount = SUM(CASE WHEN MirrorOperationID = 1 THEN 1 ELSE 0 END),
    @UnregisterMirrorCount = SUM(CASE WHEN MirrorOperationID = 2 THEN 1 ELSE 0 END),
    @ProfitableUnregisterMirrorCount = SUM(CASE WHEN MirrorOperationID = 2 AND NetProfit >= 0 THEN 1 ELSE 0 END),
    @TotalRegisterMirrorAmount = SUM(CASE WHEN MirrorOperationID = 1 THEN Amount ELSE 0 END),
    @UnregisterMirrorTotalCopyDurationInDays = SUM(CASE WHEN MirrorOperationID = 2 THEN CopyDurationInDays ELSE 0 END)
FROM History.Mirror hm
INNER JOIN Customer.Customer ccm ON ccm.CID = hm.CID AND ccm.PlayerLevelID <> 4
WHERE ParentCID = @CID AND ModificationDate BETWEEN @StartDate AND @MostRecentSnapShotDate
  AND MirrorOperationID IN (1,2)
```
- MirrorOperationID 1 = register (start copying), 2 = unregister (stop copying)
- PlayerLevelID<>4 excludes internal/test/staff from stats

### 2.5 Trade.Mirror Live Aggregation

```sql
SELECT @TotalActiveMirrors = COUNT(tm.CID),
       @ActiveMirrorTotalCopyDurationInDays = SUM(DATEDIFF(day, tm.Occurred, GETUTCDATE()))
FROM Trade.Mirror tm
INNER JOIN Customer.Customer ccm ON ccm.CID = tm.CID AND ccm.PlayerLevelID <> 4
WHERE ParentCID = @CID
```
- All active copiers (no date window - all current copiers count)
- CopyDuration for active = days since Occurred to now

### 2.6 Four Computed Statistics

All four apply the `@MinCopiersForStatsCalc` privacy guard (default 20):

**AveragreCopyAmount** (minimum copiers = @RegisterMirrorCount):
```
0 if @RegisterMirrorCount < @MinCopiersForStatsCalc
ELSE ROUND(@TotalRegisterMirrorAmount / @RegisterMirrorCount, 2)
```

**AveragreCopyDurationInDays** (denominator = unregistered + active):
```
0 if (@UnregisterMirrorCount + @TotalActiveMirrors) < @MinCopiersForStatsCalc
ELSE (@UnregisterMirrorTotalCopyDurationInDays + @ActiveMirrorTotalCopyDurationInDays) / (@UnregisterMirrorCount + @TotalActiveMirrors)
```

**ProfitableCopiersChangePercentage** (denominator = unregistered + snapshot count):
```
0 if (@UnregisterMirrorCount + @MostRecentSnapShotNumberOfCopiers) < @MinCopiersForStatsCalc
ELSE 100 * (CAST(@ProfitableUnregisterMirrorCount + @MostRecentSnapShotNumberOfProfitableCopiers) / (@UnregisterMirrorCount + @MostRecentSnapShotNumberOfCopiers))
```
Note: combines profitable ex-copiers (History.Mirror) with currently-profitable copiers (from snapshot's NumProfitableMirrors).

**NetCashFlowChange**:
```
@MostRecentSnapShotTotalRealized - @StartDateSnapShotTotalRealized
```
No privacy guard (dollar change can be negative; reveals AUM delta without absolute values).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The Popular Investor's customer ID. All stats are computed for this PI. |
| 2 | @StartDate | DATE | YES | 1 month ago | CODE-BACKED | Start of the look-back window. Defaults to 1 month ago. Hard 1-year cap applied. |
| 3 | @MinCopiersForStatsCalc | INT | YES | 20 | CODE-BACKED | Privacy threshold: stats returned as 0 when copier count denominator < this value. Prevents reverse-engineering individual copier data. Default 20. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AveragreCopyAmount | MONEY | NO | 0 | CODE-BACKED | Average initial copy amount when copiers registered within the window. 0 when @RegisterMirrorCount < @MinCopiersForStatsCalc. Note: "Averagre" spelling is in the procedure output as-is. |
| 2 | AveragreCopyDurationInDays | INT | NO | 0 | CODE-BACKED | Average number of days copiers have been (or were) copying this PI: (total duration days of ex-copiers + active copiers) / (ex-copier count + active count). 0 when total count < @MinCopiersForStatsCalc. |
| 3 | ProfitableCopiersChangePercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Percentage of copiers who made a profit: 100 * (profitable ex-copiers + snapshot profitable copiers) / (total ex-copiers + snapshot total copiers). 0 when total count < @MinCopiersForStatsCalc. |
| 4 | NetCashFlowChange | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Change in total copier AUM from start-date snapshot to most recent snapshot: (Cash+Investment) at most recent snapshot - (Cash+Investment) at start date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, DateModified, NumOfCopiers, NumProfitableMirrors, Cash, Investment | dbo.etoroGeneral_Copiers_DATA | Lookup (READ) | Historical daily snapshots: current/start-date AUM, copier counts, profitability. Early exit if no data. |
| CID, ParentCID, MirrorOperationID, Amount, NetProfit, ModificationDate, Occurred | History.Mirror | Lookup (READ) | Completed copy sessions: register counts, unregister counts, profitable exits, copy duration. |
| ParentCID, CID, Occurred | Trade.Mirror | Lookup (READ) | Active copiers: live count and current copy duration. |
| CID, PlayerLevelID | Customer.Customer | Lookup (READ) | Staff filter (PlayerLevelID<>4) applied to both History.Mirror and Trade.Mirror queries. |

### 5.2 Referenced By

Not analyzed in this phase. Called by TDAPI service - powers the PI profile statistics summary panel.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderStats (procedure)
+-- dbo.etoroGeneral_Copiers_DATA (table - cross-schema) - snapshot data
+-- History.Mirror (table - cross-schema) - completed copy sessions
+-- Trade.Mirror (table) - active copy sessions
+-- Customer.Customer (table - cross-schema) - staff filter
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.etoroGeneral_Copiers_DATA | Table | Historical daily PI stats snapshots. Primary source for profitability data and AUM. |
| History.Mirror | Table | Completed copy operations (register/unregister). Source for amounts, durations, profitable exits. |
| Trade.Mirror | Table | Live active copiers: count and current copy durations. |
| Customer.Customer | Table | PlayerLevelID<>4 filter on both historical and live copier queries. |

### 6.2 Objects That Depend On This

No dependents found from procedure search.

---

## 7. Technical Details

### 7.1 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Early exit: no snapshot | Business Rule | `IF @@ROWCOUNT = 0 RETURN` after most-recent snapshot query. No output if PI has no historical snapshot data in the last year. |
| Privacy guard | Business Rule | @MinCopiersForStatsCalc (default 20) gates AveragreCopyAmount, AveragreCopyDurationInDays, and ProfitableCopiersChangePercentage. Each uses its own denominator count. |
| Column name typo | NOTE | Output columns named "AveragreCopyAmount" and "AveragreCopyDurationInDays" (not "Average"). These are in the original procedure and output as-is. |
| History.Mirror upper bound | Business Rule | History.Mirror filter uses `ModificationDate < @MostRecentSnapShotDate` as upper bound - events after the latest snapshot are excluded to stay consistent with snapshot data. |
| NetCashFlowChange no guard | NOTE | NetCashFlowChange has no @MinCopiersForStatsCalc check; it reveals AUM delta even for small PIs. |

---

## 8. Sample Queries

### 8.1 Get PI stats for the last month

```sql
EXEC Trade.TDAPI_GetLeaderStats
    @CID = 55555,
    @StartDate = NULL,
    @MinCopiersForStatsCalc = 20
-- Returns 1 row with 4 stats
```

### 8.2 Get PI stats for a 6-month window with lower privacy threshold

```sql
EXEC Trade.TDAPI_GetLeaderStats
    @CID = 55555,
    @StartDate = '2024-09-01',
    @MinCopiersForStatsCalc = 5
```

### 8.3 Diagnose PI stats inputs directly

```sql
-- Most recent snapshot
SELECT TOP 1 DateModified, NumOfCopiers, NumProfitableMirrors, Cash+Investment AS TotalRealized
FROM dbo.etoroGeneral_Copiers_DATA WHERE CID = 55555 AND DateModified >= DATEADD(year,-1,GETUTCDATE())
ORDER BY DateModified DESC

-- History.Mirror summary
SELECT MirrorOperationID, COUNT(*) AS Count, SUM(Amount) AS TotalAmount
FROM History.Mirror hm WITH (NOLOCK)
INNER JOIN Customer.Customer ccm WITH (NOLOCK) ON ccm.CID = hm.CID AND ccm.PlayerLevelID <> 4
WHERE hm.ParentCID = 55555 AND hm.ModificationDate >= DATEADD(month,-1,GETUTCDATE())
  AND hm.MirrorOperationID IN (1,2)
GROUP BY MirrorOperationID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderStats | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderStats.sql*
