# BI_DB_dbo.BI_DB_AllDeposits

> Comprehensive deposit analytics table — 126 columns recording all eToro deposit attempts with human-readable resolved labels, PSP payload fields, customer segmentation (Category), and regulatory context. Built daily from DWH_dbo.Fact_BillingDeposit via SP_AllDeposits with 15 Dim JOINs. Excludes Popular Investor (PI) deposits.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Deposit (via DWH_dbo.Fact_BillingDeposit) |
| **Refresh** | Daily (SP_AllDeposits @date, DELETE by DepositID + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED (ModificationDateID ASC) |
| | |
| **OpsDB Priority** | 0 (base layer — reads directly from DWH_dbo, no BI_DB intra-dependencies) |
| **OpsDB Process** | SB_Daily, ProcessType=SQL |
| **Downstream** | BI_DB_ClubUsersDataRemarketingGoogle (SP_ClubUsersDataRemarketingGoogle reads from this table) |
| **View** | BI_DB_dbo.V_BI_DB_AllDeposits (alias layer: spaces/special chars replaced with underscores) |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_AllDeposits` is the BI-layer deposit reporting table, designed for analyst consumption. It covers every deposit attempt (approved, declined, pending) across all eToro regulatory entities, enriched with customer-facing labels, marketing attributes, and provider-level raw data.

Where `DWH_dbo.Fact_BillingDeposit` stores integer foreign keys (FundingTypeID, PaymentStatusID, RegulationID, etc.), this table resolves them to human-readable names (FundingType='eToroMoney', PaymentStatus='Approved', Regulation='CySEC') using 15 LEFT/INNER JOINs to DWH dimension tables. It also adds:
- **Category** segmentation (FTD / REDEPOSIT / LEAD) for marketing attribution
- **BINCountry**, **CardType**, **CardSubType** resolved from BIN lookup tables
- **Account Manager** name (FirstName + LastName) for AM reporting
- **Region** from the eToro marketing dictionary
- **Response** label from the payment dictionary (via DepositAction staging)
- 86 XML-extracted PSP payload fields (passed through directly from Fact_BillingDeposit)

**Scale (Jan-Apr 2026)**: ~3.5M rows in a 4-month window. eToroMoney (58%) and CreditCard (30%) dominate funding types. 83% of deposits are Approved; 6% Decline, 2% DeclineByRRE. CySEC entity (~66%) is the largest regulatory cohort.

**Exclusion**: `WHERE PlayerLevelID != 4` — Popular Investor (PI) client deposits are excluded from this table.

**Important — ModificationDateID type mismatch**: The DDL column is `int`, but the SP writes `CONVERT(VARCHAR(10), ModificationDate, 112)` which SQL Server implicitly casts to int at INSERT. Values are YYYYMMDD integers (e.g., 20260101).

---

## 2. Business Logic

### 2.1 Deposit Category Classification

**What**: Every deposit row is assigned one of three categories that drive marketing attribution and funnel analysis.

**Columns Involved**: `Category`, `IsFTD`, `FirstDepositDate`

**Rules**:
```
Category = CASE
  WHEN IsFTD = 1              → 'FTD'        (first-ever approved deposit)
  WHEN FirstDepositDate IS NOT NULL → 'REDEPOSIT'  (returning depositor)
  ELSE                        → 'LEAD'       (deposit attempt with no prior approved deposit)
END
```
- **FTD** (3.5% in 2026): Triggers marketing attribution, bonus eligibility checks. `IsFTD` is a production guarantee — only one FTD per CID.
- **REDEPOSIT** (96.5% in 2026): Customer has a prior approved deposit (`FirstDepositDate` populated from Dim_Customer).
- **LEAD**: Rare case — a deposit attempt from a customer who has no prior FirstDepositDate and whose IsFTD=0. Possible for declined/pending deposits on a never-deposited account. Absent from 2026 data slice (all active depositors have prior history by that point).

### 2.2 PI Exclusion Filter

**What**: Popular Investor (PI) clients are excluded from this reporting table.

**Rule**: `WHERE PlayerLevelID != 4` applied against `DWH_dbo.Dim_Customer` in the SP. PI deposits exist in `DWH_dbo.Fact_BillingDeposit` but not in `BI_DB_AllDeposits`.

### 2.3 Duplicate Resolution

**What**: DepositID may appear multiple times in the source due to multiple modification records on the same deposit date. The SP takes the most recent record per deposit.

**Rule**: `ROW_NUMBER() OVER (PARTITION BY DepositID ORDER BY ModificationDate DESC)` in `final_all_deposit` CTE; only RN=1 is inserted.

**Delete strategy**: DELETE by `DepositID` match (not by date-range), ensuring exact replacement of the specific deposit records being refreshed. This prevents partial deletes on deposits that span date boundaries.

### 2.4 Response Lookup via DepositAction Staging

**What**: The `Response` column provides the human-readable payment gateway response name for each deposit.

**Chain**:
1. `SP_Create_Synapse_Table_etoro_History_DepositAction @date` populates `Synapse_Table_etoro_History_DepositAction` with the day's deposit action rows from `etoro.History.DepositAction` (via lake)
2. `#deposit_action` deduplicates on DepositID (latest by ModificationDate, requires ResponseID IS NOT NULL)
3. `#etoro_Dictionary_Response` joins `External_etoro_Dictionary_Response` (Bronze/etoro/Dictionary/Response)
4. Final JOIN: `#deposit_action.ResponseID = #etoro_Dictionary_Response.ResponseID → ResponseName`

Result: `Response` = PSP gateway response name (e.g., 'Approved', 'Do Not Honor', 'Insufficient Funds') for the latest action on each deposit.

### 2.5 BIN Enrichment

**What**: Three columns are resolved from the card BIN (first 6-8 digits of card number):
- `BINCountry` → country of card issuance (Dim_Country WHERE CountryID = BinCountryIDAsInteger)
- `Bank name by Bincode` → issuing bank name (Dim_CountryBin.IssuingBank WHERE BinCode = BinCodeAsString)
- `CardSubType` → card subtype label (Dim_CountryBin.CardSubType WHERE BinCode = BinCodeAsString)

**`CardType`** is resolved separately: Dim_CardType.CarTypeName WHERE CardTypeID = CardTypeIDAsInteger.

### 2.6 Amount in USD

**What**: `[Amount in $]` is the deposit amount converted to USD.

**Rule**: `Amount * ExchangeRate` (both from Fact_BillingDeposit). Stored as decimal(36,12). For USD deposits: ExchangeRate=1.0, so `[Amount in $]` = `[Amount In Orig Curr]`.

---

## 3. Query Advisory

### 3.1 Distribution and Indexing

ROUND_ROBIN distribution means no co-location benefit for JOINs — joining large tables against this table will involve data movement. Clustered index on `ModificationDateID` (int YYYYMMDD) makes date-range queries efficient.

**Preferred filter**: `WHERE ModificationDateID >= 20260101` (int comparison, clustered index aligned).

### 3.2 Column Name Gotchas

Several columns have spaces or special characters — always bracket them:
- `[Amount In Orig Curr]`, `[Amount in $]`, `[Deposit Time]`, `[Country (customer)]`, `[Country By Reg IP]`, `[Deposit Risk Status]`, `[External Transaction ID]`, `[Affiliate ID]`, `[Account Manager]`, `[Bank name by Bincode]`

Use `V_BI_DB_AllDeposits` for SQL clients that can't handle column names with spaces (view aliases all to underscores).

### 3.3 PSP Payload Column Sparsity

The 86 `*AsString/*AsDecimal/*AsInteger` columns are sparse — each is only populated for the funding type(s) that use that payment attribute. For eToroMoney deposits, card-specific fields (BinCode, CardType, CardNumberAsString) will be NULL; for CreditCard deposits, bank wire fields (IBANCodeAsString, SwiftCodeAsString) will be NULL. Filter by FundingType before aggregating these.

### 3.4 ThreeDsAsJson Truncation

The `ThreeDsAsJson` column is `varchar(100)` in this table but `nvarchar(max)` in Fact_BillingDeposit. The SP explicitly casts: `cast(ThreeDsAsJson AS VARCHAR(100))`. JSON may be truncated.

### 3.5 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily FTD volume by regulation | WHERE Category='FTD' AND ModificationDateID >= 20260101, GROUP BY Regulation, ModificationDateID |
| Payment method mix | GROUP BY FundingType, ModificationDateID WHERE ModificationDateID >= 20260101 |
| Approval rate by provider | GROUP BY Provider, PaymentStatus |
| Card BIN analysis | JOIN on BinCode (bigint), filter WHERE CardType IS NOT NULL |
| Deposit response analysis | GROUP BY Response WHERE FundingType='CreditCard' |
| AM deposit reporting | WHERE [Account Manager] IS NOT NULL, GROUP BY [Account Manager], ModificationDateID |

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — DWH_dbo.Fact_BillingDeposit wiki (verbatim) | (Tier 1 — Fact_BillingDeposit) |
| Tier 2 — SP_AllDeposits ETL code | (Tier 2 — SP_AllDeposits) |
| Tier 2 — Propagation blacklist canonical | (Tier 2 — ETL metadata) |

### 4.1 Core Identifiers & Deposit Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NOT NULL | Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer. Popular Investor (PlayerLevelID=4) CIDs are excluded. (Tier 1 — Fact_BillingDeposit) |
| 2 | DepositID | int | NOT NULL | Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). DELETE/INSERT keyed on this column by SP_AllDeposits. (Tier 1 — Fact_BillingDeposit) |
| 3 | FundingType | varchar(50) | NULL | Payment method name resolved from Dim_FundingType. Top values (2026): eToroMoney (58%), CreditCard (30%), PayPal (4%), WireTransfer (3%). (Tier 2 — SP_AllDeposits) |
| 4 | Amount In Orig Curr | money | NOT NULL | Deposit amount in the deposit currency (Currency column). As of 2025-04-17, capped via CASE expression in Fact_BillingDeposit ETL to prevent extreme outlier values from distorting aggregations. (Tier 1 — Fact_BillingDeposit) |
| 5 | Amount in $ | decimal(36,12) | NULL | Deposit amount converted to USD. Computed: Amount × ExchangeRate (both from Fact_BillingDeposit). For USD deposits ExchangeRate=1.0 so this equals Amount In Orig Curr. (Tier 2 — SP_AllDeposits) |
| 6 | Currency | varchar(20) | NULL | Currency abbreviation of the deposit amount (e.g., 'USD', 'EUR', 'GBP'). Resolved from Dim_Currency.Abbreviation via Fact_BillingDeposit.CurrencyID. (Tier 2 — SP_AllDeposits) |
| 7 | ModificationDate | datetime | NULL | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. (Tier 1 — Fact_BillingDeposit) |
| 8 | Deposit Time | datetime | NOT NULL | UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time. Maps to Fact_BillingDeposit.PaymentDate. (Tier 1 — Fact_BillingDeposit) |
| 9 | Month | int | NULL | Calendar month of ModificationDate. Computed: MONTH(ModificationDate). (Tier 2 — SP_AllDeposits) |
| 10 | Day | int | NULL | Calendar day of ModificationDate. Computed: DAY(ModificationDate). (Tier 2 — SP_AllDeposits) |
| 11 | Year | int | NULL | Calendar year of ModificationDate. Computed: YEAR(ModificationDate). (Tier 2 — SP_AllDeposits) |
| 12 | PaymentStatus | varchar(50) | NOT NULL | Deposit status name resolved from Dim_PaymentStatus. Top values (2026): Approved (83%), Decline (6%), DeclineByRRE (2%), Pending (2%), InProcess (2%). See Fact_BillingDeposit wiki §2.1 for full state lifecycle. (Tier 2 — SP_AllDeposits) |
| 13 | Country (customer) | varchar(50) | NULL | Customer's country of registration. Resolved from Dim_Country.Name via Dim_Customer.CountryID. (Tier 2 — SP_AllDeposits) |
| 14 | FirstDepositDate | datetime | NULL | Date of the customer's first ever approved deposit. NULL for customers who have never successfully deposited. Sourced from DWH_dbo.Dim_Customer.FirstDepositDate. Used in Category logic: NOT NULL → REDEPOSIT. (Tier 2 — SP_AllDeposits) |
| 15 | Funnel | varchar(50) | NULL | Marketing funnel name at the time of the deposit. Resolved from Dim_Funnel.Name via Fact_BillingDeposit.FunnelID. (Tier 2 — SP_AllDeposits) |
| 16 | FunnelFrom | varchar(50) | NULL | Original acquisition funnel of the customer account. Resolved from Dim_Funnel.Name via Dim_Customer.FunnelFromID. (Tier 2 — SP_AllDeposits) |
| 17 | BINCountry | varchar(50) | NULL | Country of card issuance based on BIN (Bank Identification Number). Resolved from Dim_Country.Name WHERE CountryID = BinCountryIDAsInteger. NULL for non-card funding types. (Tier 2 — SP_AllDeposits) |
| 18 | Provider | varchar(50) | NULL | Payment provider/gateway name (acquirer). Resolved from Dim_BillingDepot.Name via Fact_BillingDeposit.DepotID. (Tier 2 — SP_AllDeposits) |
| 19 | CardType | varchar(50) | NULL | Card type name (e.g., 'Visa', 'Mastercard'). Resolved from Dim_CardType.CarTypeName via BinCountryIDAsInteger (CardTypeID). NULL for non-card funding types. (Tier 2 — SP_AllDeposits) |
| 20 | CardSubType | varchar(50) | NULL | Card subtype label (e.g., 'Classic', 'Gold', 'Platinum'). Resolved from Dim_CountryBin.CardSubType via BinCodeAsString. NULL for non-card funding types. (Tier 2 — SP_AllDeposits) |
| 21 | IsFTD | int | NULL | First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 historically. (Tier 1 — Fact_BillingDeposit) |
| 22 | Country By Reg IP | varchar(50) | NULL | Country inferred from the customer's IP address at registration. Resolved from Dim_Country.Name via Dim_Customer.CountryIDByIP. (Tier 2 — SP_AllDeposits) |
| 23 | Deposit Risk Status | varchar(50) | NULL | Risk management decision label for this deposit. Resolved from Dim_RiskManagementStatus.Name via Fact_BillingDeposit.RiskManagementStatusID. (Tier 2 — SP_AllDeposits) |
| 24 | RiskStatus | varchar(100) | NULL | Customer-level risk classification label. Resolved from Dim_RiskStatus.Name via Dim_Customer.RiskStatusID. Reflects the customer's overall risk status at time of ETL, not deposit-specific. (Tier 2 — SP_AllDeposits) |
| 25 | External Transaction ID | char(50) | NULL | External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution. Maps to Fact_BillingDeposit.ExTransactionID. (Tier 1 — Fact_BillingDeposit) |
| 26 | Region | varchar(50) | NULL | eToro marketing region name for the customer's country. Resolved from External_etoro_Dictionary_MarketingRegion.Name via Dim_Country.MarketingRegionID. (Tier 2 — SP_AllDeposits) |
| 27 | Affiliate ID | int | NULL | Affiliate partner ID responsible for acquiring this customer. Sourced from Dim_Customer.AffiliateID. NULL for organic/direct acquisitions. (Tier 2 — SP_AllDeposits) |
| 28 | Account Manager | nvarchar(101) | NULL | Full name of the assigned account manager. Computed: Dim_Manager.FirstName + ' ' + LastName via Dim_Customer.AccountManagerID. NULL when no AM is assigned. (Tier 2 — SP_AllDeposits) |
| 29 | BinCode | bigint | NULL | Card BIN (Bank Identification Number, first 6-8 digits). Stored as bigint (implicit cast from BinCodeAsString). NULL for non-card funding types. (Tier 1 — Fact_BillingDeposit, BinCodeAsString) |
| 30 | Bank name by Bincode | varchar(100) | NULL | Issuing bank name for the card BIN. Resolved from Dim_CountryBin.IssuingBank via BinCodeAsString. NULL for non-card deposits. (Tier 2 — SP_AllDeposits) |
| 31 | Regulation | varchar(50) | NULL | Regulatory entity of the customer's trading account (e.g., 'CySEC', 'FCA', 'ASIC & GAML'). Resolved from Dim_Regulation.Name via Dim_Customer.RegulationID. Distribution (2026): CySEC 66%, FCA 15%, FSA Seychelles 6%, ASIC&GAML 3%, FSRA 3%, BVI 2%, FinCEN+FINRA 2%. (Tier 2 — SP_AllDeposits) |
| 32 | DesignatedRegulation | varchar(50) | NULL | Designated (preferred) regulatory entity for the customer. Resolved from Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. May differ from Regulation when customer trades under a specific entity. (Tier 2 — SP_AllDeposits) |
| 33 | Category | varchar(9) | NOT NULL | Deposit category for marketing attribution. Values: 'FTD' (3.5%), 'REDEPOSIT' (96.5%), 'LEAD' (<0.1%). Logic: IsFTD=1→'FTD'; FirstDepositDate IS NOT NULL→'REDEPOSIT'; ELSE→'LEAD'. (Tier 2 — SP_AllDeposits) |
| 34 | MID | nvarchar(250) | NULL | Merchant ID configuration value for payment routing. Resolved from External_etoro_Billing_ProtocolMIDSettings.Value via Fact_BillingDeposit.ProtocolMIDSettingsID. NULL when no MID profile applies. (Tier 2 — SP_AllDeposits) |
| 35 | UpdateDate | datetime | NOT NULL | ETL load timestamp. GETDATE() at SP_AllDeposits execution. (Tier 2 — ETL metadata) |
| 36 | Response | varchar(max) | NULL | Payment gateway response name for the latest DepositAction on this deposit (e.g., 'Approved', 'Do Not Honor'). Resolved via Synapse_Table_etoro_History_DepositAction → External_etoro_Dictionary_Response.ResponseName. NULL when no DepositAction with ResponseID exists. (Tier 2 — SP_AllDeposits) |
| 37 | ModificationDateID | int | NULL | ETL partition key — ModificationDate as YYYYMMDD integer. Computed by SP as CONVERT(VARCHAR(10), ModificationDate, 112) implicitly cast to int. Clustered index key. (Tier 2 — SP_AllDeposits) |
| 38 | BankCode | varchar(100) | NULL | Bank code for the payment instrument. Alias of Fact_BillingDeposit.BankCodeAsString (renamed for readability). (Tier 1 — Fact_BillingDeposit, BankCodeAsString) |
| 39 | PSPCode | varchar(100) | NULL | Payment service provider code. Alias of Fact_BillingDeposit.PSPCodeAsString (renamed for readability). Also present as PSPCodeAsString (duplicate for API compatibility). (Tier 1 — Fact_BillingDeposit, PSPCodeAsString) |
| 40 | FundingID | bigint | NULL | Payment instrument (credit card, bank account, e-wallet) identifier used for this deposit. References Billing.Funding. Stored as bigint here vs int in Fact_BillingDeposit. (Tier 1 — Fact_BillingDeposit) |
| 41 | BaseExchangeRate | money | NULL | Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019). (Tier 1 — Fact_BillingDeposit) |
| 42 | DepotID | int | NULL | Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production. Numeric ID; use Provider column for the resolved name. (Tier 1 — Fact_BillingDeposit) |

