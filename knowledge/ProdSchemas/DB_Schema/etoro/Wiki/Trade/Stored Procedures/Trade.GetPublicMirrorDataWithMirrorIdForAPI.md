# Trade.GetPublicMirrorDataWithMirrorIdForAPI

> Returns a specific CopyTrader mirror's state as up to five result sets: the mirror record, then (if active) the copied positions, copied stock orders, copied entry orders, and copied exit orders for that mirror. Companion to GetPublicMirrorDataWithCIDForAPI but filtered by MirrorID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @mirrorId INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure loads the portfolio state for a specific CopyTrader mirror relationship (identified by MirrorID), returning the mirror record and all trades associated with it. It is the mirror-ID-scoped counterpart to `GetPublicMirrorDataWithCIDForAPI` (which returns all mirrors for a customer). Used when the public API needs data for a single specific copy-trade relationship rather than all of a customer's mirrors.

The conditional pattern (result sets 2-5 only if mirror is active) prevents empty result sets for inactive or non-existent mirrors.

---

## 2. Business Logic

### 2.1 Conditional Five-Result-Set Pattern

**What**: Same conditional pattern as GetPublicMirrorDataWithCIDForAPI, but filtered by @mirrorId instead of CID.

**Rules**:
- Result set 1: Trade.Mirror WHERE MirrorID=@mirrorId AND IsActive=1.
- IF @@ROWCOUNT > 0 (mirror exists and is active): return result sets 2-5.
- Result set 2: Positions WHERE MirrorID=@mirrorId AND ParentPositionID>0.
- Result set 3: Stocks.Orders WHERE MirrorID=@mirrorId.
- Result set 4: Trade.OrdersEntry WHERE MirrorID=@mirrorId.
- Result set 5: Trade.OrdersExit WHERE MirrorID=@mirrorId.
- Exit orders result set (RS5): Does NOT include OpenActionType or MirrorCloseActionType (differs from GetPublicMirrorDataWithCIDForAPI RS5 which has both).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @mirrorId | INT | NO | - | CODE-BACKED | The specific CopyTrader mirror relationship ID to retrieve data for. |

**Output columns**: Same schemas as `Trade.GetPublicMirrorDataWithCIDForAPI` for all result sets, except:
- RS5 (Exit Orders): columns are OrderID, CID, OpenOccurred, PositionID, InstrumentID, MirrorID (no MirrorCloseActionType, no OpenActionType).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.Mirror | Reader | The specific mirror record |
| PositionID | Trade.Position | Reader + JOIN | Copied positions for this mirror; JOIN for InstrumentID in exit orders |
| Stock OrderID | Stocks.Orders | Reader | Stock orders for this mirror |
| Entry OrderID | Trade.OrdersEntry | Reader | Entry orders for this mirror |
| Exit OrderID | Trade.OrdersExit | Reader | Exit orders for this mirror |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @mirrorId | Application call | Single mirror portfolio data for display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPublicMirrorDataWithMirrorIdForAPI (procedure)
+-- Trade.Mirror (table)
+-- Trade.Position (view)
+-- Stocks.Orders (table)
+-- Trade.OrdersEntry (table)
+-- Trade.OrdersExit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Mirror record lookup (IsActive=1) |
| Trade.Position | View | Copied positions (MirrorID=@mirrorId, ParentPositionID>0); JOIN for InstrumentID |
| Stocks.Orders | Table | Copied stock orders |
| Trade.OrdersEntry | Table | Copied entry orders |
| Trade.OrdersExit | Table | Copied exit orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Single mirror portfolio state |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @@ROWCOUNT guard | Conditional | Result sets 2-5 only if mirror exists and is active |
| IsActive=1 | Mirror filter | Inactive mirrors return only the (empty) first result set |
| NOLOCK | Isolation | All reads are READ UNCOMMITTED |

---

## 8. Sample Queries

### 8.1 Get portfolio state for a specific mirror

```sql
EXEC Trade.GetPublicMirrorDataWithMirrorIdForAPI @mirrorId = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicMirrorDataWithMirrorIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicMirrorDataWithMirrorIdForAPI.sql*
