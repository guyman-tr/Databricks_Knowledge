# Trade.TDAPI_GetLeaderLeavingCopiers

> Returns a Popular Investor's list of former copiers who have stopped copying (left) within the date window: two result sets - (1) count of non-active leavers, and (2) a sortable, paginated list of ex-copiers with copy duration, net profit percentage, and the reason they stopped.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (leaving/former copiers list, History.Mirror source, two result sets, privacy-masked) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the counterpart to `Trade.TDAPI_GetLeaderJoinedCopiers`. Where that procedure shows who is **currently** copying a PI, this procedure shows who **stopped** copying. It powers the "Ex-Copiers" or "Leaving Copiers" tab on a Popular Investor's profile dashboard.

A "leaving copier" is defined as someone who:
1. Appears in `History.Mirror` with `MirrorOperationID = 2` (unregister/stop copying)
2. Does NOT appear in `Trade.Mirror` for the same ParentCID (no active copy session)

This dual condition ensures only fully-stopped copiers are shown - not copiers who stopped and restarted (who would still have an active Trade.Mirror row).

The procedure returns two result sets:
1. **RS1**: Count of non-active leavers within the window (early exit if zero - RS2 not produced)
2. **RS2**: Paginated list of ex-copiers with 7 output columns (UserName, MirrorID, CID, CopyStart, CopyStop, CopyDurationInDays, NetProfitPercentage, CloseReason)

Privacy masking applies identically to the JoinedCopiers procedure: copiers who have blocked public portfolio viewing (OperationTypeID=3) appear as "Anonymous User" with MirrorID=-1 and CID=-1.

---

## 2. Business Logic

### 2.1 Date Window and 1-Year Cap

**What**: Establishes the window for copiers who stopped copying.

**Columns/Parameters Involved**: `@StartDate`, `@OneYearBackDate`, `History.Mirror.ModificationDate`

**Rules**:
- `@OneYearBackDate = CAST(DATEADD(year,-1,GETUTCDATE()) AS DATE)`
- `@StartDate = ISNULL(@StartDate, DATEADD(month,-1,GETUTCDATE()))` - defaults to 1 month ago
- Filter applied to `History.Mirror.ModificationDate` (the date the copy was stopped), not `Occurred` (when it started)

### 2.2 "Leaving Copier" Definition

**What**: Identifies ex-copiers who stopped and did NOT restart.

**Rules**:
```sql
History.Mirror hm
INNER JOIN (
    SELECT CID, MAX(ModificationDate) as ModificationDate
    FROM History.Mirror
    WHERE ModificationDate >= @StartDate AND ModificationDate >= @OneYearBackDate
      AND MirrorOperationID = 2 AND ParentCID = @ParentCID
    GROUP BY CID
) hm1 ON hm.CID = hm1.CID AND hm.ModificationDate = hm1.ModificationDate
LEFT JOIN Trade.Mirror tm ON hm.CID = tm.CID AND tm.ParentCID = @ParentCID
WHERE tm.CID IS NULL AND hm.ParentCID = @ParentCID
```
- `MirrorOperationID = 2`: unregister (stop copying) operation in History.Mirror
- `GROUP BY CID + MAX(ModificationDate)`: picks the most recent unregister event per copier
- `LEFT JOIN Trade.Mirror + WHERE tm.CID IS NULL`: excludes any copier who has since restarted (appears in Trade.Mirror)
- This pattern is repeated identically in RS1 (count) and RS2 (detail)

### 2.3 Result Set 1 - Count (Always Returned)

**What**: Simple count of leaving copiers. Early exit if zero.

**Rules**:
- `SELECT COUNT(hm.CID) AS 'NonActiveLeavers'`
- `IF @@ROWCOUNT = 0 RETURN` - RS2 is not produced if no leavers exist
- Excludes internal/test/staff (PlayerLevelID<>4)

### 2.4 Result Set 2 - Paginated Ex-Copier Detail

**What**: Full detail for each ex-copier with copy metrics.

