# Wallet.GetSentTransactionByCorrelationId

> Retrieves sent transaction details by business correlation ID with a fallback mechanism that synthesizes a virtual transaction record from the request layer when no actual blockchain transaction exists yet.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns transaction rows by CorrelationId + CryptoId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves sent transaction details by business correlation ID and cryptocurrency. It is the primary interface for services that need to check the status of a send operation using the business-level CorrelationId (the same ID used in Wallet.Requests). Five service consumers use it: the wallet middleware, conversion, staking, redeem scheduler, and billing notification services.

The procedure's distinguishing feature is its fallback mechanism. When a CorrelationId has a matching sent transaction in `Wallet.SentTransactions`, the procedure returns that record enriched with its latest status and an IsEtoroFee flag. However, when no sent transaction exists yet (the request was created but blockchain execution hasn't started), the procedure falls back to the request layer: it finds the matching request in `Wallet.Requests`, resolves the customer's wallet via `CustomerWalletsView`, and synthesizes a virtual transaction record with a derived status (status 5 if the request failed, status 0 otherwise). This ensures callers always get a response regardless of where the operation is in its lifecycle.

Data flows through two paths: the primary path joins SentTransactions to CustomerWalletsView and enriches with the latest SentTransactionStatuses status and an IsEtoroFee flag from SentTransactionOutputs. The fallback path joins Requests to CustomerWalletsView and derives a status from the latest RequestStatuses entry.

---

## 2. Business Logic

### 2.1 Two-Path Lookup with Fallback

**What**: Ensures callers always get a response by falling back to the request layer when no blockchain transaction exists.

**Columns/Parameters Involved**: `@CorrelationId`, `@CryptoId`, `SentTransactions`, `Requests`

**Rules**:
- Primary path: SELECT from SentTransactions WHERE CorrelationId = @CorrelationId AND CryptoId = @CryptoId
- If primary path returns 0 rows, fallback path activates
- Fallback: SELECT from Requests WHERE CorrelationId = @CorrelationId, joined to CustomerWalletsView for wallet details
- Fallback returns WalletId (from CustomerWalletsView), request timestamp, and a derived status

**Diagram**:
```
@CorrelationId + @CryptoId
        |
        v
  SentTransactions
  matched? -------YES-------> Return enriched transaction
        |                     (+ latest status + IsEtoroFee flag)
        NO
        |
        v
  Requests + CustomerWalletsView
        |
        v
  Return virtual record
  (WalletId, timestamp, derived status)
```

### 2.2 IsEtoroFee Detection

**What**: Determines whether a sent transaction is entirely an eToro fee payment (no value-transfer outputs).

**Columns/Parameters Involved**: `SentTransactionOutputs.IsEtoroFee`

**Rules**:
- If COUNT of non-fee outputs (IsEtoroFee = 0) for this transaction is 0, then IsEtoroFee = 1
- Otherwise IsEtoroFee = 0 (transaction has at least one value-transfer output)
- Used by callers to distinguish fee-only transactions from actual sends

### 2.3 Fallback Status Derivation

**What**: When no sent transaction exists, derives a status from the request's lifecycle.

**Columns/Parameters Involved**: `RequestStatuses.RequestStatusId`

