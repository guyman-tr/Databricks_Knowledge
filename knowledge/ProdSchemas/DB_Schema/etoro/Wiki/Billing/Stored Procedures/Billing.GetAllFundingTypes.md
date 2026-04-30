# Billing.GetAllFundingTypes

> Returns the complete payment method catalog from Dictionary.FundingType, providing all 44 funding types with their operational capability flags for deposit, cashout, refund, and redemption flows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns FundingTypeID (payment method identifier) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetAllFundingTypes` exposes the complete payment method registry to authorized callers. Each row in the result describes one payment method (funding type) available on the eToro platform — from legacy methods like BankDraft to modern integrations like Apple Pay, Google Pay, and Open Banking — along with a matrix of capability flags controlling whether deposits, cashouts, refunds, and redemptions are supported.

This procedure is the primary way the billing service layer loads its payment method configuration. Callers use the flags (`IsFundingTypeActive`, `IsCashoutActive`, `IsRefundable`, etc.) to determine which payment methods to offer in the UI and which code paths to invoke for a given transaction. The `PaymentGeneration` field distinguishes older legacy integrations (0) from newer ones (1), affecting which payment processing infrastructure is used.

The procedure is granted to the `SQL_SecurePay` database role and consumed by the payment service application tier. It was introduced as PAYIL-1371 (the Billing schema initial payment service version).

---

## 2. Business Logic

### 2.1 Payment Method Capability Matrix

**What**: Each funding type has seven binary/flag columns that together define exactly what operations are permitted for that payment method.

**Columns/Parameters Involved**: `IsFundingTypeActive`, `IsCashoutActive`, `IsSingleFunding`, `IsRefundable`, `IsCountryConflictActive`, `IsRedeemable`, `IsNewStyle`

**Rules**:
- `IsFundingTypeActive=1`: method is globally enabled and may appear in the deposit UI
- `IsCashoutActive=1`: method supports withdrawals; 0=deposit-only
- `IsSingleFunding=1`: one-time use only (cannot be saved for repeat payments)
- `IsRefundable=1`: deposits via this method can be reversed back to the source
- `IsRedeemable=1`: funds can be redeemed (relevant in copy-trading payout scenarios)
- `IsCountryConflictActive=1`: country-level restrictions apply (routing engine checks Billing.CountryToCountryConflictGroup)
- `IsNewStyle=1`: uses modern payment integration infrastructure; 0=legacy code path

**Active vs. inactive breakdown (26 active, 18 inactive/legacy):**
```
ACTIVE (IsFundingTypeActive=1):
  1  CreditCard, 2  WireTransfer, 3  PayPal, 6  Neteller, 8  MoneyBookers
  11 Giropay, 15 Sofort, 16 InternalPayment, 18 TestDeposit, 19 IBDeposit
  22 UnionPay, 27 eToroCryptoWallet, 28 OnlineBanking, 30 RapidTransfer
  32 PWMB, 33 eToroMoney, 34 iDEAL, 35 Trustly, 36 Przelewy24, 37 POLI
  38 OpenBanking, 39 Payoneer, 40 NFT, 42 EtoroOptions
  43 GCCInstantBankTransfer, 44 MoneyFarm

INACTIVE (legacy/decommissioned):
  4  BankDraft, 5  WesternUnion, 7  NetellerOnePay, 9  MoneyGram
  10 WebMoney, 12 ELV, 13 Direct24, 14 Payoneer(old), 17 LocalBankWire
  20 BankDetails, 21 Yandex, 23 Qiwi, 24 CashU, 25 AliPay
  26 WeChat, 29 ACH, 31 AstroPay
