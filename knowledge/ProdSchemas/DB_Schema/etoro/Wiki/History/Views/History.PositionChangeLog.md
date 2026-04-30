# History.PositionChangeLog

> Full position change audit log spanning the complete history - UNION ALL of a linked-server archive (PositionChangeLogArchive for records older than 6 months) and History.PositionChangeLog_Active (records from the last 6 months) - with NULL backfill for newer columns (IsNoStopLoss, IsNoTakeProfit, LotCountDecimal variants) in the archived branch. Used by trading engine position operations, monitoring, and full audit trail queries.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionChangeID (bigint) |
| **Partition** | N/A (view - sources are partitioned/archived) |
| **Indexes** | N/A (view - base source indexes used) |

---

## 1. Business Meaning

History.PositionChangeLog is the complete position change audit log - the full-history complement to `History.PositionChangeLog_Active`. While PositionChangeLog_Active covers only the last ~6 months (rolling partition window), PositionChangeLog bridges the historical archive with the active window to provide access to all position change records ever recorded.

The view uses a 6-month boundary (DATEADD(mm,-6, GETUTCDATE())) to split traffic between two sources:
1. **Archive (older than 6 months)**: `PositionChangeLogArchive.HistoryPositionChangeLog_Real.History.V_PositionChangeLog` - a linked server/cross-database view providing position change records from before the active partition window
2. **Active (last 6 months)**: `History.PositionChangeLog_Active` - the current rolling partition table

**Cross-database/linked server**: The archive source is accessed via a four-part name (linked server + database + schema + view), meaning it may reside on a separate server or in a separate database named `PositionChangeLogArchive`. This is a common pattern for archiving high-volume audit data.

**Column normalization**: The archive branch does not have `PreviousIsNoTakeProfit`, `PreviousIsNoStopLoss`, `IsNoStopLoss`, `IsNoTakeProfit`, `PreviousLotCountDecimal`, and `LotCountDecimal` (columns added in UM 25.2). These are NULL-backfilled in the archive branch. The active branch provides native values.

**ClientVersion collation**: In the archive branch, ClientVersion is COLLATE Latin1_General_BIN - a binary collation used to avoid collation conflicts when the linked server/archive database uses a different default collation.

The view is referenced by ~12 consumers: trading engine procedures (PositionOpen, PositionEditTakeProfit, DetachFromParentPosition, PostOpenPositionActions, PostEditStopLossPosition, ClaimEndOfWeekFee, PositionAdjustment) and the History.PositionChangeLogFull companion view.

---

## 2. Business Logic

### 2.1 6-Month Split Boundary

**What**: Traffic is split at 6 months ago between the archive and active sources.

**Columns/Parameters Involved**: `Occurred`

**Rules**:
- Archive branch: `WHERE [Occurred] < DATEADD(mm,-6, GETUTCDATE())` - records older than 6 months
- Active branch: `WHERE [Occurred] >= DATEADD(mm,-6, GETUTCDATE())` - records from last 6 months
- The boundary is computed at query time (not a static date), so the split point moves forward as time passes
- UNION ALL: the two date ranges are mutually exclusive (one is strictly `<`, the other is `>=`), so no deduplication is needed

**Diagram**:
```
PositionChangeLogArchive.HistoryPositionChangeLog_Real.History.V_PositionChangeLog
  WHERE Occurred < 6 months ago   (archive - older records)
  NULL for: PreviousIsNoTakeProfit, PreviousIsNoStopLoss, IsNoStopLoss, IsNoTakeProfit
           PreviousLotCountDecimal, LotCountDecimal
  ClientVersion COLLATE Latin1_General_BIN
  |
UNION ALL
  |
History.PositionChangeLog_Active
  WHERE Occurred >= 6 months ago   (active - recent records)
  Native values for all 57 columns (from History.PositionChangeLog_Active_BIGINT)
  |
  v
History.PositionChangeLog (complete audit trail)
```

### 2.2 Column Normalization (UM 25.2 Columns)

**What**: Six columns added in UM 25.2 are NULL in the archive branch.

**Columns/Parameters Involved**: `PreviousIsNoTakeProfit`, `PreviousIsNoStopLoss`, `IsNoStopLoss`, `IsNoTakeProfit`, `PreviousLotCountDecimal`, `LotCountDecimal`

