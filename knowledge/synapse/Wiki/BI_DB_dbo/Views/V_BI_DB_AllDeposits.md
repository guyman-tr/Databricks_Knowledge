# BI_DB_dbo.V_BI_DB_AllDeposits

> 126-column passthrough view over `BI_DB_dbo.BI_DB_AllDeposits`. The base table uses bracketed column names with spaces and special characters (e.g. `[Amount In Orig Curr]`, `[Country (customer)]`). The view exists to expose the same columns under SQL-friendly identifiers — spaces/special chars replaced with underscores — so that downstream UC consumers and SQL clients without bracket-quoting can query without escaping. **For full business logic, lineage, and ETL details, see the parent table wiki: [`BI_DB_AllDeposits.md`](../Tables/BI_DB_AllDeposits.md).**

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | View — alias layer over BI_DB_AllDeposits |
| **Production Source** | `BI_DB_dbo.BI_DB_AllDeposits` (which is fed by `DWH_dbo.Fact_BillingDeposit` via `SP_AllDeposits`) |
| **Refresh** | Inherits from base table — daily |
| **Row Count** | ~3.5M (Jan-Apr 2026 window) |
| **Grain** | One row per DepositID (after RN=1 dedup in base) |
| **Filter** | Excludes Popular Investor (PI) deposits (`PlayerLevelID != 4` applied in base SP) |
| | |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (generic pipeline) |

---

## 1. Business Meaning

`V_BI_DB_AllDeposits` is the SQL-client-friendly alias view over `BI_DB_AllDeposits` — the BI-layer deposit reporting table. Every eToro deposit attempt (approved, declined, pending, in-process) is here, enriched with:

- Resolved label fields (FundingType, PaymentStatus, Regulation, CardType, Provider, Country, Funnel) from 15 DWH dimension joins.
- Marketing attribution (Funnel, FunnelFrom, Affiliate_ID, Region, Account_Manager, BINCountry).
- The customer's `Category` segmentation (FTD / REDEPOSIT / LEAD) — see base wiki §2.1.
- 86 PSP-payload passthrough fields (`*AsString`/`*AsInteger`/`*AsDecimal`) extracted from XML in `Fact_BillingDeposit`.

The view's only transformations are **column renames**:

| Base column (bracket-quoted) | View column |
|------------------------------|-------------|
| `[Amount In Orig Curr]` | `Amount_In_Orig_Curr` |
| `[Amount in $]` | `Amount_in_USD` |
| `[Deposit Time]` | `Deposit_Time` |
| `[Country (customer)]` | `Country_customer` |
| `[Country By Reg IP]` | `Country_By_Reg_IP` |
| `[Deposit Risk Status]` | `Deposit_Risk_Status` |
| `[External Transaction ID]` | `External_Transaction_ID` |
| `[Affiliate ID]` | `Affiliate_ID` |
| `[Account Manager]` | `Account_Manager` |
| `[Bank name by Bincode]` | `Bank_name_by_Bincode` |

All other columns flow through unchanged. **Use this view (not the base table) when querying from UC/Databricks.**

---

## 2. Query Advisory

### 2.1 Common Patterns

| Question | Approach |
|----------|----------|
| Daily approved deposit volume | `WHERE PaymentStatus = 'Approved' GROUP BY ModificationDateID` |
| FTD count by region | `WHERE Category = 'FTD' GROUP BY Region` |
| Decline rate by Provider | `GROUP BY Provider, PaymentStatus` |
| Card-only volume | `WHERE FundingType = 'CreditCard'` |
| BIN-level volume | `GROUP BY CardType, CardSubType, BINCountry` |

### 2.2 Gotchas

- **PI excluded**: Popular Investor deposits never appear here. For full coverage including PI, query `Fact_BillingDeposit` directly.
- **`Category = 'LEAD'` is rare** (~<0.1% historically; absent in 2026 sample).
- **`ModificationDateID` is YYYYMMDD int** — join to `Dim_Date.DateKey` for date semantics.
- **`Response` column is varchar(max)** — large free-text values are present; tokenize before string ops.
- **86 PSP `AsString`/`AsInteger`/`AsDecimal` cols** are XML-passthrough — typed string columns, NULL when the corresponding XML attribute was absent for the funding type. Same value space across funding types is NOT guaranteed.
- **`AccountIDAsString` (col 100) is always NULL** — hardcoded NULL in `SP_AllDeposits` (kept for schema compatibility).
- **`PSPCode` ↔ `PSPCodeAsString`**: duplicates retained for API compatibility — pick one.

