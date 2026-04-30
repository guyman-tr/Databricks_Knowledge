# Billing.FundingPaymentDetailsForWithdraw

> Funding-instrument-only projection with country resolution that surfaces payment instrument details and a computed PaymentDetails field for withdrawal investigation, without joining to any withdrawal transaction table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | FundingID (from Billing.Funding) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.FundingPaymentDetailsForWithdraw` is a lightweight variant of the withdrawal investigation views that exposes payment instrument data with country resolution, WITHOUT joining to withdrawal transaction tables. It is the withdrawal counterpart to `Billing.FundingPaymentDetailsForDeposit`, but with an important addition: it LEFT JOINs `Dictionary.Country` to resolve the country from FundingData XML, enabling proper country display for WireTransfer and Trustly payment methods.

The view was built incrementally by multiple developers: Adi (11/05/2020, bug fix for country display), Ran Ovadia (04/07/2020, added FundingType 22), Shay Oren (16/09/2020, FundingType 35/MIMOPS-2220), Shay Oren (01/11/2020, iDeal/MIMOPS-2621). This version supports more payment types than the deposit variant (adds types 20, 21, 22, 28, 34, 35 with country-aware formatting).

Key difference from `Billing.FundingDataForWithdraw`: this view reads from Billing.Funding only (plus Dictionary.Country), so it does NOT include WithdrawToFunding-specific fields (no Amount, CashoutStatusID, etc.). Use this when you need instrument details without execution context.

---

## 2. Business Logic

### 2.1 PaymentDetails with Country Resolution

**What**: Extracts a human-readable account identifier from FundingData XML, with LEFT JOIN to Dictionary.Country enabling country name display for bank-based payment types.

**Columns/Parameters Involved**: `FundingTypeID`, `FundingData`, `PaymentDetails`, `DC.Name` (Dictionary.Country)

**Rules** (key additions vs FundingPaymentDetailsForDeposit):
- 2 (WireTransfer): Full bank details including DC.Name as country (not NULL like in the deposit view)
- 35 (Trustly): AccountID, BankName (from ClientBankNameAsString), AccountHolderName, DC.Name as BankCountry, IBAN, SWIFT
- 34 (SEPA): IBAN + BIC
- 20 (international bank): Full bank details
- 21, 22, 28 (local bank variants): Various combinations of account ID, customer name, bank name, branch/province/city
- Country JOIN: `BFUN.FundingData.value('/Funding[1]/CountryIDAsInteger[1]', 'INT') = DC.CountryID` (direct INT cast, unlike FundingDataForWithdraw which uses CAST(NULLIF(...)) pattern)
- eToroMoney (type 33): Commented out in this view (uses WithdrawData fields not available here)

---

## 3. Data Overview

N/A - exposes all ~3.5M rows of Billing.Funding with Dictionary.Country JOIN. Country will be NULL for instruments without a CountryIDAsInteger in FundingData (e.g., credit cards, most e-wallets).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Payment instrument PK. From Billing.Funding. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. From Billing.Funding. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | Operations manager who created/modified this instrument. NULL=self-registered. |
| 4 | IsBlocked | bit | NO | - | CODE-BACKED | 1=instrument blocked. 0=active. From Billing.Funding. |
| 5 | BlockedDescription | nvarchar | YES | - | CODE-BACKED | Reason for block. NULL if not blocked. From Billing.Funding. |
| 6 | BlockedAt | datetime | YES | - | CODE-BACKED | When blocked. NULL if not blocked. From Billing.Funding. |
| 7 | FundingData | nvarchar(4000) | YES | - | CODE-BACKED | FundingData XML CAST to NVARCHAR(4000). Subject to DDM masking. |
| 8 | IsRefundExcluded | bit | NO | - | CODE-BACKED | 1=excluded from automatic refund. From Billing.Funding. |
| 9 | DocumentRequired | bit | NO | - | CODE-BACKED | 1=KYC documentation required. From Billing.Funding. |
| 10 | DateCreated | datetime | NO | - | CODE-BACKED | UTC timestamp of instrument registration. From Billing.Funding. |
| 11 | PaymentDetails | varchar | YES | - | CODE-BACKED | Computed human-readable payment account identifier from FundingData XML with country name from Dictionary.Country. WireTransfer (type 2) includes country name (unlike FundingPaymentDetailsForDeposit). eToroMoney (type 33) is commented out. Covers more types than the deposit variant: adds 20, 21, 22, 28, 34, 35. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All Funding columns | Billing.Funding | Source (FROM) | Payment instrument data |
| PaymentDetails (country) | Dictionary.Country | Source (LEFT JOIN via CountryIDAsInteger) | Country name for WireTransfer and Trustly payment details display |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedures in Billing schema reference this view | - | - | Ad-hoc instrument lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingPaymentDetailsForWithdraw (view)
├── Billing.Funding (table)
└── Dictionary.Country (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | FROM source: all payment instrument rows |
| Dictionary.Country | Table | LEFT JOIN: CountryIDAsInteger from FundingData XML -> country name for WireTransfer/Trustly PaymentDetails |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered | - | Ad-hoc lookup view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Country JOIN uses direct INT cast: `FundingData.value(..., 'INT')` - will throw on malformed XML values (unlike FundingDataForWithdraw which uses safer CAST(NULLIF(...)). Multiple authors: Adi, Ran Ovadia, Shay Oren (MIMOPS-2220, MIMOPS-2621).

---

## 8. Sample Queries

### 8.1 Look up a specific payment instrument with full details

```sql
SELECT FundingID, FundingTypeID, PaymentDetails, IsBlocked, BlockedDescription, DateCreated
FROM Billing.FundingPaymentDetailsForWithdraw WITH (NOLOCK)
WHERE FundingID = @FundingID
```

### 8.2 Find WireTransfer instruments by country

```sql
SELECT FundingID, PaymentDetails, DateCreated
FROM Billing.FundingPaymentDetailsForWithdraw WITH (NOLOCK)
WHERE FundingTypeID = 2  -- WireTransfer
  AND PaymentDetails LIKE '%Country : France%'
ORDER BY DateCreated DESC
```

### 8.3 Find all Trustly instruments for audit

```sql
SELECT FundingID, PaymentDetails, DateCreated, IsBlocked
FROM Billing.FundingPaymentDetailsForWithdraw WITH (NOLOCK)
WHERE FundingTypeID = 35  -- Trustly
ORDER BY DateCreated DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-2220 | Jira (referenced in DDL comment) | Shay Oren 16/09/2020 - added FundingType 35 (Trustly) handling |
| MIMOPS-2621 | Jira (referenced in DDL comment) | Shay Oren 01/11/2020 - added iDeal handling |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 2 Jira (DDL comment refs) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingPaymentDetailsForWithdraw | Type: View | Source: etoro/etoro/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.sql*
