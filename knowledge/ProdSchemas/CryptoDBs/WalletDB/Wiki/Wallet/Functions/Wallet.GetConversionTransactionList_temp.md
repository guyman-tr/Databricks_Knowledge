# Wallet.GetConversionTransactionList_temp

> Experimental/optimized variant of GetConversionTransactionList using OPENJSON for fully parsed conversion request data; intended as a candidate replacement or performance test harness.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per conversion request (CorrelationId) |

---

## 1. Business Meaning

`GetConversionTransactionList_temp` is a development/staging variant of `GetConversionTransactionList`, explicitly annotated in its DDL comment as "Fully optimized Wallet.GetConversionTransactionList using OPENJSON." It was created to test or benchmark a refactored version of the conversion transaction list query before promoting the changes to the production V1 or V2 functions. The `_temp` suffix is a common eToro WalletDB convention indicating a function that is not yet officially promoted but may be used in non-production environments or canary testing.

The function produces the same return schema and business output as `GetConversionTransactionList` and `GetConversionTransactionListV2`, making it a drop-in candidate for replacement. One structural difference from V1 is the absence of an `ORDER BY` clause in the `requests` CTE's date filter, which may reflect a query optimizer experiment. It should not be called by production application code without first confirming it has passed validation.

---

## 2. Business Logic

Three CTEs mirror the V1/V2 structure:

- **`requests`** — Selects `TOP @RecordsLimit` from `Wallet.Requests` for `RequestTypeId = 4` (conversions), filtered by `@Gcid` and date range. `OPENJSON` parses `DetailsJson` for `CryptoIdTo`, `AmountFrom`, `AmountTo`, `IsAmountFromFixed`, `RateUsedFrom`, `RateUsedTo`, and blockchain fees. Latest status is resolved via `CROSS APPLY TOP 1`. Error JSON captured via `OUTER APPLY`. Status: `3` (Error) or `0`. `TransactionType`: `2` or `3` based on `IsAmountFromFixed`. Note: the `requests` CTE **omits an explicit ORDER BY** on the outer query (unlike V1), which may affect page stability.
- **`conversions`** — Identical to V1: reads `Wallet.Conversions`, joins wallet addresses, per-leg `ConversionTransactions`, `ConversionTypes`, and latest `ConversionStatuses`. Computes settled exchange rate as `FromRateUsd / ToRateUsd`.
- **`transactions`** — Aggregates `SentTransactions` by `CorrelationId + CryptoId + BlockChainTransactionId` for fee and TX ID resolution.

**Final SELECT** applies the same `ISNULL(c.value, r.value)` precedence logic as V1/V2.

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
| Development/test harnesses | Ad-hoc | Performance testing and validation before promotion to V1/V2 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetConversionTransactionList_temp
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

- No known production dependents; intended for development/testing use only

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. Validate output parity against V1 for a sample customer:**
```sql
SELECT 'temp' AS Version, CorrelationId, Status, FromAmount, ToAmount, ExchangeRate
FROM Wallet.GetConversionTransactionList_temp(123456, NULL, '2025-01-01', NULL, 200)
EXCEPT
SELECT 'v1' AS Version, CorrelationId, Status, FromAmount, ToAmount, ExchangeRate
FROM Wallet.GetConversionTransactionList(123456, NULL, '2025-01-01', NULL, 200);
```

**2. Basic retrieval for development testing:**
```sql
SELECT *
FROM Wallet.GetConversionTransactionList_temp(
    123456, NULL,
    DATEADD(DAY, -7, GETUTCDATE()),
    GETUTCDATE(),
    100
)
ORDER BY BeginDate DESC;
```

**3. Check for rows with errors in the temp function:**
```sql
SELECT CorrelationId, BeginDate, TransactionError
FROM Wallet.GetConversionTransactionList_temp(
    123456, NULL, '2024-01-01', NULL, 10000
)
WHERE Status = 3
  AND TransactionError IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetConversionTransactionList_temp | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetConversionTransactionList_temp.sql*
