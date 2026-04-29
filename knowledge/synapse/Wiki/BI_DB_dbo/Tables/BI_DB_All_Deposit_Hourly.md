# BI_DB_dbo.BI_DB_All_Deposit_Hourly

> **DORMANT -- 0 rows, no writer SP, fully orphaned.** 117-column hourly deposit transaction table combining core deposit fields (CID, amounts, currency, payment status, customer demographics, risk assessment, regulation) with ~80 flattened payment service provider (PSP) response attributes following the `*AsString`/`*AsDecimal`/`*AsInteger` naming convention. Designed for payments operations monitoring with full PSP response payload for fraud analysis, payment debugging, and reconciliation. ROUND_ROBIN with CLUSTERED INDEX on CID. No stored procedure in Synapse SSDT reads or writes this table. Related to BI_DB_AllDeposits_Tempalte (126 cols, also dormant).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown -- no writer SP in SSDT, no references |
| **Refresh** | **DORMANT** -- no active ETL process |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **Row Count** | 0 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_All_Deposit_Hourly` was designed as an **hourly deposit transaction feed** capturing every deposit event with full payment service provider (PSP) response details. The table combines standard deposit fields with ~80 flattened PSP response attributes, creating a comprehensive payments operations dataset.

Key design characteristics:
- **Transaction grain**: Each row = one deposit transaction
- **Core deposit fields** (columns 1-36): Customer (CID), deposit amounts (original currency + USD), dates, payment status, card/bank details, risk assessment, regulation, affiliate
- **PSP response payload** (columns 37-125): Full payment gateway response flattened into individual columns using `*AsString`/`*AsDecimal`/`*AsInteger` naming convention -- covers card details, bank details, customer PII, error codes, 3DS authentication, Plaid integration
- **Metadata** (columns 126-128): Exchange rate, deposit category, depot ID

The table is currently **empty (0 rows)** and **fully orphaned** -- no stored procedure reads or writes it. This was likely an on-prem BI_DB hourly payments monitoring report that either:
1. Was replaced by direct PSP reporting integrations (Stripe, PayPal, Wire dashboards)
2. Was migrated to Databricks payment analytics pipelines
3. Was a custom development for the payments operations team that was never completed in Synapse

The PSP response columns contain potentially sensitive data (card numbers, names, addresses, IBANs) -- if this table were ever populated, it would require PII masking/access controls.

**Related table**: `BI_DB_AllDeposits_Tempalte` (126 columns) has a similar structure with additional PSP fields -- likely the template/master version of this hourly variant.

---

## 2. Business Logic

### 2.1 Deposit Amount Dual-Currency Tracking (Inferred)

**What**: Every deposit tracked in both original currency and USD equivalent.
**Columns Involved**: Amount In Orig Curr, Amount in $, Currency, BaseExchangeRate
**Rules**:
- Amount In Orig Curr = deposit amount in the customer's currency
- Amount in $ = converted USD amount (decimal(36,12) for high precision)
- BaseExchangeRate = FX rate used for conversion
- Currency = original currency code (EUR, GBP, AUD, etc.)

### 2.2 Payment Risk Assessment (Inferred)

**What**: Multi-level risk classification for fraud prevention.
**Columns Involved**: PaymentStatus, Deposit Risk Status, RiskStatus, BINCountry, Country (customer), Country By Reg IP
**Rules**:
- Country mismatch detection: BINCountry vs Country (customer) vs Country By Reg IP
- PaymentStatus = PSP-level status (Approved, Declined, Pending)
- Deposit Risk Status = eToro internal risk assessment
- RiskStatus = overall risk classification (potentially AML-related)

### 2.3 PSP Response Payload (Inferred)

**What**: Full payment gateway response flattened into individual columns for debugging and reconciliation.
**Columns Involved**: ~80 `*AsString`/`*AsDecimal`/`*AsInteger` columns
**Rules**:
- Each PSP provider returns different fields; NULL columns indicate the field was not returned by that provider
- Card details: CardNumberAsString, CardTypeIDAsInteger, BinCodeAsString, ExpirationDateAsString
- Bank details: BankCodeAsString, BankNameAsString, IBANCodeAsString, SortCodeAsString, SwiftCodeAsString
- Error handling: ErrorCodeAsString, ErrorTypeAsString, ResponseMessageAsString
- 3DS authentication: ThreeDsAsJson, ThreeDsResponseType
- Plaid integration: PlaidItemIDAsString, PlaidNamesAsString

### 2.4 FTD Identification (Inferred)

**What**: First-time deposit flagging for customer conversion analysis.
**Columns Involved**: IsFTD, FirstDepositDate
**Rules**:
- IsFTD = 1 when the deposit is the customer's first deposit, 0 otherwise
- FirstDepositDate = date of the customer's FTD for cohort analysis

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN -- suitable for this wide table without a natural distribution key
- **Index**: CLUSTERED INDEX on CID -- optimized for customer-level lookups

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Deposit volume by hour | `GROUP BY DATEPART(HOUR, [Deposit Time])` with SUM and COUNT |
| Failed deposits by PSP | `WHERE PaymentStatus = 'Declined' GROUP BY Provider` |
| Country mismatch fraud detection | `WHERE BINCountry <> [Country (customer)]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| N/A | N/A | Table is dormant with 0 rows -- no active join patterns |

