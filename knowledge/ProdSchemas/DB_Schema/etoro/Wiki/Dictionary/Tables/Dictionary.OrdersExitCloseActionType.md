# Dictionary.OrdersExitCloseActionType

> Lookup table defining the 8 ways an exit-close order can be resolved — manual closure, execution success/failure, parent position close, retry exhaustion, redemption, account liquidation, or mirror unregister.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ActionTypeID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.OrdersExitCloseActionType classifies the resolution outcomes for exit-close orders. Exit-close orders are orders to close (fully or partially) an existing position — such as stop-loss triggers, take-profit triggers, manual close requests, or system-initiated closures.

This table exists because exit-close orders can terminate through multiple pathways with different business implications. A successful execution closes the position as intended, while failures and cancellations require different follow-up actions. Partial closures from account liquidation or CopyTrading mirror unregister represent special cases with specific settlement requirements.

The 8 action types cover manual intervention, successful execution, transient and permanent execution failures, parent position cascade closure, CopyTrading redemption, account liquidation, and mirror relationship termination.

---

## 2. Business Logic

### 2.1 Exit-Close Resolution Pathways

**What**: Exit-close orders terminate through 8 distinct outcomes covering success, failure, and various system-initiated cancellations.

**Columns/Parameters Involved**: `ActionTypeID`, `ActionName`

**Rules**:
- **Manual (0)** — Closed by a BackOffice operator or system admin.
- **CloseByExecution (1)** — Successfully executed — the exit-close order filled and the position was closed/reduced.
- **CloseByExecutionFail (2)** — Execution attempted but failed (transient). System may retry.
- **CloseByPositionClose (3)** — The parent position was closed through another mechanism, making this exit-close order irrelevant.
- **CloseByExecutionFailDueToMaxRetries (4)** — Execution failed permanently after exhausting retry attempts.
- **CloseByRedeem (5)** — Closed due to a CopyTrading redemption operation (investor withdrawing from a copy relationship).
- **ClosePartialByAccountLiquidation (6)** — Partially closed as part of account liquidation. The system reduces positions to meet margin requirements.
- **ClosePartialByMirrorUnregister (7)** — Partially closed because the CopyTrading mirror relationship was terminated.

**Diagram**:
```
Exit-Close Order Outcomes
├── Success
│   └── 1 = CloseByExecution (filled)
├── Failures
│   ├── 2 = CloseByExecutionFail (transient)
│   └── 4 = CloseByExecutionFailDueToMaxRetries (permanent)
├── Cascade/System
│   ├── 0 = Manual (BO intervention)
│   ├── 3 = CloseByPositionClose (parent closed)
│   ├── 5 = CloseByRedeem (CopyTrading redemption)
│   ├── 6 = ClosePartialByAccountLiquidation
│   └── 7 = ClosePartialByMirrorUnregister
```

---

## 3. Data Overview

| ActionTypeID | ActionName | Meaning |
|---|---|---|
| 0 | Manual | Exit-close order manually closed by BackOffice or system admin. Used for error correction, compliance actions, or operational overrides. |
| 1 | CloseByExecution | The exit-close order executed successfully — the position was closed or reduced as intended. The standard happy-path outcome. |
| 3 | CloseByPositionClose | The parent position was already closed through a different path, making this exit-close order moot. Automatically cancelled. |
| 5 | CloseByRedeem | Triggered by a CopyTrading redemption — an investor stopped copying a trader, forcing closure of the copied positions via exit-close orders. |
| 6 | ClosePartialByAccountLiquidation | The account hit a margin call or BSL threshold, triggering partial position closure. The exit-close order was created as part of the liquidation cascade. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionTypeID | int | NO | - | CODE-BACKED | Primary key identifying the exit-close action type. 0=Manual, 1=CloseByExecution, 2=CloseByExecutionFail, 3=CloseByPositionClose, 4=CloseByExecutionFailDueToMaxRetries, 5=CloseByRedeem, 6=ClosePartialByAccountLiquidation, 7=ClosePartialByMirrorUnregister. |
| 2 | ActionName | varchar(35) | NO | - | CODE-BACKED | Human-readable label for the exit-close action. Displayed in position lifecycle reports and execution audit trails. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK consumers found in the SSDT codebase. Used by the exit order execution pipeline at the application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryOrdersExitCloseActionType | CLUSTERED PK | ActionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryOrdersExitCloseActionType | PRIMARY KEY | Unique exit-close action type identifier |

---

## 8. Sample Queries

### 8.1 List all exit-close action types
```sql
SELECT  ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersExitCloseActionType] WITH (NOLOCK)
ORDER BY ActionTypeID;
```

### 8.2 Find all partial-close actions
```sql
SELECT  ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersExitCloseActionType] WITH (NOLOCK)
WHERE   ActionName LIKE 'ClosePartial%'
ORDER BY ActionTypeID;
```

### 8.3 Group by success vs failure vs cancellation
```sql
SELECT  CASE WHEN ActionTypeID = 1 THEN 'Success'
             WHEN ActionTypeID IN (2, 4) THEN 'Failure'
             ELSE 'System/Manual'
        END AS Category,
        ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersExitCloseActionType] WITH (NOLOCK)
ORDER BY ActionTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrdersExitCloseActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrdersExitCloseActionType.sql*
