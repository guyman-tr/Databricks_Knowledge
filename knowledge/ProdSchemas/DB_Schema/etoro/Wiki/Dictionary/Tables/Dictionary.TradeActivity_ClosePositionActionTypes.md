# Dictionary.TradeActivity_ClosePositionActionTypes

> Maps ClosePositionActionType IDs to execution categories for trade activity close reporting.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, PK) |
| **Row Count** | 21 |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

### What It Is
Dictionary.TradeActivity_ClosePositionActionTypes is a junction/mapping table that assigns each close position action type (from `Dictionary.ClosePositionActionType`) to a higher-level execution category (from `Dictionary.TradeActivity_ExecutionTypes`). It answers: "What *kind* of execution was this close action?"

### Why It Exists
The platform has 27+ specific close position action types (SL hit, TP hit, manual close, BSL liquidation, etc.), but for trade activity reporting, these need to be rolled up into broader categories (Normal, TransferOut, Technical, CorporateAction, RetroactiveExecution). This mapping table provides that roll-up.

### How It Works
The procedure `Trade.GetTradeActivityActionTypes` returns this table alongside the execution types and open position action types. The API/application layer uses the mapping to classify each closed position's action type into its execution category for user-facing trade activity reports.

---

## 2. Business Logic

### Mapping (21 rows — key examples)

| ClosePositionActionTypeID | → ExecutionActionTypeID | Execution Category |
|---------------------------|-------------------------|--------------------|
| 0 (Manual) | 1 | Normal |
| 1 (StopLoss) | 1 | Normal |
| 3 (TakeProfit) | 1 | Normal |
| 5, 6, 7 | 1 | Normal |
| 19 (MirrorTransferOut) | 3 | TransferOut |
| 22 (FundTransferOut) | 3 | TransferOut |
| 20 (TechnicalClose) | 6 | Technical |
| 24 (CorporateAction) | 7 | CorporateAction |
| 25 (RetroactiveClose) | 4 | RetroactiveExecution |

### Distribution
- 16 of 21 close actions map to **Normal** (ID 1) — most closes are standard executions
- 2 map to **TransferOut** (ID 3) — CopyTrading/fund transfers
- 1 maps to **Technical** (ID 6), **CorporateAction** (ID 7), and **RetroactiveExecution** (ID 4) each

---

## 3. Data Overview

N/A — this is a mapping table, not a data table. See Business Logic section for the full mapping.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | HIGH | Auto-incrementing surrogate key. |
| 2 | ClosePositionActionTypeID | int | NO | — | HIGH | References `Dictionary.ClosePositionActionType` — the specific close reason (SL, TP, manual, etc.). |
| 3 | ExecutionActionTypeID | int | NO | — | HIGH | References `Dictionary.TradeActivity_ExecutionTypes` — the broad execution category (Normal, TransferOut, Technical, etc.). |

---

## 5. Relationships

### Depends On (Implicit)

| Referenced Table | Column | Evidence |
|-----------------|--------|----------|
| Dictionary.ClosePositionActionType | ClosePositionActionTypeID | Maps specific close reasons |
| Dictionary.TradeActivity_ExecutionTypes | ExecutionActionTypeID | Maps to execution categories |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Trade.GetTradeActivityActionTypes | SELECT | Returns full mapping for API |

---

## 6. Dependencies

### Depends On
- `Dictionary.ClosePositionActionType` — source of close action type IDs
- `Dictionary.TradeActivity_ExecutionTypes` — target execution categories

### Depended On By
- Trade activity API for close position classification

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| (unnamed PK) | CLUSTERED PK | ID ASC | IDENTITY(1,1) surrogate |

---

## 8. Sample Queries

```sql
-- Get full close action to execution mapping
SELECT  c.ClosePositionActionTypeID,
        cpat.Name AS CloseActionName,
        e.ExecutionActionName
FROM    Dictionary.TradeActivity_ClosePositionActionTypes c WITH (NOLOCK)
JOIN    Dictionary.ClosePositionActionType cpat WITH (NOLOCK)
        ON c.ClosePositionActionTypeID = cpat.ClosePositionActionTypeID
JOIN    Dictionary.TradeActivity_ExecutionTypes e WITH (NOLOCK)
        ON c.ExecutionActionTypeID = e.ID
ORDER BY e.ExecutionActionName, cpat.Name;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.TradeActivity_ClosePositionActionTypes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TradeActivity_ClosePositionActionTypes.sql*
