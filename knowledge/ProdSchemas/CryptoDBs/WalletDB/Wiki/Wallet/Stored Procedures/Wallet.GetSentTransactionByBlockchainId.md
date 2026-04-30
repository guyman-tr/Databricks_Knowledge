# Wallet.GetSentTransactionByBlockchainId

> Retrieves a sent transaction's full details - including latest status and output addresses as JSON - by its on-chain blockchain transaction hash, used for transaction verification and blockchain-to-internal correlation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns sent transaction row by BlockchainTransactionId match |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure looks up a sent blockchain transaction by its on-chain transaction hash (BlockchainTransactionId). It returns the transaction's core details along with two enrichments: the latest blockchain confirmation status (from SentTransactionStatuses) and the output destinations/amounts as a JSON array (from SentTransactionOutputs, excluding fee outputs).

This is the primary interface for correlating an on-chain transaction hash back to eToro's internal records. It serves four service consumers: the redeem persistor (verifying redemption sends completed), the executer (checking broadcast status), the balance service (reconciling wallet balances), and the back-office API (operations lookup). When a blockchain transaction hash appears in logs, monitoring, or blockchain explorer, this procedure bridges from the external hash to the full internal context.

The procedure returns a single flattened row combining data from three tables in one call: the transaction itself, its latest status via correlated subquery, and its non-fee outputs as a JSON array. This avoids multiple round-trips for common lookup patterns.

---

## 2. Business Logic

### 2.1 Latest Status Resolution

**What**: Resolves the current blockchain confirmation status by selecting the most recent status event.

**Columns/Parameters Involved**: `SentTransactionStatuses.StatusId`, `SentTransactionStatuses.Id`

