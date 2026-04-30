# Wallet.StoreSentTransaction

> Records an outbound blockchain transaction with its outputs and initial Pending status atomically, with idempotency protection via BlockchainTransactionId uniqueness, used by the executer service after blockchain broadcast.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into SentTransactions + SentTransactionOutputs + SentTransactionStatuses (transactional, idempotent) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary procedure for recording outbound blockchain transactions. The executer service calls this after successfully broadcasting a transaction to the blockchain network. It atomically creates three records: the transaction itself, all its outputs (via TransactionOutputsType TVP), and the initial Pending status (StatusId=0). Idempotent via BlockchainTransactionId uniqueness - if the same hash is submitted twice, the existing transaction's Id is returned instead.

The procedure supports backward-compatible CryptoId resolution from base-chain wallet. Default TransactionTypeId is 1 (CustomerMoneyOut).

---

## 2. Business Logic

### 2.1 Idempotent Three-Table Atomic Insert

**What**: Creates transaction + outputs + initial status atomically, handling duplicates gracefully.

**Columns/Parameters Involved**: `@BlockchainTransactionId`, `SentTransactions`, `SentTransactionOutputs`, `SentTransactionStatuses`

**Rules**:
- WHERE NOT EXISTS (SentTransactions WHERE BlockchainTransactionId = @BlockchainTransactionId)
- If new: SCOPE_IDENTITY captures Id, then INSERT outputs from TVP, then INSERT status=0 (Pending)
- If duplicate: @SentTransactionId IS NULL, so skip outputs/status, lookup existing Id
- Returns @SentTransactionId (new or existing) to caller

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Source wallet. |
| 2 | @CryptoId | int | YES | NULL | VERIFIED | Cryptocurrency. Auto-resolved if NULL. |
| 3 | @BlockchainTransactionId | nvarchar(100) | NO | - | VERIFIED | On-chain hash. Idempotency key. |
| 4 | @TransactionOutputs | Wallet.TransactionOutputsType | NO | - | VERIFIED | TVP of outputs (ToAddress, Amount, EtoroFees, IsEtoroFee, SourceId, SourceIdType). |
| 5 | @CorrelationId | uniqueidentifier | YES | NULL | VERIFIED | Business correlation ID. |
| 6 | @TransactionTypeId | tinyint | YES | 1 | VERIFIED | Default 1=CustomerMoneyOut. See [Transaction Type](../../_glossary.md#transaction-type). |
| 7 | @BlockchainFee | decimal(36,18) | YES | NULL | CODE-BACKED | Network fee. |
| 8 | (output) | bigint | NO | - | CODE-BACKED | Returns the SentTransactionId (new or existing). 0 on error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SentTransactions | INSERT | Transaction record |
| - | Wallet.SentTransactionOutputs | INSERT | Output records from TVP |
| - | Wallet.SentTransactionStatuses | INSERT | Initial Pending status |
| @WalletId | Wallet.CustomerWalletsView | Lookup | CryptoId resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Records broadcast transactions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreSentTransaction (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | INSERT with idempotency |
| Wallet.SentTransactionOutputs | Table | Output INSERT from TVP |
| Wallet.SentTransactionStatuses | Table | Initial status INSERT |
| Wallet.CustomerWalletsView | View | CryptoId resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses BEGIN/COMMIT TRANSACTION.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Store a sent transaction
```sql
DECLARE @outputs Wallet.TransactionOutputsType;
INSERT INTO @outputs VALUES ('1A1zP1eP5...', 0.5, 0.001, 0, NULL, NULL);
EXEC Wallet.StoreSentTransaction @WalletId='WALLET-GUID', @CryptoId=1, @BlockchainTransactionId='0xabc...', @TransactionOutputs=@outputs, @CorrelationId='REQUEST-GUID';
```

### 8.2 Store with multiple outputs (UTXO)
```sql
DECLARE @outputs Wallet.TransactionOutputsType;
INSERT INTO @outputs VALUES ('recipient-addr', 0.5, 0.001, 0, NULL, NULL);
INSERT INTO @outputs VALUES ('change-addr', 0.3, 0, 0, NULL, NULL);
EXEC Wallet.StoreSentTransaction @WalletId='WALLET-GUID', @CryptoId=1, @BlockchainTransactionId='0xdef...', @TransactionOutputs=@outputs;
```

### 8.3 Check stored transaction
```sql
SELECT * FROM Wallet.SentTransactions WITH (NOLOCK) WHERE BlockchainTransactionId = '0xabc...';
SELECT * FROM Wallet.SentTransactionOutputs WITH (NOLOCK) WHERE SentTransactionId = /* Id from above */;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreSentTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreSentTransaction.sql*
