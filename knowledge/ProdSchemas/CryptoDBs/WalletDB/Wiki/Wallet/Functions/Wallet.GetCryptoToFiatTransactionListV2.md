# Wallet.GetCryptoToFiatTransactionListV2

> Returns a paginated list of crypto-to-fiat sell transactions for a customer wallet (V2 variant), restricted to RequestTypeId = 7 only and with a hardcoded TransactionType = 7 in the output.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per crypto-to-fiat request (CorrelationId) |

---

## 1. Business Meaning

`GetCryptoToFiatTransactionListV2` is the V2 successor to `GetCryptoToFiatTransactionList`, designed to serve the V2 wallet transaction history API endpoint for crypto-to-fiat sell operations. The most significant business difference from V1 is that V2 narrows the request type filter to `RequestTypeId = 7` only, excluding the additional type 9 that V1 supports. This reflects a deliberate API versioning decision: V2 exposes only the primary crypto-to-fiat sell pathway, while V1 captures both type 7 and the secondary type 9 variant.

Additionally, V2 hardcodes `TransactionType = 7` in the output rather than returning `r.RequestTypeId`, ensuring the V2 API always emits a consistent type code regardless of the underlying request variant. The `@ForReport` parameter and `AdditionalDetails` column are retained for back-office report compatibility, and the `IsDone` detection and two-pass OPENJSON parsing are identical to V1.

---

## 2. Business Logic

**Three CTEs:**

- **`raw_requests`** — Top `@RecordsLimit` rows from `Wallet.Requests` for `RequestTypeId = 7` (V2 narrows from `IN (7, 9)` to `= 7`), filtered by `@Gcid`, optional `@CryptoId`, and date range. Latest status resolved via `OUTER APPLY TOP 1`. `FiatAccountFunded` JSON captured via second `OUTER APPLY`. `IsDone` flag from `EXISTS` subquery. Note: V2 omits `RequestTypeId` from the `raw_requests` column list.
- **`requests`** — Two `OPENJSON` passes parse `DetailsJson` and `FiatFundedDetailsJson` for amounts, rates, FiatId, estimated fees, and `ConversionFeePercentage`. Status: `2` (IsDone), `3` (Error), `0` (pending). `EtoroFee` = `EstimatedFiatAmount * ConversionFeePercentage / 100`.
- **`transactions`** — Joins `SentTransactions` to non-fee `SentTransactionOutputs` for TX ID, address, fee, and crypto amount.

**Final SELECT**: `CryptoAmount` is negative. `FiatAmount` and `ExchangeRate` use final values when `Status = 2`, estimates otherwise. `TransactionType` is hardcoded to `7`. `TransactionError` fetched inline only when `Status = 3`.

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
| `@ForReport` | BIT | 0 | 0 = customer API (suppress AdditionalDetails); 1 = report mode |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `CorrelationId` | UNIQUEIDENTIFIER | Cross-system correlation key |
| `BeginDate` | DATETIME2(7) | Timestamp the sell request was initiated |
| `CryptoAmount` | DECIMAL(36,18) | Crypto sold (negative value) |
| `FiatAmount` | DECIMAL(36,18) | Fiat received; final if completed, estimated otherwise |
| `FiatId` | TINYINT | Fiat currency identifier |
| `Status` | INT | 0=Pending, 2=Completed, 3=Error |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain transaction ID |
| `Address` | NVARCHAR(1024) | Destination blockchain address |
| `TransactionType` | INT | Hardcoded to 7 in V2 (RequestTypeId in V1) |
| `EtoroFee` | DECIMAL(36,18) | Estimated platform fee |
| `BlockchainFees` | DECIMAL(36,18) | Actual blockchain fee (or estimated) |
| `ExchangeRate` | DECIMAL(36,18) | Crypto-to-fiat rate; final if completed, estimated otherwise |
| `AdditionalDetails` | NVARCHAR(1000) | FiatAccountFunded JSON when @ForReport = 1 |
| `TransactionError` | VARCHAR(MAX) | JSON error details when Status = 3 |

---

## 5. Relationships

### 5.1 References To

| Object | Schema | Type | Purpose |
|--------|--------|------|---------|
| `Requests` | Wallet | Table | Primary request source (RequestTypeId = 7) |
| `RequestStatuses` | Wallet | Table | Latest status and FiatAccountFunded resolution |
| `RequestStatuses` | Dictionary | Table | Status name lookup |
| `SentTransactions` | Wallet | Table | Blockchain TX ID and fee |
| `SentTransactionOutputs` | Wallet | Table | Non-fee outputs for crypto amount and address |

### 5.2 Referenced By

| Object | Type | Notes |
|--------|------|-------|
| Wallet V2 transaction list API procedures | Stored Procedure | V2 customer-facing sell transaction history |
| Back-office reporting procedures | Stored Procedure | Called with @ForReport = 1 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetCryptoToFiatTransactionListV2
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

- Wallet API V2 transaction list stored procedures
- Back-office crypto-to-fiat reporting procedures (V2)

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. Standard V2 customer API call — all cryptos, last 30 days:**
```sql
SELECT *
FROM Wallet.GetCryptoToFiatTransactionListV2(
    123456, NULL,
    DATEADD(DAY, -30, GETUTCDATE()),
    GETUTCDATE(),
    500,
    0
)
ORDER BY BeginDate DESC;
```

**2. Highlight V1 vs V2 difference: V2 excludes RequestTypeId 9:**
```sql
-- Rows in V1 but not V2 (these would be RequestTypeId = 9 rows)
SELECT CorrelationId, BeginDate, TransactionType
FROM Wallet.GetCryptoToFiatTransactionList(123456, NULL, '2025-01-01', NULL, 10000, 0)
EXCEPT
SELECT CorrelationId, BeginDate, TransactionType
FROM Wallet.GetCryptoToFiatTransactionListV2(123456, NULL, '2025-01-01', NULL, 10000, 0);
```

**3. Back-office report with additional fiat funded details:**
```sql
SELECT CorrelationId, BeginDate, CryptoAmount, FiatAmount, FiatId,
       ExchangeRate, AdditionalDetails
FROM Wallet.GetCryptoToFiatTransactionListV2(
    123456, NULL,
    '2025-06-01', '2025-12-31',
    10000,
    1
)
WHERE Status = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetCryptoToFiatTransactionListV2 | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetCryptoToFiatTransactionListV2.sql*
