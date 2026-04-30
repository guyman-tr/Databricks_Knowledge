# Billing.GetCashoutInfo

> Customer contact and KYC enrichment view for cashout processing, joining customer identity data with their successfully processed withdrawal payment method details for compliance and operations review.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | CID (customer) + FundingTypeID (payment method) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.GetCashoutInfo` answers the question "who is this customer and how do they withdraw?" by combining a customer's identity/contact data (from Customer schema) with their withdrawal payment method details (from Billing schema). Each row represents a customer and one payment instrument they have used in a processed (CashoutStatusID=3) withdrawal, enriched with the customer's contact info, KYC verification status, country, and state.

The view exists for operations teams that need to verify customer identity alongside their payment details when reviewing or approving cashout requests. Compliance workflows (AML/KYC checks), cashout dispute resolution, and customer service agents use this view to get the full picture without manually joining tables across schemas.

Data flows from Customer.CustomerStatic and BackOffice.Customer (INNER JOIN - only verified registered customers), then LEFT JOINs to Billing.Withdraw (the cashout request), Billing.WithdrawToFunding (filtered to CashoutStatusID=3=Processed to avoid showing pending/failed legs), Billing.Funding (excluding credit cards, FundingTypeID!=1), and Dictionary lookups for country, state, and funding type names. With 18.9M rows, this is a very large view and should always be filtered by CID or FundingTypeID in queries.

---

## 2. Business Logic

### 2.1 Processed Cashout Filter - Excluding Pending and Failed Legs

**What**: Only withdrawal legs that were successfully processed (money actually sent) are shown, excluding pending, canceled, and rejected legs.

**Columns/Parameters Involved**: `CashoutStatusID` (from Billing.Withdraw)

**Rules**:
- JOIN condition: `BWDR.CashoutStatusID = 3` (Processed - money sent successfully)
- Other status values (1=Pending, 4=Canceled, 7=Rejected, etc.) are excluded from the join
- Effect: the view shows payment methods that customers have successfully used to receive money, not just requested

### 2.2 Credit Card Exclusion

**What**: Credit card payment instruments (FundingTypeID=1) are excluded from the view.

**Columns/Parameters Involved**: `FundingTypeID`, `FundingData`

**Rules**:
- JOIN condition: `BFUN.FundingTypeID != 1` (excludes CreditCard)
- Credit cards typically cannot receive cashouts (regulatory requirement) - only used for deposits
- The BankName, Beneficiary, AccountID, Email, BankAccount, PurseNumber fields are only relevant for non-CC payment methods
- A customer with only credit card instruments will appear with NULL for all payment method fields (left join result)

### 2.3 Payment Method Detail Extraction per FundingType

**What**: Different payment methods store different account identifiers in XML; the view extracts the relevant one per type.

**Columns/Parameters Involved**: `FundingTypeID`, `BankName`, `Beneficiary`, `Email`, `AccountID`, `BankAddress`, `BankAccount`, `PurseNumber`

**Rules**:
- FundingTypeID 2 (WireTransfer): BankName from WithdrawData XML, Beneficiary (PayeeName) from WithdrawData, BankAccount (AccountID) from WithdrawData
- FundingTypeID 4 (similar): BankName + BankAddress from WithdrawData
- FundingTypeID 3 or 8 (PayPal/similar): Email from FundingData
- FundingTypeID 6, 7, or 10 (Neteller/Skrill/WebMoney): AccountID from FundingData
- FundingTypeID 10 (WebMoney): PurseNumber from WithdrawData
- All other types: NULL for all computed columns

---

## 3. Data Overview

N/A for view - the view has 18.9M rows and should not be fully scanned. Typical use is filtering by CID:

| CID | FundingTypeID | FundingType | FullName | Verified | Country | Email | AccountID | BankName | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| (example) | 2 | WireTransfer | John Smith | 1 | United Kingdom | (null) | GB12BARC20201012345678 | Barclays Bank | Verified UK customer with a processed wire transfer withdrawal - shows bank details for AML verification. |
| (example) | 6 | Neteller | Maria Garcia | 1 | Spain | (null) | 456789012 | (null) | Spanish customer who successfully withdrew via Neteller to account 456789012. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | YES | - | CODE-BACKED | Payment method type used for the processed cashout. From Dictionary.FundingType. NULL if no processed cashout exists for this customer (LEFT JOIN result). 2=WireTransfer, 3=PayPal, 6=Neteller, 7=Skrill, 8=similar, 10=WebMoney, etc. CreditCard (1) is always NULL here (excluded). |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. From Customer.CustomerStatic. INNER JOIN anchor - every row has a CID. The base customer identity. |
| 3 | FullName | nvarchar | YES | - | CODE-BACKED | Customer's full name: CONCAT(FirstName, ' ', LastName). From Customer.CustomerStatic. Used for identity verification in cashout review. |
| 4 | Address | nvarchar | YES | - | CODE-BACKED | Customer's registered street address. From Customer.CustomerStatic. Used for address verification (AML). |
| 5 | City | nvarchar | YES | - | CODE-BACKED | Customer's registered city. From Customer.CustomerStatic. |
| 6 | Phone | nvarchar | YES | - | CODE-BACKED | Customer's registered phone number. From Customer.CustomerStatic. Used for contact verification in cashout workflows. |
| 7 | Zip | nvarchar | YES | - | CODE-BACKED | Customer's postal/zip code. From Customer.CustomerStatic. |
| 8 | CustomerEmail | nvarchar | YES | - | CODE-BACKED | Customer's account email address. From Customer.CustomerStatic. Distinct from the Email column (Element 15) which is the e-wallet account email. |
| 9 | UserName | nvarchar | YES | - | CODE-BACKED | Customer's eToro username. From Customer.CustomerStatic. Used in all customer communications and audit logs. |
| 10 | Verified | bit | YES | - | CODE-BACKED | KYC verification status. From BackOffice.Customer. 1=customer has passed identity verification (documents submitted and approved). 0=not verified. NULL if not in BackOffice.Customer. Critical for cashout processing - unverified customers may require additional review. |
| 11 | Country | nvarchar | YES | - | CODE-BACKED | Customer's registered country name. From Dictionary.Country (via CCST.CountryID). Human-readable country for compliance and routing decisions. |
| 12 | State | nvarchar | YES | - | CODE-BACKED | Customer's registered state/province name. From Dictionary.State (via CCST.StateID). Used for US customers and other regions with state-level regulation. |
| 13 | FundingType | nvarchar | YES | - | CODE-BACKED | Human-readable payment method name. From Dictionary.FundingType. NULL if no non-CC processed cashout exists for this customer. |
| 14 | BankName | nvarchar | YES | - | CODE-BACKED | Bank name for wire transfer (FundingTypeID=2) and type 4 cashouts. Extracted from WithdrawData XML. NULL for other payment types. |
| 15 | Beneficiary | nvarchar | YES | - | CODE-BACKED | Payee/beneficiary name for wire transfer cashouts (FundingTypeID=2). From WithdrawData XML `/Withdraw/PayeeNameAsString`. Used to verify the wire transfer recipient matches the customer's identity. |
| 16 | Email | nvarchar | YES | - | CODE-BACKED | E-wallet account email for PayPal (FundingTypeID=3) and type 8 cashouts. From FundingData XML `/Funding/EmailAsString`. NULL for non-email payment types. Distinct from CustomerEmail (Element 8). |
| 17 | AccountID | nvarchar | YES | - | CODE-BACKED | E-wallet account identifier for Neteller (6), Skrill (7), WebMoney (10) cashouts. From FundingData XML `/Funding/AccountIDAsDecimal`. NULL for other types. |
| 18 | BankAddress | nvarchar | YES | - | CODE-BACKED | Bank's physical address for type 4 cashouts. From WithdrawData XML `/Withdraw/AddressAsString`. NULL for other types. |
| 19 | BankAccount | nvarchar | YES | - | CODE-BACKED | Bank account number (or IBAN) for wire transfer (FundingTypeID=2) cashouts. From WithdrawData XML `/Withdraw/AccountIDAsString`. NULL for other types. |
| 20 | PurseNumber | nvarchar | YES | - | CODE-BACKED | WebMoney purse ID (FundingTypeID=10). From WithdrawData XML `/Withdraw/PayerPurseAsString`. NULL for other types. Used to identify the specific WebMoney wallet receiving the funds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, FullName, Address, ... | Customer.CustomerStatic | Source (INNER JOIN anchor) | Customer identity and contact data |
| Verified | BackOffice.Customer | Source (INNER JOIN on CID) | KYC verification status |
| WithdrawID | Billing.Withdraw | Source (LEFT JOIN via CID) | Withdrawal requests |
| FundingID, CashoutStatusID, WithdrawData | Billing.WithdrawToFunding | Source (LEFT JOIN, CashoutStatusID=3 filter) | Processed withdrawal payment legs only |
| FundingData, FundingTypeID | Billing.Funding | Source (LEFT JOIN, FundingTypeID!=1) | Non-CC payment instrument data |
| FundingType | Dictionary.FundingType | Source (LEFT JOIN) | Payment method name lookup |
| Country | Dictionary.Country | Source (LEFT JOIN via CountryID) | Country name |
| State | Dictionary.State | Source (LEFT JOIN via StateID) | State/province name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedures in Billing schema reference this view | - | - | Compliance/operations ad-hoc query view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCashoutInfo (view)
├── Customer.CustomerStatic (table, cross-schema)
├── BackOffice.Customer (table, cross-schema)
├── Billing.Withdraw (table)
├── Billing.WithdrawToFunding (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table, cross-schema)
├── Dictionary.Country (table, cross-schema)
└── Dictionary.State (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | INNER JOIN anchor: customer identity, contact, country, state |
| BackOffice.Customer | Table | INNER JOIN: KYC Verified flag |
| Billing.Withdraw | Table | LEFT JOIN via CID: withdrawal requests |
| Billing.WithdrawToFunding | Table | LEFT JOIN via WithdrawID, filter CashoutStatusID=3: processed payment legs |
| Billing.Funding | Table | LEFT JOIN via FundingID, exclude FundingTypeID=1: non-CC payment instruments |
| Dictionary.FundingType | Table | LEFT JOIN via FundingTypeID: payment method name |
| Dictionary.Country | Table | LEFT JOIN via CountryID: country name |
| Dictionary.State | Table | LEFT JOIN via StateID: state name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered | - | Ad-hoc compliance query view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Performance warning: 18.9M rows. Always filter by CID when querying. The Customer.CustomerStatic anchor is indexed by CID; Billing.Withdraw has a CID index; Billing.WithdrawToFunding has WithdrawID+CashoutStatusID coverage.

### 7.2 Constraints

N/A for view. No SCHEMABINDING (cross-schema). Multiple LEFT JOINs produce NULL for all payment method columns when no non-CC processed cashout exists for a customer. FundingTypeID exclusion: `BFUN.FundingTypeID != 1` means CreditCard withdrawals (if any) are excluded.

---

## 8. Sample Queries

### 8.1 Get cashout details for a specific customer

```sql
SELECT CID, FullName, Country, FundingType, BankName, BankAccount, AccountID, Email, Verified
FROM Billing.GetCashoutInfo WITH (NOLOCK)
WHERE CID = @CustomerID
```

### 8.2 Find unverified customers with processed wire transfer cashouts

```sql
SELECT CID, FullName, Country, BankName, BankAccount, Beneficiary, CustomerEmail
FROM Billing.GetCashoutInfo WITH (NOLOCK)
WHERE Verified = 0
  AND FundingTypeID = 2  -- WireTransfer
ORDER BY CID
```

### 8.3 Count customers by withdrawal method for a country

```sql
SELECT Country, FundingType, COUNT(DISTINCT CID) AS CustomerCount
FROM Billing.GetCashoutInfo WITH (NOLOCK)
WHERE Country = 'United Kingdom'
  AND FundingTypeID IS NOT NULL
GROUP BY Country, FundingType
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCashoutInfo | Type: View | Source: etoro/etoro/Billing/Views/Billing.GetCashoutInfo.sql*
