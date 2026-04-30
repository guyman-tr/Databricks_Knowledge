# Wallet.GetSentTransactionListV2

> Returns a paginated list of outgoing crypto send transactions for a customer wallet (V2 API variant), with identical logic to V1 including Travel Rule compliance status and blockchain activation records.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per send request (CorrelationId) plus additional rows for blockchain activation transactions |

---

## 1. Business Meaning

`GetSentTransactionListV2` is the versioned successor to `GetSentTransactionList`, serving the V2 wallet API's outgoing transaction history endpoint. It covers the same business scenario as V1: presenting customers with a complete history of their outgoing crypto sends, including the current on-chain status, fee breakdown, and Travel Rule compliance state.

Like all V2 function variants in this codebase, the function was forked to allow the V2 API endpoint to evolve independently from V1. At the time of creation, the SQL body is functionally identical to V1: the same five CTEs (raw_requests, requests, transactions, outputs, travelRuleStatuses), the same dual-INSERT pattern for send requests and blockchain activation records, and the same `TravelRuleRequired`/`TravelRuleStatus` compliance columns. Any future divergence between V1 and V2 (e.g., new output columns, changed status logic) can be made to either version without impacting the other.

---

## 2. Business Logic

Identical to `GetSentTransactionList`:

- **`raw_requests`** — Top `@RecordsLimit` rows from `Wallet.Requests` for `RequestTypeId = 1`, ordered by `Timestamp DESC`. Latest status via `OUTER APPLY TOP 1`. `IsVerified`, `IsConfirmed`, and `ErrorDetailsJson` via `OUTER APPLY MAX CASE WHEN` aggregation across all status rows.
- **`requests`** — OPENJSON parse of `DetailsJson` for `Amount`, `ToAddress`, `BlockchainTransactionId`. Status: `2` (Verified), `1` (Confirmed), `3` (Error), `0` (pending).
- **`transactions`** — `SentTransactions` aggregated by `CorrelationId + BlockChainTransactionId` (non-fee outputs only) for actual fee and TX ID.
- **`outputs`** — `SentTransactionOutputs` (non-fee) joined to `SentTransactions` for total `Amount` and `EtoroFee`.
- **`travelRuleStatuses`** — Latest Travel Rule status per `TransactionTravelRuleInformationId` via `ROW_NUMBER()`.

**First INSERT**: Send transactions with negative amounts, status logic, and Travel Rule fields.
**Second INSERT**: Blockchain activation records (`TransactionTypeId = 10`) via `CustomerWalletsView JOIN SentTransactions`.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

### Parameters (IN)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `@Gcid` | BIGINT | required | Customer global customer ID |
| `@CryptoId` | INT | required | Filter by crypto (NULL = all) |
| `@BeginDateAfter` | DATETIME2(7) | required | Inclusive lower bound on request timestamp (NULL = 2000-01-01) |
| `@BeginDateBefore` | DATETIME2(7) | required | Exclusive upper bound on request timestamp (NULL = 2100-01-01) |
| `@RecordsLimit` | INT | 10000 | Maximum rows returned (send requests only; activations are unthrottled) |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `CorrelationId` | UNIQUEIDENTIFIER | Cross-system correlation key |
| `BeginDate` | DATETIME2(7) | Request timestamp (sends) or SentTransactions.Occurred (activations) |
| `Amount` | DECIMAL(36,18) | Negative crypto debit (settled: -(Amount+EtoroFee+BlockchainFee); pending: -request Amount) |
| `Status` | INT | 0=Pending, 1=Confirmed, 2=Verified/Completed, 3=Error |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain transaction ID |
| `Address` | NVARCHAR(MAX) | Destination address from request JSON |
| `TransactionType` | INT | 0=Send, 6=Blockchain Activation |
| `EtoroFee` | DECIMAL(36,18) | eToro fee from SentTransactionOutputs |
| `BlockchainFees` | DECIMAL(36,18) | Actual blockchain fee |
| `TransactionError` | VARCHAR(MAX) | Error JSON (Status = 3 only) |
| `TravelRuleRequired` | BIT | 1 if Travel Rule applies to this send |
| `TravelRuleStatus` | VARCHAR(64) | Current Travel Rule compliance status name |

