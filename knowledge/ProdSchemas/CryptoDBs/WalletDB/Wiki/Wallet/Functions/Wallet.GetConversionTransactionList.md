# Wallet.GetConversionTransactionList

> Multi-statement table-valued function returning a customer's crypto-to-crypto conversion transaction history, merging request-level data with settled conversion records for a unified view.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement Table-Valued Function |
| **Key Identifier** | Returns table - one row per conversion request (keyed by CorrelationId) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetConversionTransactionList powers the conversion transaction history for the eToro wallet API. When a customer converts one cryptocurrency to another (e.g., BTC to ETH), the platform generates a request record in `Wallet.Requests` (RequestTypeId=4) and, once processed, a corresponding settlement record in `Wallet.Conversions`. This function bridges both data sources so the UI always shows the most complete state of each conversion.

The dual-source design means in-flight requests (not yet settled) still appear with status derived from the request pipeline, while completed conversions are enriched with actual exchange rates, settled amounts, wallet addresses, and blockchain fee details. The result is a unified view that accurately represents the customer's full conversion history.

Called by `Wallet.GetTransactionList` and `Wallet.GetTransactionList_temp` as part of the unified transaction history that aggregates all transaction types (sent, received, conversion, payment, staking) for the wallet UI. The V2 variant (`GetConversionTransactionListV2`) is identical in logic and is consumed by `Wallet.GetTransactionListV2`.

---

## 2. Business Logic

### 2.1 Request-Level Data Extraction

**What**: Fetches conversion requests from the request pipeline, extracting structured fields from JSON detail payloads.

**Columns/Parameters Involved**: `@Gcid`, `@CryptoId`, `@RecordsLimit`, Wallet.Requests

**Rules**:
- Filters `Wallet.Requests` to `RequestTypeId = 4` (conversion) for the given customer and date range
- Extracts via OPENJSON: `CryptoIdTo`, `AmountFrom`, `AmountTo`, `IsAmountFromFixed`, `RateUsedFrom`, `RateUsedTo`, `BlockChainFromFee`, `BlockChainToFee`
- Latest status resolved via CROSS APPLY TOP 1 on RequestStatuses
- Error details captured via OUTER APPLY filtered to `'Error'` status with valid JSON
- Status simplified: 3 (Error) or 0 (pending/in-progress)
- TransactionType: 2 (FixedFrom) when `IsAmountFromFixed='true'`, 3 (FixedTo) when `'false'`
- Exchange rate calculated as `RateUsedFrom / RateUsedTo`

### 2.2 Settlement-Level Enrichment

**What**: Enriches with actual settled conversion data when available.

**Columns/Parameters Involved**: Wallet.Conversions, Wallet.ConversionTransactions, Wallet.CustomerWalletsView

**Rules**:
- Reads `Wallet.Conversions` joined to `CustomerWalletsView` for wallet addresses
- Joins `ConversionTransactions` for both from-leg and to-leg amounts, rates, and fees
- Latest conversion status from `ConversionStatuses` via OUTER APPLY: Completed=2, Failed=3, other=0
- ConversionType from `Dictionary.ConversionTypes`: FixedTo=3, else=2
- Exchange rate: `FromCryptoRateUsd / ToCryptoRateUsd`

### 2.3 Blockchain Fee Aggregation

**What**: Aggregates actual blockchain fees from sent transactions.

**Columns/Parameters Involved**: Wallet.SentTransactions

**Rules**:
- Groups `SentTransactions` by CorrelationId and CryptoId to get blockchain TX IDs and summed fees
- Provides both from-leg (`BlockChainTransactionId`, `BlockchainFees`) and to-leg (`BlockChainTransactionId2`, `BlockchainFees2`)

### 2.4 Data Source Priority

**What**: Settled data overrides request-level estimates using ISNULL pattern.