### 4.2 PSP Payload Fields (XML-Extracted from Billing.Deposit — Passthrough from Fact_BillingDeposit)

All columns below are passthrough of XML-extracted attributes from `Billing.Deposit.PaymentData` / `FundingData`. They were extracted in `DWH_dbo.Fact_BillingDeposit` ETL and passed through without modification. Each column stores the string value of a single XML attribute. All are varchar/nvarchar(100) unless noted. NULL = attribute absent for this deposit/funding type.

**(Tier 1 — Fact_BillingDeposit §4.8 for all columns in this section)**

| # | Element | Type | Notes |
|---|---------|------|-------|
| 43 | AccountBalanceAsDecimal | varchar(100) | Account balance from payment provider |
| 44 | AccountHolderAsString | varchar(100) | Account holder name |
| 45 | AccountIDAsDecimal | nvarchar(100) | Account identifier (numeric string) |
| 46 | ACHBankAccountIDAsInteger | varchar(100) | ACH bank account reference ID |
| 47 | Address1AsString | varchar(100) | Billing address line 1 |
| 48 | Address2AsString | varchar(100) | Billing address line 2 |
| 49 | AdviseAsString | varchar(100) | Payment provider advisory message |
| 50 | AvailableBalanceAsDecimal | varchar(100) | Available balance from provider |
| 51 | BankCodeAsString | nvarchar(100) | Bank code (string form) — duplicate of BankCode above |
| 52 | BankIDAsInteger | nvarchar(100) | Bank identifier integer |
| 53 | BillNumberAsString | varchar(100) | Bill/invoice number |
| 54 | BuildingNumberAsString | varchar(100) | Building number in address |
| 55 | CardHolderPhoneNumberBodyAsString | varchar(100) | Cardholder phone number body |
| 56 | CardHolderPhoneNumberPrefixAsString | varchar(100) | Cardholder phone number prefix |
| 57 | CardNumberAsString | nvarchar(100) | Card number (masked) |
| 58 | CityAsString | varchar(100) | Billing city |
| 59 | CountryIDAsString | varchar(100) | Country identifier string |
| 60 | CountryNameAsString | varchar(100) | Country name from payment XML |
| 61 | CreatedAtAsString | varchar(100) | Payment instrument creation timestamp |
| 62 | CurrentBalanceAsDecimal | varchar(100) | Current balance from provider |
| 63 | CustomerIDAsString | varchar(100) | Customer ID string from payment data |
| 64 | EmailAsString | nvarchar(100) | Customer email from payment instrument |
| 65 | EndPointIDAsString | varchar(100) | Payment provider endpoint identifier |
| 66 | ErrorCodeAsString | varchar(100) | Provider error code on decline |
| 67 | ErrorTypeAsString | varchar(100) | Provider error type classification |
| 68 | FirstNameAsString | varchar(100) | Cardholder/account holder first name |
| 69 | IBANCodeAsString | nvarchar(100) | IBAN for wire/SEPA transfers |
| 70 | InitialTransactionIDAsString | varchar(100) | Initial transaction ID for recurring |
| 71 | IPAsString | varchar(100) | Customer IP as string |
| 72 | LanguageIDAsInteger | varchar(100) | Language ID from payment data |
| 73 | LastNameAsString | varchar(100) | Cardholder/account holder last name |
| 74 | MD5AsString | varchar(100) | MD5 hash from payment provider |
| 75 | PayerAsString | varchar(100) | Payer name (PayPal/e-wallet) |
| 76 | PayerBusiness | varchar(100) | Payer business name (PayPal) |
| 77 | PayerIDAsString | nvarchar(100) | Payer identifier string |
| 78 | PayerPurseAsString | varchar(100) | Payer purse/wallet ID |
| 79 | PayerStatus | varchar(100) | Payer verification status |
| 80 | PaymentAmountAsDecimal | varchar(100) | Amount from payment XML |
| 81 | PaymentDateAsDateTime | varchar(100) | Payment date from XML |
| 82 | PaymentGuaranteeAsString | varchar(100) | Payment guarantee code |
| 83 | PaymentModeAsInteger | varchar(100) | Payment processing mode |
| 84 | PaymentProviderTransactionStatusAsString | varchar(100) | Status string from provider |
| 85 | PaymentStatusAsInteger | varchar(100) | Status integer from provider |
| 86 | PaymentTypeAsString | varchar(100) | Payment type label from provider |
| 87 | PlaidItemIDAsString | varchar(100) | Plaid (ACH) item identifier |
| 88 | PlaidNamesAsString | varchar(100) | Plaid account holder names |
| 89 | PlatformIDAsInteger | varchar(100) | Platform from payment XML (separate from any DWH PlatformID enrichment) |
| 90 | PromotionCodeAsString | varchar(100) | Promotion/voucher code used |
| 91 | PSPCodeAsString | varchar(100) | Payment service provider code — duplicate of PSPCode above (both present for API compatibility) |
| 92 | RapidFirstNameAsString | varchar(100) | Rapid (payout) first name |
| 93 | RapidLastNameAsString | varchar(100) | Rapid (payout) last name |
| 94 | ResponseMessageAsString | varchar(100) | Provider response message |
| 95 | ResponseTimeAsString | varchar(100) | Provider response time |
| 96 | SecretKeyAsString | varchar(100) | Provider secret key (masked/reference) |
| 97 | ThreeDsAsJson | varchar(100) | Raw 3DS authentication data as JSON string — TRUNCATED to 100 chars (Fact_BillingDeposit stores full nvarchar(max)) |
| 98 | ThreeDsResponseType | varchar(100) | 3DS outcome ID as string. Cast to INT to JOIN Dim_ThreeDsResponseTypes. 15 possible values (0-14). |
| 99 | TokenAsString | varchar(100) | Payment token from tokenization service |
| 100 | TransactionIDAsString | varchar(100) | Provider transaction ID string |
| 101 | ZipCodeAsString | varchar(100) | Billing postal/ZIP code |
| 102 | AccountIDAsString | nvarchar(100) | Always NULL — hardcoded as NULL in SP_AllDeposits (retained for schema compatibility) |
| 103 | AccountTypeAsString | nvarchar(100) | Bank account type (checking, savings) |
| 104 | BankAccountAsString | nvarchar(100) | Bank account number (masked) |
| 105 | BankAddressAsString | nvarchar(100) | Bank address |
| 106 | BankCodeAsDecimal | nvarchar(100) | Bank code (numeric string) |
| 107 | BankDetailsAccountIDAsString | nvarchar(100) | Bank details account identifier |
| 108 | BankIDAsString | nvarchar(100) | Bank identifier string |
| 109 | BankNameAsString | nvarchar(100) | Name of the bank |
| 110 | BICCodeAsString | nvarchar(100) | SWIFT/BIC code for wire transfers |
| 111 | BinCodeAsString | nvarchar(100) | Card BIN (first 6-8 digits) — string form; see also BinCode (bigint) |
| 112 | BinCountryIDAsInteger | nvarchar(100) | Country ID of card BIN (integer as string). Used to resolve BINCountry via Dim_Country |
| 113 | CardTypeIDAsInteger | nvarchar(100) | Card type ID (integer as string). Used to resolve CardType via Dim_CardType |
| 114 | CIDAsString | nvarchar(100) | Customer ID as string (XML cross-check field) |
| 115 | ClientBankNameAsString | nvarchar(200) | Client's bank name |
| 116 | CountryIDAsInteger | nvarchar(100) | Customer country from payment data (integer as string) |
| 117 | CustomerAddressAsString | nvarchar(100) | Customer's billing address |
| 118 | CustomerNameAsString | nvarchar(100) | Customer name from payment instrument |
| 119 | ExpirationDateAsString | nvarchar(100) | Card expiration date as raw string from XML. Used by Fact_BillingDeposit to compute ExpirationDateID (not applicable in BI_DB_AllDeposits). |
| 120 | MaskedAccountIDAsString | nvarchar(100) | Masked account/card identifier for display |
| 121 | PurseAsString | nvarchar(100) | E-wallet purse/account ID |
| 122 | RoutingNumberAsString | nvarchar(100) | US ACH routing number |
| 123 | SecuredCardDataAsString | nvarchar(100) | Tokenized card data reference |
| 124 | SecureIDAsDecimal | nvarchar(100) | Secure transaction ID (numeric string) |
| 125 | SortCodeAsString | nvarchar(100) | UK bank sort code |
| 126 | SwiftCodeAsString | nvarchar(100) | SWIFT code for wire transfers |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Role | Columns |
|--------|------|---------|
| etoro.Billing.Deposit | Primary — all deposit facts + PSP payload | All core columns + 86 XML-extracted fields (via Fact_BillingDeposit) |
| DWH_dbo.Dim_Customer | Dimension | FirstDepositDate, AffiliateID, CountryID, CountryIDByIP, AccountManagerID, RiskStatusID, RegulationID, DesignatedRegulationID, FunnelFromID, FunnelID, PlayerLevelID (filter) |
| DWH_dbo.Dim_PaymentStatus | Dimension | PaymentStatus |
| DWH_dbo.Dim_FundingType | Dimension | FundingType |
| DWH_dbo.Dim_Country (×3) | Dimension | Country (customer), Country By Reg IP, BINCountry |
| DWH_dbo.Dim_Manager | Dimension | Account Manager |
| DWH_dbo.Dim_Regulation (×2) | Dimension | Regulation, DesignatedRegulation |
| DWH_dbo.Dim_Currency | Dimension | Currency |
| DWH_dbo.Dim_RiskManagementStatus | Dimension | Deposit Risk Status |
| DWH_dbo.Dim_RiskStatus | Dimension | RiskStatus |
| DWH_dbo.Dim_Funnel (×2) | Dimension | Funnel, FunnelFrom |
| DWH_dbo.Dim_BillingDepot | Dimension | Provider |
| DWH_dbo.Dim_CardType | Dimension | CardType |
| DWH_dbo.Dim_CountryBin (×2) | Dimension | Bank name by Bincode, CardSubType |
| BI_DB_dbo.External_etoro_Billing_ProtocolMIDSettings | External — Bronze | MID |
| BI_DB_dbo.External_etoro_Dictionary_Response | External — Bronze/etoro/Dictionary/Response | Response (via DepositAction staging) |
| BI_DB_dbo.External_etoro_Dictionary_MarketingRegion | External — Bronze/etoro/Dictionary/MarketingRegion | Region |
| BI_DB_dbo.Synapse_Table_etoro_History_DepositAction | Staging (daily window) | ResponseID lookup |
| etoro.History.DepositAction | Upstream of staging | (via SP_Create_Synapse_Table_etoro_History_DepositAction) |

