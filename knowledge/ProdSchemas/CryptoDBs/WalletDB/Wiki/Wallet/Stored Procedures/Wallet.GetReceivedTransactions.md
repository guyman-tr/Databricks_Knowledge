# Wallet.GetReceivedTransactions

> Retrieves all received (inbound) crypto transactions for a specific wallet and cryptocurrency, with optional date filtering and backward-compatible crypto ID resolution.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns received transaction history for a wallet |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the history of inbound crypto transactions for a customer's wallet. It serves as the primary API for retrieving deposit/receive history, powering customer-facing transaction lists, back-office inquiry screens, and reconciliation workflows.

Without this procedure, there would be no efficient way to retrieve a customer's received transaction history filtered by wallet and crypto type. It provides the foundation for "show me my deposits" functionality in the wallet application.

For backward compatibility, when @CryptoId is NULL, the procedure auto-resolves it from `Wallet.CustomerWalletsView` by matching the wallet where CryptoId equals BlockchainCryptoId (the native blockchain crypto). This supports older callers that were unaware of token-level CryptoId and only tracked wallets by their blockchain address.

---

## 2. Business Logic

### 2.1 Backward-Compatible Crypto Resolution

**What**: Auto-resolves the crypto ID when legacy callers omit it.

**Columns/Parameters Involved**: `@CryptoId`, `@WalletId`, `CustomerWalletsView.CryptoId`, `CustomerWalletsView.BlockchainCryptoId`

**Rules**:
- If @CryptoId is provided: use it directly
- If @CryptoId is NULL: resolve from CustomerWalletsView where cwv.Id = @WalletId AND cwv.CryptoId = cwv.BlockchainCryptoId
- The condition CryptoId = BlockchainCryptoId selects the "native" crypto entry for a wallet (e.g., ETH for an Ethereum wallet, not ERC-20 tokens)
- This ensures legacy callers that only know the wallet ID get the native blockchain transactions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | The wallet to retrieve received transactions for. FK to Wallet.Wallets. |
| 2 | @CryptoId | int | YES | NULL | CODE-BACKED | Optional cryptocurrency filter. When NULL, auto-resolved to the wallet's native blockchain crypto. When specified, filters to that exact crypto (e.g., a specific ERC-20 token). |
| 3 | @FromDate | datetime | YES | NULL | CODE-BACKED | Optional lower bound on transaction date. When NULL, returns all transactions. When specified, only returns transactions with Occurred >= @FromDate. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Timestamp when the received transaction was recorded in the wallet system. |
| 2 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | The wallet that received the transaction. |
| 3 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency ID of the received transaction. FK to Wallet.CryptoTypes. |
| 4 | SenderAddress | nvarchar | YES | - | CODE-BACKED | Blockchain address of the sender. May be NULL for some blockchain types. |
| 5 | ReceiverAddress | nvarchar | NO | - | CODE-BACKED | Blockchain address that received the funds. |
| 6 | Amount | decimal | NO | - | CODE-BACKED | Amount of crypto received. |
| 7 | BlockchainFee | decimal | YES | - | CODE-BACKED | Blockchain network fee for this transaction. |
| 8 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Correlation identifier linking this transaction to the request pipeline. |
| 9 | BlockchainTransactionId | nvarchar(100) | YES | - | CODE-BACKED | The on-chain transaction hash. |
| 10 | BlockchainTransactionDate | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the transaction on the blockchain (block time). |
| 11 | ReceivedTransactionTypeId | tinyint | YES | - | CODE-BACKED | Type of received transaction (e.g., customer deposit, internal transfer, staking reward). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId | Wallet.CustomerWalletsView | Lookup | Resolves wallet to crypto ID for backward compatibility |
| FROM | Wallet.ReceivedTransactions | FROM | Main data source for received transactions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | - | Called for customer deposit history display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetReceivedTransactions (procedure)
├── Wallet.ReceivedTransactions (table)
└── Wallet.CustomerWalletsView (view)
      ├── Wallet.Wallets (table)
      ├── Wallet.WalletAddresses (table)
      └── Wallet.BlockchainCryptos (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | Main data source - SELECT with NOLOCK |
| Wallet.CustomerWalletsView | View | Backward-compatible crypto ID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No SQL dependents found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hints | Read isolation | Both ReceivedTransactions and CustomerWalletsView use NOLOCK |

---

## 8. Sample Queries

### 8.1 Get all received transactions for a wallet
```sql
EXEC Wallet.GetReceivedTransactions @WalletId = 'A1B2C3D4-GUID-HERE', @CryptoId = NULL, @FromDate = NULL;
```

### 8.2 Get BTC deposits since a specific date
```sql
EXEC Wallet.GetReceivedTransactions @WalletId = 'A1B2C3D4-GUID-HERE', @CryptoId = 1, @FromDate = '2026-01-01';
```

### 8.3 Manual query for received transactions with status
```sql
SELECT rt.Occurred, rt.Amount, rt.SenderAddress, rt.ReceiverAddress, rt.BlockchainTransactionId,
    rts.StatusId AS CurrentStatus
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
    CROSS APPLY (
        SELECT TOP 1 StatusId FROM Wallet.ReceivedTransactionStatuses WITH (NOLOCK)
        WHERE ReceivedTransactionId = rt.Id ORDER BY Id DESC
    ) rts
WHERE rt.WalletId = 'A1B2C3D4-GUID-HERE' AND rt.CryptoId = 1
ORDER BY rt.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetReceivedTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetReceivedTransactions.sql*
