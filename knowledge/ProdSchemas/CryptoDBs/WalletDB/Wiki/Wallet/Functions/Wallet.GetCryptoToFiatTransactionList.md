# Wallet.GetCryptoToFiatTransactionList

> Returns a paginated list of crypto-to-fiat sell transactions for a customer wallet, merging request data with settled blockchain outputs and supporting both customer-facing and back-office report modes.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per crypto-to-fiat request (CorrelationId) |

---

## 1. Business Meaning

When an eToro wallet customer sells cryptocurrency for fiat currency, the platform creates a request record with `RequestTypeId IN (7, 9)`. Type 7 represents a standard crypto-to-fiat sell; type 9 represents a related variant (e.g., instant sell or secondary pathway). This function aggregates those requests with their eventual blockchain settlement and fiat funding outcome to produce the transaction history shown in the customer's wallet UI.

The function has a dual-mode design controlled by the `@ForReport` flag. When called by the customer API (`@ForReport = 0`), the `AdditionalDetails` column is suppressed (NULL). When called from a back-office reporting context (`@ForReport = 1`), `AdditionalDetails` is populated with the raw `FiatAccountFunded` status JSON, giving compliance and operations teams access to the full settlement payload without a separate query.

---

## 2. Business Logic

**Three CTEs and two OPENJSON passes:**

- **`raw_requests`** — Top `@RecordsLimit` rows from `Wallet.Requests` for `RequestTypeId IN (7, 9)`, filtered by `@Gcid`, optional `@CryptoId`, and date range. The latest status name is resolved via `OUTER APPLY TOP 1`. The `FiatAccountFunded` status JSON (settlement record) is separately captured via a second `OUTER APPLY`. An `EXISTS` subquery determines `IsDone` (whether a 'Done' status ever existed).
- **`requests`** — Parses both `r.DetailsJson` and `r.FiatFundedDetailsJson` via `OPENJSON` to extract: `CryptoAmount`, `FiatId`, estimated fiat amount, estimated blockchain fee, estimated and final crypto-to-fiat rates, and `ConversionFeePercentage`. Status is: `2` (Done/Completed), `3` (Error), `0` (in-progress). `EtoroFee` = `EstimatedFiatAmount * ConversionFeePercentage / 100`.
- **`transactions`** — Joins `SentTransactions` to `SentTransactionOutputs` (non-fee outputs only, `IsEtoroFee = 0`) to get the actual blockchain TX ID, destination address, actual blockchain fee, and total sent crypto amount, grouped by `CorrelationId`.

**Final SELECT**: LEFT JOINs requests to transactions on `CorrelationId`. `CryptoAmount` is returned as negative (debit). `FiatAmount` and `ExchangeRate` use final settled values when `Status = 2`, otherwise estimates. `TransactionError` is fetched inline via a subquery only when `Status = 3`.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

### Parameters (IN)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `@Gcid` | BIGINT | required | Customer global customer ID |
| `@CryptoId` | INT | required | Filter by specific crypto ID (NULL = all) |
| `@BeginDateAfter` | DATETIME2(7) | required | Inclusive lower bound on request timestamp (NULL = 2000-01-01) |
| `@BeginDateBefore` | DATETIME2(7) | required | Exclusive upper bound on request timestamp (NULL = 2100-01-01) |
| `@RecordsLimit` | INT | 10000 | Maximum rows returned |
| `@ForReport` | BIT | 0 | 0 = customer API (suppress AdditionalDetails); 1 = back-office report mode |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `CorrelationId` | UNIQUEIDENTIFIER | Cross-system correlation key |
| `BeginDate` | DATETIME2(7) | Timestamp the sell request was initiated |
| `CryptoAmount` | DECIMAL(36,18) | Crypto sold (returned as negative value) |
| `FiatAmount` | DECIMAL(36,18) | Fiat received; final if completed, estimated otherwise |
| `FiatId` | TINYINT | Fiat currency identifier |
| `Status` | INT | 0=Pending, 2=Completed, 3=Error |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain transaction ID |
| `Address` | NVARCHAR(1024) | Destination blockchain address |
| `TransactionType` | INT | RequestTypeId (7 or 9) |
| `EtoroFee` | DECIMAL(36,18) | Estimated platform fee (EstimatedFiatAmount * FeePercentage / 100) |
| `BlockchainFees` | DECIMAL(36,18) | Actual blockchain fee (or estimated if not yet settled) |
| `ExchangeRate` | DECIMAL(36,18) | Crypto-to-fiat rate; final if completed, estimated otherwise |
| `AdditionalDetails` | NVARCHAR(1000) | FiatAccountFunded JSON (populated only when @ForReport = 1) |
| `TransactionError` | VARCHAR(MAX) | JSON error details (populated only when Status = 3) |

---

## 5. Relationships

### 5.1 References To

| Object | Schema | Type | Purpose |
|--------|--------|------|---------|
| `Requests` | Wallet | Table | Primary request source (RequestTypeId 7, 9) |
| `RequestStatuses` | Wallet | Table | Latest status and FiatAccountFunded resolution |
| `RequestStatuses` | Dictionary | Table | Status name lookup |
| `SentTransactions` | Wallet | Table | Blockchain TX ID and fee |
| `SentTransactionOutputs` | Wallet | Table | Non-fee outputs for crypto amount and destination address |

### 5.2 Referenced By

| Object | Type | Notes |
|--------|------|-------|
| Wallet transaction list API procedures | Stored Procedure | Customer-facing sell transaction history endpoint |
| Back-office reporting procedures | Stored Procedure | Called with @ForReport = 1 for compliance/reconciliation reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetCryptoToFiatTransactionList
├── Wallet.Requests
├── Wallet.RequestStatuses → Dictionary.RequestStatuses
└── Wallet.SentTransactions
    └── Wallet.SentTransactionOutputs
```

### 6.1 Objects This Depends On

- `Wallet.Requests`
- `Wallet.RequestStatuses`
- `Dictionary.RequestStatuses`
- `Wallet.SentTransactions`
- `Wallet.SentTransactionOutputs`

### 6.2 Objects That Depend On This

- Wallet API transaction list stored procedures
- Back-office crypto-to-fiat reporting procedures

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. Get all crypto-to-fiat sells for a customer in the last 60 days:**
```sql
SELECT *
FROM Wallet.GetCryptoToFiatTransactionList(
    123456, NULL,
    DATEADD(DAY, -60, GETUTCDATE()),
    GETUTCDATE(),
    1000,
    0
)
ORDER BY BeginDate DESC;
```

**2. Back-office report mode — include AdditionalDetails for reconciliation:**
```sql
SELECT CorrelationId, BeginDate, CryptoAmount, FiatAmount, FiatId,
       Status, ExchangeRate, AdditionalDetails
FROM Wallet.GetCryptoToFiatTransactionList(
    123456, NULL,
    '2025-01-01', '2026-01-01',
    10000,
    1   -- @ForReport = 1
)
WHERE Status = 2;
```

**3. Retrieve failed sells with error details:**
```sql
SELECT CorrelationId, BeginDate, CryptoAmount, TransactionError
FROM Wallet.GetCryptoToFiatTransactionList(
    123456, NULL, '2024-01-01', NULL, 10000, 0
)
WHERE Status = 3
  AND TransactionError IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetCryptoToFiatTransactionList | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetCryptoToFiatTransactionList.sql*
