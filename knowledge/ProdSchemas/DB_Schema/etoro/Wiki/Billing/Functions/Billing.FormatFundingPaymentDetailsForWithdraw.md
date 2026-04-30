# Billing.FormatFundingPaymentDetailsForWithdraw

> Inline TVF that formats a withdrawal's funding XML into a human-readable payment details string, with payment-method-specific formatting for 15+ funding types (credit card, wire transfer, PayPal, MoneyBookers, ACH, SEPA, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE with one row: PaymentDetails varchar(max) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.FormatFundingPaymentDetailsForWithdraw is the display formatting layer for withdrawal payment details. Given a funding type and the raw payment data XML, it extracts the relevant fields and assembles a human-readable string appropriate for that payment method. The result is used in back-office reports, operations dashboards, and export files where payment details must be presented to agents without requiring them to parse XML.

This function exists because different payment methods have completely different sets of relevant identifiers. A credit card withdrawal is identified by its BIN code; a wire transfer needs IBAN, BIC, bank name, and sort code; MoneyBookers/Skrill uses an email address; Chinese bank transfers need bank name, account number, and branch code. Centralizing this formatting logic ensures consistent presentation across all reporting surfaces.

The function is referenced from `Billing.Funding` (likely via a computed column or as a formatting reference used in queries against Billing.Funding) and is used in reports consuming withdrawal/funding data.

---

## 2. Business Logic

### 2.1 Per-FundingType Format Rules

**What**: A CASE expression maps each FundingTypeID to its specific set of relevant payment identifiers extracted from the XML.

**Columns/Parameters Involved**: `@FundingTypeID`, `@FundingData`

**Rules**:
- FundingTypeID=1 (Credit Card): `"BinCode:{BinCodeAsString}"` - shows bank identification number.
- FundingTypeID=2 (Wire Transfer): Full bank details - PayeeName, BankName, ClientBankName, AccountID, IBANCode, SwiftCode, Country (via Dictionary.Country JOIN), SortCode, RoutingNumber.
- FundingTypeID=8 (MoneyBookers/Skrill): EmailAsString only.
- FundingTypeID=20 (Western Union): CustomerName + CustomerAddress + BankName + BankAddress + SwiftCode + IbanCode + AccountID + CountryID.
- FundingTypeID=7 (Neteller): AccountIDAsDecimal.
- FundingTypeID=11 (Skrill local): IBAN if available, else AccID from AccountIDAsDecimal.
- FundingTypeID=6 (WebMoney): AccountID + Email.
- FundingTypeID=21 (UnionPay): AccountID + PayerID.
- FundingTypeID=22 (Chinese bank/UnionPay Pro): AccountID + BeneficiaryName + BankName + BankAccount + BranchCode + Province + City + Address.
- FundingTypeID=28 (EU Bank): CID + IBANCode.
- FundingTypeID=29 & 32 (ACH bank types): BankName + last 4 digits of account + account type.
- FundingTypeID=34 (SEPA): IBAN + BIC.
- FundingTypeID=35 (Local bank transfer): AccountID + BankName + AccountHolderName + BankCountry + IBAN + Swift.
- FundingTypeID=43 (Wire v2): PayeeName + ClientBankName + IBANCode + SwiftCode + Country.
- All other FundingTypeIDs: NULL (no formatting defined).

### 2.2 Country Name Resolution

**What**: For funding types that include a country, the function joins Dictionary.Country to resolve CountryIDAsInteger from XML to the country name.

**Columns/Parameters Involved**: `@FundingData`, Dictionary.Country

**Rules**:
- The JOIN uses the XML value `/Funding[1]/CountryIDAsInteger[1]` as the key into Dictionary.Country.CountryID.
- Used by FundingTypeID=2 (wire transfer), 35 (local bank), 43 (wire v2).
- ISNULL(DC.Name, 'Not available') or ISNULL(DC.Name, '') - handles missing/unresolved countries gracefully.

---

## 3. Data Overview

N/A for Table-Valued Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | int | NO | - | VERIFIED | The funding type of the withdrawal. Controls which CASE branch executes and which XML fields are extracted. See Business Logic section 2.1 for all handled funding types. |
| 2 | @FundingData | xml | NO | - | VERIFIED | The funding payment data XML from Billing.Funding.FundingData. Expected root: `<Funding>` with type-specific child elements (BinCodeAsString, IBANCodeAsString, EmailAsString, CustomerNameAsString, etc.). |
| RETURN: PaymentDetails | varchar(max) | YES | - | VERIFIED | Formatted human-readable payment details string. NULL for unrecognized FundingTypeIDs. Format varies by payment method - see Business Logic for per-type format. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryIDAsInteger (from XML) | Dictionary.Country | Lookup (LEFT JOIN) | Resolves country ID to country name for wire transfer, local bank, and wire v2 funding types. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Funding | FundingTypeID, FundingData | Reference | Referenced in queries against Billing.Funding to format payment details for display. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FormatFundingPaymentDetailsForWithdraw (inline TVF)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Resolves CountryIDAsInteger XML value to country name for applicable funding types. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | References this function (via CROSS APPLY in consuming queries) to format FundingData XML for display. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Table-Valued Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| NULL return | Design | Unhandled FundingTypeIDs return NULL as PaymentDetails. New payment methods require adding a new CASE branch. |
| Commented branches | Note | Several CASE branches are commented out (FundingTypeID=3 PayPal, 10 WebMoney purse, 33 eToroCard, etc.) - these payment methods were removed or rerouted. |

---

## 8. Sample Queries

### 8.1 Format payment details for a specific withdrawal

```sql
SELECT pd.PaymentDetails
FROM Billing.Funding f WITH (NOLOCK)
CROSS APPLY Billing.FormatFundingPaymentDetailsForWithdraw(f.FundingTypeID, f.FundingData) pd
WHERE f.FundingID = 98765;
```

### 8.2 Get formatted details for recent wire transfer withdrawals

```sql
SELECT TOP 20
    f.FundingID,
    f.FundingTypeID,
    pd.PaymentDetails
FROM Billing.Funding f WITH (NOLOCK)
CROSS APPLY Billing.FormatFundingPaymentDetailsForWithdraw(f.FundingTypeID, f.FundingData) pd
WHERE f.FundingTypeID = 2  -- Wire Transfer
  AND pd.PaymentDetails IS NOT NULL
ORDER BY f.FundingID DESC;
```

### 8.3 Check which funding types return NULL (unhandled)

```sql
SELECT DISTINCT
    f.FundingTypeID,
    COUNT(*) AS RecordCount
FROM Billing.Funding f WITH (NOLOCK)
CROSS APPLY Billing.FormatFundingPaymentDetailsForWithdraw(f.FundingTypeID, f.FundingData) pd
WHERE pd.PaymentDetails IS NULL
GROUP BY f.FundingTypeID
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FormatFundingPaymentDetailsForWithdraw | Type: Inline Table-Valued Function | Source: etoro/etoro/Billing/Functions/Billing.FormatFundingPaymentDetailsForWithdraw.sql*
