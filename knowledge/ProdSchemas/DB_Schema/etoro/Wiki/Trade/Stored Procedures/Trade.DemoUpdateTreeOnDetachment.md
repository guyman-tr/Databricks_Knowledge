# Trade.DemoUpdateTreeOnDetachment

> Demo-only procedure that reassigns positions to a new copy-trade tree when detaching from a parent, creating a PositionTreeInfo record and updating TreeID on child positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewTreeID, @ParentPositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure handles **copy-trade tree reassignment in demo environments** when a position is detached from its parent. In copy-trading, positions form a hierarchical tree (parent -> child copiers). When a child position detaches, it needs a new TreeID in Trade.PositionTreeInfo to maintain its own stop-loss, take-profit, and close-on-end-of-week settings independently.

This procedure is restricted to demo environments only (Maintenance.Feature FeatureID=22 must NOT be 1/real). On real environments, a different code path handles detachment. The procedure creates a new PositionTreeInfo record for the detached tree, logs the change to History.PositionChangeLog_Active_BIGINT with ChangeTypeID=6, and updates all child positions under @ParentPositionID to use the @NewTreeID.

The data flow is: check real/demo flag -> create PositionTreeInfo record (if not exists) by copying StopRate/LimitRate/CloseOnEndOfWeek from the position -> log the tree change -> UPDATE Trade.PositionTbl SET TreeID = @NewTreeID for all positions WHERE ParentPositionID = @ParentPositionID.

---

## 2. Business Logic

### 2.1 Demo-Only Safety Guard

**What**: Prevents execution on real/production environments.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID`, `Maintenance.Feature.Value`

**Rules**:
- Reads Maintenance.Feature WHERE FeatureID = 22
- If Value = 1 (real): RAISERROR "You can't use this procedure in Real environment"
- Only proceeds on demo environments (Value = 0)

### 2.2 PositionTreeInfo Creation

**What**: Creates a new tree record if one doesn't exist for @NewTreeID.

**Columns/Parameters Involved**: `@NewTreeID`, `Trade.PositionTreeInfo.TreeID`, `StopRate`, `LimitRate`, `CloseOnEndOfWeek`

**Rules**:
- Uses XLOCK, ROWLOCK, HOLDLOCK to prevent race conditions when checking for existing record
- If NOT EXISTS: copies StopRate, LimitRate, CloseOnEndOfWeek from RealOpenPositions (or RealHistoryPosition if not found in open)
- INSERT INTO Trade.PositionTreeInfo with the copied values

### 2.3 Change Logging and TreeID Update

**What**: Logs the tree change and updates all child positions.

**Columns/Parameters Involved**: `@NewTreeID`, `@ParentPositionID`, `ChangeTypeID=6`

**Rules**:
- INSERT INTO History.PositionChangeLog_Active_BIGINT with ChangeTypeID=6 (tree reassignment)
- Records PrevTreeID (old tree) and new TreeID for each affected position
- UPDATE Trade.PositionTbl SET TreeID = @NewTreeID WHERE ParentPositionID = @ParentPositionID
- OUTPUT INSERTED.PositionID returns the list of updated positions to the caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NewTreeID | BIGINT | NO | - | CODE-BACKED | The new TreeID to assign to the detached positions. Typically @IsReal * @PositionID (positive for real, negative for demo). Used as the PK for the new PositionTreeInfo record. |
| 2 | @ParentPositionID | BIGINT | NO | - | CODE-BACKED | The parent position from which child positions are being detached. All positions WHERE ParentPositionID = this value will have their TreeID updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Maintenance.Feature | Lookup | Reads FeatureID=22 to verify demo environment |
| (SELECT/INSERT) | Trade.PositionTreeInfo | Read + Write | Checks for existing tree record, creates new one if needed |
| (SELECT) | RealOpenPositions | Read (synonym/view) | Copies StopRate/LimitRate/CloseOnEndOfWeek for the new tree |
| (SELECT) | RealHistoryPosition | Read (synonym/view) | Fallback source for tree settings if not found in open positions |
| (INSERT) | History.PositionChangeLog_Active_BIGINT | Write | Logs tree change with ChangeTypeID=6 |
| (UPDATE) | Trade.PositionTbl | Write | Sets TreeID = @NewTreeID on all child positions |
| (SELECT) | Trade.Position | Read (view) | Reads position data for change log entries |
| (SELECT) | Customer.Customer | Read | Gets RealizedEquity for change log |
| (SELECT) | Trade.Mirror | Read | Gets mirror RealizedEquity for change log |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Demo detachment flows) | N/A | Caller | Called during demo copy-trade tree detachment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DemoUpdateTreeOnDetachment (procedure)
+-- Maintenance.Feature (table)
+-- Trade.PositionTreeInfo (table)
+-- Trade.PositionTbl (table)
+-- Trade.Position (view)
+-- RealOpenPositions (synonym/view)
+-- RealHistoryPosition (synonym/view)
+-- Customer.Customer (table)
+-- Trade.Mirror (table)
+-- History.PositionChangeLog_Active_BIGINT (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | Read FeatureID=22 for real/demo check |
| Trade.PositionTreeInfo | Table | Read + INSERT - creates new tree record |
| Trade.PositionTbl | Table | UPDATE - sets new TreeID on child positions |
| Trade.Position | View | Read - gets position data for change log |
| RealOpenPositions | Synonym/View | Read - copies tree settings |
| RealHistoryPosition | Synonym/View | Read - fallback for tree settings |
| Customer.Customer | Table | Read - gets RealizedEquity for change log |
| Trade.Mirror | Table | Read - gets mirror RealizedEquity for change log |
| History.PositionChangeLog_Active_BIGINT | Table | INSERT - logs tree change (ChangeTypeID=6) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo | - | Called from application layer during demo detachment |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Uses explicit BEGIN TRAN with XLOCK/ROWLOCK/HOLDLOCK on the PositionTreeInfo check to prevent race conditions. Returns @Flag (0=success, 1=change log failure, -1=critical error).

---

## 8. Sample Queries

### 8.1 Check positions under a parent

```sql
SELECT  PositionID, CID, TreeID, ParentPositionID, MirrorID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   ParentPositionID = 12345;
```

### 8.2 Verify PositionTreeInfo for a tree

```sql
SELECT  TreeID, StopRate, LimitRate, CloseOnEndOfWeek
FROM    Trade.PositionTreeInfo WITH (NOLOCK)
WHERE   TreeID = -12345;
```

### 8.3 View recent tree changes in change log

```sql
SELECT  TOP 20 PositionID, ChangeTypeID, TreeID, PrevTreeID, Occurred
FROM    History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE   ChangeTypeID = 6
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DemoUpdateTreeOnDetachment | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DemoUpdateTreeOnDetachment.sql*