**Rules**:
- Archive: `null as PreviousIsNoTakeProfit, null as PreviousIsNoStopLoss, null as IsNoStopLoss, null as IsNoTakeProfit, null as PreviousLotCountDecimal, null as LotCountDecimal`
- Active: native values from History.PositionChangeLog_Active (which inherits from History.PositionChangeLog_Active_BIGINT)
- These 6 columns reflect post-UM-25.2 schema additions; older archive records predate these columns

### 2.3 ClientVersion Collation

**What**: ClientVersion in the archive branch uses COLLATE Latin1_General_BIN.

**Columns/Parameters Involved**: `ClientVersion`

**Rules**:
- Archive: `[ClientVersion] COLLATE Latin1_General_BIN AS [ClientVersion]`
- Active: `[ClientVersion]` (native collation from History.PositionChangeLog_Active_BIGINT)
- The binary collation in the archive branch forces a specific collation to avoid conflicts when the archive database has a different server/database collation than the etoro database

---

## 3. Data Overview

Complete position change audit trail. The active branch (History.PositionChangeLog_Active) has 5.77M rows from ~May 2023. The archive branch (V_PositionChangeLog) provides older records dating back further (the DDL changelog shows archives added from 2014Q2 onward).

Sample from active branch (Occurred = 2026-03-21):

| PositionChangeID | PositionID | ChangeTypeID | CID | Occurred |
|-----------------|------------|-------------|-----|----------|
| 3713814537 | 2152976745 | 0 (Open) | varies | 2026-03-21 |
| 3713814536 | 2152976742 | 0 (Open) | 25132377 | 2026-03-21 |
| 3713814535 | 2152976740 | 6 (Close) | 14952810 | 2026-03-21 |

---

## 4. Elements

57 output columns (same count as History.PositionChangeLog_Active). The 6 UM-25.2 columns (positions 52-57 approximately) are NULL for archive rows. See History.PositionChangeLog_Active.md and History.PositionChangeLog_Active_BIGINT.md for full element descriptions.

| # | Element | Confidence | Notes |
|---|---------|------------|-------|
| 1 | PositionChangeID | CODE-BACKED | Surrogate PK. bigint. |
| 2 | PositionID | CODE-BACKED | The position this change relates to. |
| 3-12 | (PreviousCloseOnEndOfWeek...StopRate) | CODE-BACKED | EOW/amount/rate before-after pairs |
| 13 | Occurred | CODE-BACKED | Event timestamp. Used as split boundary. |
| 14-45 | (ParentPositionID...IsSettled) | CODE-BACKED | Operational fields. Present in both branches. |
| 46-51 | (PreviousAmountInUnits...ClientRateForCalc) | CODE-BACKED | Units/rate fields. Present in both branches. |
| 52 | PreviousIsNoTakeProfit | CODE-BACKED | NULL for archive rows; native for active rows. UM 25.2. |
| 53 | PreviousIsNoStopLoss | CODE-BACKED | NULL for archive rows. UM 25.2. |
| 54 | IsNoStopLoss | CODE-BACKED | NULL for archive rows. UM 25.2. |
| 55 | IsNoTakeProfit | CODE-BACKED | NULL for archive rows. UM 25.2. |
| 56 | PreviousLotCountDecimal | CODE-BACKED | NULL for archive rows. UM 25.2. |
| 57 | LotCountDecimal | CODE-BACKED | NULL for archive rows. UM 25.2. |

