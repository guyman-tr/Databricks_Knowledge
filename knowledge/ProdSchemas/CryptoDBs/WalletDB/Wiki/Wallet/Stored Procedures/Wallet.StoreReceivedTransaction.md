# Wallet.StoreReceivedTransaction

> Stores an inbound blockchain transaction with its receiver outputs, performing change detection to skip unchanged data, handling both new inserts and updates with delete-on-update capability, and normalizing addresses before storage.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT/UPDATE ReceivedTransactions + ReceivedTransactionStatuses (transactional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary procedure for recording inbound blockchain transactions. The balance, executer, and redeem persistor services call this when the blockchain provider reports a new incoming transaction or updates an existing one. The procedure is sophisticated: it first checks if the existing data matches the new data (change detection via FULL JOIN on address+amount counts), and returns early if nothing changed. If data is new or different, it handles both fresh inserts and updates, optionally deleting old records before re-inserting (@DeleteOnUpdate).

The procedure processes multiple receiver outputs via the ReceiverListType TVP, normalizes addresses (stripping protocol prefixes/suffixes), and atomically creates the transaction, its initial status, and optionally a request correlation via an exclusive lock on ReceivedTransactionsLock for concurrency safety.

---

## 2. Business Logic

### 2.1 Change Detection (Skip If Up-To-Date)

**What**: Compares existing receiver records against new data to avoid unnecessary writes.

**Columns/Parameters Involved**: `@WalletId`, `@CryptoId`, `@BlockchainTransactionId`, `@Receives`

**Rules**:
- FULL JOIN existing ReceivedTransactions vs @Receives TVP on normalized Address + Amount
- If all records match (no NULL/mismatch rows), returns (0, 0) - WasUpToDate
- Address normalization: RemovePrefix/RemoveSuffix strips protocol and query params
- ProviderTransactionId also considered in matching

### 2.2 Exclusive Concurrency Lock

**What**: Prevents concurrent inserts for the same transaction from different service instances.

**Rules**:
- UPDATE ReceivedTransactionsLock SET Num = Num + 1 at start of transaction
- This exclusive table lock serializes concurrent StoreReceivedTransaction calls
- Prevents duplicate received transactions from parallel blockchain provider callbacks

### 2.3 Delete-On-Update Mode

**What**: When @DeleteOnUpdate=1, removes existing records before re-inserting.

**Rules**:
- Used when the blockchain provider sends a corrected version of a transaction
- Deletes old ReceivedTransactions for same WalletId + CryptoId + BlockchainTransactionId
- Then inserts all new receiver outputs from the TVP

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Destination wallet receiving the transaction. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency. FK to Wallet.CryptoTypes. |
| 3 | @SenderAddress | nvarchar(512) | NO | - | VERIFIED | Blockchain address that sent the transaction. |
| 4 | @BlockchainFee | decimal(36,18) | NO | - | CODE-BACKED | Network fee for the transaction. |
| 5 | @CorrelationId | uniqueidentifier | YES | NULL | VERIFIED | Business correlation ID. |
| 6 | @BlockchainTransactionId | nvarchar(100) | YES | NULL | VERIFIED | On-chain transaction hash. |
| 7 | @BlockchainTransactionDate | datetime | YES | NULL | CODE-BACKED | On-chain transaction timestamp. |
| 8 | @Receives | Wallet.ReceiverListType | NO | - | VERIFIED | TVP of receiver outputs (Address, Amount pairs). |
| 9 | @ReceivedTransactionTypeId | tinyint | YES | 1 | CODE-BACKED | Transaction type. Default 1 (standard receive). |
| 10 | @ProviderTransactionId | varchar(128) | YES | NULL | CODE-BACKED | Provider's internal transaction reference. |
| 11 | @DeleteOnUpdate | bit | YES | 0 | CODE-BACKED | When 1, deletes existing records before re-inserting. |
| 12 | @ReceiveRequestCorrelationId | uniqueidentifier | YES | NULL | CODE-BACKED | Correlation ID for the receive request (if initiated by request). |
| 13 | @ReceiveDetailsJsonString | nvarchar(max) | YES | NULL | CODE-BACKED | Optional JSON details for the receive status. |
| 14 | InsertionIndex (output) | bigint | NO | - | CODE-BACKED | ID of the first inserted ReceivedTransaction. 0 if up-to-date. |
| 15 | InsertionStatus (output) | int | NO | - | CODE-BACKED | 0=WasUpToDate, 1=NewInsert, 2=UpdatedExisting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ReceivedTransactions | INSERT/DELETE | Transaction records |
| - | Wallet.ReceivedTransactionStatuses | INSERT | Initial status (Pending=0) |
| - | Wallet.ReceivedTransactionsLock | UPDATE | Concurrency lock |
| @WalletId | Wallet.CustomerWalletsView | Lookup | Address normalization |
| @WalletId | Wallet.WalletAddresses | Lookup | Main address detection |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | Balance sync inbound transactions |
| ExecuterUser | - | EXECUTE | Blockchain provider callbacks |
| RedeemPersistorUser | - | EXECUTE | Redemption receive processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreReceivedTransaction (procedure)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.ReceivedTransactionsLock (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | INSERT/DELETE/SELECT |
| Wallet.ReceivedTransactionStatuses | Table | Initial status INSERT |
| Wallet.ReceivedTransactionsLock | Table | Concurrency lock |
| Wallet.CustomerWalletsView | View | Address normalization |
| Wallet.WalletAddresses | Table | Main address detection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BalanceUser, ExecuterUser, RedeemPersistorUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses ReceivedTransactionsLock for concurrency control.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Store a received transaction
```sql
DECLARE @receives Wallet.ReceiverListType;
INSERT INTO @receives VALUES ('1A1zP1eP5...', 0.5);
EXEC Wallet.StoreReceivedTransaction @WalletId='WALLET-GUID', @CryptoId=1, @SenderAddress='sender-addr', @BlockchainFee=0.0001, @BlockchainTransactionId='0xabc...', @Receives=@receives;
```

### 8.2 Check received transactions for a wallet
```sql
SELECT * FROM Wallet.ReceivedTransactions WITH (NOLOCK) WHERE WalletId = 'WALLET-GUID' ORDER BY Id DESC;
```

### 8.3 Store with delete-on-update
```sql
DECLARE @receives Wallet.ReceiverListType;
INSERT INTO @receives VALUES ('1A1zP1eP5...', 0.6);
EXEC Wallet.StoreReceivedTransaction @WalletId='WALLET-GUID', @CryptoId=1, @SenderAddress='sender-addr', @BlockchainFee=0.0001, @BlockchainTransactionId='0xabc...', @Receives=@receives, @DeleteOnUpdate=1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreReceivedTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreReceivedTransaction.sql*
