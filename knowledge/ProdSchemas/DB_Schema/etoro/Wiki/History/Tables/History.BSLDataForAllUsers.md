# History.BSLDataForAllUsers

> Active BSL per-customer result log recording equity state and warning classification for each customer evaluated during a BSL execution run - the primary write target for the BSL messaging system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ID, TimeMessageInserted) - composite PK CLUSTERED |
| **Partition** | Yes - EndMonth scheme, partitioned on TimeMessageInserted |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSLDataForAllUsers records the per-customer output of each Balance Stop Loss (BSL) execution run. BSL monitors all customer account equity in real time. When a customer's equity approaches or breaches a threshold (based on account balance, position exposure, or BSL configuration), the system generates a message event - and that event is recorded here.

Each row represents one BSL message event for one customer: what type of action was triggered (MessageType), how severe the equity situation is (WarningType), the complete equity breakdown (RealizedEquity, UnRealizedEquity, BonusCredit, BSLRealFunds), and the threshold breached (PercentThreshold). This data supports post-mortem audit, regulatory review of account liquidations, and customer support investigations ("why was my account closed?").

This is an **active, continuously-written** table. Trade.InsertBSLMessagesIntoQueue and Customer.SetBalance* procedures write here after processing each BSL check. The synonym `dbo.RW_BSLDataForAllUsers` points to this table on [AO-REAL-DB] (Always On secondary), enabling read-scale offloading. History.BSLDataForAllUsersPartition is a companion shard in the same series.

---

## 2. Business Logic

### 2.1 BSL Message Classification

**What**: MessageType and WarningType classify the severity and nature of the BSL action.

**Columns/Parameters Involved**: `MessageType`, `WarningType`, `PercentThreshold`

**Rules**:
- MessageType distinguishes the category: warning notification vs. forced close action vs. system event
- WarningType indicates severity level within the warning hierarchy
- PercentThreshold (nullable): the equity-to-funds percentage that was breached, when a threshold-based warning was triggered
- ExecutionID links to the specific BSL run that generated this message

### 2.2 Equity State Snapshot

**What**: The four money columns capture the complete equity breakdown at the time of the BSL check.

**Columns/Parameters Involved**: `BonusCredit`, `RealizedEquity`, `UnRealizedEquity`, `BSLRealFunds`

**Rules**:
- RealizedEquity: settled account balance (deposits minus cashouts, closed trade results)
- UnRealizedEquity: floating PnL from open positions at snapshot prices
- BonusCredit: non-withdrawable bonus portion (may inflate total equity above real funds)
- BSLRealFunds: real funds only (RealizedEquity + UnRealizedEquity, excluding bonus) - the denominator for threshold percentage calculations

**Diagram**:
```
BSL Threshold Check:
  TotalEquity  = RealizedEquity + UnRealizedEquity + BonusCredit
  BSLRealFunds = RealizedEquity + UnRealizedEquity  (no bonus)
  ThresholdPct = BSLRealFunds / InitialEquity * 100
  If ThresholdPct < PercentThreshold -> trigger WarningType message
```

---

## 3. Data Overview

Table is empty in current environment (0 rows returned). Active in production where BSL continuously processes customer accounts. Same row semantics as History.BSLDataForAllUsersPartition.

