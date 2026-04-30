# Dictionary.TradeActivity_OpenPositionActionTypes

> Maps OpenPositionActionType IDs to execution categories for trade activity open reporting.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, PK) |
| **Row Count** | 16 |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

### What It Is
Dictionary.TradeActivity_OpenPositionActionTypes is a junction/mapping table that assigns each open position action type (from `Dictionary.OpenPositionActionType`) to a higher-level execution category (from `Dictionary.TradeActivity_ExecutionTypes`). It answers: "What *kind* of execution was this open action?"

### Why It Exists
The platform has 18+ specific open position action types (manual, entry order, copy open, etc.), but for trade activity reporting, these need to be rolled up into broader categories. This mapping provides that classification for API consumers and user-facing trade history.

### How It Works
The procedure `Trade.GetTradeActivityActionTypes` returns this table alongside the execution types and close position action types. The API/application layer uses the mapping to classify each opened position's action type into its execution category.

---

## 2. Business Logic

### Mapping (16 rows — key examples)

| OpenPositionActionTypeID | → ExecutionActionTypeID | Execution Category |
|--------------------------|-------------------------|--------------------|
| 0 (Manual/Market) | 1 | Normal |
| 1 (EntryOrder) | 1 | Normal |
| 3 (CopyOpen) | 1 | Normal |
| 8, 16 | 1 | Normal |
| 11 (StakingReward) | 5 | Staking |
| 2, 6, 15 | 6 | Technical |
| 4, 5 | 7 | CorporateAction |
| 9, 10, 12, 13, 14 | 8 | Admin |

### Distribution
- 5 open actions → **Normal** (most user-initiated opens)
- 1 → **Staking** (crypto staking rewards)
- 3 → **Technical** (system/transfer positions)
- 2 → **CorporateAction** (splits, mergers)
- 5 → **Admin** (BackOffice manual operations)

---

## 3. Data Overview

N/A — this is a mapping table, not a data table. See Business Logic section for the full mapping.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | HIGH | Auto-incrementing surrogate key. |
| 2 | OpenPositionActionTypeID | int | NO | — | HIGH | References `Dictionary.OpenPositionActionType` — the specific open reason. |
| 3 | ExecutionActionTypeID | int | NO | — | HIGH | References `Dictionary.TradeActivity_ExecutionTypes` — the broad execution category. |

---

## 5. Relationships

### Depends On (Implicit)

| Referenced Table | Column | Evidence |
|-----------------|--------|----------|
| Dictionary.OpenPositionActionType | OpenPositionActionTypeID | Maps specific open reasons |
| Dictionary.TradeActivity_ExecutionTypes | ExecutionActionTypeID | Maps to execution categories |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Trade.GetTradeActivityActionTypes | SELECT | Returns full mapping for API |

---

## 6. Dependencies

### Depends On
- `Dictionary.OpenPositionActionType` — source of open action type IDs
- `Dictionary.TradeActivity_ExecutionTypes` — target execution categories

### Depended On By
- Trade activity API for open position classification

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| (unnamed PK) | CLUSTERED PK | ID ASC | IDENTITY(1,1) surrogate |

---

## 8. Sample Queries

```sql
-- Get full open action to execution mapping
SELECT  o.OpenPositionActionTypeID,
        opat.Name AS OpenActionName,
        e.ExecutionActionName
FROM    Dictionary.TradeActivity_OpenPositionActionTypes o WITH (NOLOCK)
JOIN    Dictionary.OpenPositionActionType opat WITH (NOLOCK)
        ON o.OpenPositionActionTypeID = opat.OpenPositionActionTypeID
JOIN    Dictionary.TradeActivity_ExecutionTypes e WITH (NOLOCK)
        ON o.ExecutionActionTypeID = e.ID
ORDER BY e.ExecutionActionName, opat.Name;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.TradeActivity_OpenPositionActionTypes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TradeActivity_OpenPositionActionTypes.sql*