Note: SnapshotTimestamp and PriceType (columns 58-59 of the base table) are NOT included in either branch - same omission as History.PositionChangeLog_Active.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (archive branch) | PositionChangeLogArchive.HistoryPositionChangeLog_Real.History.V_PositionChangeLog | View (UNION ALL, linked server) | Historical position changes (older than 6 months) |
| (active branch) | History.PositionChangeLog_Active | View (UNION ALL, local) | Recent position changes (last 6 months) |
| PositionID | Trade.PositionTbl / History.Position | Implicit FK | The position being changed |
| CID | Customer.Customer | Implicit FK | Customer |
| ChangeTypeID | Dictionary.PCL_ChangeType | Implicit FK | Change type lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PositionChangeLogFull | PositionChangeID | View (references this view) | Extended version of the full changelog |
| Trade.PositionOpen | PositionChangeID | Read | Post-open audit validation |
| Trade.PositionEditTakeProfit | PositionChangeID | Read | Post-TP-edit audit |
| Trade.DetachFromParentPosition | PositionChangeID | Read | Post-detach audit |
| Trade.PostOpenPositionActions | PositionChangeID | Read | Async post-open validation |
| Trade.PostEditStopLossPosition | PositionChangeID | Read | Post-SL-edit audit |
| Trade.ClaimEndOfWeekFee | PositionChangeID | Read | EOW fee audit |
| Trade.PositionAdjustment | PositionID | Read | Position data fix validation |
| Trade.GetRealEditSLMMRecovery | PositionID | Read | SL/MM recovery view |
| Trade.PositionChange | PositionID | Read | Position change tracking view |
| dbo.PR_Dashboard_ORG | PositionID | Read (report) | ORG dashboard |
| dbo.PR_Report_FailDashbordNew | PositionID | Read (report) | Failure dashboard |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionChangeLog (view)
|- PositionChangeLogArchive.HistoryPositionChangeLog_Real.History.V_PositionChangeLog (linked server view)
|    - External database/server: PositionChangeLogArchive
|    - Provides: records older than 6 months; NULL for 6 UM-25.2 columns
|
+- History.PositionChangeLog_Active (view - local)
     +- History.PositionChangeLog_Active_BIGINT (table - rolling 6-month partition)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| PositionChangeLogArchive.HistoryPositionChangeLog_Real.History.V_PositionChangeLog | Linked server view | UNION ALL branch 1 - historical archive (older than 6 months) |
| History.PositionChangeLog_Active | View (local) | UNION ALL branch 2 - active rolling window (last 6 months) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLogFull | View | Extended full changelog view |
| Trade.PositionOpen | Stored Procedure | Post-open audit |
| Trade.PositionEditTakeProfit | Stored Procedure | Post-TP-edit audit |
| Trade.DetachFromParentPosition | Stored Procedure | Post-detach audit |
| Trade.PostOpenPositionActions | Stored Procedure | Async post-open validation |
| Trade.PostEditStopLossPosition | Stored Procedure | Post-SL-edit audit |
| Trade.ClaimEndOfWeekFee | Stored Procedure | EOW fee processing |
| Trade.PositionAdjustment | Stored Procedure | Data fix operations |
| Trade.GetRealEditSLMMRecovery | View | SL/MM recovery |
| Trade.PositionChange | View | Position change tracking |
| dbo.PR_Dashboard_ORG | Stored Procedure | Dashboard reporting |
| dbo.PR_Report_FailDashbordNew | Stored Procedure | Failure reporting |

---

## 7. Technical Details

### 7.1 Linked Server Dependency

The archive branch uses a four-part object name: `[PositionChangeLogArchive].[HistoryPositionChangeLog_Real].[History].[V_PositionChangeLog]`
- `PositionChangeLogArchive` = linked server name (or database alias)
- `HistoryPositionChangeLog_Real` = database name on that server
- `History` = schema
- `V_PositionChangeLog` = view name

If the linked server is unavailable, queries against History.PositionChangeLog will fail. For recent data only, use History.PositionChangeLog_Active directly.

---

## 8. Sample Queries

### 8.1 Get complete position change history including archive
```sql
SELECT
    pcl.PositionChangeID,
    pcl.ChangeTypeID,
    pcl.PreviousStopRate,
    pcl.StopRate,
    pcl.Occurred
FROM History.PositionChangeLog pcl WITH (NOLOCK)
WHERE pcl.PositionID = 2152976742
ORDER BY pcl.Occurred;
```

### 8.2 For recent data only (faster - avoids linked server)
```sql
SELECT
    pcl.PositionChangeID,
    pcl.ChangeTypeID,
    pcl.IsNoStopLoss,  -- only available in active branch
    pcl.LotCountDecimal,  -- only available in active branch
    pcl.Occurred
FROM History.PositionChangeLog_Active pcl WITH (NOLOCK)
WHERE pcl.CID = 14952810
  AND pcl.Occurred >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY pcl.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.PositionChangeLog. Business context inherited from History.PositionChangeLog_Active and History.PositionChangeLog_Active_BIGINT documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 8.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 57 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.PositionChangeLog | Type: View | Source: etoro/etoro/History/Views/History.PositionChangeLog.sql*