| ID | MessageType | WarningType | CID | RealizedEquity | UnRealizedEquity | PercentThreshold | TimeMessageInserted | Meaning |
|----|------------|------------|-----|---------------|-----------------|-----------------|--------------------| --------|
| (active data) | (tinyint) | (tinyint) | (int) | (money) | (money) | (numeric) | (datetime) | One BSL message event per customer per execution. Row shows the equity state at the moment of the warning/close event. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-incrementing surrogate PK. Identity seeded at 1. PK component with TimeMessageInserted. |
| 2 | MessageType | tinyint | NO | - | CODE-BACKED | Category of BSL message: distinguishes warning notifications from forced close actions. Written by Trade.InsertBSLMessagesIntoQueue which classifies BSL output by type. |
| 3 | WarningType | tinyint | NO | - | CODE-BACKED | Severity level of the equity warning. Indicates how far below threshold the customer's equity has fallen. Multiple levels allow graduated response (alert -> warning -> close). |
| 4 | CID | int | NO | - | VERIFIED | Customer ID whose account triggered this BSL message. The account being monitored. |
| 5 | BonusCredit | money | NO | - | VERIFIED | Non-withdrawable bonus money in the account at this equity snapshot. May inflate total equity above real-funds equity. Excluded from BSLRealFunds threshold calculation. |
| 6 | RealizedEquity | money | NO | - | VERIFIED | Settled account balance at this snapshot point: deposits received minus cashouts minus closed trade losses plus closed trade profits. Does not include open position PnL. |
| 7 | UnRealizedEquity | money | NO | - | VERIFIED | Floating profit/loss from all open positions at snapshot prices. Calculated from position data and price snapshots in History.BSLCurrencyPriceSnapShots for this ExecutionID. |
| 8 | BSLRealFunds | money | NO | - | VERIFIED | Real funds component of equity: RealizedEquity + UnRealizedEquity (excludes BonusCredit). Used as the numerator in the BSL threshold percentage check. If BSLRealFunds / InitialFunds < PercentThreshold, warning triggered. |
| 9 | TimeMessageInserted | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when this BSL message was recorded. Default = GETUTCDATE(). PK component and EndMonth partition key. |
| 10 | PercentThreshold | numeric(4,2) | YES | - | CODE-BACKED | The specific equity percentage threshold that was breached (e.g., 20.00 = 20%). NULL if the message was triggered by a non-threshold condition. Format: 2 decimal places (e.g., 25.00). |
| 11 | ExecutionID | bigint | YES | - | CODE-BACKED | BSL execution run that generated this message. bigint to support very high run counts. Links to Trade.ManageBSL/Trade.CheckBSL ExecutionID. NULL for legacy records where execution tracking was not yet implemented. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | History.Customer | Implicit | Customer whose equity triggered the BSL message. |
| ExecutionID | Trade.ManageBSL | Implicit | BSL execution cycle that produced this message. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertBSLMessagesIntoQueue | CID, MessageType | Writer | Inserts BSL message results after processing. Primary writer. |
| Customer.PostMIMOOperations | CID | Writer | Writes BSL data after MIMO credit operations. |
| Customer.SetBalance* | CID | Writer | Various SetBalance procedures write BSL data on balance changes. |
| dbo.RW_BSLDataForAllUsers | (synonym) | Linked Server | Synonym pointing to this table on AO-REAL-DB secondary. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSLDataForAllUsers (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertBSLMessagesIntoQueue | Stored Procedure | Writer - BSL message recording |
| Customer.PostMIMOOperations | Stored Procedure | Writer - MIMO operation BSL data |
| Customer.SetBalance (and variants) | Stored Procedure | Writer - balance change BSL recording |
| dbo.RW_BSLDataForAllUsers | Synonym | Linked server alias for AO secondary access |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLDataForAllUsersNEW | CLUSTERED PK | ID ASC, TimeMessageInserted ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLDataForAllUsersNEW | PRIMARY KEY CLUSTERED | (ID, TimeMessageInserted), FILLFACTOR=95 |
| DF_HistoryBSLDataForAllUsersNEW | DEFAULT | TimeMessageInserted = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Get BSL message history for a customer
```sql
SELECT
    b.ID,
    b.MessageType,
    b.WarningType,
    b.RealizedEquity,
    b.UnRealizedEquity,
    b.BonusCredit,
    b.BSLRealFunds,
    b.PercentThreshold,
    b.ExecutionID,
    b.TimeMessageInserted
FROM History.BSLDataForAllUsers b WITH (NOLOCK)
WHERE b.CID = 12345678
ORDER BY b.TimeMessageInserted DESC;
```

### 8.2 Find all customers who breached a threshold below 25% in the past 7 days
```sql
SELECT b.CID, b.WarningType, b.BSLRealFunds, b.PercentThreshold, b.TimeMessageInserted
FROM History.BSLDataForAllUsers b WITH (NOLOCK)
WHERE b.PercentThreshold < 25.00
  AND b.TimeMessageInserted >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY b.PercentThreshold ASC, b.TimeMessageInserted DESC;
```

### 8.3 Get equity breakdown for all customers in a specific BSL execution
```sql
SELECT b.CID, b.MessageType, b.WarningType,
       b.RealizedEquity, b.UnRealizedEquity, b.BonusCredit, b.BSLRealFunds,
       b.PercentThreshold
FROM History.BSLDataForAllUsers b WITH (NOLOCK)
WHERE b.ExecutionID = 98765
ORDER BY b.BSLRealFunds ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.1/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSLDataForAllUsers | Type: Table | Source: etoro/etoro/History/Tables/History.BSLDataForAllUsers.sql*
