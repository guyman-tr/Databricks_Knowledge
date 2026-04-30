# Dictionary.OrdersExitOpenActionType

> Lookup table defining the 7 triggers for exit-open orders — including manual intervention, mirror unregister, BackOffice override, liquidation scenarios, redemption, and batch close operations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ActionTypeID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.OrdersExitOpenActionType classifies the triggers that initiate exit-open orders. Exit-open orders are a special order type where the system opens a new close-order against an existing position — typically as part of CopyTrading operations, liquidation cascades, or batch position closures.

This table exists because exit-open orders originate from fundamentally different business scenarios, and the trigger type determines the priority, settlement rules, and audit classification of the resulting close operation.

The ActionTypeID is referenced by Trade.GetLivePositionWithPartialCloseData when displaying partial close information, connecting exit-open order triggers to the position lifecycle reporting.

---

## 2. Business Logic

### 2.1 Exit-Open Trigger Classification

**What**: Seven distinct triggers can create exit-open orders, each with different business context and priority.

**Columns/Parameters Involved**: `ActionTypeID`, `ActionName`

**Rules**:
- **Manual (0)** — A BackOffice operator or system manually created the exit-open order.
- **OpenByUnregisterMirror (1)** — Created when a CopyTrading mirror relationship is terminated. The copied positions need exit-open orders to close them.
- **OpenByBackOffice (2)** — BackOffice explicitly created a close order against a position.
- **ManualLiquidation (3)** — An operator manually initiated account liquidation, generating exit-open orders for the positions being liquidated.
- **BSLLiquidation (4)** — The Balance Stop Loss (BSL) system automatically triggered liquidation, generating exit-open orders for affected positions.
- **ExitOrderForRedeem (5)** — A CopyTrading redemption operation triggered exit-open orders to close the copied positions.
- **ExitOrderForCloseMultiplePositions (6)** — A batch close operation generated exit-open orders for multiple positions simultaneously.

**Diagram**:
```
Exit-Open Order Triggers
├── Manual/BO
│   ├── 0 = Manual
│   └── 2 = OpenByBackOffice
├── CopyTrading
│   ├── 1 = OpenByUnregisterMirror
│   └── 5 = ExitOrderForRedeem
├── Liquidation
│   ├── 3 = ManualLiquidation
│   └── 4 = BSLLiquidation (automatic)
└── Batch
    └── 6 = ExitOrderForCloseMultiplePositions
```

---

## 3. Data Overview

| ActionTypeID | ActionName | Meaning |
|---|---|---|
| 0 | Manual | Exit-open order created manually by operator or system. Used for ad-hoc position closures outside normal flows. |
| 1 | OpenByUnregisterMirror | CopyTrading mirror relationship ended — the platform creates exit-open orders to close all copied positions from the terminated relationship. |
| 4 | BSLLiquidation | The Balance Stop Loss protection system detected equity below threshold and automatically generated exit-open orders to liquidate positions and prevent further losses. |
| 5 | ExitOrderForRedeem | A CopyTrading investor redeemed (withdrew from) a copy relationship, triggering exit-open orders to close the proportional share of copied positions. |
| 6 | ExitOrderForCloseMultiplePositions | A batch close operation (e.g., "close all positions" on an instrument) generated exit-open orders for multiple positions at once. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionTypeID | int | NO | - | VERIFIED | Primary key identifying the exit-open trigger type. 0=Manual, 1=OpenByUnregisterMirror, 2=OpenByBackOffice, 3=ManualLiquidation, 4=BSLLiquidation, 5=ExitOrderForRedeem, 6=ExitOrderForCloseMultiplePositions. Referenced by Trade.GetLivePositionWithPartialCloseData. |
| 2 | ActionName | varchar(35) | NO | - | VERIFIED | Human-readable label for the trigger. Displayed in position lifecycle and partial close reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetLivePositionWithPartialCloseData | ActionTypeID | Lookup | Joins to display exit-open action type in partial close reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLivePositionWithPartialCloseData | Stored Procedure | Reader — joins for display in partial close data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryOrdersExitOpenActionType | CLUSTERED PK | ActionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryOrdersExitOpenActionType | PRIMARY KEY | Unique exit-open action type identifier |

---

## 8. Sample Queries

### 8.1 List all exit-open action types
```sql
SELECT  ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersExitOpenActionType] WITH (NOLOCK)
ORDER BY ActionTypeID;
```

### 8.2 Find CopyTrading-related triggers
```sql
SELECT  ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersExitOpenActionType] WITH (NOLOCK)
WHERE   ActionName LIKE '%Mirror%' OR ActionName LIKE '%Redeem%'
ORDER BY ActionTypeID;
```

### 8.3 Find liquidation triggers
```sql
SELECT  ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersExitOpenActionType] WITH (NOLOCK)
WHERE   ActionName LIKE '%Liquidation%'
ORDER BY ActionTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrdersExitOpenActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrdersExitOpenActionType.sql*
