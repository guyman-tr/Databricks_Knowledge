# Staking.GetStakingRecordsList

> Aggregates a customer's staking history into a unified timeline combining rewards, transactions, and stake-and-reward refunds, sorted by most recent first.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: unified staking records with RecordType discriminator |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure builds a unified staking activity timeline for a customer by combining three types of records: rewards (RecordType=2), staking transactions (RecordType=1), and stake-and-reward refund transactions (RecordType=3). It calls three cross-schema Wallet functions and merges results into a single temp table, returning the most recent records first.

This is the user-facing "staking activity" feed showing all staking-related movements - money staked, rewards earned, and any refunds - in chronological order.

Uses `EXECUTE AS owner` for elevated permissions to call cross-schema functions.

---

## 2. Business Logic

### 2.1 Three-Source Record Aggregation

**What**: Combines rewards, transactions, and refunds into a single timeline with a type discriminator.

**Columns/Parameters Involved**: `RecordType`, `Amount`, `BeginDate`

**Rules**:
- RecordType=1 (Transaction): From `Wallet.GetStakingTransactionList(@Gcid, @CryptoId, NULL, @BeginDateBefore, @RecordsLimit, 0)` - staking delegation transfers
- RecordType=2 (Reward): From `Wallet.GetStakingRewardsList(@Gcid, @CryptoId, @BeginDateBefore, @RecordsLimit)` - monthly reward distributions with yield data
- RecordType=3 (Stake&Reward refund): From `Wallet.GetReceivedTransactionList(@Gcid, @CryptoId, NULL, @BeginDateBefore, @RecordsLimit, 1)` - refund/bounce-back transactions
- All three are merged into #GetStakingRecords and sorted by BeginDate DESC
- Final output limited by @RecordsLimit

**Diagram**:
```
Wallet.GetStakingRewardsList -----> [RecordType=2] --|
Wallet.GetStakingTransactionList -> [RecordType=1] --|--> #GetStakingRecords --> TOP N ORDER BY BeginDate DESC
Wallet.GetReceivedTransactionList > [RecordType=3] --|
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint (IN) | NO | - | VERIFIED | Global Customer ID. Passed to all three Wallet functions to filter by customer. |
| 2 | @CryptoId | int (IN) | NO | - | VERIFIED | The cryptocurrency to retrieve staking records for. Passed to all three functions. |
| 3 | @BeginDateBefore | datetime2(7) (IN) | NO | - | CODE-BACKED | Date cursor for pagination. Returns records with BeginDate before this value. |
| 4 | @RecordsLimit | int (IN) | YES | 1000 | CODE-BACKED | Maximum total records to return across all three record types. Default 1000. |

**Return Columns**:

| # | Element | Type | Description |
|---|---------|------|-------------|
| 1 | RecordId | bigint | Source record ID (meaning varies by RecordType) |
| 2 | RecordType | int | Discriminator: 1=Transaction, 2=Reward, 3=Stake&Reward refund |
| 3 | Amount | decimal(36,18) | Amount in crypto native units |
| 4 | CryptoId | int | The cryptocurrency |
| 5 | BeginDate | datetime2(7) | Timestamp of the record (used for chronological ordering) |
| 6 | YieldPercentage | decimal(36,18) | Yield % (only for RecordType=2 rewards, NULL for others) |
| 7 | MonthId | int | Staking month YYYYMM (only for RecordType=2, NULL for others) |
| 8 | Status | int | Status ID (only for RecordType=1 transactions and RecordType=3, NULL for rewards) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.GetStakingRewardsList | FUNCTION CALL | Retrieves reward records (RecordType=2) |
| - | Wallet.GetStakingTransactionList | FUNCTION CALL | Retrieves transaction records (RecordType=1) |
| - | Wallet.GetReceivedTransactionList | FUNCTION CALL | Retrieves stake-and-reward refund records (RecordType=3) |

### 5.2 Referenced By (other objects point to this)

Called by the staking service API for the unified staking activity feed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.GetStakingRecordsList (procedure)
+-- Wallet.GetStakingRewardsList (function)
+-- Wallet.GetStakingTransactionList (function)
+-- Wallet.GetReceivedTransactionList (function)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetStakingRewardsList | Function | Called to get reward records |
| Wallet.GetStakingTransactionList | Function | Called to get transaction records |
| Wallet.GetReceivedTransactionList | Function | Called to get refund records |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS owner | Security | Elevated permissions for cross-schema function access |
| #GetStakingRecords | Temp Table | In-memory staging table for merging three record sources |

---

## 8. Sample Queries

### 8.1 Get staking records for a customer
```sql
EXEC Staking.GetStakingRecordsList
    @Gcid = 14509456,
    @CryptoId = 2,
    @BeginDateBefore = '2024-01-01',
    @RecordsLimit = 100
```

### 8.2 Get all staking records (using far-future date)
```sql
EXEC Staking.GetStakingRecordsList
    @Gcid = 14509456,
    @CryptoId = 2,
    @BeginDateBefore = '9999-12-31'
```

### 8.3 Interpret record types
```sql
-- After calling the procedure, interpret RecordType:
-- 1 = Staking Transaction (delegation to pool)
-- 2 = Staking Reward (monthly distribution)
-- 3 = Stake & Reward Refund (bounce-back)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Users can view staking rewards, transactions, and refunds through the platform; rewards distributed monthly; reverse/refund process exists for opt-out scenarios |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.GetStakingRecordsList | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.GetStakingRecordsList.sql*
