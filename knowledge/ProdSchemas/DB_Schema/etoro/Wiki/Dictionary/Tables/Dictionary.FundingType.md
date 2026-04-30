# Dictionary.FundingType

> System-versioned lookup table defining the 24 payment methods/providers available on the eToro platform, with per-method operational flags.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (System-Versioned / Temporal) |
| **Key Identifier** | FundingTypeID (INT, NONCLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **History Table** | History.FundingType |
| **Indexes** | 3 active (PK nonclustered + 2 NC on active/ID) |

---

## 1. Business Meaning

Dictionary.FundingType defines every payment method available on the eToro platform — credit cards, wire transfers, e-wallets (PayPal, Skrill, Neteller), and newer payment providers (Trustly, Rapid Transfer, Apple Pay, Google Pay). Each method has operational flags controlling whether it can be used for deposits, withdrawals (cashouts), and refunds.

This is one of the most configuration-heavy Dictionary tables. The flags control which payment methods appear in the deposit/withdrawal UI, which support cashout, which count as single-use payment sources, and which are active at all. Changes to these flags directly affect what users see and can do in the payment flow.

Being **system-versioned** (temporal table with History.FundingType), every change to funding type configuration is automatically tracked with timestamps. This enables auditing of when payment methods were enabled/disabled — critical for regulatory compliance and incident investigation.

The computed Trace column captures execution context (hostname, app name, SPID) for every DML operation, providing additional audit capability.

---

## 2. Business Logic

### 2.1 Payment Method Capability Matrix

**What**: Each funding type has a matrix of capabilities controlling its behavior in deposit/withdrawal flows.

**Columns/Parameters Involved**: `IsFundingTypeActive`, `IsCashoutActive`, `IsSingleFunding`, `IsRefundable`, `IsRedeemable`, `IsCountryConflictActive`, `PaymentGeneration`

**Rules**:
- **IsFundingTypeActive=1**: Method appears in deposit UI; =0 disabled globally
- **IsCashoutActive=1**: Method supports withdrawals; =0 deposit-only
- **IsSingleFunding=1**: One-time use — user cannot save this method for repeat use
- **IsRefundable=1**: Deposits via this method can be refunded to the same source
- **IsRedeemable=1**: Funds deposited via this method can be redeemed (copy-trading context)
- **IsCountryConflictActive=1**: Country-specific restrictions apply
- **PaymentGeneration**: Generation of the payment integration (0=legacy, 1+=newer integrations)

### 2.2 Default Currency Routing

**What**: Some funding types have a default currency for processing.

**Columns/Parameters Involved**: `DefaultCurrency`, `MaxDepositAmount`

**Rules**:
- DefaultCurrency links to Dictionary.Currency — forces deposits through this method to use a specific currency
- MaxDepositAmount caps the maximum single deposit for risk management
- NULL values mean no restriction (use user's account currency, no max)

---

## 3. Data Overview

| FundingTypeID | Name | IsFundingTypeActive | IsCashoutActive | Meaning |
|---|---|---|---|---|
| 1 | CreditCard | 1 | 1 | Standard credit/debit card deposits and withdrawals. The most common payment method. Supports both deposit and cashout. |
| 6 | Wire | 1 | 1 | Bank wire transfer. Used for large deposits. Slower processing but no card-based limits. Supports cashout (bank transfer withdrawal). |
| 7 | PayPal | 1 | 1 | PayPal e-wallet integration. Popular in UK/EU markets. Supports instant deposits and withdrawals back to PayPal account. |
| 13 | Rapid Transfer | 1 | 0 | Rapid online bank transfer. Deposit-only — cannot be used for withdrawals. Faster than traditional wire. |
| 20 | ApplePay | 1 | 0 | Apple Pay mobile payment. Deposit-only. Available on iOS devices. Newer payment generation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | CODE-BACKED | Primary key identifying the payment method. See [Funding Type](_glossary.md#funding-type). (Dictionary.FundingType) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). |
| 3 | IsNewStyle | bit | NO | - | CODE-BACKED | Whether this payment method uses the newer integration style. Affects which code path handles the transaction. |
| 4 | IsSingleFunding | bit | NO | - | CODE-BACKED | Whether this is a one-time payment method (cannot be saved for repeat use). 1=single-use, 0=can be saved. |
| 5 | IsCashoutActive | bit | NO | (1) | CODE-BACKED | Whether withdrawals (cashouts) are supported via this method. 1=supports cashout, 0=deposit-only. |
| 6 | IsFundingTypeActive | tinyint | YES | - | CODE-BACKED | Whether this payment method is globally active. 1=active (shown in UI), 0=disabled. NULL treated as inactive. |
| 7 | DefaultCurrency | int | YES | - | CODE-BACKED | FK to Dictionary.Currency — if set, forces transactions through this method to use this currency. NULL=use user's account currency. |
| 8 | MaxDepositAmount | int | YES | - | CODE-BACKED | Maximum allowed single deposit amount. NULL=no limit. Used for risk management and fraud prevention. |
| 9 | IsRefundable | bit | NO | (0) | CODE-BACKED | Whether deposits via this method can be refunded to the same payment source. Important for chargeback prevention. |
| 10 | IsCountryConflictActive | bit | YES | (0) | CODE-BACKED | Whether country-based availability restrictions apply. 1=some countries are blocked for this method. |
| 11 | PaymentGeneration | int | NO | (0) | CODE-BACKED | Integration generation version. 0=legacy, 1+=newer integrations with different API contracts and flow patterns. |
| 12 | IsRedeemable | bit | NO | (0) | CODE-BACKED | Whether funds deposited via this method can be redeemed in copy-trading (mirror) context. |
| 13 | Trace | computed | - | - | CODE-BACKED | Auto-computed audit column capturing hostname, app name, SPID, and database context for every DML operation. Not stored — calculated on read. |
| 14 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioning row start time. Automatically maintained. Records when this row version became current. |
| 15 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioning row end time. Automatically maintained. 9999-12-31 for current rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DefaultCurrency | Dictionary.Currency | Implicit Lookup | Default processing currency for this payment method |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | FundingTypeID | Implicit Lookup | Payment method used for each deposit |
| Billing cashout tables | FundingTypeID | Implicit Lookup | Payment method used for withdrawals |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DFDT_TPL | NC PK | FundingTypeID ASC | - | - | Active |
| IX_FundingTypeID | NC | FundingTypeID ASC, IsFundingTypeActive ASC | - | - | Active |
| IX_IsFundingTypeActive | NC | IsFundingTypeActive ASC, FundingTypeID ASC | - | - | Active |

### 7.2 System Versioning

| Property | Value |
|----------|-------|
| History Table | History.FundingType |
| Period Columns | ValidFrom, ValidTo |
| Temporal Query | `SELECT * FROM Dictionary.FundingType FOR SYSTEM_TIME AS OF '2025-01-01'` |

---

## 8. Sample Queries

### 8.1 List all active payment methods
```sql
SELECT FundingTypeID, Name, IsCashoutActive, IsRefundable, PaymentGeneration
FROM [Dictionary].[FundingType] WITH (NOLOCK)
WHERE IsFundingTypeActive = 1 ORDER BY Name;
```

### 8.2 View payment method changes over time
```sql
SELECT FundingTypeID, Name, IsFundingTypeActive, IsCashoutActive, ValidFrom, ValidTo
FROM [Dictionary].[FundingType] FOR SYSTEM_TIME ALL
WHERE FundingTypeID = 7 ORDER BY ValidFrom;
```

---

*Generated: 2026-03-13 | Quality: 8.8/10*
*Object: Dictionary.FundingType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FundingType.sql*
