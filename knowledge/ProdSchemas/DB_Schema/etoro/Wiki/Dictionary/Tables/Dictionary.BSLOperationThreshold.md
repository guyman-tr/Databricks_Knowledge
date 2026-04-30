# Dictionary.BSLOperationThreshold

> Configuration table defining the 4 equity percentage thresholds that trigger BSL (Balance Stop-Loss) actions — two warning levels, a liquidation trigger, and an unblock recovery threshold.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.BSLOperationThreshold stores the equity percentage thresholds that drive the BSL (Balance Stop-Loss) margin protection system. When a customer's equity-to-invested ratio drops below these configurable percentages, the system triggers the corresponding action: first warning, second warning, forced liquidation, or account unblock upon recovery.

This is the configuration backbone of the margin call system. The `Trade.InsertBSLMessagesIntoQueue` procedure reads all threshold values from this table at execution start to determine which customers need warnings or liquidation. The `Trade.GetMaxAmountToWithdraw` procedure reads the liquidation threshold (ID=1) to calculate the maximum safe withdrawal amount that won't trigger forced liquidation. The `Trade.SendUnBlockMessage` procedure reads the unblock threshold (ID=4) to identify accounts eligible for unblocking after equity recovery.

Changing values in this table directly affects when customers receive margin warnings and when their positions are forcibly closed. This is a high-impact configuration table controlled by the risk management team.

---

## 2. Business Logic

### 2.1 Tiered Equity Protection Thresholds

**What**: Four configurable equity thresholds that define the BSL protection cascade.

**Columns/Parameters Involved**: `ID`, `MessageTypeID`, `Name`, `ValueInPercent`

**Rules**:
- **Liquidation (ID=1, 5%)**: When equity drops to 5% of invested amount, all positions are forcibly closed. Links to MessageTypeID=2 (Liquidation message type). This is the last resort to prevent negative balances.
- **First Alert (ID=2, 20%)**: First warning sent when equity drops to 20%. Links to MessageTypeID=1 (Warning message type). Customer is urged to add funds.
- **Second Alert (ID=3, 10%)**: Escalated warning at 10% equity. Links to MessageTypeID=1 (Warning message type). More urgent notification before liquidation.
- **Unblock (ID=4, 25%)**: When equity recovers to 25%, restricted accounts are automatically unblocked. Links to MessageTypeID=3 (Unblock message type). Allows customer to resume normal trading.

**Diagram**:
```
Equity % ──────────────────────────── BSL Action
  100%   Normal trading
   25%   ← ID=4: Unblock threshold (recovery)
   20%   ← ID=2: First Alert (warning)
   10%   ← ID=3: Second Alert (escalated warning)
    5%   ← ID=1: Liquidation (forced close)
    0%   Account depleted

Threshold → MessageTypeID → Dictionary.BSLMessageTypes
  ID=1 (Liquidation 5%)    → MessageTypeID=2
  ID=2 (First Alert 20%)   → MessageTypeID=1
  ID=3 (Second Alert 10%)  → MessageTypeID=1
  ID=4 (Unblock 25%)       → MessageTypeID=3
```

---

## 3. Data Overview

| ID | MessageTypeID | Name | ValueInPercent | Meaning |
|---|---|---|---|---|
| 1 | 2 | Liquidation | 5.00 | When equity falls to 5%, the system forcibly liquidates all customer positions. Read by `Trade.InsertBSLMessagesIntoQueue` as @PercentForBlocking and by `Trade.GetMaxAmountToWithdraw` to cap withdrawal amounts. |
| 2 | 1 | First alert | 20.00 | First warning threshold — customer notified at 20% equity to deposit more funds. Read by `Trade.InsertBSLMessagesIntoQueue` as @PercentForAlert1. |
| 3 | 1 | Second Alert | 10.00 | Escalated warning at 10% equity — stronger urgency before liquidation. Read by `Trade.InsertBSLMessagesIntoQueue` as @PercentForAlert2. |
| 4 | 3 | Unblock | 25.00 | Recovery threshold — accounts restricted during low equity are unblocked when equity returns to 25%. Read by `Trade.SendUnBlockMessage` as @UnBlockPercent. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the threshold row. Values 1-4. Referenced by procedures using hardcoded IDs (e.g., `WHERE ID = 1` for liquidation, `WHERE ID = 4` for unblock). |
| 2 | MessageTypeID | int | NO | - | VERIFIED | FK (implicit) to `Dictionary.BSLMessageTypes.ID`. Determines which type of BSL message is generated when this threshold is crossed: 1=Warning, 2=Liquidation, 3=Unblock. Multiple thresholds can map to the same message type (both alerts map to MessageTypeID=1). |
| 3 | Name | varchar(30) | NO | - | VERIFIED | Human-readable label for the threshold (e.g., 'Liquidation', 'First alert', 'Second Alert', 'Unblock'). Used in dashboards and configuration UIs. |
| 4 | ValueInPercent | numeric(4,2) | NO | - | VERIFIED | The equity percentage that triggers this action. Read directly by trading procedures: `Trade.InsertBSLMessagesIntoQueue` reads all 4 values using `SUM(IIF(ID = N, ValueInPercent, 0))`, while `Trade.GetMaxAmountToWithdraw` reads the liquidation threshold and divides by 100 for ratio calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MessageTypeID | Dictionary.BSLMessageTypes | Implicit FK | Links each threshold to the BSL message type it generates — determines whether a warning, liquidation, or unblock message is queued |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertBSLMessagesIntoQueue | Direct read | Procedure | Reads all 4 threshold percentages at start of BSL batch processing to classify customers by equity level |
| Trade.GetMaxAmountToWithdraw | WHERE ID = 1 | Procedure | Reads liquidation threshold (5%) to calculate maximum safe withdrawal that won't trigger forced position closing |
| Trade.SendUnBlockMessage | WHERE ID = 4 | Procedure | Reads unblock threshold (25%) to identify accounts eligible for unblocking after equity recovery |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertBSLMessagesIntoQueue | Procedure | Reads all threshold values to drive BSL batch processing |
| Trade.GetMaxAmountToWithdraw | Procedure | Reads liquidation threshold for withdrawal cap calculation |
| Trade.SendUnBlockMessage | Procedure | Reads unblock threshold for account recovery |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryBSLOperationThreshold | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all BSL thresholds with message types
```sql
SELECT  BOT.ID,
        BOT.Name,
        BOT.ValueInPercent,
        BMT.MessageTypeDecstiption AS MessageType
FROM    Dictionary.BSLOperationThreshold BOT WITH (NOLOCK)
INNER JOIN Dictionary.BSLMessageTypes BMT WITH (NOLOCK)
        ON BMT.ID = BOT.MessageTypeID
ORDER BY BOT.ValueInPercent DESC;
```

### 8.2 Get liquidation threshold as a ratio
```sql
SELECT  ValueInPercent / 100.0 AS LiquidationRatio
FROM    Dictionary.BSLOperationThreshold WITH (NOLOCK)
WHERE   ID = 1;
```

### 8.3 Show threshold cascade from highest to lowest
```sql
SELECT  Name,
        ValueInPercent,
        CASE MessageTypeID
            WHEN 1 THEN 'Warning'
            WHEN 2 THEN 'Liquidation'
            WHEN 3 THEN 'Unblock'
        END AS ActionType
FROM    Dictionary.BSLOperationThreshold WITH (NOLOCK)
ORDER BY ValueInPercent DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.BSLOperationThreshold | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BSLOperationThreshold.sql*
