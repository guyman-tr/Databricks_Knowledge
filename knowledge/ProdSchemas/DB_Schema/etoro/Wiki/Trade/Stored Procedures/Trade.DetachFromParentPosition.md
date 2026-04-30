# Trade.DetachFromParentPosition

> Detaches a copied position from its parent in the copy-trade hierarchy, creating a new tree, updating child positions, recording credit changes, and logging the detachment in History.PositionChangeLog.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure handles **position-level detachment from a copy-trade parent**. When a copier's position needs to be disconnected from the leader's position (e.g., mirror stopped, manual detach), this procedure breaks the parent-child link, creates a new independent tree for the position, and records the financial/audit implications.

The procedure is used in both real and demo environments (unlike DemoUpdateTreeOnDetachment which is demo-only). It determines the real/demo environment from Maintenance.Feature FeatureID=22, resolves the position's parent/mirror/tree data, creates a new PositionTreeInfo record for stock instruments (@StockFlag < 1000), updates the position's ParentPositionID to 0 and TreeID to the new tree, recursively updates all child positions' TreeID, records credit via Customer.SetBalance (CreditTypeID=27 = Detachment), and logs the change to History.PositionChangeLog_Active_BIGINT with ChangeTypeID=5.

---

## 2. Business Logic

### 2.1 Stock vs CFD Tree Handling

**What**: Only stock-like instruments get a new PositionTreeInfo record.

**Columns/Parameters Involved**: `Trade.ProviderToInstrument.Enabled`, `@StockFlag`, `@InstrumentID`

**Rules**:
- Reads Trade.ProviderToInstrument WHERE InstrumentID = @InstrumentID. If Enabled=0 then @StockFlag=1001 (non-stock), else @StockFlag=1 (stock-like)
- If @StockFlag < 1000: INSERT INTO Trade.PositionTreeInfo with StopRate/LimitRate/CloseOnEndOfWeek from the position, TreeID = @IsReal * @PositionID
- If @StockFlag >= 1000: TreeID is set to 0 (no tree for CFDs)

### 2.2 Recursive Child Position Update

**What**: Recursively updates all child positions' TreeID using a CTE.

**Columns/Parameters Involved**: `Trade.PositionTbl.ParentPositionID`, `Trade.PositionTbl.TreeID`

**Rules**:
- Uses recursive CTE starting from @PositionID, following ParentPositionID chains
- Updates all descendants to use the new TreeID
- Only applies when @StockFlag < 1000 and @ShouldUpdateTradePositions = 1

### 2.3 Mirror Credit Recording

**What**: Records a credit entry for the mirror detachment.

**Columns/Parameters Involved**: `@MirrorID`, `@CID`, `Customer.SetBalance`

**Rules**:
- Only when @MirrorID > 0 (position was part of a mirror/copy relationship)
- Calls Customer.SetBalance with CreditTypeID=27 (Detachment), Description='Mirror Position Disconnected'
- @Payment flag: 0=take Amount from position, 1=use 0 (called from PositionClose where payment was already handled)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position being detached from its parent. |
| 2 | @ParentPositionID | BIGINT | NO | 0 | CODE-BACKED | Parent position ID. If 0 (default), resolved from Trade.PositionTbl. |
| 3 | @ShouldUpdateTradePositions | TINYINT | NO | 1 | CODE-BACKED | Controls whether PositionTbl is updated: 1=update ParentPositionID/TreeID, 0=skip (caller handles update, e.g., PositionClose). |
| 4 | @Payment | INT | NO | 0 | CODE-BACKED | Flag controlling mirror credit calculation: 0=use position Amount for MirrorEquityChange, 1=use 0 (position close already handled payment). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.PositionTbl | Read + Write | Reads position data, updates ParentPositionID=0 and TreeID |
| (INSERT) | Trade.PositionTreeInfo | Write | Creates new tree record for detached stock positions |
| (SELECT) | Trade.ProviderToInstrument | Read | Determines if instrument is stock-like (Enabled) |
| (SELECT) | Maintenance.Feature | Read | Reads FeatureID=22 for real/demo environment |
| (EXEC) | Customer.SetBalance | Procedure call | Records mirror detachment credit (CreditTypeID=27) |
| (INSERT) | History.PositionChangeLog_Active_BIGINT | Write | Logs detachment with ChangeTypeID=5 |
| (SELECT) | Trade.Position | Read (view) | Gets position data for change log |
| (SELECT) | Customer.Customer | Read | Gets RealizedEquity for change log |
| (SELECT) | Trade.Mirror | Read | Gets mirror RealizedEquity for change log |
| (INSERT) | History.LogErrorGeneral | Write | Logs errors if change log INSERT fails |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionClose | EXEC call | Caller | Calls with @Payment=1, @ShouldUpdateTradePositions=0 |
| (Copy-trade detachment flows) | N/A | Caller | Called during mirror disconnection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DetachFromParentPosition (procedure)
+-- Trade.PositionTbl (table)
+-- Trade.PositionTreeInfo (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.Position (view)
+-- Maintenance.Feature (table)
+-- Customer.Customer (table)
+-- Customer.SetBalance (procedure)
+-- Trade.Mirror (table)
+-- History.PositionChangeLog_Active_BIGINT (table)
+-- History.LogErrorGeneral (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Read + UPDATE ParentPositionID, TreeID |
| Trade.PositionTreeInfo | Table | INSERT new tree record |
| Trade.ProviderToInstrument | Table | Read Enabled flag for stock/CFD distinction |
| Maintenance.Feature | Table | Read FeatureID=22 for real/demo |
| Trade.Position | View | Read position data for change log |
| Customer.Customer | Table | Read RealizedEquity |
| Customer.SetBalance | Stored Procedure | Record detachment credit |
| Trade.Mirror | Table | Read mirror RealizedEquity |
| History.PositionChangeLog_Active_BIGINT | Table | INSERT detachment log (ChangeTypeID=5) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionClose | Stored Procedure | Calls during position closure to detach from parent |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Uses XACT_ABORT ON with explicit transaction. The change log INSERT is in a separate TRY/CATCH outside the main transaction - if the log fails, @Flag=1 is returned but the detachment itself succeeds. Errors are logged to History.LogErrorGeneral.

---

## 8. Sample Queries

### 8.1 Find positions with parent links (copy-trade children)

```sql
SELECT  PositionID, ParentPositionID, MirrorID, TreeID, CID, InstrumentID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   ParentPositionID > 0
ORDER BY MirrorID;
```

### 8.2 View recent detachment logs

```sql
SELECT  TOP 20 PositionID, ChangeTypeID, TreeID, PrevTreeID, CID, Occurred
FROM    History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE   ChangeTypeID = 5
ORDER BY Occurred DESC;
```

### 8.3 Check PositionTreeInfo for a detached position

```sql
DECLARE @PosID BIGINT = 12345;
SELECT  TreeID, StopRate, LimitRate, CloseOnEndOfWeek
FROM    Trade.PositionTreeInfo WITH (NOLOCK)
WHERE   TreeID IN (@PosID, -@PosID);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.6/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DetachFromParentPosition | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DetachFromParentPosition.sql*
