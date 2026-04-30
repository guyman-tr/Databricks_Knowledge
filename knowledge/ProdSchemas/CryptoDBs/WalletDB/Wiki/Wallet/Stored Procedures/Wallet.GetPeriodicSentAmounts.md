# Wallet.GetPeriodicSentAmounts

> Calculates the total outbound crypto amounts for a customer within a time period, combining both verified sent transactions and pending request amounts across send, conversion, and payment transaction types.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated sent + pending amounts per crypto with market rate symbols |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure computes the total outbound crypto volume for a customer over a specified time window, serving as a key input for spending limit enforcement. It answers the question: "How much has this customer sent (or committed to send) since time X?" by combining two components: (1) verified sent transactions already on the blockchain, and (2) pending requests that have not yet completed or errored.

Without this procedure, the spending limit system could not accurately enforce periodic withdrawal caps. A customer might exceed their daily/weekly limit by submitting multiple simultaneous requests before any completes. By summing both confirmed sends and in-flight requests, the procedure provides a conservative (pessimistic) view of outbound volume.

Called by `BackApiUser` (back-office API) and `ConversionUser` (conversion service). The procedure handles three transaction types: customer send (type 1), conversion (type 5->4), and payment (type 7->2), each with different amount extraction logic from the request JSON payload.

---

## 2. Business Logic

### 2.1 Two-Component Amount Calculation

**What**: Sums verified blockchain sends and pending in-flight requests to get total committed outbound volume.

**Columns/Parameters Involved**: `SentTransactions.Amount`, `Requests.DetailsJson`, `SentTransactionStatuses.StatusId`, `RequestStatuses.RequestStatusId`

**Rules**:
- Component 1 (Verified Sends): SentTransactions with latest status = 2 (confirmed/verified), joined to SentTransactionOutputs for actual amounts
- Component 2 (Pending Requests): Requests where latest RequestStatusId NOT IN (1=Done, 2=Error), extracting amounts from JSON payload
- Both components are summed into #Result and then aggregated by CryptoId and MarketRatesCurrencySymbol
- The @ExcludedCorrelationId parameter allows excluding the current request being evaluated (to avoid double-counting)

**Diagram**:
```
Total Outbound = Verified Sends + Pending Requests

Verified Sends:
  SentTransactions (StatusId=2)
    -> SentTransactionOutputs.Amount
    -> SUM by CryptoId

Pending Requests:
  Requests (StatusId NOT IN 1,2)
    -> JSON_VALUE(DetailsJson, path)
    -> SUM by CryptoId

Combined -> GROUP BY CryptoId, MarketRatesCurrencySymbol
```

### 2.2 Transaction Type Mapping

**What**: Maps TransactionTypeId values to RequestTypeId values and determines the JSON path for amount extraction.

**Columns/Parameters Involved**: `@TransactionTypeId`, `Requests.RequestTypeId`, `Requests.DetailsJson`

**Rules**:
- TransactionTypeId 1 (CustomerMoneyOut) -> RequestTypeId 1 (SendTransaction) -> JSON path: $.Amount
- TransactionTypeId 5 (ConversionMoneyIn) -> RequestTypeId 4 (Conversion) -> JSON path: $.AmountFrom
- TransactionTypeId 7 (Payment) -> RequestTypeId 2 (InitiatePayment) -> JSON path: $.FiatAmount
- When @TransactionTypeId is NULL, all three types are included
- Payment requests use FiatMarketRatesMappings instead of CryptoMarketRatesMappings for the market rate symbol

### 2.3 Status Filtering

**What**: Only includes transactions/requests in specific lifecycle states.

**Columns/Parameters Involved**: `SentTransactionStatuses.StatusId`, `RequestStatuses.RequestStatusId`

