# Wallet.StoreWalletCreationTransaction

> Records the blockchain activation transaction for a wallet, atomically creating the sent transaction with Verified status and marking the wallet as activated, used by the redeem and scheduled jobs services.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT SentTransactions + SentTransactionStatuses + UPDATE Wallets.IsActivated (transactional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records the blockchain transaction that activates a wallet (e.g., the first funding transaction for blockchains that require on-chain activation like XRP). Unlike StoreSentTransaction which creates transactions with Pending status (0), this creates them with Verified status (2) - because the activation transaction is already confirmed by the time it's recorded. It also atomically sets Wallets.IsActivated = 1.

The redeem scheduler and scheduled jobs services call this after a wallet creation transaction is confirmed on-chain. Idempotent via BlockchainTransactionId uniqueness.

---

## 2. Business Logic

### 2.1 Activation Transaction with Pre-Verified Status

**What**: Creates the sent transaction record with StatusId=2 (Verified) and activates the wallet.

**Rules**:
- INSERT SentTransactions with explicit Occurred = @TransactionDateTime (not GETDATE())
- WHERE NOT EXISTS for idempotency on BlockchainTransactionId
- If new: INSERT SentTransactionStatuses with StatusId=2 (Verified, not Pending)
- UPDATE Wallets SET IsActivated=1 WHERE WalletId = @WalletId AND IsActivated <> 1
- Returns ISNULL(@SentTransactionId, 0) - new Id or 0 if duplicate

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Wallet being activated. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency. |
| 3 | @BlockchainTransactionId | nvarchar(100) | NO | - | VERIFIED | On-chain hash of the activation transaction. |
| 4 | @CorrelationId | uniqueidentifier | YES | NULL | VERIFIED | Business correlation ID. |
| 5 | @TransactionTypeId | tinyint | NO | - | VERIFIED | Transaction type (typically 10=BlockChainActivation). |
| 6 | @BlockchainFee | decimal(36,18) | YES | NULL | CODE-BACKED | Network fee. |
| 7 | @TransactionDateTime | datetime2(7) | NO | - | CODE-BACKED | On-chain transaction timestamp. |
| 8 | (output) | bigint | NO | - | CODE-BACKED | SentTransactionId or 0 if duplicate/error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SentTransactions | INSERT | Activation transaction record |
| - | Wallet.SentTransactionStatuses | INSERT | Verified status (2) |
| @WalletId | Wallet.Wallets | UPDATE | Sets IsActivated=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemSchedulerUser | - | EXECUTE | Wallet activation recording |
| ScheduledJobsUser | - | EXECUTE | Scheduled activation recording |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreWalletCreationTransaction (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.Wallets (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | INSERT with idempotency |
| Wallet.SentTransactionStatuses | Table | Verified status INSERT |
| Wallet.Wallets | Table | UPDATE IsActivated |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemSchedulerUser, ScheduledJobsUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record wallet activation
```sql
EXEC Wallet.StoreWalletCreationTransaction @WalletId='WALLET-GUID', @CryptoId=4, @BlockchainTransactionId='0xabc...', @TransactionTypeId=10, @TransactionDateTime='2026-04-15 12:00:00';
```

### 8.2 Check wallet activation status
```sql
SELECT WalletId, IsActivated FROM Wallet.Wallets WITH (NOLOCK) WHERE WalletId = 'WALLET-GUID';
```

### 8.3 Compare with StoreSentTransaction
```sql
-- StoreSentTransaction: StatusId=0 (Pending), no wallet activation
-- StoreWalletCreationTransaction (this SP): StatusId=2 (Verified), activates wallet
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreWalletCreationTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreWalletCreationTransaction.sql*
