# Staking.InsertStakingTransaction

> Creates a blockchain transaction record for a staking operation, recording the destination address and fees.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | WRITER for Staking.StakingTransactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records the blockchain-level details of a staking transfer - the external address where assets were sent and the associated fees. It locates the staking record via CorrelationId and inserts into Staking.StakingTransactions. The procedure also handles wallet resolution when the caller provides an empty or NULL WalletId, using the original staking record's wallet to find the correct target wallet for the specified CryptoId.

Called after the blockchain transfer is initiated to record the on-chain details alongside the business-level staking record.

---

## 2. Business Logic

### 2.1 Wallet Resolution for Cross-Crypto Staking

**What**: Resolves the correct wallet when the caller's WalletId is empty, supporting scenarios where the staking wallet differs from the originating wallet.

**Columns/Parameters Involved**: `@WalletId`, `@CorrelationId`, `@CryptoId`

**Rules**:
- If @WalletId is NULL or empty GUID (all zeros): resolves by joining Staking.Staking -> Wallet.CustomerWalletsView (original wallet's customer) -> Wallet.CustomerWalletsView (wallet for @CryptoId)
- If @CryptoId is NULL: resolved from Wallet.CustomerWalletsView WHERE CryptoId = BlockchainCryptoId (backward compatibility)
- INSERT uses NOT EXISTS check to prevent duplicates (references WalletId and CryptoId columns in the WHERE clause)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier (IN) | NO | - | VERIFIED | The idempotency key to locate the staking record. Used to look up Staking.Staking.Id for the StakingId FK. |
| 2 | @CryptoId | int (IN) | YES | - | VERIFIED | The cryptocurrency being staked. Used for wallet resolution if WalletId is empty. If NULL, resolved from CustomerWalletsView. |
| 3 | @WalletId | uniqueidentifier (IN) | YES | - | VERIFIED | The wallet associated with this transaction. If NULL or empty GUID, resolved from the staking record's wallet via CustomerWalletsView. |
| 4 | @ExternalStakingAddress | varchar(64) (IN) | NO | - | VERIFIED | The blockchain address of the staking pool. Stored in StakingTransactions.ExternalStakingAddress. |
| 5 | @EtoroFee | decimal(36,18) (IN) | NO | - | VERIFIED | eToro's service fee for this staking transfer, in crypto native units. |
| 6 | @BlockchainEstFee | decimal(36,18) (IN) | NO | - | VERIFIED | Estimated blockchain network fee for this transfer, in crypto native units. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Staking.Staking | SELECT | Looks up staking record by CorrelationId |
| - | Staking.StakingTransactions | INSERT | Creates the transaction record |
| - | Wallet.CustomerWalletsView | SELECT | Wallet resolution for empty WalletId and CryptoId fallback |

### 5.2 Referenced By (other objects point to this)

Called by the staking service after blockchain transfer initiation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.InsertStakingTransaction (procedure)
+-- Staking.Staking (table)
+-- Staking.StakingTransactions (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.Staking | Table | SELECT - CorrelationId lookup |
| Staking.StakingTransactions | Table | INSERT - creates transaction record |
| Wallet.CustomerWalletsView | View | SELECT - wallet and CryptoId resolution |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Record a staking transaction
```sql
EXEC Staking.InsertStakingTransaction
    @CorrelationId = 'A2397984-2E2F-4BEB-9CCB-CF93D206F8DC',
    @CryptoId = 2,
    @WalletId = 'AA322F68-E305-48EF-866B-599E503F418D',
    @ExternalStakingAddress = '0xCB2A66540680c344bab5f818d68c3e4B9D57363B',
    @EtoroFee = 0,
    @BlockchainEstFee = 0
```

### 8.2 Verify transaction was recorded
```sql
SELECT st.* FROM Staking.StakingTransactions st WITH (NOLOCK)
INNER JOIN Staking.Staking s WITH (NOLOCK) ON s.Id = st.StakingId
WHERE s.CorrelationId = 'A2397984-2E2F-4BEB-9CCB-CF93D206F8DC'
```

### 8.3 Staking operations with transaction details
```sql
SELECT s.Id, s.Amount, st.ExternalStakingAddress, st.EtoroFee, st.BlockchainEstFee
FROM Staking.Staking s WITH (NOLOCK)
INNER JOIN Staking.StakingTransactions st WITH (NOLOCK) ON st.StakingId = s.Id
ORDER BY s.Id DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Staking transfers go to eToro-managed pool addresses; fees currently zero |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.InsertStakingTransaction | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.InsertStakingTransaction.sql*