For deeper logic (Category derivation, Response chain via DepositAction staging, BIN enrichment), see [`BI_DB_AllDeposits.md`](../Tables/BI_DB_AllDeposits.md) §2.

---

## 3. Elements

All 126 columns are passthrough from `BI_DB_dbo.BI_DB_AllDeposits` (with the 10 renames listed above). For full per-column lineage, ETL semantics, and example values, see the base wiki — descriptions below are summary form for UC comment population.

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 1 | Inherited from BI_DB_AllDeposits wiki + DDL + view definition |
| ** | Tier 2 | SP_AllDeposits-derived enrichment |
| * | Tier 3 | PSP XML passthrough — semantics depend on funding type |

### 3.1 Core / Resolved-Label Columns (1-42)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer identifier — joins to `DWH_dbo.Dim_Customer.RealCID` and to other deposits/MIMO panels. (Tier 1) |
| 2 | DepositID | int | NO | Surrogate primary key of the deposit (one row per dedup'd deposit attempt). FK from `Fact_BillingDeposit`. (Tier 1) |
| 3 | FundingType | varchar(50) | YES | Funding method label (`'eToroMoney'`, `'CreditCard'`, `'BankWire'`, `'PayPal'`, `'ACH'`, `'Skrill'`, `'Neteller'`, ...). Resolved from `Dim_FundingType` via `Fact_BillingDeposit.FundingTypeID`. (Tier 2) |
| 4 | Amount_In_Orig_Curr | money | NO | Deposit amount in the customer's local/funding currency. Renamed from base column `[Amount In Orig Curr]`. (Tier 1) |
| 5 | Amount_in_USD | decimal(36,12) | YES | Deposit amount converted to USD using the day's FX rate. Renamed from base column `[Amount in $]`. (Tier 1) |
| 6 | Currency | varchar(20) | YES | ISO currency code of `Amount_In_Orig_Curr` (`'USD'`, `'EUR'`, `'GBP'`, ...). Resolved from `Dim_Currency` via `Fact_BillingDeposit.CurrencyID`. (Tier 2) |
| 7 | ModificationDate | datetime | YES | UTC timestamp of the most recent modification to this deposit row in the source. Used for incremental ETL detection. (Tier 1) |
| 8 | Deposit_Time | datetime | NO | UTC timestamp when the deposit was submitted. Renamed from `[Deposit Time]`. NOT the approval time. (Tier 1) |
| 9 | Month | int | YES | `MONTH(ModificationDate)`. (Tier 2) |
| 10 | Day | int | YES | `DAY(ModificationDate)`. (Tier 2) |
| 11 | Year | int | YES | `YEAR(ModificationDate)`. (Tier 2) |
| 12 | PaymentStatus | varchar(50) | NO | Deposit-state label resolved from `Dim_PaymentStatus`. Top values (2026): `Approved` (83%), `Decline` (6%), `DeclineByRRE` (2%), `Pending` (2%), `InProcess` (2%). (Tier 2) |
| 13 | Country_customer | varchar(50) | YES | Customer's registration country. Renamed from `[Country (customer)]`. Resolved via `Dim_Customer.CountryID` → `Dim_Country.Name`. (Tier 2) |
| 14 | FirstDepositDate | datetime | YES | Date of customer's first ever approved deposit. NULL for never-deposited customers. Drives `Category` logic. (Tier 2) |
| 15 | Funnel | varchar(50) | YES | Marketing funnel name at deposit time. Resolved from `Dim_Funnel` via `Fact_BillingDeposit.FunnelID`. (Tier 2) |
| 16 | FunnelFrom | varchar(50) | YES | Original acquisition funnel of the customer account. Resolved from `Dim_Funnel` via `Dim_Customer.FunnelFromID`. (Tier 2) |
| 17 | BINCountry | varchar(50) | YES | Country of card issuance, derived from BIN lookup. Resolved from `Dim_Country` WHERE `CountryID = BinCountryIDAsInteger`. NULL for non-card. (Tier 2) |
| 18 | Provider | varchar(50) | YES | Payment provider/gateway/acquirer name. Resolved from `Dim_BillingDepot.Name` via `Fact_BillingDeposit.DepotID`. (Tier 2) |
| 19 | CardType | varchar(50) | YES | Card type label (`'Visa'`, `'Mastercard'`, ...). Resolved from `Dim_CardType`. NULL for non-card. (Tier 2) |
| 20 | CardSubType | varchar(50) | YES | Card subtype (`'Classic'`, `'Gold'`, `'Platinum'`, ...). Resolved from `Dim_CountryBin` via `BinCodeAsString`. NULL for non-card. (Tier 2) |
| 21 | IsFTD | int | YES | First-Time-Deposit flag. 1 = customer's very first approved deposit (drives marketing attribution). 0 = repeat or ineligible. (Tier 1) |
| 22 | Country_By_Reg_IP | varchar(50) | YES | Country inferred from registration IP. Renamed from `[Country By Reg IP]`. Resolved via `Dim_Customer.CountryIDByIP` → `Dim_Country.Name`. (Tier 2) |
| 23 | Deposit_Risk_Status | varchar(50) | YES | Risk-management decision label for this deposit. Renamed from `[Deposit Risk Status]`. Resolved from `Dim_RiskManagementStatus`. (Tier 2) |
| 24 | RiskStatus | varchar(100) | YES | Customer-level risk classification at ETL time. Resolved from `Dim_RiskStatus` via `Dim_Customer.RiskStatusID`. (Tier 2) |
| 25 | External_Transaction_ID | char(50) | YES | External (PSP) transaction identifier. Renamed from `[External Transaction ID]`. Used for provider-side reconciliation. (Tier 1) |
| 26 | Region | varchar(50) | YES | eToro marketing region for the customer's country. Resolved from `External_etoro_Dictionary_MarketingRegion`. (Tier 2) |
| 27 | Affiliate_ID | int | YES | Affiliate partner ID responsible for customer acquisition. Renamed from `[Affiliate ID]`. NULL for organic. (Tier 2) |
| 28 | Account_Manager | nvarchar(202) | YES | Full name of assigned AM (`FirstName + ' ' + LastName`). Renamed from `[Account Manager]`. NULL when unassigned. (Tier 2) |
| 29 | BinCode | bigint | YES | Card BIN as bigint (first 6-8 digits). NULL for non-card. (Tier 1) |
| 30 | Bank_name_by_Bincode | varchar(100) | YES | Issuing bank name from BIN lookup. Renamed from `[Bank name by Bincode]`. NULL for non-card. (Tier 2) |
| 31 | Regulation | varchar(50) | YES | Regulatory entity at deposit time (`'CySEC'`, `'FCA'`, `'ASIC & GAML'`, ...). Resolved from `Dim_Regulation` via `Dim_Customer.RegulationID`. (Tier 2) |
| 32 | DesignatedRegulation | varchar(50) | YES | Designated (preferred) regulatory entity for the customer. May differ from `Regulation`. (Tier 2) |
| 33 | Category | varchar(9) | NO | Deposit category for marketing attribution: `'FTD'` / `'REDEPOSIT'` / `'LEAD'`. Logic: IsFTD=1→FTD; FirstDepositDate not null→REDEPOSIT; else LEAD. (Tier 2) |
| 34 | MID | nvarchar(500) | YES | Merchant ID configuration value for payment routing. Resolved from `External_etoro_Billing_ProtocolMIDSettings`. (Tier 2) |
| 35 | UpdateDate | datetime | NO | ETL load timestamp (`GETDATE()` at SP_AllDeposits run). (Tier 2) |
| 36 | Response | varchar(max) | YES | Payment-gateway response name for the latest `DepositAction` row (`'Approved'`, `'Do Not Honor'`, ...). Resolved via `Synapse_Table_etoro_History_DepositAction` → `External_etoro_Dictionary_Response`. (Tier 2) |
| 37 | ModificationDateID | int | YES | YYYYMMDD form of `ModificationDate`. CLUSTERED index key in base. Joins to `Dim_Date.DateKey`. (Tier 2) |
| 38 | BankCode | varchar(100) | YES | Bank code for the payment instrument. Alias of `BankCodeAsString` (renamed for readability). (Tier 1) |
| 39 | PSPCode | varchar(100) | YES | Payment service provider code. Alias of `PSPCodeAsString` (renamed for readability). Duplicate of #91 for API compatibility. (Tier 1) |
| 40 | FundingID | bigint | YES | Payment instrument identifier (card/account/wallet) used for this deposit. Joins to `Billing.Funding`. (Tier 1) |

### 3.2 PSP Payload Fields — XML Passthrough (41-126)

These columns are XML-extracted attributes from `Billing.Deposit.PaymentData` / `FundingData`. NULL = the attribute was absent for this deposit's funding type. Type is `varchar(100)` unless noted; `nvarchar(200)` for fields that may carry Unicode.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 41 | AccountBalanceAsDecimal | varchar(100) | YES | Account balance from payment provider. (Tier 3) |
| 42 | AccountHolderAsString | varchar(100) | YES | Account holder name. (Tier 3) |
| 43 | AccountIDAsDecimal | nvarchar(200) | YES | Account identifier (numeric string). (Tier 3) |
| 44 | ACHBankAccountIDAsInteger | varchar(100) | YES | ACH bank account reference ID. (Tier 3) |
| 45 | Address1AsString | varchar(100) | YES | Billing address line 1. (Tier 3) |
| 46 | Address2AsString | varchar(100) | YES | Billing address line 2. (Tier 3) |
| 47 | AdviseAsString | varchar(100) | YES | Payment-provider advisory message. (Tier 3) |
| 48 | AvailableBalanceAsDecimal | varchar(100) | YES | Available balance from provider. (Tier 3) |
| 49 | BankCodeAsString | nvarchar(200) | YES | Bank code (string form). Duplicate of `BankCode` (#38) for API compatibility. (Tier 3) |
| 50 | BankIDAsInteger | nvarchar(200) | YES | Bank identifier integer (string form). (Tier 3) |
| 51 | BillNumberAsString | varchar(100) | YES | Bill / invoice number. (Tier 3) |
| 52 | BuildingNumberAsString | varchar(100) | YES | Building number in address. (Tier 3) |
| 53 | CardHolderPhoneNumberBodyAsString | varchar(100) | YES | Cardholder phone number body. (Tier 3) |
| 54 | CardHolderPhoneNumberPrefixAsString | varchar(100) | YES | Cardholder phone number prefix. (Tier 3) |
| 55 | CardNumberAsString | nvarchar(200) | YES | Card number (masked). (Tier 3) |
| 56 | CityAsString | varchar(100) | YES | Billing city. (Tier 3) |
| 57 | CountryIDAsString | varchar(100) | YES | Country identifier string from PSP payload. (Tier 3) |
| 58 | CountryNameAsString | varchar(100) | YES | Country name from payment XML. (Tier 3) |
| 59 | CreatedAtAsString | varchar(100) | YES | Payment instrument creation timestamp (string form). (Tier 3) |
| 60 | CurrentBalanceAsDecimal | varchar(100) | YES | Current balance from provider. (Tier 3) |
| 61 | CustomerIDAsString | varchar(100) | YES | Customer ID string from payment data (PSP-side identifier). (Tier 3) |
| 62 | EmailAsString | nvarchar(200) | YES | Customer email from payment instrument. (Tier 3) |
| 63 | EndPointIDAsString | varchar(100) | YES | Payment-provider endpoint identifier. (Tier 3) |
| 64 | ErrorCodeAsString | varchar(100) | YES | Provider error code on decline. (Tier 3) |
| 65 | ErrorTypeAsString | varchar(100) | YES | Provider error type classification. (Tier 3) |
| 66 | FirstNameAsString | varchar(100) | YES | Cardholder/account-holder first name. (Tier 3) |
| 67 | IBANCodeAsString | nvarchar(200) | YES | IBAN for wire/SEPA transfers. (Tier 3) |
| 68 | InitialTransactionIDAsString | varchar(100) | YES | Initial transaction ID for recurring payments. (Tier 3) |
| 69 | IPAsString | varchar(100) | YES | Customer IP from payment data (string form). (Tier 3) |
| 70 | LanguageIDAsInteger | varchar(100) | YES | Language ID from payment data. (Tier 3) |
| 71 | LastNameAsString | varchar(100) | YES | Cardholder/account-holder last name. (Tier 3) |
| 72 | MD5AsString | varchar(100) | YES | MD5 hash from payment provider (integrity / dedup). (Tier 3) |
| 73 | PayerAsString | varchar(100) | YES | Payer name (PayPal / e-wallet). (Tier 3) |
| 74 | PayerBusiness | varchar(100) | YES | Payer business name (PayPal). (Tier 3) |
| 75 | PayerIDAsString | nvarchar(200) | YES | Payer identifier string. (Tier 3) |
| 76 | PayerPurseAsString | varchar(100) | YES | Payer purse / wallet ID. (Tier 3) |
| 77 | PayerStatus | varchar(100) | YES | Payer verification status. (Tier 3) |
| 78 | PaymentAmountAsDecimal | varchar(100) | YES | Amount from payment XML (string form). (Tier 3) |
| 79 | PaymentDateAsDateTime | varchar(100) | YES | Payment date from XML (string form). (Tier 3) |
| 80 | PaymentGuaranteeAsString | varchar(100) | YES | Payment guarantee code. (Tier 3) |
| 81 | PaymentModeAsInteger | varchar(100) | YES | Payment processing mode (string form). (Tier 3) |
| 82 | PaymentProviderTransactionStatusAsString | varchar(100) | YES | Status string from provider (raw). (Tier 3) |
| 83 | PaymentStatusAsInteger | varchar(100) | YES | Status integer from provider (string form). (Tier 3) |
| 84 | PaymentTypeAsString | varchar(100) | YES | Payment type label from provider. (Tier 3) |
| 85 | PlaidItemIDAsString | varchar(100) | YES | Plaid (ACH) item identifier. (Tier 3) |
| 86 | PlaidNamesAsString | varchar(100) | YES | Plaid account-holder names. (Tier 3) |
| 87 | PlatformIDAsInteger | varchar(100) | YES | Platform from payment XML — separate from any DWH PlatformID. (Tier 3) |
| 88 | PromotionCodeAsString | varchar(100) | YES | Promotion / voucher code used. (Tier 3) |
| 89 | PSPCodeAsString | varchar(100) | YES | Payment service provider code. Duplicate of `PSPCode` (#39). (Tier 3) |
| 90 | RapidFirstNameAsString | varchar(100) | YES | Rapid (payout) first name. (Tier 3) |
| 91 | RapidLastNameAsString | varchar(100) | YES | Rapid (payout) last name. (Tier 3) |
| 92 | ResponseMessageAsString | varchar(100) | YES | Provider response message. (Tier 3) |
| 93 | ResponseTimeAsString | varchar(100) | YES | Provider response time (string form). (Tier 3) |
| 94 | SecretKeyAsString | varchar(100) | YES | Provider secret key (masked / reference). (Tier 3) |
| 95 | ThreeDsAsJson | varchar(100) | YES | Raw 3DS authentication data as JSON string — TRUNCATED to 100 chars in this table. (Tier 3) |
| 96 | ThreeDsResponseType | varchar(100) | YES | 3DS outcome ID as string. Cast to INT to JOIN `Dim_ThreeDsResponseTypes`. 15 possible values (0-14). (Tier 3) |
| 97 | TokenAsString | varchar(100) | YES | Payment token from tokenization service. (Tier 3) |
| 98 | TransactionIDAsString | varchar(100) | YES | Provider transaction ID string. (Tier 3) |
| 99 | ZipCodeAsString | varchar(100) | YES | Billing postal/ZIP code. (Tier 3) |
| 100 | AccountIDAsString | nvarchar(200) | YES | Always NULL — hardcoded NULL in `SP_AllDeposits` (kept for schema compatibility). (Tier 3) |
| 101 | AccountTypeAsString | nvarchar(200) | YES | Bank account type (`'checking'`, `'savings'`). (Tier 3) |
| 102 | BankAccountAsString | nvarchar(200) | YES | Bank account number (masked). (Tier 3) |
| 103 | BankAddressAsString | nvarchar(200) | YES | Bank address. (Tier 3) |
| 104 | BankCodeAsDecimal | nvarchar(200) | YES | Bank code as numeric string. (Tier 3) |
| 105 | BankDetailsAccountIDAsString | nvarchar(200) | YES | Bank details account identifier. (Tier 3) |
| 106 | BankIDAsString | nvarchar(200) | YES | Bank identifier string. (Tier 3) |
| 107 | BankNameAsString | nvarchar(200) | YES | Name of the bank. (Tier 3) |
| 108 | BICCodeAsString | nvarchar(200) | YES | SWIFT / BIC code for wire transfers. (Tier 3) |
| 109 | BinCodeAsString | nvarchar(200) | YES | Card BIN (string form) — see also `BinCode` (#29) for bigint form. (Tier 3) |
| 110 | BinCountryIDAsInteger | nvarchar(200) | YES | Country ID of card BIN — used to resolve `BINCountry` via `Dim_Country`. (Tier 3) |
| 111 | CardTypeIDAsInteger | nvarchar(200) | YES | Card type ID — used to resolve `CardType` via `Dim_CardType`. (Tier 3) |
| 112 | CIDAsString | nvarchar(200) | YES | Customer ID as string (XML cross-check field). (Tier 3) |
| 113 | ClientBankNameAsString | nvarchar(200) | YES | Client's bank name. (Tier 3) |
| 114 | CountryIDAsInteger | nvarchar(200) | YES | Customer country from payment data (integer as string). (Tier 3) |
| 115 | CustomerAddressAsString | nvarchar(200) | YES | Customer's billing address. (Tier 3) |
| 116 | CustomerNameAsString | nvarchar(200) | YES | Customer name from payment instrument. (Tier 3) |
| 117 | ExpirationDateAsString | nvarchar(200) | YES | Card expiration date as raw string from XML. (Tier 3) |
| 118 | MaskedAccountIDAsString | nvarchar(200) | YES | Masked account/card identifier for display. (Tier 3) |
| 119 | PurseAsString | nvarchar(200) | YES | E-wallet purse / account ID. (Tier 3) |
| 120 | RoutingNumberAsString | nvarchar(200) | YES | US ACH routing number. (Tier 3) |
| 121 | SecuredCardDataAsString | nvarchar(200) | YES | Tokenized card data reference. (Tier 3) |
| 122 | SecureIDAsDecimal | nvarchar(200) | YES | Secure transaction ID (numeric string). (Tier 3) |
| 123 | SortCodeAsString | nvarchar(200) | YES | UK bank sort code. (Tier 3) |
| 124 | SwiftCodeAsString | nvarchar(200) | YES | SWIFT code for wire transfers. (Tier 3) |
| 125 | BaseExchangeRate | money | YES | Reference exchange rate before fee markup; fee spread = `ExchangeRate - BaseExchangeRate`. (Tier 1) |
| 126 | DepotID | int | YES | Acquirer/gateway configuration ID. Validated at insert against `DepotToCurrency` in production. Numeric — see `Provider` for resolved name. (Tier 1) |

---

## 4. Lineage

```
etoro.Billing.Deposit (production, 73.9M rows)
   │
   ▼ Generic Pipeline
DWH_dbo.Fact_BillingDeposit (Synapse, HASH DepositID)
   │
   ▼ SP_AllDeposits @date  (Priority 0, Daily, SB_Daily)
BI_DB_dbo.BI_DB_AllDeposits (ROUND_ROBIN, CLUSTERED ModificationDateID)
   │
   ▼ View definition (column renames only)
BI_DB_dbo.V_BI_DB_AllDeposits
   │
   ▼ Generic Pipeline
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits
```

See [`BI_DB_AllDeposits.md`](../Tables/BI_DB_AllDeposits.md) §5 for the full ETL with the 15 dimension joins and 86 PSP fields.

---

## 5. Relationships

### 5.1 Renames From Base

The 10-column rename table in §1 is the entire transformation. All other relationships (FKs to `Dim_Customer`, `Dim_Funnel`, `Dim_Country`, etc.) are inherited from `BI_DB_AllDeposits` — see parent §6.

### 5.2 Referenced By

This view (rather than the base table) is the canonical UC-side surface — joined into MIMO panels, deposits skill, and customer-360 rollups via the `payments/deposits-and-withdrawals` skill.

---

*Generated: 2026-05-07 | Wave 2 systematic NO_WIKI fill-in*
*Source: View definition + parent BI_DB_AllDeposits.md + DDL*
*Object: BI_DB_dbo.V_BI_DB_AllDeposits | Type: View | Base: BI_DB_AllDeposits*