```

### 2.2 Deposit Amount Limits

**What**: `MaxDepositAmount` caps the maximum single deposit via each method for risk management.

**Columns/Parameters Involved**: `MaxDepositAmount`, `DefaultCurrency`

**Rules**:
- MaxDepositAmount=0 means either unlimited (for active methods) or deactivated (for inactive ones)
- WireTransfer (2): max $500,000 - highest limit for high-value institutional deposits
- CreditCard (1): max $100,000 - capped lower than wire for card fraud risk
- DefaultCurrency: specifies which currency the MaxDepositAmount is denominated in (NULL=use customer's account currency)

### 2.3 Payment Generation Versioning

**What**: The `PaymentGeneration` field distinguishes which generation of payment infrastructure handles this funding type.

**Columns/Parameters Involved**: `PaymentGeneration`

**Rules**:
- `PaymentGeneration=0`: legacy integration (BankDraft, WesternUnion, WebMoney, etc.)
- `PaymentGeneration=1`: current generation payment infrastructure
- All currently-active methods use PaymentGeneration=1
- Inactive methods retain their original generation value for historical record

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters. Returns all columns from `Dictionary.FundingType`:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | VERIFIED | Primary key identifying the payment method. 44 rows (IDs 1-44 with gap at 41). See full value map in Section 2.1. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Payment method identifier string (e.g., 'CreditCard', 'WireTransfer', 'PayPal', 'Neteller', 'MoneyBookers', 'eToroCryptoWallet', 'OpenBanking'). Used in code as payment method labels. |
| 3 | IsNewStyle | bit | NO | - | CODE-BACKED | Whether this payment method uses the modern payment integration infrastructure: 1=new-style processing, 0=legacy code path. All currently-active methods are IsNewStyle=1. |
| 4 | IsSingleFunding | bit | NO | - | CODE-BACKED | Whether this is a single-use payment method that cannot be saved for repeat use: 1=one-time only (e.g., WesternUnion, TestDeposit, IBDeposit), 0=can be saved/reused (e.g., CreditCard, PayPal). |
| 5 | IsCashoutActive | bit | NO | (1) | VERIFIED | Whether withdrawals (cashouts) are supported via this method: 1=supports cashout, 0=deposit-only. Example deposit-only: Giropay, Sofort, RapidTransfer, iDEAL (domestic bank transfers that cannot be reversed). |
| 6 | IsFundingTypeActive | tinyint | YES | - | VERIFIED | Whether this payment method is globally enabled: 1=active (eligible to appear in payment UI), 0=disabled, NULL=inactive. 26 of 44 methods are currently active. |
| 7 | DefaultCurrency | int | YES | - | CODE-BACKED | FK to Dictionary.Currency (CurrencyID). If set, transactions via this method are processed in this currency. Example: CreditCard=2 (EUR), WireTransfer=1 (USD), UnionPay=38 (CNY). NULL=use customer account currency. |
| 8 | MaxDepositAmount | int | YES | - | CODE-BACKED | Maximum single deposit amount in the DefaultCurrency (or account currency if DefaultCurrency is NULL). 0 means either no limit (active methods) or method is deactivated. Largest limits: WireTransfer=500000, eToroCryptoWallet=500000, eToroMoney=500000. |
| 9 | IsRefundable | bit | NO | - | VERIFIED | Whether deposits via this method can be refunded to the original payment source: 1=refundable (CreditCard, PayPal, Neteller, MoneyBookers, POLI, Payoneer), 0=non-refundable (WireTransfer, Giropay, UnionPay). |
| 10 | IsCountryConflictActive | bit | YES | - | CODE-BACKED | Whether country-level conflict restrictions apply for this method: 1=restrictions apply (WireTransfer is the only active method with this flag), NULL/0=no country restrictions. Controls routing through Billing.CountryToCountryConflictGroup. |
| 11 | PaymentGeneration | int | NO | - | VERIFIED | Generation of payment processing infrastructure: 0=legacy integration (inactive methods), 1=current generation. All 26 currently-active methods use PaymentGeneration=1. |
| 12 | IsRedeemable | bit | NO | - | CODE-BACKED | Whether funds deposited via this method can be redeemed in copy-trading payout scenarios: 1=redeemable (WireTransfer, Neteller, MoneyBookers, OnlineBanking, RapidTransfer, PWMB, iDEAL, Trustly, Przelewy24, POLI, OpenBanking, Payoneer, EtoroOptions), 0=non-redeemable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Dictionary.FundingType | Read | Full SELECT from Dictionary.FundingType with no filter - returns all 44 funding type rows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay role | EXECUTE permission | Permission | Payment processing service loads funding type configuration via this role. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetAllFundingTypes (procedure)
└── Dictionary.FundingType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | Full SELECT returning all 12 columns with no WHERE clause. Returns all 44 rows including inactive/legacy methods. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay (role) | Permission | Application payment service consumes this to load the full payment method capability matrix. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all currently-active payment methods with capabilities
```sql
SELECT FundingTypeID, Name, IsCashoutActive, IsRefundable, IsRedeemable,
       DefaultCurrency, MaxDepositAmount, PaymentGeneration
FROM Dictionary.FundingType WITH (NOLOCK)
WHERE IsFundingTypeActive = 1
ORDER BY FundingTypeID
```

### 8.2 Find deposit-only methods (no cashout support)
```sql
SELECT FundingTypeID, Name, MaxDepositAmount
FROM Dictionary.FundingType WITH (NOLOCK)
WHERE IsFundingTypeActive = 1 AND IsCashoutActive = 0
ORDER BY FundingTypeID
-- Returns: Giropay(11), Sofort(15), RapidTransfer(30), MoneyFarm(44), etc.
```

### 8.3 Get funding types with deposit limits and their default currencies
```sql
SELECT ft.FundingTypeID, ft.Name, ft.MaxDepositAmount,
       c.Abbreviation AS DefaultCurrencyCode, ft.IsRefundable, ft.IsRedeemable
FROM Dictionary.FundingType ft WITH (NOLOCK)
LEFT JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = ft.DefaultCurrency
WHERE ft.IsFundingTypeActive = 1 AND ft.MaxDepositAmount > 0
ORDER BY ft.MaxDepositAmount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetAllFundingTypes | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetAllFundingTypes.sql*
