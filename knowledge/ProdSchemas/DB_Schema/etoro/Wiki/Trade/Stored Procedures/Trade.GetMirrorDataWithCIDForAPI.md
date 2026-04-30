# Trade.GetMirrorDataWithCIDForAPI

> Comprehensive CopyTrader API endpoint that returns ALL mirror relationships and their full state (positions, orders, hierarchy) for a customer, across all mirrors the customer is copying.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: up to 10 result sets covering ALL mirrors for a CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorDataWithCIDForAPI is the customer-level variant of GetMirrorDataWithCIDAndMirrorIdForAPI. While the mirror-specific variant returns data for a single mirror, this procedure returns ALL active copy relationships for a customer. It's the primary endpoint for rendering the customer's complete CopyTrader portfolio.

This procedure exists because when a customer opens the CopyTrader section of the app, the UI needs data for ALL their active mirrors at once - not just one. The procedure returns all mirrors from Trade.Mirror, then ALL copied positions across ALL mirrors (MirrorID > 0), and all associated orders.

The structure is nearly identical to GetMirrorDataWithCIDAndMirrorIdForAPI but filtered by CID only (not CID+MirrorID). Supports the same @returnPositionMirrorHierarchy flag for parent/grandparent hierarchy enrichment. Entry/exit order result sets are disabled (AND 1=0) matching the mirror-specific variant.

---

## 2. Business Logic

### 2.1 Customer-Level Multi-Mirror Data

**What**: Returns all mirrors and all copied positions/orders for a customer in a single call.

**Columns/Parameters Involved**: `@cid`, `Trade.Mirror`, `Trade.Position`, order tables

**Rules**:
- Mirror data: SELECT FROM Trade.Mirror WHERE CID = @cid (returns all mirrors)
- Positions: WHERE MirrorID > 0 AND ParentPositionID > 0 AND CID = @cid (all copied positions)
- Orders: WHERE CID = @cid AND MirrorID > 0 (all mirror-related orders)
- Same 10 result sets as GetMirrorDataWithCIDAndMirrorIdForAPI
- Same @returnPositionMirrorHierarchy support
- Same disabled entry/exit order legacy result sets

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @cid | int | IN | - | CODE-BACKED | Customer ID to retrieve all CopyTrader data for. Returns ALL active mirrors and their positions/orders. |
| 2 | @returnPositionMirrorHierarchy | bit | IN | 0 | CODE-BACKED | When 1, enriches positions with parent/grandparent CopyTrader hierarchy (ParentCID, GrandParentCID, usernames). |

### 4.2 Key Result Set Fields (Mirror - Set 1)

Same as Trade.GetMirrorDataWithCIDAndMirrorIdForAPI (CID, MirrorID, ParentCID, Amount, MirrorSL, MirrorSLPercentage, PauseCopy, IsOpenOpen, MirrorCalculationType, MirrorStatusID, etc.) but returns multiple rows (one per mirror).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Mirror | SELECT (READER) | All mirrors for CID |
| FROM | Trade.Position | SELECT (READER) | All copied positions |
| FROM | Trade.OrdersEntry | SELECT (READER) | Entry orders (disabled) |
| FROM | Trade.OrdersExit | SELECT (READER) | Exit orders (disabled) |
| FROM | Trade.OrderForOpen | SELECT (READER) | Active open orders |
| FROM | Trade.OrderForClose | SELECT (READER) | Active close orders |
| FROM | Trade.CloseExecutionPlan | SELECT (READER) | Close execution plans |
| FROM | Dictionary.OrderForExecutionStatus | SELECT (READER) | Terminal status filter |
| FROM | Trade.DelayedOrderForOpen | SELECT (READER) | Delayed open orders |
| FROM | Trade.DelayedOrderForClose | SELECT (READER) | Delayed close orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Trading API) | Direct call | Application | Customer CopyTrader portfolio |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorDataWithCIDForAPI (procedure)
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
| Trade.Mirror | Table | All mirrors for customer |
| Trade.Position | View | All copied positions |
| Trade.OrdersEntry | Table | Entry orders |
| Trade.OrdersExit | Table | Exit orders |
| Trade.OrderForOpen | Table | Open orders |
| Trade.OrderForClose | Table | Close orders |
| Trade.CloseExecutionPlan | Table | Close plans |
| Dictionary.OrderForExecutionStatus | Table | Status filter |
| Trade.DelayedOrderForOpen | Table | Delayed open |
| Trade.DelayedOrderForClose | Table | Delayed close |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Trading API) | Application | Customer portfolio |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

TRY/CATCH with THROW. Uses same TVPs as GetMirrorDataWithCIDAndMirrorIdForAPI.

---

## 8. Sample Queries

### 8.1 Get all mirror data for a customer

```sql
EXEC Trade.GetMirrorDataWithCIDForAPI @cid = 67890;
```

### 8.2 Get with hierarchy

```sql
EXEC Trade.GetMirrorDataWithCIDForAPI @cid = 67890, @returnPositionMirrorHierarchy = 1;
```

### 8.3 Count mirrors and copied positions per customer

```sql
SELECT  m.CID,
        COUNT(DISTINCT m.MirrorID) AS ActiveMirrors,
        COUNT(p.PositionID) AS CopiedPositions
FROM    Trade.Mirror m WITH (NOLOCK)
        LEFT JOIN Trade.PositionTbl p WITH (NOLOCK) ON m.MirrorID = p.MirrorID AND p.StatusID = 1
WHERE   m.CID = 67890 AND m.IsActive = 1
GROUP BY m.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorDataWithCIDForAPI.sql*
