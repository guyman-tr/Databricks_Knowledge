# Trade.GetMirrorDataWithCIDAndMirrorIdForAPI

> Comprehensive CopyTrader API endpoint that returns a mirror relationship's full state: mirror details, all copied positions (with optional hierarchy), entry/exit orders, open/close execution orders, and delayed orders for a specific MirrorID+CID pair.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: up to 10 result sets covering mirror, positions, and all order types |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorDataWithCIDAndMirrorIdForAPI is the primary API-facing procedure for retrieving a complete snapshot of a single CopyTrader mirror relationship for a specific copier. It returns the mirror details, all copied positions, entry orders, exit orders, orders-for-open, orders-for-close (with execution plans), and delayed orders. This is the full state needed for the Trading API to render a copier's mirror portfolio.

This procedure exists because the CopyTrader UI and API need a single call to hydrate the complete state of a mirror - including all pending and in-flight orders. Without it, the API would need multiple round-trips to assemble this data. The optional @returnPositionMirrorHierarchy flag adds parent/grandparent CopyTrader hierarchy information when enabled.

Note: Entry orders and exit orders result sets include `AND 1=0` filter, effectively returning empty sets. This appears to be a deliberate disabling of these legacy result sets while maintaining backward compatibility with API consumers that expect the result set shape.

---

## 2. Business Logic

### 2.1 Multi-Result-Set Architecture

**What**: Returns up to 10 result sets in a single call for complete mirror state hydration.

**Result Sets**:
1. **Mirror Data**: From Trade.Mirror - mirror details, amounts, status
2. **Copied Positions**: From Trade.Position - all open positions for this mirror+CID (via TVP Trade.PositionData_MOT)
3. **Entry Orders** (DISABLED: `AND 1=0`): From Trade.OrdersEntry - legacy, returns empty
4. **Exit Orders** (DISABLED: `AND 1=0`): From Trade.OrdersExit - legacy, returns empty
5. **Orders for Open**: From Trade.OrderForOpen - active non-terminal open orders
6. **Orders for Close** (distinct): From Trade.OrderForClose + CloseExecutionPlan - active close orders
7. **Orders for Close (position map)**: OrderID to PositionID mapping
8. **Delayed Orders for Open**: From Trade.DelayedOrderForOpen with StatusID=1 (PLACED)
9. **Delayed Orders for Close** (distinct): From Trade.DelayedOrderForClose with StatusID=1
10. **Delayed Orders for Close (position map)**: OrderID to PositionID mapping

### 2.2 Position Hierarchy Mode

**What**: When @returnPositionMirrorHierarchy=1, enriches positions with parent/grandparent CopyTrader details.

**Columns/Parameters Involved**: `@returnPositionMirrorHierarchy`, `Trade.Mirror tm1`, `Trade.Mirror tm2`

