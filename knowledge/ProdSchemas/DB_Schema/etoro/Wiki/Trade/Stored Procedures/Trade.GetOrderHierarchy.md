# Trade.GetOrderHierarchy

> Returns the order tree for a given parent order ID using a recursive CTE, with recursive traversal gated by a feature flag in Maintenance.Feature.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID INT (root of the hierarchy to retrieve) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderHierarchy` traverses the order parent-child relationship in `Trade.GetOrders` (view over Trade.Orders), starting from all direct children of `@OrderID` and optionally recursing into deeper levels. It returns the complete subtree of orders that descend from the given order. The "Level" column in the output is always 0 due to the recursive CTE not incrementing it.

**WHY:** Orders on eToro's platform can have a parent-child structure (e.g., a copy-trade order spawns child orders for each copier). This SP provides a way to retrieve the full order tree for a given root order, useful for BI analysis, reconciliation, and debugging hierarchical order flows. Access is granted to the PROD_BIadmins role indicating this is used primarily for BI/analytics purposes.

**HOW:**
1. Anchor: Select all orders where `ParentOrderID = @OrderID` (Level 0 - direct children of the given order).
2. Recursive step: If `@UseHierarchy = 1` AND `Maintenance.Feature FeatureID = 22` is enabled (cast(Value as int) = 1), join `Trade.GetOrders` back to the CTE on `og.ParentOrderID = oh.OrderID` to traverse deeper levels. The Level value from the parent is carried forward (not incremented) so the output Level is always 0.
3. Result ordered by `Level, ParentOrderID`.

---

## 2. Business Logic

### 2.1 Recursive Hierarchy Traversal - Feature Flag Gated

**What:** The recursive traversal of the order tree is controlled by two conditions: the `@UseHierarchy` parameter AND the Maintenance.Feature flag for FeatureID=22. Both must be true for recursion to occur.

**Columns/Parameters Involved:** `@UseHierarchy`, `Maintenance.Feature.FeatureID=22`, `Maintenance.Feature.Value`

**Rules:**
- If `@UseHierarchy = 0` OR `Maintenance.Feature WHERE FeatureID=22 AND cast(Value as int) != 1`: only direct children of @OrderID are returned (anchor only)
- If `@UseHierarchy = 1` AND feature 22 is enabled: full recursive tree traversal proceeds
- The feature flag (FeatureID=22) acts as a kill switch for hierarchy traversal - operations can disable recursive expansion without changing application code
- The `EXISTS` check in the recursive part is evaluated at each recursion level

### 2.2 Level Column Behavior (Not Incrementing)

**What:** The `Level` column in the output is always 0 for all rows, regardless of tree depth. This is because the recursive part of the CTE uses `SELECT Level, ...` (inheriting from parent row) rather than `SELECT Level + 1, ...`. The column does not represent true depth.

**Columns/Parameters Involved:** `Level`

**Rules:**
- Anchor assigns `0 as Level`
- Recursive part carries `oh.Level` forward unchanged
- Effective behavior: Level = 0 for all output rows regardless of depth
- ORDER BY `Level, ParentOrderID` therefore orders only by ParentOrderID

### 2.3 CTE Typo - "OrderHiararchy"

**What:** The CTE is named `OrderHiararchy` (note the transposed "ia" - should be "OrderHierarchy"). This is an internal name and does not affect the external interface.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The parent order ID to retrieve children for. The SP returns all orders where ParentOrderID = @OrderID (and their descendants if recursion is enabled). |
| 2 | @UseHierarchy | INT | YES | 1 | CODE-BACKED | Controls recursive traversal: 1 = recurse into child orders (subject to feature flag), 0 = return only direct children of @OrderID. Defaults to 1. |

**Output columns (from Trade.GetOrders view):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Level | INT | NO | - | CODE-BACKED | Always 0 for all rows. Intended to represent tree depth but the recursive CTE does not increment this value. See Section 2.2. |
| 2 | OrderID | INT | NO | - | CODE-BACKED | The order ID. From Trade.GetOrders (Trade.Orders). Primary key for the order. |
| 3 | ParentOrderID | INT | YES | - | CODE-BACKED | The parent order ID. Forms the hierarchy: this order's parent is ParentOrderID. The root order (@OrderID) is the parent of all Level-0 results. |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer ID who placed the order. |
| 5 | ForexResultID | INT | YES | - | CODE-BACKED | Forex rate result ID used for this order's currency conversion. |
| 6 | CurrencyID | INT | NO | - | CODE-BACKED | Currency of the order amount. FK to Dictionary.Currency. |
| 7 | ProviderID | INT | YES | - | CODE-BACKED | Liquidity provider ID for this order execution. |
| 8 | Amount | DECIMAL | NO | - | CODE-BACKED | Order amount in the order's currency. |
| 9 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument (asset) being traded. FK to Trade.Instrument. |
| 10 | RateFrom | DECIMAL | YES | - | CODE-BACKED | Lower bound rate for the order (range order lower limit). |
| 11 | RateTo | DECIMAL | YES | - | CODE-BACKED | Upper bound rate for the order (range order upper limit). |
| 12 | StopLosRate | DECIMAL | YES | - | CODE-BACKED | Stop-loss rate for this order. Note spelling in original SP: "StopLosRate" (missing 's'). |
| 13 | TakeProfitRate | DECIMAL | YES | - | CODE-BACKED | Take-profit rate for this order. |
| 14 | StopLosAmount | DECIMAL | YES | - | CODE-BACKED | Stop-loss amount threshold. Note spelling in original SP: "StopLosAmount" (missing 's'). |
| 15 | TakeProfitAmount | DECIMAL | YES | - | CODE-BACKED | Take-profit amount threshold. |
| 16 | IsBuy | INT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. Cast from BIT to INT by the Trade.GetOrders view for application compatibility. |
| 17 | IsOverWeekend | INT | NO | - | CODE-BACKED | 1 if this is an over-weekend order (held across market close/open). Cast from BIT to INT by Trade.GetOrders. |
| 18 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Order size in lots. |
| 19 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier for this order. |
| 20 | Units | DECIMAL | YES | - | CODE-BACKED | Order size in instrument units. |
| 21 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Margin required per unit for this order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.GetOrders | Trade.GetOrders | View | All order data read through this view (wraps Trade.Orders with BIT-to-INT conversions) |
| Feature FeatureID=22 | Maintenance.Feature | Lookup | Feature flag controlling whether recursive hierarchy traversal is enabled |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| UsersPermissions.PROD_BIadmins | GRANT EXECUTE | Permission | BI admin role has execute permission - used for BI/analytics order tree analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderHierarchy (procedure)
|- Trade.GetOrders (view)
|    └── Trade.Orders (table) - all order data
|- Maintenance.Feature (table) - feature flag FeatureID=22 for recursive traversal
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrders | View | All order data for hierarchy traversal. Both anchor and recursive CTE read from this view. |
| Maintenance.Feature | Table | EXISTS check on FeatureID=22 to gate recursive traversal in the recursive CTE step. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| UsersPermissions.PROD_BIadmins | Permission role | GRANT EXECUTE for BI admin access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Recursive CTE max recursion | Default (100) | SQL Server default max recursion applies; deep order trees (>100 levels) would cause an error, but order hierarchies in practice are shallow |
| SET QUOTED_IDENTIFIER ON | Session setting | Standard setting at SP creation |

---

## 8. Sample Queries

### 8.1 Get full order hierarchy for a specific order

```sql
EXEC Trade.GetOrderHierarchy
    @OrderID = 12345678,
    @UseHierarchy = 1
```

### 8.2 Get only direct children (no recursion)

```sql
EXEC Trade.GetOrderHierarchy
    @OrderID = 12345678,
    @UseHierarchy = 0
```

### 8.3 Check if recursive hierarchy feature flag is enabled

```sql
SELECT FeatureID, Value, Description
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 22
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.0/10, Logic: 7.5/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderHierarchy | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderHierarchy.sql*