### 5.2 ETL Pipeline

```
etoro.Billing.Deposit (production, 73.9M rows)
  |
  v [Generic Pipeline — daily]
DWH_staging.etoro_Billing_Deposit
  |
  v [SP_Fact_BillingDeposit_DL_To_Synapse — XML extraction (~91 cols) + Billing.Funding JOIN]
DWH_dbo.Fact_BillingDeposit (73.9M rows, HASH DepositID)
  |
  v [SP_AllDeposits @date — Priority 0, Daily, SB_Daily]
    1. SP_Create_Synapse_Table_etoro_History_DepositAction @date
       (populates BI_DB_dbo.Synapse_Table_etoro_History_DepositAction from etoro.History.DepositAction)
    2. #BillingDeposit = Fact_BillingDeposit WHERE ModificationDate=@date, PaymentStatusID NOT IN (11,12,26)
    3. #deposit_action = Synapse_Table_etoro_History_DepositAction deduped by DepositID
    4. #etoro_Dictionary_Response = External_etoro_Dictionary_Response
    5. xml_Temp CTE: 15 Dim JOINs → resolved text labels
    6. xml_dep_parse CTE: adds Month/Day/Year
    7. final_all_deposit CTE: BIN enrichment (CardType, CardSubType, BINCountry), RN dedup
    8. DELETE FROM BI_DB_AllDeposits WHERE DepositID IN (#final_insert_delete)
    9. INSERT INTO BI_DB_AllDeposits SELECT * FROM #final_insert_delete WHERE RN=1
BI_DB_dbo.BI_DB_AllDeposits (ROUND_ROBIN, CLUSTERED ModificationDateID)
```

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer demographics, regulation, AM assignment, risk |
| FundingType | DWH_dbo.Dim_FundingType | Payment method labels |
| PaymentStatus | DWH_dbo.Dim_PaymentStatus | Deposit state labels |
| Country (customer), Country By Reg IP, BINCountry | DWH_dbo.Dim_Country | Country name lookups |
| Regulation, DesignatedRegulation | DWH_dbo.Dim_Regulation | Regulatory entity labels |
| Currency | DWH_dbo.Dim_Currency | Currency abbreviation |
| Deposit Risk Status | DWH_dbo.Dim_RiskManagementStatus | Risk check result labels |
| RiskStatus | DWH_dbo.Dim_RiskStatus | Customer risk classification |
| Provider | DWH_dbo.Dim_BillingDepot | Acquirer/gateway labels |
| Funnel, FunnelFrom | DWH_dbo.Dim_Funnel | Marketing funnel labels |
| CardType | DWH_dbo.Dim_CardType | Card type labels |
| CardSubType, Bank name by Bincode | DWH_dbo.Dim_CountryBin | BIN enrichment |
| Account Manager | DWH_dbo.Dim_Manager | AM name resolution |
| MID | BI_DB_dbo.External_etoro_Billing_ProtocolMIDSettings | Merchant ID profile |
| Region | BI_DB_dbo.External_etoro_Dictionary_MarketingRegion | Marketing region label |
| Response | BI_DB_dbo.External_etoro_Dictionary_Response | PSP gateway response name |
| (all deposit facts) | DWH_dbo.Fact_BillingDeposit | Primary fact source |

### 6.2 Referenced By (other objects use this table)

| Source Object | Description |
|--------------|-------------|
| BI_DB_dbo.V_BI_DB_AllDeposits | View alias layer — replaces column name spaces/special chars with underscores for SQL clients |
| BI_DB_dbo.BI_DB_ClubUsersDataRemarketingGoogle | SP_ClubUsersDataRemarketingGoogle reads deposit history from this table |

---

## 7. Sample Queries

### 7.1 Daily deposit volume by funding type (2026 YTD)

```sql
SELECT
    ModificationDateID,
    FundingType,
    COUNT(*) AS DepositCount,
    SUM([Amount in $]) AS TotalUSD,
    SUM(CASE WHEN Category = 'FTD' THEN 1 ELSE 0 END) AS FTDs
FROM [BI_DB_dbo].[BI_DB_AllDeposits]
WHERE ModificationDateID >= 20260101
  AND PaymentStatus = 'Approved'
GROUP BY ModificationDateID, FundingType
ORDER BY ModificationDateID DESC, DepositCount DESC
```

### 7.2 Approval rate by regulation entity

```sql
SELECT
    Regulation,
    COUNT(*) AS TotalAttempts,
    SUM(CASE WHEN PaymentStatus = 'Approved' THEN 1 ELSE 0 END) AS Approved,
    CAST(SUM(CASE WHEN PaymentStatus = 'Approved' THEN 1 ELSE 0 END) AS float) / COUNT(*) AS ApprovalRate
FROM [BI_DB_dbo].[BI_DB_AllDeposits]
WHERE ModificationDateID >= 20260101
GROUP BY Regulation
ORDER BY TotalAttempts DESC
```

