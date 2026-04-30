# Trade.ManageBSL_OLD2

> Intermediate ManageBSL version. Upgraded ID from int to bigint, added partitioning on PS_ManageBSL_Partitions by TimeMessageInsertedToQueue. PK became composite (ID, TimeMessageInsertedToQueue) for partition alignment. Replaced by current Trade.ManageBSL. NOT in live DB (dropped, SSDT only).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID, TimeMessageInsertedToQueue (composite CLUSTERED PK) |
| **Partition** | PS_ManageBSL_Partitions(TimeMessageInsertedToQueue) |
| **Indexes** | PK + 2 partitioned NC indexes |

---

## 1. Business Meaning

Trade.ManageBSL_OLD2 is the intermediate version of the BSL queue table between ManageBSL_OLD and the current Trade.ManageBSL. Changes from ManageBSL_OLD: ID upgraded from int to bigint; partitioning added on PS_ManageBSL_Partitions by TimeMessageInsertedToQueue; PK became composite (ID, TimeMessageInsertedToQueue) for partition alignment. Same column set as ManageBSL_OLD. This version was subsequently replaced by current Trade.ManageBSL which added system versioning and the ForDequeue index pattern.

The live database reports DOES NOT EXIST; it has been dropped and exists only in SSDT. See Trade.ManageBSL for current structure and business logic.

---

## 2. Business Logic

### 2.1 Inherited BSL Message Semantics

**What**: Same business logic as Trade.ManageBSL. MessageType, WarningType, CID, financial snapshot, timing columns, ExecutionID.

**Columns/Parameters Involved**: MessageType, WarningType, CID, financial columns, ExecutionID

**Rules**:
- bigint ID supports higher volume than int
- Partition alignment allows efficient partition-level delete/sliding window

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Live DB | DOES NOT EXIST (dropped) |
| SSDT | Present for schema history |
| Purpose | Intermediate partitioned version |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | Surrogate key; upgraded from int |
| 2 | MessageType | tinyint | NO | - | 0=no action, 1=Warning, 2=Liquidation, 3=Unblock |
| 3 | WarningType | tinyint | NO | - | 0=block, 1=Alert1, 2=Alert2 |
| 4 | CID | int | NO | - | Customer ID |
| 5 | BonusCredit | money | NO | - | Bonus credit at snapshot |
| 6 | RealizedEquity | money | NO | - | Realized equity at snapshot |
| 7 | UnRealizedEquity | money | NO | - | Unrealized equity at snapshot |
| 8 | BSLRealFunds | money | NO | - | Balance stop loss real funds |
| 9 | TimeMessageInsertedToQueue | datetime | NO | getutcdate() | When enqueued; partition key |
| 10 | TimeMessageWasRecieved | datetime | YES | - | When consumer received |
| 11 | TimeMessageWasAck | datetime | YES | - | When acknowledged |
| 12 | ExecutionID | bigint | YES | - | BSL execution run ID |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer lookup |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ManageBSL | - | Current | Final version with system versioning |

---

## 6. Dependencies

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Implicit CID reference |
| PS_ManageBSL_Partitions | Partition Scheme | Table partitioning |

### 6.2 Objects That Depend On This

None. Table dropped from live.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Partition | Status |
|-----------|------|-------------|-----------------|-----------|--------|
| PK_TradeManageBSL_Partitions | CLUSTERED | ID, TimeMessageInsertedToQueue | - | PS_ManageBSL_Partitions | Active |
| IX_ManageBSL_Partitions_CIDMessageTypeWarningType | NC | CID, MessageType, WarningType | (INCLUDE columns) | PS_ManageBSL_Partitions | Active (PAGE compression) |
| IX_ManageBSL_Partitions_TimeMessageWasAck | NC | TimeMessageWasAck, MessageType, TimeMessageInsertedToQueue DESC | - | PS_ManageBSL_Partitions | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| PK_TradeManageBSL_Partitions | PRIMARY KEY | (ID, TimeMessageInsertedToQueue) CLUSTERED ON PS_ManageBSL_Partitions |

---

*Generated: 2026-03-14 | Quality: 6.5/10*
*Object: Trade.ManageBSL_OLD2 | Type: Table | Dropped from live, SSDT only*
