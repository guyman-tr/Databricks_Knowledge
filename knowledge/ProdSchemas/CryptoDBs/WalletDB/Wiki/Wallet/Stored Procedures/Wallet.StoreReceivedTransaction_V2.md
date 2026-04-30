# Wallet.StoreReceivedTransaction_V2

> V2 of the received transaction storage procedure with simplified logic - performs change detection, delete-and-reinsert on update, and atomic creation of transaction records with initial Pending status.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT/DELETE ReceivedTransactions + ReceivedTransactionStatuses (transactional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the V2 version of StoreReceivedTransaction with simplified parameters (no CryptoId, ReceivedTransactionTypeId, ProviderTransactionId, DeleteOnUpdate, or ReceiveRequestCorrelationId). It performs the same core function: storing inbound blockchain transactions with change detection. If existing records match the new data, it returns 0 (WasUpToDate). If different, it deletes existing records (including their statuses) and re-inserts with the new data. Returns 1 (Added) for new or 2 (Updated) for changed transactions.

The balance and redeem persistor services use this simpler V2 interface.

---

## 2. Business Logic

### 2.1 Change Detection + Delete-and-Reinsert

**What**: Compares existing vs new data, deletes old and inserts new on change.

**Rules**:
- FULL JOIN existing ReceivedTransactions vs @Receives on Address + Amount + Count
- If all match: returns 0 (WasUpToDate) - no writes
- If existing records exist but differ: DELETE statuses + DELETE transactions, then INSERT new (RetValue=2 Updated)
- If no existing records: INSERT new (RetValue=1 Added)
- Initial status = 0 (Pending) for all new records
- Uses OUTPUT to capture inserted IDs

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Destination wallet. |
| 2 | @SenderAddress | nvarchar(512) | NO | - | VERIFIED | Sender blockchain address. |
| 3 | @BlockchainFee | decimal(36,18) | NO | - | CODE-BACKED | Network fee. |
| 4 | @CorrelationId | uniqueidentifier | YES | NULL | VERIFIED | Business correlation ID. |
| 5 | @BlockchainTransactionId | nvarchar(100) | YES | NULL | VERIFIED | On-chain hash. |
| 6 | @BlockchainTransactionDate | datetime | YES | NULL | CODE-BACKED | On-chain timestamp. |
| 7 | @Receives | Wallet.ReceiverListType | NO | - | VERIFIED | TVP of receiver outputs (Address, Amount). |
| 8 | Response (output) | int | NO | - | CODE-BACKED | 0=WasUpToDate, 1=Added, 2=Updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ReceivedTransactions | INSERT/DELETE | Transaction records |
| - | Wallet.ReceivedTransactionStatuses | INSERT/DELETE | Status records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | Balance sync |
| RedeemPersistorUser | - | EXECUTE | Redemption receive processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreReceivedTransaction_V2 (procedure)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | INSERT/DELETE + change detection |
| Wallet.ReceivedTransactionStatuses | Table | INSERT/DELETE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BalanceUser, RedeemPersistorUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Store a received transaction (V2)
```sql
DECLARE @receives Wallet.ReceiverListType;
INSERT INTO @receives VALUES ('1A1zP1eP5...', 0.5);
EXEC Wallet.StoreReceivedTransaction_V2 @WalletId='WALLET-GUID', @SenderAddress='sender-addr', @BlockchainFee=0.0001, @BlockchainTransactionId='0xabc...', @Receives=@receives;
```

### 8.2 Compare V1 vs V2
```sql
-- V1 (more params): EXEC Wallet.StoreReceivedTransaction @WalletId=..., @CryptoId=1, @SenderAddress=..., @BlockchainFee=..., @Receives=..., @ReceivedTransactionTypeId=1, ...
-- V2 (simpler): EXEC Wallet.StoreReceivedTransaction_V2 @WalletId=..., @SenderAddress=..., @BlockchainFee=..., @Receives=...
```

### 8.3 Check result meaning
```sql
-- Response = 0: Data was already up to date (no writes)
-- Response = 1: New transaction added
-- Response = 2: Existing transaction updated (deleted + re-inserted)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreReceivedTransaction_V2 | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreReceivedTransaction_V2.sql*