**Columns**:
- `UserName`: copier username; 'Anonymous User' if OperationTypeID=3
- `MirrorID`: History.Mirror.MirrorID; -1 if anonymous
- `CID`: copier CID; -1 if anonymous
- `CopyStart`: History.Mirror.Occurred - when this copy session started
- `CopyStop`: History.Mirror.ModificationDate - when the copy was stopped
- `CopyDurationInDays`: `CASE WHEN DATEDIFF(day, Occurred, ModificationDate) = 0 THEN 1 ELSE DATEDIFF(day, Occurred, ModificationDate) END` - minimum 1 day
- `NetProfitPercentage`: `100 * NetProfit / (InitialInvestment + DepositSummary)` - return on investment from History.Mirror
- `CloseReason`: `ISNULL(CloseMirrorActionType, 0)` - why the copy was stopped (0 = unknown/manual)

**Dynamic Sort**: 8 sort columns
- 1=UserName, 2=MirrorID, 3=CID, 4=CopyStart, 5=CopyStop (default), 6=CopyDurationInDays, 7=NetProfitPercentage, 8=CloseReason

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's CID. All leavers are former copiers of this leader. |
| 2 | @StartDate | DATE | YES | 1 month ago | CODE-BACKED | Start of the window (based on ModificationDate - when they stopped). Defaults to 1 month ago. 1-year cap enforced. |
| 3 | @OrderbyDesc | BIT | YES | 1 | CODE-BACKED | Sort direction: 1=DESC (default), 0=ASC. |
| 4 | @OrderColumn | INT | YES | 5 | CODE-BACKED | Sort column: 1=UserName, 2=MirrorID, 3=CID, 4=CopyStart, 5=CopyStop (default), 6=CopyDurationInDays, 7=NetProfitPercentage, 8=CloseReason. |
| 5 | @PageNumber | INT | YES | 1 | CODE-BACKED | 1-based page number. |
| 6 | @ItemsPerPage | INT | YES | 3 | CODE-BACKED | Page size; hard-capped at 50. |

### Output - Result Set 1 (Leaver Count)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NonActiveLeavers | INT | NO | - | CODE-BACKED | Count of non-internal copiers (PlayerLevelID<>4) who stopped copying within the @StartDate window and have NOT restarted. 0 triggers early exit (RS2 not produced). |

### Output - Result Set 2 (Ex-Copier Detail List)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserName | VARCHAR | NO | - | CODE-BACKED | Ex-copier's username. 'Anonymous User' if blocked public portfolio (OperationTypeID=3 in BlockedCustomerOperations). |
| 2 | MirrorID | INT | NO | - | CODE-BACKED | History.Mirror MirrorID for this completed copy session. -1 if anonymous. |
| 3 | CID | INT | NO | - | CODE-BACKED | Ex-copier's customer ID. -1 if anonymous. |
| 4 | CopyStart | DATETIME | NO | - | CODE-BACKED | History.Mirror.Occurred - when this copy session was started. |
| 5 | CopyStop | DATETIME | NO | - | CODE-BACKED | History.Mirror.ModificationDate - when this copy session was stopped. Default sort key (DESC = most recently stopped first). |
| 6 | CopyDurationInDays | INT | NO | 1 | CODE-BACKED | Number of days from CopyStart to CopyStop. Minimum 1 (same-day stops counted as 1 day). |
| 7 | NetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Return on investment from this copy session: 100 * NetProfit / (InitialInvestment + DepositSummary). 0 when denominator is 0. From History.Mirror. |
| 8 | CloseReason | INT | NO | 0 | CODE-BACKED | ISNULL(History.Mirror.CloseMirrorActionType, 0). Reason the copy was stopped: 0 = manual/unknown. Other values map to CloseMirrorActionType lookup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, ParentCID, MirrorOperationID, ModificationDate, Occurred, NetProfit, InitialInvestment, DepositSummary, CloseMirrorActionType | History.Mirror | Lookup (READ) | Primary source: completed copy sessions with MirrorOperationID=2 (stopped). |
| CID, UserName, PlayerLevelID | Customer.Customer | Lookup (READ) | Ex-copier username + staff filter (PlayerLevelID<>4). |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy masking: OperationTypeID=3 -> Anonymous User. |
| CID, ParentCID | Trade.Mirror | Lookup (READ) | LEFT JOIN to verify "not currently active" (tm.CID IS NULL = no active copy session for this leader). |

### 5.2 Referenced By

