# Wallet.GetConversionTransactionListV2

> Returns a paginated list of crypto-to-crypto conversion transactions for a customer wallet (V2 API variant), merging request-level data with settled conversion records using identical logic to V1.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per conversion request (CorrelationId) |

---

## 1. Business Meaning

`GetConversionTransactionListV2` is the versioned successor to `GetConversionTransactionList`, created to support iterative API evolution without breaking existing consumers. It powers the V2 conversion history endpoint in the eToro wallet, surfacing the same dual-source merge of request records and settled conversion records that V1 provides, while leaving room for future schema or logic divergence between the two versions.

At the time of its creation the SQL body of V2 is functionally identical to V1, making it a safe copy-fork for future modifications. Both functions are maintained in parallel to allow the application layer to route different API versions to their respective database functions without a shared code path that could inadvertently affect both versions simultaneously when changes are required.

---

## 2. Business Logic

The function uses three CTEs with logic identical to `GetConversionTransactionList`:

- **`requests`** — Top `@RecordsLimit` rows from `Wallet.Requests` for `RequestTypeId = 4` (conversions), filtered by `@Gcid`, date range, and optionally `@CryptoId` (matching either `r.CryptoId` or the `CryptoIdTo` parsed from `DetailsJson`). OPENJSON extracts conversion fields. Latest status resolved via `CROSS APPLY TOP 1`; error JSON via `OUTER APPLY`. Status: `3` (Error) or `0` (in-progress/pending). `TransactionType`: `2` (FixedFrom) or `3` (FixedTo).
- **`conversions`** — Settled rows from `Wallet.Conversions` joined to wallet addresses, per-leg `ConversionTransactions`, conversion type, and latest `ConversionStatuses`. Status: `2` (Completed), `3` (Failed), `0` (other).
- **`transactions`** — `SentTransactions` aggregated by `CorrelationId + CryptoId` for blockchain TX IDs and summed fees.

**Final SELECT** LEFT JOINs `requests → conversions → transactions`, preferring settled data (`ISNULL(c.value, r.value)`) over request estimates. Returns both from-leg and to-leg blockchain transaction IDs.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

### Parameters (IN)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `@Gcid` | BIGINT | required | Customer global customer ID |
| `@CryptoId` | INT | required | Filter by crypto (NULL = all); matches either from or to crypto |
| `@BeginDateAfter` | DATETIME2(7) | required | Inclusive lower bound on request timestamp (NULL = 2000-01-01) |
| `@BeginDateBefore` | DATETIME2(7) | required | Exclusive upper bound on request timestamp (NULL = 2100-01-01) |
| `@RecordsLimit` | INT | 10000 | Maximum rows returned (applied as TOP in requests CTE) |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `CorrelationId` | UNIQUEIDENTIFIER | Cross-system correlation key linking request to conversion |
| `BeginDate` | DATETIME2(7) | Timestamp the conversion request was initiated |
| `Status` | INT | 0=Pending, 2=Completed, 3=Failed/Error |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain TX ID for the from-crypto leg |
| `Address` | NVARCHAR(MAX) | Source wallet address (from-leg) |
| `TransactionType` | INT | 2=FixedFrom, 3=FixedTo |
| `EtoroFee` | DECIMAL(36,18) | Platform fee from the to-leg ConversionTransaction |
| `BlockchainFees` | DECIMAL(36,18) | Actual blockchain fee for the from-leg |
| `FromCryptoId` | INT | Crypto being sold |
| `ToCryptoId` | INT | Crypto being bought |
| `FromAmount` | DECIMAL(36,18) | Amount of from-crypto sold |
| `ToAmount` | DECIMAL(36,18) | Amount of to-crypto received |
| `ToAddress` | NVARCHAR(1024) | Destination wallet address (to-leg) |
| `ExchangeRate` | DECIMAL(36,18) | FromCryptoRateUsd / ToCryptoRateUsd |
| `BlockChainTransactionId2` | NVARCHAR(100) | On-chain TX ID for the to-crypto leg |
| `BlockchainFees2` | DECIMAL(36,18) | Estimated blockchain fee for the to-leg |
| `TransactionError` | VARCHAR(MAX) | JSON error detail from the latest Error status record |

---

## 5. Relationships

### 5.1 References To

| Object | Schema | Type | Purpose |
|--------|--------|------|---------|
| `Requests` | Wallet | Table | Primary source for conversion request rows |
| `RequestStatuses` | Wallet | Table | Latest and error status resolution |
| `RequestStatuses` | Dictionary | Table | Status name lookup |
| `Conversions` | Wallet | Table | Settled conversion records |
| `ConversionStatuses` | Wallet | Table | Latest conversion status |
| `ConversionStatuses` | Dictionary | Table | Status name lookup |
| `ConversionTypes` | Dictionary | Table | FixedFrom vs FixedTo classification |
| `ConversionTransactions` | Wallet | Table | Per-leg settled amounts and rates |
| `CustomerWalletsView` | Wallet | View | Wallet address lookup by Gcid and CryptoId |
| `SentTransactions` | Wallet | Table | Blockchain TX IDs and fees |

### 5.2 Referenced By

| Object | Type | Notes |
|--------|------|-------|
| Wallet transaction list API procedures (V2) | Stored Procedure | V2 customer-facing transaction history endpoint |
| Back-office reporting queries | Ad-hoc | Conversion reconciliation reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetConversionTransactionListV2
├── Wallet.Requests
├── Wallet.RequestStatuses → Dictionary.RequestStatuses
├── Wallet.Conversions
│   ├── Wallet.CustomerWalletsView
│   ├── Wallet.ConversionTransactions
│   ├── Wallet.ConversionStatuses → Dictionary.ConversionStatuses
│   └── Dictionary.ConversionTypes
└── Wallet.SentTransactions
```

### 6.1 Objects This Depends On

- `Wallet.Requests`
- `Wallet.RequestStatuses`
- `Dictionary.RequestStatuses`
- `Wallet.Conversions`
- `Wallet.ConversionStatuses`
- `Dictionary.ConversionStatuses`
- `Dictionary.ConversionTypes`
- `Wallet.ConversionTransactions`
- `Wallet.CustomerWalletsView`
- `Wallet.SentTransactions`

### 6.2 Objects That Depend On This

- Wallet transaction list stored procedures (V2 API layer)
- Back-office conversion reporting procedures

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. All conversions for a customer across all cryptos:**
```sql
SELECT *
FROM Wallet.GetConversionTransactionListV2(
    123456, NULL,
    DATEADD(DAY, -90, GETUTCDATE()),
    GETUTCDATE(),
    5000
)
ORDER BY BeginDate DESC;
```

**2. Completed ETH conversions (CryptoId = 3):**
```sql
SELECT CorrelationId, BeginDate, FromCryptoId, ToCryptoId,
       FromAmount, ToAmount, ExchangeRate
FROM Wallet.GetConversionTransactionListV2(
    123456, 3,
    '2025-01-01', '2026-01-01',
    1000
)
WHERE Status = 2;
```

**3. Compare V1 vs V2 output for the same customer (should be identical):**
```sql
SELECT 'V1' AS Version, CorrelationId, Status, FromAmount, ToAmount
FROM Wallet.GetConversionTransactionList(123456, NULL, '2025-01-01', NULL, 100)
UNION ALL
SELECT 'V2' AS Version, CorrelationId, Status, FromAmount, ToAmount
FROM Wallet.GetConversionTransactionListV2(123456, NULL, '2025-01-01', NULL, 100)
ORDER BY CorrelationId, Version;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetConversionTransactionListV2 | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetConversionTransactionListV2.sql*
