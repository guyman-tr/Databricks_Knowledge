# Dictionary.TradeActivity_ExecutionTypes

> Defines execution action categories for trade activity reporting (Normal, Transfer, Staking, CorporateAction, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (heap — no PK) |
| **Key Identifier** | ID (int, logical PK) |
| **Row Count** | 9 |
| **Indexes** | None (heap table) |

---

## 1. Business Meaning

### What It Is
Dictionary.TradeActivity_ExecutionTypes is a lookup table that categorizes trade executions into broad action types for trade activity reporting. It provides the high-level classification layer that groups multiple specific open/close position action types into meaningful business categories.

### Why It Exists
Trade activity reporting needs to distinguish between different *kinds* of trade execution — not just whether a position was opened or closed, but *how* and *why*. A normal user-initiated trade is fundamentally different from a corporate action adjustment, a staking reward, or an admin correction. This table provides the top-level categorization that the TradeActivity junction tables map to.

### How It Works
The `ID` serves as the logical key referenced by both `TradeActivity_ClosePositionActionTypes.ExecutionActionTypeID` and `TradeActivity_OpenPositionActionTypes.ExecutionActionTypeID`. The procedure `Trade.GetTradeActivityActionTypes` returns all three tables together, enabling the API/application layer to construct the complete mapping from specific action types to execution categories.

---

## 2. Business Logic

### Value Map (Complete — 9 rows)

| ID | ExecutionActionName | Business Meaning |
|----|---------------------|------------------|
| 0 | Undefined | Default/unknown execution type |
| 1 | Normal | Standard user-initiated trade execution (buy/sell, market/limit) |
| 2 | GuaranteedStopLoss | Position closed by guaranteed stop loss (GSL) feature |
| 3 | TransferOut | Position transferred out (e.g., CopyTrading mirror close) |
| 4 | RetroactiveExecution | Position executed retroactively (corrections, delayed fills) |
| 5 | Staking | Crypto staking reward position |
| 6 | Technical | Technical/system execution (manual adjustments, transfers) |
| 7 | CorporateAction | Corporate action event (stock splits, dividends, mergers) |
| 8 | Admin | Administrative position operation (manual BackOffice actions) |

---

## 3. Data Overview

| ID | ExecutionActionName | Scenario |
|----|---------------------|----------|
| 1 | Normal | User clicks "Buy" on Apple stock — standard execution |
| 3 | TransferOut | Copier stops copying, mirror position transferred out |
| 5 | Staking | Ethereum staking rewards credited as new position |
| 7 | CorporateAction | Tesla 3:1 stock split creates adjustment positions |
| 8 | Admin | BackOffice manually opens compensation position |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | — | HIGH | Logical primary key identifying the execution category. `0`=Undefined through `8`=Admin. Referenced by TradeActivity_ClosePositionActionTypes and TradeActivity_OpenPositionActionTypes. |
| 2 | ExecutionActionName | varchar(100) | NO | — | HIGH | PascalCase execution category label used in API responses and reporting. |

---

## 5. Relationships

### Referenced By

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| Dictionary.TradeActivity_ClosePositionActionTypes | ExecutionActionTypeID | Implicit FK → ID | Maps close actions to execution categories |
| Dictionary.TradeActivity_OpenPositionActionTypes | ExecutionActionTypeID | Implicit FK → ID | Maps open actions to execution categories |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Trade.GetTradeActivityActionTypes | SELECT | Returns all three TradeActivity tables for API |

---

## 6. Dependencies

### Depends On
None — root lookup table.

### Depended On By
- `Dictionary.TradeActivity_ClosePositionActionTypes` — maps close action types to execution categories
- `Dictionary.TradeActivity_OpenPositionActionTypes` — maps open action types to execution categories

---

## 7. Technical Details

**Note**: This table is a **heap** (no primary key or clustered index). The `ID` column serves as a logical key but is not enforced by a constraint.

---

## 8. Sample Queries

```sql
-- Get all execution types
SELECT  ID AS ExecutionTypeID,
        ExecutionActionName
FROM    Dictionary.TradeActivity_ExecutionTypes WITH (NOLOCK)
ORDER BY ID;

-- Map close action types to execution categories
SELECT  c.ClosePositionActionTypeID,
        e.ExecutionActionName
FROM    Dictionary.TradeActivity_ClosePositionActionTypes c WITH (NOLOCK)
JOIN    Dictionary.TradeActivity_ExecutionTypes e WITH (NOLOCK)
        ON c.ExecutionActionTypeID = e.ID
ORDER BY c.ClosePositionActionTypeID;

-- Find all action types classified as CorporateAction
SELECT  'Close' AS Direction, c.ClosePositionActionTypeID AS ActionTypeID
FROM    Dictionary.TradeActivity_ClosePositionActionTypes c WITH (NOLOCK)
WHERE   c.ExecutionActionTypeID = 7
UNION ALL
SELECT  'Open', o.OpenPositionActionTypeID
FROM    Dictionary.TradeActivity_OpenPositionActionTypes o WITH (NOLOCK)
WHERE   o.ExecutionActionTypeID = 7;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TradeActivity_ExecutionTypes`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.TradeActivity_ExecutionTypes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TradeActivity_ExecutionTypes.sql*
