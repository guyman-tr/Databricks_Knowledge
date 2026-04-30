# Wallet.GetSentTransactionByWalletId

> Retrieves the outbound transaction history for a specific wallet, with optional crypto, date range filtering, and backward-compatible wallet-to-crypto resolution via CustomerWalletsView.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns sent transactions filtered by WalletId + optional CryptoId/date range |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the history of outbound blockchain transactions for a specific wallet, ordered by most recent first. It supports optional filtering by cryptocurrency, start date, and end date. The primary consumer is the executer service, which uses it to review a wallet's send history for processing decisions such as duplicate detection and rate limiting.

The procedure includes a backward-compatibility mechanism: if @CryptoId is NULL, it resolves the crypto from CustomerWalletsView by matching the WalletId where CryptoId equals BlockchainCryptoId (the base-chain crypto). This handles legacy callers that don't pass the crypto parameter. The result includes the transaction's blockchain hash, type, fees, and correlation ID, providing enough context for the executer to make processing decisions without additional lookups.

---

## 2. Business Logic

### 2.1 Backward-Compatible CryptoId Resolution

**What**: Auto-resolves the cryptocurrency when not provided by the caller.

**Columns/Parameters Involved**: `@WalletId`, `@CryptoId`, `CustomerWalletsView`

**Rules**:
- If @CryptoId IS NULL, resolves from CustomerWalletsView WHERE Id = @WalletId AND CryptoId = BlockchainCryptoId
- The condition CryptoId = BlockchainCryptoId selects the base-chain wallet entry (not token sub-wallets)
- This preserves backward compatibility with older callers that only pass WalletId
- When @CryptoId IS provided, the resolution step is skipped

### 2.2 Date Range Filtering

**What**: Optional date boundaries constrain the result set for performance and relevance.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `SentTransactions.Occurred`

**Rules**:
- Both parameters are optional (NULL = no constraint)
- @FromDate filters: Occurred >= @FromDate
- @ToDate filters: Occurred <= @ToDate
- Results always ordered by Occurred DESC (most recent first)
- Used by callers to limit lookups to recent time windows

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet whose outbound transaction history to retrieve. Matched against SentTransactions.WalletId. |
| 2 | @CryptoId | int | YES | NULL | VERIFIED | Optional cryptocurrency filter. When NULL, auto-resolved from CustomerWalletsView. FK to Wallet.CryptoTypes. |
| 3 | @FromDate | datetime | YES | NULL | CODE-BACKED | Optional start date for the transaction history window. Filters Occurred >= @FromDate. |
| 4 | @ToDate | datetime | YES | NULL | CODE-BACKED | Optional end date for the transaction history window. Filters Occurred <= @ToDate. |
| 5 | Id (output) | bigint | NO | - | CODE-BACKED | Internal sent transaction ID. |
| 6 | BlockchainTransactionId (output) | nvarchar(100) | NO | - | CODE-BACKED | On-chain transaction hash for blockchain explorer lookup. |
| 7 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Source wallet (echo of @WalletId). |
| 8 | TransactionTypeId (output) | tinyint | YES | - | VERIFIED | Business purpose: 0=Redeem, 1=CustomerMoneyOut, 4=Funding, etc. See [Transaction Type](../../_glossary.md#transaction-type). |
| 9 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency sent. FK to Wallet.CryptoTypes. |
| 10 | BlockchainFee (output) | decimal(36,18) | NO | - | CODE-BACKED | Network fee in crypto native units. |
| 11 | CorrelationId (output) | uniqueidentifier | YES | - | CODE-BACKED | Business request correlation ID. Links to Wallet.Requests. |
| 12 | BeginDate (output) | datetime2(7) | YES | - | CODE-BACKED | Transaction broadcast timestamp. Aliased from SentTransactions.Occurred. Named 'BeginDate' for backward compatibility with consumers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId | Wallet.SentTransactions.WalletId | Lookup | Primary search key |
| @CryptoId (fallback) | Wallet.CustomerWalletsView | Lookup | Resolves CryptoId when not provided |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Reviews wallet send history for processing decisions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSentTransactionByWalletId (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Primary query - wallet's sent history |
| Wallet.CustomerWalletsView | View | Backward-compatible CryptoId resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Relies on SentTransactions NC index on WalletId for efficient filtering.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all sent transactions for a wallet
```sql
EXEC Wallet.GetSentTransactionByWalletId
    @WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678';
```

### 8.2 Get BTC transactions for a wallet in a date range
```sql
EXEC Wallet.GetSentTransactionByWalletId
    @WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678',
    @CryptoId = 1,
    @FromDate = '2026-01-01',
    @ToDate = '2026-04-15';
```

### 8.3 Direct equivalent with explicit crypto resolution
```sql
SELECT Id, BlockchainTransactionId, WalletId, TransactionTypeId,
       CryptoId, BlockchainFee, CorrelationId, Occurred AS BeginDate
FROM Wallet.SentTransactions WITH (NOLOCK)
WHERE WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678'
    AND CryptoId = 1
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSentTransactionByWalletId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetSentTransactionByWalletId.sql*
