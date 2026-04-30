# Trade.BSLQueue

> Transient message queue for BSL (Bonus Stop Loss) margin call actions - holds pending liquidation and warning messages for customers whose equity has breached thresholds.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + 1 NC - IX_ID is redundant with PK) |

---

## 1. Business Meaning

This table is a **transient message queue** for BSL (Bonus Stop Loss) operations. When the BSL check runs (`Trade.InsertBSLMessagesIntoQueue`), it evaluates all customers' unrealized PnL against their equity and bonus credit. Customers who breach warning or liquidation thresholds get a row inserted here with their financial snapshot and the action to take.

The queue is consumed by downstream BSL processors (`Trade.SendMessagesToBSL`, `Trade.AcknowledgeMessagesBSL`) that send warning notifications or initiate account liquidation. Once processed, rows are acknowledged and removed. The table is normally empty between BSL execution cycles.

Data flows in from `Trade.InsertBSLMessagesIntoQueue` via the `RW_BSLQueue` synonym (which routes to this table on the primary). The procedure calculates unrealized PnL for each customer's open positions, compares against thresholds from `Dictionary.BSLOperationThreshold`, and queues actions for customers in breach. Messages are of type 1 (warning) or 2 (liquidation).

---

## 2. Business Logic

### 2.1 BSL Threshold Evaluation

**What**: Customer equity is checked against configurable percentage thresholds to determine if a warning or liquidation is needed.

**Columns/Parameters Involved**: `MessageType`, `PercentThreshold`, `BonusCredit`, `RealizedEquity`, `UnRealizedEquity`, `BSLRealFunds`

**Rules**:
- Thresholds loaded from Dictionary.BSLOperationThreshold: ID=1 (liquidation %), ID=2 (alert level 1 %), ID=3 (alert level 2 %)
- MessageType 1 = Warning: equity dropped below alert threshold but above liquidation
- MessageType 2 = Liquidation: equity dropped below liquidation threshold, all positions must be closed
- Formula: `(UnRealizedPnL + RealizedEquity - BonusCredit) <= BSLRealFunds / 100 * ThresholdPercent`
- If BSLRealFunds <= 0 or total equity <= 0, immediate liquidation (MessageType 2)

**Diagram**:
```
Customer Equity Assessment:
                                          
[Equity OK]     [Alert Zone]     [Liquidation Zone]
    |                |                   |
    |   <= Alert%    |  <= Liquidate%    |
    +-------->-------+-------->----------+
                     |                   |
              MessageType=1       MessageType=2
              (Warning sent)      (Positions closed)
```

---

## 3. Data Overview

Table is empty (0 rows) - this is normal between BSL execution cycles. The queue is populated during each BSL run and emptied after processing.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key, sourced from Trade.ManageBSL.ID during the BSL execution cycle. Links this queue entry back to the ManageBSL audit record. |
| 2 | MessageType | tinyint | NO | - | VERIFIED | Action type: 1=Warning (send margin call alert to customer), 2=Liquidation (close all positions to prevent further losses). Derived from BSL threshold calculation in InsertBSLMessagesIntoQueue. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer identifier whose equity breached the threshold. Implicit FK to Customer.CustomerStatic. |
| 4 | BonusCredit | money | NO | - | CODE-BACKED | Customer's bonus credit balance at the time of the BSL check. Subtracted from equity in the threshold formula. |
| 5 | RealizedEquity | money | NO | - | CODE-BACKED | Customer's realized equity (cash balance from closed positions) at the time of the BSL check. |
| 6 | UnRealizedEquity | money | NO | - | CODE-BACKED | Customer's unrealized equity (open position PnL + realized equity) at the time of the BSL check. This is the snapshot value used for the threshold decision. |
| 7 | BSLRealFunds | money | NO | - | CODE-BACKED | Customer's real funds (deposits minus withdrawals, excluding bonuses). The base amount against which threshold percentages are applied. |
| 8 | PercentThreshold | numeric(4,2) | YES | - | CODE-BACKED | The specific threshold percentage that was breached. Set to the liquidation, alert1, or alert2 percentage from Dictionary.BSLOperationThreshold depending on the MessageType/WarningType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Customer being warned or liquidated |
| ID | Trade.ManageBSL | Implicit FK | Links to the BSL audit/management record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertBSLMessagesIntoQueue | - | WRITER | Populates queue with customers breaching thresholds |
| Trade.SendMessagesToBSL | - | READER | Reads queue to process pending messages |
| Trade.AcknowledgeMessagesBSL | - | MODIFIER/DELETER | Acknowledges processed messages |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertBSLMessagesIntoQueue | Stored Procedure | WRITER - inserts via RW_BSLQueue synonym |
| Trade.SendMessagesToBSL | Stored Procedure | READER - processes pending messages |
| Trade.AcknowledgeMessagesBSL | Stored Procedure | MODIFIER - marks messages as processed |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BSLQueue | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=95) |
| IX_ID | NC | ID ASC | - | - | Active (redundant with PK) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check current BSL queue for pending actions
```sql
SELECT  bq.ID,
        bq.MessageType,
        CASE bq.MessageType WHEN 1 THEN 'Warning' WHEN 2 THEN 'Liquidation' END AS ActionType,
        bq.CID,
        bq.RealizedEquity,
        bq.UnRealizedEquity,
        bq.BonusCredit,
        bq.BSLRealFunds,
        bq.PercentThreshold
FROM    Trade.BSLQueue bq WITH (NOLOCK)
ORDER BY bq.MessageType DESC, bq.CID
```

### 8.2 Identify customers pending liquidation
```sql
SELECT  bq.CID,
        bq.BSLRealFunds,
        bq.RealizedEquity,
        bq.UnRealizedEquity,
        bq.BonusCredit,
        (bq.UnRealizedEquity - bq.BonusCredit) AS NetEquity
FROM    Trade.BSLQueue bq WITH (NOLOCK)
WHERE   bq.MessageType = 2
```

### 8.3 Queue summary by action type
```sql
SELECT  MessageType,
        CASE MessageType WHEN 1 THEN 'Warning' WHEN 2 THEN 'Liquidation' END AS ActionType,
        COUNT(*) AS CustomerCount,
        SUM(BSLRealFunds) AS TotalRealFunds
FROM    Trade.BSLQueue WITH (NOLOCK)
GROUP BY MessageType
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| AI Generated: BSL (Bonus Stop Loss) Service Design Overview and Technical Details | Confluence | BSL system architecture and threshold-based warning/liquidation flow |

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BSLQueue | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.BSLQueue.sql*