**Rules**:
- @returnPositionMirrorHierarchy=0 (default): Returns position data as-is from Trade.Position
- @returnPositionMirrorHierarchy=1: Joins back to Trade.Position and Trade.Mirror to add ParentCID, GrandParentCID, ParentUserName, GrandParentUserName, ParentMirrorID
- Supports multi-level CopyTrader chains (copier -> trader -> trader's trader)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @mirrorId | int | IN | - | CODE-BACKED | The specific CopyTrader mirror ID to retrieve data for. |
| 2 | @cid | int | IN | - | CODE-BACKED | The copier's customer ID. Must match the mirror's CID. |
| 3 | @returnPositionMirrorHierarchy | bit | IN | 0 | CODE-BACKED | When 1, enriches positions with parent/grandparent CopyTrader hierarchy (ParentCID, GrandParentCID, usernames). Default 0 for flat position data. |

### 4.2 Key Result Set Fields (Mirror - Set 1)

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CID | int | CODE-BACKED | Copier's customer ID. |
| 2 | MirrorID | int | CODE-BACKED | Mirror relationship ID. |
| 3 | ParentCID | int | CODE-BACKED | Copied trader's customer ID. |
| 4 | Amount | money | CODE-BACKED | Current mirror investment amount. |
| 5 | MirrorSL | money | CODE-BACKED | Stop-loss amount. |
| 6 | MirrorSLPercentage | decimal | CODE-BACKED | Stop-loss percentage. |
| 7 | PauseCopy | bit | CODE-BACKED | Whether copying is paused. |
| 8 | IsOpenOpen | bit | CODE-BACKED | Whether new positions can be opened. ISNULL to 0. |
| 9 | MirrorCalculationType | int | CODE-BACKED | Allocation calculation method. |
| 10 | MirrorStatusID | int | CODE-BACKED | Mirror lifecycle status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Mirror | SELECT (READER) | Mirror relationship details |
| FROM | Trade.Position | SELECT (READER) | Copied positions for this mirror |
| FROM | Trade.OrdersEntry | SELECT (READER) | Entry orders (disabled with 1=0) |
| FROM | Trade.OrdersExit | SELECT (READER) | Exit orders (disabled with 1=0) |
| FROM | Trade.OrderForOpen | SELECT (READER) | Active open orders |
| FROM | Trade.OrderForClose | SELECT (READER) | Active close orders |
| FROM | Trade.CloseExecutionPlan | SELECT (READER) | Close order execution plans |
| FROM | Dictionary.OrderForExecutionStatus | SELECT (READER) | Terminal status filter |
| FROM | Trade.DelayedOrderForOpen | SELECT (READER) | Delayed open orders |
| FROM | Trade.DelayedOrderForClose | SELECT (READER) | Delayed close orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application) | Direct call | Application | Trading API mirror portfolio |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorDataWithCIDAndMirrorIdForAPI (procedure)
+-- Trade.Mirror (table)
+-- Trade.Position (view)
+-- Trade.OrdersEntry (table)
+-- Trade.OrdersExit (table)
+-- Trade.OrderForOpen (table)
+-- Trade.OrderForClose (table)
+-- Trade.CloseExecutionPlan (table)
+-- Dictionary.OrderForExecutionStatus (table)
+-- Trade.DelayedOrderForOpen (table)
+-- Trade.DelayedOrderForClose (table)
+-- Trade.PositionData_MOT (type)
+-- Trade.OrderWithPositions_MOT (type)
+-- Trade.DelayedOrdersForClose_MOT (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Mirror data + hierarchy JOINs |
| Trade.Position | View | Copied positions lookup |
| Trade.OrdersEntry | Table | Entry orders (disabled) |
| Trade.OrdersExit | Table | Exit orders (disabled) |
| Trade.OrderForOpen | Table | Active open orders |
| Trade.OrderForClose | Table | Active close orders |
| Trade.CloseExecutionPlan | Table | Close execution plan |
| Dictionary.OrderForExecutionStatus | Table | Terminal status filter |
| Trade.DelayedOrderForOpen | Table | Delayed open orders |
| Trade.DelayedOrderForClose | Table | Delayed close orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No DB-level dependents found) | - | Called from Trading API |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

TRY/CATCH with THROW. Uses TVPs (Trade.PositionData_MOT, Trade.OrderWithPositions_MOT, Trade.DelayedOrdersForClose_MOT) as intermediate staging.

---

## 8. Sample Queries

### 8.1 Get full mirror data for API

```sql
EXEC Trade.GetMirrorDataWithCIDAndMirrorIdForAPI
    @mirrorId = 12345,
    @cid = 67890,
    @returnPositionMirrorHierarchy = 0;
```

### 8.2 Get with hierarchy

```sql
EXEC Trade.GetMirrorDataWithCIDAndMirrorIdForAPI
    @mirrorId = 12345,
    @cid = 67890,
    @returnPositionMirrorHierarchy = 1;
```

### 8.3 Check active mirrors for a customer

```sql
SELECT  MirrorID, ParentCID, Amount, IsActive, MirrorStatusID
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   CID = 67890 AND IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorDataWithCIDAndMirrorIdForAPI.sql*