Not analyzed in this phase. Called by TDAPI service - powers the "Leaving/Ex-Copiers" tab on a PI's public profile. Companion: `Trade.TDAPI_GetLeaderJoinedCopiers` (active copiers).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderLeavingCopiers (procedure)
+-- History.Mirror (table - cross-schema) - primary source
+-- Customer.Customer (table - cross-schema) - filter + masking
+-- Customer.BlockedCustomerOperations (table - cross-schema) - privacy
+-- Trade.Mirror (table) - "not active" verification
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table | Primary source: stopped copy sessions (MirrorOperationID=2). Provides copy start/stop dates, PnL, close reason. |
| Customer.Customer | Table | Ex-copier UserName, PlayerLevelID filter. |
| Customer.BlockedCustomerOperations | Table | Privacy masking OperationTypeID=3. |
| Trade.Mirror | Table | LEFT JOIN to verify the ex-copier is not currently active (has not restarted). |

### 6.2 Objects That Depend On This

No dependents found from procedure search.

---

## 7. Technical Details

### 7.1 Comparison with TDAPI_GetLeaderJoinedCopiers

| Aspect | TDAPI_GetLeaderJoinedCopiers | TDAPI_GetLeaderLeavingCopiers |
|--------|------------------------------|-------------------------------|
| Data source | Trade.Mirror (active) | History.Mirror (stopped, MirrorOperationID=2) |
| Date filter | Mirror.Occurred (start date) | History.Mirror.ModificationDate (stop date) |
| Temp tables / CTE | #MirrorPnL + CTE | CTE (resTable) only |
| Extra columns | InvestedPercentage | CopyStop, CopyDurationInDays, CloseReason |
| Sort columns | 6 | 8 |
| "Not active" check | N/A (always active in Trade.Mirror) | LEFT JOIN Trade.Mirror WHERE tm.CID IS NULL |
| RS1 label | ActiveJoiners | NonActiveLeavers |
| Early exit | None | IF @@ROWCOUNT = 0 RETURN |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| "Not currently active" filter | Business Rule | Only ex-copiers who have NO active Trade.Mirror row for this leader are included. Copiers who stopped and restarted are excluded. |
| MIN 1 day duration | Business Rule | CASE WHEN DATEDIFF=0 THEN 1 - same-day copy sessions counted as 1 day. |
| Max page size | Business Rule | @ItemsPerPage capped at 50. |
| RS2 early exit | Performance | RS2 not produced when @@ROWCOUNT=0 after RS1 count. Callers must check RS1 first. |

---

## 8. Sample Queries

### 8.1 Get copiers who recently left a PI

```sql
EXEC Trade.TDAPI_GetLeaderLeavingCopiers
    @ParentCID = 55555,
    @StartDate = NULL,
    @OrderbyDesc = 1,
    @OrderColumn = 5,
    @PageNumber = 1,
    @ItemsPerPage = 10
-- RS1: count; RS2: 10 most recently stopped copiers
```

### 8.2 Sort by copy duration (longest copiers who left)

```sql
EXEC Trade.TDAPI_GetLeaderLeavingCopiers
    @ParentCID = 55555,
    @StartDate = '2024-06-01',
    @OrderbyDesc = 1,
    @OrderColumn = 6,
    @PageNumber = 1,
    @ItemsPerPage = 20
```

### 8.3 Query ex-copiers directly for a PI

```sql
SELECT hm.CID, hm.MirrorID, hm.Occurred AS CopyStart, hm.ModificationDate AS CopyStop,
       DATEDIFF(day, hm.Occurred, hm.ModificationDate) AS DurationDays,
       100.0 * ISNULL(hm.NetProfit,0) / NULLIF(hm.InitialInvestment + hm.DepositSummary, 0) AS NetProfitPct,
       hm.CloseMirrorActionType AS CloseReason
FROM History.Mirror hm WITH (NOLOCK)
INNER JOIN (
    SELECT CID, MAX(ModificationDate) as MaxStopDate
    FROM History.Mirror WITH (NOLOCK)
    WHERE ParentCID = 55555 AND MirrorOperationID = 2
      AND ModificationDate >= DATEADD(month,-1,GETUTCDATE())
    GROUP BY CID
) latest ON hm.CID = latest.CID AND hm.ModificationDate = latest.MaxStopDate
LEFT JOIN Trade.Mirror tm WITH (NOLOCK) ON hm.CID = tm.CID AND tm.ParentCID = 55555
WHERE hm.ParentCID = 55555 AND tm.CID IS NULL
ORDER BY hm.ModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderLeavingCopiers | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderLeavingCopiers.sql*
