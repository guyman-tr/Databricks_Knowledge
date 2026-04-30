# Wallet.GetPaymentTransactionListV2

> Returns a paginated list of fiat payment (buy crypto with fiat) transactions for a customer wallet (V2 API variant), with identical logic to V1 including chargeback support and provider fee breakdown.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per payment request (CorrelationId) |

---

## 1. Business Meaning

`GetPaymentTransactionListV2` is the versioned successor to `GetPaymentTransactionList`, serving the V2 wallet API's payment transaction history endpoint. It covers the same business scenario — customers purchasing cryptocurrency with fiat money via a payment provider — and returns an identical result schema. The function was forked as a V2 variant to isolate the V2 API code path from V1, allowing either version to be modified independently without risk of breaking the other.

At the time of its creation, the SQL body of V2 is functionally identical to V1: same four CTEs (requests, payments, transactions, chargebacks), same status mapping, same visibility gate (`PaymentSubmitted > 0 OR @FromBackOffice = 1`), same `COALESCE(c.Status, p.Status, r.Status)` priority, and same `@FromBackOffice` flag for chargeback data. Both versions call `Wallet.GetRequestLastError` for error text.

---

## 2. Business Logic

**Four CTEs (identical to V1):**

- **`requests`** — Top `@RecordsLimit` rows from `Wallet.Requests` for `RequestTypeId = 2`, filtered by `@Gcid`, optional `@CryptoId`, and date range. Latest status via `OUTER APPLY TOP 1`. Error text via `Wallet.GetRequestLastError(r.Id)`. `OPENJSON` extracts `FiatId` and `FiatAmount`. Status: `3` (Error) or `4` (default).
- **`payments`** — Joins `Wallet.Payments` to `requests`, `CustomerWalletsView`, and `PaymentTransactions`. Resolves current payment status name. Computes `InitiationTime` (StatusId = 2) and `ModificationTime` (StatusId = 7). Status: Completed→2, Failed→3, PendingTransaction→5, else→4. `PaymentSubmitted` gates customer visibility.
- **`transactions`** — Aggregates `SentTransactions` for on-chain fee and TX ID.
- **`chargebacks`** — Populated when `@FromBackOffice = 1`: ChargeBack→6, Refund→7, RefundAsChargeback→8.

**Final SELECT**: COALESCE status priority: chargeback → payment → request. `TransactionType` hardcoded to 4. Filtered by `PaymentSubmitted > 0 OR @FromBackOffice = 1`.

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
| `@RecordsLimit` | INT | 10000 | Maximum rows returned |
| `@FromBackOffice` | BIT | 0 | 0 = customer API; 1 = back-office mode (enables chargebacks, removes gate) |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `CorrelationId` | UNIQUEIDENTIFIER | Cross-system correlation key |
| `BeginDate` | DATETIME2(7) | Timestamp the payment request was initiated |
| `Amount` | DECIMAL(36,18) | Crypto amount purchased |
| `Status` | INT | 0=Pending, 2=Completed, 3=Failed, 4=Default, 5=PendingTransaction, 6=Chargeback, 7=Refund, 8=RefundAsChargeback |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain transaction ID |
| `Address` | NVARCHAR(MAX) | Destination crypto address |
| `TransactionType` | INT | Hardcoded to 4 |
| `BlockchainFees` | DECIMAL(36,18) | Actual or estimated blockchain fee |
| `ProviderPaymentId` | VARCHAR(100) | External payment provider reference |
| `FiatId` | INT | Fiat currency ID |
| `FiatName` | VARCHAR(20) | Fiat currency name |
| `FiatAmount` | DECIMAL(36,18) | Fiat amount paid |
| `ExchangeRate` | DECIMAL(36,18) | Fiat-to-crypto exchange rate |
| `EtoroFeePercentage` | DECIMAL(36,18) | eToro platform fee percentage |
| `EtoroFeeCalculated` | DECIMAL(36,18) | eToro platform fee amount |
| `ProviderFeePercentage` | DECIMAL(36,18) | Provider fee percentage |
| `ProviderFeeCalculated` | DECIMAL(36,18) | Provider fee amount |
| `InitiationTime` | DATETIME2(7) | Time payment reached ProviderSubmitted state |
| `ModificationTime` | DATETIME2(7) | Time payment reached final state |
| `ChargebackDate` | DATETIME2(7) | Chargeback/refund date (back-office only) |
| `ChargebackAmount` | DECIMAL(36,18) | Chargeback amount (back-office only) |
| `ChargebackDescription` | VARCHAR(256) | Chargeback description (back-office only) |
| `ChargebackVerificationCode` | VARCHAR(20) | Chargeback code (back-office only) |
| `TransactionError` | VARCHAR(MAX) | Last error text from GetRequestLastError |

