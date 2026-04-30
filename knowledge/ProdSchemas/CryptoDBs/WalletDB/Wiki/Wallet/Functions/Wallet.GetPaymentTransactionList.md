# Wallet.GetPaymentTransactionList

> Returns a paginated list of fiat payment (buy crypto with fiat) transactions for a customer wallet, including chargeback and refund status, fee breakdown, and provider payment identifiers.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per payment request (CorrelationId) |

---

## 1. Business Meaning

This function powers the payment transaction history for the eToro crypto wallet, covering scenarios where customers fund their wallet by purchasing cryptocurrency with fiat money via a payment provider. Each payment flows through a multi-step lifecycle: the customer initiates a request, the provider submits the payment, the blockchain transaction is executed, and the payment completes. This function assembles all of those lifecycle stages into a single row per payment for display in the wallet UI and for back-office operations.

A critical business rule governs which records are visible: only payments that have reached `ProviderSubmitted` or `PendingTransaction` status are shown to customers (`PaymentSubmitted > 0`). This prevents in-flight or abandoned payment attempts from cluttering the transaction history. Back-office users bypass this filter via `@FromBackOffice = 1`, which also enables the chargeback CTE to populate `ChargebackDate`, `ChargebackAmount`, `ChargebackDescription`, and `ChargebackVerificationCode` for compliance and dispute resolution workflows.

---

## 2. Business Logic

**Four CTEs:**

- **`requests`** — Top `@RecordsLimit` rows from `Wallet.Requests` for `RequestTypeId = 2` (payment/buy requests), filtered by `@Gcid`, optional `@CryptoId`, and date range. Latest status via `OUTER APPLY TOP 1`. Error text via `Wallet.GetRequestLastError(r.Id)`. `OPENJSON` extracts `FiatId` and `FiatAmount` from `DetailsJson`. Status simplified to `3` (Error) or `4` (default/pending).
- **`payments`** — Joins `Wallet.Payments` back to `requests` on `CorrelationId`. Joins `CustomerWalletsView` (optional, for wallet context) and `PaymentTransactions` (for crypto amount, address, exchange rate, fee breakdown). Resolves `PaymentStatusName` via correlated subquery. Computes `InitiationTime` (PaymentStatusId = 2) and `ModificationTime` (PaymentStatusId = 7). Status mapping: Completed→2, Failed→3, PendingTransaction→5, else→4. `PaymentSubmitted` count used as visibility gate.
- **`transactions`** — Aggregates `SentTransactions` by `CorrelationId + CryptoId + BlockChainTransactionId` for on-chain fee and TX ID.
- **`chargebacks`** — Only populated when `@FromBackOffice = 1`. Joins `Wallet.Chargebacks` to `Dictionary.ChargebackStatuses` to produce status codes: ChargeBack→6, Refund→7, RefundAsChargeback→8.

**Final SELECT**: COALESCE priority for status is `c.Status` (chargeback) → `p.Status` (payment) → `r.Status` (request). Filtered by `p.PaymentSubmitted > 0 OR @FromBackOffice = 1`. Joins `Wallet.FiatTypes` for the fiat currency name.

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
| `@FromBackOffice` | BIT | 0 | 0 = customer API (hides chargebacks, applies payment gate); 1 = back-office mode |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `CorrelationId` | UNIQUEIDENTIFIER | Cross-system correlation key |
| `BeginDate` | DATETIME2(7) | Timestamp the payment request was initiated |
| `Amount` | DECIMAL(36,18) | Crypto amount purchased |
| `Status` | INT | 0=Pending, 2=Completed, 3=Failed, 4=Default, 5=PendingTransaction, 6=Chargeback, 7=Refund, 8=RefundAsChargeback |
| `BlockChainTransactionId` | NVARCHAR(100) | On-chain transaction ID |
| `Address` | NVARCHAR(MAX) | Destination crypto address |
| `TransactionType` | INT | Hardcoded to 4 (payment/buy) |
| `BlockchainFees` | DECIMAL(36,18) | Actual blockchain fee (or estimated) |
| `ProviderPaymentId` | VARCHAR(100) | External payment provider reference ID |
| `FiatId` | INT | Fiat currency ID |
| `FiatName` | VARCHAR(20) | Fiat currency name (from FiatTypes) |
| `FiatAmount` | DECIMAL(36,18) | Fiat amount paid |
| `ExchangeRate` | DECIMAL(36,18) | Fiat-to-crypto exchange rate |
| `EtoroFeePercentage` | DECIMAL(36,18) | eToro platform fee percentage |
| `EtoroFeeCalculated` | DECIMAL(36,18) | eToro platform fee amount |
| `ProviderFeePercentage` | DECIMAL(36,18) | Payment provider fee percentage |
| `ProviderFeeCalculated` | DECIMAL(36,18) | Payment provider fee amount |
| `InitiationTime` | DATETIME2(7) | Time payment reached ProviderSubmitted status (StatusId = 2) |
| `ModificationTime` | DATETIME2(7) | Time payment reached final status (StatusId = 7) |
| `ChargebackDate` | DATETIME2(7) | Date of chargeback/refund (back-office only) |
| `ChargebackAmount` | DECIMAL(36,18) | Chargeback/refund amount (back-office only) |
| `ChargebackDescription` | VARCHAR(256) | Chargeback description (back-office only) |
| `ChargebackVerificationCode` | VARCHAR(20) | Chargeback verification code (back-office only) |
| `TransactionError` | VARCHAR(MAX) | Last error text from `Wallet.GetRequestLastError` |

---

## 5. Relationships

### 5.1 References To

| Object | Schema | Type | Purpose |
|--------|--------|------|---------|
| `Requests` | Wallet | Table | Payment request source (RequestTypeId = 2) |
| `RequestStatuses` | Wallet | Table | Status name resolution |
| `RequestStatuses` | Dictionary | Table | Status name lookup |
| `Payments` | Wallet | Table | Payment lifecycle records |
| `PaymentStatuses` | Wallet | Table | Payment status history |
| `PaymentStatuses` | Dictionary | Table | Payment status name lookup |
| `PaymentTransactions` | Wallet | Table | Crypto amount, address, exchange rate, fees |
| `CustomerWalletsView` | Wallet | View | Wallet lookup for context |
| `SentTransactions` | Wallet | Table | Blockchain TX ID and fee |
| `Chargebacks` | Wallet | Table | Chargeback/refund records (back-office) |
| `ChargebackStatuses` | Dictionary | Table | Chargeback status name lookup |
| `FiatTypes` | Wallet | Table | Fiat currency name lookup |
| `GetRequestLastError` | Wallet | Function | Retrieves last error JSON for a request |

### 5.2 Referenced By

| Object | Type | Notes |
|--------|------|-------|
| Wallet payment transaction list API procedures | Stored Procedure | Customer-facing payment history endpoint |
| Back-office payment and chargeback reports | Stored Procedure | Called with @FromBackOffice = 1 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPaymentTransactionList
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

- Wallet API payment transaction list stored procedures
- Back-office payment dispute and chargeback reporting

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. Get all payments for a customer in the last 90 days (customer API mode):**
```sql
SELECT *
FROM Wallet.GetPaymentTransactionList(
    123456, NULL,
    DATEADD(DAY, -90, GETUTCDATE()),
    GETUTCDATE(),
    500,
    0
)
ORDER BY BeginDate DESC;
```

**2. Back-office query including chargeback details:**
```sql
SELECT CorrelationId, BeginDate, Amount, Status,
       ProviderPaymentId, FiatAmount, FiatName,
       ChargebackDate, ChargebackAmount, ChargebackDescription
FROM Wallet.GetPaymentTransactionList(
    123456, NULL,
    '2025-01-01', '2026-01-01',
    10000,
    1   -- @FromBackOffice = 1
)
WHERE Status IN (6, 7, 8);  -- Chargeback, Refund, RefundAsChargeback
```

**3. Summarize fee breakdown for completed payments:**
```sql
SELECT SUM(FiatAmount) AS TotalFiat,
       SUM(EtoroFeeCalculated) AS TotalEtoroFees,
       SUM(ProviderFeeCalculated) AS TotalProviderFees,
       COUNT(*) AS PaymentCount
FROM Wallet.GetPaymentTransactionList(
    123456, NULL,
    '2025-01-01', NULL,
    10000, 0
)
WHERE Status = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPaymentTransactionList | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetPaymentTransactionList.sql*
