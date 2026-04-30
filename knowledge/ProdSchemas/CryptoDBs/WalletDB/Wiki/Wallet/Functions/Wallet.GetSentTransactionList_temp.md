# Wallet.GetSentTransactionList_temp

> Experimental/candidate replacement for GetSentTransactionList, with identical send and activation logic but omitting the ORDER BY clause from the raw_requests CTE for query optimizer evaluation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per send request (CorrelationId) plus additional rows for blockchain activation transactions |

---

## 1. Business Meaning

`GetSentTransactionList_temp` is a development/staging variant of `GetSentTransactionList`, following the eToro WalletDB convention of using a `_temp` suffix to denote a function that is under evaluation but not yet promoted to production status. It was created to test a refactored version of the send transaction list query — most likely a query optimizer experiment focused on whether removing the `ORDER BY` from the `raw_requests` CTE improves execution plan quality when the enclosing TVF already controls result ordering at the API layer.

The business output of this function is identical to V1 and V2: the same two-INSERT pattern covering standard send transactions and blockchain activation records, the same Travel Rule compliance columns, and the same negative-amount convention for debits. It should not be called by production application code without validation and promotion to a named version.

---

## 2. Business Logic

Five CTEs mirror V1/V2 exactly, with one notable structural difference:

- **`raw_requests`** — Top `@RecordsLimit` from `Wallet.Requests` for `RequestTypeId = 1`, filtered by `@Gcid`, optional `@CryptoId`, and date range. Latest status via `OUTER APPLY TOP 1`. `IsVerified`, `IsConfirmed`, `ErrorDetailsJson` via `OUTER APPLY MAX CASE WHEN`. **Key difference from V1/V2: no `ORDER BY r.Timestamp DESC` in this CTE.** The `TOP` without `ORDER BY` produces non-deterministic row selection, which may be intentional for optimizer testing.
- **`requests`** — OPENJSON parse of `DetailsJson` for `Amount`, `ToAddress`, `BlockchainTransactionId`. Status: `2` (Verified), `1` (Confirmed), `3` (Error), `0` (pending).
- **`transactions`** — `SentTransactions` aggregated (non-fee outputs) for TX ID and fee.
- **`outputs`** — `SentTransactionOutputs` (non-fee) for total amount and eToro fee.
- **`travelRuleStatuses`** — Latest Travel Rule status via `ROW_NUMBER()`.

**First INSERT**: Send transactions with negative amounts and Travel Rule fields.
**Second INSERT**: Blockchain activation records (`TransactionTypeId = 10`).

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
| `@RecordsLimit` | INT | 10000 | Maximum rows returned (non-deterministic without ORDER BY in raw_requests) |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `CorrelationId` | UNIQUEIDENTIFIER | Cross-system correlation key |
| `BeginDate` | DATETIME2(7) | Request timestamp (sends) or SentTransactions.Occurred (activations) |
| `Amount` | DECIMAL(36,18) | Negative crypto debit |
| `Status` | INT | 0=Pending, 1=Confirmed, 2=Verified/Completed, 3=Error |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain transaction ID |
| `Address` | NVARCHAR(MAX) | Destination address from request JSON |
| `TransactionType` | INT | 0=Send, 6=Blockchain Activation |
| `EtoroFee` | DECIMAL(36,18) | eToro fee from SentTransactionOutputs |
| `BlockchainFees` | DECIMAL(36,18) | Actual blockchain fee |
| `TransactionError` | VARCHAR(MAX) | Error JSON (Status = 3 only) |
| `TravelRuleRequired` | BIT | 1 if Travel Rule applies |
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
| Development/test harnesses | Ad-hoc | Performance and correctness testing before promotion to V1/V2 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSentTransactionList_temp
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

- No known production dependents; development/test use only

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. Basic development test call:**
```sql
SELECT *
FROM Wallet.GetSentTransactionList_temp(
    123456, NULL,
    DATEADD(DAY, -7, GETUTCDATE()),
    GETUTCDATE(),
    100
);
```

**2. Validate row-set parity against production V1 (note: ordering may differ due to no ORDER BY):**
```sql
SELECT CorrelationId, Status, Amount, BlockchainFees
FROM Wallet.GetSentTransactionList(123456, NULL, '2025-06-01', '2025-07-01', 200)
EXCEPT
SELECT CorrelationId, Status, Amount, BlockchainFees
FROM Wallet.GetSentTransactionList_temp(123456, NULL, '2025-06-01', '2025-07-01', 200);
```

**3. Check for Travel Rule rows in temp output:**
```sql
SELECT CorrelationId, TravelRuleRequired, TravelRuleStatus
FROM Wallet.GetSentTransactionList_temp(
    123456, NULL, '2025-01-01', NULL, 10000
)
WHERE TravelRuleRequired = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSentTransactionList_temp | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetSentTransactionList_temp.sql*