**Rules**:
- Sent transactions: Only status 2 (verified/confirmed on blockchain) are counted
- Pending requests: All statuses EXCEPT 1 (Done) and 2 (Error) are counted - these represent in-flight commitment
- This means cancelled, expired, or failed requests are NOT counted against the limit

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. Identifies the customer whose outbound volume is being calculated. |
| 2 | @CryptoId | int | YES | - | CODE-BACKED | Optional cryptocurrency filter. When NULL, calculates across all cryptos. When specified, limits to that crypto. |
| 3 | @TransactionTypeId | tinyint | YES | - | CODE-BACKED | Optional transaction type filter: 1=CustomerMoneyOut, 5=ConversionMoneyIn, 7=Payment. When NULL, includes all types. |
| 4 | @FromTime | datetime2(7) | NO | - | CODE-BACKED | Start of the calculation period. Only transactions/requests after this time are included. Used for rolling-window limit checks. |
| 5 | @ExcludedCorrelationId | uniqueidentifier | NO | - | CODE-BACKED | CorrelationId to exclude from the pending requests calculation. Prevents double-counting when evaluating a specific request against its own limit. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency identifier for this aggregation row. |
| 2 | MarketRatesCurrencySymbol | varchar(20) | YES | - | CODE-BACKED | Market rate currency symbol for this crypto (from CryptoMarketRatesMappings) or fiat (from FiatMarketRatesMappings for payment types). Used by the caller to convert amounts to a common denomination for limit comparison. |
| 3 | Amount | decimal(36,18) | YES | - | CODE-BACKED | Total combined amount of verified sends plus pending requests for this CryptoId in the specified period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Wallet.CustomerWalletsView | JOIN | Resolves customer wallets for the Gcid |
| SentTransactions | Wallet.SentTransactions | JOIN | Verified outbound blockchain transactions |
| SentTransactionOutputs | Wallet.SentTransactionOutputs | JOIN | Individual output amounts per sent transaction |
| SentTransactionStatuses | Wallet.SentTransactionStatuses | Subquery | Latest status check (status=2 for verified) |
| CryptoMarketRatesMappings | Wallet.CryptoMarketRatesMappings | JOIN | Maps CryptoId to market rate currency symbol |
| Requests | Wallet.Requests | JOIN | Pending outbound requests |
| RequestStatuses | Wallet.RequestStatuses | Subquery | Latest request status to filter out Done/Error |
| FiatMarketRatesMappings | Wallet.FiatMarketRatesMappings | LEFT JOIN | Maps FiatId to market rate symbol (payment types only) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | GRANT EXECUTE | Permission | Back-office API for limit enforcement |
| ConversionUser | GRANT EXECUTE | Permission | Conversion service for limit checks during crypto conversions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPeriodicSentAmounts (procedure)
├── Wallet.CustomerWalletsView (view)
│     ├── Wallet.Wallets (table)
│     ├── Wallet.WalletAddresses (table)
│     └── Wallet.BlockchainCryptos (table)
├── Wallet.SentTransactions (table)
├── Wallet.SentTransactionOutputs (table)
├── Wallet.SentTransactionStatuses (table)
├── Wallet.CryptoMarketRatesMappings (table)
├── Wallet.Requests (table)
├── Wallet.RequestStatuses (table)
└── Wallet.FiatMarketRatesMappings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Resolves Gcid to wallet IDs |
| Wallet.SentTransactions | Table | Verified sent transaction records |
| Wallet.SentTransactionOutputs | Table | Individual output amounts per transaction |
| Wallet.SentTransactionStatuses | Table | Status verification (only status=2 counted) |
| Wallet.CryptoMarketRatesMappings | Table | Crypto to market rate symbol mapping |
| Wallet.Requests | Table | Pending outbound request amounts |
| Wallet.RequestStatuses | Table | Request status filtering (exclude Done/Error) |
| Wallet.FiatMarketRatesMappings | Table | Fiat to market rate symbol (payments) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (BackApiUser service) | External | Spending limit enforcement for back-office operations |
| (ConversionUser service) | External | Limit checks during crypto conversion flows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp tables | Performance | Uses #Gcids, #Result, #RequestTypes temp tables for intermediate aggregation |
| NOLOCK hints | Read isolation | All table reads use NOLOCK |
| JSON_VALUE extraction | Data access | Extracts amounts from Requests.DetailsJson using different JSON paths per transaction type |
| Empty GUID creation | Logic | Creates an empty GUID constant for comparison (CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER)) |

---

## 8. Sample Queries

### 8.1 Check a customer's total sent amounts in the last 24 hours
```sql
DECLARE @EmptyGuid UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';
EXEC Wallet.GetPeriodicSentAmounts
    @Gcid = 12345678,
    @CryptoId = NULL,
    @TransactionTypeId = NULL,
    @FromTime = '2026-04-14T00:00:00',
    @ExcludedCorrelationId = @EmptyGuid;
```

### 8.2 Check BTC send amounts only for limit evaluation
```sql
EXEC Wallet.GetPeriodicSentAmounts
    @Gcid = 12345678,
    @CryptoId = 1,
    @TransactionTypeId = 1,
    @FromTime = '2026-04-14T00:00:00',
    @ExcludedCorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.3 Manual query for verified sent amounts per customer wallet
```sql
SELECT st.CryptoId, SUM(sto.Amount) AS TotalSent
FROM Wallet.SentTransactions st WITH (NOLOCK)
    JOIN Wallet.SentTransactionOutputs sto WITH (NOLOCK) ON sto.SentTransactionId = st.Id
WHERE st.WalletId = 'WALLET-GUID-HERE'
    AND st.Occurred > DATEADD(HOUR, -24, GETDATE())
    AND (SELECT TOP 1 sts.StatusId FROM Wallet.SentTransactionStatuses sts WITH (NOLOCK)
         WHERE sts.SentTransactionId = st.Id ORDER BY sts.Occurred DESC) = 2
GROUP BY st.CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPeriodicSentAmounts | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPeriodicSentAmounts.sql*