### 7.3 FTD attribution by affiliate and region

```sql
SELECT
    [Affiliate ID],
    Region,
    Regulation,
    COUNT(*) AS FTDs,
    SUM([Amount in $]) AS TotalFTD_USD
FROM [BI_DB_dbo].[BI_DB_AllDeposits]
WHERE Category = 'FTD'
  AND PaymentStatus = 'Approved'
  AND ModificationDateID >= 20260101
GROUP BY [Affiliate ID], Region, Regulation
ORDER BY FTDs DESC
```

### 7.4 Credit card BIN country analysis

```sql
SELECT
    BINCountry,
    CardType,
    COUNT(*) AS DepositCount,
    SUM([Amount in $]) AS TotalUSD
FROM [BI_DB_dbo].[BI_DB_AllDeposits]
WHERE FundingType = 'CreditCard'
  AND PaymentStatus = 'Approved'
  AND ModificationDateID >= 20260101
  AND BINCountry IS NOT NULL
GROUP BY BINCountry, CardType
ORDER BY DepositCount DESC
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| Billing.Deposit upstream wiki | Tier 1 wiki | PSP integration patterns, deposit lifecycle, XML field definitions |
| DWH_dbo.Fact_BillingDeposit wiki | Tier 1 wiki | Full column descriptions for all passthrough and XML-extracted columns |

---

*Generated: 2026-04-23 | Quality: 9.1/10 | Batch: 63 | Object: 1/4*
*Tiers: 12 T1 named + 83 T1 PSP payload, 31 T2 | Elements: 9.5/10, Logic: 9.0/10, Lineage: 9.5/10, Relationships: 9.0/10*
*Object: BI_DB_dbo.BI_DB_AllDeposits | Type: Table | Production Source: etoro.Billing.Deposit via DWH_dbo.Fact_BillingDeposit*
