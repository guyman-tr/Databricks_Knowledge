# History.BSLDataForAllUsersPartition

> Balance Stop Loss per-user result log capturing the equity state and warning classification for each customer evaluated during a BSL execution run.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ID, TimeMessageInserted) - composite PK CLUSTERED |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSLDataForAllUsersPartition records the per-customer output of each Balance Stop Loss (BSL) execution run. BSL monitors all customers' account equity in real time and sends messages (warnings, close notifications) when equity falls below configured thresholds. This table captures the message type, warning level, and equity snapshot for each customer processed in each BSL run.

Each row represents one BSL message event for one customer in one execution cycle: it tells what type of action was triggered (MessageType), how severe the equity situation was (WarningType), and the exact equity breakdown (RealizedEquity, UnRealizedEquity, BonusCredit, BSLRealFunds) at that moment. This supports audit, post-mortem analysis of close events, and regulatory review of account liquidations.

The "Partition" suffix indicates this is a partition-based generation table, replacing History.BSLDataForAllUsers. The composite PK (ID, TimeMessageInserted) is the standard pattern for partitioned tables where the partition key is included in the PK.

---

## 2. Business Logic

### 2.1 BSL Message Classification

**What**: MessageType and WarningType classify the severity and type of BSL action for the customer.

**Columns/Parameters Involved**: `MessageType`, `WarningType`, `PercentThreshold`

**Rules**:
- MessageType distinguishes the category of BSL message (e.g., warning vs. close action)
- WarningType indicates the severity level of the equity warning
- PercentThreshold (nullable) captures the configured equity percentage threshold that was breached, when applicable
- ExecutionID links the row to the specific BSL run that produced it

### 2.2 Equity State Snapshot

**What**: The four money columns capture the complete equity breakdown at the time of the BSL check.

**Columns/Parameters Involved**: `RealizedEquity`, `UnRealizedEquity`, `BonusCredit`, `BSLRealFunds`

**Rules**:
- RealizedEquity: the customer's realized account balance (settled trades, deposits, cashouts)
- UnRealizedEquity: the unrealized profit/loss from open positions at snapshot prices
- BonusCredit: bonus credits included in equity calculation
- BSLRealFunds: the "real funds" component of equity (excluding bonus credit) - the denominator for threshold calculations

**Diagram**:
```
BSL Equity Check:
  TotalEquity = RealizedEquity + UnRealizedEquity + BonusCredit
  BSLRealFunds = RealizedEquity + UnRealizedEquity (no bonus)
  WarningThreshold = BSLRealFunds / InitialFunds < PercentThreshold
```

---

## 3. Data Overview

The table is empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. PK component with TimeMessageInserted. |
| 2 | MessageType | tinyint | NO | - | CODE-BACKED | Type of BSL message generated for this customer in this execution. Classifies the kind of BSL action (warning, close signal, etc.). Lookup values defined in the BSL processing service. |
| 3 | WarningType | tinyint | NO | - | CODE-BACKED | Severity level of the equity warning. Higher values typically indicate more critical equity situations closer to forced closure. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID of the account evaluated in this BSL run. Implicit FK to Customer.Customer. |
| 5 | BonusCredit | money | NO | - | CODE-BACKED | Bonus credit amount included in the customer's equity at time of BSL check. Non-withdrawable promotional credit component. |
| 6 | RealizedEquity | money | NO | - | CODE-BACKED | Customer's realized account equity (settled balance) at time of BSL check. Excludes unrealized PnL from open positions. |
| 7 | UnRealizedEquity | money | NO | - | CODE-BACKED | Unrealized profit/loss from all open positions at time of BSL check, computed using the price snapshots from the same ExecutionID. |
| 8 | BSLRealFunds | money | NO | - | CODE-BACKED | "Real funds" equity = RealizedEquity + UnRealizedEquity (excludes bonus credit). This is the value compared against BSL thresholds to determine if action is required. |
| 9 | TimeMessageInserted | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when this BSL message was recorded. PK component. Default = getutcdate() (UTC, unlike some other BSL tables that use getdate()). |
| 10 | PercentThreshold | numeric(4,2) | YES | - | CODE-BACKED | The configured equity percentage threshold that was breached, triggering this message. E.g., 10.00 means BSLRealFunds fell below 10% of initial investment. Nullable - not all message types have a percentage threshold. |
| 11 | ExecutionID | bigint | YES | - | CODE-BACKED | Links this message to the specific BSL execution run (from Trade.ManageBSL). Nullable - some early records may not have had ExecutionID. Enables joining to price snapshots (BSLCurrencyPriceSnapShotsPartition) for the same run. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer whose equity was evaluated |
| ExecutionID | Trade.ManageBSL | Implicit | BSL execution run that produced this message |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SendMessagesToBSL | ExecutionID | Writer | Writes BSL results per user |
| Trade.AcknowledgeMessagesBSL | ExecutionID | Reader/Deleter | Processes and removes pending BSL messages |
| Monitor.TimeMessageInsertedToQueu | TimeMessageInserted | Monitor | Monitors queue latency of BSL messages |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSLDataForAllUsersPartition (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SendMessagesToBSL | Stored Procedure | Writer |
| Trade.AcknowledgeMessagesBSL | Stored Procedure | Reader/Consumer |
| Monitor.TimeMessageInsertedToQueu | Stored Procedure | Monitor - checks message queue age |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLDataForAllUsersNEWPartition | CLUSTERED PK | ID ASC, TimeMessageInserted ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLDataForAllUsersNEWPartition | PRIMARY KEY | (ID, TimeMessageInserted) |
| DF_HistoryBSLDataForAllUsersNEWPartition | DEFAULT | TimeMessageInserted = getutcdate() |

---

## 8. Sample Queries

### 8.1 Get all BSL messages for a customer
```sql
SELECT ID, MessageType, WarningType, RealizedEquity, UnRealizedEquity,
       BSLRealFunds, BonusCredit, PercentThreshold, TimeMessageInserted, ExecutionID
FROM [History].[BSLDataForAllUsersPartition] WITH (NOLOCK)
WHERE CID = @CID
ORDER BY TimeMessageInserted DESC
```

### 8.2 Find critical BSL events by execution
```sql
SELECT ExecutionID, CID, MessageType, WarningType, BSLRealFunds, PercentThreshold, TimeMessageInserted
FROM [History].[BSLDataForAllUsersPartition] WITH (NOLOCK)
WHERE ExecutionID = @ExecutionID
ORDER BY BSLRealFunds ASC
```

### 8.3 Monitor queue age (unprocessed messages)
```sql
SELECT MIN(TimeMessageInserted) AS OldestMessage,
       MAX(TimeMessageInserted) AS NewestMessage,
       COUNT(*) AS PendingCount
FROM [History].[BSLDataForAllUsersPartition] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSLDataForAllUsersPartition | Type: Table | Source: etoro/etoro/History/Tables/History.BSLDataForAllUsersPartition.sql*
