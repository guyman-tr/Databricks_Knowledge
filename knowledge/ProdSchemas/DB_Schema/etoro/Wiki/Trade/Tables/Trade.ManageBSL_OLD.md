# Trade.ManageBSL_OLD

> Original non-partitioned version of ManageBSL. Uses int ID (vs bigint in current). Same column set but no partitioning. Replaced by ManageBSL_OLD2 (partitioned) then by current Trade.ManageBSL. NOT in live DB (dropped, SSDT only).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | PK + 2 nonclustered |

---

## 1. Business Meaning

Trade.ManageBSL_OLD is the original non-partitioned version of the BSL (Balance Stop Loss) queue table. It has the same column set as the current Trade.ManageBSL: MessageType (0=no action, 1=Warning, 2=Liquidation, 3=Unblock), WarningType (0=block, 1=Alert1, 2=Alert2), CID, financial snapshot columns (BonusCredit, RealizedEquity, UnRealizedEquity, BSLRealFunds), and timing columns (TimeMessageInsertedToQueue, TimeMessageWasRecieved, TimeMessageWasAck, ExecutionID). Key differences from current: ID is `int` (vs `bigint`), no partitioning, PK on ID only (current has composite PK on ID + TimeMessageInsertedToQueue for partition alignment).

This table was replaced by Trade.ManageBSL_OLD2 (partitioned, bigint ID) and then by current Trade.ManageBSL. The live database reports DOES NOT EXIST; it has been dropped and exists only in SSDT for schema history.

---

## 2. Business Logic

### 2.1 Inherited BSL Message Semantics

**What**: Same business logic as Trade.ManageBSL. See Trade.ManageBSL.md for MessageType, WarningType, lifecycle, and cleanup rules.

**Columns/Parameters Involved**: MessageType, WarningType, CID, financial columns, ExecutionID

**Rules**:
- MessageType: 0=no action, 1=Warning, 2=Liquidation, 3=Unblock
- WarningType: 0=block, 1=Alert1, 2=Alert2
- int ID limits max ~2.1B rows vs bigint in later versions

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Live DB | DOES NOT EXIST (dropped) |
| SSDT | Present for schema history |
| Purpose | Pre-partitioning snapshot |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | Surrogate key (PK); int vs bigint in current |
| 2 | MessageType | tinyint | NO | - | 0=no action, 1=Warning, 2=Liquidation, 3=Unblock |
| 3 | WarningType | tinyint | NO | - | 0=block, 1=Alert1, 2=Alert2 |
| 4 | CID | int | NO | - | Customer ID |
| 5 | BonusCredit | money | NO | - | Bonus credit at snapshot |
| 6 | RealizedEquity | money | NO | - | Realized equity at snapshot |
| 7 | UnRealizedEquity | money | NO | - | Unrealized equity at snapshot |
| 8 | BSLRealFunds | money | NO | - | Balance stop loss real funds |
| 9 | TimeMessageInsertedToQueue | datetime | NO | getutcdate() | When enqueued |
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
| Trade.ManageBSL_OLD2 | - | Successor | Partitioned version with bigint ID |
| Trade.ManageBSL | - | Current | Final version with partitioning + system versioning |

---

## 6. Dependencies

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Implicit CID reference |

### 6.2 Objects That Depend On This

None. Table dropped from live; historical schema only.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeManageBSL | CLUSTERED | ID | - | - | Active |
| IX_TimeMessageWasAck | NC | TimeMessageWasAck, MessageType, TimeMessageInsertedToQueue DESC | - | - | Active (PAGE compression) |
| IX_TradeManageBSL_CIDMessageTypeWarningType | NC | CID, MessageType, WarningType | TimeMessageInsertedToQueue, TimeMessageWasAck | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| PK_TradeManageBSL | PRIMARY KEY | ID (CLUSTERED) |

---

*Generated: 2026-03-14 | Quality: 6.5/10*
*Object: Trade.ManageBSL_OLD | Type: Table | Dropped from live, SSDT only*