---

## 5. Relationships

### 5.1 References To

| Object | Schema | Type | Purpose |
|--------|--------|------|---------|
| `Requests` | Wallet | Table | Payment request source (RequestTypeId = 2) |
| `RequestStatuses` | Wallet | Table | Status name resolution |
| `RequestStatuses` | Dictionary | Table | Status name lookup |
| `GetRequestLastError` | Wallet | Function | Last error text for a request |
| `Payments` | Wallet | Table | Payment lifecycle records |
| `PaymentStatuses` | Wallet | Table | Payment status history |
| `PaymentStatuses` | Dictionary | Table | Payment status name lookup |
| `PaymentTransactions` | Wallet | Table | Crypto amount, address, exchange rate, fees |
| `CustomerWalletsView` | Wallet | View | Wallet lookup |
| `SentTransactions` | Wallet | Table | Blockchain TX ID and fee |
| `Chargebacks` | Wallet | Table | Chargeback/refund records |
| `ChargebackStatuses` | Dictionary | Table | Chargeback status name lookup |
| `FiatTypes` | Wallet | Table | Fiat currency name lookup |

### 5.2 Referenced By

| Object | Type | Notes |
|--------|------|-------|
| Wallet V2 payment transaction list API procedures | Stored Procedure | V2 customer-facing payment history |
| Back-office reporting (V2) | Stored Procedure | Called with @FromBackOffice = 1 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPaymentTransactionListV2
├── Wallet.Requests
├── Wallet.RequestStatuses → Dictionary.RequestStatuses
├── Wallet.GetRequestLastError (scalar function)
├── Wallet.Payments
│   ├── Wallet.PaymentStatuses → Dictionary.PaymentStatuses
│   ├── Wallet.PaymentTransactions
│   └── Wallet.CustomerWalletsView
├── Wallet.SentTransactions
├── Wallet.Chargebacks → Dictionary.ChargebackStatuses
└── Wallet.FiatTypes
```

### 6.1 Objects This Depends On

- `Wallet.Requests`
- `Wallet.RequestStatuses`
- `Dictionary.RequestStatuses`
- `Wallet.GetRequestLastError`
- `Wallet.Payments`
- `Wallet.PaymentStatuses`
- `Dictionary.PaymentStatuses`
- `Wallet.PaymentTransactions`
- `Wallet.CustomerWalletsView`
- `Wallet.SentTransactions`
- `Wallet.Chargebacks`
- `Dictionary.ChargebackStatuses`
- `Wallet.FiatTypes`

### 6.2 Objects That Depend On This

- Wallet API V2 payment transaction list stored procedures
- Back-office payment and chargeback reporting (V2)

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. Standard V2 customer call — last 60 days:**
```sql
SELECT *
FROM Wallet.GetPaymentTransactionListV2(
    123456, NULL,
    DATEADD(DAY, -60, GETUTCDATE()),
    GETUTCDATE(),
    500,
    0
)
ORDER BY BeginDate DESC;
```

**2. Back-office — identify all chargebacks and refunds:**
```sql
SELECT CorrelationId, BeginDate, Status, FiatAmount,
       ChargebackDate, ChargebackAmount, ChargebackDescription
FROM Wallet.GetPaymentTransactionListV2(
    123456, NULL,
    '2025-01-01', '2026-01-01',
    10000, 1
)
WHERE Status IN (6, 7, 8);
```

**3. Confirm V1 and V2 produce identical results:**
```sql
SELECT CorrelationId, Status, Amount, FiatAmount
FROM Wallet.GetPaymentTransactionList(123456, NULL, '2025-01-01', NULL, 500, 0)
EXCEPT
SELECT CorrelationId, Status, Amount, FiatAmount
FROM Wallet.GetPaymentTransactionListV2(123456, NULL, '2025-01-01', NULL, 500, 0);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPaymentTransactionListV2 | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetPaymentTransactionListV2.sql*