**Rules**:
- Uses correlated subquery: `SELECT TOP 1 StatusId ... ORDER BY Id DESC`
- Returns the most recent status event as a scalar value
- Status values: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError
- See [Transaction Status](../../_glossary.md#transaction-status). FK to Dictionary.TransactionStatus.
- If no status exists yet (edge case), returns NULL

### 2.2 Output JSON Aggregation

**What**: Aggregates non-fee transaction outputs into a JSON array for the caller.

**Columns/Parameters Involved**: `SentTransactionOutputs.ToAddress`, `Amount`, `EtoroFees`, `IsEtoroFee`

**Rules**:
- Filters: `IsEtoroFee = 0` excludes fee-dedicated outputs (UTXO change for fees)
- Returns JSON array via `FOR JSON AUTO` with columns: ToAddress, Amount, Fees (aliased from EtoroFees)
- If no non-fee outputs exist, returns empty array `'[]'` via ISNULL wrapper
- Multi-output transactions (Bitcoin UTXO) produce multiple array entries
- Single-output transactions (ETH, SOL) produce one array entry

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BlockchainId | varchar(100) | NO | - | VERIFIED | The on-chain transaction hash to look up. Matched against SentTransactions.BlockchainTransactionId. Format varies by blockchain: hex for ETH/BTC, base58 for SOL/XRP. |
| 2 | Id (output) | bigint | NO | - | CODE-BACKED | Internal auto-incrementing ID of the sent transaction record. FK target for SentTransactionStatuses and SentTransactionOutputs. |
| 3 | BlockchainTransactionId (output) | nvarchar(100) | NO | - | CODE-BACKED | Echo of the on-chain hash. Confirmed match for the input parameter. |
| 4 | WalletId (output) | uniqueidentifier | NO | - | VERIFIED | Source wallet the transaction was sent from. For customer withdrawals, this is the customer's wallet. For redemptions, this is the omnibus/redeem wallet. |
| 5 | CryptoId (output) | int | NO | - | VERIFIED | Cryptocurrency sent. FK to Wallet.CryptoTypes. Determines the blockchain network and fee denomination. |
| 6 | Occurred (output) | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp when the transaction was broadcast to the blockchain. |
| 7 | CorrelationId (output) | uniqueidentifier | YES | - | VERIFIED | Links to the parent business request in Wallet.Requests.CorrelationId. Enables end-to-end tracing from blockchain hash to business operation. |
| 8 | TransactionTypeId (output) | tinyint | YES | - | VERIFIED | Business purpose: 0=Redeem, 1=CustomerMoneyOut, 4=Funding, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 13=ManualUserMoneyOut, etc. See [Transaction Type](../../_glossary.md#transaction-type). FK to Dictionary.TransactionTypes. |
| 9 | BlockchainFee (output) | decimal(36,18) | NO | - | CODE-BACKED | Network fee paid in the crypto's native units. Recorded after on-chain confirmation. |
| 10 | StatusId (output) | tinyint | YES | - | VERIFIED | Latest blockchain confirmation status: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. Resolved via correlated subquery on SentTransactionStatuses (TOP 1 ORDER BY Id DESC). See [Transaction Status](../../_glossary.md#transaction-status). |
| 11 | Outputs (output) | nvarchar(max) | NO | - | CODE-BACKED | JSON array of non-fee transaction outputs: `[{"ToAddress":"...","Amount":0.5,"Fees":0.001}, ...]`. Excludes fee-dedicated outputs (IsEtoroFee=1). Returns `'[]'` if no non-fee outputs exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BlockchainId | Wallet.SentTransactions.BlockchainTransactionId | Lookup | Primary search key - on-chain hash |
| StatusId | Wallet.SentTransactionStatuses | Subquery | Latest status event for the transaction |
| Outputs | Wallet.SentTransactionOutputs | Subquery (JSON) | Non-fee output addresses and amounts |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemPersistorUser | - | EXECUTE | Verifies redemption sends completed on-chain |
| ExecuterUser | - | EXECUTE | Checks broadcast status after submission |
| BalanceUser | - | EXECUTE | Reconciles wallet balances against blockchain |
| BackApiUser | - | EXECUTE | Operations lookup by transaction hash |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSentTransactionByBlockchainId (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
|     +-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
      +-- Wallet.SentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Primary lookup by BlockchainTransactionId |
| Wallet.SentTransactionStatuses | Table | Correlated subquery for latest status |
| Wallet.SentTransactionOutputs | Table | Correlated subquery for output JSON |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemPersistorUser | Service Account | EXECUTE grant |
| ExecuterUser | Service Account | EXECUTE grant |
| BalanceUser | Service Account | EXECUTE grant |
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Relies on SentTransactions unique index on BlockchainTransactionId for efficient lookup.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up a transaction by its blockchain hash
```sql
EXEC Wallet.GetSentTransactionByBlockchainId
    @BlockchainId = '37cqS8sdJALVD5bf2Pz1nX7qJfE4hGrM4pWknD8XyT1';
```

### 8.2 Parse the JSON outputs in the result
```sql
-- After calling the procedure, parse Outputs JSON
DECLARE @Outputs NVARCHAR(MAX) = '[]'; -- from result
SELECT *
FROM OPENJSON(@Outputs)
WITH (
    ToAddress NVARCHAR(512),
    Amount DECIMAL(36,18),
    Fees DECIMAL(36,18)
);
```

### 8.3 Verify a transaction hash exists and check its status
```sql
-- Direct equivalent of what the procedure does
SELECT st.Id, st.BlockchainTransactionId, st.WalletId, st.CorrelationId,
    (SELECT TOP 1 sts.StatusId
     FROM Wallet.SentTransactionStatuses sts WITH (NOLOCK)
     WHERE sts.SentTransactionId = st.Id
     ORDER BY sts.Id DESC) AS LatestStatus
FROM Wallet.SentTransactions st WITH (NOLOCK)
WHERE st.BlockchainTransactionId = '37cqS8sdJALVD5bf2Pz1nX7qJfE4hGrM4pWknD8XyT1';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSentTransactionByBlockchainId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetSentTransactionByBlockchainId.sql*
