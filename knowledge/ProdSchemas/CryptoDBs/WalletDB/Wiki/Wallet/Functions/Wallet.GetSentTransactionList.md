# Wallet.GetSentTransactionList

> Returns a paginated list of outgoing crypto send transactions for a customer wallet, including Travel Rule compliance status and blockchain activation records.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per send request (CorrelationId) plus additional rows for blockchain activation transactions |

---

## 1. Business Meaning

This function powers the outgoing crypto send transaction history in the eToro wallet. When a customer sends cryptocurrency to an external address, the platform creates a send request (`RequestTypeId = 1`) and subsequently records on-chain outputs in `SentTransactions` and `SentTransactionOutputs`. This function assembles both the request-level intent and the settled blockchain data into a unified row for each send event.

Beyond standard send transactions, the function performs a second INSERT to append blockchain wallet activation records (`TransactionTypeId = 10`). Some blockchains (e.g., Cardano, Algorand) require an initial on-chain activation fee before a wallet can transact. These activations are not initiated by a customer request but are still debits from the customer's wallet balance, so they must appear in the transaction history. The Travel Rule compliance dimension is also surfaced: if a send is subject to regulatory Travel Rule requirements, `TravelRuleRequired = 1` and `TravelRuleStatus` reflects the current compliance workflow state.

---

## 2. Business Logic

**Five CTEs + one additional INSERT block:**

- **`raw_requests`** — Top `@RecordsLimit` rows from `Wallet.Requests` for `RequestTypeId = 1`, filtered by `@Gcid`, optional `@CryptoId`, and date range, ordered by `Timestamp DESC`. Latest status name resolved via `OUTER APPLY TOP 1`. Status flags (`IsVerified`, `IsConfirmed`, `ErrorDetailsJson`) aggregated via `OUTER APPLY MAX CASE WHEN` across all `RequestStatuses` rows.
- **`requests`** — Parses `raw_requests.DetailsJson` via `OPENJSON` for `Amount`, `ToAddress`, and `BlockchainTransactionId`. Derives Status: `2` (TransactionVerified), `1` (TransactionConfirmed), `3` (Error), `0` (pending).
- **`transactions`** — Aggregates `SentTransactions` (non-fee outputs only, via `EXISTS` filter on `SentTransactionOutputs.IsEtoroFee = 0`) for actual TX ID and summed blockchain fee.
- **`outputs`** — Aggregates `SentTransactionOutputs` (non-fee) joined to `SentTransactions` for total sent `Amount` and `EtoroFee` by `CorrelationId`.
- **`travelRuleStatuses`** — Uses `ROW_NUMBER()` window function over `TransactionTravelRuleStatuses` to get the most recent Travel Rule status name per `TransactionTravelRuleInformationId`.

**First INSERT**: PRIMARY send transactions. Amount is negative: if outputs exist, uses `-(Amount + EtoroFee + BlockchainFee)`; otherwise falls back to `-r.Amount`. `TransactionError` only populated when `Status = 3`. `TravelRuleRequired` is 0/1 based on existence of a `TransactionTravelRuleInformation` record.

**Second INSERT**: BLOCKCHAIN ACTIVATION records from `CustomerWalletsView JOIN SentTransactions` where `TransactionTypeId = 10`. Status comes from the latest `SentTransactionStatuses` record. `TransactionType = 6`. No travel rule data for activations.

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
| `@RecordsLimit` | INT | 10000 | Maximum rows returned (applies to send requests only, not activations) |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `CorrelationId` | UNIQUEIDENTIFIER | Cross-system correlation key (NULL for activations without requests) |
| `BeginDate` | DATETIME2(7) | Request timestamp for sends; `SentTransactions.Occurred` for activations |
| `Amount` | DECIMAL(36,18) | Crypto amount as negative debit (total of sent + fees for settled; request amount for pending) |
| `Status` | INT | 0=Pending, 1=Confirmed, 2=Verified/Completed, 3=Error |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain transaction ID |
| `Address` | NVARCHAR(MAX) | Destination address from request JSON |
| `TransactionType` | INT | 0=Send, 6=Blockchain Activation |
| `EtoroFee` | DECIMAL(36,18) | eToro platform fee from SentTransactionOutputs |
| `BlockchainFees` | DECIMAL(36,18) | Actual blockchain fee paid |
| `TransactionError` | VARCHAR(MAX) | Error details JSON (populated only when Status = 3) |
| `TravelRuleRequired` | BIT | 1 if Travel Rule compliance is required for this send |
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
| `TransactionTravelRuleInformation` | Wallet | Table | Travel Rule requirement flag per request |
| `TransactionTravelRuleStatuses` | Wallet | Table | Travel Rule compliance status history |
| `TravelRuleStatuses` | Dictionary | Table | Travel Rule status name lookup |
| `CustomerWalletsView` | Wallet | View | Wallet lookup for activation records |

### 5.2 Referenced By

| Object | Type | Notes |
|--------|------|-------|
| Wallet send transaction list API procedures | Stored Procedure | Customer-facing send history endpoint |
| Back-office send and Travel Rule reports | Ad-hoc | Compliance investigation queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSentTransactionList
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

- Wallet API send transaction list stored procedures
- Back-office Travel Rule compliance reporting queries

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. Get all outgoing sends for a customer in the last 30 days:**
```sql
SELECT *
FROM Wallet.GetSentTransactionList(
    123456, NULL,
    DATEADD(DAY, -30, GETUTCDATE()),
    GETUTCDATE(),
    500
)
ORDER BY BeginDate DESC;
```

**2. Find sends subject to Travel Rule compliance:**
```sql
SELECT CorrelationId, BeginDate, Amount, Status,
       TravelRuleRequired, TravelRuleStatus
FROM Wallet.GetSentTransactionList(
    123456, NULL,
    '2025-01-01', NULL,
    10000
)
WHERE TravelRuleRequired = 1;
```

**3. Retrieve blockchain activation records only:**
```sql
SELECT CorrelationId, BeginDate, Amount, BlockchainFees
FROM Wallet.GetSentTransactionList(
    123456, 1,   -- BTC CryptoId = 1
    NULL, NULL, 10000
)
WHERE TransactionType = 6;  -- Activation type
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSentTransactionList | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetSentTransactionList.sql*