### 3.4 Gotchas

- **0 rows**: Table has never been populated in Synapse -- all queries will return empty
- **Column names with spaces**: Many columns use spaces (e.g., `[Amount In Orig Curr]`, `[Country (customer)]`, `[Deposit Time]`) -- must use brackets in all queries
- **PII risk**: PSP response fields contain card numbers, names, addresses, IBANs -- PII masking would be required if populated
- **varchar(max)**: Response column is varchar(max) -- potential performance issue for scans
- **117 columns**: Extremely wide table; SELECT * would be expensive; always select specific columns
- **Related table**: BI_DB_AllDeposits_Tempalte (126 cols) is a similar structure -- check which is the intended target before any reactivation

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki verbatim | Highest -- production-documented |
| Tier 2 | SP code analysis | High -- code is king |
| Tier 3 | Live data evidence | Medium -- empirical |
| Tier 4 | Inferred from column name/type/context | Low -- best guess |
| Tier 5 | ETL metadata (canonical) | Standard ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID -- unique identifier for a customer account in the eToro platform. (Tier 4 -- inferred from name) |
| 2 | DepositID | int | YES | Unique deposit transaction identifier. Likely FK to Billing.Deposit or Billing.Funding. (Tier 4 -- inferred from name) |
| 3 | FundingType | varchar(50) | YES | Payment method used for the deposit (e.g., Credit Card, Wire Transfer, PayPal, Neteller). Likely resolved from Dim_FundingType. (Tier 4 -- inferred from name) |
| 4 | Amount In Orig Curr | money | YES | Deposit amount in the customer's original currency. (Tier 4 -- inferred from name) |
| 5 | Amount in $ | decimal(36,12) | YES | Deposit amount converted to USD. High precision (12 decimal places) for accurate cross-currency aggregation. (Tier 4 -- inferred from name) |
| 6 | Currency | varchar(20) | YES | ISO currency code of the original deposit (e.g., EUR, GBP, AUD). (Tier 4 -- inferred from name) |
| 7 | ModificationDate | datetime | YES | Timestamp of the last modification to the deposit record. (Tier 4 -- inferred from name) |
| 8 | Deposit Time | datetime | YES | Timestamp when the deposit was created/submitted. (Tier 4 -- inferred from name) |
| 9 | Month | int | YES | Month extracted from the deposit date (1-12). (Tier 4 -- inferred from name) |
| 10 | Day | int | YES | Day of month extracted from the deposit date (1-31). (Tier 4 -- inferred from name) |
| 11 | Year | int | YES | Year extracted from the deposit date. (Tier 4 -- inferred from name) |
| 12 | PaymentStatus | varchar(50) | YES | Payment processing status from the PSP (e.g., Approved, Declined, Pending, Error). (Tier 4 -- inferred from name) |
| 13 | Country (customer) | varchar(50) | YES | Country where the customer is registered. (Tier 4 -- inferred from name) |
| 14 | FirstDepositDate | datetime | YES | Date of the customer's first deposit. Used for FTD cohort analysis. (Tier 4 -- inferred from name) |
| 15 | Funnel | varchar(50) | YES | Customer acquisition funnel stage at time of deposit. (Tier 4 -- inferred from name) |
| 16 | FunnelFrom | varchar(50) | YES | Previous funnel stage before the current one. Tracks funnel transitions. (Tier 4 -- inferred from name) |
| 17 | BINCountry | varchar(50) | YES | Country derived from the card BIN (Bank Identification Number). Used for country mismatch fraud detection. (Tier 4 -- inferred from name) |
| 18 | Provider | varchar(50) | YES | Payment service provider (PSP) name processing the deposit (e.g., Stripe, PayPal, Wire). (Tier 4 -- inferred from name) |
| 19 | CardType | varchar(50) | YES | Card network type (e.g., Visa, Mastercard, Amex). (Tier 4 -- inferred from name) |
| 20 | CardSubType | varchar(50) | YES | Card sub-type (e.g., Debit, Credit, Prepaid). (Tier 4 -- inferred from name) |
| 21 | IsFTD | int | YES | First-time deposit flag. 1=this is the customer's first deposit, 0=redeposit. (Tier 4 -- inferred from name) |
| 22 | Country By Reg IP | varchar(50) | YES | Country derived from the customer's registration IP address. Used for geo-mismatch fraud detection. (Tier 4 -- inferred from name) |
| 23 | Deposit Risk Status | varchar(50) | YES | eToro internal risk assessment status for this deposit. (Tier 4 -- inferred from name) |
| 24 | RiskStatus | varchar(100) | YES | Overall risk classification for the deposit (potentially AML-related). (Tier 4 -- inferred from name) |
| 25 | External Transaction ID | char(50) | YES | PSP external transaction reference ID for reconciliation. (Tier 4 -- inferred from name) |
| 26 | Region | varchar(50) | YES | Marketing or geographic region for the customer. (Tier 4 -- inferred from name) |
| 27 | Affiliate ID | int | YES | Referring affiliate partner ID. FK to fiktivo affiliate system. (Tier 4 -- inferred from name) |
| 28 | Account Manager | nvarchar(101) | YES | Full name of the assigned account manager. (Tier 4 -- inferred from name) |
| 29 | BinCode | bigint | YES | Card BIN code (first 6-8 digits of card number). Used for issuer identification. (Tier 4 -- inferred from name) |
| 30 | Bank name by Bincode | varchar(100) | YES | Issuing bank name resolved from the BIN code. (Tier 4 -- inferred from name) |
| 31 | Regulation | varchar(50) | YES | Active regulatory jurisdiction governing the customer. (Tier 4 -- inferred from name) |
| 32 | DesignatedRegulation | varchar(50) | YES | Designated (original) regulatory jurisdiction for the customer. May differ from Regulation after migrations. (Tier 4 -- inferred from name) |
| 33 | MID | nvarchar(250) | YES | Merchant Identification Number used for the payment transaction. Identifies the eToro merchant account at the PSP. (Tier 4 -- inferred from name) |
| 34 | UpdateDate | datetime | YES | Timestamp of last row update. (Tier 5 -- ETL metadata) |
| 35 | Response | varchar(max) | YES | Full raw PSP response text (JSON/XML). Contains the complete payment gateway response for debugging. (Tier 4 -- inferred from name) |
| 36 | ModificationDateID | int | YES | Integer date key (YYYYMMDD format) for ModificationDate. For JOIN to date dimension. (Tier 4 -- inferred from name) |
| 37 | BankCode | varchar(100) | YES | Bank code from PSP response. (Tier 4 -- PSP response field) |
| 38 | PSPCode | varchar(100) | YES | PSP-specific code from payment response. (Tier 4 -- PSP response field) |
| 39 | FundingID | varchar(100) | YES | Funding transaction ID from PSP response. (Tier 4 -- PSP response field) |
| 40 | AccountBalanceAsDecimal | varchar(100) | YES | Account balance from PSP response (stored as string). (Tier 4 -- PSP response field) |
| 41 | AccountHolderAsString | varchar(100) | YES | Account holder name from PSP response. PII field. (Tier 4 -- PSP response field) |
| 42 | AccountIDAsDecimal | nvarchar(100) | YES | Account ID from PSP response (stored as string). (Tier 4 -- PSP response field) |
| 43 | ACHBankAccountIDAsInteger | varchar(100) | YES | ACH bank account ID from PSP response. US-specific banking field. (Tier 4 -- PSP response field) |
| 44 | Address1AsString | varchar(100) | YES | Primary address line from PSP response. PII field. (Tier 4 -- PSP response field) |
| 45 | Address2AsString | varchar(100) | YES | Secondary address line from PSP response. PII field. (Tier 4 -- PSP response field) |
| 46 | AdviseAsString | varchar(100) | YES | Advisory message from PSP response. (Tier 4 -- PSP response field) |
| 47 | AvailableBalanceAsDecimal | varchar(100) | YES | Available balance from PSP response. (Tier 4 -- PSP response field) |
| 48 | BankCodeAsString | nvarchar(100) | YES | Bank code from PSP response (alternative string format). (Tier 4 -- PSP response field) |
| 49 | BankIDAsInteger | nvarchar(100) | YES | Bank ID from PSP response. (Tier 4 -- PSP response field) |
| 50 | BillNumberAsString | varchar(100) | YES | Bill/invoice number from PSP response. (Tier 4 -- PSP response field) |
| 51 | BuildingNumberAsString | varchar(100) | YES | Building number from PSP response address. (Tier 4 -- PSP response field) |
| 52 | CardHolderPhoneNumberBodyAsString | varchar(100) | YES | Cardholder phone number (body) from PSP response. PII field. (Tier 4 -- PSP response field) |
| 53 | CardHolderPhoneNumberPrefixAsString | varchar(100) | YES | Cardholder phone number (country prefix) from PSP response. PII field. (Tier 4 -- PSP response field) |
| 54 | CardNumberAsString | nvarchar(100) | YES | Card number from PSP response (likely masked/tokenized). PII field. (Tier 4 -- PSP response field) |
| 55 | CityAsString | varchar(100) | YES | City from PSP response. PII field. (Tier 4 -- PSP response field) |
| 56 | CountryIDAsString | varchar(100) | YES | Country ID from PSP response. (Tier 4 -- PSP response field) |
| 57 | CountryNameAsString | varchar(100) | YES | Country name from PSP response. (Tier 4 -- PSP response field) |
| 58 | CreatedAtAsString | varchar(100) | YES | Creation timestamp from PSP response. (Tier 4 -- PSP response field) |
| 59 | CurrentBalanceAsDecimal | varchar(100) | YES | Current balance from PSP response. (Tier 4 -- PSP response field) |
| 60 | CustomerIDAsString | varchar(100) | YES | Customer ID from PSP response (PSP's own customer reference). (Tier 4 -- PSP response field) |
| 61 | EmailAsString | nvarchar(100) | YES | Email address from PSP response. PII field. (Tier 4 -- PSP response field) |
| 62 | EndPointIDAsString | varchar(100) | YES | API endpoint ID from PSP response. (Tier 4 -- PSP response field) |
| 63 | ErrorCodeAsString | varchar(100) | YES | Error code from PSP response (populated on failures). (Tier 4 -- PSP response field) |
| 64 | ErrorTypeAsString | varchar(100) | YES | Error type classification from PSP response. (Tier 4 -- PSP response field) |
| 65 | FirstNameAsString | varchar(100) | YES | Customer first name from PSP response. PII field. (Tier 4 -- PSP response field) |
| 66 | IBANCodeAsString | varchar(100) | YES | IBAN code from PSP response. PII field. (Tier 4 -- PSP response field) |
| 67 | InitialTransactionIDAsString | varchar(100) | YES | Initial/parent transaction ID from PSP response (for recurring/linked transactions). (Tier 4 -- PSP response field) |
| 68 | IPAsString | varchar(100) | YES | IP address from PSP response. PII field. (Tier 4 -- PSP response field) |
| 69 | LanguageIDAsInteger | varchar(100) | YES | Language ID from PSP response. (Tier 4 -- PSP response field) |
| 70 | LastNameAsString | varchar(100) | YES | Customer last name from PSP response. PII field. (Tier 4 -- PSP response field) |
| 71 | MD5AsString | varchar(100) | YES | MD5 hash from PSP response (request/response verification). (Tier 4 -- PSP response field) |
| 72 | PayerAsString | varchar(100) | YES | Payer identifier from PSP response (e-wallet payer reference). (Tier 4 -- PSP response field) |
| 73 | PayerBusiness | varchar(100) | YES | Payer business name from PSP response (for PayPal-type providers). (Tier 4 -- PSP response field) |
| 74 | PayerIDAsString | nvarchar(100) | YES | Payer ID from PSP response. (Tier 4 -- PSP response field) |
| 75 | PayerPurseAsString | varchar(100) | YES | Payer purse/wallet from PSP response. (Tier 4 -- PSP response field) |
| 76 | PayerStatus | varchar(100) | YES | Payer verification status from PSP response. (Tier 4 -- PSP response field) |
| 77 | PaymentAmountAsDecimal | varchar(100) | YES | Payment amount from PSP response (stored as string). (Tier 4 -- PSP response field) |
| 78 | PaymentDateAsDateTime | varchar(100) | YES | Payment date from PSP response (stored as string). (Tier 4 -- PSP response field) |
| 79 | PaymentGuaranteeAsString | varchar(100) | YES | Payment guarantee status from PSP response. (Tier 4 -- PSP response field) |
| 80 | PaymentModeAsInteger | varchar(100) | YES | Payment mode from PSP response. (Tier 4 -- PSP response field) |
| 81 | PaymentProviderTransactionStatusAsString | varchar(100) | YES | PSP transaction status from response. (Tier 4 -- PSP response field) |
| 82 | PaymentStatusAsInteger | varchar(100) | YES | Payment status code from PSP response (numeric). (Tier 4 -- PSP response field) |
| 83 | PaymentTypeAsString | varchar(100) | YES | Payment type from PSP response. (Tier 4 -- PSP response field) |
| 84 | PlaidItemIDAsString | varchar(100) | YES | Plaid Item ID from PSP response (US bank linking). (Tier 4 -- PSP response field) |
| 85 | PlaidNamesAsString | varchar(100) | YES | Plaid account holder names from PSP response. PII field. (Tier 4 -- PSP response field) |
| 86 | PlatformIDAsInteger | varchar(100) | YES | Platform ID from PSP response. (Tier 4 -- PSP response field) |
| 87 | PromotionCodeAsString | varchar(100) | YES | Promotion/coupon code used with the deposit. (Tier 4 -- PSP response field) |
| 88 | PSPCodeAsString | varchar(100) | YES | PSP response code (alternative string format). (Tier 4 -- PSP response field) |
| 89 | RapidFirstNameAsString | varchar(100) | YES | First name from Rapid transfer PSP response. PII field. (Tier 4 -- PSP response field) |
| 90 | RapidLastNameAsString | varchar(100) | YES | Last name from Rapid transfer PSP response. PII field. (Tier 4 -- PSP response field) |
| 91 | ResponseMessageAsString | varchar(100) | YES | Response message text from PSP. (Tier 4 -- PSP response field) |
| 92 | ResponseTimeAsString | varchar(100) | YES | Response latency from PSP. (Tier 4 -- PSP response field) |
| 93 | SecretKeyAsString | varchar(100) | YES | Secret key from PSP response (security token). Sensitive field. (Tier 4 -- PSP response field) |
| 94 | ThreeDsAsJson | varchar(100) | YES | 3D Secure authentication data from PSP response (JSON format). (Tier 4 -- PSP response field) |
| 95 | ThreeDsResponseType | varchar(100) | YES | 3D Secure response type (e.g., Challenge, Frictionless). (Tier 4 -- PSP response field) |
| 96 | TokenAsString | varchar(100) | YES | Payment token from PSP response (tokenized card reference). (Tier 4 -- PSP response field) |
| 97 | TransactionIDAsString | varchar(100) | YES | Transaction ID from PSP response. (Tier 4 -- PSP response field) |
| 98 | ZipCodeAsString | varchar(100) | YES | ZIP/postal code from PSP response. PII field. (Tier 4 -- PSP response field) |
| 99 | AccountIDAsString | nvarchar(100) | YES | Account ID from PSP response (string format, distinct from AccountIDAsDecimal). (Tier 4 -- PSP response field) |
| 100 | AccountTypeAsString | nvarchar(100) | YES | Account type from PSP response (e.g., Checking, Savings). (Tier 4 -- PSP response field) |
| 101 | BankAccountAsString | nvarchar(100) | YES | Bank account number from PSP response. PII field. (Tier 4 -- PSP response field) |
| 102 | BankAddressAsString | nvarchar(100) | YES | Bank address from PSP response. (Tier 4 -- PSP response field) |
| 103 | BankCodeAsDecimal | nvarchar(100) | YES | Bank code from PSP response (decimal format). (Tier 4 -- PSP response field) |
| 104 | BankDetailsAccountIDAsString | nvarchar(100) | YES | Bank details account ID from PSP response. (Tier 4 -- PSP response field) |
| 105 | BankIDAsString | nvarchar(100) | YES | Bank ID from PSP response (string format). (Tier 4 -- PSP response field) |
| 106 | BankNameAsString | nvarchar(100) | YES | Bank name from PSP response. (Tier 4 -- PSP response field) |
| 107 | BICCodeAsString | nvarchar(100) | YES | BIC/SWIFT code from PSP response. (Tier 4 -- PSP response field) |
| 108 | BinCodeAsString | nvarchar(100) | YES | BIN code from PSP response (string format). (Tier 4 -- PSP response field) |
| 109 | BinCountryIDAsInteger | nvarchar(100) | YES | BIN country ID from PSP response. (Tier 4 -- PSP response field) |
| 110 | CardTypeIDAsInteger | nvarchar(100) | YES | Card type ID from PSP response. (Tier 4 -- PSP response field) |
| 111 | CIDAsString | nvarchar(100) | YES | Customer ID from PSP response (string format). (Tier 4 -- PSP response field) |
| 112 | ClientBankNameAsString | nvarchar(100) | YES | Client's bank name from PSP response. (Tier 4 -- PSP response field) |
| 113 | CountryIDAsInteger | nvarchar(100) | YES | Country ID from PSP response. (Tier 4 -- PSP response field) |
| 114 | CustomerAddressAsString | nvarchar(100) | YES | Customer address from PSP response. PII field. (Tier 4 -- PSP response field) |
| 115 | CustomerNameAsString | nvarchar(100) | YES | Customer name from PSP response. PII field. (Tier 4 -- PSP response field) |
| 116 | ExpirationDateAsString | nvarchar(100) | YES | Card expiration date from PSP response. (Tier 4 -- PSP response field) |
| 117 | MaskedAccountIDAsString | nvarchar(100) | YES | Masked account ID from PSP response (partially redacted). (Tier 4 -- PSP response field) |
| 118 | PurseAsString | nvarchar(100) | YES | E-wallet purse reference from PSP response. (Tier 4 -- PSP response field) |
| 119 | RoutingNumberAsString | nvarchar(100) | YES | US bank routing number from PSP response. PII field. (Tier 4 -- PSP response field) |
| 120 | SecuredCardDataAsString | nvarchar(100) | YES | Secured/encrypted card data from PSP response. Sensitive field. (Tier 4 -- PSP response field) |
| 121 | SecureIDAsDecimal | nvarchar(100) | YES | Secure ID from PSP response (security reference). (Tier 4 -- PSP response field) |
| 122 | SortCodeAsString | nvarchar(100) | YES | UK bank sort code from PSP response. (Tier 4 -- PSP response field) |
| 123 | SwiftCodeAsString | nvarchar(100) | YES | SWIFT code from PSP response (international bank identifier). (Tier 4 -- PSP response field) |
| 124 | BaseExchangeRate | money | YES | Exchange rate used for converting original currency to USD. (Tier 4 -- inferred from name) |
| 125 | Category | varchar(9) | YES | Deposit category classification (e.g., manual categories). Limited to 9 characters. (Tier 4 -- inferred from name) |
| 126 | DepotID | int | YES | Depot or sub-account identifier for the deposit destination. (Tier 4 -- inferred from name) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| All columns | Unknown | Unknown | No writer SP found -- fully orphaned |

### 5.2 ETL Pipeline

```
(Unknown production source -- likely Billing.Deposit + Billing.Funding + PSP API responses)
  |-- (No Generic Pipeline mapping found)
  v
BI_DB_dbo.BI_DB_All_Deposit_Hourly (0 rows -- DORMANT)
  |-- (No UC migration -- _Not_Migrated)
  v
(not exported)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer ID FK (inferred) |
| DepositID | Billing.Deposit/Funding | Deposit transaction FK (inferred) |
| Affiliate ID | fiktivo affiliate system | Affiliate partner FK (inferred) |
| FundingType | DWH_dbo.Dim_FundingType | Payment method lookup (inferred) |

### 6.2 Referenced By (other objects point to this)

No objects in the Synapse SSDT reference this table.

---

## 7. Sample Queries

### 7.1 Check Table Status

```sql
-- Verify the table is still empty
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_All_Deposit_Hourly];
```

### 7.2 Hourly Deposit Volume (if populated)

```sql
-- Deposit volume by hour and payment status
SELECT
    CAST([Deposit Time] AS DATE) AS deposit_date,
    DATEPART(HOUR, [Deposit Time]) AS deposit_hour,
    PaymentStatus,
    COUNT(*) AS deposit_count,
    SUM([Amount in $]) AS total_usd
FROM [BI_DB_dbo].[BI_DB_All_Deposit_Hourly]
GROUP BY CAST([Deposit Time] AS DATE), DATEPART(HOUR, [Deposit Time]), PaymentStatus
ORDER BY deposit_date DESC, deposit_hour;
```

### 7.3 Country Mismatch Detection (if populated)

```sql
-- Potential fraud: BIN country doesn't match customer country
SELECT
    CID,
    [Country (customer)],
    BINCountry,
    [Country By Reg IP],
    [Amount in $],
    Provider
FROM [BI_DB_dbo].[BI_DB_All_Deposit_Hourly]
WHERE BINCountry <> [Country (customer)]
    AND PaymentStatus = 'Approved'
ORDER BY [Amount in $] DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. Payments operations reporting may be documented under the Payments or FinOps team spaces.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 125 T4, 1 T5 | Elements: 126/126, Logic: 6/10, Lineage: 3/10*
*Object: BI_DB_dbo.BI_DB_All_Deposit_Hourly | Type: Table | Production Source: Unknown (dormant)*