**Rules**:
- Gets the latest RequestStatusId for the request (TOP 1 ORDER BY Timestamp DESC)
- If RequestStatusId = 2 (Failed), returns StatusId = 5 (PermanentError equivalent)
- Otherwise returns StatusId = 0 (Pending equivalent)
- This maps from the request lifecycle domain to the transaction status domain

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID linking to Wallet.Requests.CorrelationId. The primary search key identifying the business operation. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency filter. FK to Wallet.CryptoTypes. Combined with CorrelationId for precise lookup. Also used to resolve the customer's wallet via CustomerWalletsView in the fallback path. |
| 3 | Id (output) | bigint | YES | - | CODE-BACKED | Internal ID of the sent transaction. NULL in fallback path (no real transaction exists). |
| 4 | BlockchainTransactionId (output) | nvarchar(100) | YES | - | CODE-BACKED | On-chain hash. NULL in fallback path. |
| 5 | BlockchainFee (output) | decimal(36,18) | YES | - | CODE-BACKED | Network fee in crypto native units. NULL in fallback path. |
| 6 | WalletId (output) | uniqueidentifier | YES | - | VERIFIED | Source wallet. In primary path, from SentTransactions. In fallback path, resolved via CustomerWalletsView using Gcid + CryptoId. |
| 7 | Occurred (output) | datetime2(7) | YES | - | CODE-BACKED | Transaction broadcast time (primary path) or request creation time (fallback path). |
| 8 | CorrelationId (output) | uniqueidentifier | YES | - | CODE-BACKED | Echo of the correlation ID. Always matches @CorrelationId. |
| 9 | TransactionTypeId (output) | tinyint | YES | - | CODE-BACKED | Business purpose of the transaction. NULL in fallback path. See [Transaction Type](../../_glossary.md#transaction-type). |
| 10 | StatusId (output) | tinyint | YES | - | VERIFIED | Transaction status. Primary path: latest SentTransactionStatuses.StatusId (0=Pending through 6=WavedError). Fallback path: 5 if request failed, 0 otherwise. See [Transaction Status](../../_glossary.md#transaction-status). |
| 11 | IsEtoroFee (output) | bit | YES | - | CODE-BACKED | Whether this transaction is entirely a fee payment with no value-transfer outputs. 1=fee-only transaction, 0=has value outputs. Primary path only; 0 in fallback path. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.SentTransactions.CorrelationId | Lookup | Primary search path |
| @CorrelationId | Wallet.Requests.CorrelationId | Fallback Lookup | Fallback when no sent transaction exists |
| @CryptoId | Wallet.CustomerWalletsView.CryptoId | JOIN | Resolves wallet in both paths |
| StatusId | Wallet.SentTransactionStatuses | Subquery | Latest transaction status (primary path) |
| StatusId | Wallet.RequestStatuses | Subquery | Latest request status (fallback path) |
| IsEtoroFee | Wallet.SentTransactionOutputs | Subquery | Count of non-fee outputs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WalletMiddlewareUser | - | EXECUTE | Wallet API middleware checks send status |
| ConversionUser | - | EXECUTE | Conversion service verifies send legs |
| StakingUser | - | EXECUTE | Staking service checks staking transaction status |
| RedeemSchedulerUser | - | EXECUTE | Redemption scheduler verifies send execution |
| BillingNotificationUser | - | EXECUTE | Billing service correlates transactions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSentTransactionByCorrelationId (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Primary lookup by CorrelationId + CryptoId |
| Wallet.SentTransactionStatuses | Table | Correlated subquery for latest transaction status |
| Wallet.SentTransactionOutputs | Table | Correlated subquery for IsEtoroFee detection |
| Wallet.CustomerWalletsView | View | JOINed to resolve WalletId from CryptoId in both paths |
| Wallet.Requests | Table | Fallback lookup when no sent transaction exists |
| Wallet.RequestStatuses | Table | Correlated subquery for request status in fallback path |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| WalletMiddlewareUser | Service Account | EXECUTE grant |
| ConversionUser | Service Account | EXECUTE grant |
| StakingUser | Service Account | EXECUTE grant |
| RedeemSchedulerUser | Service Account | EXECUTE grant |
| BillingNotificationUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up a sent transaction by correlation ID and crypto
```sql
EXEC Wallet.GetSentTransactionByCorrelationId
    @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @CryptoId = 1;  -- BTC
```

### 8.2 Understand which path returned the result
```sql
-- If Id IS NOT NULL and BlockchainTransactionId IS NOT NULL: primary path (real transaction)
-- If Id IS NULL: fallback path (request exists but no blockchain execution yet)
EXEC Wallet.GetSentTransactionByCorrelationId
    @CorrelationId = 'NEW-REQUEST-GUID',
    @CryptoId = 1;
```

### 8.3 Trace a correlation ID through the full pipeline
```sql
-- Step 1: Check the request
SELECT * FROM Wallet.Requests WITH (NOLOCK) WHERE CorrelationId = 'YOUR-GUID';
-- Step 2: Check if a sent transaction exists
EXEC Wallet.GetSentTransactionByCorrelationId @CorrelationId = 'YOUR-GUID', @CryptoId = 1;
-- Step 3: If it exists, check outputs
SELECT * FROM Wallet.SentTransactionOutputs WITH (NOLOCK)
WHERE SentTransactionId = /* Id from step 2 */;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSentTransactionByCorrelationId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetSentTransactionByCorrelationId.sql*
