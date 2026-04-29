# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_SameIP]
(
	[NumOfClientsSameIP] [int] NULL,
	[IP] [nvarchar](250) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 14 upstream wiki(s). Read EACH one in full.


### Upstream `DWH_dbo.Fact_BillingDeposit` — synapse
- **Resolved as**: `DWH_dbo.Fact_BillingDeposit`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md`

# DWH_dbo.Fact_BillingDeposit

> Central deposit transaction fact table — 73.9M rows recording every eToro deposit attempt with full payment lifecycle state, routing details, exchange metadata, and ~90 XML-extracted payment data attributes. Updated daily from etoro.Billing.Deposit via SP_Fact_BillingDeposit_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Deposit + etoro.Billing.Funding + etoro.Billing.RecurringDeposit (SP join) |
| **Refresh** | Daily (SP_Fact_BillingDeposit_DL_To_Synapse, rolling DELETE + INSERT) |
| | |
| **Synapse Distribution** | HASH (DepositID) |
| **Synapse Index** | CLUSTERED (DepositID ASC) + NC (PaymentStatusID ASC, ExpirationDateID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Fact_BillingDeposit` is the DWH's authoritative record of every deposit attempt on the eToro platform — approved, declined, pending, charged back, or refunded. With 73.9M rows, it is the primary billing analytics table, used for FTD (First Time Deposit) attribution, payment provider performance, fraud analysis, exchange revenue reporting, regulatory compliance segmentation, and customer lifecycle analytics.

The table combines data from three production sources:
1. **`Billing.Deposit`** — the core deposit ledger (direct passthrough for 35 columns)
2. **`Billing.Funding`** — payment instrument details (FundingTypeID, IsRefundExcluded, DocumentRequired, AFT flags)
3. **`Billing.RecurringDeposit`** — recurring deposit configuration (OUTER APPLY for IsRecurring flag)

Additionally, ~91 columns are extracted from XML blobs stored in `Billing.Deposit.PaymentData` and `Billing.Deposit.FundingData` using the DWH UDF `ExtractXMLValue`. These cover payment-method-specific fields that vary by funding type (credit card BIN details, bank account info, e-wallet data, etc.).

**ETL pattern** (`SP_Fact_BillingDeposit_DL_To_Synapse`):
1. DELETE rows from `Ext_FBD_Fact_BillingDeposit` for the ModificationDateID window
2. INSERT from staging into Ext_FBD (multi-source JOIN + XML extraction)
3. DELETE from main `Fact_BillingDeposit` for the window
4. INSERT from Ext_FBD into Fact_BillingDeposit
5. UPDATE `PlatformID` from `Fact_CustomerAction` WHERE ActionTypeID=14 matching on SessionID (second SP pass: `EXEC SP_Fact_BillingDeposit @Yesterday`)

**Amount capping**: As of 2025-04-17, an `Amount CASE` expression caps extreme values before storage to prevent outlier distortion in aggregations.

**PlatformID enrichment**: The platform the customer used when depositing is not stored in Billing.Deposit — it is looked up via a session-to-platform join against `Fact_CustomerAction` (ActionTypeID=14, session-based match) in a second ETL pass.

**Upstream wiki**: `Billing.Deposit` has a full upstream wiki (documented in DB_Schema) providing Tier 1 column descriptions for 35 DWH columns.

---

## 2. Business Logic

### 2.1 Deposit Status Lifecycle

**What**: Deposits progress through states from submission through approval, decline, or reversal.

**Columns Involved**: `PaymentStatusID`, `RiskManagementStatusID`, `MatchStatusID`

**Rules**:
- `PaymentStatusID=2` (Approved) is the only successful terminal state — drives customer account crediting via Billing.AmountAdd in production
- `PaymentStatusID=35` (DeclineByRRE) represents real-time risk engine declines (~10.2% of deposits)
- `PaymentStatusID=13` (Pending), `5` (InProcess): intermediate states for offline/wire deposits
- States 11-12, 26, 37-39 represent post-approval reversals (Chargeback, Refund, and their reversals)
- For full state machine, see upstream wiki: Billing.Deposit §2.1

### 2.2 First Time Deposit (FTD)

**What**: `IsFTD=1` marks the customer's first ever approved deposit — the event that triggers marketing attribution and FTD bonus eligibility.

**Columns Involved**: `IsFTD`, `CID`, `DepositID`

**Rules**:
- Only one deposit per customer can have `IsFTD=1` (monotonic guarantee from production)
- `IsFTD=0` for DepositTypeID=4 (MoneyTransfer/internal transfer) regardless of deposit history
- ~60.6% of Billing.Deposit rows have IsFTD=1 (many customers deposit exactly once)
- DWH stores this as `int` (0/1) rather than `bit` in production

### 2.3 Amount and Exchange Rate

**What**: Deposits are stored in deposit currency (CurrencyID) and pre-computed to USD (AmountUSD).

**Columns Involved**: `Amount`, `CurrencyID`, `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`, `AmountUSD`

**Rules**:
- `Amount` is in deposit currency; stored as MONEY (4 decimal places)
- As of 2025-04-17: Amount is capped via CASE expression before storage (prevents extreme outlier values)
- `AmountUSD = Amount × ExchangeRate` (DWH-computed in ETL)
- `BaseExchangeRate` stores the rate before fee markup; `ExchangeFee` stores the fee
- For USD deposits: ExchangeRate=1.0, AmountUSD=Amount

### 2.4 XML-Extracted Payment Data (~91 Columns)

**What**: `Billing.Deposit.PaymentData` and `FundingData` store provider-specific XML blobs. The DWH ETL extracts ~91 attributes using `ExtractXMLValue(xml_blob, attribute_name)` into dedicated nvarchar(max) columns.

**Rules**:
- Each `*AsString`, `*AsDecimal`, `*AsInteger` suffix column is a single XML attribute extracted by name
- The payment data schema varies by FundingTypeID — credit card deposits populate card-specific fields; bank wire deposits populate bank-specific fields; e-wallet deposits populate e-wallet fields
- NULL in any XML column means either: (a) the attribute doesn't exist for this funding type, or (b) it was absent from the XML for this deposit
- `ThreeDsResponseType` is a notable XML-extracted field — joins to Dim_ThreeDsResponseTypes via TRY_CAST(...AS INT)

### 2.5 Platform Attribution

**What**: `PlatformID` identifies the device/platform the customer was on when making the deposit (web, iOS, Android, etc.).

**Columns Involved**: `PlatformID`, `SessionID`

**Rules**:
- `PlatformID` is NOT from Billing.Deposit — it's populated via a second ETL pass:
  `UPDATE Fact_BillingDeposit SET PlatformID = (SELECT PlatformID FROM Fact_CustomerAction WHERE ActionTypeID=14 AND SessionID = Fact_BillingDeposit.SessionID)`
- If no matching Fact_CustomerAction row exists for the session, PlatformID remains NULL
- ActionTypeID=14 represents a "Deposit" action type in Fact_CustomerAction

### 2.6 Recurring Deposits

**What**: `IsRecurring` identifies deposits that are part of a scheduled recurring deposit plan.

**Columns Involved**: `IsRecurring`, `DepositID`

**Rules**:
- `IsRecurring = 1` when a matching row exists in `Billing.RecurringDeposit` for this deposit (OUTER APPLY)
- `IsRecurring = 0` for one-time deposits
- Recurring deposits may have DepositTypeID=3 (Recurring) or DepositTypeID=5 (RecurringInvestment)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`HASH(DepositID)` ensures even distribution — each deposit has a unique ID so this is an optimal hash key for point lookups and JOINs by deposit. The clustered index on `DepositID` makes per-deposit point lookups fast. The NC index on `(PaymentStatusID, ExpirationDateID)` supports filtered queries by status and expiration date.

**Warning**: At 73.9M rows, full-table scans are expensive. Always filter by `ModificationDateID` or `PaymentStatusID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily approved deposit volume | WHERE PaymentStatusID=2, GROUP BY ModificationDateID |
| FTD analysis | WHERE IsFTD=1 AND PaymentStatusID=2 |
| Exchange fee revenue | SUM(AmountUSD - Amount/ExchangeRate×BaseExchangeRate) |
| Regulation-specific deposits | WHERE ProcessRegulationID = @regId |
| Platform breakdown | GROUP BY PlatformID (JOIN Dim_Platform) |
| 3DS outcome analysis | TRY_CAST(ThreeDsResponseType AS INT) JOIN Dim_ThreeDsResponseTypes |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID | Customer demographics |
| DWH_dbo.Dim_Date | ON ModificationDateID | Time dimension |
| DWH_dbo.Dim_Currency | ON CurrencyID | Currency name |
| DWH_dbo.Dim_Platform | ON PlatformID | Device/platform |
| DWH_dbo.Dim_ThreeDsResponseTypes | ON TRY_CAST(ThreeDsResponseType AS INT) | 3DS outcome |

### 3.4 Gotchas

- **73.9M rows**: Always filter. Prefer ModificationDateID or ExpirationDateID index for range queries
- **XML columns are all nvarchar(max)**: Aggregating or joining on XML-extracted columns requires TRY_CAST — they are stored as strings regardless of semantic type
- **`v` column**: This unnamed column (`v`) is an XML-extracted field with no descriptive name — artifact of the XML schema. Contents unknown without domain review
- **PlatformID may be NULL**: Session-to-platform join succeeds only if the deposit session was logged in Fact_CustomerAction
- **AmountUSD is ETL-computed**: Not from production; recalculated as Amount×ExchangeRate at ETL time. For exact USD reconciliation, use Amount×ExchangeRate directly
- **ExpirationDateID formula**: Complex derived calculation from ExpirationDateAsString XML field — not a simple date conversion

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — upstream wiki, Billing.Deposit) |
| Tier 2 — SP ETL code | (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

**Note**: Elements are grouped by category for readability.

### 4.1 Core Deposit Identifiers & Status (from Billing.Deposit — Tier 1)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | int | YES | Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH. (Tier 1 — upstream wiki, Billing.Deposit) |
| 2 | CID | int | YES | Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer. (Tier 1 — upstream wiki, Billing.Deposit) |
| 3 | PaymentStatusID | int | YES | Current deposit status. Key values: 1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum in upstream wiki. NC index key. (Tier 1 — upstream wiki, Billing.Deposit) |
| 4 | IsFTD | int | YES | First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 in Billing.Deposit. Stored as int in DWH (vs. bit in production). (Tier 1 — upstream wiki, Billing.Deposit) |
| 5 | PaymentDate | datetime | YES | UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time. (Tier 1 — upstream wiki, Billing.Deposit) |
| 6 | ModificationDate | datetime | YES | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. (Tier 1 — upstream wiki, Billing.Deposit) |
| 7 | RiskManagementStatusID | int | YES | Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation. (Tier 1 — upstream wiki, Billing.Deposit) |
| 8 | MatchStatusID | tinyint | YES | PSP reconciliation match status. Default 0=Unmatched; 3=Matched. Used for provider reconciliation workflows. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.2 Amount & Currency (from Billing.Deposit — Tier 1)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 9 | Amount | money | YES | Deposit amount in the deposit currency (CurrencyID). As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations. (Tier 1 — upstream wiki, Billing.Deposit) |
| 10 | CurrencyID | int | YES | Currency of the deposit amount. References DWH_dbo.Dim_Currency. 1=USD, 2=EUR, 3=GBP, etc. (Tier 1 — upstream wiki, Billing.Deposit) |
| 11 | ExchangeRate | numeric(16,8) | YES | Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 12 | BaseExchangeRate | numeric(16,8) | YES | Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019). (Tier 1 — upstream wiki, Billing.Deposit) |
| 13 | ExchangeFee | int | YES | Exchange fee in provider-specific integer encoding (basis points). Added by Adi (19/02/2019). (Tier 1 — upstream wiki, Billing.Deposit) |
| 14 | Commission | money | YES | Commission charged on this deposit. Default 0 in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 15 | AmountUSD | decimal(11,2) | YES | Deposit amount converted to USD. DWH-computed: Amount × ExchangeRate. Not from production source — pre-computed in ETL for reporting convenience. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

### 4.3 Payment Instrument & Routing (from Billing.Deposit + Billing.Funding — Tier 1 + Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 16 | FundingID | int | YES | Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. (Tier 1 — upstream wiki, Billing.Deposit) |
| 17 | FundingTypeID | int | YES | Type of payment instrument. Sourced from Billing.Funding.FundingTypeID (not from Billing.Deposit directly). Categorizes the deposit by payment method (credit card, wire, ACH, etc.). (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 18 | DepotID | int | YES | Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 19 | ProtocolMIDSettingsID | int | YES | Merchant ID configuration profile. Default 0=no specific MID. Added 2018-10-24. (Tier 1 — upstream wiki, Billing.Deposit) |
| 20 | MerchantAccountID | int | YES | Merchant account legal entity for regulatory routing. Added with DBA-646. (Tier 1 — upstream wiki, Billing.Deposit) |
| 21 | RoutingReasonID | int | YES | Reason code for routing path selection. Values 1-8; 3=most common (~29%). ~31% NULL for legacy records. Added PAYUS-3061, 2021-06-15. (Tier 1 — upstream wiki, Billing.Deposit) |
| 22 | ProcessRegulationID | int | YES | Regulatory entity/jurisdiction: 1=Cyprus/EU (~63%), 2=UK/FCA (~16%), 4=AU (~2.5%), others for ASIC etc. Added DBA-646, 2021-09-05. (Tier 1 — upstream wiki, Billing.Deposit) |
| 23 | FlowID | int | YES | Deposit UX flow variant. NULL=default (98.9%), 1=new flow (0.97%), 3=specific variant. Added PAYIL-8362, 2024-04-18. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.4 Identifiers & Timestamps (from Billing.Deposit — Tier 1 + DWH Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 24 | Approved | bit | YES | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Retained for backward compatibility. (Tier 1 — upstream wiki, Billing.Deposit) |
| 25 | ProcessorValueDate | datetime | YES | Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods. (Tier 1 — upstream wiki, Billing.Deposit) |
| 26 | ClearingHouseEffectiveDate | datetime | YES | Settlement date assigned by the clearing house. NULL for instant payment methods. (Tier 1 — upstream wiki, Billing.Deposit) |
| 27 | ExTransactionID | varchar(50) | YES | External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution. (Tier 1 — upstream wiki, Billing.Deposit) |
| 28 | RefundVerificationCode | varchar(50) | YES | Verification code for refund correlation. Set by UpdateRefundDetails. NULL for non-refunded deposits. (Tier 1 — upstream wiki, Billing.Deposit) |
| 29 | IPAddress | numeric(18,0) | YES | Customer IP address at deposit time, as a 32-bit integer. Used for fraud detection. (Tier 1 — upstream wiki, Billing.Deposit) |
| 30 | SessionID | bigint | YES | Application session ID. Used for PlatformID enrichment via Fact_CustomerAction JOIN (second ETL pass). (Tier 1 — upstream wiki, Billing.Deposit) |
| 31 | ManagerID | int | YES | Operations manager who processed this deposit. 0=automated. (Tier 1 — upstream wiki, Billing.Deposit) |
| 32 | FunnelID | int | YES | Marketing funnel ID. FK to Dictionary.Funnel. (Tier 1 — upstream wiki, Billing.Deposit) |
| 33 | PaymentGeneration | int | YES | Payment infrastructure generation: 0=Gen0 (7.7%), 1=Gen1 (92%). Added 2020-04-19. (Tier 1 — upstream wiki, Billing.Deposit) |
| 34 | ModificationDateID | int | YES | ETL key. Integer YYYYMMDD derived from ModificationDate (CONVERT(INT, date)). Used for rolling-window DELETE+INSERT. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 35 | ExpirationDateID | int | YES | Integer date ID derived from ExpirationDateAsString XML attribute via a complex formula in SP. Represents card expiration date as YYYYMMDD. NC index key. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 36 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at SP execution. Not from production. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

### 4.5 Bonus & Campaign (from Billing.Deposit — Tier 1)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 37 | BonusStatusID | int | YES | Promotional bonus status. Values: 0=New, 1=Approved, 2=Declined, 3=Reverted. Only 239 non-zero records in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 38 | BonusAmount | money | YES | Bonus amount credited with this deposit. NULL when no bonus applies. (Tier 1 — upstream wiki, Billing.Deposit) |
| 39 | BonusErrorCode | int | YES | Error code when bonus processing fails (BonusStatusID=2). NULL when bonus succeeds or not attempted. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.6 Platform & Recurring (DWH-enriched — Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 40 | PlatformID | int | YES | Device/platform the customer used for this deposit. NOT from Billing.Deposit — enriched via second ETL pass: JOIN Fact_CustomerAction ON SessionID WHERE ActionTypeID=14. NULL if no matching session action found. References DWH_dbo.Dim_Platform. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 41 | IsRecurring | int | YES | 1=deposit is part of a recurring schedule (OUTER APPLY on Billing.RecurringDeposit). 0=one-time deposit. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 42 | IsSetBalanceCompleted | int | YES | 1=account crediting (Billing.AmountAdd) completed for this deposit. Added DBA-646. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.7 Funding Instrument Metadata (from Billing.Funding — Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 43 | IsRefundExcluded | int | YES | Whether this deposit is excluded from refund eligibility. Sourced from Billing.Funding.IsRefundExcluded. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 44 | DocumentRequired | int | YES | Whether documentation was required for this deposit/funding instrument. Sourced from Billing.Funding.DocumentRequired. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 45 | IsAftSupportedAsBool | bit | YES | Whether Account Funding Transaction (AFT) is supported by this funding instrument. Sourced from Billing.Funding. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 46 | IsAftEligibleAsBool | bit | YES | Whether this deposit was eligible for AFT processing. Sourced from Billing.Funding. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 47 | IsAftProcessedAsBool | bit | YES | Whether this deposit was actually processed via AFT. Sourced from Billing.Funding or Billing.Deposit. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

### 4.8 XML-Extracted Payment Data Fields (~91 Columns — Tier 2)

The following columns are all extracted from `Billing.Deposit.PaymentData` or `FundingData` XML blobs using `ExtractXMLValue(xml_blob, 'AttributeName')`. Each column stores the string value of a single XML attribute. All are `nvarchar(max)` unless noted. NULL means the attribute was absent in the XML for this deposit/funding type.

| # | Element | Notes |
|---|---------|-------|
| 48 | SecuredCardDataAsString | Tokenized card data reference |
| 49 | BinCodeAsString | Card BIN (first 6-8 digits) |
| 50 | BinCountryIDAsInteger (int) | Country of card BIN |
| 51 | CardTypeIDAsInteger (int) | Card type ID (Visa, MC, etc.) |
| 52 | CountryIDAsInteger (int) | Customer country from payment data |
| 53 | StateIDAsInteger (int) | Customer state/province from payment data |
| 54 | BankIDAsInteger (int) | Bank identifier integer |
| 55 | AccountNameAsString | Bank account holder name |
| 56 | AccountTypeAsString | Bank account type (checking, savings) |
| 57 | BankAccountAsString | Bank account number (masked) |
| 58 | BankAddressAsString | Bank address |
| 59 | BankCodeAsDecimal | Bank code (numeric string) |
| 60 | BankDetailsAccountIDAsString | Bank details account identifier |
| 61 | BankIDAsString | Bank identifier string |
| 62 | BankNameAsString | Name of the bank |
| 63 | BICCodeAsString | SWIFT/BIC code for wire transfers |
| 64 | CIDAsString | Customer ID as string (XML cross-check) |
| 65 | v | XML-extracted field with no descriptive name (artifact) — contents require domain review |
| 66 | CustomerAddressAsString | Customer's billing address |
| 67 | CustomerNameAsString | Customer name from payment instrument |
| 68 | FundingType | Funding type label from XML |
| 69 | MaskedAccountIDAsString | Masked account/card identifier for display |
| 70 | PurseAsString | E-wallet purse/account ID |
| 71 | RoutingNumberAsString | US ACH routing number |
| 72 | SecureIDAsDecimal | Secure transaction ID (numeric string) |
| 73 | SortCodeAsString | UK bank sort code |
| 74 | AccountBalanceAsDecimal | Account balance from payment provider |
| 75 | AccountHolderAsString | Account holder name |
| 76 | AccountIDAsDecimal | Account identifier (numeric string) |
| 77 | ACHBankAccountIDAsInteger | ACH bank account reference ID |
| 78 | Address1AsString | Billing address line 1 |
| 79 | Address2AsString | Billing address line 2 |
| 80 | AdviseAsString | Payment provider advisory message |
| 81 | AvailableBalanceAsDecimal | Available balance from provider |
| 82 | BankCodeAsString | Bank code (string form) |
| 83 | BillNumberAsString | Bill/invoice number |
| 84 | BuildingNumberAsString | Building number in address |
| 85 | CardHolderPhoneNumberBodyAsString | Cardholder phone number body |
| 86 | CardHolderPhoneNumberPrefixAsString | Cardholder phone number prefix |
| 87 | CardNumberAsString | Card number (masked) |
| 88 | CityAsString | Billing city |
| 89 | CountryIDAsString | Country identifier string |
| 90 | CountryNameAsString | Country name from payment XML |
| 91 | CreatedAtAsString | Payment instrument creation timestamp |
| 92 | CurrentBalanceAsDecimal | Current balance from provider |
| 93 | CustomerIDAsString | Customer ID string from payment data |
| 94 | EmailAsString | Customer email from payment instrument |
| 95 | EndPointIDAsString | Payment provider endpoint identifier |
| 96 | ErrorCodeAsString | Provider error code on decline |
| 97 | ErrorTypeAsString | Provider error type classification |
| 98 | FirstNameAsString | Cardholder/account holder first name |
| 99 | IBANCodeAsString | IBAN for wire/SEPA transfers |
| 100 | InitialTransactionIDAsString | Initial transaction ID for recurring |
| 101 | IPAsString | Customer IP as string |
| 102 | LanguageIDAsInteger | Language ID from payment data |
| 103 | LastNameAsString | Cardholder/account holder last name |
| 104 | MD5AsString | MD5 hash from payment provider |
| 105 | PayerAsString | Payer name (PayPal/e-wallet) |
| 106 | PayerBusiness | Payer business name (PayPal) |
| 107 | PayerIDAsString | Payer identifier string |
| 108 | PayerPurseAsString | Payer purse/wallet ID |
| 109 | PayerStatus | Payer verification status |
| 110 | PaymentAmountAsDecimal | Amount from payment XML |
| 111 | PaymentDateAsDateTime | Payment date from XML |
| 112 | PaymentGuaranteeAsString | Payment guarantee code |
| 113 | PaymentModeAsInteger | Payment processing mode |
| 114 | PaymentProviderTransactionStatusAsString | Status string from provider |
| 115 | PaymentStatusAsInteger | Status integer from provider |
| 116 | PaymentTypeAsString | Payment type label from provider |
| 117 | PlaidItemIDAsString | Plaid (ACH) item identifier |
| 118 | PlaidNamesAsString | Plaid account holder names |
| 119 | PlatformIDAsInteger | Platform from payment XML (separate from PlatformID) |
| 120 | PromotionCodeAsString | Promotion/voucher code used |
| 121 | PSPCodeAsString | Payment service provider code |
| 122 | RapidFirstNameAsString | Rapid (payout) first name |
| 123 | RapidLastNameAsString | Rapid (payout) last name |
| 124 | ResponseMessageAsString | Provider response message |
| 125 | ResponseTimeAsString | Provider response time |
| 126 | SecretKeyAsString | Provider secret key (masked/reference) |
| 127 | ThreeDsAsJson | Raw 3DS authentication data as JSON string |
| 128 | ThreeDsResponseType | 3DS outcome ID as string. Cast to INT to JOIN Dim_ThreeDsResponseTypes. 15 possible values (0-14). |
| 129 | TokenAsString | Payment token from tokenization service |
| 130 | TransactionIDAsString | Provider transaction ID string |
| 131 | ZipCodeAsString | Billing postal/ZIP code |
| 132 | MOPCountry | Method-of-Payment country code |
| 133 | SwiftCodeAsString | SWIFT code for wire transfers |
| 134 | ClientBankNameAsString | Client's bank name |
| 135 | BankName | Bank name (varchar(100), not nvarchar(max)) |
| 136 | CardCategory | Card category label (varchar(50)) |

*All XML-extracted columns: Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse (ExtractXMLValue)*

---

## 5. Lineage

### 5.1 Production Sources

| Source | DWH Columns | Transform |
|--------|-------------|-----------|
| etoro.Billing.Deposit (d) | CID, CurrencyID, Commission, Approved, ModificationDate, FundingID, ExchangeRate, DepositID, ProcessorValueDate, DepotID, PaymentStatusID, ManagerID, RiskManagementStatusID, Amount (capped), PaymentDate, IPAddress, ClearingHouseEffectiveDate, IsFTD, RefundVerificationCode, MatchStatusID, BonusStatusID, BonusAmount, BonusErrorCode, ExTransactionID, BaseExchangeRate, ExchangeFee, ProtocolMIDSettingsID, FunnelID, SessionID, PaymentGeneration, ProcessRegulationID, MerchantAccountID, IsSetBalanceCompleted, RoutingReasonID, FlowID | Mostly passthrough; Amount has CASE cap |
| etoro.Billing.Funding (f) | FundingTypeID, IsRefundExcluded, DocumentRequired, IsAftSupportedAsBool, IsAftEligibleAsBool, IsAftProcessedAsBool | JOIN on FundingID |
| etoro.Billing.RecurringDeposit | IsRecurring | OUTER APPLY check |
| ETL-computed | ModificationDateID, ExpirationDateID, AmountUSD, UpdateDate | SP formulas |
| XML (d.PaymentData / d.FundingData) | ~91 XML columns | ExtractXMLValue(xml, 'attr') |
| DWH_dbo.Fact_CustomerAction (2nd pass) | PlatformID | UPDATE via SessionID JOIN, ActionTypeID=14 |

### 5.2 ETL Pipeline

```
etoro.Billing.Deposit (etoroDB-REAL, 73.9M rows)
  + etoro.Billing.Funding (payment instruments)
  + etoro.Billing.RecurringDeposit (recurring schedule)
  |
  v [Generic Pipeline — daily, 1440 min, Override]
Bronze/etoro/Billing/Deposit/
  |
  v [staging]
DWH_staging.etoro_Billing_Deposit + etoro_Billing_Funding + etoro_Billing_RecurringDeposit
  |
  v [SP_Fact_BillingDeposit_DL_To_Synapse — Pass 1]
    1. DELETE Ext_FBD (rolling window by ModificationDateID)
    2. INSERT Ext_FBD from staging (multi-source JOIN + ~91 ExtractXMLValue calls)
    3. DELETE Fact_BillingDeposit (same window)
    4. INSERT Fact_BillingDeposit from Ext_FBD
  |
  v [SP_Fact_BillingDeposit @Yesterday — Pass 2]
    UPDATE PlatformID via Fact_CustomerAction (SessionID JOIN, ActionTypeID=14)
DWH_dbo.Fact_BillingDeposit (73.9M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who made the deposit |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Current deposit status |
| RiskManagementStatusID | DWH_dbo.Dim_RiskManagementStatus | Risk engine decision |
| ModificationDateID | DWH_dbo.Dim_Date | Date dimension |
| ExpirationDateID | DWH_dbo.Dim_Date | Card expiration date |
| FundingTypeID | DWH_dbo.Dim_FundingType | Payment method type |
| PlatformID | DWH_dbo.Dim_Platform | Device/platform |
| FunnelID | DWH_dbo.Dim_Funnel | Marketing funnel |
| TRY_CAST(ThreeDsResponseType AS INT) | DWH_dbo.Dim_ThreeDsResponseTypes | 3DS authentication outcome |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Cashout_State | DepositID | Linked deposit for refund/chargeback cashouts |
| SP_Fact_BillingDeposit (2nd pass) | SessionID | Platform enrichment pass reads this table |

---

## 7. Sample Queries

### 7.1 Daily approved deposit volume (USD)

```sql
SELECT
    ModificationDateID,
    COUNT(*) AS DepositCount,
    SUM(AmountUSD) AS TotalUSD,
    SUM(CASE WHEN IsFTD=1 THEN 1 ELSE 0 END) AS FTDCount
FROM [DWH_dbo].[Fact_BillingDeposit]
WHERE PaymentStatusID = 2
  AND ModificationDateID >= CONVERT(INT, CONVERT(varchar(8), DATEADD(day,-30,GETDATE()), 112))
GROUP BY ModificationDateID
ORDER BY ModificationDateID DESC
```

### 7.2 Decline rate by regulation entity

```sql
SELECT
    ProcessRegulationID,
    COUNT(*) AS TotalDeposits,
    SUM(CASE WHEN PaymentStatusID = 2 THEN 1 ELSE 0 END) AS Approved,
    SUM(CASE WHEN PaymentStatusID = 35 THEN 1 ELSE 0 END) AS DeclinedByRRE,
    CAST(SUM(CASE WHEN PaymentStatusID = 2 THEN 1 ELSE 0 END) AS float) / COUNT(*) AS ApprovalRate
FROM [DWH_dbo].[Fact_BillingDeposit]
WHERE ModificationDateID >= CONVERT(INT, CONVERT(varchar(8), DATEADD(day,-7,GETDATE()), 112))
GROUP BY ProcessRegulationID
ORDER BY TotalDeposits DESC
```

### 7.3 3DS outc

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Customer` — synapse
- **Resolved as**: `DWH_dbo.Dim_Customer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`

﻿# DWH_dbo.Dim_Customer

> Master customer dimension table for the DWH; consolidates identity, demographics, compliance status, acquisition tracking, and external integrations from 14+ staging sources into a single slowly-changing Type 1 dimension with explicit change detection, PII masking, and multi-phase post-load enrichment.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | RealCID (PK NOT ENFORCED, CLUSTERED INDEX, HASH distribution key) |
| **Distribution** | HASH(RealCID) |
| **Index** | CLUSTERED INDEX (RealCID ASC); PK NONCLUSTERED NOT ENFORCED |
| **Column Count** | 107 |
| **PII Masking** | 14 columns with Dynamic Data Masking |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Tables** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (masked), `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer` (unmasked PII) |
| **UC Copy Strategy** | Override |
| **Refresh** | Daily (1440 min) |
| **ETL Pattern** | CDC-style: change detection → DELETE/INSERT → multi-phase UPDATE enrichment |

---

## 1. Business Meaning

`Dim_Customer` is the DWH's central customer master table — the single point of reference for all customer attributes in analytics and reporting. It consolidates data from 14+ production staging tables spanning multiple microservices (Customer, BackOffice, Billing, Compliance, STS Audit, UserAPI, SalesForce, ContactVerification) into one denormalized row per customer.

The table follows a Type 1 SCD (Slowly Changing Dimension) pattern: each daily ETL run detects changes across 50+ columns and performs a DELETE/INSERT for modified customers, preserving certain indicator fields (deposit history, avatar, document proofs, Tangany/DLT/EquiLend IDs) that are maintained independently of the core change cycle.

Two UC copies exist:
- **Masked**: `main.dwh.gold_...dim_customer_masked` — PII columns contain masked values, accessible to general analytics
- **Unmasked**: `main.pii_data.gold_...dim_customer` — full PII, restricted access

### Business Usage

- **Regulatory Reporting**: Confluence "Business & Regulatory Undertakings Monitoring Platform" JOINs `Dim_Customer` on CID=RealCID for country, regulation, and status filtering
- **BI Queries**: Nearly every DWH fact table JOINs to Dim_Customer (via CID=RealCID) for customer segmentation
- **Synapse Training**: Confluence "Temporary Tables in Synapse" uses Dim_Customer as a reference example for HASH distribution optimization

---

## 5. Lineage

### 2.1 Staging Sources (14+ tables)

| Staging Table | Production Source | Role |
|--------------|-------------------|------|
| `DWH_staging.etoro_Customer_Customer` | Customer.CustomerStatic | Core customer profile (identity, demographics, registration) |
| `DWH_staging.etoro_BackOffice_Customer` | BackOffice.Customer | Compliance/admin attributes (verification, risk, regulation, guru status) |
| `DWH_staging.etoro_History_Customer` | History.Customer | Latest version for change detection (SCD) |
| `DWH_staging.etoro_History_BackOfficeCustomer` | History.BackOfficeCustomer | Latest version for BO attribute change detection |
| `DWH_staging.STS_Audit_UserOperationsData` | STS_Audit.UserOperationsData | 2FA enable/disable tracking |
| `DWH_staging.ContactVerification_Phone_Customer` | ContactVerification.Phone.Customer | Phone number, verification status |
| `DWH_staging.UserApiDB_Customer_Avatars` | UserApiDB.Customer.Avatars | Avatar upload tracking |
| `DWH_staging.etoro_Billing_vDeposit` | Billing.vDeposit | Legacy FTD source (replaced by below) |
| `DWH_staging.CustomerFinanceDB_Customer_FirstTimeDeposits` | CustomerFinanceDB.Customer.FirstTimeDeposits | FTD date, amount, platform, recovery date |
| `DWH_staging.ScreeningService_Screening_UserScreening` | ScreeningService.Screening.UserScreening | Screening/compliance status |
| `DWH_staging.SalesForce_DB_Prod_dbo_IdMapTopology` | SalesForce_DB_Prod.dbo.IdMapTopology | SalesForce account ID mapping |
| `DWH_staging.etoro_BackOffice_CustomerDocument` + `etoro_BackOffice_CustomerDocumentToDocumentType` | BackOffice.CustomerDocument | Address proof & ID proof status |
| `DWH_staging.etoro_Customer_CustomerStatic` | Customer.CustomerStatic | ApexID only |
| `DWH_staging.UserApiDB_Customer_CustomerIdentification` | UserApiDB.Customer.CustomerIdentification | GCID, DemoCID, TanganyID, DltID |
| `DWH_staging.ComplianceStateDB_Compliance_StocksLending` | ComplianceStateDB.Compliance.StocksLending | EquiLendID, StocksLendingStatusID |
| `DWH_dbo.Ext_Dim_SubChannel_UnifyCode` | (DWH internal) | SubChannelID via AffiliateID mapping |

### 2.2 ETL Pipeline (SP_Dim_Customer_DL_To_Synapse → SP_Dim_Customer)

```
ORCHESTRATOR (SP_Dim_Customer_DL_To_Synapse):
  1. Load 14 staging/external tables:
     Ext_Dim_Customer_Affiliate, Ext_Dim_Customer_BOCustomer, Ext_Dim_Customer_2FA,
     Ext_Dim_Customer_PhoneCustomer, Ext_Dim_Customer_Customer, Ext_Dim_Customer_Avatars,
     Ext_etoro_Billing_vDeposit, Ext_CustomerFinanceDB_Customer_FirstTimeDeposits,
     Ext_Dim_Customer_ScreeningStatusID, Ext_Dim_Customer_SF_ID, Ext_Dim_Customer_Document,
     Ext_Dim_CustomerStatic, Ext_Dim_Customer_CustomerIdentification, Ext_Dim_Customer_StocksLending
  2. EXEC SP_Dim_Customer

CORE LOGIC (SP_Dim_Customer):
  Step 1: Build #customer — JOIN Ext_Customer_Customer + Ext_BOCustomer
          Compute: IsValidCustomer, IsCreditReportValidCB
          Rename: SerialID→AffiliateID, ManagerID→AccountManagerID, isEmployeeAccount→EmployeeAccount
  Step 2: Detect #new (CIDs not yet in Dim_Customer)
  Step 3: Detect #update (50+ column comparison using ISNULL + COLLATE)
  Step 4: Build #full_list (new OR updated CIDs) with 2FA from Ext_2FA
  Step 5: Preserve #CustomerInitalIndicaton (deposit, avatar, document, Tangany, DLT, phone, FTD fields)
  Step 6: BEGIN TRAN: DELETE matching CIDs → INSERT with preserved indicators
  Step 7: Post-transaction UPDATEs:
          Avatar → HasAvatar, AvatarUploadDate
          Deposit → IsDepositor, FirstDepositDate, FirstDepositAmount, FTD fields
          ScreeningStatusID → from screening service
          SalesForceAccountID → from SF ID map
          Document proofs → IsAddressProof, IsIDProof + expiry dates
          2FA → from audit log
          SubChannelID → from affiliate mapping
          ApexID → from CustomerStatic
          Phone → PhoneNumber, IsPhoneVerified, PhoneVerificationDate
          Tangany → TanganyID, TanganyStatusID
          DLT → DltID, DltStatusID
          StocksLending → EquiLendID, StocksLendingStatusID
  Step 8: Populate Ext_Dim_Customer_ExternalID_GCID, update UserName_Lower
```

### 2.3 Key Column Renames

| DWH Column | Source Column | Source Table | Why |
|-----------|-------------|-------------|-----|
| RealCID | CID | etoro_Customer_Customer | Disambiguate from other CID uses in DWH |
| AffiliateID | SerialID | etoro_Customer_Customer | Business-friendly name |
| AccountManagerID | ManagerID | etoro_BackOffice_Customer | Disambiguate from other ManagerID columns |
| EmployeeAccount | isEmployeeAccount | etoro_BackOffice_Customer | Normalize casing |
| RegisteredReal | Registered | etoro_Customer_Customer | Clarify real-account registration |

### 2.4 DWH-Computed Columns

| Column | Computation |
|--------|------------|
| IsValidCustomer | `1` when PlayerLevelID≠4 AND LabelID NOT IN (30,26) AND CountryID≠250; else `0` |
| IsCreditReportValidCB | Similar to IsValidCustomer but also excludes PlayerLevelID=4 when AccountTypeID≠2, and has specific CID exceptions for CountryID=250 |
| UpdateDate | `GETDATE()` — ETL timestamp |
| UserName_Lower | `LOWER(UserName)` — set in final UPDATE |

---

## 4. Elements

### 3.1 Customer Identity

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 1 | RealCID | int | NO | No | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | No | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | DemoCID | int | YES | No | Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`. (Tier 2 — SP_Dim_Customer) |
| 4 | OriginalCID | int | YES | No | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 5 | ID | uniqueidentifier | NO | No | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — Customer.CustomerStatic) |
| 6 | ExternalID | decimal(38,0) | YES | No | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 — Customer.CustomerStatic) |

### 3.2 Personal Information (PII — Masked)

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 7 | UserName | varchar(20) | YES | Yes | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 8 | UserName_Lower | varchar(20) | YES | Yes | Lowercase version of UserName. Set by final UPDATE in SP_Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 9 | FirstName | nvarchar(50) | YES | Yes | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 10 | LastName | nvarchar(50) | YES | Yes | Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 11 | MiddleName | nvarchar(50) | YES | Yes | Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 — Customer.CustomerStatic) |
| 12 | Gender | char(1) | YES | Yes | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 13 | BirthDate | datetime | YES | Yes | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic) |
| 14 | Email | varchar(50) | YES | Yes | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic) |
| 15 | Phone | varchar(30) | YES | Yes | Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic) |
| 16 | IP | varchar(15) | YES | Yes | Registration IP address. (Tier 1 — Customer.CustomerStatic) |
| 17 | Zip | nvarchar(50) | YES | Yes | Postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 18 | City | nvarchar(50) | YES | Yes | City in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 19 | Address | nvarchar(100) | YES | Yes | Street address in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 20 | BuildingNumber | nvarchar(30) | YES | Yes | Building/apartment number. Separate from Address for structured address storage. (Tier 1 — Customer.CustomerStatic) |

### 3.3 Acquisition & Marketing

| # | Column | Type | Description |
|---|--------|------|-------------|
| 21 | AffiliateID | int | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — Customer.CustomerStatic) |
| 22 | CampaignID | int | Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organically acquired customers. (Tier 1 — Customer.CustomerStatic) |
| 23 | SubChannelID | int | Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 24 | LabelID | int | Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0. (Tier 1 — Customer.CustomerStatic) |
| 25 | BannerID | int | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 — Customer.CustomerStatic) |
| 26 | FunnelID | int | Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. NULL when not tracked. (Tier 1 — Customer.CustomerStatic) |
| 27 | FunnelFromID | int | Source funnel variant ID tracking where the customer came from within the acquisition funnel. (Tier 1 — Customer.CustomerStatic) |
| 28 | DownloadID | int | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 — Customer.CustomerStatic) |
| 29 | ReferralID | int | Referral CID - the customer who referred this customer (for RAF program tracking). (Tier 1 — Customer.CustomerStatic) |
| 30 | SubSerialID | varchar(1024) | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 — Customer.CustomerStatic) |

### 3.4 Registration & Account Lifecycle

| # | Column | Type | Description |
|---|--------|------|-------------|
| 31 | RegisteredReal | datetime | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 32 | RegisteredDemo | datetime | Demo account registration date. Source unclear — may be populated separately. (Tier 2 — SP_Dim_Customer) |
| 33 | AccountExpirationDate | datetime | Expiration date for demo or time-limited accounts. NULL for standard real-money accounts. (Tier 1 — Customer.CustomerStatic) |
| 34 | AccountStatusID | int | Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. (Tier 1 — Customer.CustomerStatic) |
| 35 | PlayerStatusID | int | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 36 | PlayerStatusReasonID | int | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 — Customer.CustomerStatic) |
| 37 | PlayerStatusSubReasonID | int | Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989). (Tier 1 — Customer.CustomerStatic) |
| 38 | PendingClosureStatusID | tinyint | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. (Tier 1 — Customer.CustomerStatic) |
| 39 | PlayerLevelID | int | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 40 | AccountTypeID | int | Customer account classification. Default=1 (real retail account). Distribution: 1=18.614M, 0=44K, 2=37K, 6=17K, others <6K. (Tier 1 — BackOffice.Customer) |
| 41 | IsDepositor | bit | Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. (Tier 2 — SP_Dim_Customer) |
| 42 | FirstDepositDate | datetime | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 43 | FirstDepositAmount | money | Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer) |

### 3.5 Compliance & Regulation

| # | Column | Type | Description |
|---|--------|------|-------------|
| 44 | RegulationID | tinyint | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 — BackOffice.Customer) |
| 45 | DesignatedRegulationID | int | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 — BackOffice.Customer) |
| 46 | RegulationChangeDate | datetime | Timestamp when RegulationID was last changed. Updated automatically by the CustomerHistoryUpdate trigger. NULL if never changed since creation. (Tier 1 — BackOffice.Customer) |
| 47 | CountryID | int | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 48 | CountryIDByIP | int | Country detected from the customer IP address at registration. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging). (Tier 1 — Customer.CustomerStatic) |
| 49 | CitizenshipCountryID | int | Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 — Customer.CustomerStatic) |
| 50 | POBCountryID | int | Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436). (Tier 1 — Customer.CustomerStatic) |
| 51 | RegionID | int | Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. (Tier 1 — Customer.CustomerStatic) |
| 52 | RegionByIP_ID | int | Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection. (Tier 1 — Customer.CustomerStatic) |
| 53 | VerificationLevelID | int | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0. (Tier 1 — BackOffice.Customer) |
| 54 | DocsOK | tinyint | Whether required documents are verified. (Tier 2 — SP_Dim_Customer) |
| 55 | DocumentStatusID | int | Current state of the customer KYC document submission and review queue. NULL if no documents submitted. (Tier 1 — BackOffice.Customer) |
| 56 | IsAddressProof | int | Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument. (Tier 2 — SP_Dim_Customer) |
| 57 | IsAddressProofExpiryDate | datetime | Expiry date of address proof document. (Tier 2 — SP_Dim_Customer) |
| 58 | IsIDProof | int | Whether ID proof document is on file (1/0). (Tier 2 — SP_Dim_Customer) |
| 59 | IsIDProofExpiryDate | datetime | Expiry date of ID proof document. (Tier 2 — SP_Dim_Customer) |
| 60 | SuitabilityTestStatusID | int | MiFID II appropriateness/suitability test result. NULL if test not completed. (Tier 1 — BackOffice.Customer) |
| 61 | MifidCategorizationID | int | MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1. (Tier 1 — BackOffice.Customer) |
| 62 | ScreeningStatusID | int | Compliance screening status. Updated from ScreeningService. (Tier 2 — SP_Dim_Customer) |
| 63 | WorldCheckID | int | Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0. (Tier 1 — BackOffice.Customer) |
| 64 | WorldCheckResultsUpdated | datetime | When World-Check results were last updated. Preserved from previous row. (Tier 2 — SP_Dim_Customer) |
| 65 | IsEDD | bit | Enhanced Due Diligence required flag. 1 = customer requires deeper AML/KYC investigation (PEP, high-risk country, large transactions). 23,944 customers (0.13%) flagged. Default=0. (Tier 1 — BackOffice.Customer) |
| 66 | Bankruptcy | tinyint | Bankruptcy flag. (Tier 2 — SP_Dim_Customer) |
| 67 | IsValidCustomer | int | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 — SP_Dim_Customer) |
| 68 | IsCreditReportValidCB | int | DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250. (Tier 2 — SP_Dim_Customer) |

### 3.6 Risk & Communication

| # | Column | Type | Description |
|---|--------|------|-------------|
| 69 | RiskStatusID | int | Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk (which allows multiple simultaneous risk flags). (Tier 1 — BackOffice.Customer) |
| 70 | RiskClassificationID | int | Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. Tracked in UPDATE trigger audit. (Tier 1 — BackOffice.Customer) |
| 71 | EmployeeAccount | tinyint | 1 if this is an eToro employee personal trading account (renamed from isEmployeeAccount). Flags employee accounts for special monitoring and compliance checks. (Tier 1 — BackOffice.Customer) |
| 72 | LanguageID | int | Customer preferred platform language. FK to Dictionary.Language. Controls UI language. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 73 | CommunicationLanguageID | int | Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences. (Tier 1 — Customer.CustomerStatic) |
| 74 | IsEmailVerified | int | Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag. (Tier 1 — Customer.CustomerStatic) |
| 75 | PrivacyPolicyID | int | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 — Customer.CustomerStatic) |
| 76 | IsCopyBlocked | bit | 1 if the customer is blocked from copy trading. 0 in all current rows - feature exists but currently unused/not enforced. (Tier 1 — BackOffice.Customer) |

### 3.7 Social & Trading Features

| # | Column | Type | Description |
|---|--------|------|-------------|
| 77 | GuruStatusID | smallint | eToro Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. (Tier 1 — BackOffice.Customer) |
| 78 | NumOfGurus | int | Number of Popular Investors this customer is copying. (Tier 2 — SP_Dim_Customer) |
| 79 | NumOfCopiers | int | Number of customers copying this customer's trades. (Tier 2 — SP_Dim_Customer) |
| 80 | NumOfRAF | int | Number of successful Refer-A-Friend referrals. (Tier 2 — SP_Dim_Customer) |
| 81 | SocialConnectID | int | Social media connection type. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 82 | PremiumAccount | tinyint | Whether this is a premium account. (Tier 2 — SP_Dim_Customer) |
| 83 | Evangelist | tinyint | Whether this customer is an evangelist/ambassador. (Tier 2 — SP_Dim_Customer) |
| 84 | HasAvatar | tinyint | Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). (Tier 2 — SP_Dim_Customer) |
| 85 | AvatarUploadDate | datetime | When the avatar was uploaded. (Tier 2 — SP_Dim_Customer) |
| 86 | EvMatchStatus | int | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — BackOffice.Customer) |

### 3.8 Account Management

| # | Column | Type | Description |
|---|--------|------|-------------|
| 87 | AccountManagerID | int | Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 — BackOffice.Customer) |
| 88 | UpdateDate | datetime | ETL load/update timestamp (GETDATE()). (Tier 2 — SP_Dim_Customer) |
| 89 | SalesForceAccountID | nvarchar(18) | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. (Tier 1 — BackOffice.Customer) |

### 3.9 Authentication & Phone Verification

| # | Column | Type | Description |
|---|--------|------|-------------|
| 90 | 2FA | int | Two-factor authentication status. 0=disabled, 1=enabled. Derived from `STS_Audit_UserOperationsData` login type events. Preserves previous value when no new 2FA event exists. (Tier 2 — SP_Dim_Customer) |
| 91 | PhoneVerifiedID | int | Result code of phone number verification process. NULL if not yet attempted. (Tier 1 — BackOffice.Customer) |
| 92 | PhoneNumber | varchar(30) | Verified phone number from ContactVerification service. Overrides `Phone` from Customer_Customer when available. (Tier 2 — SP_Dim_Customer) |
| 93 | IsPhoneVerified | bit | Whether phone is verified (VerificationStatusID IN (1,2) → 1). (Tier 2 — SP_Dim_Customer) |
| 94 | PhoneVerificationDate | smalldatetime | Date phone was verified. '1900-01-01' if not verified. (Tier 2 — SP_Dim_Customer) |

### 3.10 External Integrations

| # | Column | Type | Description |
|---|--------|------|-------------|
| 95 | ApexID | varchar(8) | APEX US stocks broker account ID. Only populated for US-regulated customers at Level >= 2 who have APEX accounts. (Tier 1 — Customer.CustomerStatic) |
| 96 | TanganyID | nvarchar(max) | Tangany crypto custody integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 97 | TanganyStatusID | tinyint | Tangany integration status. (Tier 2 — SP_Dim_Customer) |
| 98 | EquiLendID | nvarchar(max) | EquiLend securities lending integration ID. Updated from StocksLending. (Tier 2 — SP_Dim_Customer) |
| 99 | StocksLendingStatusID | int | Stocks lending consent status. (Tier 2 — SP_Dim_Customer) |
| 100 | DltID | nvarchar(max) | Distributed Ledger Technology integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 101 | DltStatusID | int | DLT integration status. (Tier 2 — SP_Dim_Customer) |
| 102 | HasWallet | int | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — BackOffice.Customer) |

### 3.11 FTD (First Time Deposit) Tracking

| # | Column | Type | Description |
|---|--------|------|-------------|
| 103 | FTDPlatformID | nvarchar(4000) | Platform/account type of the first deposit (AccountTypeId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 104 | FTDTransactionID | nvarchar(4000) | Transaction ID of the first deposit (TransactionId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 105 | FTDRecoveryDate | datetime2(7) | Recovery date for the FTD (Updated field from source). If FTDRecoveryDate is later than original FirstDepositDate, FirstDepositDate is updated to FTDRecoveryDate. Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |

### 3.12 Miscellaneous

| # | Column | Type | Description |
|---|--------|------|-------------|
| 106 | CashoutFeeGroupID | int | Determines which withdrawal fee schedule applies to this customer. FK to Dictionary.CashoutFeeGroup. NULL = default fee group. (Tier 1 — BackOffice.Customer) |
| 107 | WeekendFeePrecentage | int | Weekend swap fee percentage. Default=100 (full fee). Values below 100 indicate discounted weekend fees for select customers. Note: column name has typo Precentage. (Tier 1 — Customer.CustomerStatic) |

---

## 2. Business Logic

### 4.1 Change Detection (CDC-Style)

The SP compares 50+ columns between `#customer` (staging) and existing `Dim_Customer` using `ISNULL(old,0) <> ISNULL(new,0)` with explicit `COLLATE Latin1_General_100_BIN` for string columns. Only customers with actual changes (or new customers) are processed. This prevents unnecessary row churn.

### 4.2 Indicator Preservation

When a customer row is updated (DELETE+INSERT), certain indicator fields are preserved from the old row via `#CustomerInitalIndicaton`: FirstDepositAmount, FirstDepositDate, HasAvatar, IsDepositor, ScreeningStatusID, SalesForceAccountID, document proofs, WorldCheckID, Tangany, Phone, EquiLend, DLT, FTD fields. These are then refreshed in subsequent post-load UPDATEs if new data is available.

### 4.3 Multi-Source Identity Resolution

Customer attributes come from multiple microservices. The ETL uses `ISNULL(history_version, current_value)` patterns to prefer the latest History version (with temporal filtering: ValidFrom < @CurrentDate, ValidFrom >= @DelayDate, ValidTo >= @CurrentDate) over the current snapshot, ensuring the most up-to-date attribute values are captured.

### 4.4 FTD Recovery Date Logic

The `FirstDepositDate` is updated using: if the existing `FirstDepositDate` (as date) is earlier than `FTDRecoveryDate`, use `FTDRecoveryDate`; otherwise use the `FTDDate`. This handles cases where an FTD was reversed and re-deposited on a different day.

### 4.5 IsValidCustomer Business Rule

```
IsValidCustomer = 1 WHEN:
  PlayerLevelID ≠ 4 (not Popular Investor)
  AND LabelID NOT IN (30, 26) (not bonus-only or specific label)
  AND CountryID ≠ 250
```

This excludes demo-like, internal, and specific-jurisdiction accounts from standard reporting.

---

## 6. Relationships

### 5.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CountryID / CountryIDByIP / CitizenshipCountryID / POBCountryID | Dim_Country | CountryID = CountryID |
| AffiliateID | Dim_Affiliate | AffiliateID = AffiliateID |
| CampaignID | Dim_Campaign | CampaignID = CampaignID |
| AccountTypeID | Dim_AccountType | AccountTypeID = AccountTypeID |
| AccountStatusID | Dim_AccountStatus | AccountStatusID = AccountStatusID |
| PlayerLevelID | (Dictionary.PlayerLevel — no DWH dim) | — |
| GuruStatusID | Dim_GuruStatus | GuruStatusID = GuruStatusID |
| FunnelID | Dim_Funnel | FunnelID = FunnelID |
| DocumentStatusID | Dim_DocumentStatus | DocumentStatusID = DocumentStatusID |
| EvMatchStatus | Dim_EvMatchStatus | EvMatchStatus = EvMatchStatus |
| CashoutFeeGroupID | Dim_CashoutFeeGroup | CashoutFeeGroupID = CashoutFeeGroupID |

### 5.2 Fact Table Relationships

Nearly every DWH fact table JOINs to Dim_Customer:
- `Fact_BillingWithdraw.CID = Dim_Customer.RealCID`
- `Fact_CustomerUnrealized_PnL.CID = Dim_Customer.RealCID`
- `Fact_SnapshotCustomer.RealCID = Dim_Customer.RealCID`
- `Fact_CustomerAction.CID = Dim_Customer.RealCID`
- `Dim_Position.CID = Dim_Customer.RealCID`

### 5.3 Source Chain

```
Production Microservices                    DWH Staging                         Synapse DWH
──────────────────────                    ──────────                         ───────────
Customer.CustomerStatic          →  etoro_Customer_Customer            ─┐
BackOffice.Customer              →  etoro_BackOffice_Customer          ─┤
History.Customer                 →  etoro_History_Customer             ─┤
History.BackOfficeCustomer       →  etoro_History_BackOfficeCustomer   ─┤  

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Fact_BillingWithdraw` — synapse
- **Resolved as**: `DWH_dbo.Fact_BillingWithdraw`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md`

# DWH_dbo.Fact_BillingWithdraw

> Denormalized withdrawal fact table; each row combines a customer withdrawal request (Billing.Withdraw), its payment execution leg (Billing.WithdrawToFunding), and the funding instrument metadata (Billing.Funding) into a single wide row with XML-extracted payment details and BIN-code enrichment, providing a one-stop analytics surface for withdrawal operations, cashout monitoring, and regulatory reporting.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | Billing.Withdraw + Billing.WithdrawToFunding + Billing.Funding |
| **Key Identifier** | WithdrawID (CLUSTERED INDEX, HASH distribution key) |
| **Distribution** | HASH(WithdrawID) |
| **Index** | CLUSTERED INDEX (WithdrawID ASC); NCI on ExpirationDateID |
| **Column Count** | 83 |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Table** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` |
| **UC Copy Strategy** | Merge |
| **Refresh** | Daily (1440 min) |
| **ETL Pattern** | DELETE-day + Staging INSERT + Post-load BIN enrichment |

---

## 1. Business Meaning

`Fact_BillingWithdraw` is the DWH's primary withdrawal analytics table. It denormalizes three production tables into a single row per withdrawal-to-funding execution:

1. **Billing.Withdraw** (`bw`): The withdrawal request — customer ID, amount, status, fees, request date
2. **Billing.WithdrawToFunding** (`wtf`): The payment execution leg — processing currency, exchange rate, payment status, depot routing
3. **Billing.Funding** (`bf`): The funding instrument — payment method metadata extracted from XML

The ETL uses `DWH_dbo.ExtractXMLValue()` to parse ~40 fields from the XML blobs (`wtf.WithdrawData` and `bf.FundingData`), flattening provider-specific payment details (card numbers, bank accounts, IBAN codes, etc.) into queryable columns. Many fields use a COALESCE pattern that tries the WithdrawToFunding XML first, falling back to the Funding XML when unavailable.

After the main load, `SP_Fact_BillingWithdraw` enriches each day's rows with `BankName` (issuing bank) and `CardCategory` from `Dim_CountryBin` matched on BIN code.

### Business Usage

- **Regulatory Reporting**: Confluence "Business & Regulatory Undertakings Monitoring Platform" queries `Fact_BillingWithdraw WHERE Fee>0` for withdrawal fee monitoring
- **Cashout Fee Analysis**: Confluence "Cashout Fee" joins to `Dim_CashoutReason`, `Dim_BillingDepot`, `Dim_FundingType`, `Dim_CardType` for fee breakdowns by regulation, club, country, and account type
- **Deposits & Withdrawals Reporting**: Confluence "Deposits and withdrawals - DWH" uses this table alongside `Fact_BillingDeposit` for combined payment flow analysis

---

## 2. Business Logic

### 2.1 ETL Pipeline (SP_Fact_BillingWithdraw_DL_To_Synapse)

```
Step 1: DELETE existing rows for @dt day (ModificationDateID range)
Step 2: TRUNCATE Ext_FBW_Fact_BillingWithdraw
Step 3: INSERT into Ext from 3-way staging JOIN:
        bw LEFT JOIN wtf ON WithdrawID
           LEFT JOIN bf ON FundingID
        WHERE bw.ModificationDate in @dt day range
        → ExtractXMLValue() for ~40 columns from XML
        → COALESCE(wtf.WithdrawData, bf.FundingData) for shared fields
Step 4: DELETE existing in Fact matching by WithdrawID (upsert pattern)
Step 5: INSERT from Ext into Fact_BillingWithdraw
Step 6: EXEC SP_Fact_BillingWithdraw @date = @dt
```

### 2.2 Post-Load Enrichment (SP_Fact_BillingWithdraw)

```
Step 1: Wait for Dim_CountryBin to be loaded today (polling loop, 60s intervals)
Step 2: UPDATE BankName = cb.IssuingBank, CardCategory = cb.CardCategory
        FROM Fact_BillingWithdraw fbw
        JOIN Dim_CountryBin cb ON CAST(fbw.BinCodeAsString AS INT) = cb.BinCode
        WHERE ModificationDateID = @dateID
```

### 2.3 Dual Status Tracking

The table carries two CashoutStatusID columns reflecting different levels:
- **CashoutStatusID_Withdraw** (request level): Tracks the overall withdrawal request lifecycle. 71% of requests are Cancelled in production.
- **CashoutStatusID_Funding** (execution level): Tracks the specific payment leg execution. A request can be Processed overall while having multiple legs with different statuses.

Both reference `Dim_CashoutStatus`. Key values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled.

### 2.4 Dual FundingType Tracking

- **FundingTypeID_Withdraw**: The payment method the customer selected when making the withdrawal request (from Billing.Withdraw)
- **FundingTypeID_Funding**: The payment method of the actual funding instrument receiving the payout (from Billing.Funding)

These may differ when the payout is routed to a different method than originally requested.

### 2.5 Dual Amount Tracking

- **Amount_Withdraw**: The gross withdrawal amount in the request currency (CurrencyID)
- **Amount_WithdrawToFunding**: The actual payout amount in the processing currency (ProcessCurrencyID)

The difference may be due to exchange rate conversion (ExchangeRate) and fees (Fee, ExchangeFee).

### 2.6 XML Extraction Pattern

~40 columns are extracted from XML blobs stored in the production `WithdrawData` and `FundingData` columns using `DWH_dbo.ExtractXMLValue()`. All are stored as `nvarchar(max)` regardless of their semantic type (some represent integers, decimals, dates). The COALESCE pattern for shared fields (BIN code, IBAN, SWIFT, etc.) prefers the payment execution data over the funding instrument data, as the execution-time data is more current.

### 2.7 BIN Code Enrichment

After the main ETL load, `SP_Fact_BillingWithdraw` enriches rows by matching `BinCodeAsString` (CAST to INT) against `Dim_CountryBin.BinCode` to populate `BankName` (issuing bank) and `CardCategory`. This step waits for `Dim_CountryBin` to be loaded for the current day, polling every 60 seconds.

### 2.8 Column Rename Disambiguation

| DWH Column | Source Column | Source Table | Why Renamed |
|-----------|-------------|-------------|-------------|
| Amount_Withdraw | Amount | bw (Billing.Withdraw) | Disambiguate from WTF amount |
| Amount_WithdrawToFunding | Amount | wtf (Billing.WithdrawToFunding) | Payment leg amount in process currency |
| FundingTypeID_Withdraw | FundingTypeID | bw (Billing.Withdraw) | Payment method of the withdrawal request |
| FundingTypeID_Funding | FundingTypeID | bf (Billing.Funding) | Payment method of the funding instrument |
| CashoutStatusID_Withdraw | CashoutStatusID | bw (Billing.Withdraw) | Request-level status |
| CashoutStatusID_Funding | CashoutStatusID | wtf (Billing.WithdrawToFunding) | Execution-level status |
| ModificationDate_WithdrawToFunding | ModificationDate | wtf (Billing.WithdrawToFunding) | Execution leg last modified |
| WithdrawPaymentID | ID | wtf (Billing.WithdrawToFunding) | WTF surrogate key |

---

## 3. Query Advisory

### 3.1 Distribution & Indexing

- **HASH(WithdrawID)**: Queries filtering on `WithdrawID` are single-node. Customer-level queries (by CID) require data movement across distributions.
- **Clustered Index**: WithdrawID ASC — efficient for point lookups and range scans by WithdrawID.
- **NCI on ExpirationDateID**: Supports card expiration-based queries (compliance, PCI reporting).

### 3.2 Data Freshness

- Daily incremental load based on `ModificationDate` in the source
- Post-load BIN enrichment depends on `Dim_CountryBin` being loaded first (blocking dependency with polling)
- `UpdateDate` reflects the ETL execution timestamp

---

## 4. Elements

> Note: Upstream production wikis available for Billing.Withdraw (9.5/10), Billing.WithdrawToFunding (9.1/10), and Billing.Funding. Tier 1 descriptions inherited verbatim from upstream where columns are passthrough or renamed. XML-extracted columns (parsed from WithdrawData/FundingData XML blobs via ExtractXMLValue) are Tier 2 because they are not table-level columns in the source — they are values inside an XML document.

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. FK to Customer.CustomerStatic. (Tier 1 — Billing.Withdraw) |
| 2 | WithdrawID | int | YES | Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column. (Tier 1 — Billing.Withdraw) |
| 3 | CurrencyID | int | YES | Currency of the withdrawal amount. FK to Dictionary.Currency. (Tier 1 — Billing.Withdraw) |
| 4 | FundingTypeID_Withdraw | int | YES | Payment method type of the withdrawal request (Visa/Wire/Neteller/eToroMoney/etc.). 26 distinct values in production. Renamed from FundingTypeID to disambiguate from Billing.Funding's FundingTypeID. (Tier 1 — Billing.Withdraw) |
| 5 | RequestDate | datetime | YES | Timestamp when the customer submitted the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 6 | Amount_Withdraw | money | YES | Gross withdrawal amount in CurrencyID denomination. Renamed from Amount to disambiguate from WithdrawToFunding Amount. (Tier 1 — Billing.Withdraw) |
| 7 | Commission | money | YES | Broker commission on this withdrawal. DEFAULT=0. Typically 0 for retail customers. (Tier 1 — Billing.Withdraw) |
| 8 | Approved | int | YES | Whether the withdrawal has received required approval. 1=Approved, 0=Pending approval. DEFAULT=0. DWH note: CAST from bit to int. (Tier 1 — Billing.Withdraw) |
| 9 | ModificationDate | datetime | YES | UTC timestamp of the most recent status change or update on the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 10 | ModificationDateID | int | YES | Integer date key derived from ModificationDate: CONVERT(INT, CONVERT(VARCHAR, ModificationDate, 112)). Format YYYYMMDD. Used for partition-style filtering and the DELETE/INSERT ETL pattern. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 11 | Fee | money | YES | Platform fee charged for this withdrawal. Subtracted from the gross Amount_Withdraw. (Tier 1 — Billing.Withdraw) |
| 12 | FundingID | int | YES | FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. (Tier 1 — Billing.Withdraw) |
| 13 | CashoutReasonID | int | YES | Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason. (Tier 1 — Billing.Withdraw) |
| 14 | ClientWithdrawReasonID | int | YES | Customer-selected reason for the withdrawal (e.g., taking profits, funds needed, dissatisfied). FK to Dim_ClientWithdrawReason. (Tier 1 — Billing.Withdraw) |
| 15 | AccountCurrencyID | int | YES | Customer eToro account currency, if different from CurrencyID. Used when account and withdrawal currencies differ. FK to Dim_Currency. (Tier 1 — Billing.Withdraw) |
| 16 | CashoutStatusID_Withdraw | int | YES | Withdrawal request-level status. FK to Dim_CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. Renamed from CashoutStatusID. (Tier 1 — Billing.Withdraw) |
| 17 | Comment | nvarchar(255) | YES | Operations comment on the withdrawal request. Free-text field populated by back-office staff. (Tier 1 — Billing.Withdraw) |
| 18 | FlowID | int | YES | Processing flow identifier. NULL=legacy, 0=standard, 2=eToroMoney (triggers MoveMoneyReasonID=5), 3=alternate (triggers MoveMoneyReasonID=6). (Tier 1 — Billing.Withdraw) |
| 19 | WithdrawTypeID | int | YES | Withdrawal type classification. NULL=legacy (55%), 0=standard (41%), 1=special/alternate (3.7%), 2=second alternate (0.5%). Added 2024-08-22. (Tier 1 — Billing.Withdraw) |
| 20 | CashoutStatusID_Funding | int | YES | Execution-level status of the payment leg. FK to Dim_CashoutStatus. Values: 3=Processed (31.5%), 4=Canceled (67.7%), 14=Pending Review, 17=Partially Reversed. Renamed from CashoutStatusID. (Tier 1 — Billing.WithdrawToFunding) |
| 21 | ProcessCurrencyID | int | YES | Currency used for the actual payment processing. May differ from withdrawal CurrencyID when cross-currency routing is applied. FK to Dim_Currency. (Tier 1 — Billing.WithdrawToFunding) |
| 22 | ExchangeRate | numeric(16,8) | YES | Exchange rate applied to convert from withdrawal currency to ProcessCurrencyID. NULL for same-currency payouts. (Tier 1 — Billing.WithdrawToFunding) |
| 23 | Amount_WithdrawToFunding | money | YES | Payout amount in ProcessCurrencyID currency. Renamed from Amount. For refunds, the amount being refunded to the instrument. (Tier 1 — Billing.WithdrawToFunding) |
| 24 | ModificationDate_WithdrawToFunding | datetime | YES | UTC timestamp of the most recent status change on the payment execution leg. Renamed from ModificationDate. (Tier 1 — Billing.WithdrawToFunding) |
| 25 | DepositID | int | YES | For refund legs (CashoutTypeID=2): references the source Billing.Deposit being refunded. Value 0 is null-equivalent for cashout legs. (Tier 1 — Billing.WithdrawToFunding) |
| 26 | CashoutTypeID | tinyint | YES | Categorizes the type of payment execution: 1=Cashout (standard withdrawal, 69%), 2=Refund (refund of a prior deposit, 31%). (Tier 1 — Billing.WithdrawToFunding) |
| 27 | VerificationCode | varchar(50) | YES | Verification code supplied or received during withdrawal processing. (Tier 1 — Billing.WithdrawToFunding) |
| 28 | ProcessorValueDate | datetime | YES | Value date from the payment processor — when funds are considered available. Set for wire/ACH payouts; NULL for instant methods. (Tier 1 — Billing.WithdrawToFunding) |
| 29 | DepotID | int | YES | Which Billing.Depot (acquirer/gateway configuration) processed this payment leg. FK to Dim_BillingDepot. (Tier 1 — Billing.WithdrawToFunding) |
| 30 | ExchangeFee | int | YES | Exchange fee in provider-specific integer units. (Tier 1 — Billing.WithdrawToFunding) |
| 31 | WithdrawPaymentID | int | YES | Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID. (Tier 1 — Billing.WithdrawToFunding) |
| 32 | BaseExchangeRate | numeric(16,8) | YES | Reference exchange rate before fee markup. Spread = ExchangeRate minus BaseExchangeRate. (Tier 1 — Billing.WithdrawToFunding) |
| 33 | ProtocolMIDSettingsID | int | YES | MID configuration profile used for this payment leg. FK to Dim_BillingProtocolMIDSettingsID. Default=0. (Tier 1 — Billing.WithdrawToFunding) |
| 34 | CashoutModeID | tinyint | YES | Mode of withdrawal execution: 1=Standard (75.2%), NULL=legacy (17%), 2=Alternate e.g. eToroMoney/ACH (4%), 0=Unknown/fallback (3.8%). FK to Dim_CashoutMode. (Tier 1 — Billing.WithdrawToFunding) |
| 35 | FundingTypeID_Funding | int | YES | Payment method type of the funding instrument receiving the payout. Renamed from FundingTypeID on Billing.Funding. 34 distinct types (Visa/MC/Neteller/PayPal/Wire/eToroMoney/etc.). FK to Dim_FundingType. (Tier 1 — Billing.Funding) |
| 36 | AccountIDAsString | nvarchar(max) | YES | Payment account identifier. COALESCE: prefers wtf.WithdrawData XML, falls back to bf.FundingData XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 37 | ACHBankAccountIDAsInteger | nvarchar(max) | YES | ACH bank account identifier for US bank transfers. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 38 | BinCodeAsString | nvarchar(max) | YES | Bank Identification Number (first 6-8 digits of card). COALESCE from wtf/bf XML. CAST to INT for JOIN with Dim_CountryBin to populate BankName and CardCategory. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 39 | BinCountryIDAsInteger | nvarchar(max) | YES | Country associated with the BIN code. COALESCE from wtf/bf XML. FK to Dim_Country after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 40 | BSBNumberAsString | nvarchar(max) | YES | Bank State Branch number for Australian bank transfers. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 41 | CardTypeIDAsInteger | nvarchar(max) | YES | Card type identifier (Visa, Mastercard, etc.). COALESCE from wtf/bf XML. FK to Dim_CardType after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 42 | CityAsString | nvarchar(max) | YES | City from the payment execution data. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 43 | ClientAddressAsString | nvarchar(max) | YES | Client address from the payment execution data. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 44 | ClientBankNameAsString | nvarchar(max) | YES | Client's bank name. COALESCE from wtf/bf XML. Distinct from BankNameAsString (#67) which is from bf.FundingData only, and BankName (#82) which is post-load enrichment from Dim_CountryBin. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 45 | CountryIDAsInteger | nvarchar(max) | YES | Country identifier from payment data. COALESCE from wtf/bf XML. FK to Dim_Country after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 46 | ExpirationDateAsString | nvarchar(max) | YES | Card expiration date as raw string from wtf.WithdrawData XML. Format varies by provider (MMYY, MM/YY, etc.). See ExpirationDateID (#69) for the normalized integer version. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 47 | ErrorCodeAsString | nvarchar(max) | YES | Provider error code if the payment leg failed or was rejected. Extracted from wtf.WithdrawData XML only. NULL for successful transactions. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 48 | IBANCodeAsString | nvarchar(max) | YES | International Bank Account Number for SEPA/wire transfers. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 49 | InitialTransactionIDAsString | nvarchar(max) | YES | Initial transaction reference from the payment provider. Extracted from wtf.WithdrawData XML only. Links the withdrawal to the original deposit transaction for refund tracing. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 50 | MD5AsString | nvarchar(max) | YES | MD5 hash of payment data for verification/deduplication. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 51 | PayeeNameAsString | nvarchar(max) | YES | Payee name from the payment execution. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 52 | PayerPurseAsString | nvarchar(max) | YES | E-wallet purse identifier (e.g., PayPal, Neteller purse ID). Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 53 | ReferenceNumberAsString | nvarchar(max) | YES | Provider reference number for the transaction. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 54 | ResponseMessageAsString | nvarchar(max) | YES | Provider response message (success/failure details). Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 55 | ResponseTimeAsString | nvarchar(max) | YES | Provider response timestamp as string. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 56 | RoutingNumberAsString | nvarchar(max) | YES | Bank routing number for US bank transfers (ABA routing). COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 57 | SecuredCardDataAsString | nvarchar(max) | YES | Secured/tokenized card data from the payment provider. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 58 | SortCodeAsString | nvarchar(max) | YES | Bank sort code for UK bank transfers. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 59 | SwiftCodeAsString | nvarchar(max) | YES | SWIFT/BIC code for international wire transfers. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 60 | AccountIDAsDecimal | nvarchar(max) | YES | Funding instrument account ID (decimal form). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 61 | AccountNameAsString | nvarchar(max) | YES | Account holder name on the funding instrument. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 62 | AccountTypeAsString | nvarchar(max) | YES | Account type (checking, savings, etc.). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 63 | BankAccountAsString | nvarchar(max) | YES | Bank account number for wire/bank transfers. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 64 | BankAddressAsString | nvarchar(max) | YES | Bank address for wire transfers. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 65 | BankCodeAsString | nvarchar(max) | YES | Bank code (national bank identifier). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 66 | BankDetailsAccountIDAsString | nvarchar(max) | YES | Bank details account reference. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 67 | BankIDAsInteger | nvarchar(max) | YES | Bank identifier (integer form). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 68 | BankIDAsString | nvarchar(max) | YES | Bank identifier (string form). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 69 | BankNameAsString | nvarchar(max) | YES | Bank name from the bf.FundingData XML. Distinct from the enriched BankName (#82) which comes from Dim_CountryBin BIN-code lookup, and ClientBankNameAsString (#44) which is COALESCE from wtf/bf. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 70 | CardNumberAsString | nvarchar(max) | YES | Masked card number (last 4 digits typically visible). Extracted from bf.FundingData XML only. Source column FundingData is masked with FUNCTION='default()' in production. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 71 | CryptoCodeAsString | nvarchar(max) | YES | Cryptocurrency code/address for crypto withdrawals. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 72 | CustomerAddressAsString | nvarchar(max) | YES | Customer address from the funding instrument record. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 73 | CustomerNameAsString | nvarchar(max) | YES | Customer name from the funding instrument record. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 74 | EmailAsString | nvarchar(max) | YES | Email address associated with the funding instrument (e.g., PayPal email). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 75 | ExpirationDateID | int | YES | Card expiration date as normalized integer key: 200000 + YY*100 + MM for valid dates; 190001 for NULL or strings shorter than 4 characters. NCI index on this column. Computed from bf.FundingData ExpirationDateAsString XML field. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 76 | InstrumentIDAsInteger | nvarchar(max) | YES | Instrument identifier within the funding provider. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 77 | MaskedAccountIDAsString | nvarchar(max) | YES | Masked version of the account ID for display/audit. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 78 | PayerIDAsString | nvarchar(max) | YES | Payer identifier (e.g., PayPal Payer ID). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 79 | PurseAsString | nvarchar(max) | YES | E-wallet purse identifier from the funding instrument. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 80 | SecureIDAsDecimal | nvarchar(max) | YES | Secure identifier for payment verification. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 81 | UpdateDate | datetime | YES | ETL load timestamp (Synapse server time at INSERT via GETDATE()). (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 82 | BankName | varchar(100) | YES | Issuing bank name looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.IssuingBank. NULL when BinCodeAsString is NULL or BIN code not found. Distinct from BankNameAsString (#69) which comes from the funding XML. (Tier 2 — SP_Fact_BillingWithdraw) |
| 83 | CardCategory | varchar(50) | YES | Card category (Debit, Credit, Prepaid, etc.) looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.CardCategory. NULL when BIN code not found. (Tier 2 — SP_Fact_BillingWithdraw) |

---

## 5. Lineage

### 5.1 Staging Sources (from DWH_staging)

| Alias | Staging Table | Production Source | Role |
|-------|--------------|-------------------|------|
| `bw` | `DWH_staging.etoro_Billing_Withdraw` | `Billing.Withdraw` | Withdrawal request (core facts) |
| `wtf` | `DWH_staging.etoro_Billing_WithdrawToFunding` | `Billing.WithdrawToFunding` | Payment execution leg + XML payment data |
| `bf` | `DWH_staging.etoro_Billing_Funding` | `Billing.Funding` | Funding instrument + XML funding data |

### 5.3 Internal DWH Dependencies

| Table | Role |
|-------|------|
| `DWH_dbo.Ext_FBW_Fact_BillingWithdraw` | Staging/external table for the 3-way join result |
| `DWH_dbo.Dim_CountryBin` | Post-load enrichment: BankName + CardCategory via BIN code |
| `DWH_dbo.ExtractXMLValue` (function) | Parses individual fields from XML blobs |

---

## 6. Relationships

### 6.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CID | Dim_Customer | CID = RealCID |
| CurrencyID / AccountCurrencyID / ProcessCurrencyID | Dim_Currency | CurrencyID = CurrencyID |
| FundingTypeID_Withdraw / FundingTypeID_Funding | Dim_FundingType | FundingTypeID = FundingTypeID |
| CashoutStatusID_Withdraw / CashoutStatusID_Funding | Dim_CashoutStatus | CashoutStatusID = CashoutStatusID |
| CashoutReasonID | Dim_CashoutReason | CashoutReasonID = CashoutReasonID |
| ClientWithdrawReasonID | Dim_ClientWithdrawReason | ClientWithdrawReasonID = ClientWithdrawReasonID |
| CashoutModeID | Dim_CashoutMode | CashoutModeID = CashoutModeID |
| DepotID | Dim_BillingDepot | DepotID = DepotID |
| ProtocolMIDSettingsID | Dim_BillingProtocolMIDSettingsID | ProtocolMIDSettingsID = ProtocolMIDSettingsID |
| BinCodeAsString (CAST INT) | Dim_CountryBin | CAST(BinCodeAsString AS INT) = BinCode |
| ModificationDateID | Dim_Date (implicit) | YYYYMMDD integer key |

### 6.2 Source Chain

```
Billing.Withdraw ──bw──┐
                        ├── LEFT JOIN ON WithdrawID ──► Ext_FBW_Fact_BillingWithdraw ──► Fact_BillingWithdraw
Billing.WithdrawToFunding ─wtf─┤                                                            │
                        ├── LEFT JOIN ON FundingID                                    POST-LOAD UPDATE
Billing.Funding ──bf────┘                                                                    │
                                                                                     Dim_CountryBin
                                                                                   (BankName, CardCategory)
```

### 6.3 Referenced By

*To be populated during cross-object enrichment (Phase 12).*

---

## 7. Sample Queries

```sql
-- Withdrawal details with status names
SELECT fbw.WithdrawID, fbw.CID, fbw.Amount_Withdraw, fbw.Fee,
       dcs.Name AS WithdrawStatus, dcs2.Name AS FundingStatus
FROM DWH_dbo.Fact_BillingWithdraw fbw
JOIN DWH_dbo.Dim_CashoutStatus dcs ON fbw.CashoutStatusID_Withdraw = dcs.CashoutStatusID
LEFT JOIN DWH_dbo.Dim_CashoutStatus dcs2 ON fbw.CashoutStatusID_Funding = dcs2.CashoutStatusID
WHERE fbw.ModificationDateID BETWEEN 20260301 AND 20260319;

-- Withdrawal fee analysis (regulatory pattern)
SELECT fbw.CID, fbw.WithdrawID, fbw.Amount_Withdraw, fbw.Fee,
       dft.Name AS FundingType, dcr.Name AS CashoutReason
FROM DWH_dbo.Fact_BillingWithdraw fbw
JOIN DWH_dbo.Dim_FundingType dft ON fbw.FundingTypeID_Withdraw = dft.FundingTypeID
LEFT JOIN DWH_dbo.Dim_CashoutReason dcr ON fbw.CashoutReasonID = dcr.CashoutReasonID
WHERE fbw.Fee > 0;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| Business & Regulatory Undertakings Monitoring Platform | Queries Fact_BillingWithdraw WHERE Fee>0 for withdrawal fee monitoring |
| Cashout Fee (Confluence) | Joins to Dim_CashoutReason, Dim_BillingDepot, Dim_FundingType for fee breakdowns |
| Deposits and withdrawals - DWH (Confluence) | Uses alongside Fact_BillingDeposit for combined payment flow analysis |

---
*Generated: 2026-03-19 | Quality: 8.5/10*
*Tiers: 34 T1, 49 T2, 0 T3, 0 T4, 0 T5 | Phases: 1,5,8,9,9B,10,10.5,13,11*


### Upstream `DWH_dbo.Dim_Country` — synapse
- **Resolved as**: `DWH_dbo.Dim_Country`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md`

# DWH_dbo.Dim_Country

> Master country dimension (251 rows) mapping every country/territory to geographic, regulatory, marketing, and risk attributes. One of the most-referenced dimension tables in the DWH.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Country (primary) + etoro.Dictionary.MarketingRegion (region label) + Ext_Dim_Country (EU flags) + Ext_Dim_Country_Region_Desk (desk/CFKey) + ComplianceStateDB.Compliance.RegulationCountry (regulation) |
| **Refresh** | Daily (SP_Dictionaries_Country_DL_To_Synapse, full TRUNCATE+INSERT + 3 UPDATE passes) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (non-clustered PK on CountryID NOT ENFORCED) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Country` is one of the most heavily-referenced dimension tables in the DWH. It defines every country and territory the eToro platform recognizes (251 rows: 250 active countries + 1 "Not available" placeholder at CountryID=0). Each row provides geographic classification, regulatory risk attributes, marketing segmentation, and compliance data for users registered from that country.

When a customer registers, their CountryID determines: which regulatory entity governs them (via RegulationID), what AML/KYC scrutiny level applies (IsHighRiskCountry, RiskGroupID), what marketing desk handles them (Desk), and whether they can receive RAF bonuses (IsEligibleForRAFBonusCountry).

The ETL is multi-step: TRUNCATE+INSERT from etoro.Dictionary.Country (primary, joined to etoro.Dictionary.MarketingRegion for the Region label), then three UPDATE passes that patch in EU classification from Ext_Dim_Country, Desk/CFKey from Ext_Dim_Country_Region_Desk, and RegulationID from ComplianceStateDB.Compliance.RegulationCountry. Several columns present in the upstream Dictionary.Country source are dropped in DWH (IsSettlementRestricted, DefaultCurrencyID, LanguageID, IsActive, PhonePrefix, IsoCode).

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, VERIFIED confidence).

---

## 2. Business Logic

### 2.1 High-Risk Country Flag (Computed)

**What**: IsHighRiskCountry is derived from RiskGroupID in the ETL, not passed through from source. AML-flagged countries trigger enhanced due diligence.

**Columns Involved**: `IsHighRiskCountry`, `RiskGroupID`

**Rules**:
- `CASE WHEN RiskGroupID IN (0, 4) THEN 0 ELSE 1 END` -> IsHighRiskCountry
- RiskGroupID=0 (None): 70 countries -> not high risk
- RiskGroupID=4 (Verified before deposit): 2 countries -> not high risk
- RiskGroupID=1 (High risk country): 100 countries -> high risk
- RiskGroupID=2 (High risk for new clients): 71 countries -> high risk
- RiskGroupID=3 (High risk FATF country): 8 countries -> high risk
- High-risk countries trigger enhanced document verification, manual review of first deposit, and reduced transaction monitoring thresholds

**Diagram**:
```
RiskGroupID -> IsHighRiskCountry
0 (None)                  -> 0  (70 countries)
4 (Verified bfr deposit)  -> 0  (2 countries)
1 (High risk)             -> 1  (100 countries)
2 (High risk new clients) -> 1  (71 countries)
3 (High risk FATF)        -> 1  (8 countries)
```

### 2.2 EU vs. European Country Classification

**What**: Two separate flags distinguish full EU membership from broader European geography.

**Columns Involved**: `EU`, `IsEuropeanCountry`

**Rules**:
- EU=1: 27 countries with full EU membership (legal/treaty member states)
- IsEuropeanCountry=1: 66 countries total (27 EU members + 39 other European countries)
- Source: Ext_Dim_Country (manual extension table), not from etoro.Dictionary.Country
- EU=1 always implies IsEuropeanCountry=1. IsEuropeanCountry=1 does NOT imply EU=1.

### 2.3 Region vs. MarketingRegion

**What**: DWH exposes two separate geographic segmentations. `Region` is marketing-driven; the source geographic `RegionID` is dropped.

**Columns Involved**: `Region`, `MarketingRegionID`, `MarketingRegionManualName`, `Desk`

**Rules**:
- `Region` is loaded from etoro.Dictionary.MarketingRegion.Name (y.Name AS Region in SP). It is the marketing region label.
- `MarketingRegionManualName` is a manual override from Ext_Dim_Country - may differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE).
- `Desk` is a sales/support desk assignment from Ext_Dim_Country_Region_Desk, joined via MarketingRegionID.
- The upstream Dictionary.Country source has a geographic `RegionID` pointing to Dictionary.Region - this is NOT loaded to DWH.
- 22 distinct Region values in DWH (South & Central America=40, Africa=38, ROW=38, French=23, etc.)

### 2.4 Dropped Source Columns (Compliance-Critical)

**What**: Several compliance and localization columns present in the upstream source are NOT loaded to DWH.

**Dropped from etoro.Dictionary.Country**:
- `IsSettlementRestricted`: 21 countries restricted to CFD-only trading (cannot hold REAL assets). Includes United States (SEC/FINRA). CRITICAL for compliance analysts.
- `DefaultCurrencyID`: Trading account default currency (USD/EUR/GBP/AUD/CAD/PLN).
- `LanguageID`: UI language default.
- `IsActive`: Whether country is active on platform.
- `PhonePrefix`: International dialing code.
- `IsoCode`: ISO 3166-1 numeric code.
- `RegionID`: Geographic region FK (DWH replaces with text Region label from MarketingRegion).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE (correct for a 251-row dimension - broadcast to all nodes avoids data movement on JOINs). HEAP means no sorted index. The non-clustered PK on CountryID is NOT ENFORCED - duplicates are theoretically possible but prevented by ETL TRUNCATE.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (251 rows). Z-ORDER on CountryID optional for join optimization.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode country for a customer | `JOIN DWH_dbo.Dim_Country d ON f.CountryID = d.CountryID` |
| Filter high-risk countries | `WHERE d.IsHighRiskCountry = 1` |
| Filter EU customers | `WHERE d.EU = 1` |
| Group by marketing region | `GROUP BY d.Region` |
| Find regulation for a country | `SELECT RegulationID FROM Dim_Country WHERE CountryID = @id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON c.CountryID = d.CountryID | Decode customer country attributes |
| DWH_dbo.Fact_BillingDeposit | ON f.CountryID = d.CountryID | Country-level deposit analytics |
| DWH_dbo.Dim_CountryBin | ON c.CountryID = d.CountryID | BIN-to-country card mapping |
| DWH_dbo.V_Dim_Customer | ON v.CountryID = d.CountryID | Customer view with country decode |

### 3.4 Gotchas

- CountryID=0 ("Not available") is a real row - use `WHERE CountryID > 0` to exclude the placeholder in population-level queries.
- `IsHighRiskCountry` is RECOMPUTED from `RiskGroupID` by the ETL (not passthrough from source). If source IsHighRiskCountry changes but RiskGroupID stays the same, DWH will not reflect the change.
- `IsSettlementRestricted` is NOT in DWH. This critical compliance flag must be looked up in the source etoro.Dictionary.Country if needed.
- `Region` reflects `MarketingRegion.Name`, not the geographic `Dictionary.Region`. The two segmentations differ (e.g., Albania: geographic region=Europe, marketing Region=ROE).
- `DWHCountryID` always equals `CountryID` (redundant copy from SP: `x.CountryID AS DWHCountryID`). Never use both in GROUP BY.
- `StatusID` is hardcoded to 1 for all rows (including CountryID=0). No meaningful variation.
- `InsertDate` and `UpdateDate` are both set to GETDATE() on each daily reload - they reflect ETL run time, not original insert or data change time.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. (Tier 1 - Dictionary.Country upstream wiki) |
| 2 | Abbreviation | char(2) | NO | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Unique per row. Used in UI display, API parameters, and geolocation matching. Trimmed on use (char type has trailing spaces). (Tier 1 - Dictionary.Country upstream wiki) |
| 3 | LongAbbreviation | char(3) | NO | ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR", "DEU"). Unique per row. Used in some international reporting standards and Compliance.GetCountryLongAbbreviation (WorldCheck KYC/AML integration). (Tier 1 - Dictionary.Country upstream wiki) |
| 4 | Name | varchar(50) | NO | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki) |
| 5 | IsHighRiskCountry | tinyint | YES | AML/compliance risk flag. 0=standard risk, 1=high risk. RECOMPUTED by SP from RiskGroupID: `CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END`. 179 high-risk countries. Triggers enhanced due diligence and stricter transaction monitoring. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 6 | Region | varchar(50) | NO | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 7 | StatusID | int | YES | Hardcoded to 1 for all rows by SP. Intended to indicate active status. In practice carries no variation. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 8 | DWHCountryID | int | NO | Redundant copy of CountryID (set to `x.CountryID AS DWHCountryID` in SP). Always equals CountryID. Retained for legacy compatibility. Do not use both CountryID and DWHCountryID in the same GROUP BY. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily full reload. Reflects ETL run time, not when country data actually changed. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 10 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate) on each daily full reload. Not a true insert timestamp - both dates are refreshed on every reload due to TRUNCATE+INSERT. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 11 | EU | int | YES | Whether this country is a full EU member state. 1=EU member (27 countries), 0=non-EU. Source: Ext_Dim_Country manual extension table (left join - NULL if not in Ext_Dim_Country). Always 0 or 1 in practice. Distinct from IsEuropeanCountry. (Tier 3 - Ext_Dim_Country live data) |
| 12 | Desk | nvarchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join (a.MarketingRegionID = b.RegionID). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. (Tier 3 - Ext_Dim_Country_Region_Desk via SP) |
| 13 | RegulationID | int | YES | Regulatory entity ID governing users from this country. Loaded from ComplianceStateDB.Compliance.RegulationCountry via Ext_Dim_Country_Regulation staging. Left join - NULL if country not in compliance mapping. References the regulatory framework (e.g., CySEC, FCA, ASIC). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse via ComplianceStateDB) |
| 14 | CFKey | int | YES | Clearing/settlement framework key for this country's marketing region. Loaded from Ext_Dim_Country_Region_Desk.CFKey via MarketingRegionID join. Exact business meaning unclear - likely maps to a clearing firm or settlement category. (Tier 3 - Ext_Dim_Country_Region_Desk live data) |
| 15 | MarketingRegionID | int | YES | FK to etoro.Dictionary.MarketingRegion. Marketing segment ID grouping countries by marketing strategy. Distinct from geographic RegionID (which is dropped in DWH). 22 distinct values matching the 22 Region labels. (Tier 1 - Dictionary.Country upstream wiki) |
| 16 | RiskGroupID | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. IsHighRiskCountry is derived from this column. (Tier 1 - Dictionary.Country upstream wiki) |
| 17 | IsEligibleForRAFBonusCountry | int | YES | Whether users from this country can participate in the Refer-A-Friend bonus program. Source: CAST(etoro.Dictionary.Country.IsEligibleForRAFBonusCountry AS int) - type cast from bit to int. 1=eligible (most countries), 0=ineligible (regulatory/fraud restrictions). (Tier 1 - Dictionary.Country upstream wiki) |
| 18 | IsEuropeanCountry | int | YES | Whether this country is geographically European (broader than EU membership). 1=European (66 countries total: 27 EU + 39 others), 0=non-European. Source: Ext_Dim_Country manual extension table. Always >= EU flag. (Tier 3 - Ext_Dim_Country live data) |
| 19 | MarketingRegionManualName | varchar(50) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. (Tier 3 - Ext_Dim_Country live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | etoro.Dictionary.Country | CountryID | passthrough |
| Abbreviation | etoro.Dictionary.Country | Abbreviation | passthrough (nvarchar(max) -> char(2)) |
| LongAbbreviation | etoro.Dictionary.Country | LongAbbreviation | passthrough (nvarchar(max) -> char(3)) |
| Name | etoro.Dictionary.Country | Name | passthrough |
| IsHighRiskCountry | etoro.Dictionary.Country | RiskGroupID | computed: CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END |
| Region | etoro.Dictionary.MarketingRegion | Name | rename (y.Name AS Region via JOIN on MarketingRegionID) |
| StatusID | - | - | ETL-computed (hardcoded constant 1) |
| DWHCountryID | etoro.Dictionary.Country | CountryID | copy (x.CountryID AS DWHCountryID, always = CountryID) |
| UpdateDate | - | - | ETL-computed (GETDATE()) |
| InsertDate | - | - | ETL-computed (GETDATE()) |
| EU | DWH_dbo.Ext_Dim_Country | EU | UPDATE pass (LEFT JOIN on CountryID) |
| Desk | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| RegulationID | ComplianceStateDB.Compliance.RegulationCountry | RegulationID | UPDATE pass via Ext_Dim_Country_Regulation staging |
| CFKey | DWH_dbo.Ext_Dim_Country_Region_Desk | CFKey | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| MarketingRegionID | etoro.Dictionary.Country | MarketingRegionID | passthrough |
| RiskGroupID | etoro.Dictionary.Country | RiskGroupID | passthrough |
| IsEligibleForRAFBonusCountry | etoro.Dictionary.Country | IsEligibleForRAFBonusCountry | type cast (CAST(bit AS int)) |
| IsEuropeanCountry | DWH_dbo.Ext_Dim_Country | IsEuropeanCountry | UPDATE pass (LEFT JOIN on CountryID) |
| MarketingRegionManualName | DWH_dbo.Ext_Dim_Country | MarketingRegionManualName | UPDATE pass (LEFT JOIN on CountryID) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10).

### 5.2 ETL Pipeline

```
etoro.Dictionary.Country (x)
  -> [Generic Pipeline or direct load]
  -> DWH_staging.etoro_Dictionary_Country
  -> (JOIN) DWH_staging.etoro_Dictionary_MarketingRegion
  -> DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_Country (initial population: 19 cols partially loaded)
  -> UPDATE from DWH_dbo.Ext_Dim_Country (EU, IsEuropeanCountry, MarketingRegionManualName)
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Region_Desk (CFKey, Desk via MarketingRegionID)
  -> TRUNCATE+INSERT DWH_dbo.Ext_Dim_Country_Regulation from DWH_staging.ComplianceStateDB_Compliance_RegulationCountry
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Regulation (RegulationID)
  -> DWH_dbo.Dim_Country (fully loaded)
```

Note: The same SP also loads Dim_CountryIPAnonymous in the same transaction.

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Country | Master country reference (251 rows). 16-column source, DWH drops 8 columns. |
| Source | etoro.Dictionary.MarketingRegion | Marketing region labels. Provides Region text and MarketingRegionID. |
| Staging | DWH_staging.etoro_Dictionary_Country | Raw staging: 16 cols, HEAP ROUND_ROBIN. |
| ETL | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse | TRUNCATE + INSERT. Computes IsHighRiskCountry from RiskGroupID. Joins MarketingRegion. Hardcodes StatusID=1. Sets GETDATE() for UpdateDate/InsertDate. |
| Patch 1 | DWH_dbo.Ext_Dim_Country | Manual extension table: EU=1/0, IsEuropeanCountry=1/0, MarketingRegionManualName. LEFT JOIN on CountryID. |
| Patch 2 | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk and CFKey lookup by MarketingRegionID. LEFT JOIN on MarketingRegionID=RegionID. |
| Patch 3 | DWH_dbo.Ext_Dim_Country_Regulation | Regulation staging loaded from ComplianceStateDB.Compliance.RegulationCountry. Then LEFT JOIN on CountryID. |
| Target | DWH_dbo.Dim_Country | Final DWH dimension (251 rows). |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| MarketingRegionID | etoro.Dictionary.MarketingRegion | Marketing region segment. Implicit FK (not enforced in Synapse). |
| RiskGroupID | etoro.Dictionary.CountryRiskGroup | Country risk classification. Implicit FK (not enforced in Synapse). |
| RegulationID | ComplianceStateDB (Regulation) | Regulatory entity governing country users. Sourced from ComplianceStateDB. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | CountryID | Customer view JOINs to Dim_Country for country attributes. |
| DWH_dbo.Dim_CountryIP | CountryID | IP-to-country lookup table references Dim_Country via Abbreviation join. |
| DWH_dbo.Dim_CountryIPAnonymous | CountryID | Anonymous proxy IP table; CountryID set via Abbreviation-to-CountryID lookup against Dim_Country. |
| DWH_dbo.SP_Fact_BillingDeposit | CountryID | Billing deposit facts reference Dim_Country for country-level analytics. |
| BI_DB_dbo.SP_BI_DB_LTV_Conversions_Multipliers_Table | CountryID | LTV modeling references country dimension. |
| BI_DB_dbo.SP_Group_LTV_Table | CountryID | Group LTV analytics references country dimension. |

---

## 7. Sample Queries

### 7.1 Decode customer country
```sql
SELECT c.CustomerID, d.Name AS Country, d.Region, d.IsHighRiskCountry
FROM [DWH_dbo].[Dim_Customer] c
JOIN [DWH_dbo].[Dim_Country] d ON c.CountryID = d.CountryID
WHERE d.IsHighRiskCountry = 1;
```

### 7.2 Countries by EU membership
```sql
SELECT CountryID, Name, Abbreviation, EU, IsEuropeanCountry, Region
FROM [DWH_dbo].[Dim_Country]
WHERE EU = 1
ORDER BY Name;
```

### 7.3 Risk group distribution
```sql
SELECT RiskGroupID, IsHighRiskCountry, COUNT(*) AS CountryCount
FROM [DWH_dbo].[Dim_Country]
WHERE CountryID > 0
GROUP BY RiskGroupID, IsHighRiskCountry
ORDER BY RiskGroupID;
```

### 7.4 RAF-ineligible countries by region
```sql
SELECT Region, Name, Abbreviation
FROM [DWH_dbo].[Dim_Country]
WHERE IsEligibleForRAFBonusCountry = 0 AND CountryID > 0
ORDER BY Region, Name;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, 16 VERIFIED columns).

---

*Generated: 2026-03-19 | Quality: 8.8/10 (4 stars) | Phases: 9/14 (full pipeline, no Atlassian)*
*Tiers: 6 T1, 8 T2, 5 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Country | Type: Table | Production Source: etoro.Dictionary.Country + etoro.Dictionary.MarketingRegion + Ext_Dim_Country + ComplianceStateDB*


### Upstream `DWH_dbo.Dim_Regulation` — synapse
- **Resolved as**: `DWH_dbo.Dim_Regulation`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md`

# DWH_dbo.Dim_Regulation

> Lookup table defining the 15 regulatory jurisdictions under which eToro operates globally, with DWH-specific grouping (ClusterRegulationID) for analytics aggregation.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Regulation |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Regulation defines the 15 regulatory jurisdictions under which eToro operates globally. Each regulation represents a financial authority (CySEC, FCA, ASIC, FinCEN, etc.) and maps to an eToro legal entity holding the corresponding license. This classification drives multi-jurisdiction compliance - it determines which rules apply to each customer, what instruments they can trade, what leverage limits are enforced, and how their funds are segregated. (Tier 1 - upstream wiki, Dictionary.Regulation)

RegulationID is one of the most frequently joined columns in the DWH. It is assigned to users at registration (CustomerStatic.RegulationID) and propagated through every subsequent operation - deposits, trading, copy-trading, and compliance reporting. V_Dim_Customer joins Dim_Regulation to resolve the regulation name for every customer.

**DWH vs Production differences**: The DWH strips 6 columns from production (IsUSA, JurisdictionName, BankID, RegulationLongName, RegulationShortName, DefaultRegulationID) and adds 3 DWH-specific columns (DWHRegulationID = ID alias, StatusID = hardcoded 1, ClusterRegulationID = grouping logic). Analysts needing US/non-US split or jurisdiction names should reference the upstream wiki or query production via the Bronze layer.

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_Regulation. All 15 rows have StatusID=1 (Active). No sentinel row.

---

## 2. Business Logic

### 2.1 ClusterRegulationID Grouping

**What**: The ETL groups certain regulations into a single cluster (ID=1) for analytics aggregation.

**Columns Involved**: `ClusterRegulationID`, `ID`

**Rules**:
- IDs 0 (None), 1 (CySEC), 5 (BVI) -> ClusterRegulationID=1 (grouped as "CySEC/BVI/None" cluster)
- All other IDs -> ClusterRegulationID = ID (each regulation is its own cluster)

**Rationale**: BVI (5) is the non-US fallback regulation for users in jurisdictions without a specific eToro entity. CySEC (1) is the primary EU regulation. None (0) is the sentinel for unassigned users. Grouping them under cluster 1 allows DWH analytics to treat these three as a single reporting unit.

```
ClusterRegulationID mapping:
  ID=0 (None)    -> Cluster 1
  ID=1 (CySEC)   -> Cluster 1
  ID=5 (BVI)     -> Cluster 1
  All others     -> Cluster = ID (FCA=2, NFA=3, ASIC=4, eToroUS=6, ...)
```

### 2.2 DWH Column Gaps vs Production

**What**: The DWH drops 6 production columns that are needed for full compliance analysis.

**Columns Dropped**:
- `IsUSA` - US/non-US jurisdiction flag (critical for instrument availability branching)
- `JurisdictionName` - eToro legal entity name (e.g., "eToro EU", "eToro UK")
- `BankID` - FK to Dictionary.Bank (custodian banking partner)
- `RegulationLongName` - Full formal name (e.g., "Cyprus Securities Exchange Commission")
- `RegulationShortName` - Abbreviated code for compact display
- `DefaultRegulationID` - Self-reference fallback (non-US->BVI, US->eToroUS)

**Impact**: DWH analytics that need US vs non-US split must either hardcode the IDs (6, 7, 8, 12, 14 are US) or join to the Bronze layer. See Section 3.4 Gotchas.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on ID. With 15 rows, REPLICATE is optimal. Join on ID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` is Parquet. Read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RegulationID to name in customer data | `LEFT JOIN DWH_dbo.Dim_Regulation r ON r.ID = cs.RegulationID` |
| Group analytics by regulation cluster | `GROUP BY r.ClusterRegulationID` |
| US vs non-US split (without IsUSA) | `WHERE r.ID IN (6, 7, 8, 12, 14)` for US; else non-US |
| Full customer record with regulation | Use `DWH_dbo.V_Dim_Customer` (pre-joins Dim_Regulation) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.CustomerStatic / V_Dim_Customer | ON r.ID = cs.RegulationID | Resolve regulation name per customer |
| DWH_dbo.V_Dim_Customer | Dim_Regulation already joined (INNER JOIN on RegulationID) | Use view instead of re-joining |

### 3.4 Gotchas

- **IsUSA not in DWH**: Production Dictionary.Regulation.IsUSA (US=1, non-US=0) is dropped by ETL. DWH analysts must hardcode: US regulations = IDs 6, 7, 8, 12, 14.
- **DWHRegulationID = ID**: These two columns always have the same value. DWHRegulationID is an ETL alias and appears redundant. Prefer ID for joins.
- **StatusID always 1**: Hardcoded Active for all rows. Not a meaningful filter.
- **Cluster 1 includes 3 regulations**: ClusterRegulationID=1 covers None (0), CySEC (1), and BVI (5). Aggregating by ClusterRegulationID will merge these three.
- **V_Dim_Customer uses INNER JOIN**: V_Dim_Customer has `INNER JOIN Dim_Regulation ON ID = RegulationID`. Customers with NULL RegulationID would be excluded.
- **Production has 6 more columns**: If you need IsUSA, JurisdictionName, or DefaultRegulationID, use the Bronze/staging layer or etoro.Dictionary.Regulation directly.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.Regulation)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in CustomerStatic.RegulationID. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 2 | Name | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 3 | DWHRegulationID | tinyint | YES | ETL-computed alias of ID - always equals ID. `[ID] as [DWHRegulationID]` in SP_Dictionaries_DL_To_Synapse. DWH-specific field not present in production. Use ID for joins. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded 1 (Active) for all rows by ETL (`1 as [StatusID]`). Not present in production Dictionary.Regulation. Not a meaningful filter. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Same value as UpdateDate since table is TRUNCATE+INSERTed daily. Not present in production. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | ClusterRegulationID | tinyint | YES | ETL-computed grouping: `CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END`. Groups None (0), CySEC (1), and BVI (5) into cluster 1. All other regulations map to their own ID. Used for analytics aggregation where BVI/CySEC/None are treated as a single reporting unit. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | etoro.Dictionary.Regulation | ID | passthrough |
| Name | etoro.Dictionary.Regulation | Name | passthrough |
| DWHRegulationID | - | - | ETL-computed: [ID] aliased as DWHRegulationID |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |
| ClusterRegulationID | - | - | ETL-computed: CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END |

**Lost from production** (dropped by ETL):

| Production Column | Type | Reason Dropped |
|-------------------|------|----------------|
| IsUSA | tinyint | Not carried to DWH; hardcode IDs 6,7,8,12,14 for US |
| JurisdictionName | varchar(30) | Not carried to DWH |
| BankID | int | Not carried to DWH |
| RegulationLongName | varchar(100) | Not carried to DWH |
| RegulationShortName | varchar(50) | Not carried to DWH |
| DefaultRegulationID | int | Not carried to DWH |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.Regulation.md (quality 9.2, 15 rows documented)

### 5.2 ETL Pipeline

```
etoro.Dictionary.Regulation -> Generic Pipeline -> DWH_staging.etoro_Dictionary_Regulation -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_Regulation
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Regulation | 15 current rows (IDs 0-14) |
| Staging | DWH_staging.etoro_Dictionary_Regulation | Raw import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds DWHRegulationID, StatusID, InsertDate, UpdateDate, ClusterRegulationID. Drops 6 production columns. |
| Target | DWH_dbo.Dim_Regulation | 15 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - production FKs (BankID, DefaultRegulationID) are dropped by ETL.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | ID (INNER JOIN on RegulationID) | Pre-joined customer view resolves regulation name |
| DWH_dbo.CustomerStatic | RegulationID | Every customer assigned a regulation at registration |

---

## 7. Sample Queries

### 7.1 List all regulations with cluster groupings
```sql
SELECT
    ID,
    Name,
    DWHRegulationID,
    ClusterRegulationID,
    StatusID
FROM [DWH_dbo].[Dim_Regulation]
ORDER BY ID
```

### 7.2 US vs non-US regulation breakdown
```sql
SELECT
    CASE WHEN ID IN (6, 7, 8, 12, 14) THEN 'US' ELSE 'Non-US' END AS Region,
    ID,
    Name
FROM [DWH_dbo].[Dim_Regulation]
WHERE ID > 0
ORDER BY Region, ID
```

### 7.3 Customer count by regulation cluster
```sql
SELECT
    r.ClusterRegulationID,
    r.Name AS PrimaryRegulationName,
    COUNT(DISTINCT cs.CustomerID) AS customer_count
FROM [DWH_dbo].[CustomerStatic] cs
LEFT JOIN [DWH_dbo].[Dim_Regulation] r ON r.ID = cs.RegulationID
GROUP BY r.ClusterRegulationID, r.Name
ORDER BY customer_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 2 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Regulation | Type: Table | Production Source: etoro.Dictionary.Regulation*


### Upstream `DWH_dbo.Dim_PlayerStatus` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerStatus`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md`

# DWH_dbo.Dim_PlayerStatus

> Permission matrix table defining 16 account restriction states (Normal through Block Deposit & Trading) that control which platform capabilities -- trading, deposits, withdrawals, login, social, and copy-trading -- are enabled for each customer.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PlayerStatus defines 16 distinct account restriction states in the eToro platform, each encoding a granular permission matrix controlling what a user can and cannot do. Unlike Dim_AccountStatus (binary open/closed), PlayerStatus provides fine-grained control over trading, deposits, withdrawals, social features, and copy-trading. This enables compliance and fraud teams to surgically restrict specific capabilities without full account lockout.

The data originates from `etoro.Dictionary.PlayerStatus` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override) to the data lake, and `SP_Dictionaries_DL_To_Synapse` loads it via TRUNCATE + INSERT, plus a separate sentinel INSERT for ID=0 (N/A placeholder). The ETL adds 4 computed columns (DWHPlayerStatusID, StatusID, UpdateDate, InsertDate) and **drops 2 production columns** (`CanCopy` and `GetsInterest`).

PlayerStatusID is stored in Dim_Customer and is read by virtually every user-facing operation -- login, trading, funding, social posting, and copy-trading -- to enforce permission checks. The permission flags are queried directly from this table rather than hardcoded in business logic.

---

## 2. Business Logic

### 2.1 Permission Matrix System

**What**: Each player status defines a complete set of boolean permissions that gate platform features.

**Columns Involved**: `IsBlocked`, `CanEditPosition`, `CanOpenPosition`, `CanClosePosition`, `CanDeposit`, `CanRequestWithdraw`, `CanLogin`, `CanChatAndPost`, `CanBeCopied`

**Rules**:
- **Full Block** (IsBlocked=1): IDs 2, 4, 6, 7, 8, 14 -- user cannot log in. All capabilities disabled.
- **Partial Restriction**: IDs 3, 9, 10, 11, 12, 13, 15 -- user can access some features but not others.
- **Full Access**: IDs 1, 5 -- all capabilities enabled. ID=5 (Warning) is identical to Normal in permissions but signals compliance flagging.
- **Close-Only / Wind-Down**: IDs 9 (Trade & MIMO Blocked) and 15 (Block Deposit & Trading) -- user can close existing positions and log in, but cannot open new positions or deposit.

**Diagram**:
```
Access Level Summary:
  ID=1  Normal                -- All capabilities ON
  ID=5  Warning               -- All ON + compliance flag
  ID=3  Chat Blocked          -- All ON except CanChatAndPost
  ID=10 Deposit Blocked       -- All ON except CanDeposit
  ID=12 Copy Block            -- All ON except CanBeCopied (note: DWH lacks CanCopy col)
  ID=9  Trade & MIMO Blocked  -- Close+Login only; no open/deposit/withdraw
  ID=13 Pending Verification  -- Close+Login only
  ID=15 Block Deposit&Trading -- Close+Login+Chat+Copy; no open/deposit
  ID=11 Social Index          -- All ON except CanDeposit + CanRequestWithdraw
  ID=2  Blocked               -- ALL OFF (full lockout, cannot login)
  ID=4  Blocked Upon Request  -- ALL OFF (self-requested lockout)
  ID=6  Under Investigation   -- ALL OFF (compliance hold)
  ID=7  Scalpers Block        -- ALL OFF (trading abuse)
  ID=8  PayPal Investigation  -- ALL OFF (payment fraud)
  ID=14 Failed Verification   -- ALL OFF (KYC failure)
  ID=0  N/A                   -- All OFF (DWH ETL placeholder)
```

### 2.2 Status Transition Patterns

**What**: Common pathways between player statuses driven by compliance, fraud, and user lifecycle events.

**Columns Involved**: `PlayerStatusID`

**Rules**:
- New accounts: 1 (Normal) or 13 (Pending Verification) depending on regulation
- Compliance investigation: 1 -> 6 (Under Investigation) -> 1 (cleared) or 2 (blocked)
- KYC timeout: 13 (Pending) -> 14 (Failed Verification) if docs not submitted
- Self-service closure: 1 -> 4 (Blocked Upon Request)
- Scalping detection: 1 -> 7 (Scalpers Block)
- PayPal fraud: 1 -> 8 (PayPal Investigation)
- Wind-down: 1 -> 9 or 15 (close-only mode for accounts under investigation)

### 2.3 Schema Drift -- Dropped Production Columns

**What**: Two production permission columns are not loaded into DWH.

**Dropped**:
- `CanCopy` (bit, default 1) -- whether user can copy other traders. Status 12 (Copy Block) sets this to 0.
- `GetsInterest` (bit) -- whether overnight fees/credits apply to user's positions. NOT available in DWH.

**Impact**: Analysts cannot determine from DWH whether a given status blocks copy-trading (CanCopy) or overnight interest (GetsInterest). For these, query production or the upstream wiki.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a HEAP index. HEAP means no CCI/sort -- for 16 rows this is irrelevant to performance, but row order is arbitrary without ORDER BY. Always join on `PlayerStatusID`. With REPLICATE, JOINs are zero-cost (all nodes have a full copy).

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed. Full scan of 16 rows is trivial.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve a PlayerStatusID to a name | JOIN Dim_PlayerStatus ON PlayerStatusID |
| Find customers who cannot trade | JOIN Dim_Customer, filter CanOpenPosition = 0 or IsBlocked = 1 |
| Count customers by restriction category | GROUP BY IsBlocked + CanOpenPosition combination |
| Find wind-down accounts (close-only) | Filter CanClosePosition = 1 AND CanOpenPosition = 0 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerStatusID = dps.PlayerStatusID | Resolve status name and permission flags per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerStatusID = dps.PlayerStatusID | View-level status resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerStatusID = dps.PlayerStatusID | Customer status in daily snapshots |

### 3.4 Gotchas

- **HEAP index**: Like Dim_PlayerLevel, this table uses HEAP. No guaranteed row order without ORDER BY.
- **ID=0 sentinel**: All permission bits are 0 for ID=0 (N/A). LEFT JOIN if the fact table may have NULL or missing PlayerStatusID.
- **CanCopy and GetsInterest are MISSING**: These two production columns are not in DWH. Analysts needing copy-block or interest-eligibility logic must use production data.
- **Status 5 (Warning) = same permissions as Status 1 (Normal)**: All permission flags are identical. The only difference is the compliance signal encoded in the ID itself.
- **Status names have trailing spaces**: Live data shows "Blocked" with trailing whitespace for some status names (e.g., Name column for ID=2). Apply RTRIM() in comparisons if matching by name string.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerStatusID | int | NO | Primary key identifying the restriction state. 0=N/A (sentinel), 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 11=Social Index, 12=Copy Block, 13=Pending Verification, 14=Failed Verification, 15=Block Deposit & Trading. FK from Dim_Customer. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 2 | Name | varchar(50) | NO | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 3 | IsBlocked | bit | NO | Master block flag. 1 for statuses 2, 4, 6, 7, 8, 14 -- ALL capabilities disabled including login. 0 for statuses where individual CanX flags control granular permissions. Checked by login and order entry procedures. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 4 | CanEditPosition | bit | YES | Whether the user can modify existing position parameters (SL/TP/trailing stop). False when IsBlocked=1 and for close-only statuses (9, 13, 15). (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 5 | CanOpenPosition | bit | YES | Whether the user can open new trading positions. False when IsBlocked=1 and for close-only statuses (9, 13, 15). True for all active/warning/partial statuses. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 6 | CanClosePosition | bit | YES | Whether the user can close existing positions. True even for most restricted statuses -- regulators require users to be able to exit. Only IsBlocked=1 statuses set this to False. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 7 | CanDeposit | bit | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only statuses (9, 15), status 10 (Deposit Blocked), and status 11 (Social Index). (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 8 | CanRequestWithdraw | bit | YES | Whether the user can request withdrawals. False for full-block statuses (IsBlocked=1), close-only statuses (9, 13, 15), and status 11 (Social Index). (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 9 | CanLogin | bit | YES | Whether the user can authenticate and access the platform. False when IsBlocked=1. True for all partial-restriction statuses -- wind-down users can view their portfolio. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 10 | CanChatAndPost | bit | YES | Whether the user can post to the social feed or chat. False when IsBlocked=1 and for status 3 (Chat Blocked). True for all other statuses including close-only. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 11 | CanBeCopied | bit | YES | Whether other users can start copying this user's trades. False when IsBlocked=1. Used to hide restricted users from the CopyTrader marketplace. Note: CanCopy (whether THIS user can copy others) is NOT loaded into DWH. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 12 | DWHPlayerStatusID | int | YES | DWH surrogate key -- always equals PlayerLevelID (redundant copy). Set by ETL: SELECT [PlayerStatusID] AS [DWHPlayerStatusID]. 0 for the ID=0 sentinel. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 13 | StatusID | int | YES | Hardcoded to 1 (active) for all rows by the ETL. Not derived from production source. Standard DWH ETL convention for SP_Dictionaries_DL_To_Synapse-loaded tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 14 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 15 | InsertDate | datetime | YES | ETL load timestamp -- GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel. Does not reflect production insert time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerStatusID | Dictionary.PlayerStatus | PlayerStatusID | passthrough |
| Name | Dictionary.PlayerStatus | Name | passthrough |
| IsBlocked | Dictionary.PlayerStatus | IsBlocked | passthrough |
| CanEditPosition | Dictionary.PlayerStatus | CanEditPosition | passthrough |
| CanOpenPosition | Dictionary.PlayerStatus | CanOpenPosition | passthrough |
| CanClosePosition | Dictionary.PlayerStatus | CanClosePosition | passthrough |
| CanDeposit | Dictionary.PlayerStatus | CanDeposit | passthrough |
| CanRequestWithdraw | Dictionary.PlayerStatus | CanRequestWithdraw | passthrough |
| CanLogin | Dictionary.PlayerStatus | CanLogin | passthrough |
| CanChatAndPost | Dictionary.PlayerStatus | CanChatAndPost | passthrough |
| CanBeCopied | Dictionary.PlayerStatus | CanBeCopied | passthrough |
| DWHPlayerStatusID | -- | -- | ETL-computed: = PlayerStatusID (redundant surrogate) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() or @ddate for ID=0 |
| InsertDate | -- | -- | ETL-computed: GETDATE() or @ddate for ID=0 |

**Dropped from production**: CanCopy (bit), GetsInterest (bit).

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerStatus.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerStatus
  -> Generic Pipeline (daily, Override)
  -> Bronze/etoro/Dictionary/PlayerStatus/
  -> DWH_staging.etoro_Dictionary_PlayerStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT + INSERT VALUES for ID=0)
  -> DWH_dbo.Dim_PlayerStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerStatus | 15 rows, 13 columns (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/PlayerStatus/ | Daily full export via Generic Pipeline |
| Staging | DWH_staging.etoro_Dictionary_PlayerStatus | 11 passthrough cols loaded |
| ETL step 1 | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; adds 4 computed cols; drops CanCopy, GetsInterest |
| ETL step 2 | SP_Dictionaries_DL_To_Synapse (line ~1568) | INSERT VALUES for ID=0 N/A sentinel with all-false permissions |
| Target | DWH_dbo.Dim_PlayerStatus | 16 rows (0-15), 15 cols, REPLICATE + HEAP |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerStatusID | Customer's current account restriction state |
| DWH_dbo.V_Dim_Customer | PlayerStatusID | View-level customer status |
| DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | Daily snapshot of customer restriction state |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerStatusID | Year-end snapshot status |

---

## 7. Sample Queries

### 7.1 List all statuses with key permission flags

```sql
SELECT PlayerStatusID,
       Name,
       IsBlocked,
       CanOpenPosition,
       CanClosePosition,
       CanDeposit,
       CanLogin
FROM   [DWH_dbo].[Dim_PlayerStatus]
WHERE  PlayerStatusID > 0
ORDER BY PlayerStatusID;
```

### 7.2 Count customers by restriction category

```sql
SELECT  CASE
            WHEN dps.IsBlocked = 1          THEN 'Full Block'
            WHEN dps.CanOpenPosition = 0    THEN 'Close-Only / Restricted'
            WHEN dps.CanDeposit = 0         THEN 'Deposit Blocked'
            ELSE 'Active'
        END               AS RestrictionCategory,
        dps.Name          AS PlayerStatus,
        COUNT(*)          AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatus] dps
        ON dc.PlayerStatusID = dps.PlayerStatusID
WHERE   dps.PlayerStatusID > 0
GROUP BY dps.IsBlocked, dps.CanOpenPosition, dps.CanDeposit, dps.Name
ORDER BY CustomerCount DESC;
```

### 7.3 Find customers in wind-down state (can close, cannot open)

```sql
SELECT  dc.CID,
        dps.Name   AS PlayerStatus
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatus] dps
        ON dc.PlayerStatusID = dps.PlayerStatusID
WHERE   dps.CanClosePosition = 1
        AND dps.CanOpenPosition = 0
        AND dps.PlayerStatusID > 0;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 9.0/10 (*****) | Phases: 11/14*
*Tiers: 11 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerStatus | Type: Table | Production Source: etoro.Dictionary.PlayerStatus*


### Upstream `DWH_dbo.Dim_PlayerLevel` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerLevel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md`

# DWH_dbo.Dim_PlayerLevel

> Lookup table defining the 7 eToro Club loyalty tiers (Bronze through Diamond plus Internal) with tier-specific cashout wait times and display sort order. NOTE: DWH drops the primary equity qualification thresholds (RealizedEquityFrom/To, DaysInRiskBeforeDowngrade) present in production.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerLevel |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PlayerLevel defines the eToro Club loyalty program tiers that segment customers by their realized equity (account value). Each tier grants progressively better benefits: faster cashout processing, higher service priority, and dedicated account management. The tiers in ascending rank are: Bronze -> Silver -> Gold -> Platinum -> Platinum Plus -> Diamond, plus a special Internal tier for employee/test accounts.

The data originates from `etoro.Dictionary.PlayerLevel` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/PlayerLevel/` in the data lake. Production has 7 active tier rows (IDs 1-7); DWH adds a synthetic ID=0 N/A placeholder.

**CRITICAL SCHEMA DRIFT**: The DWH ETL loads only 8 of the production's 13 columns. The following production columns are DROPPED and not available in DWH: `RealizedEquityFrom`, `RealizedEquityTo` (the primary tier qualification thresholds), `IsWalletRedeemAllowed`, `ThresholdPercentToCurrentLevel`, and `DaysInRiskBeforeDowngrade`. For tier qualification logic, query the upstream `etoro.Dictionary.PlayerLevel` directly or the upstream wiki. The DWH table is suitable only for resolving tier names and cashout hours -- not for equity-based tier evaluation.

Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from staging, followed by a separate INSERT VALUES for the ID=0 N/A sentinel using `@ddate` (midnight timestamp). Refreshes daily.

---

## 2. Business Logic

### 2.1 Tier Hierarchy and Rank Order

**What**: Six customer-facing loyalty tiers plus one internal tier, ranked by realized equity.

**Columns Involved**: `PlayerLevelID`, `Name`, `Sort`

**Rules**:
- IDs are NOT in rank order -- use `Sort` column for display ordering.
- Sort order: 0=Internal (excluded), 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond.
- Internal (ID=4) is excluded from customer-facing reports: `WHERE PlayerLevelID <> 4`.
- ID=0 (N/A) is a DWH-only ETL placeholder for NULL FK safety. Not in production.

**Diagram**:
```
Tier Hierarchy (by Sort/Rank):
  Sort 1 = Bronze     (ID=1) -- entry level
  Sort 2 = Silver     (ID=5)
  Sort 3 = Gold       (ID=3)
  Sort 4 = Platinum   (ID=2)
  Sort 5 = Platinum + (ID=6)
  Sort 6 = Diamond    (ID=7) -- top tier
  Sort 0 = Internal   (ID=4) -- excluded
  (ID=0  = N/A       -- DWH ETL placeholder)
```

### 2.2 Cashout Processing Speed by Tier

**What**: Higher tiers receive priority cashout processing as a loyalty benefit.

**Columns Involved**: `CashoutPendingHours`

**Rules**:
- **120 hours (5 days)**: Bronze (1), Silver (5), Internal (4), N/A (0)
- **72 hours (3 days)**: Gold (3)
- **24 hours (1 day)**: Platinum (2), Platinum Plus (6), Diamond (7)
- This is one of the most impactful benefits of upper tier membership.

### 2.3 Legacy Lot/Deposit Thresholds (Deprecated)

**What**: Historical tier qualification fields -- superseded by RealizedEquity (not in DWH).

**Columns Involved**: `FromSumLotCount`, `ToSumLotCount`, `FromSumDeposit`, `ToSumDeposit`

**Rules**:
- All set to `-1` for Platinum (2), Platinum Plus (6), Diamond (7) -- meaning "disabled/not applicable".
- Bronze (1) has 1-3000 lots, $0-$999 deposit; Silver (5) has 3001-20000 lots, $1000-$4999; Gold (3) has 20001-100000 lots, $5000-$19999.
- These columns are legacy artifacts. The current tier system uses `RealizedEquityFrom/To` which are NOT loaded into DWH.
- Value -1 = "threshold disabled -- upper tier, equity-based qualification only".

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a HEAP index. HEAP (no clustering) is unusual for dimension tables -- most Dim_ tables use CLUSTERED INDEX. With only 8 rows, HEAP is not a concern for performance but means scans are unordered. Always use `ORDER BY Sort` for consistent tier display.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`. With 8 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What tier is a customer in? | JOIN Dim_Customer ON PlayerLevelID for Name |
| Tier distribution of customer base | GROUP BY PlayerLevelID, exclude Internal (ID=4) |
| Display tiers in rank order | ORDER BY Sort ASC, exclude ID=0 and ID=4 |
| Cashout processing time for a tier | SELECT CashoutPendingHours WHERE PlayerLevelID = X |
| What are the equity thresholds? | NOT available in DWH -- use upstream wiki or prod data |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerLevelID = dpl.PlayerLevelID | Resolve tier name per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerLevelID = dpl.PlayerLevelID | View-level tier resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerLevelID = dpl.PlayerLevelID | Tier in daily snapshots |

### 3.4 Gotchas

- **IDs are NOT in rank order**: PlayerLevelID 2=Platinum, 3=Gold, 5=Silver. Always use `Sort` for ordering tiers. Filtering `PlayerLevelID > 3` does NOT mean "higher than Gold".
- **Internal tier (ID=4)**: Must be excluded in most customer analytics: `WHERE PlayerLevelID <> 4` or `WHERE PlayerLevelID NOT IN (0, 4)`.
- **-1 in range columns means disabled**: For Platinum/Platinum Plus/Diamond, FromSumLotCount=-1 and ToSumLotCount=-1 indicate the legacy lot-count threshold is not used. Do NOT interpret -1 as a valid lot count.
- **Critical columns missing from DWH**: `RealizedEquityFrom`, `RealizedEquityTo`, `DaysInRiskBeforeDowngrade`, `ThresholdPercentToCurrentLevel`, and `IsWalletRedeemAllowed` are ALL in production but NOT in DWH. For equity-tier evaluation, use the upstream source.
- **HEAP index**: Unlike most DWH Dim_ tables, this uses HEAP (no CCI). Row order is not guaranteed without explicit ORDER BY.
- **ID=0 midnight timestamp**: The N/A placeholder (ID=0) has midnight InsertDate/UpdateDate from `@ddate = CAST(GETDATE() AS DATE)`, while production rows have full timestamps from GETDATE().

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerLevelID | int | NO | Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort for ordering. FK from Dim_Customer. Excludes Internal in customer-facing queries: WHERE PlayerLevelID <> 4. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 2 | Name | varchar(50) | NO | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 3 | CashoutPendingHours | int | NO | Maximum hours a cashout request waits before processing. 24=1 day (Platinum/Platinum Plus/Diamond), 72=3 days (Gold), 120=5 days (Bronze/Silver/Internal). Key loyalty benefit -- higher tiers get faster withdrawals. 0 for N/A placeholder. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 4 | FromSumLotCount | int | NO | Legacy: minimum cumulative lot count for tier qualification. Set to -1 for upper tiers (Platinum/Platinum Plus/Diamond -- threshold disabled). Superseded by RealizedEquityFrom (not loaded in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 5 | ToSumLotCount | int | NO | Legacy: maximum cumulative lot count for tier qualification. Set to -1 for upper tiers (threshold disabled). Superseded by RealizedEquityTo (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 6 | FromSumDeposit | int | NO | Legacy: minimum cumulative deposit (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquityFrom (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 7 | ToSumDeposit | int | NO | Legacy: maximum cumulative deposit (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquityTo (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 8 | Sort | int | NO | Display order for tier hierarchy. 0=Internal/N/A, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Use ASC sort on this column for correct tier rank ordering. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 9 | DWHPlayerLevelID | int | NO | DWH surrogate key -- always equals PlayerLevelID (redundant copy). Set by ETL: SELECT [PlayerLevelID] AS [DWHPlayerLevelID]. 0 for ID=0 sentinel. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 10 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() for production rows; set to @ddate (midnight) for the ID=0 N/A sentinel. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 11 | InsertDate | datetime | NO | ETL load timestamp -- set to GETDATE() for production rows; set to @ddate (midnight) for the ID=0 N/A sentinel. Does not reflect production insert time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 12 | StatusID | tinyint | NO | Hardcoded to 1 (active) for all rows by the ETL. Not derived from production source. DWH ETL convention for dictionary tables loaded by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerLevelID | Dictionary.PlayerLevel | PlayerLevelID | passthrough |
| Name | Dictionary.PlayerLevel | Name | passthrough |
| CashoutPendingHours | Dictionary.PlayerLevel | CashoutPendingHours | passthrough |
| FromSumLotCount | Dictionary.PlayerLevel | FromSumLotCount | passthrough |
| ToSumLotCount | Dictionary.PlayerLevel | ToSumLotCount | passthrough |
| FromSumDeposit | Dictionary.PlayerLevel | FromSumDeposit | passthrough |
| ToSumDeposit | Dictionary.PlayerLevel | ToSumDeposit | passthrough |
| Sort | Dictionary.PlayerLevel | Sort | passthrough |
| DWHPlayerLevelID | -- | -- | ETL-computed: = PlayerLevelID (redundant surrogate) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() (or @ddate for ID=0 sentinel) |
| InsertDate | -- | -- | ETL-computed: GETDATE() (or @ddate for ID=0 sentinel) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |

**Dropped from production (schema drift)**: IsWalletRedeemAllowed, RealizedEquityFrom, RealizedEquityTo, ThresholdPercentToCurrentLevel, DaysInRiskBeforeDowngrade.

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerLevel.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerLevel
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerLevel/
  -> DWH_staging.etoro_Dictionary_PlayerLevel
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT + INSERT VALUES for ID=0)
  -> DWH_dbo.Dim_PlayerLevel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerLevel | Production tier dictionary (etoroDB-REAL) -- 13 cols, 7 rows |
| Lake | Bronze/etoro/Dictionary/PlayerLevel/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerLevel | Raw staging import -- 8 passthrough cols only |
| ETL step 1 | SP_Dictionaries_DL_To_Synapse (line ~931) | TRUNCATE + INSERT SELECT; adds 4 computed cols; drops 5 production cols |
| ETL step 2 | SP_Dictionaries_DL_To_Synapse (line ~1538) | INSERT VALUES for ID=0 N/A sentinel using @ddate (midnight) |
| Target | DWH_dbo.Dim_PlayerLevel | 8 rows, 12 cols, REPLICATE + HEAP |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerLevelID | Customer's current loyalty tier |
| DWH_dbo.V_Dim_Customer | PlayerLevelID | View exposing tier for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Daily snapshot of customer tier |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerLevelID | Year-end snapshot tier |

---

## 7. Sample Queries

### 7.1 List all tiers in rank order

```sql
SELECT PlayerLevelID,
       Name,
       Sort,
       CashoutPendingHours
FROM   [DWH_dbo].[Dim_PlayerLevel]
WHERE  PlayerLevelID NOT IN (0, 4)   -- exclude N/A and Internal
ORDER BY Sort ASC;
```

### 7.2 Count customers by tier (excluding internal)

```sql
SELECT  dpl.Name             AS Tier,
        dpl.Sort,
        COUNT(*)             AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerLevel] dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.PlayerLevelID NOT IN (0, 4)
GROUP BY dpl.Name, dpl.Sort
ORDER BY dpl.Sort;
```

### 7.3 Identify customers in premium tiers (24h cashout)

```sql
SELECT  dc.CID,
        dpl.Name  AS Tier,
        dpl.CashoutPendingHours
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerLevel] dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.CashoutPendingHours = 24   -- Platinum, Platinum Plus, Diamond
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 9.0/10 (*****) | Phases: 11/14*
*Tiers: 8 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerLevel | Type: Table | Production Source: etoro.Dictionary.PlayerLevel*


### Upstream `DWH_dbo.Dim_PhoneVerified` — synapse
- **Resolved as**: `DWH_dbo.Dim_PhoneVerified`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PhoneVerified.md`

# DWH_dbo.Dim_PhoneVerified

> Lookup table defining the 6 phone verification lifecycle states -- from NotVerified through AutomaticallyVerified, ManualyVerified (typo preserved from source), Initiated, Rejected, and AbuseFlag -- used in customer KYC tracking across DWH.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PhoneVerified |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PhoneVerifiedID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PhoneVerified is a 6-row dictionary defining the phone number verification lifecycle states used in eToro's KYC (Know Your Customer) process. Phone verification is a key identity check -- customers must prove ownership of their registered phone number to complete account verification and enable certain platform features. The states cover the full lifecycle: from not yet started (ID=0), through initiation (ID=3), to successful outcomes (IDs 1 and 2), to failed outcomes (ID=4) and abuse detection (ID=5).

The data originates from `etoro.Dictionary.PhoneVerified` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/PhoneVerified/` in the data lake, with UC Bronze table `general.bronze_etoro_dictionary_phoneverified`.

Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from `DWH_staging.etoro_Dictionary_PhoneVerified`. Refreshes daily. As of 2026-03-19, UpdateDate is 2026-03-11 -- 8 days stale, consistent with the schema-wide ETL freshness issue.

---

## 2. Business Logic

### 2.1 Phone Verification Lifecycle

**What**: Phone numbers move through 6 verification states from initial submission to final outcome.

**Columns Involved**: `PhoneVerifiedID`, `PhoneVerifiedName`

**Rules**:
- **ID=0 (NotVerified)** -- Default state. Customer's phone has not been verified. May restrict certain platform features.
- **ID=1 (AutomaticallyVerified)** -- Phone verified through automated SMS code or callback system. Highest-throughput path.
- **ID=2 (ManualyVerified)** -- Phone verified by a BackOffice agent who called the customer directly. Used when automated verification fails or for high-value customers. **Note: "ManualyVerified" contains a production typo (single 'l') -- preserved verbatim in DWH.**
- **ID=3 (Initiated)** -- Verification started (SMS sent / call placed) but customer has not yet completed it.
- **ID=4 (Rejected)** -- Verification attempt failed (wrong code, number unreachable, mismatch detected).
- **ID=5 (AbuseFlag)** -- Phone flagged for abuse: multiple accounts sharing one number, known fraud number, or manipulation detected. Triggers compliance investigation.

**Diagram**:
```
Phone Verification Lifecycle
  0 = NotVerified (default)
      |
      v (verification initiated)
  3 = Initiated (SMS sent / call placed)
      |
      +-- Success (auto)  --> 1 = AutomaticallyVerified
      +-- Success (manual) -> 2 = ManualyVerified (BO agent)
      +-- Fail            --> 4 = Rejected
      +-- Abuse detected  --> 5 = AbuseFlag
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `PhoneVerifiedID`. With only 6 rows, REPLICATE is optimal -- every compute node holds a full copy, making JOIN operations zero-shuffle-cost. Always join on `PhoneVerifiedID` as the integer key.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified`. With 6 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What does a PhoneVerifiedID mean? | JOIN Dim_PhoneVerified ON PhoneVerifiedID for the label |
| Count customers by phone verification state | GROUP BY with Dim_PhoneVerified for readable labels |
| Find customers with abuse-flagged phone numbers | Filter PhoneVerifiedID = 5 |
| Find customers not yet verified | Filter PhoneVerifiedID = 0 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PhoneVerifiedID = dpv.PhoneVerifiedID | Resolve phone verification label per customer |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PhoneVerifiedID = dpv.PhoneVerifiedID | Phone verification in daily snapshots |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | ON fsc.PhoneVerifiedID = dpv.PhoneVerifiedID | Year-end snapshot phone verification state |

### 3.4 Gotchas

- **Typo in production data**: `PhoneVerifiedName` for ID=2 is `"ManualyVerified"` (single 'l' -- missing second 'l'). This typo originates in the production database and is preserved in DWH. Do not correct it in queries or reporting unless explicitly instructed, as fixing it in the DWH would cause a mismatch with upstream.
- **ID=0 exists**: Unlike Dim_PendingClosureStatus, this table DOES have an ID=0 row (NotVerified). Standard INNER JOIN is safe.
- **Only 6 rows**: Pure enum lookup -- always load the full table, never filter by date.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PhoneVerified) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PhoneVerifiedID | int | NO | Primary key identifying the phone verification state. 0=NotVerified (default), 1=AutomaticallyVerified, 2=ManualyVerified (BO agent -- note production typo), 3=Initiated (in-progress), 4=Rejected (failed), 5=AbuseFlag (fraud detected). Stored in Dim_Customer. Referenced by 20+ procedures across BackOffice, Customer, SalesForce, and dbo schemas. (Tier 1 - upstream wiki, Dictionary.PhoneVerified) |
| 2 | PhoneVerifiedName | varchar(50) | NO | Human-readable verification state label. Note: ID=2 has value "ManualyVerified" -- a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Displayed in customer cards, verification reports, and compliance dashboards. (Tier 1 - upstream wiki, Dictionary.PhoneVerified) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PhoneVerifiedID | etoro.Dictionary.PhoneVerified | PhoneVerifiedID | passthrough |
| PhoneVerifiedName | etoro.Dictionary.PhoneVerified | PhoneVerifiedName | passthrough (typo preserved) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on each reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PhoneVerified.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PhoneVerified
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PhoneVerified/
  -> DWH_staging.etoro_Dictionary_PhoneVerified
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_PhoneVerified
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PhoneVerified | Production phone verification state dictionary (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/PhoneVerified/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PhoneVerified | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; UpdateDate overridden to GETDATE() |
| Target | DWH_dbo.Dim_PhoneVerified | 6-row enum lookup, REPLICATE distributed |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PhoneVerifiedID | Customer-level phone verification state |
| DWH_dbo.Fact_SnapshotCustomer | PhoneVerifiedID | Daily customer snapshot phone verification state |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PhoneVerifiedID | Year-end closed-account snapshot verification state |

---

## 7. Sample Queries

### 7.1 List all phone verification states

```sql
SELECT PhoneVerifiedID,
       PhoneVerifiedName
FROM   [DWH_dbo].[Dim_PhoneVerified]
ORDER BY PhoneVerifiedID;
```

### 7.2 Count customers by phone verification state

```sql
SELECT  dpv.PhoneVerifiedName,
        COUNT(*) AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PhoneVerified] dpv
        ON dc.PhoneVerifiedID = dpv.PhoneVerifiedID
GROUP BY dpv.PhoneVerifiedName
ORDER BY CustomerCount DESC;
```

### 7.3 Find customers with abuse-flagged or rejected phone numbers

```sql
SELECT  dc.CID,
        dpv.PhoneVerifiedName
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PhoneVerified] dpv
        ON dc.PhoneVerifiedID = dpv.PhoneVerifiedID
WHERE   dc.PhoneVerifiedID IN (4, 5);
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PhoneVerified | Type: Table | Production Source: etoro.Dictionary.PhoneVerified*


### Upstream `DWH_dbo.Dim_PlayerStatusReasons` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerStatusReasons`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md`

# DWH_dbo.Dim_PlayerStatusReasons

> Lookup table defining 44 reason codes explaining why a customer's account status was changed -- from compliance/AML actions and KYC failures to chargebacks, user-initiated closures, and administrative decisions.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerStatusReasons |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PlayerStatusReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` |
| **UC Format** | Delta |
| **UC Partitioned By** | None (44 rows) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PlayerStatusReasons is the first level of a two-tier reason classification hierarchy for account status changes. When an account is blocked, suspended, restricted, or closed, the system records both the new status (Dim_PlayerStatus) and the broad reason category for the change. This table provides that top-level category.

The 44 reason codes (IDs 0-43) span the full range of account status change triggers: compliance/AML investigations (IDs 6, 10, 11, 18), KYC failures (1, 2, 39), risk flags (4, 7, 14, 25, 34, 35), fraud/chargebacks (5, 23, 24, 30-32), user-initiated actions (3, 20, 21, 22), payment issues (13, 16, 17, 38), and administrative decisions (8, 9, 12, 19, 37, 40-43). ID=0 (None) is the default when no reason has been explicitly recorded.

This table works as a hierarchy with Dim_PlayerStatusSubReasons -- Reason gives the broad category (e.g., "Chargeback"), and SubReason provides granular detail (e.g., "ACH CHBK", "Credit Card CHBK"). Dim_Customer and Fact_SnapshotCustomer store both PlayerStatusReasonID and PlayerStatusSubReasonID for every customer.

Data originates from `etoro.Dictionary.PlayerStatusReasons` on etoroDB-REAL, exported daily via Generic Pipeline, then loaded from `DWH_staging.etoro_Dictionary_PlayerStatusReasons` by SP_Dictionaries_DL_To_Synapse using TRUNCATE + INSERT passthrough.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: Major groupings of the 44 account status change reasons.

**Columns Involved**: `PlayerStatusReasonID`, `Name`

**Rules**:
- **ID=0 (None)**: Default state -- no explicit reason recorded. Included in production table, not a DWH-only sentinel.
- **Compliance/AML** (6, 10, 11, 18): AML-Account Closed, AML, AML review, WCH match (World Check sanctions screening)
- **KYC/Verification** (1, 2, 27, 39): Failed Verification, Expired Document, Pending Docs, KYC
- **Risk/Fraud** (4, 7, 14, 15, 25, 34, 35): Risk, HRC (High Risk Country), Risk Check, 3rd Party, Abuse, Abusive Trading, Hacked Account
- **Chargebacks** (5, 23, 24, 30, 31, 32): Chargeback, ACH Chargeback, PWMB Chargeback, CheckoutChargeback, CheckoutRetrievel, CheckoutCaptureDecline
- **User-Initiated** (3, 20, 21, 22): CloseAccountByUser, Right to be forgotten (GDPR), Self-Service, By request
- **Payment Issues** (13, 16, 17, 38): Overpayment, PayPal Investigation, NOC/NOF/RFI, Deposits
- **Account Types** (26, 28, 29, 36): Affiliate Account, Employee Account, PI Account, Partners & PIs
- **Administrative** (8, 9, 12, 19, 37, 40, 42, 43): Underage, Deceased, Off Market Abuse, Other, CS management decision, Account Closed, Corporate, Gap
- **Regulatory** (33, 41): eToro Money Restriction, Tax (FATCA/CRS)

### 2.2 Reason-SubReason Hierarchy

**What**: Reasons are further refined by sub-reasons stored in Dim_PlayerStatusSubReasons.

**Columns Involved**: `PlayerStatusReasonID`

**Rules**:
- Not every reason is valid for every status -- BackOffice.PlayerStatusToReason governs valid status-to-reason combinations (production side).
- Not every sub-reason is valid for every reason -- BackOffice.PlayerStatusReasonToSubReason governs valid reason-to-subreason combinations (production side).
- Both PlayerStatusReasonID and PlayerStatusSubReasonID are stored together on Dim_Customer and Fact_SnapshotCustomer.
- ID=0 (None) is the default -- use `WHERE PlayerStatusReasonID > 0` to filter to customers with explicit status change reasons.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on PlayerStatusReasonID. With 44 rows, performance is never a concern. JOIN to Dim_Customer or Fact_SnapshotCustomer on PlayerStatusReasonID is straightforward.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`. With 44 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What reason was given for a blocked customer? | JOIN Dim_Customer ON PlayerStatusReasonID |
| Count customers blocked per reason | GROUP BY PlayerStatusReasonID on Fact_SnapshotCustomer |
| Filter to AML-related reasons only | WHERE PlayerStatusReasonID IN (6, 10, 11, 18) |
| Exclude "no reason" rows | WHERE PlayerStatusReasonID > 0 |
| What sub-reasons exist under a reason? | JOIN Dim_PlayerStatusSubReasons -- mapping in production BackOffice only |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | Resolve reason name per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | View-level reason resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | Reason in daily snapshots |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | ON fsccy.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | Reason in year-end snapshots |

### 3.4 Gotchas

- **Name is nullable**: Unlike most DWH dimension columns, `Name` is varchar(50) NULL. Handle NULL safely: `ISNULL(Name, 'Unknown')`.
- **ID=0 is a real production row (None)**: Unlike other Dim_ tables, there is no DWH-only ID=0 sentinel -- row 0 comes directly from production and means "no reason specified".
- **ETL staleness**: UpdateDate = 2026-03-11 for all rows (8+ days as of 2026-03-19) -- consistent with known SP_Dictionaries_DL_To_Synapse disruption across the schema.
- **Reason-SubReason mapping not in DWH**: The valid Reason->SubReason combinations are only in production BackOffice.PlayerStatusReasonToSubReason. DWH has both dimension tables but not the mapping table.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerStatusReasonID | int | NO | Primary key identifying the account status change reason. Range 0-43. 0=None (no reason -- real production row, not a DWH placeholder). FK used by Dim_Customer, Fact_SnapshotCustomer, V_Dim_Customer, and Fact_SnapshotCustomerCloseYear. Represents first-level classification in the Reason->SubReason hierarchy. (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| 2 | Name | varchar(50) | YES | Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views. (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() on each SP_Dictionaries_DL_To_Synapse run. Does not reflect production data modification time. All rows share the same timestamp per reload (2026-03-11 as of last load). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons | PlayerStatusReasonID | passthrough |
| Name | Dictionary.PlayerStatusReasons | Name | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerStatusReasons.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerStatusReasons
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerStatusReasons/
  -> DWH_staging.etoro_Dictionary_PlayerStatusReasons
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT)
  -> DWH_dbo.Dim_PlayerStatusReasons
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerStatusReasons | Production reason dictionary (etoroDB-REAL) -- 2 data cols + metadata, 44 rows |
| Lake | Bronze/etoro/Dictionary/PlayerStatusReasons/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerStatusReasons | Raw staging import -- passthrough cols |
| ETL | SP_Dictionaries_DL_To_Synapse (line ~999) | TRUNCATE + INSERT SELECT; UpdateDate=getdate() |
| Target | DWH_dbo.Dim_PlayerStatusReasons | 44 rows, 3 cols, REPLICATE + CLUSTERED INDEX |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerStatusReasonID | Customer's current status change reason |
| DWH_dbo.V_Dim_Customer | PlayerStatusReasonID | View exposing reason for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerStatusReasonID | Reason in daily customer snapshot |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerStatusReasonID | Reason in year-end customer snapshot |

---

## 7. Sample Queries

### 7.1 List all status change reasons

```sql
SELECT PlayerStatusReasonID,
       Name
FROM   [DWH_dbo].[Dim_PlayerStatusReasons]
ORDER BY PlayerStatusReasonID;
```

### 7.2 Count customers by status reason (excluding "no reason")

```sql
SELECT  dpsr.Name            AS StatusReason,
        COUNT(*)             AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusReasons] dpsr
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
WHERE   dc.PlayerStatusReasonID > 0
GROUP BY dpsr.Name
ORDER BY CustomerCount DESC;
```

### 7.3 Find all AML and compliance-blocked customers

```sql
SELECT  dc.CID,
        dpsr.Name  AS StatusReason
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusReasons] dpsr
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
WHERE   dc.PlayerStatusReasonID IN (6, 10, 11, 18)  -- AML variants + WCH match
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (Simple-Dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerStatusReasons | Type: Table | Production Source: etoro.Dictionary.PlayerStatusReasons*


### Upstream `DWH_dbo.Dim_PlayerStatusSubReasons` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerStatusSubReasons`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md`

# DWH_dbo.Dim_PlayerStatusSubReasons

> Lookup table defining 83 granular sub-reason codes for account status changes -- providing the second-level detail beneath Dim_PlayerStatusReasons, covering fraud types, chargeback sources, compliance investigations, AML triggers, and regulatory requirements.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerStatusSubReasons |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PlayerStatusSubReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` |
| **UC Format** | Delta |
| **UC Partitioned By** | None (83 rows) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PlayerStatusSubReasons provides the second level of detail for account status changes, working beneath Dim_PlayerStatusReasons. While the Reason gives the broad category (e.g., "Chargeback"), the SubReason gives the specific detail (e.g., "ACH CHBK", "Credit Card CHBK", "PayPal CHBK"). This two-level classification gives compliance, risk, and operations teams the granularity needed for investigation tracking and reporting.

The 83 sub-reasons (IDs 0-82) span: fraud types (Fraud, Fake docs, Attack, Affiliate Fraud, 3rd Party), verification failures (Failed Verification, POI/POA Required), chargeback sources (ACH CHBK, Credit Card CHBK, PayPal CHBK, PWMB CHBK -- 11 variants), screening results (Sanctions, PEP, WCH matches), AML triggers (Investigation, AML Trigger, SAR filed, Law enforcement request), regulatory (FATCA, CRS, W-8BEN, corporate LEI), and operational states (1st Warning, 2nd Warning, Vulnerable Client).

This table is always used together with Dim_PlayerStatusReasons -- both IDs are stored on Dim_Customer and Fact_SnapshotCustomer for every customer. ID=0 (None) is the default when no specific sub-reason has been recorded.

**COLUMN RENAME**: Production column `Name` is renamed to `PlayerStatusSubReasonName` in DWH. All other columns are passthrough.

**ALL COLUMNS NULLABLE**: Unlike Dim_PlayerStatusReasons, all 3 DWH columns (including the PK PlayerStatusSubReasonID) are defined as NULL in the DDL. This is structurally unusual.

Data originates from `etoro.Dictionary.PlayerStatusSubReasons` on etoroDB-REAL, exported daily via Generic Pipeline, then loaded from `DWH_staging.etoro_Dictionary_PlayerStatusSubReasons` by SP_Dictionaries_DL_To_Synapse using TRUNCATE + INSERT with a Name -> PlayerStatusSubReasonName rename.

---

## 2. Business Logic

### 2.1 Sub-Reason Categories

**What**: Major groupings of the 83 sub-reasons.

**Columns Involved**: `PlayerStatusSubReasonID`, `PlayerStatusSubReasonName`

**Rules**:
- **ID=0 (None)**: Default -- no specific sub-reason recorded. Comes from production (not a DWH-only placeholder).
- **Fraud/Abuse** (1-6, 49, 64-65): Fraud, Fake docs, Attack, Affiliate Fraud, 3rd Party, Lost Funds, 3rd Party Trading, Market Abuse, Affiliate Abuse
- **Verification** (7, 24-26, 59, 61, 81-82): Failed Verification, Closed Verification, Selfie, Expired POI/POA, Pending Docs, 15-Day Failure, POI Required, POA Required
- **Chargeback Sources** (35-45): ACH CHBK, Credit Card CHBK, PayPal CHBK, PWMB CHBK, Other MOP CHBK, 3rd Party CHBK, CO Logic CHBK, Currency Difference CHBK, Fraud CHBK, Risk Refunded CHBK, Service/Complaint CHBK
- **Screening** (13-16, 31-34): WCH negative results, Sanctions, PEP Failed Verification, Possible Match (old and new naming)
- **AML/Investigation** (17-21, 73-74): Investigation, Cross Border, AML Trigger, Business Method, Mixed Funds, SAR Filed, Law Enforcement Request
- **Deposit-Related** (22-23, 29, 46-48, 53, 69, 78-79): FTD, Redeposit, PWMB Failed Deposit, 3rd Party FTD/Business MOP/Redeposit, ACH Failed Deposit, Preapproved Monitoring, Failed Min FTD, Failed Deposit
- **Warnings** (62-63): 1st Warning, 2nd Warning/Termination
- **Account Types** (54-58): Affiliate Account, Affiliate Re-linked, Affiliate Terminated, PI 2nd Account, PI Account
- **Regulatory** (60, 66-68, 70-72, 76): Corp Expired LEI, FATCA, CRS, FATCA0013, Corporate LEI issues, Corporate/SMSF Pending Docs, W-8BEN
- **Other** (8-12, 50-52, 75, 77, 80): Service/technical issues, Risk Refunded, Currency Differences, CO Logic, No Triggers, PayPal Investigation, Risk Check, Low Risk, Vulnerable Client, Negative Balance, UAE PASS Reactivation

**Abbreviation Glossary**: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, LEI=Legal Entity Identifier, PEP=Politically Exposed Person, SAR=Suspicious Activity Report, WCH=World Check, CRS=Common Reporting Standard, FATCA=Foreign Account Tax Compliance Act.

### 2.2 Reason-SubReason Hierarchy

**What**: Sub-reasons are always paired with a parent reason.

**Columns Involved**: `PlayerStatusSubReasonID`

**Rules**:
- Used alongside PlayerStatusReasonID -- both are stored on Dim_Customer.
- In production, valid Reason->SubReason combinations are governed by BackOffice.PlayerStatusReasonToSubReason (not replicated to DWH).
- ID=0 (None) as sub-reason typically accompanies ID=0 (None) as reason -- meaning neither level has been explicitly set.
- Use `WHERE PlayerStatusSubReasonID > 0` to filter to customers with explicit sub-reason classifications.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on PlayerStatusSubReasonID. With 83 rows, performance is never a concern. All columns are nullable -- apply ISNULL() defensively.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`. With 83 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What sub-reason for a customer? | JOIN Dim_Customer ON PlayerStatusSubReasonID |
| Find all chargeback sub-reasons | WHERE PlayerStatusSubReasonName LIKE '%CHBK%' |
| Count customers by sub-reason | GROUP BY PlayerStatusSubReasonID on Fact_SnapshotCustomer |
| Exclude "no sub-reason" rows | WHERE PlayerStatusSubReasonID > 0 |
| Combine with parent reason | JOIN BOTH Dim_PlayerStatusReasons AND Dim_PlayerStatusSubReasons |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | Resolve sub-reason per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | View-level sub-reason resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | Sub-reason in daily snapshots |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | ON fsccy.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | Sub-reason in year-end snapshots |

### 3.4 Gotchas

- **Column rename**: Production `Name` -> DWH `PlayerStatusSubReasonName`. Do NOT query for `Name` in DWH; the column does not exist.
- **ALL columns nullable**: PlayerStatusSubReasonID itself is defined as NULL in the DDL (unusual for a PK). Handle potential NULLs defensively even on the ID column.
- **ID=0 is a real production row**: Row 0 (None) comes from production -- not a DWH-only ETL placeholder.
- **CHBK abbreviation**: All chargeback sub-reasons use the abbreviation "CHBK" not "Chargeback". Filter with LIKE '%CHBK%' to find them.
- **ETL staleness**: UpdateDate = 2026-03-11 (8+ days stale as of 2026-03-19) -- consistent with schema-wide SP_Dictionaries_DL_To_Synapse disruption.
- **Reason-SubReason mapping not in DWH**: The valid Reason->SubReason combination table (BackOffice.PlayerStatusReasonToSubReason) is only in production. DWH does not replicate it.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerStatusSubReasonID | int | YES | Primary key identifying the granular sub-reason (NOTE: DDL allows NULL -- unusual for a PK). Range 0-82. 0=None (real production row, not DWH placeholder). FK used by Dim_Customer, Fact_SnapshotCustomer, V_Dim_Customer, and Fact_SnapshotCustomerCloseYear. Provides second-level detail beneath PlayerStatusReasonID. (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| 2 | PlayerStatusSubReasonName | varchar(50) | YES | Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75). (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() on each SP_Dictionaries_DL_To_Synapse run. Does not reflect production data modification time. All rows share same timestamp per reload (2026-03-11 as of last load). Also nullable in DWH DDL. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | PlayerStatusSubReasonID | passthrough |
| PlayerStatusSubReasonName | Dictionary.PlayerStatusSubReasons | Name | rename (Name -> PlayerStatusSubReasonName) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerStatusSubReasons.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerStatusSubReasons
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerStatusSubReasons/
  -> DWH_staging.etoro_Dictionary_PlayerStatusSubReasons
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT, Name -> PlayerStatusSubReasonName)
  -> DWH_dbo.Dim_PlayerStatusSubReasons
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerStatusSubReasons | Production sub-reason dictionary (etoroDB-REAL) -- 2 data cols, 83 rows |
| Lake | Bronze/etoro/Dictionary/PlayerStatusSubReasons/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerStatusSubReasons | Raw staging import -- Name col stored as `Name` |
| ETL | SP_Dictionaries_DL_To_Synapse (line ~1015) | TRUNCATE + INSERT SELECT; Name -> PlayerStatusSubReasonName rename; UpdateDate=getdate() |
| Target | DWH_dbo.Dim_PlayerStatusSubReasons | 83 rows, 3 cols, REPLICATE + CLUSTERED INDEX |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerStatusSubReasonID | Customer's current status change sub-reason |
| DWH_dbo.V_Dim_Customer | PlayerStatusSubReasonID | View exposing sub-reason for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerStatusSubReasonID | Sub-reason in daily customer snapshot |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerStatusSubReasonID | Sub-reason in year-end customer snapshot |

---

## 7. Sample Queries

### 7.1 List all chargeback sub-reasons

```sql
SELECT PlayerStatusSubReasonID,
       PlayerStatusSubReasonName
FROM   [DWH_dbo].[Dim_PlayerStatusSubReasons]
WHERE  PlayerStatusSubReasonName LIKE '%CHBK%'
ORDER BY PlayerStatusSubReasonID;
```

### 7.2 Count customers by sub-reason (excluding none)

```sql
SELECT  dpssr.PlayerStatusSubReasonName  AS SubReason,
        COUNT(*)                          AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusSubReasons] dpssr
        ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
WHERE   dc.PlayerStatusSubReasonID > 0
GROUP BY dpssr.PlayerStatusSubReasonName
ORDER BY CustomerCount DESC;
```

### 7.3 Full reason + sub-reason for each customer

```sql
SELECT  dc.CID,
        dpsr.Name                         AS Reason,
        dpssr.PlayerStatusSubReasonName   AS SubReason
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusReasons] dpsr
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
JOIN    [DWH_dbo].[Dim_PlayerStatusSubReasons] dpssr
        ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
WHERE   dc.PlayerStatusReasonID > 0
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (Simple-Dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerStatusSubReasons | Type: Table | Production Source: etoro.Dictionary.PlayerStatusSubReasons*


### Upstream `DWH_dbo.Dim_EvMatchStatus` — synapse
- **Resolved as**: `DWH_dbo.Dim_EvMatchStatus`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_EvMatchStatus.md`

# DWH_dbo.Dim_EvMatchStatus

> Identity verification match status dimension - maps numeric status codes to descriptive labels for the eToro EV (eVerification) identity matching process.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB.Dictionary.EvMatchStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (EvMatchStatusID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_EvMatchStatus` is a small dictionary table (4 rows) mapping integer codes to human-readable labels for the EV (eVerification) identity matching process. "EV" refers to the automated document/identity verification matching pipeline used by eToro to satisfy KYC (Know Your Customer) regulatory requirements. The four statuses indicate whether a customer's identity documents have been matched against a verification provider: 0=None (no match attempted), 1=PartiallyVerified, 2=Verified, 3=NotVerified.

The data originates from `UserApiDB.Dictionary.EvMatchStatus` on the `UserApiDB-REAL` production server. UserApiDB is the eToro user/customer API backend database. The Generic Pipeline does not appear to export this specific dictionary table to the Bronze lake directly; instead, the DWH staging table `DWH_staging.UserApiDB_Dictionary_EvMatchStatus` is loaded via a separate mechanism, then consumed by `SP_Dictionaries_DL_To_Synapse`.

`SP_Dictionaries_DL_To_Synapse` runs the ETL: TRUNCATE `Dim_EvMatchStatus`, then INSERT from staging. `UpdateDate` is set to `GETDATE()` at load time. The table was last refreshed on 2026-03-11 (as of batch execution date), which is consistent with a known SP_Dictionaries staleness issue (~7 days behind schedule as of 2026-03-19).

---

## 2. Business Logic

### 2.1 EV Match Status Values

**What**: The four-state identity verification matching outcome for a customer account.

**Columns Involved**: `EvMatchStatusID`, `EvMatchStatusName`

**Rules**:
- ID 0 = None: No EV match has been attempted. New or pre-KYC customers.
- ID 1 = PartiallyVerified: EV match ran but produced partial results. Some identity attributes matched, others did not.
- ID 2 = Verified: Full EV match passed. Customer identity confirmed against the verification provider.
- ID 3 = NotVerified: EV match ran but identity could not be confirmed.

**Diagram**:
```
Customer registration
        |
        v
   [None (0)] --- EV process triggered --> [PartiallyVerified (1)]
                                                    |
                                           +--------+--------+
                                           |                 |
                                    [Verified (2)]   [NotVerified (3)]
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed (4 rows - ideal for replication). The CLUSTERED INDEX on `EvMatchStatusID` supports efficient point lookups. Since the table is replicated across all nodes, joins from large fact tables (`Fact_SnapshotCustomer`, `Dim_Customer`) incur no data movement.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is exported to `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus` (Gold layer). With only 4 rows, no partitioning or Z-ORDER is needed. Broadcast join is automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode EvMatchStatusID in a customer query | `LEFT JOIN DWH_dbo.Dim_EvMatchStatus ON EvMatchStatusID` |
| Count customers by verification status | `GROUP BY ev.EvMatchStatusName` after joining to Dim_Customer |
| Find fully verified customers | `WHERE EvMatchStatusID = 2` (Verified) |
| Find customers not yet verified | `WHERE EvMatchStatusID IN (0, 3)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Customer.EvMatchStatusID = Dim_EvMatchStatus.EvMatchStatusID | Decode EV match status on customer records |
| DWH_dbo.Fact_SnapshotCustomer | ON Fact_SnapshotCustomer.EvMatchStatusID = Dim_EvMatchStatus.EvMatchStatusID | Decode EV status in daily customer snapshots |

### 3.4 Gotchas

- **ID=0 exists in production data** (unlike many other DWH Dim tables that use ID=0 as an ETL placeholder with N/A). The 0=None value represents customers who have not undergone the EV process.
- **Only 4 rows** - if a JOIN returns NULLs for the status name, the source `EvMatchStatusID` value is not in this dimension (data quality issue upstream, not a new status value).
- **Staleness**: UpdateDate reflects the SP_Dictionaries run time, not the production data change time. As of 2026-03-19 this table is ~8 days stale.
- **No ID=0 placeholder insert** in SP_Dictionaries for this table - the 0 value comes directly from production data.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| **** | Tier 1 | Upstream wiki verbatim (no upstream wiki found for UserApiDB) |
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | EvMatchStatusID | int | YES | Primary key. Integer code identifying the EV (eVerification) identity match status. Values: 0=None, 1=PartiallyVerified, 2=Verified, 3=NotVerified. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 | EvMatchStatusName | varchar(30) | YES | Human-readable label for the EV match status. Renamed from `Name` in the production source. Values: None, PartiallyVerified, Verified, NotVerified. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. Does not reflect production source update time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| EvMatchStatusID | UserApiDB.Dictionary.EvMatchStatus | EvMatchStatusId | None (passthrough, case rename only: Id->ID) |
| EvMatchStatusName | UserApiDB.Dictionary.EvMatchStatus | Name | Rename: Name -> EvMatchStatusName |
| UpdateDate | — | — | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
UserApiDB.Dictionary.EvMatchStatus -> Staging pipeline -> DWH_staging.UserApiDB_Dictionary_EvMatchStatus -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_EvMatchStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | UserApiDB.Dictionary.EvMatchStatus | EV match status dictionary on UserApiDB-REAL production server |
| Staging | DWH_staging.UserApiDB_Dictionary_EvMatchStatus | Raw import (EvMatchStatusId, Name). HEAP/ROUND_ROBIN. |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames Name->EvMatchStatusName. Adds UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_EvMatchStatus | 4-row REPLICATE dictionary. Daily refresh. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | — | No foreign key references to other DWH objects. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | EvMatchStatusID | Customer's current EV identity match status |
| DWH_dbo.Fact_SnapshotCustomer | EvMatchStatusID | Daily snapshot of customer's EV match status |
| DWH_dbo.V_Dim_Customer | EvMatchStatusID | Customer view including EV status |

---

## 7. Sample Queries

### 7.1 Count customers by EV verification status

```sql
SELECT
    ev.EvMatchStatusName,
    COUNT(*) AS CustomerCount
FROM DWH_dbo.Dim_Customer c
LEFT JOIN DWH_dbo.Dim_EvMatchStatus ev ON c.EvMatchStatusID = ev.EvMatchStatusID
GROUP BY ev.EvMatchStatusName
ORDER BY CustomerCount DESC
```

### 7.2 Find fully verified customers

```sql
SELECT c.CID, c.RegistrationDate
FROM DWH_dbo.Dim_Customer c
WHERE c.EvMatchStatusID = 2  -- Verified
```

### 7.3 Daily snapshot with decoded EV status

```sql
SELECT
    s.SnapshotDate,
    ev.EvMatchStatusName,
    COUNT(*) AS CustomerCount
FROM DWH_dbo.Fact_SnapshotCustomer s
LEFT JOIN DWH_dbo.Dim_EvMatchStatus ev ON s.EvMatchStatusID = ev.EvMatchStatusID
WHERE s.SnapshotDate >= '2026-01-01'
GROUP BY s.SnapshotDate, ev.EvMatchStatusName
ORDER BY s.SnapshotDate, ev.EvMatchStatusName
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.8/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_EvMatchStatus | Type: Table | Production Source: UserApiDB.Dictionary.EvMatchStatus*


### Upstream `eMoney_dbo.eMoney_Dim_Account` — synapse
- **Resolved as**: `eMoney_dbo.eMoney_Dim_Account`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md`

# eMoney_dbo.eMoney_Dim_Account

> One row per eToro Money fiat currency balance, consolidating currency-balance identity, customer DWH enrichment, bank account and card details, account program history, and change-detection flags from FiatDwhDB and DWH_dbo sources. 2,034,012 rows; currency balances created 2020-11-09 to 2026-04-13; refreshed daily via DELETE + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dimension) |
| **Production Source** | FiatDwhDB (eToro Money fiat platform DWH) via SP_eMoney_Dim_Account |
| **Refresh** | Daily DELETE + INSERT (Step 3 of SP_eMoney_Execute_Group_One; @Date = yesterday) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CurrencyBalanceID ASC); NCI (CID ASC) |
| **Row Count** | 2,034,012 (sampled 2026-04-13) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dim_Account` is the central account dimension for eToro Money (eTM), the fiat banking product. Each row represents one **currency balance** — the fundamental money-holding unit in the fiat platform. A single customer (GCID) can have multiple currency balances (e.g., EUR and GBP), so this table is at currency-balance grain, not customer grain.

The table consolidates three layers of data:
1. **FiatDwhDB identity** — currency balance, fiat account, bank account, card, and current status fields sourced from FiatDwhDB tables (FiatCurrencyBalances, FiatAccount, FiatBankAccount, FiatCards, FiatCardStatuses, FiatAccountStatuses, FiatAccountsProperties, FiatCurrencyBalancesStatuses)
2. **DWH customer enrichment** — club, regulation, country, and player status attributes from DWH_dbo.Dim_Customer and registration-time snapshots from Fact_SnapshotCustomer, joined via GCID
3. **DWH-computed fields** — IsValidETM composite flag, change-detection flags, seniority months, entity mapping

The ETL SP (`SP_eMoney_Dim_Account`) runs daily in an 11-step pipeline. It builds temp tables for each source cluster, filters to the primary currency balance per GCID (`GCID_Unique_Count=1`) for DWH enrichment joins, then performs a full DELETE + INSERT. Rows with `GCID_Unique_Count > 1` are secondary accounts and will have NULL customer attributes (CID, ClubID, RegulationID, etc.).

**Entity distribution** (2026-04-13): Malta 66.6%, UK 31.4%, AUS 2.0%.
**Account program distribution**: IBAN 95.3%, card 4.7%.
**Note on GCID=0**: Cancelled accounts are recorded with GCID=0; `IsCancelledAccount` = 1 for these rows.

---

## 2. Business Logic

### 2.1 Currency Balance Grain

**What**: The table is at currency-balance grain, not customer grain. One GCID can appear on multiple rows (one per currency balance / account type).

**Columns Involved**: `CurrencyBalanceID`, `AccountID`, `GCID`, `GCID_Unique_Count`

**Rules**:
- `CurrencyBalanceID` = `FiatCurrencyBalances.Id` — the primary key of this table's logical entity
- `AccountID` = `FiatAccount.Id` — one account can hold multiple currency balances
- `GCID_Unique_Count` = `ROW_NUMBER() PARTITION BY GCID ORDER BY AccountCreateTime DESC` — rank 1 = most recently created eMoney account for this customer
- Customer enrichment (CID, ClubID, RegulationID, etc.) is populated only for rows with `GCID_Unique_Count = 1`; secondary accounts have NULL for all DWH customer attributes

### 2.2 Primary Account Identification (GCID_Unique_Count=1 Rule)

**What**: DWH customer attributes are only available for the primary eMoney account per customer.

**Columns Involved**: `GCID_Unique_Count`, `CID`, `ClubID`, `RegulationID`, `CountryID`, `PlayerStatusID`, and all `Reg*` snapshot columns

**Rules**:
- Only rows where `GCID_Unique_Count = 1` are joined to `DWH_dbo.Dim_Customer` and `Fact_SnapshotCustomer`
- Rows with `GCID_Unique_Count > 1` have NULL in all customer-DWH enrichment columns
- `GCID_Unique_Count` itself is always populated (not NULL) — it indicates rank, not count
- Use `WHERE GCID_Unique_Count = 1` when joining to trading-side CID-based analysis

### 2.3 Current vs Registration-Time Attributes

**What**: The table captures two time points for club, regulation, country, player status, and account program: the current state and the state at eMoney account creation.

**Columns Involved**: `ClubID`/`RegClubID`, `RegulationID`/`RegRegulationID`, `CountryID`/`RegCountryID`, `PlayerStatusID`/`RegPlayerStatusID`, `AccountProgramID`/`RegAccountProgramID`, `AccountSubProgramID`/`RegAccountSubProgramID`

**Rules**:
- `Reg*` columns come from `Fact_SnapshotCustomer` joined at the `AccountCreateDateID` range — they represent the customer's attributes at the time they opened their eMoney account
- Current columns (no prefix) come from current `Dim_Customer` values
- Change flags (`HasClubChanged`, `HasRegulationChanged`, etc.) are 1 when the corresponding current and reg values differ

### 2.4 IsValidETM Composite Flag

**What**: Composite flag combining trading-side validity, test account exclusion, and cancelled account exclusion.

**Columns Involved**: `IsValidETM`, `IsValidCustomer`, `IsTestAccount`, `IsCancelledAccount`

**Rules**:
- `IsValidETM = 1` when ALL three conditions hold: `IsValidCustomer=1`, `IsTestAccount=0`, `IsCancelledAccount=0`
- `IsValidCustomer` is sourced from `Dim_Customer` (excludes Popular Investors, label 30/26 accounts, and CountryID=250)
- `IsTestAccount=1` when GCID appears in the Fivetran Google Sheets test-user list (`eMoney_google_sheets.emoney_test_users`)
- `IsCancelledAccount=1` when `GCID=0` (cancelled accounts stored with a zero GCID)
- Use `IsValidETM = 1` as the standard filter for production eMoney analytics

### 2.5 Account Program and Sub-Program (Current vs Registration)

**What**: The `AccountProgramID`/`AccountSubProgramID` reflect the customer's current program; the `RegAccountProgramID`/`RegAccountSubProgramID` reflect what was assigned at account creation.

**Columns Involved**: `AccountProgramID`, `AccountSubProgramID`, `RegAccountProgramID`, `RegAccountSubProgramID`, `CountAccountProgramChanges`, `CountAccountSubProgramChanges`

**Rules**:
- Current program: `ISNULL(latest FiatAccountsProperties record, original FiatAccount value)` — ensures latest program change is reflected
- `CountAccountProgramChanges`: number of distinct program values seen; set to 0 if the count was ≤1 (i.e., never changed; 0 = never changed, N≥2 = changed N times)
- Sub-programs (16 active: 1=Card Premium UK through 16=IBAN Black DKK) map region and tier

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is distributed on `HASH(CID)`. Most analytics joins are `CID`-based (eToro trading platform joins), so shuffle is minimized. However, `CurrencyBalanceID` is the clustered index key, making point lookups by currency balance ID efficient.

The NCI on `CID` speeds up `WHERE CID = N` predicates common in user-level queries.

**Note**: For eMoney-only analysis (without trading-side JOIN), consider joining on `GCID` — but GCID is not the distribution key, so cross-joins will cause data movement. Filter to `GCID_Unique_Count = 1` first to reduce scan size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| eTM KPIs by entity/club/regulation | Filter `IsValidETM=1 AND GCID_Unique_Count=1`, GROUP BY Entity, RegulationID, ClubID |
| Account program distribution | GROUP BY AccountProgram WHERE GCID_Unique_Count=1 |
| Customers with card | WHERE HasCard=1 AND GCID_Unique_Count=1 |
| AUS entity onboarding funnel | WHERE Entity='AUS', filter by AccountCreateDate range |
| Regulation migrations | WHERE HasRegulationChanged=1 AND RegulationID <> RegRegulationID |
| UK IBAN holders | WHERE Entity='UK' AND AccountProgramID=2 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON da.CID = dc.RealCID | Full trading profile for eTM customer |
| eMoney_dbo.eMoney_Dim_Transaction | ON da.CID = dt.CID | Transaction history for this account |
| eMoney_dbo.eMoney_Fact_Transaction_Status | ON da.CID = fts.CID | All transaction status events |
| eMoney_dbo.eMoneyClientBalance | ON da.CurrencyBalanceID = cb.CurrencyBalanceID | Daily balance reconciliation |
| DWH_dbo.Dim_Country | ON da.CountryID = c.CountryID | Country name/region lookup |
| DWH_dbo.Dim_Regulation | ON da.RegulationID = r.DWHRegulationID | Regulation name |

### 3.4 Gotchas

- **GCID_Unique_Count > 1 rows have NULL customer attributes**: Joining without filtering GCID_Unique_Count=1 will cause inflated counts and NULL-rich result sets.
- **GCID=0 rows**: Cancelled accounts appear with GCID=0. Use `IsCancelledAccount=0` to exclude them.
- **CID is NULL for secondary accounts**: `CID` is NULL when GCID_Unique_Count > 1; cannot use CID for cross-table JOINs on those rows.
- **UpdateDate = GETDATE() at INSERT time**: Not a business timestamp; it marks when the daily refresh ran.
- **BankAccountIBAN, BankAccountNumber, BankAccountName** are PII fields — masked in analytics environments (Synapse DDM enforced at FiatDwhDB source; may be masked in UC gold copy too).
- **NULL bank account fields**: Card-program accounts have no bank account linkage; BankAccountID and all BankAccount* columns will be NULL.
- **NULL card fields**: IBAN-only accounts may have HasCard=0 and NULL card columns.
- **TP_FTDDate sentinel**: Dim_Customer.FirstDepositDate defaults to '19000101' for non-depositors; TP_FTDDate will reflect that sentinel value (cast to date).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (FiatDwhDB or DWH_dbo) |
| Tier 2 | Description written from ETL SP code analysis (SP_eMoney_Dim_Account) |
| Tier 3 | Description inferred from column name and surrounding context |
| Tier 4 | Best available — limited evidence |
| Tier 5 | Name only — no description available |

### 4.1 Currency Balance Identity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CurrencyBalanceID | int | YES | Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. (Tier 1 — dbo.FiatCurrencyBalances) |
| 2 | AccountID | int | YES | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. (Tier 1 — dbo.FiatAccount) |
| 3 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |

### 4.2 DWH Customer Enrichment (Primary Account Only)

*Columns 4–19 are populated only for rows where `GCID_Unique_Count = 1`. NULL for secondary accounts.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 4 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | ClubID | int | YES | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard; 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. Renamed from PlayerLevelID. (Tier 1 — Customer.CustomerStatic) |
| 6 | Club | varchar(50) | YES | Player level display name resolved from DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_eMoney_Dim_Account) |
| 7 | ClubCategory | varchar(50) | YES | Grouped player level bucket. NoClub=PlayerLevelID 1; LowClub=3 or 5; HighClub=2, 6, or 7; Internal=4; Error=unmapped values. (Tier 2 — SP_eMoney_Dim_Account) |
| 8 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 — BackOffice.Customer) |
| 9 | Regulation | varchar(50) | YES | Regulation display name resolved from DWH_dbo.Dim_Regulation. (Tier 2 — SP_eMoney_Dim_Account) |
| 10 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 11 | Country | varchar(50) | YES | Country display name resolved from DWH_dbo.Dim_Country. (Tier 2 — SP_eMoney_Dim_Account) |
| 12 | Region | varchar(50) | YES | Geographic region from DWH_dbo.Dim_Country.Region, resolved via CountryID. (Tier 2 — SP_eMoney_Dim_Account) |
| 13 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered; other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 14 | PlayerStatus | varchar(50) | YES | Player status display name resolved from DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 15 | IsValidETM | int | YES | eToro Money validity flag. 1 when IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0. Standard filter for eTM production analytics. (Tier 2 — SP_eMoney_Dim_Account) |
| 16 | IsValidCustomer | int | YES | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 17 | IsTestAccount | int | YES | 1 if GCID appears in the Fivetran Google Sheets test-user list (eMoney_google_sheets.emoney_test_users); 0 otherwise. Exclude from all production analytics. (Tier 2 — SP_eMoney_Dim_Account) |
| 18 | IsCancelledAccount | int | YES | 1 when GCID=0 (cancelled accounts are recorded with a zero GCID in FiatDwhDB). (Tier 2 — SP_eMoney_Dim_Account) |
| 19 | GCID_Unique_Count | int | YES | Rank of this currency balance account for its GCID, ordered by AccountCreateTime DESC. 1 = most recently created eMoney account for this customer (the primary account). Customer DWH enrichment columns (CID, ClubID, etc.) are only populated for rank=1 rows. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.3 TP Trading Platform Dates

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 20 | TP_RegDate | date | YES | Account registration date (renamed from Registered). Default=getdate(). DWH note: CAST to DATE (time component discarded); renamed RegisteredReal→TP_RegDate. (Tier 1 — Customer.CustomerStatic) |
| 21 | TP_FTDDate | date | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. DWH note: CAST to DATE; renamed FirstDepositDate→TP_FTDDate. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |

### 4.4 Registration-Time Snapshot (Customer State at eMoney Account Creation)

*Sourced from DWH_dbo.Fact_SnapshotCustomer at the date range matching AccountCreateDateID.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 22 | RegClubID | int | YES | PlayerLevelID from Fact_SnapshotCustomer at the date of eMoney account creation. Represents the customer's club at eTM onboarding. (Tier 2 — SP_eMoney_Dim_Account) |
| 23 | RegClub | varchar(50) | YES | Club display name for RegClubID, resolved from DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_eMoney_Dim_Account) |
| 24 | RegClubCategory | varchar(50) | YES | Club category bucket at account creation. Same mapping as ClubCategory (NoClub/LowClub/HighClub/Internal) applied to RegClubID. (Tier 2 — SP_eMoney_Dim_Account) |
| 25 | RegRegulationID | int | YES | RegulationID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 — SP_eMoney_Dim_Account) |
| 26 | RegRegulation | varchar(50) | YES | Regulation display name for RegRegulationID, resolved from DWH_dbo.Dim_Regulation. (Tier 2 — SP_eMoney_Dim_Account) |
| 27 | RegCountryID | int | YES | CountryID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 — SP_eMoney_Dim_Account) |
| 28 | RegCountry | varchar(50) | YES | Country display name for RegCountryID, resolved from DWH_dbo.Dim_Country. (Tier 2 — SP_eMoney_Dim_Account) |
| 29 | RegRegion | varchar(50) | YES | Geographic region for RegCountryID, resolved from DWH_dbo.Dim_Country.Region. (Tier 2 — SP_eMoney_Dim_Account) |
| 30 | RegPlayerStatusID | int | YES | PlayerStatusID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 — SP_eMoney_Dim_Account) |
| 31 | RegPlayerStatus | varchar(50) | YES | Player status display name for RegPlayerStatusID, resolved from DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 32 | RegAccountProgramID | int | YES | Account program type at eMoney account creation: 0=Unknown, 1=card, 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). Captured from eMoney_Account_Mappings baseline (original FiatAccount.AccountProgramId). (Tier 1 — dbo.FiatAccount) |
| 33 | RegAccountProgram | varchar(50) | YES | Account program display name for RegAccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 — SP_eMoney_Dim_Account) |
| 34 | RegAccountSubProgramID | int | YES | Specific sub-program variant at eMoney account creation: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. Captured from eMoney_Account_Mappings baseline. (Tier 1 — dbo.FiatAccount) |
| 35 | RegAccountSubProgram | varchar(50) | YES | Sub-program display name for RegAccountSubProgramID, resolved from eMoney_dbo.SubPrograms. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.5 Change Detection Flags

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 36 | HasCustomerInfoChanged | int | YES | 1 if ANY of the following changed since account creation: ClubID, RegulationID, CountryID, PlayerStatusID, AccountProgramID, AccountSubProgramID. Composite of all six individual change flags. (Tier 2 — SP_eMoney_Dim_Account) |
| 37 | HasClubChanged | int | YES | 1 if ClubID (current) ≠ RegClubID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 38 | HasRegulationChanged | int | YES | 1 if RegulationID (current) ≠ RegRegulationID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 39 | HasCountryChanged | int | YES | 1 if CountryID (current) ≠ RegCountryID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 40 | HasPlayerStatusChanged | int | YES | 1 if PlayerStatusID (current) ≠ RegPlayerStatusID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 41 | HasAccountProgramChanged | int | YES | 1 if AccountProgramID (current) ≠ RegAccountProgramID (at account creation). Tracks card-to-IBAN upgrades. (Tier 2 — SP_eMoney_Dim_Account) |
| 42 | HasAccountSubProgramChanged | int | YES | 1 if AccountSubProgramID (current) ≠ RegAccountSubProgramID (at account creation). Tracks sub-program tier/region changes. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.6 Currency Balance Details

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 43 | CurrencyBalanceISOCode | int | YES | ISO 4217 numeric currency code. E.g., "826"=GBP, "978"=EUR, "036"=AUD. Indexed for currency-based queries. Renamed from FiatCurrencyBalances.CurrencyISON. (Tier 1 — dbo.FiatCurrencyBalances) |
| 44 | CurrencyBalanceISODesc | varchar(50) | YES | Currency display name resolved from eMoney_Currency_Instrument_Mapping_Static via CurrencyBalanceISOCode (where SellCurrencyID=1). (Tier 2 — SP_eMoney_Dim_Account) |
| 45 | CurrencyBalanceCreateTime | datetime | YES | UTC timestamp when this currency balance was created in the data warehouse. Renamed from FiatCurrencyBalances.Created. (Tier 1 — dbo.FiatCurrencyBalances) |
| 46 | CurrencyBalanceCreateDate | date | YES | Date portion of CurrencyBalanceCreateTime. DWH-derived: CAST(CurrencyBalanceCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 47 | CurrencyBalanceCreateDateID | int | YES | YYYYMMDD integer date key for CurrencyBalanceCreateDate. DWH-derived: CONVERT(VARCHAR(8), CurrencyBalanceCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 48 | CurrencyBalanceStatusID | int | YES | Current currency balance operational status: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. Latest status from FiatCurrencyBalancesStatuses (RNDesc=1 by EventTimestamp). (Tier 2 — SP_eMoney_Dim_Account) |
| 49 | CurrencyBalanceStatus | varchar(50) | YES | Currency balance status display name for CurrencyBalanceStatusID, resolved from eMoney_Dictionary_CurrencyBalanceStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 50 | CurrencyBalanceStatusTime | datetime | YES | EventTimestamp of the most recent status change for this currency balance (from FiatCurrencyBalancesStatuses, RNDesc=1). (Tier 2 — SP_eMoney_Dim_Account) |
| 51 | ProviderDesc | varchar(50) | YES | Provider name for this account (e.g., Tribe), sourced from AccountsProviderHoldersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |
| 52 | ProviderCurrencyBalanceID | int | YES | Provider-side currency balance identifier from CurrencyBalancesProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.7 Bank Account Details

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 53 | BankAccountID | int | YES | Auto-incrementing surrogate primary key. (Tier 1 — dbo.FiatBankAccount) |
| 54 | BankAccountIsExternal | int | YES | Classifies the bank account: 0=internal platform bank account (linked to currency balance), 1=external customer payee bank account (standalone). Determines how the account is used in payment flows. (Tier 1 — dbo.FiatBankAccount) |
| 55 | BankAccountName | nvarchar(100) | YES | Full name of the bank account holder. Masked with dynamic data masking (DDM) for PII protection - only privileged users see the actual value. Renamed from FiatBankAccount.FullName. (Tier 1 — dbo.FiatBankAccount) |
| 56 | BankAccountNumber | int | YES | Bank account number. Masked for PII protection. Format varies by region (UK: 8 digits, other regions vary). (Tier 1 — dbo.FiatBankAccount) |
| 57 | BankAccountSortCode | int | YES | UK bank sort code (6 digits, e.g., "040004"). Used together with BankAccountNumber for UK Faster Payments and Bacs transfers. NULL for non-UK accounts. (Tier 1 — dbo.FiatBankAccount) |
| 58 | BankAccountIBAN | varchar(200) | YES | International Bank Account Number. Masked for PII protection. Used for SEPA transfers in EU/EEA. NULL for non-IBAN accounts (e.g., UK-only sort code accounts). (Tier 1 — dbo.FiatBankAccount) |
| 59 | BankAccountBIC | varchar(200) | YES | Bank Identifier Code (SWIFT/BIC). Identifies the bank for international transfers. Used alongside IBAN for SEPA payments. (Tier 1 — dbo.FiatBankAccount) |

### 4.8 Fiat Account Create & Status

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 60 | AccountCreateTime | datetime | YES | UTC timestamp when this account record was created in the data warehouse. Renamed from FiatAccount.Created. (Tier 1 — dbo.FiatAccount) |
| 61 | AccountCreateDate | date | YES | Date portion of AccountCreateTime. DWH-derived: CAST(AccountCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 62 | AccountCreateDateID | int | YES | YYYYMMDD integer date key for AccountCreateDate. DWH-derived: CONVERT(VARCHAR(8), AccountCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 63 | AccountStatusID | int | YES | Current account lifecycle status: 0=Active, 1=Suspended, 2=Deleted. Latest StatusType from FiatAccountStatuses (RNDesc=1 by Created). (Tier 1 — dbo.FiatAccountStatuses) |
| 64 | AccountStatus | varchar(50) | YES | Account status display name for AccountStatusID, resolved from eMoney_Dictionary_AccountStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 65 | AccountStatusTime | datetime | YES | Created timestamp of the most recent account status change event (from FiatAccountStatuses, RNDesc=1). (Tier 2 — SP_eMoney_Dim_Account) |

### 4.9 Account Program & Sub-Program (Current)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 66 | AccountProgramID | int | YES | Account program type: 0=Unknown, 1=card, 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). DWH note: current program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.AccountProgramId) — reflects most recent program upgrade/downgrade. (Tier 1 — dbo.FiatAccount) |
| 67 | AccountProgram | varchar(50) | YES | Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 — SP_eMoney_Dim_Account) |
| 68 | AccountSubProgramID | int | YES | Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. DWH note: current sub-program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.SubProgramId). (Tier 1 — dbo.FiatAccount) |
| 69 | AccountSubProgram | varchar(50) | YES | Sub-program display name for AccountSubProgramID, resolved from eMoney_dbo.SubPrograms (16 active programs across UK/EU/AUS regions). (Tier 2 — SP_eMoney_Dim_Account) |
| 70 | AccountPropertiesTime | datetime | YES | Created timestamp of the most recent FiatAccountsProperties record for this account (the source of AccountProgramID/AccountSubProgramID). NULL if no properties record exists. (Tier 2 — SP_eMoney_Dim_Account) |
| 71 | AccountPropertiesDate | date | YES | Date portion of AccountPropertiesTime. DWH-derived: CAST(AccountPropertiesTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 72 | CountAccountProgramChanges | int | YES | Number of distinct program types this account has had. Set to 0 when ≤1 (i.e., never changed). N≥2 means the account has changed program N times. (Tier 2 — SP_eMoney_Dim_Account) |
| 73 | CountAccountSubProgramChanges | int | YES | Number of distinct sub-programs this account has had. Set to 0 when ≤1 (never changed). N≥2 means the account has changed sub-program N times. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.10 Provider & Seniority

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 74 | ProviderHolderID | int | YES | Provider-side holder identifier from AccountsProviderHoldersMapping via eMoney_Account_Mappings. Identifies the customer's account in the Tribe payment provider system. (Tier 2 — SP_eMoney_Dim_Account) |
| 75 | Seniority_TP_RegDate | int | YES | Months since TP (trading platform) registration date (DATEDIFF MONTH between RegisteredReal and @Date=yesterday). NULL when TP_RegDate is NULL. (Tier 2 — SP_eMoney_Dim_Account) |
| 76 | Seniority_TP_FTDDate | int | YES | Months since first trading platform deposit date (DATEDIFF MONTH between FirstDepositDate and @Date=yesterday). NULL when TP_FTDDate is NULL or is the sentinel '19000101'. (Tier 2 — SP_eMoney_Dim_Account) |
| 77 | Seniority_eTM_RegDate | int | YES | Months since eToro Money account creation date (DATEDIFF MONTH between AccountCreateTime and @Date=yesterday). Measures eTM-specific tenure. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.11 Card Details

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 78 | HasCard | int | YES | 1 if this account has an associated card (CardID IS NOT NULL), 0 otherwise. (Tier 2 — SP_eMoney_Dim_Account) |
| 79 | CardID | int | YES | Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. (Tier 1 — dbo.FiatCards) |
| 80 | CardCreateTime | datetime | YES | UTC timestamp when this card record was created in the data warehouse. Renamed from FiatCards.Created. (Tier 1 — dbo.FiatCards) |
| 81 | CardCreateDate | date | YES | Date portion of CardCreateTime. DWH-derived: CAST(CardCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 82 | CardCreateDateID | int | YES | YYYYMMDD integer date key for CardCreateDate. DWH-derived: CONVERT(VARCHAR(8), CardCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 83 | CardStatusID | int | YES | Current card lifecycle status: 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. Latest status from FiatCardStatuses (RNDesc=1 by EventTimestamp). (Tier 1 — dbo.FiatCardStatuses) |
| 84 | CardStatus | varchar(50) | YES | Card status display name for CardStatusID, resolved from eMoney_Dictionary_CardStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 85 | CardStatusExpirationTime | datetime | YES | Card expiration date at the time of this status event. (Tier 1 — dbo.FiatCardStatuses) |
| 86 | CardStatusTime | datetime | YES | When the status change occurred in the source system. (Tier 1 — dbo.FiatCardStatuses) |
| 87 | ProviderCardID | int | YES | Provider-side card identifier from CardsProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.12 Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 88 | UpdateDate | datetime | YES | GETDATE() at INSERT time. Marks when the daily ETL refresh ran; not a business timestamp. (Tier 2 — SP_eMoney_Dim_Account) |
| 89 | Entity | varchar(250) | YES | eToro Money entity name resolved from eMoney_EntityByCurrencyISO_MappingStatic via CurrencyBalanceISOCode. Identifies the regulatory/legal entity serving this balance. ISNULL → 'N/A' when no mapping exists. Values observed: Malta, UK, AUS. (Tier 2 — SP_eMoney_Dim_Account) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column Group | Production Source | Source Column(s) | Transform |
|-----------------|-------------------|-----------------|-----------|
| CurrencyBalanceID | FiatDwhDB.dbo.FiatCurrencyBalances | Id | Passthrough |
| AccountID, GCID | FiatDwhDB.dbo.FiatAccount | Id, Gcid | Passthrough |
| AccountCreateTime | FiatDwhDB.dbo.FiatAccount | Created | Rename |
| CID, ClubID, RegulationID, CountryID, PlayerStatusID, IsValidCustomer, TP_RegDate, TP

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.V_Liabilities` — synapse
- **Resolved as**: `DWH_dbo.V_Liabilities`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md`

# DWH_dbo.V_Liabilities

> Daily customer liabilities view combining equity snapshots (`Fact_SnapshotEquity`) with unrealized PnL (`Fact_CustomerUnrealized_PnL`) to compute **ActualNWA** (credit-capped net worth), **Liabilities** (customer obligations to the platform), **WA_Liabilities** (credit-covered portion), and asset-class breakdowns — the central view for regulatory balance reporting, dormant fee calculations, AML monitoring, and client balance dashboards.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Source Tables** | Fact_SnapshotEquity (a), V_M2M_Date_DateRange (b), Fact_CustomerUnrealized_PnL (c), Fact_Guru_Copiers (gc — dead join) |
| **Key Identifier** | CID + DateID |
| **Output Columns** | 75 (T1: 63, T2: 12) |
| **UC Table** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` |
| **Data Scope** | All dates **before today** (`DateKey < CAST(CONVERT(VARCHAR(MAX),GETDATE(),112) AS INT)`) |
| **Generated** | 2026-03-22 |

---

## 1. Business Meaning

`V_Liabilities` is the platform's primary view for computing what eToro owes each customer (liabilities) and how much of the customer's balance is "real" vs promotional credit.

**Core formula** — let `NetEquity = TotalPositionsAmount + TotalCash + TotalStockOrders + PositionPnL`:
- **ActualNWA** (Non-Withdrawable Amount): The portion of NetEquity covered by BonusCredit. Clamped to `[0, BonusCredit]`. If the customer's NetEquity exceeds their BonusCredit, ActualNWA = BonusCredit. If NetEquity goes negative, ActualNWA = 0.
- **Liabilities**: InProcessCashouts + the portion of NetEquity **above** BonusCredit. This is what eToro owes the customer — real money, not promotional credit.
- **Balance**: Liabilities + ActualNWA = RealizedEquity + PositionPnL (Confluence: "Summary of V-Liabilities")

**Business context** (from Confluence):
- "If clients lose money, their Actual NWA will reflect only what's left. A client has $1000, loses $200 → Actual NWA = $800. When they profit back to $2000 → Actual NWA = $1000 and Liabilities show $1000 bonus credit."
- The view excludes today's date because end-of-day snapshots (FSE + FCUPNL) must both be loaded before the view is meaningful.

**Key consumers**: SP_DDR_Fact_AUM, SP_Client_Balance_New, SP_Client_Balance_Breakdown, SP_Q_AML_EDD_US_Report, SP_Q_AML_FSA_Report, SP_AML_PI_Abuse, SP_AML_BI_Alerts_New_Singapore, SP_CIDFirstDates, SP_CID_DailyPanel_FullData, SP_CID_MonthlyPanel_FullData, SP_MarketingCloudDaily, SP_Copyfunds_SignificantAllocation, SP_Fact_RegulationTransfer, SP_TIN_Gap, SP_BI_DB_W8_Users_Status, SP_BI_DB_CO_Cluster_Daily, SP_IR_Dashboard_Monitor_Checks, SP_OPS_MultipleAccounts, SP_Q_QSR_New.

---

## 2. Business Logic

### 2.1 Join Structure

```
Fact_SnapshotEquity a                   -- daily equity snapshot per CID
  JOIN V_M2M_Date_DateRange b           -- expands DateRangeID → one row per calendar day (DateKey)
    ON a.DateRangeID = b.DateRangeID
  LEFT JOIN Fact_CustomerUnrealized_PnL c  -- daily PnL snapshot per CID
    ON a.CID = c.CID AND b.DateKey = c.DateModified
  LEFT JOIN Fact_Guru_Copiers gc        -- DEAD JOIN: no columns selected (Boris Slutski, 2021-01-11)
    ON a.CID = gc.CID AND b.DateKey = gc.DateID
WHERE b.DateKey < today
```

### 2.2 Computed Column Formulas

All computed columns use a common intermediate value:

```
NetEquity = ISNULL(TotalPositionsAmount, 0) + ISNULL(TotalCash, 0)
          + ISNULL(TotalStockOrders, 0) + ISNULL(PositionPnL, 0)
```

Note: `TotalStockOrders` is a legacy column hardcoded to 0 since 2019 (see Fact_SnapshotEquity wiki). Its presence in the formula is a historical artifact — it does not affect computation.

| Column | Formula |
|--------|---------|
| **ActualNWA** | `CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END` |
| **Liabilities** | `InProcessCashouts + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END` |
| **WA_Liabilities** | `MIN(Liabilities_excl_cashouts, Credit)` — the portion of liabilities coverable by credit |
| **Liabilities_InUsedMargin** | `MAX(Liabilities_excl_cashouts - Credit, 0)` — liabilities exceeding available credit |
| **LiabilitiesStockReal** | `ISNULL(PositionPnLStocksReal, 0) + ISNULL(TotalRealStocks, 0)` |
| **LiabilitiesCryptoReal** | `ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0)` |
| **LiabilitiesCrypto_TRS** | `ISNULL(CryptoPositionPnL_TRS, 0) + ISNULL(Total_TRSCrypto, 0)` |
| **LiabilitiesFuturesReal** | `ISNULL(PositionPnLFuturesReal, 0) + ISNULL(TotalRealFutures, 0)` |
| **TotalStockManualPosition** | `TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount` |
| **ManualStockPositionPnL** | `StocksPositionPnL - MirrorStocksPositionPnL` |
| **TotalCryptoManualPosition** | `TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount` |
| **TotalCryptoManualPosition_TRS** | `TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS` |

---

## 3. Source Objects

| Object | Schema | Alias | Role |
|--------|--------|-------|------|
| Fact_SnapshotEquity | DWH_dbo | a | Equity balances, cash, positions, AUM, credit |
| V_M2M_Date_DateRange | DWH_dbo | b | Expands DateRangeID to per-day rows (DateKey, FullDate) |
| Fact_CustomerUnrealized_PnL | DWH_dbo | c | Unrealized PnL, NOP, notional, commissions, risk |
| Fact_Guru_Copiers | DWH_dbo | gc | **Dead join** — no columns selected. LEFT JOIN preserved from 2021, can be removed. |

---

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | CID | Fact_SnapshotEquity.CID | Direct | T1 |
| 2 | DateID | V_M2M_Date_DateRange.DateKey | Direct (alias DateKey → DateID) | T1 |
| 3 | FullDate | V_M2M_Date_DateRange.FullDate | Direct | T1 |
| 4 | RealizedEquity | Fact_SnapshotEquity.RealizedEquity | Direct | T1 |
| 5 | TotalPositionsAmount | Fact_SnapshotEquity.TotalPositionsAmount | Direct | T1 |
| 6 | TotalCash | Fact_SnapshotEquity.TotalCash | Direct | T1 |
| 7 | InProcessCashouts | Fact_SnapshotEquity.InProcessCashouts | Direct | T1 |
| 8 | TotalMirrorPositionsAmount | Fact_SnapshotEquity.TotalMirrorPositionsAmount | Direct | T1 |
| 9 | TotalMirrorCash | Fact_SnapshotEquity.TotalMirrorCash | Direct | T1 |
| 10 | TotalStockOrders | Fact_SnapshotEquity.TotalStockOrders | Direct (legacy — always 0 since 2019) | T1 |
| 11 | TotalMirrorStockOrders | Fact_SnapshotEquity.TotalMirrorStockOrders | Direct (legacy — always 0 since 2019) | T1 |
| 12 | Credit | Fact_SnapshotEquity.Credit | Direct | T1 |
| 13 | AUM | Fact_SnapshotEquity.AUM | Direct | T1 |
| 14 | BonusCredit | Fact_SnapshotEquity.BonusCredit | Direct | T1 |
| 15 | TotalStockPositionAmount | Fact_SnapshotEquity.TotalStockPositionAmount | Direct | T1 |
| 16 | TotalMirrorStockPositionAmount | Fact_SnapshotEquity.TotalMirrorStockPositionAmount | Direct | T1 |
| 17 | PositionPnL | Fact_CustomerUnrealized_PnL.PositionPnL | Direct | T1 |
| 18 | CopyPositionPnL | Fact_CustomerUnrealized_PnL.CopyPositionPnL | Direct | T1 |
| 19 | StandardDeviation | Fact_CustomerUnrealized_PnL.StandardDeviation | Direct | T1 |
| 20 | CommissionOnOpen | Fact_CustomerUnrealized_PnL.CommissionOnOpen | Direct | T1 |
| 21 | ActualNWA | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END. NetEquity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0) | T2 |
| 22 | Liabilities | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(InProcessCashouts,0) + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END | T2 |
| 23 | WA_Liabilities | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | MIN(Liabilities_excl_cashouts, Credit) — credit-capped liabilities | T2 |
| 24 | Liabilities_InUsedMargin | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | MAX(Liabilities_excl_cashouts - Credit, 0) — liabilities beyond credit | T2 |
| 25 | StocksPositionPnL | Fact_CustomerUnrealized_PnL.StocksPositionPnL | Direct | T1 |
| 26 | TotalStockManualPosition | Fact_SnapshotEquity | TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount | T2 |
| 27 | ManualStockPositionPnL | Fact_CustomerUnrealized_PnL | StocksPositionPnL - MirrorStocksPositionPnL | T2 |
| 28 | MirrorStocksPositionPnL | Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL | Direct | T1 |
| 29 | CryptoPositionPnL | Fact_CustomerUnrealized_PnL.CryptoPositionPnL | Direct | T1 |
| 30 | ManualCryptoPositionPnL | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL | Direct | T1 |
| 31 | CopyCryptoPositionPnL | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL | Direct | T1 |
| 32 | TotalCryptoPositionAmount | Fact_SnapshotEquity.TotalCryptoPositionAmount | Direct | T1 |
| 33 | TotalCryptoManualPosition | Fact_SnapshotEquity | TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount | T2 |
| 34 | CopyFundAUM | Fact_SnapshotEquity.CopyFundAUM | Direct | T1 |
| 35 | CopyFundPnL | Fact_CustomerUnrealized_PnL.CopyFundPnL | Direct | T1 |
| 36 | NOP | Fact_CustomerUnrealized_PnL.NOP | Direct | T1 |
| 37 | Notional | Fact_CustomerUnrealized_PnL.Notional | Direct | T1 |
| 38 | NOP_Crypto | Fact_CustomerUnrealized_PnL.NOP_Crypto | Direct | T1 |
| 39 | Notional_Crypto | Fact_CustomerUnrealized_PnL.Notional_Crypto | Direct | T1 |
| 40 | NOP_CFD | Fact_CustomerUnrealized_PnL.NOP_CFD | Direct | T1 |
| 41 | Notional_CFD | Fact_CustomerUnrealized_PnL.Notional_CFD | Direct | T1 |
| 42 | NOP_Crypto_CFD | Fact_CustomerUnrealized_PnL.NOP_Crypto_CFD | Direct | T1 |
| 43 | Notional_Crypto_CFD | Fact_CustomerUnrealized_PnL.Notional_Crypto_CFD | Direct | T1 |
| 44 | PositionPnLStocksReal | Fact_CustomerUnrealized_PnL.PositionPnLStocksReal | Direct | T1 |
| 45 | PositionPnLCryptoReal | Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal | Direct | T1 |
| 46 | TotalRealStocks | Fact_SnapshotEquity.TotalRealStocks | Direct | T1 |
| 47 | TotalRealCrypto | Fact_SnapshotEquity.TotalRealCrypto | Direct | T1 |
| 48 | LiabilitiesStockReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLStocksReal, 0) + ISNULL(TotalRealStocks, 0) | T2 |
| 49 | LiabilitiesCryptoReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0) | T2 |
| 50 | CommissionByUnitsCrypto_TRS | Fact_CustomerUnrealized_PnL.CommissionByUnitsCrypto_TRS | Direct | T1 |
| 51 | CopyCryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS | Direct | T1 |
| 52 | CryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.CryptoPositionPnL_TRS | Direct | T1 |
| 53 | FullCommissionByUnitsCrypto_TRS | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCrypto_TRS | Direct | T1 |
| 54 | ManualCryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL_TRS | Direct | T1 |
| 55 | NOP_Crypto_TRS | Fact_CustomerUnrealized_PnL.NOP_Crypto_TRS | Direct | T1 |
| 56 | Notional_Crypto_TRS | Fact_CustomerUnrealized_PnL.Notional_Crypto_TRS | Direct | T1 |
| 57 | Total_TRSCrypto | Fact_SnapshotEquity.Total_TRSCrypto | Direct | T1 |
| 58 | TotalCryptoPositionAmount_TRS | Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS | Direct | T1 |
| 59 | TotalCryptoManualPosition_TRS | Fact_SnapshotEquity | TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS | T2 |
| 60 | LiabilitiesCrypto_TRS | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(CryptoPositionPnL_TRS, 0) + ISNULL(Total_TRSCrypto, 0) | T2 |
| 61 | MirrorRealFuturesPositionPnL | Fact_CustomerUnrealized_PnL.MirrorRealFuturesPositionPnL | Direct | T1 |
| 62 | ManualRealFuturesPositionPnL | Fact_CustomerUnrealized_PnL.ManualRealFuturesPositionPnL | Direct | T1 |
| 63 | NOP_FuturesReal | Fact_CustomerUnrealized_PnL.NOP_FuturesReal | Direct | T1 |
| 64 | Notional_FuturesReal | Fact_CustomerUnrealized_PnL.Notional_FuturesReal | Direct | T1 |
| 65 | PositionPnLFuturesReal | Fact_CustomerUnrealized_PnL.PositionPnLFuturesReal | Direct | T1 |
| 66 | FullCommissionByUnitsFuturesReal | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsFuturesReal | Direct | T1 |
| 67 | CommissionByUnitsFuturesReal | Fact_CustomerUnrealized_PnL.CommissionByUnitsFuturesReal | Direct | T1 |
| 68 | TotalMirrorRealFuturesPositionAmount | Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount | Direct | T1 |
| 69 | TotalRealFutures | Fact_SnapshotEquity.TotalRealFutures | Direct | T1 |
| 70 | TotalFuturesProviderMargin | Fact_SnapshotEquity.TotalFuturesProviderMargin | Direct | T1 |
| 71 | LiabilitiesFuturesReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLFuturesReal, 0) + ISNULL(TotalRealFutures, 0) | T2 |
| 72 | NOP_StocksMargin | Fact_CustomerUnrealized_PnL.NOP_StocksMargin | Direct | T1 |
| 73 | PositionPnLStocksMargin | Fact_CustomerUnrealized_PnL.PositionPnLStocksMargin | Direct | T1 |
| 74 | TotalStocksMargin | Fact_SnapshotEquity.TotalStocksMargin | Direct | T1 |
| 75 | TotalStockMarginLoanValue | Fact_SnapshotEquity.TotalStockMarginLoanValue | Direct | T1 |

---

## 5. Query Advisory

- **Always filter by DateID** — the view contains the full history of daily snapshots. Unfiltered queries are expensive.
- **Balance formula**: `Liabilities + ActualNWA` or equivalently `ISNULL(RealizedEquity,0) + ISNULL(PositionPnL,0)` (Confluence)
- **TotalCash decomposition**: `TotalCash = Credit + TotalMirrorCash` (Confluence)
- **Today's data is excluded** — the WHERE clause filters `DateKey < today`. This is by design; use yesterday's date.
- **LEFT JOIN to FCUPNL**: PnL columns will be NULL for CIDs with no open positions on a given date. Use ISNULL when aggregating.

---

## 6. Relationships

### 6.1 Upstream Sources

| Source | Join Key | Columns Contributed |
|--------|----------|-------------------|
| Fact_SnapshotEquity | CID + DateRangeID → V_M2M_Date_DateRange | Equity, cash, positions, credit, AUM, asset-class amounts (32 columns) |
| Fact_CustomerUnrealized_PnL | CID + DateModified = DateKey | PnL, NOP, notional, commissions, risk (31 columns) |
| V_M2M_Date_DateRange | DateRangeID | DateKey (→ DateID), FullDate |

### 6.2 Downstream Consumers (20+ SPs)

| SP | Schema | Usage Pattern |
|----|--------|---------------|
| SP_DDR_Fact_AUM | BI_DB_dbo | AUM dashboard aggregation |
| SP_Client_Balance_New | BI_DB_dbo | Customer balance reporting |
| SP_Client_Balance_Breakdown | BI_DB_dbo | Detailed balance decomposition |
| SP_Q_AML_EDD_US_Report | BI_DB_dbo | AML enhanced due diligence (US) |
| SP_Q_AML_FSA_Report | BI_DB_dbo | AML FSA regulatory report |
| SP_AML_PI_Abuse | BI_DB_dbo | Popular Investor abuse detection |
| SP_AML_BI_Alerts_New_Singapore | BI_DB_dbo | AML alerts (Singapore) |
| SP_Fact_RegulationTransfer | DWH_dbo | Regulation transfer processing |
| SP_Fact_CustomerUnrealized_PnL | DWH_dbo | Uses equity from FSE for risk weights |
| SP_CIDFirstDates | BI_DB_dbo | First date tracking per CID |
| SP_MarketingCloudDaily | BI_DB_dbo | Marketing data feed |
| SP_Copyfunds_SignificantAllocation | BI_DB_dbo | Copy fund allocation analysis |
| SP_Q_QSR_New | BI_DB_dbo | QSR regulatory report |
| SP_TIN_Gap | BI_DB_dbo | TIN gap analysis |
| SP_CID_DailyPanel_FullData | BI_DB_dbo | Daily customer panel |
| SP_CID_MonthlyPanel_FullData | BI_DB_dbo | Monthly customer panel |
| SP_BI_DB_CO_Cluster_Daily | BI_DB_dbo | Cashout clustering |
| SP_BI_DB_W8_Users_Status | BI_DB_dbo | W8 tax form status |
| SP_IR_Dashboard_Monitor_Checks | BI_DB_dbo | IR dashboard monitoring |
| SP_OPS_MultipleAccounts | BI_DB_dbo | Multiple account detection |
| SP_M_Affiliates_FraudMonitoring | BI_DB_dbo | Affiliate fraud monitoring |

---

## 7. Sample Queries

```sql
-- Customer balance for yesterday
SELECT CID, DateID,
       Liabilities + ActualNWA AS Balance,
       Liabilities, ActualNWA, Credit,
       RealizedEquity, PositionPnL
FROM DWH_dbo.V_Liabilities
WHERE DateID = CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT)
  AND CID = 12345;

-- Platform total liabilities trend (last 7 days)
SELECT DateID,
       SUM(Liabilities) AS TotalLiabilities,
       SUM(ActualNWA) AS TotalNWA,
       SUM(Liabilities) + SUM(ActualNWA) AS TotalBalance,
       COUNT(DISTINCT CID) AS Customers
FROM DWH_dbo.V_Liabilities
WHERE DateID >= CAST(CONVERT(CHAR(8), GETDATE()-8, 112) AS INT)
GROUP BY DateID
ORDER BY DateID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| Summary of V-Liabilities (Confluence/BI) | Authoritative business definitions: Balance = Liabilities + ActualNWA = RealizedEquity + PositionPnL. BonusCredit examples. TotalCash = Credit + TotalMirrorCash. |
| BI Dictionary (Confluence/BI) | "V_Liabilities: a view that summarizes or exposes customer liabilities, such as negative balances, equity, Position PnL, etc." |
| DDR Tables (Confluence) | "BI_DB_DDR_Fact_AUM is the same as V_Liabilities table (daily snapshot per user)" — notes equivalence for equity/AUM |
| Azure Data Platform Projects (Confluence/BDP) | Lists V_Liabilities as a Gold-tier replicated asset |
| PNL flow (Confluence/BDP) | V_Liabilities as downstream consumer of PnL pipeline |
| Dormant Fee (Confluence/REGTECH) | Uses V_Liabilities.Liabilities and Credit for dormant fee eligibility |
| Credit Line COs (Confluence/OTS) | NWA / Credit Line rules: "Credit Line × 3 = AAA; Equity - AAA = what can be CO" |

---
*Generated: 2026-03-22 | Reviewed: 2026-03-28 (Batch 17) | Quality: 9.2/10 (★★★★★)*
*Tiers: 63 T1, 12 T2, 0 T3, 0 T4 | Phases: 1,5,7,8,10,11 | 75 cols individually documented — no shortcuts*


### Upstream `DWH_dbo.STS_User_Operations_Data_History` — synapse
- **Resolved as**: `DWH_dbo.STS_User_Operations_Data_History`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\STS_User_Operations_Data_History.md`

# DWH_dbo.STS_User_Operations_Data_History

> Historical log of every STS (Security Token Service) authentication and session event — logins, logouts, token exchanges, and re-authentications — capturing client device, IP, application, and session identifiers for each customer interaction.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact-like History) |
| **Row Count** | Billions (daily partitioned, data from 2021-08 onward) |
| **Production Source** | `STS_Audit.StsAudit.UserOperations` (via `DWH_staging.STS_Audit_UserOperationsData`) |
| **Refresh** | Daily append (midnight ETL via partition SWITCH) |
| | |
| **Synapse Distribution** | HASH(Gcid) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Synapse Partitioning** | RANGE LEFT on DateID — per-day partitions from 2022-01-01 through 2026-02-28 |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history` |
| **UC Format** | Parquet |
| **Generic Pipeline** | ID 459, SynapseSourceWithoutSecret, daily Append |

---

## 1. Business Meaning

`DWH_dbo.STS_User_Operations_Data_History` is the authoritative session-level audit trail for eToro's Security Token Service (STS). Every time a user logs in, authenticates, exchanges a token, or logs out — on web, iOS, or Android — a row is recorded here. The table answers: "When did this customer access the platform, from where, and using which device/app?"

The STS service handles all authentication CRUD operations for eToro users. This DWH table captures the historical record of those events, enabling analysis of:
- **Login frequency and patterns** — how often users access the platform
- **Device/platform distribution** — mobile app vs. web, iOS vs. Android
- **Session lineage** — parent-to-child session chains via ParentSessionId
- **Geographic access patterns** — via ClientIp (CountryISOCode and ProxyType available but sparsely populated)
- **Security auditing** — hashed access tokens, device IDs, user agents

The table is loaded as a subsection of `SP_Fact_CustomerAction_DL_To_Synapse` — the same mega-SP that populates `Fact_CustomerAction`. STS data is appended daily via the partition SWITCH pattern (no deletes, no updates).

---

## 2. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Gcid | int | YES | Global Customer ID — unique cross-platform identifier linking Real and Demo accounts for the same person. Distribution key. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 2 | RealCid | int | YES | Real-money account Customer ID. NULL when the session is Demo-only. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 3 | DemoCid | int | YES | Virtual/demo account Customer ID. NULL when the session is Real-only. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 4 | ApplicationIdentifier | nvarchar(100) | YES | Client application that initiated the session. Known values: `retoro` (web/generic), `retoroios` (iOS app), `retoroandroid` (Android app). (Tier 2 — STS_Audit_UserOperationsData) |
| 5 | ApplicationVersion | nvarchar(20) | YES | Build version of the client application, e.g. `340.0.10`, `355.0.1`. (Tier 2 — STS_Audit_UserOperationsData) |
| 6 | ClientIp | varchar(20) | YES | IPv4 address of the client at the time of the session event. (Tier 2 — STS_Audit_UserOperationsData) |
| 7 | ClientName | nvarchar(100) | YES | Server-side service name that processed the authentication request. Consistently `STS.WebAPI` across all observed data. (Tier 2 — STS_Audit_UserOperationsData) |
| 8 | CreatedAt | datetime | YES | Timestamp when the authentication/session event occurred in the STS service. This is the business event time (not the ETL load time). (Tier 2 — STS_Audit_UserOperationsData) |
| 9 | UserAgent | nvarchar(512) | YES | Full HTTP User-Agent string from the client browser or mobile WebView. Contains OS, browser, and app metadata. May be NULL for some mobile token exchanges. (Tier 2 — STS_Audit_UserOperationsData) |
| 10 | AccessTokenHashed | nvarchar(256) | YES | Hashed authentication access token for security audit trail. Not reversible. Sparsely populated. (Tier 2 — STS_Audit_UserOperationsData) |
| 11 | ClientDeviceId | nvarchar(50) | YES | UUID-format device identifier (e.g. `3c24d4e9-8ef0-405f-...`). Populated primarily for mobile app sessions; typically NULL or empty for web. (Tier 2 — STS_Audit_UserOperationsData) |
| 12 | ParentSessionId | bigint | YES | Session ID of the parent session for linked/chained sessions. Value `0` indicates a root session (no parent). Enables session chain tracing. (Tier 2 — STS_Audit_UserOperationsData) |
| 13 | AccountTypeName | varchar(100) | YES | Account context for the session: `Real` (live trading) or `Demo` (virtual portfolio). (Tier 2 — STS_Audit_UserOperationsData) |
| 14 | LoginTypeName | varchar(100) | YES | Type of authentication event. Known values: `Login` (new session), `Authenticate` (credential re-validation), `TokenExchange` (token refresh), `Logout` (session end). (Tier 2 — STS_Audit_UserOperationsData) |
| 15 | SessionId | bigint | YES | Unique session identifier assigned by the STS service. Monotonically increasing. (Tier 2 — STS_Audit_UserOperationsData) |
| 16 | GatewayAppId | int | YES | Identifier of the API gateway application that routed the request. Commonly `1` or `2`. NULL for some Logout events. (Tier 2 — STS_Audit_UserOperationsData) |
| 17 | DateID | int | YES | Date partition key in YYYYMMDD integer format (e.g. `20210901`). Computed in ETL from the `@Yesterday` parameter: `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, @Yesterday), 0), 112))`. Clustered index and partition column. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 18 | UpdateDate | datetime | YES | Timestamp when this row was loaded into the DWH, set to `GETDATE()` during ETL execution. Not the business event time. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 19 | ProxyType | nvarchar(max) | YES | Type of proxy detected for the client IP connection (e.g. VPN, TOR). Sparsely populated — NULL in most observed rows. Added after initial table creation. (Tier 3 — data sampling inference) |
| 20 | CountryISOCode | nvarchar(max) | YES | ISO country code resolved from the ClientIp address. Sparsely populated — NULL in most observed rows. Added after initial table creation. (Tier 3 — data sampling inference) |
| 21 | AdditionalData | nvarchar(max) | YES | Extensible JSON or free-text field for additional session metadata. Sparsely populated. (Tier 3 — data sampling inference) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Customer | Gcid = Gcid (or RealCid/DemoCid) | Customer who initiated the session | Outbound FK (implicit) |
| DWH_dbo.Dim_Date | DateID = DateID | Calendar date of the session event | Outbound FK (implicit) |
| DWH_dbo.Fact_CustomerAction | Same SP populates both; Gcid+DateID linkage for login-type ActionTypeIDs | Sibling in the same ETL pipeline | Co-populated |
| DWH_dbo.Vw_STS_User_Operations_Data_History | Direct 1:1 view wrapper | Presentation layer | View |

---

## 4. ETL & Data Pipeline

### Load Pattern: Daily Append via Partition SWITCH

```
SP_Fact_CustomerAction_DL_To_Synapse(@dt)
  │
  ├─ [Step 1] EXEC SP_STS_User_Operations_Data_History_CREATE_SWITCH_SINGLE @dt
  │    → Drops and recreates _SWITCH_SINGLE and _SWITCH tables
  │    → Creates matching HASH(Gcid), CI(DateID) with 3-day partition range
  │
  ├─ [Step 2] INSERT INTO STS_User_Operations_Data_History_SWITCH_SINGLE
  │    SELECT * FROM DWH_staging.STS_Audit_UserOperationsData
  │    WHERE CreatedAt >= @Yesterday AND CreatedAt < @CurrentDate
  │    + DateID computed from @Yesterday
  │    + UpdateDate = GETDATE()
  │
  └─ [Step 3] EXEC SP_STS_User_Operations_Data_History_SWITCH
       → Determines partition number for @CurrentDay
       → SWITCH existing partition data OUT to _SWITCH (shadow table)
       → SWITCH new data IN from _SWITCH_SINGLE (WITH TRUNCATE_TARGET = ON)
       → TRUNCATE _SWITCH shadow table
```

### Source Chain

```
STS_Audit.StsAudit.UserOperations (production)
  → Generic Pipeline (Bronze, daily Append)
  → DWH_staging.STS_Audit_UserOperationsData (Synapse staging)
  → SP_Fact_CustomerAction_DL_To_Synapse (daily ETL)
  → STS_User_Operations_Data_History_SWITCH_SINGLE (temp)
  → SP_STS_User_Operations_Data_History_SWITCH (partition swap)
  → DWH_dbo.STS_User_Operations_Data_History (final)
  → Generic Pipeline ID 459 (Gold, daily Append, parquet)
  → dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history (UC)
```

### Column Transformations

| Target Column | Source Expression | Notes |
|---------------|-------------------|-------|
| DateID | `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, @Yesterday), 0), 112))` | Computed from SP parameter, not from source data |
| UpdateDate | `GETDATE()` | ETL load timestamp |
| All other columns | Direct pass-through | No transformation from STS_Audit_UserOperationsData |

---

## 5. Referenced By

| Object | Usage |
|--------|-------|
| DWH_dbo.Vw_STS_User_Operations_Data_History | Trivial wrapper view — `SELECT *` with `CAST(ClientDeviceId AS NVARCHAR(MAX))` to widen the column type |
| SP_Fact_CustomerAction_DL_To_Synapse | Writer SP (daily ETL) |
| SP_STS_User_Operations_Data_History_SWITCH | Partition swap SP |
| SP_STS_User_Operations_Data_History_CREATE_SWITCH_SINGLE | SWITCH table creator SP |

---

## 6. Business Logic & Patterns

### Key Patterns

- **Append-only history**: No deletes or updates after initial load. The commented-out DELETE confirms this was a design decision (old delete-then-insert replaced by SWITCH pattern).
- **Partition SWITCH for performance**: Daily data is loaded via a temp table with matching schema, then swapped in atomically — avoids row-by-row INSERT overhead on a massive partitioned table.
- **Session lifecycle tracking**: A single user action (e.g. opening the app) generates multiple events — `Login` → `TokenExchange` → ... → `Logout`. Sessions can be chained via `ParentSessionId`.
- **Sparse late columns**: `ProxyType`, `CountryISOCode`, and `AdditionalData` are `NVARCHAR(MAX)` and mostly NULL in older data — likely added after the table was created (Jira DSM-598: "STS - add 3 new fields").

### Data Quality Notes

- **ParentSessionId = 0**: Indicates a root session (most Authenticate events have ParentSessionId = 0)
- **GatewayAppId NULL**: Some Logout events have NULL GatewayAppId
- **UserAgent NULL**: Some older mobile TokenExchange events have no UserAgent
- **ClientDeviceId truncation**: Stored as nvarchar(50) in the table but CAST to nvarchar(max) in the view — some UUIDs may be truncated at the 50-char boundary

---

## 7. Query Advisory

### Distribution & Partitioning

- **Distribution**: HASH(Gcid) — optimized for per-customer queries
- **Clustered Index**: DateID ASC — fast date-range scans
- **Partitioning**: Daily partitions — always filter on DateID for partition elimination

### Recommended Patterns

```sql
-- Daily login count by platform
SELECT DateID,
       ApplicationIdentifier,
       LoginTypeName,
       COUNT_BIG(*) AS event_count
FROM [DWH_dbo].[STS_User_Operations_Data_History]
WHERE DateID BETWEEN 20260301 AND 20260319
  AND LoginTypeName = 'Login'
GROUP BY DateID, ApplicationIdentifier, LoginTypeName
ORDER BY DateID, event_count DESC;
```

### Anti-Patterns

- **Never scan without DateID filter** — table has billions of rows across daily partitions
- **Avoid COUNT(*)** — overflows INT; always use `COUNT_BIG(*)`
- **Prefer the base table** over `Vw_STS_User_Operations_Data_History` — the view's `CAST(ClientDeviceId)` prevents index usage on that column

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Information |
|--------|------|-----------------|
| [STS - Audit_Loggin](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12026741071/STS+-+Audit_Loggin) | Confluence | ADF pipeline documentation: **STSAuditToDataLake** uses dataset **STS_Audit_User_Operations_Data** — maps the lake/staging lineage into Synapse `STS_User_Operations_Data_History` load path. |
| [DEI-2424](https://etoro-jira.atlassian.net/browse/DEI-2424) | Jira | "Optimize insert into [DWH_dbo].[STS_User_Operations_Data_History]" — performance optimization ticket for the INSERT step |
| [DSM-598](https://etoro-jira.atlassian.net/browse/DSM-598) | Jira | "STS - add 3 new fields" — added ProxyType, CountryISOCode, AdditionalData columns. Source: SP_Fact_CustomerAction_DL_To_Synapse |
| [Azure Data Platform Projects](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11782555745) | Confluence | Notes that the Gold data lake path for STS_User_Operations_Data_History was "cancelled" per Inbal Escholi — however the Synapse table and its ETL remain active |
| [sts-user-api](https://etoro-jira.atlassian.net/wiki/spaces/IG/pages/11791106108) | Confluence | STS service documentation — handles CRUD operations on STS user data including creating, retrieving, and updating user sessions |

---

*Generated: 2026-03-19 | Quality: 7.6/10 (★★★★☆) | Phases: 9/14 (P10 Atlassian refresh)*
*Tiers: 0 T1, 16 T2, 3 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 7/10, Relationships: 6/10, Sources: 7.5/10*
*Object: DWH_dbo.STS_User_Operations_Data_History | Type: Table | Production Source: STS_Audit.StsAudit.UserOperations*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_AML_Multiple_Accounts`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_AML_Multiple_Accounts.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_AML_Multiple_Accounts] @Date [DATE] AS
BEGIN
SET NOCOUNT ON;
/**************************************Start Main Comment History******************************************************
=============================================
Author: Lior Ben Dor
Create date: 2023-11-13
Description: Multiple Accounts Dashboard
=============================================

**************************
** Change History
**************************
Date                 Author                   Description  
13/11/2023           Lior Ben Dor             Migration to Synapse
14/10/2023           Lior Ben Dor             Device ID script changes
----------           -----------              -------------------------------------
----------           -----------              -------------------------------------
****************************************End Main Comment History****************************************************/


-- EXECUTE BI_DB_dbo.SP_AML_Multiple_Accounts '2024-10-13'

/********** Declaring Dates **********/

--DECLARE @Date AS DATE = CAST(GETDATE()-1 AS DATE)
DECLARE @DateID INT = CAST(CONVERT(CHAR(8),@Date,112) AS INT)

/********** Step 01 **********/
/********** Funding ID - Deposit **********/
IF OBJECT_ID('tempdb..#fid_deposit') IS NOT NULL DROP TABLE #fid_deposit
CREATE TABLE #fid_deposit  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT fbd.FundingID
	  ,COUNT(DISTINCT fbd.CID) AS 'Total_Users'	
	  ,CASE WHEN COUNT(DISTINCT fbd.CID) <= 20 THEN '5-20' 
			WHEN COUNT(DISTINCT fbd.CID) BETWEEN 21 AND 50 THEN '21-50'
			WHEN COUNT(DISTINCT fbd.CID) BETWEEN 51 AND 500 THEN '51-500'
			WHEN COUNT(DISTINCT fbd.CID)> 500 THEN '500+ '
			END AS 'Group_Type'
	  ,MAX(fbd.ModificationDate) AS 'Last_Deposit_Date'	
FROM DWH_dbo.Fact_BillingDeposit fbd WITH(NOLOCK)
JOIN DWH_dbo.Dim_Customer dc WITH(NOLOCK) ON dc.RealCID = fbd.CID AND dc.IsValidCustomer = 1 AND dc.IsDepositor = 1 AND dc.VerificationLevelID >=2
LEFT JOIN DWH_dbo.Fact_BillingWithdraw fbw WITH(NOLOCK) ON fbd.CID = fbw.CID
WHERE fbd.AmountUSD >0
AND fbd.FundingID NOT IN (1,2,3,4,5,6,7)
GROUP BY fbd.FundingID
HAVING COUNT(DISTINCT fbd.CID) >= 2 

IF OBJECT_ID('tempdb..#dep_info') IS NOT NULL DROP TABLE #dep_info
CREATE TABLE #dep_info  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT fd.FundingID
	   ,SUM(fbd.AmountUSD) AS Total_Approved_Deposit
	   ,COUNT(DISTINCT fbd.DepositID) AS Num_Approved_Deposit
FROM #fid_deposit fd
LEFT JOIN DWH_dbo.Fact_BillingDeposit fbd WITH(NOLOCK) ON fd.FundingID = fbd.FundingID AND fbd.PaymentStatusID =2 -- Approved
GROUP BY fd.FundingID

IF OBJECT_ID('tempdb..#final_dep') IS NOT NULL DROP TABLE #final_dep
CREATE TABLE #final_dep  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT dp.FundingID
	  ,dp.Total_Users
	  ,dp.Group_Type
	  ,dp.Last_Deposit_Date
	  ,di.Total_Approved_Deposit
	  ,di.Num_Approved_Deposit 
FROM #fid_deposit dp
LEFT JOIN #dep_info di ON dp.FundingID = di.FundingID

/********** Step 02 **********/
/********** Funding ID - Withdraw **********/
IF OBJECT_ID('tempdb..#fid_Withdraw') IS NOT NULL DROP TABLE #fid_Withdraw
CREATE TABLE #fid_Withdraw  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT fbw.FundingID
	  ,COUNT(DISTINCT fbw.CID) AS 'Total_Users'	
	  ,CASE WHEN COUNT(DISTINCT fbw.CID) <= 20 THEN '5-20' 
			WHEN COUNT(DISTINCT fbw.CID) BETWEEN 21 AND 50 THEN '21-50'
			WHEN COUNT(DISTINCT fbw.CID) BETWEEN 51 AND 500 THEN '51-500'
			WHEN COUNT(DISTINCT fbw.CID)> 500 THEN '500+ '
			END AS 'Group_Type'
	  ,MAX(fbw.ModificationDate) AS 'Last_Withdraw_Date'	
FROM DWH_dbo.Fact_BillingWithdraw fbw WITH(NOLOCK)
JOIN DWH_dbo.Dim_Customer dc WITH(NOLOCK) ON dc.RealCID = fbw.CID AND dc.IsValidCustomer = 1 AND dc.IsDepositor = 1 AND dc.VerificationLevelID >=2
WHERE fbw.Amount_WithdrawToFunding >0
AND fbw.FundingID NOT IN (1,2,3,4,5,6,7)
GROUP BY fbw.FundingID
HAVING COUNT(DISTINCT fbw.CID) >= 2 

IF OBJECT_ID('tempdb..#Withdraw_info') IS NOT NULL DROP TABLE #Withdraw_info
CREATE TABLE #Withdraw_info  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT fw.FundingID
	   ,SUM(fbw.Amount_WithdrawToFunding) AS Total_Approved_Withdraw
	   ,COUNT(DISTINCT fbw.WithdrawID) AS Num_Approved_Withdraw 
FROM #fid_Withdraw fw
LEFT JOIN DWH_dbo.Fact_BillingWithdraw fbw WITH(NOLOCK) ON fw.FundingID = fbw.FundingID AND fbw.CashoutStatusID_Funding = 3 -- Approved 
GROUP BY fw.FundingID

IF OBJECT_ID('tempdb..#final_Withdraw') IS NOT NULL DROP TABLE #final_Withdraw
CREATE TABLE #final_Withdraw  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT fw.FundingID
	  ,fw.Total_Users
	  ,fw.Group_Type
	  ,fw.Last_Withdraw_Date
	  ,wi.Total_Approved_Withdraw
	  ,wi.Num_Approved_Withdraw 
FROM #fid_Withdraw fw
LEFT JOIN #Withdraw_info wi ON fw.FundingID = wi.FundingID 

/********** Step 03 **********/
/********** Adding Funding Data from XML - Is the FID Blocked? **********/
IF OBJECT_ID('tempdb..#funding_XML_Full_List') IS NOT NULL DROP TABLE #funding_XML_Full_List
CREATE TABLE #funding_XML_Full_List  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT bf.FundingID       
	  ,bf.IsBlocked
FROM [BI_DB_dbo].[External_etoro_Billing_Funding] bf
WHERE bf.FundingID NOT IN (1,2,3,4,5,6,7)

/********** Step 04 **********/
/********** Final Tables - Deposit and Withdraw **********/
IF OBJECT_ID('tempdb..#finaldep') IS NOT NULL DROP TABLE #finaldep
CREATE TABLE #finaldep  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT fd.FundingID
	  ,fl.IsBlocked
	  ,fd.Total_Users
	  ,fd.Group_Type
	  ,fd.Last_Deposit_Date
	  ,fd.Total_Approved_Deposit
	  ,fd.Num_Approved_Deposit	
FROM #final_dep fd
LEFT JOIN #funding_XML_Full_List fl ON fd.FundingID= fl.FundingID

IF OBJECT_ID('tempdb..#finalWithdraw') IS NOT NULL DROP TABLE #finalWithdraw
CREATE TABLE #finalWithdraw  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT fw.FundingID
	  ,fl.IsBlocked
	  ,fw.Total_Users
	  ,fw.Group_Type
	  ,fw.Last_Withdraw_Date
	  ,fw.Total_Approved_Withdraw
	  ,fw.Num_Approved_Withdraw  
FROM #final_Withdraw fw
LEFT JOIN #funding_XML_Full_List fl ON fw.FundingID= fl.FundingID

/********** Step 05 **********/
/********** Full Data Deposit **********/
IF OBJECT_ID('tempdb..#fid_full_data') IS NOT NULL DROP TABLE #fid_full_data
CREATE TABLE #fid_full_data  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT DISTINCT fbd.FundingID
	  ,dc.RealCID AS CID	
	  ,dc.GCID	
	  ,dc.UserName
	  ,CAST(dc.BirthDate AS DATE) AS BirthDate
	  ,dpv.PhoneVerifiedName
	  ,dc.RegisteredReal 
	  ,dc.FirstDepositDate
	  ,dc.VerificationLevelID
	  ,dc1.Name AS Country
	  ,dr.Name AS Regulation
	  ,dps.Name AS PlayerStatus
	  ,dpsr.Name AS PlayerStatusReason
	  ,dpssr.PlayerStatusSubReasonName
	  ,dpl.Name AS Club
	  ,dc.AffiliateID	
	  ,dc.City
	  ,dc.Zip
	  ,dc.BuildingNumber
	  ,dc.Gender
	  ,dems.EvMatchStatusName
	  ,dc.HasWallet
	  ,mda.AccountProgram 
FROM DWH_dbo.Fact_BillingDeposit fbd WITH(NOLOCK)
JOIN DWH_dbo.Dim_Customer dc WITH(NOLOCK) ON dc.RealCID = fbd.CID AND dc.IsValidCustomer =1 AND dc.IsDepositor =1 AND dc.VerificationLevelID >=2			
JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.DWHCountryID
JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN DWH_dbo.Dim_PhoneVerified dpv WITH(NOLOCK) ON dc.PhoneVerifiedID = dpv.PhoneVerifiedID
LEFT JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr WITH(NOLOCK) ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
LEFT JOIN DWH_dbo.Dim_PlayerStatusSubReasons dpssr WITH(NOLOCK) ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
LEFT JOIN DWH_dbo.Dim_EvMatchStatus dems ON dems.EvMatchStatusID = dc.EvMatchStatus
LEFT JOIN eMoney_dbo.eMoney_Dim_Account mda ON dc.RealCID = mda.CID AND mda.IsValidETM =1 AND mda.IsTestAccount =0
WHERE fbd.FundingID IN (SELECT fd.FundingID FROM #fid_deposit fd)

-- Liabilities
IF OBJECT_ID('tempdb..#dep_liabilities') IS NOT NULL DROP TABLE #dep_liabilities
CREATE TABLE #dep_liabilities  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT ff.*
	  ,vl.Liabilities
	  ,vl.RealizedEquity
	  ,vl.PositionPnL
	  ,ISNULL(vl.Liabilities, 0) + ISNULL(vl.ActualNWA, 0) AS TotalEquity
FROM #fid_full_data ff
LEFT JOIN DWH_dbo.V_Liabilities vl ON ff.CID = vl.CID AND vl.DateID = @DateID

-- Risk Alert
IF OBJECT_ID('tempdb..#riskalert') IS NOT NULL DROP TABLE #riskalert
CREATE TABLE #riskalert  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT * 
FROM 
(SELECT h.Id as AlertID,
            h.CID,
			h.CreationDate,
			h.ModificationDate,
			d.Name [AlertType],
			d.Description [AlertTypeDescription],
			dc.Name [CategoryName],
			dt.Name [TriggerType],
			st.Name [StatusType],
			ds.Name[StatusReason], 
			ROW_NUMBER() OVER (PARTITION BY h.CID ORDER BY h.ModificationDate DESC) AS RN
FROM [BI_DB_dbo].[External_AlertServiceDB_Alert_Alert] h
	 LEFT JOIN [BI_DB_dbo].[External_AlertServiceDB_Configuration_AlertTemplate] a ON h.TemplateID=a.Id
     LEFT JOIN [BI_DB_dbo].[External_AlertServiceDB_Dictionary_AlertType] d ON d.Id=a.AlertTypeID
     LEFT JOIN [BI_DB_dbo].[External_AlertServiceDB_Dictionary_Category] dc ON dc.Id=a.CategoryID
     LEFT JOIN [BI_DB_dbo].[External_AlertServiceDB_Dictionary_TriggerType] dt ON dt.Id=a.TriggerType
     LEFT JOIN [BI_DB_dbo].[External_AlertServiceDB_Configuration_AlertStatus] ca ON h.StatusID=ca.Id
     LEFT JOIN [BI_DB_dbo].[External_AlertServiceDB_Dictionary_StatusType] st ON st.Id=ca.StatusTypeID
     LEFT JOIN [BI_DB_dbo].[External_AlertServiceDB_Dictionary_StatusReason] ds ON ds.Id=ca.StatusReasonID
)a
WHERE a.RN =1


-- Final Full Data - Deposit
IF OBJECT_ID('tempdb..#finalfulldatadep') IS NOT NULL DROP TABLE #finalfulldatadep
CREATE TABLE #finalfulldatadep  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT dd.FundingID
	  ,dd.CID
	  ,dd.GCID
	  ,dd.UserName
	  ,dd.BirthDate
	  ,dd.PhoneVerifiedName
	  ,dd.RegisteredReal
	  ,dd.FirstDepositDate
	  ,dd.VerificationLevelID
	  ,dd.Country
	  ,dd.Regulation
	  ,dd.PlayerStatus
	  ,dd.PlayerStatusReason
	  ,dd.PlayerStatusSubReasonName
	  ,dd.Club
	  ,dd.AffiliateID
	  ,dd.City
	  ,dd.Zip
	  ,dd.BuildingNumber
	  ,dd.Gender
	  ,dd.EvMatchStatusName
	  ,dd.HasWallet
	  ,dd.AccountProgram
	  ,dd.Liabilities
	  ,dd.RealizedEquity
	  ,dd.PositionPnL
	  ,dd.TotalEquity
	  ,rr.AlertID
	  ,rr.CreationDate
      ,rr.ModificationDate
      ,rr.[AlertType]
      ,rr.[AlertTypeDescription]
      ,rr.[CategoryName]
      ,rr.[TriggerType]
      ,rr.[StatusType]
      ,rr.[StatusReason]
FROM #dep_liabilities dd
LEFT JOIN #riskalert rr ON dd.CID = rr.CID

/********** Step 06 **********/
/********** Full Data Withdraw **********/
IF OBJECT_ID('tempdb..#fid_full_data_withdraw') IS NOT NULL DROP TABLE #fid_full_data_withdraw
CREATE TABLE #fid_full_data_withdraw  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT DISTINCT fbw.FundingID
	  ,dc.RealCID AS CID	
	  ,dc.GCID
	  ,dc.UserName
	  ,CAST(dc.BirthDate AS DATE) AS BirthDate
	  ,dpv.PhoneVerifiedName
	  ,dc.RegisteredReal 
	  ,dc.FirstDepositDate
	  ,dc.VerificationLevelID
	  ,dc1.Name AS Country
	  ,dr.Name AS Regulation
	  ,dps.Name AS PlayerStatus
	  ,dpsr.Name AS PlayerStatusReason
	  ,dpssr.PlayerStatusSubReasonName
	  ,dpl.Name AS Club
	  ,dc.AffiliateID
	  ,dc.City
	  ,dc.Zip
	  ,dc.BuildingNumber
	  ,dc.Gender	
	  ,dems.EvMatchStatusName
	  ,dc.HasWallet
	  ,mda.AccountProgram 
FROM DWH_dbo.Fact_BillingWithdraw fbw WITH(NOLOCK)
JOIN DWH_dbo.Dim_Customer dc WITH(NOLOCK) ON dc.RealCID = fbw.CID AND dc.IsValidCustomer =1 AND dc.IsDepositor =1 AND dc.VerificationLevelID >=2			
JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.DWHCountryID
JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN DWH_dbo.Dim_PhoneVerified dpv WITH(NOLOCK) ON dc.PhoneVerifiedID = dpv.PhoneVerifiedID
LEFT JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr WITH(NOLOCK) ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
LEFT JOIN DWH_dbo.Dim_PlayerStatusSubReasons dpssr WITH(NOLOCK) ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
LEFT JOIN DWH_dbo.Dim_EvMatchStatus dems ON dems.EvMatchStatusID = dc.EvMatchStatus
LEFT JOIN eMoney_dbo.eMoney_Dim_Account mda ON dc.RealCID = mda.CID AND mda.IsValidETM =1 AND mda.IsTestAccount =0
WHERE fbw.FundingID IN (SELECT fw.FundingID FROM #fid_Withdraw fw)

-- Liabilities
IF OBJECT_ID('tempdb..#CO_liabilities') IS NOT NULL DROP TABLE #CO_liabilities
CREATE TABLE #CO_liabilities  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT ff.*
	  ,vl.Liabilities
	  ,vl.RealizedEquity
	  ,vl.PositionPnL
	  ,ISNULL(vl.Liabilities, 0) + ISNULL(vl.ActualNWA, 0) AS TotalEquity
FROM #fid_full_data_withdraw ff
LEFT JOIN DWH_dbo.V_Liabilities vl ON ff.CID = vl.CID AND vl.DateID = @DateID

-- Risk Alert
IF OBJECT_ID('tempdb..#fulldataco') IS NOT NULL DROP TABLE #fulldataco
CREATE TABLE #fulldataco  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT cc.FundingID
	  ,cc.CID
	  ,cc.GCID
	  ,cc.UserName
	  ,cc.BirthDate
	  ,cc.PhoneVerifiedName
	  ,cc.RegisteredReal
	  ,cc.FirstDepositDate
	  ,cc.VerificationLevelID
	  ,cc.Country
	  ,cc.Regulation
	  ,cc.PlayerStatus
	  ,cc.PlayerStatusReason
	  ,cc.PlayerStatusSubReasonName
	  ,cc.Club
	  ,cc.AffiliateID
	  ,cc.City
	  ,cc.Zip
	  ,cc.BuildingNumber
	  ,cc.Gender
	  ,cc.EvMatchStatusName
	  ,cc.HasWallet
	  ,cc.AccountProgram
	  ,cc.Liabilities
	  ,cc.RealizedEquity
	  ,cc.PositionPnL
	  ,cc.TotalEquity
	  ,rr.AlertID
	  ,rr.CreationDate
      ,rr.ModificationDate
      ,rr.[AlertType]
      ,rr.[AlertTypeDescription]
      ,rr.[CategoryName]
      ,rr.[TriggerType]
      ,rr.[StatusType]
      ,rr.[StatusReason] 
FROM #CO_liabilities cc
LEFT JOIN #riskalert rr ON cc.CID = rr.CID

/********** Step 07 **********/
/********** Same IP Cal **********/
IF OBJECT_ID('tempdb..#SameIP') IS NOT NULL DROP TABLE #SameIP
CREATE TABLE #SameIP  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT COUNT(DISTINCT dc.RealCID) AS NumOfClientsSameIP
	  ,dc.IP 
	  ,GETDATE() AS UpdateDate
FROM DWH_dbo.Dim_Customer dc
WHERE dc.IsValidCustomer =1
AND dc.IsDepositor =1
AND dc.VerificationLevelID = 3
GROUP BY dc.IP
HAVING COUNT(DISTINCT dc.RealCID) > 1

/********** Step 08 **********/
/********** IP Full Data **********/
IF OBJECT_ID('tempdb..#SameIP_Fulldata') IS NOT NULL DROP TABLE #SameIP_Fulldata
CREATE TABLE #SameIP_Fulldata  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT DISTINCT dc.RealCID AS CID 
	  ,CHECKSUM(ss.IP) AS HashIP
	  ,ss.UpdateDate
FROM #SameIP ss
JOIN DWH_dbo.Dim_Customer dc ON ss.IP = dc.IP
WHERE dc.IsValidCustomer =1
AND dc.IsDepositor =1
AND dc.VerificationLevelID = 3

/********** Step 09 **********/
/********** Device ID Cal **********/
IF OBJECT_ID('tempdb..#DeviceID') IS NOT NULL DROP TABLE #DeviceID
CREATE TABLE #DeviceID  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT COUNT(DISTINCT dh.RealCid) AS NumOfClientsSameDeviceID
      ,dh.ClientDeviceId
	  ,GETDATE() AS UpdateDate
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.STS_User_Operations_Data_History dh ON dh.RealCid = dc.RealCID
WHERE dh.DateID >= 20230101
AND dh.ClientDeviceId <> '00000000-0000-0000-0000-000000000000'
GROUP BY dh.ClientDeviceId
HAVING COUNT(DISTINCT dh.RealCid) >1

/********** Step 10 **********/
/********** Device ID Full data **********/
IF OBJECT_ID('tempdb..#DeviceID_Fulldata') IS NOT NULL DROP TABLE #DeviceID_Fulldata
CREATE TABLE #DeviceID_Fulldata  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT DISTINCT dh.RealCid AS CID
	  ,dd.ClientDeviceId
	  ,rr.AlertID
	  ,rr.CreationDate
      ,rr.ModificationDate
      ,rr.[AlertType]
      ,rr.[AlertTypeDescription]
      ,rr.[CategoryName]
      ,rr.[TriggerType]
      ,rr.[StatusType]
      ,rr.[StatusReason]
	  ,dd.UpdateDate 
FROM #DeviceID dd
JOIN DWH_dbo.STS_User_Operations_Data_History dh ON dd.ClientDeviceId = dh.ClientDeviceId
AND dh.ClientDeviceId <> '00000000-0000-0000-0000-000000000000'
LEFT JOIN #riskalert rr ON rr.CID = dh.RealCid
WHERE dh.DateID >= 20230101


/********** Step 11 **********/
/********** Truncate and Insert into Table - Deposit FID **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep

INSERT INTO BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep
	   (FundingID
	  ,IsBlocked
	  ,Total_Users
	  ,Group_Type
	  ,Last_Deposit_Date
	  ,Total_Approved_Deposit
	  ,Num_Approved_Deposit
	  ,UpdateDate)
SELECT FundingID
	  ,IsBlocked
	  ,Total_Users
	  ,Group_Type
	  ,Last_Deposit_Date
	  ,Total_Approved_Deposit
	  ,Num_Approved_Deposit
	  ,GETDATE() AS UpdateDate
FROM #finaldep  

/********** Step 12 **********/
/********** Truncate and Insert into Table - Withdraw FID **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw

INSERT INTO BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw
	   (FundingID
	   ,IsBlocked
	  ,Total_Users
	  ,Group_Type
	  ,Last_Withdraw_Date
	  ,Total_Approved_Withdraw
	  ,Num_Approved_Withdraw
	  ,UpdateDate)
SELECT FundingID
	  ,Total_Users
	  ,IsBlocked
	  ,Group_Type
	  ,Last_Withdraw_Date
	  ,Total_Approved_Withdraw
	  ,Num_Approved_Withdraw
	  ,GETDATE() AS UpdateDate
FROM #finalWithdraw   

/********** Step 13 **********/
/********** Truncate and Insert into Table - Deposit FID Full Data **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep_fulldata

INSERT INTO BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep_fulldata
	  (FundingID
	  ,CID
	  ,GCID
	  ,UserName
	  ,BirthDate
	  ,PhoneVerifiedName
	  ,RegisteredReal
	  ,FirstDepositDate
	  ,VerificationLevelID
	  ,Country
	  ,Regulation
	  ,PlayerStatus
	  ,PlayerStatusReason
	  ,PlayerStatusSubReasonName
	  ,Club
	  ,AffiliateID
	  ,City
	  ,Zip
	  ,BuildingNumber
	  ,Gender
	  ,EvMatchStatusName
	  ,HasWallet
	  ,AccountProgram
	  ,Liabilities
	  ,RealizedEquity
	  ,PositionPnL
	  ,TotalEquity
	  ,AlertID
	  ,CreationDate
      ,ModificationDate
      ,[AlertType]
      ,[AlertTypeDescription]
      ,[CategoryName]
      ,[TriggerType]
      ,[StatusType]
      ,[StatusReason]
	  ,UpdateDate)
SELECT FundingID
	  ,CID
	  ,GCID
	  ,UserName
	  ,BirthDate
	  ,PhoneVerifiedName
	  ,RegisteredReal
	  ,FirstDepositDate
	  ,VerificationLevelID
	  ,Country
	  ,Regulation
	  ,PlayerStatus
	  ,PlayerStatusReason
	  ,PlayerStatusSubReasonName
	  ,Club
	  ,AffiliateID
	  ,City
	  ,Zip
	  ,BuildingNumber
	  ,Gender
	  ,EvMatchStatusName
	  ,HasWallet
	  ,AccountProgram
	  ,Liabilities
	  ,RealizedEquity
	  ,PositionPnL
	  ,TotalEquity
	  ,AlertID
	  ,CreationDate
      ,ModificationDate
      ,[AlertType]
      ,[AlertTypeDescription]
      ,[CategoryName]
      ,[TriggerType]
      ,[StatusType]
      ,[StatusReason]
	  ,GETDATE() AS UpdateDate
FROM #finalfulldatadep   


/********** Step 14 **********/
/********** Truncate and Insert into Table - Withdraw FID Full Data **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata

INSERT INTO BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata
	  (FundingID
	  ,CID
	  ,GCID
	  ,UserName
	  ,BirthDate
	  ,PhoneVerifiedName
	  ,RegisteredReal
	  ,FirstDepositDate
	  ,VerificationLevelID
	  ,Country
	  ,Regulation
	  ,PlayerStatus
	  ,PlayerStatusReason
	  ,PlayerStatusSubReasonName
	  ,Club
	  ,AffiliateID
	  ,City
	  ,Zip
	  ,BuildingNumber
	  ,Gender
	  ,EvMatchStatusName
	  ,HasWallet
	  ,AccountProgram
	  ,Liabilities
	  ,RealizedEquity
	  ,PositionPnL
	  ,TotalEquity
	  ,AlertID
	  ,CreationDate
      ,ModificationDate
      ,[AlertType]
      ,[AlertTypeDescription]
      ,[CategoryName]
      ,[TriggerType]
      ,[StatusType]
      ,[StatusReason]
	  ,UpdateDate)
SELECT FundingID
	  ,CID
	  ,GCID
	  ,UserName
	  ,BirthDate
	  ,PhoneVerifiedName
	  ,RegisteredReal
	  ,FirstDepositDate
	  ,VerificationLevelID
	  ,Country
	  ,Regulation
	  ,PlayerStatus
	  ,PlayerStatusReason
	  ,PlayerStatusSubReasonName
	  ,Club
	  ,AffiliateID
	  ,City
	  ,Zip
	  ,BuildingNumber
	  ,Gender
	  ,EvMatchStatusName
	  ,HasWallet
	  ,AccountProgram
	  ,Liabilities
	  ,RealizedEquity
	  ,PositionPnL
	  ,TotalEquity
	  ,AlertID
	  ,CreationDate
      ,ModificationDate
      ,[AlertType]
      ,[AlertTypeDescription]
      ,[CategoryName]
      ,[TriggerType]
      ,[StatusType]
      ,[StatusReason]
	  ,GETDATE() AS UpdateDate
FROM #fulldataco  

/********** Step 14 **********/
/********** Truncate and Insert into Table - DeviceID **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID

INSERT INTO BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID
	  (NumOfClientsSameDeviceID
	  ,ClientDeviceId
	  ,UpdateDate)
SELECT NumOfClientsSameDeviceID
	  ,ClientDeviceId
	  ,UpdateDate
FROM #DeviceID 
/********** Step 15 **********/
/********** Truncate and Insert into Table - DeviceID Full Data **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID_FullData

INSERT INTO BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID_FullData
	  (CID
	  ,ClientDeviceId
	  ,AlertID
	  ,CreationDate
      ,ModificationDate
      ,[AlertType]
      ,[AlertTypeDescription]
      ,[CategoryName]
      ,[TriggerType]
      ,[StatusType]
      ,[StatusReason]
	  ,UpdateDate)
SELECT CID
	  ,ClientDeviceId
	  ,AlertID
	  ,CreationDate
      ,ModificationDate
      ,[AlertType]
      ,[AlertTypeDescription]
      ,[CategoryName]
      ,[TriggerType]
      ,[StatusType]
      ,[StatusReason]
	  ,UpdateDate
FROM #DeviceID_Fulldata  

/********** Step 16 **********/
/********** Truncate and Insert into Table - IP **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP

INSERT INTO BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP
	  (NumOfClientsSameIP
	  ,IP
	  ,UpdateDate)
SELECT NumOfClientsSameIP
	  ,IP
	  ,UpdateDate
FROM #SameIP 

/********** Step 17 **********/
/********** Truncate and Insert into Table - IP Full Data **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData
INSERT INTO BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData
	  (CID
	  ,HashIP
	  ,UpdateDate)
SELECT CID
	  ,HashIP
	  ,UpdateDate
FROM #SameIP_Fulldata 

/********** END **********/
 END
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_AML_Multiple_Accounts` | synapse_sp | BI_DB_dbo | SP_AML_Multiple_Accounts | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_AML_Multiple_Accounts.sql` |
| `DWH_dbo.Fact_BillingDeposit` | synapse | DWH_dbo | Fact_BillingDeposit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Fact_BillingWithdraw` | synapse | DWH_dbo | Fact_BillingWithdraw | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `BI_DB_dbo.External_etoro_Billing_Funding` | unresolved | BI_DB_dbo | External_etoro_Billing_Funding | `—` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `DWH_dbo.Dim_PlayerStatus` | synapse | DWH_dbo | Dim_PlayerStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `DWH_dbo.Dim_PlayerLevel` | synapse | DWH_dbo | Dim_PlayerLevel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `DWH_dbo.Dim_PhoneVerified` | synapse | DWH_dbo | Dim_PhoneVerified | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PhoneVerified.md` |
| `DWH_dbo.Dim_PlayerStatusReasons` | synapse | DWH_dbo | Dim_PlayerStatusReasons | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `DWH_dbo.Dim_PlayerStatusSubReasons` | synapse | DWH_dbo | Dim_PlayerStatusSubReasons | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `DWH_dbo.Dim_EvMatchStatus` | synapse | DWH_dbo | Dim_EvMatchStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_EvMatchStatus.md` |
| `eMoney_dbo.eMoney_Dim_Account` | synapse | eMoney_dbo | eMoney_Dim_Account | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |
| `DWH_dbo.V_Liabilities` | synapse | DWH_dbo | V_Liabilities | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md` |
| `BI_DB_dbo.External_AlertServiceDB_Alert_Alert` | unresolved | BI_DB_dbo | External_AlertServiceDB_Alert_Alert | `—` |
| `BI_DB_dbo.External_AlertServiceDB_Configuration_AlertTemplate` | unresolved | BI_DB_dbo | External_AlertServiceDB_Configuration_AlertTemplate | `—` |
| `BI_DB_dbo.External_AlertServiceDB_Dictionary_AlertType` | unresolved | BI_DB_dbo | External_AlertServiceDB_Dictionary_AlertType | `—` |
| `BI_DB_dbo.External_AlertServiceDB_Dictionary_Category` | unresolved | BI_DB_dbo | External_AlertServiceDB_Dictionary_Category | `—` |
| `BI_DB_dbo.External_AlertServiceDB_Dictionary_TriggerType` | unresolved | BI_DB_dbo | External_AlertServiceDB_Dictionary_TriggerType | `—` |
| `BI_DB_dbo.External_AlertServiceDB_Configuration_AlertStatus` | unresolved | BI_DB_dbo | External_AlertServiceDB_Configuration_AlertStatus | `—` |
| `BI_DB_dbo.External_AlertServiceDB_Dictionary_StatusType` | unresolved | BI_DB_dbo | External_AlertServiceDB_Dictionary_StatusType | `—` |
| `BI_DB_dbo.External_AlertServiceDB_Dictionary_StatusReason` | unresolved | BI_DB_dbo | External_AlertServiceDB_Dictionary_StatusReason | `—` |
| `DWH_dbo.STS_User_Operations_Data_History` | synapse | DWH_dbo | STS_User_Operations_Data_History | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\STS_User_Operations_Data_History.md` |