**Rules**:
- Final SELECT uses `ISNULL(conversion_value, request_value)` for all overlapping fields
- Settled status, amounts, exchange rates, and fees take priority when available
- Request-level data serves as fallback for in-flight conversions not yet settled

---

## 3. Data Overview

N/A for table-valued function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. Filters conversion requests and settlements to this customer. |
| 2 | @CryptoId | int | YES | - | CODE-BACKED | Cryptocurrency filter. NULL returns all conversions. When specified, matches either `FromCryptoId` or `ToCryptoId` (showing conversions involving this crypto on either side). |
| 3 | @BeginDateAfter | datetime2(7) | YES | - | CODE-BACKED | Inclusive lower bound on request timestamp. NULL defaults to '2000-01-01'. |
| 4 | @BeginDateBefore | datetime2(7) | YES | - | CODE-BACKED | Exclusive upper bound on request timestamp. NULL defaults to '2100-01-01'. |
| 5 | @RecordsLimit | int | YES | 10000 | CODE-BACKED | Maximum rows returned. Applied as TOP in the requests CTE, ordered by timestamp DESC (most recent first). |
| 6 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Cross-system correlation key linking the request to the conversion settlement. Primary join key between requests and conversions CTEs. |
| 7 | BeginDate | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the conversion request was initiated (from Requests.Timestamp). |
| 8 | Status | int | YES | - | CODE-BACKED | Unified status: 0=Pending/In-progress, 2=Completed, 3=Failed/Error. Prefers settlement status over request status when both exist. |
| 9 | BlockChainTransactionId | nvarchar(100) | YES | - | CODE-BACKED | On-chain transaction hash for the from-crypto leg (the crypto being sold). From SentTransactions aggregation. |
| 10 | Address | nvarchar(max) | YES | - | CODE-BACKED | Source wallet address for the from-leg. From CustomerWalletsView via the from-wallet join. |
| 11 | TransactionType | int | YES | - | CODE-BACKED | Conversion direction: 2=FixedFrom (customer specifies sell amount), 3=FixedTo (customer specifies buy amount). Derived from Dictionary.ConversionTypes or request JSON field IsAmountFromFixed. |
| 12 | EtoroFee | decimal(36,18) | YES | - | CODE-BACKED | Platform fee charged on the conversion. Sourced from ConversionTransactions.EtoroFeeCalculated on the to-leg. |
| 13 | BlockchainFees | decimal(36,18) | YES | - | CODE-BACKED | Actual blockchain network fee for the from-leg transaction. Falls back to request-level BlockChainFromFee estimate if no SentTransaction exists yet. |
| 14 | FromCryptoId | int | YES | - | CODE-BACKED | ID of the cryptocurrency being sold (FK to Wallet.CryptoTypes). |
| 15 | ToCryptoId | int | YES | - | CODE-BACKED | ID of the cryptocurrency being bought (FK to Wallet.CryptoTypes). |
| 16 | FromAmount | decimal(36,18) | YES | - | CODE-BACKED | Amount of from-crypto sold. Prefers settled ConversionTransactions amount over request estimate. |
| 17 | ToAmount | decimal(36,18) | YES | - | CODE-BACKED | Amount of to-crypto received. Prefers settled ConversionTransactions amount over request estimate. |
| 18 | ToAddress | nvarchar(1024) | YES | - | CODE-BACKED | Destination wallet address for the to-leg. From CustomerWalletsView via the to-wallet join. |
| 19 | ExchangeRate | decimal(36,18) | YES | - | CODE-BACKED | Effective exchange rate: FromCryptoRateUsd / ToCryptoRateUsd. Prefers settled rate over request estimate. |
| 20 | BlockChainTransactionId2 | nvarchar(100) | YES | - | CODE-BACKED | On-chain transaction hash for the to-crypto leg. From SentTransactions aggregation. |
| 21 | BlockchainFees2 | decimal(36,18) | YES | - | CODE-BACKED | Blockchain fee for the to-leg. From ConversionTransactions.EstimatedBlockChainFee. Falls back to request-level BlockChainToFee estimate. |
| 22 | TransactionError | varchar(max) | YES | - | CODE-BACKED | JSON error details from the most recent 'Error' status entry for this request. NULL if no error occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Wallet.Requests | FROM | Primary source - conversion requests (RequestTypeId=4) |
| - | Wallet.RequestStatuses | CROSS/OUTER APPLY | Latest status and error details resolution |
| - | Dictionary.RequestStatuses | JOIN | Status name lookup |
| - | Wallet.Conversions | LEFT JOIN | Settled conversion records |
| - | Wallet.CustomerWalletsView | LEFT JOIN | Wallet address lookup for from/to wallets |
| - | Dictionary.ConversionTypes | JOIN | FixedFrom vs FixedTo classification |
| - | Wallet.ConversionTransactions | LEFT JOIN | Per-leg settled amounts, rates, fees |
| - | Wallet.ConversionStatuses | OUTER APPLY | Latest conversion status |
| - | Dictionary.ConversionStatuses | JOIN | Conversion status name lookup |
| - | Wallet.SentTransactions | CTE | Blockchain TX IDs and fee aggregation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetTransactionList | - | FROM (TVF call) | Includes conversion transactions in unified V1 transaction history |
| Wallet.GetTransactionList_temp | - | FROM (TVF call) | Temp variant of unified transaction list |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetConversionTransactionList (function)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
+-- Dictionary.RequestStatuses (table)
+-- Wallet.Conversions (table)
+-- Wallet.CustomerWalletsView (view)
+-- Dictionary.ConversionTypes (table)
+-- Wallet.ConversionTransactions (table)
+-- Wallet.ConversionStatuses (table)
+-- Dictionary.ConversionStatuses (table)
+-- Wallet.SentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - conversion requests (RequestTypeId=4) |
| Wallet.RequestStatuses | Table | CROSS/OUTER APPLY - status resolution |
| Dictionary.RequestStatuses | Table | JOIN - status name lookup |
| Wallet.Conversions | Table | LEFT JOIN - settled conversion records |
| Wallet.CustomerWalletsView | View | LEFT JOIN - wallet address lookup |
| Dictionary.ConversionTypes | Table | JOIN - FixedFrom/FixedTo classification |
| Wallet.ConversionTransactions | Table | LEFT JOIN - per-leg amounts and fees |
| Wallet.ConversionStatuses | Table | OUTER APPLY - conversion status |
| Dictionary.ConversionStatuses | Table | JOIN - conversion status name |
| Wallet.SentTransactions | Table | CTE - blockchain TX IDs and fees |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetTransactionList | Stored Procedure | Calls for conversion portion of unified transaction history |
| Wallet.GetTransactionList_temp | Stored Procedure | Temp variant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for table-valued function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all conversions for a customer in the last 30 days
```sql
SELECT *
FROM Wallet.GetConversionTransactionList(
    123456, NULL,
    DATEADD(DAY, -30, GETUTCDATE()), GETUTCDATE(), 1000
)
ORDER BY BeginDate DESC
```

### 8.2 Get BTC-involved conversions (either from or to BTC)
```sql
SELECT CorrelationId, BeginDate, FromCryptoId, ToCryptoId,
       FromAmount, ToAmount, ExchangeRate, Status
FROM Wallet.GetConversionTransactionList(123456, 1, '2025-01-01', '2025-12-31', 500)
WHERE Status = 2  -- Completed only
```

### 8.3 Find failed conversions with error details
```sql
SELECT CorrelationId, BeginDate, FromCryptoId, ToCryptoId, TransactionError
FROM Wallet.GetConversionTransactionList(123456, NULL, '2024-01-01', NULL, 10000)
WHERE Status = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetConversionTransactionList | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetConversionTransactionList.sql*