---

## 5. Relationships

### 5.1 References To

| Object | Schema | Type | Purpose |
|--------|--------|------|---------|
| `Requests` | Wallet | Table | Send request source (RequestTypeId = 1) |
| `RequestStatuses` | Wallet | Table | Status flag aggregation |
| `RequestStatuses` | Dictionary | Table | Status name lookup |
| `SentTransactions` | Wallet | Table | Blockchain TX ID, fees, activation records |
| `SentTransactionOutputs` | Wallet | Table | Non-fee output amounts and eToro fees |
| `SentTransactionStatuses` | Wallet | Table | Activation transaction status |
| `TransactionTravelRuleInformation` | Wallet | Table | Travel Rule requirement flag |
| `TransactionTravelRuleStatuses` | Wallet | Table | Travel Rule compliance status history |
| `TravelRuleStatuses` | Dictionary | Table | Travel Rule status name lookup |
| `CustomerWalletsView` | Wallet | View | Wallet lookup for activation records |

### 5.2 Referenced By

| Object | Type | Notes |
|--------|------|-------|
| Wallet V2 send transaction list API procedures | Stored Procedure | V2 customer-facing send history endpoint |
| Back-office Travel Rule compliance reports | Ad-hoc | Compliance investigation queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSentTransactionListV2
├── Wallet.Requests
├── Wallet.RequestStatuses → Dictionary.RequestStatuses
├── Wallet.SentTransactions
│   ├── Wallet.SentTransactionOutputs
│   └── Wallet.SentTransactionStatuses
├── Wallet.TransactionTravelRuleInformation
├── Wallet.TransactionTravelRuleStatuses → Dictionary.TravelRuleStatuses
└── Wallet.CustomerWalletsView
```

### 6.1 Objects This Depends On

- `Wallet.Requests`
- `Wallet.RequestStatuses`
- `Dictionary.RequestStatuses`
- `Wallet.SentTransactions`
- `Wallet.SentTransactionOutputs`
- `Wallet.SentTransactionStatuses`
- `Wallet.TransactionTravelRuleInformation`
- `Wallet.TransactionTravelRuleStatuses`
- `Dictionary.TravelRuleStatuses`
- `Wallet.CustomerWalletsView`

### 6.2 Objects That Depend On This

- Wallet API V2 send transaction list stored procedures
- Back-office Travel Rule compliance reporting

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. All outgoing sends for a customer via V2 API path:**
```sql
SELECT *
FROM Wallet.GetSentTransactionListV2(
    123456, NULL,
    DATEADD(DAY, -30, GETUTCDATE()),
    GETUTCDATE(),
    500
)
ORDER BY BeginDate DESC;
```

**2. Verify parity between V1 and V2:**
```sql
SELECT CorrelationId, Status, Amount, BlockchainFees, TravelRuleStatus
FROM Wallet.GetSentTransactionList(123456, NULL, '2025-01-01', NULL, 100)
EXCEPT
SELECT CorrelationId, Status, Amount, BlockchainFees, TravelRuleStatus
FROM Wallet.GetSentTransactionListV2(123456, NULL, '2025-01-01', NULL, 100);
```

**3. Travel Rule pending items for a customer:**
```sql
SELECT CorrelationId, BeginDate, Amount, TravelRuleStatus
FROM Wallet.GetSentTransactionListV2(
    123456, NULL, '2025-01-01', NULL, 10000
)
WHERE TravelRuleRequired = 1
  AND TravelRuleStatus NOT IN ('Approved', 'Completed');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSentTransactionListV2 | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetSentTransactionListV2.sql*
