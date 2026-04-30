# Trade.GetPublicMirrorDataWithCIDForAPI

> Returns a customer's CopyTrader mirror state as up to five result sets: active mirrors, then (if mirrors exist) the copied positions, copied stock orders, copied entry orders, and copied exit orders. Consumed by the public API for copy-trade portfolio display.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure loads the CopyTrader portfolio for a customer: their active mirror relationships and all associated copied trades. Unlike `GetPublicClientPortfolioForAPI` (which returns the full portfolio including manual trades), this procedure focuses exclusively on mirror/copy-trade data. The conditional pattern (result sets 2-5 only returned if the customer has active mirrors) avoids unnecessary result sets for non-copiers.

The "Public" prefix indicates this is the API-facing version using NOLOCK.

---

## 2. Business Logic

### 2.1 Conditional Result Sets Pattern

**What**: Result sets 2-5 are only returned if the customer has at least one active mirror.

**Rules**:
- Result set 1: Always returned. Trade.Mirror WHERE CID=@cid AND IsActive=1.
- IF @@ROWCOUNT > 0 (customer is actively copying at least one leader): return result sets 2-5.
- Result set 2: Copied positions (MirrorID>0 AND ParentPositionID>0) - only copy-trade positions, not manual.
- Result set 3: Stock orders in mirrors (MirrorID>0).
- Result set 4: Entry orders in mirrors (MirrorID>0).
- Result set 5: Exit orders in mirrors (MirrorID>0). Includes OpenActionType (not in GetPublicClientPortfolioForAPI exit result set).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Used to scope all result sets to a single follower. |

**Result Set 1: Active Mirrors** - see `Trade.GetPublicClientPortfolioForAPI` section 4 (Result Set 2) for column descriptions. Same schema.

**Result Set 2: Copied Positions** - same schema as GetPublicClientPortfolioForAPI Result Set 3, with additional filter: MirrorID>0 AND ParentPositionID>0.

**Result Set 3: Copied Stock Orders** - same schema as GetPublicClientPortfolioForAPI Result Set 4, with additional filter: MirrorID>0.

**Result Set 4: Copied Entry Orders** - same schema as GetPublicClientPortfolioForAPI Result Set 5, with additional filter: MirrorID>0.

**Result Set 5: Copied Exit Orders** - same columns as GetPublicClientPortfolioForAPI Result Set 6, plus:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | OpenActionType | INT | YES | - | CODE-BACKED | Action type of the original open order for this exit. Additional column vs. GetPublicClientPortfolioForAPI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.Mirror | Reader | Active mirrors for the customer |
| PositionID | Trade.Position | Reader + JOIN | Copied positions; also JOIN for InstrumentID in exit orders |
| Stock OrderID | Stocks.Orders | Reader | Copied stock orders |
| Entry OrderID | Trade.OrdersEntry | Reader | Copied entry orders |
| Exit OrderID | Trade.OrdersExit | Reader | Copied exit orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @cid | Application call | Copy-trade portfolio display for a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPublicMirrorDataWithCIDForAPI (procedure)
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
| Trade.Mirror | Table | Active mirrors for the customer (IsActive=1) |
| Trade.Position | View | Copied open positions (MirrorID>0, ParentPositionID>0); also JOIN for exit order InstrumentID |
| Stocks.Orders | Table | Copied stock orders (MirrorID>0) |
| Trade.OrdersEntry | Table | Copied entry orders (MirrorID>0) |
| Trade.OrdersExit | Table | Copied exit orders (MirrorID>0) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Copy-trade portfolio data for customer display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @@ROWCOUNT guard | Conditional | Result sets 2-5 only returned if customer has active mirrors |
| MirrorID>0 AND ParentPositionID>0 | Copy filter | Excludes manual positions from copied positions result set |
| IsActive=1 | Mirror filter | Only active copy relationships returned |
| NOLOCK | Isolation | All reads are READ UNCOMMITTED for API performance |

---

## 8. Sample Queries

### 8.1 Get mirror portfolio for a customer

```sql
EXEC Trade.GetPublicMirrorDataWithCIDForAPI @cid = 1234567;
-- Returns 1 result set if no active mirrors, 5 result sets if active mirrors exist
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicMirrorDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicMirrorDataWithCIDForAPI.sql*
