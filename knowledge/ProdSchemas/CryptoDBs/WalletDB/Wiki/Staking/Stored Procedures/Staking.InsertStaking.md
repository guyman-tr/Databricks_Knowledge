# Staking.InsertStaking

> Creates a new staking operation record with idempotency protection, and atomically sets the initial Pending status within a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | WRITER for Staking.Staking and Staking.StakingStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary WRITER procedure for the Staking schema. It creates a new staking operation when a user delegates crypto to a staking pool. The procedure is the entry point for the entire staking lifecycle - it creates both the Staking.Staking record and the initial Pending (1) status in Staking.StakingStatuses within a single atomic transaction.

The CorrelationId parameter serves as an idempotency key - if a staking record with the same CorrelationId already exists, the insert is skipped and an error is raised. This prevents duplicate staking operations from concurrent or retried service calls.

For backward compatibility, the procedure can resolve CryptoId from Wallet.CustomerWalletsView when the parameter is NULL, using the wallet's blockchain crypto ID.

---

## 2. Business Logic

### 2.1 Idempotent Creation with Atomic Status

**What**: Creates staking record + initial Pending status in a single transaction with duplicate protection.

**Columns/Parameters Involved**: `@CorrelationId`, `@WalletId`, `@Amount`, `@CryptoId`

**Rules**:
- Validates @WalletId is not NULL (raises error with CorrelationId context if null)
- If @CryptoId is NULL, resolves from Wallet.CustomerWalletsView WHERE cwv.Id = @WalletId AND cwv.CryptoId = cwv.BlockchainCryptoId
- INSERT INTO Staking.Staking with WHERE NOT EXISTS (SELECT 1 WHERE CorrelationId = @CorrelationId)
- Uses SCOPE_IDENTITY() to get the new StakingId
- If @StakingId is NULL (no insert happened), raises error "Staking with CorrelationId already exists"
- Inserts initial status Pending (StakingStatusId=1) into Staking.StakingStatuses
- All within BEGIN TRANSACTION / COMMIT with error handling (ROLLBACK on failure)

**Diagram**:
```
BEGIN TRAN
  |
  v
Validate @WalletId != NULL
  |
  v
Resolve @CryptoId (if NULL) from CustomerWalletsView
  |
  v
INSERT Staking.Staking (if CorrelationId not exists)
  |
  +-- SCOPE_IDENTITY() = NULL? --> RAISERROR "already exists"
  |
  v
INSERT Staking.StakingStatuses (StakingStatusId=1 Pending)
  |
  v
COMMIT TRAN
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier (IN) | NO | - | VERIFIED | The customer wallet initiating the stake. Must not be NULL (validated with RAISERROR). FK to Wallet.Wallets.WalletId. Also used for CryptoId backward-compatibility resolution. |
| 2 | @Amount | decimal(36,18) (IN) | NO | - | VERIFIED | The amount of cryptocurrency to stake, in native units (e.g., 1.345 ETH). Stored in Staking.Staking.Amount. |
| 3 | @CorrelationId | uniqueidentifier (IN) | NO | - | VERIFIED | Idempotency key. Each staking request must have a unique CorrelationId. Used for duplicate detection (NOT EXISTS check) and by downstream procedures (InsertStakingStatus, InsertStakingTransaction) to locate this record. |
| 4 | @CryptoId | int (IN) | YES | - | VERIFIED | The cryptocurrency being staked. FK to Wallet.CryptoTypes.CryptoID. If NULL, resolved from Wallet.CustomerWalletsView using @WalletId (backward compatibility). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Staking.Staking | INSERT | Creates the staking operation record |
| - | Staking.StakingStatuses | INSERT | Creates the initial Pending status |
| - | Wallet.CustomerWalletsView | SELECT | Resolves CryptoId from WalletId (backward compat) |

### 5.2 Referenced By (other objects point to this)

Called by the staking application service when a user initiates a staking delegation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.InsertStaking (procedure)
+-- Staking.Staking (table)
+-- Staking.StakingStatuses (table)
+-- Wallet.CustomerWalletsView (view)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.Staking | Table | INSERT - creates staking record |
| Staking.StakingStatuses | Table | INSERT - creates initial Pending status |
| Wallet.CustomerWalletsView | View | SELECT - CryptoId resolution fallback |

### 6.2 Objects That Depend On This

No dependents found. This is the entry point, not called by other SPs.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | ACID | Entire operation (staking + status) wrapped in explicit transaction with rollback |

---

## 8. Sample Queries

### 8.1 Create a new staking operation
```sql
EXEC Staking.InsertStaking
    @WalletId = 'AA322F68-E305-48EF-866B-599E503F418D',
    @Amount = 1.5,
    @CorrelationId = NEWID(),
    @CryptoId = 2
```

### 8.2 Verify the created record
```sql
SELECT s.Id, s.Amount, s.CorrelationId, ds.Name AS Status
FROM Staking.Staking s WITH (NOLOCK)
INNER JOIN Staking.StakingStatuses ss WITH (NOLOCK) ON ss.StakingId = s.Id
INNER JOIN Dictionary.StakingStatuses ds WITH (NOLOCK) ON ds.Id = ss.StakingStatusId
WHERE s.CorrelationId = @CorrelationId
```

### 8.3 Check for recent staking operations
```sql
SELECT TOP 10 s.Id, s.WalletId, s.Amount, s.CorrelationId, s.Occurred
FROM Staking.Staking s WITH (NOLOCK)
ORDER BY s.Id DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | eToro initiates staking on behalf of users; the process is automatic for eligible real crypto positions |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.InsertStaking | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.InsertStaking.sql*
