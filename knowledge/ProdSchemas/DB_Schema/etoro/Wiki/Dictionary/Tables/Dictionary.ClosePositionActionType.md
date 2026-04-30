# Dictionary.ClosePositionActionType

> Lookup table defining the 27 triggers/reasons for closing a trading position — used for attribution, analytics, and fee routing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ClosePositionActionType defines every possible trigger or reason that can cause a trading position to close on the eToro platform. Whether a user manually closes, a stop-loss fires, a CopyTrading leader exits, or the operations team liquidates — each scenario has a distinct action type that is permanently recorded with the closed position.

This table is critical for trading analytics, PnL attribution, and regulatory reporting. Knowing WHY a position was closed determines whether the closure was user-initiated (voluntary) or system-initiated (forced), which affects fee calculations, complaint resolution, and compliance audit trails. CopyTrading closures (hierarchical, alignment, copy stop-loss) are particularly important for understanding cascade effects.

The close action type is written to Trade.PositionTbl (or its history equivalent) when a position closes. It is read by reporting procedures, DWH exports, and account statement generation to classify closures. The value is immutable once set — it represents the original trigger event.

---

## 2. Business Logic

### 2.1 Closure Trigger Categories

**What**: Close actions group into categories by who/what initiated the closure.

**Columns/Parameters Involved**: `ID`, `ClosePositionActionName`

**Rules**:
- **User-initiated** (0=Customer, 12=Close All, 14=Mirror manual close, 17=Manual Unregister): User consciously chose to close
- **System-automated** (1/3=Stop Loss, 5/6=Take Profit, 16=BSL, 2=End of Week, 26=Expiry): Triggered by price or time conditions
- **CopyTrading** (9=Hierarchical, 10=Recovery, 13=Copy SL, 14=Mirror manual, 17/18=Unregister, 23=Alignment): Related to copy relationship lifecycle
- **Operations** (8=BackOffice, 15=Manual Liquidation, 18=BO Unregister, 20=Adjustment, 21=Orphaned): Internal operational actions
- **Business events** (7=Contract Rollover, 19=Redeem, 22=Transferred Out, 24=Delist, 25=Close by rate): Driven by external business events

**Diagram**:
```
Close Position Triggers:
├── User-Initiated
│   ├── 0: Customer (manual close)
│   ├── 12: Close All
│   ├── 14: Mirror manual close
│   └── 17: Manual Unregister
├── System-Automated
│   ├── 1/3: Stop Loss
│   ├── 5/6: Take Profit
│   ├── 16: BSL (gap protection)
│   ├── 2: End of Week
│   └── 26: Expiry
├── CopyTrading
│   ├── 9: Hierarchical Close (leader closed)
│   ├── 13: Copy Stop Loss
│   └── 23: Alignment
├── Operations
│   ├── 8: BackOffice User
│   ├── 15: Manual Liquidation
│   └── 20: Adjustment
└── Business Events
    ├── 7: Contract Rollover
    ├── 19: Redeem
    ├── 22: Transferred Out
    └── 24: Delist
```

---

## 3. Data Overview

| ID | ClosePositionActionName | Meaning |
|---|---|---|
| 0 | Customer | User manually clicked "Close" on a specific position. The most common closure type for self-directed traders. Full PnL attribution to user decision. |
| 1 | Stop Loss | Position hit the user-configured stop-loss price level. System automatically closed to limit losses. May trigger during market gaps where actual close price differs from SL price. |
| 9 | Hierarchical Close | CopyTrading cascade: the copied trader (leader) closed their position, so all copiers' mirrored positions close automatically. The copier did not choose this — it was driven by the leader's action. |
| 16 | BSL | Below Stop Loss — system protection close when the market price gaps through the stop-loss level (e.g., overnight gap). Close price may be significantly worse than SL price. |
| 19 | Redeem | Position closed to free cash for a CopyTrading withdrawal (redeem). Not the user's trading decision — driven by their request to withdraw funds from a copy relationship. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the closure trigger. 0=Customer, 1=Stop Loss, 2=End of Week, 3=SL via trade server, 4=Return to Market, 5=Take Profit, 6=TP via trade server, 7=Contract Rollover, 8=BackOffice, 9=Hierarchical Close, 10=Hierarchical recovery, 11=Join Demo Challenge, 12=Close All, 13=Copy Stop Loss, 14=Mirror manual close, 15=Manual Liquidation, 16=BSL, 17=Manual Unregister, 18=BO Unregister, 19=Redeem, 20=Operational adjustment, 21=Orphaned, 22=Transferred Out, 23=Alignment, 24=Delist, 25=Close by rate, 26=Expiry. Stored with every closed position for permanent attribution. See [Close Position Action Type](_glossary.md#close-position-action-type). (Dictionary.ClosePositionActionType) |
| 2 | ClosePositionActionName | varchar(50) | NO | - | VERIFIED | Human-readable label for the closure trigger. Used in account statements, trading reports, and back-office displays. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionTbl | ClosePositionActionTypeID | Implicit Lookup | Records the closure trigger for every closed position |
| History position tables | ClosePositionActionTypeID | Implicit Lookup | Historical position records reference closure type |
| Account statement procedures | ClosePositionActionTypeID | Read | Account statements display human-readable closure reason |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Stores ClosePositionActionTypeID per closed position |
| Account statement procedures | Stored Procedure | Display closure reason in reports |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClosePositionActionType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ClosePositionActionType | PRIMARY KEY | Unique close action type identifier |

---

## 8. Sample Queries

### 8.1 List all close action types
```sql
SELECT  ID,
        ClosePositionActionName
FROM    [Dictionary].[ClosePositionActionType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count closed positions by closure reason
```sql
SELECT  cpat.ClosePositionActionName,
        COUNT(*) AS ClosureCount
FROM    [Trade].[PositionTbl] tp WITH (NOLOCK)
JOIN    [Dictionary].[ClosePositionActionType] cpat WITH (NOLOCK)
        ON tp.ClosePositionActionTypeID = cpat.ID
WHERE   tp.IsClosed = 1
GROUP BY cpat.ClosePositionActionName
ORDER BY ClosureCount DESC;
```

### 8.3 Find CopyTrading-triggered closures for a customer
```sql
SELECT  tp.PositionID,
        tp.CurrencyID,
        cpat.ClosePositionActionName,
        tp.ClosingDateTime,
        tp.PnL
FROM    [Trade].[PositionTbl] tp WITH (NOLOCK)
JOIN    [Dictionary].[ClosePositionActionType] cpat WITH (NOLOCK)
        ON tp.ClosePositionActionTypeID = cpat.ID
WHERE   tp.CID = @CID
        AND tp.IsClosed = 1
        AND tp.ClosePositionActionTypeID IN (9, 10, 13, 14, 17, 18, 23)
ORDER BY tp.ClosingDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.ClosePositionActionType.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ClosePositionActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ClosePositionActionType.sql*
