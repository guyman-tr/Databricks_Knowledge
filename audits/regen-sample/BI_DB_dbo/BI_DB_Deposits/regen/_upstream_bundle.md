# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_Deposits`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_Deposits.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_Deposits]
(
	[DepositID] [bigint] NULL,
	[CID] [int] NULL,
	[FundingID] [bigint] NULL,
	[FundingType] [nvarchar](50) NULL,
	[CurrencyID] [bigint] NULL,
	[PaymentStatusID] [bigint] NULL,
	[ManagerID] [bigint] NULL,
	[RiskManagementStatusID] [bigint] NULL,
	[Amount] [money] NULL,
	[ExchangeRate] [numeric](16, 8) NULL,
	[ModificationDate] [datetime] NULL,
	[TransactionID] [nvarchar](50) NULL,
	[IPAddress] [numeric](18, 0) NULL,
	[Approved] [bit] NULL,
	[Commission] [money] NULL,
	[PaymentDate] [datetime] NULL,
	[ClearingHouseEffectiveDate] [datetime] NULL,
	[OldPaymentID] [bigint] NULL,
	[IsFTD] [bit] NULL,
	[ProcessorValueDate] [datetime] NULL,
	[RefundVerificationCode] [nvarchar](50) NULL,
	[DepotID] [bigint] NULL,
	[MatchStatusID] [bigint] NULL,
	[FunnelID] [bigint] NULL,
	[Code] [nvarchar](50) NULL,
	[ExTransactionID] [nvarchar](50) NULL,
	[PaymentStatus_PaymentStatusID] [bigint] NULL,
	[PaymentStatus_Name] [nvarchar](50) NULL,
	[RiskManagementStatus_RiskManagementStatusID] [bigint] NULL,
	[RiskManagementStatus_Name] [nvarchar](50) NULL,
	[Channel] [nvarchar](50) NULL,
	[SubChannel] [nvarchar](100) NULL,
	[Region] [nvarchar](50) NULL,
	[Country] [nvarchar](50) NULL,
	[FirstDepositAttempt] [datetime] NULL,
	[FirstDepositDate] [datetime] NULL,
	[Registered] [datetime] NULL,
	[SerialID] [bigint] NULL,
	[Funnel] [nvarchar](50) NULL,
	[FunnelFrom] [nvarchar](50) NULL,
	[AcquisitionFunnel] [nvarchar](50) NULL,
	[BinCode] [bigint] NULL,
	[CreditCardType] [nvarchar](50) NULL,
	[CardSubType] [nvarchar](50) NULL,
	[CardCategory] [nvarchar](50) NULL,
	[BINCountry] [nvarchar](50) NULL,
	[DepoName] [nvarchar](50) NULL,
	[ResponseName] [nvarchar](255) NULL,
	[ResponseRN] [bigint] NULL,
	[Date] [date] NULL,
	[DateID] [int] NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[DateID] ASC,
		[DepositID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 11 upstream wiki(s). Read EACH one in full.


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

### Upstream `DWH_dbo.Dim_PaymentStatus` — synapse
- **Resolved as**: `DWH_dbo.Dim_PaymentStatus`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PaymentStatus.md`

# DWH_dbo.Dim_PaymentStatus

> 40-row reference dictionary mapping PaymentStatusID to the deposit/funding transaction outcome code -- covering the complete lifecycle from submission (New, InProcess) through approval (Approved, Confirmed), various decline reasons (fraud, limits, blocked payment methods, country restrictions), chargebacks, refunds, and internal operational states.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PaymentStatus (etoroDB-REAL) |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_Dictionaries_DL_To_Synapse; PaymentStatusID=-1 is a manually-inserted sentinel) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PaymentStatusID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` |
| **UC Format** | parquet |
| **UC Partitioned By** | None (40 rows) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_PaymentStatus` is the lookup table for payment/deposit transaction status codes on the eToro platform. Every deposit or funding transaction carries a PaymentStatusID that identifies where in the payment lifecycle it is, or how it was resolved.

The 40 statuses span 6 functional categories:

| Category | IDs | Examples |
|----------|-----|---------|
| **Active/Pending** | 1, 4, 5, 13, 36 | New, Technical, InProcess, Pending, PendingReview |
| **Success** | 2, 7 | Approved, Confirmed |
| **Generic Decline** | 3, 31-35 | Decline, DeclineBinConflictCountry, DeclineSecurityValidation |
| **Block-based Decline** | 8-12, 14-24, 28-29 | DeclineBlockCard, DeclinedBlockedPayPal, DeclinedBlockedCountry |
| **Chargeback/Refund** | 11, 12, 25-27, 37-39 | Chargeback, Refund, ChargebackReversal, MigratedToDepositTable |
| **Cancellation** | 6 | Canceled |

PaymentStatusID=-1 is a DWH null-sentinel (manually inserted, UpdateDate at midnight vs. 02:12 for SP-loaded rows). PaymentStatusIDs 1-39 are loaded from `etoro_Dictionary_PaymentStatus` by `SP_Dictionaries_DL_To_Synapse`.

---

## 2. Business Logic

### 2.1 Payment Status Lifecycle

**What**: A payment transaction moves through statuses as it is processed. The final status determines the financial outcome.

**Standard flow**:
```
New (1) -> InProcess (5) -> [Approved (2) | Confirmed (7)]
        or -> Technical (4) [processing issue, may retry]
        or -> Pending (13) / PendingReview (36)
        or -> Decline (3) / Declined* (8-24, 28-35)
        or -> Canceled (6)
```

**Post-settlement flows**:
```
Approved/Confirmed -> Chargeback (11) -> ChargebackReversal (37)
                   -> Refund (12) -> RefundReversal (38)
                   -> RefundAsChargeback (26)
                   -> ReversedDeposit (39)
```

### 2.2 Decline Status Taxonomy

**What**: Most decline statuses encode the specific reason for rejection, which is valuable for fraud analytics and payment operations.

**Rules**:
- **Method-specific blocks** (14-24, 28): `DeclinedBlockedPayPal`, `DeclinedBlockedNeteller`, `DeclinedBlockedMoneyBookers`, `DeclinedBlockedWebMoney`, `DeclinedBlockedGiropay`, `DeclinedBlockedELV`, `DeclinedBlockedDirect24`, `DeclinedBlockedSofort` -- the customer's specific payment method is blocked by eToro's risk rules.
- **Country blocks** (18, 29, 34): `DeclinedBlockedCountry`, `DeclinedDepositCountryConflict`, `DeclineHighRiskCountry` -- blocked due to regulatory or risk reasons related to the customer's country.
- **Limit blocks** (10, 20, 30): `DeclineMemberLimits`, `DeclinedOverTheLimit`, `DeclinedOverTheLimitSingleDeposit` -- deposit exceeds the customer's allowed limits.
- **Fraud/risk** (9, 19, 31, 32, 35): `DeclineBadBins`, `DeclinedHighRiskCID`, `DeclineBinConflictCountry`, `DeclineSecurityValidation`, `DeclineByRRE` -- flagged by fraud or risk systems.
- **FTD limit** (33): `DeclineFtdOverTheLimit` -- first-time deposit exceeds allowed amount.

### 2.3 PaymentStatusID=-1 Sentinel

**Rule**: PaymentStatusID=-1 (Name='N/A') is a manually-inserted sentinel row. Its UpdateDate is `2026-03-11 00:00:00` (midnight), compared to `02:12` for SP-loaded rows. `DWHPaymentStatusID=0` for this row (vs. `PaymentStatusID` for all others). Always filter `WHERE PaymentStatusID > 0` for real status analysis.

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Successful deposits | `WHERE PaymentStatusID IN (2, 7)` |
| All declined payments | `WHERE Name LIKE 'Decline%' OR Name LIKE 'Declined%'` or `WHERE PaymentStatusID IN (3, 8, 9, 10, 14-24, 28-35)` |
| Payments in progress | `WHERE PaymentStatusID IN (1, 4, 5, 13, 36)` |
| Chargebacks and refunds | `WHERE PaymentStatusID IN (11, 12, 26, 37, 38, 39)` |
| Exclude sentinel | `WHERE PaymentStatusID > 0` (or `<> -1`) |

### 3.2 Gotchas

- **PaymentStatusID=-1 has DWHPaymentStatusID=0**: Anomaly -- the -1 row was manually inserted (not by SP_Dictionaries) and has DWHPaymentStatusID=0 instead of -1. Indicates this is a special-case sentinel.
- **UpdateDate is GETDATE() at load**: Does not reflect production modification date.
- **Method-blocked declines reference legacy payment methods**: `DeclinedBlockedMoneyBookers`, `DeclinedBlockedGiropay`, `DeclinedBlockedELV`, `DeclinedBlockedDirect24`, `DeclinedBlockedSofort` -- some of these payment methods may no longer be active on the platform.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — Dictionary (upstream wiki) | `(Tier 1 — Dictionary.PaymentStatus)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentStatusID | int | NO | Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally. (Tier 1 — Dictionary.PaymentStatus) |
| 2 | Name | varchar(50) | NO | Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. (Tier 1 — Dictionary.PaymentStatus) |
| 3 | DWHPaymentStatusID | int | YES | Always equal to PaymentStatusID for IDs >= 1. Exception: PaymentStatusID=-1 has DWHPaymentStatusID=0 (manual sentinel). Standard DWH DWH{X}ID pattern. Do not use for JOINs. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded to 1 for all SP-loaded rows. Conveys no information. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() at load time for SP-loaded rows; midnight timestamp for PaymentStatusID=-1 (manually inserted). (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL load timestamp -- GETDATE() at load time (same as UpdateDate). Midnight for PaymentStatusID=-1. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PaymentStatusID | etoro.Dictionary.PaymentStatus | PaymentStatusID | passthrough (IDs >= 1); -1 row is manual sentinel |
| Name | etoro.Dictionary.PaymentStatus | Name | passthrough |
| DWHPaymentStatusID | etoro.Dictionary.PaymentStatus | PaymentStatusID | rename (= PaymentStatusID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.PaymentStatus  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_PaymentStatus
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_PaymentStatus  (40 rows; 39 from SP + 1 manual sentinel ID=-1)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_PaymentStatus/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Deposit/payment fact tables | PaymentStatusID | Every deposit transaction has a PaymentStatusID |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP |

---

## 7. Sample Queries

### 7.1 Count deposits by status category

```sql
SELECT
    ps.PaymentStatusID,
    ps.Name AS PaymentStatus,
    COUNT(DISTINCT f.TransactionID) AS TransactionCount
FROM [DWH_dbo].[SomePaymentFact] f
JOIN [DWH_dbo].[Dim_PaymentStatus] ps ON f.PaymentStatusID = ps.PaymentStatusID
WHERE ps.PaymentStatusID > 0
GROUP BY ps.PaymentStatusID, ps.Name
ORDER BY TransactionCount DESC;
```

### 7.2 Decline rate by method-specific block

```sql
SELECT
    ps.Name AS DeclineReason,
    COUNT(DISTINCT f.TransactionID) AS DeclineCount
FROM [DWH_dbo].[SomePaymentFact] f
JOIN [DWH_dbo].[Dim_PaymentStatus] ps ON f.PaymentStatusID = ps.PaymentStatusID
WHERE ps.Name LIKE 'Declined%' OR ps.Name LIKE 'Decline%'
GROUP BY ps.Name
ORDER BY DeclineCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.6/10 (★★★★☆) | Phases: 6/14 (Simple Dictionary Fast-Path)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 6/6, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PaymentStatus | Type: Table | Production Source: etoro.Dictionary.PaymentStatus*


### Upstream `DWH_dbo.Dim_Funnel` — synapse
- **Resolved as**: `DWH_dbo.Dim_Funnel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Funnel.md`

# DWH_dbo.Dim_Funnel

> Acquisition funnel dimension - maps funnel IDs to the channel or product surface through which eToro customers registered, with platform classification. Used in customer, deposit, and action analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Funnel |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Funnel` is an acquisition channel dimension mapping 129 funnel IDs (range -9 to 130) to the registration surface or product entry point through which an eToro customer first arrived. Funnels represent web pages, mobile apps, partner sites, and internal tools.

**FunnelID=-9 (AutomationTest)** and **FunnelID=0 (Unknown)** are special sentinel values. SP_Dim_Customer uses `ISNULL(FunnelID, 0)` coercing NULLs to 0 (Unknown).

`PlatformID` classifies the broad channel:
- 0 = Unspecified/internal (AutomationTest, Unknown, Sit&Play, Mobile generic, BackOffice, etc.)
- 1 = Web (eToro Client, Web Trader, Web Registration, Open Book, Cashier, eToro Website, etc.)
- 2 = iOS (iOS eToro Trader)
- 3 = Android (Android eToro Trader, Android Trade Alerts)

The dimension is actively consumed by `Dim_Customer` (registration funnel for each customer), `Fact_BillingDeposit` (funnel at deposit time), and `Fact_CustomerAction`.

---

## 2. Business Logic

### 2.1 Funnel Channel Classification

**What**: Funnels represent the specific registration or entry channel for a customer. PlatformID provides a coarser platform grouping.

**Columns Involved**: `FunnelID`, `Name`, `PlatformID`

**Rules**:
- Web funnels (PlatformID=1): "eToro Client", "Web Trader", "Web Registration", "Open Book", "Cashier", "eToro Website", "Landing Page", "eToroUSA Website", "eToroPartners Website"
- iOS funnels (PlatformID=2): "iOS eToro Trader"
- Android funnels (PlatformID=3): "Android eToro Trader", "Android Trade Alerts"
- Unspecified/internal (PlatformID=0): "AutomationTest" (FunnelID=-9), "Unknown" (FunnelID=0), "Mobile" (generic), "BackOffice", "Copy.me", "Sit & Play"

**Key funnels observed**:
```
-9  | AutomationTest          | 0 (internal test)
0   | Unknown                 | 0 (null sentinel)
1   | eToro Client            | 1 (web)
2   | Web Trader              | 1 (web)
3   | Web Registration        | 1 (web)
6   | Mobile                  | 0 (generic mobile)
15  | Android eToro Trader    | 3 (Android)
17  | iOS eToro Trader        | 2 (iOS)
18  | eToroUSA Website        | 1 (web, US market)
19  | eToroPartners Website   | 1 (web, partners)
```

### 2.2 Null-Sentinel Pattern

**What**: FunnelID=0 (Unknown) serves as a null-safe join target.

**Columns Involved**: `FunnelID`

**Rules**:
- SP_Dim_Customer uses `ISNULL(FunnelID, 0) AS FunnelID` to coerce NULLs to 0 before load
- SP_Dim_Customer change detection: `OR ISNULL(dc.FunnelID,0) <> ISNULL(a.FunnelID,0)`
- Fact tables with FunnelID=0 represent customers/transactions where the registration channel is unknown

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (129 rows - appropriate). HEAP index - full scans on all lookups, negligible impact at 129 rows. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 129 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FunnelID to funnel name | `LEFT JOIN DWH_dbo.Dim_Funnel ON FunnelID` |
| Group by platform (Web/iOS/Android) | `GROUP BY PlatformID` with CASE decode |
| Exclude automation/unknown funnels | `WHERE FunnelID > 0` |
| Count customers by acquisition funnel | `JOIN Dim_Customer ON FunnelID GROUP BY Name` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON FunnelID | Customer acquisition channel |
| DWH_dbo.Fact_BillingDeposit | ON FunnelID | Funnel context for deposits |
| DWH_dbo.Fact_CustomerAction | ON FunnelID | Funnel context for customer actions |

### 3.4 Gotchas

- **HEAP index**: Unlike most Dim_ tables with CLUSTERED INDEX, Dim_Funnel uses HEAP. Point-lookups are full scans but negligible at 129 rows.
- **FunnelID=-9 is negative**: AutomationTest has FunnelID=-9. Filters like `WHERE FunnelID > 0` correctly exclude both AutomationTest and Unknown.
- **PlatformID is unresolved**: There is no `Dim_Platform` table in DWH_dbo. PlatformID values (0-3) must be decoded manually or via Dim_PlatformType (if applicable).
- **Name not renamed**: Unlike most Dim_ tables where Name becomes XxxName (e.g., FunnelName), this column stays as `Name`.
- **StatusID hardcoded**: All rows have StatusID=1. No deactivation mechanism visible.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FunnelID | int | NO | Primary key identifying the acquisition funnel. Ranges from -9 (AutomationTest) through 130+. Stored on Customer.CustomerStatic via FK and on Customer.RegistrationRequest at registration time. Also stored on Billing.Deposit for first-deposit attribution. (Tier 1 — Dictionary.Funnel) |
| 2 | Name | varchar(50) | YES | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. (Tier 1 — Dictionary.Funnel) |
| 3 | PlatformID | int | YES | Platform category for this funnel. 0=Unknown/Cross-platform, 1=Web, 2=iOS, 3=Android. Defaults to 0 for server-side or platform-agnostic funnels. Links to Dictionary.Platform for platform name resolution. (Tier 1 — Dictionary.Funnel) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate per run). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | StatusID | int | YES | Hardcoded to 1 for all rows. Likely means active. No Dim_Status table in DWH to decode. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FunnelID | etoro.Dictionary.Funnel | FunnelID | passthrough |
| Name | etoro.Dictionary.Funnel | Name | passthrough |
| PlatformID | etoro.Dictionary.Funnel | PlatformID | passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |
| StatusID | - | - | ETL-computed: hardcoded 1 |

### 5.2 ETL Pipeline

```
etoro.Dictionary.Funnel -> Generic Pipeline -> DWH_staging.etoro_Dictionary_Funnel -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 698) -> DWH_dbo.Dim_Funnel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Funnel | Funnel dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/Funnel/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_Funnel | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds UpdateDate/InsertDate=GETDATE(), StatusID=1. |
| Target | DWH_dbo.Dim_Funnel | 129-row REPLICATE/HEAP funnel dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | FunnelID | Customer acquisition funnel (registration channel) |
| DWH_dbo.Fact_BillingDeposit | FunnelID | Funnel context at deposit time |
| DWH_dbo.Fact_CustomerAction | FunnelID | Funnel context for customer financial actions |

---

## 7. Sample Queries

### 7.1 All active funnels by platform

```sql
SELECT FunnelID, Name,
    CASE PlatformID
        WHEN 0 THEN 'Unspecified/Internal'
        WHEN 1 THEN 'Web'
        WHEN 2 THEN 'iOS'
        WHEN 3 THEN 'Android'
        ELSE 'Unknown'
    END AS PlatformName
FROM DWH_dbo.Dim_Funnel
WHERE FunnelID > 0
ORDER BY PlatformID, FunnelID
```

### 7.2 Customer count by acquisition platform

```sql
SELECT
    CASE f.PlatformID
        WHEN 1 THEN 'Web'
        WHEN 2 THEN 'iOS'
        WHEN 3 THEN 'Android'
        ELSE 'Other'
    END AS Platform,
    COUNT(*) AS CustomerCount
FROM DWH_dbo.Dim_Customer dc
LEFT JOIN DWH_dbo.Dim_Funnel f ON dc.FunnelID = f.FunnelID
WHERE dc.FunnelID > 0
GROUP BY f.PlatformID
ORDER BY CustomerCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 3 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/8, Logic: 8/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Funnel | Type: Table | Production Source: etoro.Dictionary.Funnel*


### Upstream `DWH_dbo.Dim_FundingType` — synapse
- **Resolved as**: `DWH_dbo.Dim_FundingType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md`

# DWH_dbo.Dim_FundingType

> Payment method dimension - maps funding type IDs to payment method names and behavioral flags for eToro deposits, withdrawals, and cashout eligibility. Used by billing and customer action fact tables.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.FundingType |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (FundingTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_FundingType` is a payment method dimension with 44 rows (FundingTypeID 0-44, with ID 41 absent). Each row represents a payment method or funding channel that eToro customers use for deposits and withdrawals. Methods span credit cards, bank transfers, e-wallets, crypto, regional payment systems (Yandex, Qiwi, AliPay, WeChat, Przelewy24), and eToro-internal channels (eToroCryptoWallet, eToroMoney).

Three behavioral flags classify each method:
- `IsNewStyle`: modern-era payment integration (True = post-legacy platform)
- `IsSingleFunding`: one-time/single use (True = e.g., BankDraft, InternalPayment)
- `IsCashoutActive`: cashout/withdrawal supported via this method (True = bidirectional)

**FundingTypeID=0 (N/A)** is a DWH-injected synthetic null-sentinel row, inserted after the main staging load as a hardcoded VALUES insert. Fact tables use `ISNULL(FundingTypeID, 0)` to replace NULLs with this sentinel, enabling NULL-safe joins.

**FundingTypeID=27 (eToroCryptoWallet)** has hardcoded business logic: `SP_Fact_CustomerAction` calculates `IsRedeem = 1` when CreditTypeID=2 AND FundingTypeID=27. This hardcoding creates a maintenance risk if the crypto wallet ID changes.

This dimension is actively consumed by three major fact tables: `Fact_BillingDeposit`, `Fact_BillingWithdraw`, and `Fact_CustomerAction`.

---

## 2. Business Logic

### 2.1 Payment Method Classification Flags

**What**: Three bit flags classify payment method behavior.

**Columns Involved**: `IsNewStyle`, `IsSingleFunding`, `IsCashoutActive`

**Rules**:
- `IsNewStyle`: FALSE only for BankDraft (4), WesternUnion (5), MoneyGram (9). These are legacy payment methods.
- `IsSingleFunding`: TRUE for one-time or non-reusable methods: BankDraft (4), WesternUnion (5), MoneyGram (9), InternalPayment (16), TestDeposit (18), IBDeposit (19)
- `IsCashoutActive`: FALSE for methods where withdrawal is not supported: Giropay (11), Payoneer (14), Sofort (15), InternalPayment (16), LocalBankWire (17), TestDeposit (18), CashU (24), AliPay (25), WeChat (26), RapidTransfer (30), AstroPay (31), EtoroOptions (42), MoneyFarm (44)

### 2.2 Null Sentinel (FundingTypeID=0)

**What**: FundingTypeID=0 / Name='N/A' is a synthetic row added post-staging to represent unknown/missing funding type.

**Columns Involved**: `FundingTypeID`, `DWHFundingTypeID`

**Rules**:
- SP_Fact_CustomerAction uses `ISNULL(FundingTypeID, 0)` and `ISNULL(d.FundingTypeID, ISNULL(dd.FundingTypeID, 0))` to coerce NULLs to 0
- For the N/A row: DWHFundingTypeID=0 (same as FundingTypeID), all flags=False
- Inserted via hardcoded VALUES block in SP_Dictionaries (not from staging)

### 2.3 eToroCryptoWallet Hardcoded Logic

**What**: FundingTypeID=27 (eToroCryptoWallet) drives the `IsRedeem` flag in Fact_CustomerAction.

**Columns Involved**: `FundingTypeID`

**Rules**:
- `IsRedeem = CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`
- This hardcoded check appears in multiple sections of SP_Fact_CustomerAction
- Risk: If eToroCryptoWallet is assigned a new FundingTypeID, IsRedeem calculation breaks silently

### 2.4 DWHFundingTypeID Passthrough

**What**: `DWHFundingTypeID` mirrors `FundingTypeID` for all source rows (passthrough from staging).

**Rules**:
- For rows from staging: `DWHFundingTypeID = FundingTypeID` (same value, ETL SET `[FundingTypeID] as [DWHFundingTypeID]`)
- For the N/A row (FundingTypeID=0): `DWHFundingTypeID = 0`
- Purpose is likely for DWH-layer remapping or future surrogate key substitution. Currently identical to FundingTypeID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (44 rows - appropriate). CLUSTERED INDEX on FundingTypeID. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 44 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FundingTypeID to name | `LEFT JOIN DWH_dbo.Dim_FundingType ON FundingTypeID` |
| Find cashout-eligible methods | `WHERE IsCashoutActive = 1` |
| Identify legacy payment methods | `WHERE IsNewStyle = 0` |
| Exclude N/A sentinel | `WHERE FundingTypeID > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingDeposit | ON FundingTypeID | Payment method for deposits |
| DWH_dbo.Fact_BillingWithdraw | ON FundingTypeID_Withdraw / FundingTypeID_Funding | Payment method for withdrawals |
| DWH_dbo.Fact_CustomerAction | ON FundingTypeID | Payment method for customer financial actions |

### 3.4 Gotchas

- **FundingTypeID=0 is synthetic**: The N/A row (ID=0) does not come from the source system. It is DWH-injected after TRUNCATE+INSERT. Never filter it out blindly - fact tables use it for NULL FK rows.
- **FundingTypeID=41 missing**: The sequence jumps from 40 to 42. ID 41 was likely deleted or never assigned.
- **FundingTypeID=27 hardcoded**: eToroCryptoWallet ID is hardcoded in SP_Fact_CustomerAction for IsRedeem logic. Do not renumber/reassign this ID.
- **FundingTypeID is smallint NULL**: Nullable primary key with NOT NULL-equivalent usage. Join columns in fact tables may be int - implicit type conversion occurs.
- **Fact_BillingWithdraw has TWO FK columns**: `FundingTypeID_Withdraw` (the withdrawal method) and `FundingTypeID_Funding` (the original funding method). Both reference this dimension.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundingTypeID | smallint | YES | Primary key identifying the payment method. (Tier 1 — Dictionary.FundingType) |
| 2 | Name | varchar(50) | NO | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). (Tier 1 — Dictionary.FundingType) |
| 3 | IsNewStyle | bit | NO | Whether this payment method uses the newer integration style. Affects which code path handles the transaction. (Tier 1 — Dictionary.FundingType) |
| 4 | IsSingleFunding | bit | NO | Whether this is a one-time payment method (cannot be saved for repeat use). 1=single-use, 0=can be saved. (Tier 1 — Dictionary.FundingType) |
| 5 | IsCashoutActive | bit | NO | Whether withdrawals (cashouts) are supported via this method. 1=supports cashout, 0=deposit-only. (Tier 1 — Dictionary.FundingType) |
| 6 | DWHFundingTypeID | smallint | NO | DWH copy of FundingTypeID. SET in ETL as `[FundingTypeID] as [DWHFundingTypeID]`. Currently identical to FundingTypeID for all rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | StatusID | int | YES | Hardcoded to 1 for all rows (both staging rows and N/A sentinel). Likely means active. No corresponding Dim_Status table found. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 8 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() (stored as @ddate variable). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 9 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate). Both columns set on each run. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | passthrough |
| Name | etoro.Dictionary.FundingType | Name | passthrough |
| IsNewStyle | etoro.Dictionary.FundingType | IsNewStyle | passthrough |
| IsSingleFunding | etoro.Dictionary.FundingType | IsSingleFunding | passthrough |
| IsCashoutActive | etoro.Dictionary.FundingType | IsCashoutActive | passthrough |
| DWHFundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | ETL-computed: same as FundingTypeID (alias) |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.FundingType -> Generic Pipeline -> DWH_staging.etoro_Dictionary_FundingType
    -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 672) -> Dim_FundingType (rows 1-44)
    -> SP_Dictionaries_DL_To_Synapse (VALUES INSERT, ~line 1475) -> Dim_FundingType row 0 (N/A sentinel)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.FundingType | Payment method dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/FundingType/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_FundingType | Raw import |
| ETL (main) | DWH_dbo.SP_Dictionaries_DL_To_Synapse ~line 672 | TRUNCATE + INSERT. Adds DWHFundingTypeID=FundingTypeID, StatusID=1, UpdateDate/InsertDate=GETDATE(). |
| ETL (sentinel) | DWH_dbo.SP_Dictionaries_DL_To_Synapse ~line 1475 | Hardcoded VALUES INSERT for FundingTypeID=0, Name='N/A'. |
| Target | DWH_dbo.Dim_FundingType | 44-row REPLICATE/CLUSTERED dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingDeposit | FundingTypeID | Payment method for each deposit transaction |
| DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Withdraw | Withdrawal payment method |
| DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Funding | Original funding method for withdrawal |
| DWH_dbo.Fact_CustomerAction | FundingTypeID | Payment method for customer financial actions |

---

## 7. Sample Queries

### 7.1 All payment methods with cashout support

```sql
SELECT FundingTypeID, Name, IsNewStyle, IsSingleFunding
FROM DWH_dbo.Dim_FundingType
WHERE IsCashoutActive = 1 AND FundingTypeID > 0
ORDER BY FundingTypeID
```

### 7.2 Legacy (non-new-style) methods

```sql
SELECT FundingTypeID, Name, IsSingleFunding, IsCashoutActive
FROM DWH_dbo.Dim_FundingType
WHERE IsNewStyle = 0 AND FundingTypeID > 0
```

### 7.3 Join deposits with payment method name

```sql
SELECT ft.Name AS PaymentMethod, COUNT(*) AS DepositCount
FROM DWH_dbo.Fact_BillingDeposit bd
JOIN DWH_dbo.Dim_FundingType ft ON bd.FundingTypeID = ft.FundingTypeID
WHERE ft.FundingTypeID > 0
GROUP BY ft.Name
ORDER BY DepositCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 5 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 9/10, Relationships: 9/10, Sources: 8/10*
*Object: DWH_dbo.Dim_FundingType | Type: Table | Production Source: etoro.Dictionary.FundingType*


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


### Upstream `DWH_dbo.Dim_CardType` — synapse
- **Resolved as**: `DWH_dbo.Dim_CardType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CardType.md`

# DWH_dbo.Dim_CardType

> 18-row replicated dimension table listing payment card network brands (Visa, MasterCard, Diners, etc.) with their active status. Sourced from etoro production `Dictionary.CardType` via one-time migration (last updated 2019-06-30). Used as a lookup dimension by billing and deposit SPs across BI_DB_dbo.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `Dictionary.CardType` (etoro production) via DWH_Migration staging |
| **Refresh** | Daily (Generic Pipeline, Override, 1440 min) — but data unchanged since 2019-06-30 |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CardTypeID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override) |

---

## 1. Business Meaning

Dim_CardType is a small lookup dimension defining the 18 payment card network brands recognized by the eToro platform in the DWH layer. It is a subset of the production `Dictionary.CardType` table (which has 32 entries). When a customer deposits via credit or debit card, the card's BIN (Bank Identification Number) is resolved to a CardTypeID, and this dimension provides the human-readable brand name and active status.

The table was loaded via a one-time migration from production (`DWH_Migration.Dim_CardType` staging table) and all 18 rows share the same UpdateDate of 2019-06-30, indicating no incremental refreshes have occurred since the initial load. The Generic Pipeline exports this table daily to Unity Catalog as a Gold Override, but the underlying data has not changed.

Notable: the DWH copy carries only 18 of the 32 production card types (CardTypeID 0–17) and does NOT include the `Is3dsOn` column from the production source. The `IsActive` values in the DWH differ from production for some card types (e.g., CardTypeID 0 "None" is IsActive=1 in DWH but IsActive=0 in production; Maestro (8) is IsActive=0 in DWH but IsActive=1 in production), suggesting the DWH snapshot was taken at a different point in time.

---

## 2. Business Logic

### 2.1 Card Brand Lookup

**What**: Maps CardTypeID integers to human-readable card network brand names.

**Columns Involved**: `CardTypeID`, `CarTypeName`

**Rules**:
- CardTypeID 0 = "None" (fallback when BIN lookup fails to identify a card network)
- CardTypeID 1 = Visa, 2 = Master Card, 3 = Diners, 8 = Maestro — the four historically active brands in production
- CardTypeIDs 4–7, 9–17 are inactive/legacy brands (Amex, Fire Pay, JCB, American Express, Laser, Switch, UK Local Credit Card, Discover, Local Card, China Union Pay, Solo, Cirrus, GE Capital)

### 2.2 Active Status Flag

**What**: Indicates whether a card brand is accepted for deposits.

**Columns Involved**: `IsActive`

**Rules**:
- IsActive = 1: Card brand is accepted for deposits. In the DWH snapshot: Visa (1), Master Card (2), Diners (3), and None (0) show as active
- IsActive = 0: Card brand is not accepted — card will be rejected at deposit time
- Note: DWH values may diverge from current production state (snapshot from 2019-06-30)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **REPLICATE** distribution — full copy on every compute node. Ideal for this 18-row lookup: JOINs never require data movement.
- **CLUSTERED INDEX** on `CardTypeID` — efficient for point lookups and range scans by ID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What card brands are active? | `SELECT * FROM DWH_dbo.Dim_CardType WHERE IsActive = 1` |
| Resolve CardTypeID to name | JOIN to Dim_CardType on CardTypeID |
| Full card type list | `SELECT * FROM DWH_dbo.Dim_CardType ORDER BY CardTypeID` (only 18 rows) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact_BillingDeposit | `ON d.CardTypeID = ct.CardTypeID` | Resolve card brand for deposit transactions |
| Dim_CountryBin | `ON cb.CardTypeID = ct.CardTypeID` | Link BIN records to card brand names |

### 3.4 Gotchas

- **Column name typo**: The column is `CarTypeName` (missing "d" — not `CardTypeName`). This is in the DDL and cannot be changed without an ALTER.
- **IsActive divergence**: DWH IsActive values reflect a 2019 snapshot and may differ from current production `Dictionary.CardType.IsActive`.
- **Missing Is3dsOn**: The production `Dictionary.CardType` has an `Is3dsOn` column for 3D Secure configuration that is NOT carried into the DWH dimension. If 3DS status is needed, query production directly.
- **Subset of production**: Only 18 of 32 production card types are present (CardTypeIDs 0–17). CardTypeIDs 18–31 are not in the DWH.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (Dictionary.CardType) |
| Tier 2 | Derived from ETL code or SP logic |
| Tier 3 | Inferred with explicit reasoning |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CardTypeID | int | YES | Card network identifier. Active brands: 1=Visa, 2=MasterCard, 3=Diners, 8=Maestro. Inactive: 0=None, 4=Amex, 5=FirePay, 6=JCB, 7=American Express, 9=Laser, 10=Switch, 11=UK Local, 12=Discover, 13=Local Card, 14=China UnionPay, 15=Solo, 16=Cirrus, 17=GE Capital. (Tier 1 — Dictionary.CardType) |
| 2 | CarTypeName | varchar(50) | YES | Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. (Tier 1 — Dictionary.CardType) |
| 3 | IsActive | int | YES | Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. Type widened from bit to int in DWH. Only 4 of 32 are currently active in production. DWH note: DWH snapshot values may differ from current production state. (Tier 1 — Dictionary.CardType) |
| 4 | UpdateDate | datetime | YES | ETL metadata timestamp recording when the row was loaded into the DWH. All 18 rows show 2019-06-30 00:22:57, indicating a single bulk migration load. (Tier 2 — DWH_Migration load) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CardTypeID | Dictionary.CardType | CardTypeID | Passthrough |
| CarTypeName | Dictionary.CardType | Name | Rename (Name → CarTypeName) |
| IsActive | Dictionary.CardType | IsActive | Passthrough, type widened (bit → int) |
| UpdateDate | — | — | ETL-added (getdate() at migration load) |

### 5.2 ETL Pipeline

```
etoro.Dictionary.CardType (production, 32 rows)
  |-- One-time migration (2019-06-30) ---|
  v
DWH_Migration.Dim_CardType (staging, ROUND_ROBIN)
  |-- INSERT INTO ... SELECT ---|
  v
DWH_dbo.Dim_CardType (18 rows, REPLICATE)
  |-- Generic Pipeline (Override, daily, parquet) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype (UC Gold)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DWH_dbo.Dim_CountryBin | CardTypeID | Implicit FK | BIN-to-country records reference card brand |
| BI_DB_dbo.SP_DepositWithdrawFee | CardTypeID | SP JOIN | Deposit/withdrawal fee calculations by card type |
| BI_DB_dbo.SP_H_Deposits | CardTypeID | SP JOIN | Historical deposit reporting by card brand |
| BI_DB_dbo.SP_AllDeposits | CardTypeID | SP JOIN | All-deposits aggregation by card type |
| BI_DB_dbo.SP_EY_Audit_Deposit_Cashouts | CardTypeID | SP JOIN | Audit deposit/cashout reports |
| BI_DB_dbo.SP_EY_Audit_BO_Deposits_With_PIPs | CardTypeID | SP JOIN | Audit BO deposits with PIPs |
| BI_DB_dbo.SP_Deposit_Reversals_PIPs | CardTypeID | SP JOIN | Deposit reversal PIP calculations |
| BI_DB_dbo.SP_Withdraw_Rollback_PIPs | CardTypeID | SP JOIN | Withdrawal rollback PIP calculations |
| BI_DB_dbo.SP_Finance_Cashout_RollbackDetails | CardTypeID | SP JOIN | Finance cashout rollback details |

---

## 7. Sample Queries

### 7.1 List all active card types
```sql
SELECT CardTypeID, CarTypeName
FROM DWH_dbo.Dim_CardType
WHERE IsActive = 1
ORDER BY CardTypeID;
```

### 7.2 Card type distribution in deposits
```sql
SELECT ct.CarTypeName AS CardBrand,
       COUNT(*) AS DepositCount
FROM DWH_dbo.Fact_BillingDeposit d
JOIN DWH_dbo.Dim_CardType ct ON d.CardTypeID = ct.CardTypeID
GROUP BY ct.CarTypeName
ORDER BY DepositCount DESC;
```

### 7.3 Full card type reference
```sql
SELECT CardTypeID, CarTypeName, IsActive, UpdateDate
FROM DWH_dbo.Dim_CardType
ORDER BY CardTypeID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Tiers: 3 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 4/4, Logic: 9/10, Lineage: 9/10*
*Object: DWH_dbo.Dim_CardType | Type: Table | Production Source: Dictionary.CardType (etoro)*


### Upstream `DWH_dbo.Dim_CountryBin` — synapse
- **Resolved as**: `DWH_dbo.Dim_CountryBin`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CountryBin.md`

# DWH_dbo.Dim_CountryBin

> Large BIN (Bank Identification Number) lookup table (16.3M rows) mapping 6-digit and 8-digit card BINs to card-issuing country, bank, type, and payment processing attributes (3DS, prepaid).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.CountryBin6 + etoro.Dictionary.CountryBin8 (unified via DWH_staging.etoro_Dictionary_CountryBin) |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full TRUNCATE+INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (BinCode ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CountryBin` is a 16.3-million-row BIN (Bank Identification Number) lookup table. During credit card deposit processing, the first 6 or 8 digits of the customer's card number are matched against this table to determine the card-issuing country, bank, card type, and processing rules (whether 3D Secure verification is required, whether the card is prepaid, etc.).

The table combines two production sources: `etoro.Dictionary.CountryBin6` (6-digit BINs, ~324K rows upstream) and `etoro.Dictionary.CountryBin8` (8-digit BINs), both pre-merged in the `DWH_staging.etoro_Dictionary_CountryBin` staging table before loading to DWH.

The ETL is a full TRUNCATE+INSERT daily reload from staging. Several processing-level columns from the upstream source are dropped: `ChallengeIndicator3DS`, `SupportsAFT`, `IsCFT`, `DomesticMoneyTransfer`, `CrossBorderMoneyTransfer`.

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryBin6.md` (6-digit BIN details; 8-digit covered by CountryBin8.md).

---

## 2. Business Logic

### 2.1 BIN Lookup During Deposit Authorization

**What**: First 6 or 8 digits of a card number identify the issuing bank, country, and payment processing rules.

**Columns Involved**: `BinCode`, `CountryID`, `CardTypeID`, `ShouldCheck3ds`, `MinAmountFor3ds`, `IsPrepaid`

**Rules**:
- BinCode < 10,000,000 -> 6-digit BIN (from Dictionary.CountryBin6)
- BinCode >= 10,000,000 -> 8-digit BIN (from Dictionary.CountryBin8)
- ShouldCheck3ds=1: 3D Secure verification required for this BIN (29% of rows = 4.8M BINs require 3DS)
- ShouldCheck3ds=0: no 3DS required (71% of rows = 11.6M BINs)
- MinAmountFor3ds: Minimum deposit amount that triggers 3DS check (0 means all amounts)
- IsPrepaid=1: Card is prepaid; may trigger additional fraud checks or processing restrictions
- CountryID: card-issuing country (links to Dim_Country)

**Diagram**:
```
Card deposit: first 6/8 digits of card number -> BinCode lookup
  -> CountryID (issuing country)
  -> CardTypeID (Visa, Mastercard, etc.)
  -> ShouldCheck3ds (0/1)
  -> IsPrepaid (True/False)
  -> IssuingBank (human-readable bank name)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE. For a 16.3M-row table this is an unusually large replicated table - normally REPLICATE is reserved for small (<10M row) dimensions. At this scale, Synapse may choose not to replicate across all nodes. The CLUSTERED INDEX on BinCode is appropriate for point-lookup BIN matching.

**Warning**: Querying this table with full scans (no BinCode filter) is expensive. Always filter by BinCode.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED). Z-ORDER BY BinCode for fast BIN lookups. At 16M rows, no partitioning needed but Z-ORDER is recommended.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Lookup BIN attributes for a card | `SELECT * FROM Dim_CountryBin WHERE BinCode = @bin` |
| Find all BINs requiring 3DS | `WHERE ShouldCheck3ds = 1` |
| Prepaid card analysis | `WHERE IsPrepaid = 1` |
| Country-level BIN distribution | `JOIN Dim_Country ON BinCode.CountryID = Dim_Country.CountryID GROUP BY Name` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON b.CountryID = c.CountryID | Decode card-issuing country from BIN |
| DWH_dbo.Dim_CardType | ON b.CardTypeID = c.CardTypeID | Decode card type (Visa/MC/etc.) from BIN |

### 3.4 Gotchas

- At 16.3M rows, REPLICATE is unusual - be aware of potential memory pressure on Synapse nodes.
- 6-digit vs 8-digit BIN disambiguation: `BinCode < 10,000,000` = 6-digit BIN; higher = 8-digit. Some cards may match both lengths - 8-digit should take precedence (more specific).
- Several processing-critical columns are dropped from DWH vs production source: `ChallengeIndicator3DS`, `SupportsAFT`, `IsCFT`. Fraud analytics requiring these must query the production etoro.Dictionary.CountryBin directly.
- IssuingBank, CardSubType, CardCategory, BankWebSite, BankInfo are frequently NULL in live data - the BIN may not have enriched metadata.
- BinCode is NOT guaranteed unique at the row level in the DWH (the composite PK of CountryID+BinCode in production is collapsed to CLUSTERED INDEX here).

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
| 1 | CountryID | int | NO | FK to DWH_dbo.Dim_Country. Card-issuing country. Same ID space as Dim_Country.CountryID (DWH internal ID, not ISO numeric). (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 2 | BinCode | int | NO | Bank Identification Number. First 6 or 8 digits of the card number identifying the issuing bank and card product. Values < 10,000,000 are 6-digit BINs; >= 10,000,000 are 8-digit BINs. Clustered index key for fast lookups. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 3 | IssuingBank | varchar(100) | YES | Human-readable name of the card-issuing bank (e.g., "CENTRAL SUPPLIES - TDFS"). NULL when the BIN has no enriched bank metadata. Informational only - not used in deposit authorization logic. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 4 | CardTypeID | int | YES | FK to DWH_dbo.Dim_CardType (if exists). Card network/type: 1=Visa, 2=Mastercard, 13=Unknown/other. Used in deposit routing and reporting. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 5 | CardSubType | varchar(50) | YES | Sub-classification of the card product within its type (e.g., "CREDIT", "DEBIT", "PREPAID"). NULL when not available. Passthrough from staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough) |
| 6 | CardCategory | varchar(50) | YES | Card product category (e.g., "STANDARD", "GOLD", "PLATINUM", "BUSINESS"). NULL when not available. Passthrough from staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough) |
| 7 | BankWebSite | varchar(50) | YES | Issuing bank website URL. Informational. NULL in most rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough) |
| 8 | BankInfo | varchar(255) | YES | Additional bank information text. Informational. NULL in most rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough) |
| 9 | ShouldCheck3ds | tinyint | YES | Whether 3D Secure verification is required for deposits from this BIN. 1=required (4.8M BINs, 29%), 0=not required (11.6M BINs, 71%). Drives deposit authorization flow. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 10 | MinAmountFor3ds | int | YES | Minimum deposit amount (in account currency units) that triggers 3DS verification for this BIN. 0 = all amounts require 3DS when ShouldCheck3ds=1. Only meaningful when ShouldCheck3ds=1. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 11 | IsPrepaid | bit | NO | Whether this is a prepaid card. True=prepaid (may trigger fraud checks or processing restrictions). False=standard credit/debit card. (Tier 1 - Dictionary.CountryBin6 upstream wiki) |
| 12 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() on each daily full reload via SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | etoro.Dictionary.CountryBin6/8 | CountryID | passthrough |
| BinCode | etoro.Dictionary.CountryBin6/8 | BinCode | passthrough |
| IssuingBank | etoro.Dictionary.CountryBin6/8 | IssuingBank | passthrough |
| CardTypeID | etoro.Dictionary.CountryBin6/8 | CardTypeID | passthrough |
| CardSubType | etoro.Dictionary.CountryBin6/8 | CardSubType | passthrough |
| CardCategory | etoro.Dictionary.CountryBin6/8 | CardCategory | passthrough |
| BankWebSite | etoro.Dictionary.CountryBin6/8 | BankWebSite | passthrough |
| BankInfo | etoro.Dictionary.CountryBin6/8 | BankInfo | passthrough |
| ShouldCheck3ds | etoro.Dictionary.CountryBin6/8 | ShouldCheck3ds | passthrough (int -> tinyint) |
| MinAmountFor3ds | etoro.Dictionary.CountryBin6/8 | MinAmountFor3ds | passthrough |
| IsPrepaid | etoro.Dictionary.CountryBin6/8 | IsPrepaid | passthrough |
| UpdateDate | - | - | ETL-computed (GETDATE()) |

Upstream wikis: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryBin6.md` and `Dictionary.CountryBin8.md`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.CountryBin6 (6-digit BINs)
etoro.Dictionary.CountryBin8 (8-digit BINs)
  -> [pre-merged in staging]
  -> DWH_staging.etoro_Dictionary_CountryBin (unified, 19 cols)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, 12 cols)
  -> DWH_dbo.Dim_CountryBin (16.3M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CountryBin6 | 6-digit BINs with full processing attributes including ChallengeIndicator3DS, SupportsAFT, IsCFT |
| Source | etoro.Dictionary.CountryBin8 | 8-digit BINs with same structure |
| Staging | DWH_staging.etoro_Dictionary_CountryBin | Pre-merged staging: 19 cols (ProductType, Category, ChallengeIndicator3DS, SupportsAFT, IsCFT, DomesticMoneyTransfer, CrossBorderMoneyTransfer present but dropped) |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. 12 of 19 staging columns loaded. UpdateDate = GETDATE(). |
| Target | DWH_dbo.Dim_CountryBin | Final DWH BIN lookup (16.3M rows) |

**Dropped staging columns** (present in staging but NOT loaded to DWH):
- `ProductType`: Card product type string (different from CardSubType)
- `Category`: Card category string (different from CardCategory)
- `ChallengeIndicator3DS`: 3DS challenge indicator code
- `SupportsAFT`: Account Funding Transaction support flag
- `IsCFT`: Card Funding Transaction flag
- `DomesticMoneyTransfer`: Domestic money transfer support
- `CrossBorderMoneyTransfer`: Cross-border money transfer support

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Card-issuing country lookup. Implicit FK (not enforced). |
| CardTypeID | DWH_dbo.Dim_CardType | Card network type (Visa, Mastercard, etc.). Implicit FK. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Fact_BillingDeposit | BinCode | Deposit ETL likely joins BIN data for card attributes. [UNVERIFIED - inferred from domain context] |

---

## 7. Sample Queries

### 7.1 Lookup BIN attributes
```sql
SELECT b.BinCode, b.IssuingBank, b.CardTypeID, c.Name AS IssuingCountry,
       b.ShouldCheck3ds, b.IsPrepaid
FROM [DWH_dbo].[Dim_CountryBin] b
JOIN [DWH_dbo].[Dim_Country] c ON b.CountryID = c.CountryID
WHERE b.BinCode = 411234;
```

### 7.2 BINs requiring 3DS by country
```sql
SELECT c.Name AS Country, COUNT(*) AS BinCount
FROM [DWH_dbo].[Dim_CountryBin] b
JOIN [DWH_dbo].[Dim_Country] c ON b.CountryID = c.CountryID
WHERE b.ShouldCheck3ds = 1
GROUP BY c.Name
ORDER BY BinCount DESC;
```

### 7.3 Prepaid BIN share by card type
```sql
SELECT CardTypeID,
       SUM(CASE WHEN IsPrepaid = 1 THEN 1 ELSE 0 END) AS PrepaidBins,
       COUNT(*) AS TotalBins
FROM [DWH_dbo].[Dim_CountryBin]
GROUP BY CardTypeID
ORDER BY TotalBins DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryBin6.md` and `Dictionary.CountryBin8.md`.

---

*Generated: 2026-03-19 | Quality: 7.7/10 (4 stars) | Phases: 9/14 (no Atlassian)*
*Tiers: 6 T1, 5 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 8/10*
*Object: DWH_dbo.Dim_CountryBin | Type: Table | Production Source: etoro.Dictionary.CountryBin6 + etoro.Dictionary.CountryBin8*


### Upstream `DWH_dbo.Dim_BillingDepot` — synapse
- **Resolved as**: `DWH_dbo.Dim_BillingDepot`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md`

# DWH_dbo.Dim_BillingDepot

> Lookup dimension of payment gateway endpoints ("depots"), each configuring one (FundingType + PaymentType + Protocol) routing combination. Sourced daily from etoro.Billing.Depot via SP_Dictionaries_DL_To_Synapse. 163 rows; 114 active.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Depot |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DepotID) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_BillingDepot is the DWH version of etoro.Billing.Depot -- the central payment gateway routing configuration table. Each row defines one payment depot: a named combination of payment method (FundingTypeID), payment direction (PaymentTypeID: Deposit/Cashout/Refund), and processing gateway (ProtocolID). The routing engine selects a depot to process each transaction based on these three dimensions plus customer-specific factors (regulation, BIN, quotas).

Source: etoro.Billing.Depot on etoroDB-REAL. The production table is exported daily to Bronze/etoro/Billing/Depot/ and staged into DWH_staging.etoro_Billing_Depot. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern.

163 rows total (DepotID range 1-174 with gaps); 114 active (70%), 49 inactive (legacy or decommissioned). The DWH includes only 7 of the 8 production columns -- PayoutGeneration and Features are excluded by the ETL SELECT.

Sample depots: 1=MoneyBookers USD, 7=Neteller, 10=Wire, 3=WebMoney, 4=Giropay.

---

## 2. Business Logic

### 2.1 Depot Routing Selection

**What**: The payment routing engine selects a depot for each transaction based on FundingTypeID, PaymentTypeID, and ProtocolID combined with customer-specific routing criteria.

**Columns Involved**: `DepotID`, `FundingTypeID`, `PaymentTypeID`, `ProtocolID`, `IsActive`

**Rules**:
- Only depots with IsActive=1 are eligible for routing (114 of 163)
- IsActive=0 or NULL means the depot is inactive (legacy or decommissioned) -- excluded from routing
- The (FundingTypeID, PaymentTypeID, ProtocolID) triple uniquely identifies a depot endpoint
- PaymentTypeID: 1=Deposit, 2=Cashout, 3=Refund

**Dimension Relationships**:
- FundingTypeID references Dictionary.FundingType (payment method: CreditCard, Wire, Neteller, etc.)
- PaymentTypeID references Dictionary.PaymentType (1=Deposit, 2=Cashout, 3=Refund)
- ProtocolID references Dictionary.Protocol (specific gateway API)

### 2.2 DWH Completeness Note

**Excluded from DWH**: The production Billing.Depot table also has PayoutGeneration (automated payout file support) and Features (per-depot JSON/XML configuration flags). These columns are not in the SP SELECT and are not present in Dim_BillingDepot. Analyses requiring payout generation capability or feature flags must query the production source.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a CLUSTERED INDEX on DepotID. REPLICATE is correct for a 163-row lookup -- every distribution node holds a local copy, eliminating data movement on JOINs. The clustered index on DepotID supports efficient point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for a 163-row reference table. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All active payment depots | WHERE IsActive = 1 |
| Deposit depots by payment method | WHERE PaymentTypeID = 1, GROUP BY FundingTypeID |
| Cashout-capable depots | WHERE PaymentTypeID = 2 AND IsActive = 1 |
| Depots for a specific gateway | WHERE ProtocolID = N |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | ON DepotID | MID configuration per depot |
| Fact tables (deposit/cashout) | ON DepotID | Resolve depot name and attributes for transactions |

### 3.4 Gotchas

- **IsActive NULL = Inactive**: The column is nullable. NULL should be treated as inactive (not eligible for routing). Use `WHERE IsActive = 1` rather than `WHERE IsActive <> 0`.
- **No InsertDate**: Unlike most other Dim_ tables loaded by SP_Dictionaries, this table has only UpdateDate (no InsertDate, no StatusID, no DWH surrogate key).
- **PayoutGeneration/Features not in DWH**: Two production columns are excluded. For payout batch analysis, the production source must be queried directly.
- **163 rows total, 114 active**: Inactive rows represent legacy/decommissioned gateway integrations. Do not assume all rows are usable.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Billing.Depot) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepotID | int | NOT NULL | Primary key. Manually assigned (no IDENTITY). Stable identifier for this payment gateway endpoint. Range 1-174 with gaps; 163 rows. Referenced by fact deposit/cashout tables and MID settings. (Tier 1 - upstream wiki, Billing.Depot) |
| 2 | FundingTypeID | int | NOT NULL | Payment method type (e.g., 1=CreditCard, 2=Wire, 6=Neteller, 8=MoneyBookers/Skrill). References Dictionary.FundingType. 38 distinct values across 163 depots. (Tier 1 - upstream wiki, Billing.Depot) |
| 3 | PaymentTypeID | int | NOT NULL | Direction of payment flow. 1=Deposit, 2=Cashout, 3=Refund. References Dictionary.PaymentType. (Tier 1 - upstream wiki, Billing.Depot) |
| 4 | ProtocolID | int | NOT NULL | Payment processing protocol/gateway. References Dictionary.Protocol. Identifies the specific API or connection (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). (Tier 1 - upstream wiki, Billing.Depot) |
| 5 | Name | varchar(50) | NOT NULL | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. (Tier 1 - upstream wiki, Billing.Depot) |
| 6 | IsActive | bit | YES | Whether this depot currently accepts transactions. 1=Active (eligible for routing); 0 or NULL=Inactive (excluded from routing). 114 of 163 rows are active. (Tier 1 - upstream wiki, Billing.Depot) |
| 7 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production depot configuration changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DepotID | etoro.Billing.Depot | DepotID | Passthrough |
| FundingTypeID | etoro.Billing.Depot | FundingTypeID | Passthrough |
| PaymentTypeID | etoro.Billing.Depot | PaymentTypeID | Passthrough |
| ProtocolID | etoro.Billing.Depot | ProtocolID | Passthrough |
| Name | etoro.Billing.Depot | Name | Passthrough |
| IsActive | etoro.Billing.Depot | IsActive | Passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |
| *(excluded)* | etoro.Billing.Depot | PayoutGeneration | Not loaded into DWH |
| *(excluded)* | etoro.Billing.Depot | Features | Not loaded into DWH |

### 5.2 ETL Pipeline

```
etoro.Billing.Depot -> Generic Pipeline (daily, Override) -> Bronze/etoro/Billing/Depot/ -> DWH_staging.etoro_Billing_Depot -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_BillingDepot
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Billing.Depot | 163-row payment depot registry (etoroDB-REAL) |
| Lake | Bronze/etoro/Billing/Depot/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Billing_Depot | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; 7 of 8 production columns loaded; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_BillingDepot | 163 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DepotID | etoro.Billing.Depot | Production source (upstream reference) |
| FundingTypeID | etoro.Dictionary.FundingType | Payment method lookup (implicit -- no FK in DWH) |
| PaymentTypeID | etoro.Dictionary.PaymentType | Payment direction lookup (implicit -- no FK in DWH) |
| ProtocolID | etoro.Dictionary.Protocol | Gateway protocol lookup (implicit -- no FK in DWH) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | DepotID | MID configuration per depot |

---

## 7. Sample Queries

### 7.1 List active depots

```sql
SELECT DepotID, Name, FundingTypeID, PaymentTypeID, ProtocolID
FROM [DWH_dbo].[Dim_BillingDepot]
WHERE IsActive = 1
ORDER BY FundingTypeID, PaymentTypeID
```

### 7.2 Count depots by payment direction

```sql
SELECT
    PaymentTypeID,
    CASE PaymentTypeID WHEN 1 THEN 'Deposit' WHEN 2 THEN 'Cashout' WHEN 3 THEN 'Refund' ELSE 'Unknown' END AS Direction,
    COUNT(*) AS TotalDepots,
    SUM(CAST(ISNULL(IsActive, 0) AS INT)) AS ActiveDepots
FROM [DWH_dbo].[Dim_BillingDepot]
GROUP BY PaymentTypeID
ORDER BY PaymentTypeID
```

### 7.3 ETL freshness check

```sql
SELECT MAX(UpdateDate) AS LastLoad, COUNT(*) AS DepotCount
FROM [DWH_dbo].[Dim_BillingDepot]
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.5/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 6 T1, 1 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_BillingDepot | Type: Table | Production Source: etoro.Billing.Depot*


### Upstream `DWH_dbo.Dim_Affiliate` — synapse
- **Resolved as**: `DWH_dbo.Dim_Affiliate`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Affiliate.md`

# DWH_dbo.Dim_Affiliate

> Denormalized affiliate partner dimension — combines AffWizz affiliate profile, channel/sub-channel classification, trading account linkage, and aggregated registration/FTD/FTDe metrics across multiple time windows.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Row Count** | Low thousands (one row per affiliate partner) |
| **Production Source** | `fiktivo_dbo.tblaff_Affiliates` (AffWizz) via `Ext_Dim_Channel_Affiliate_UnifyCode` |
| **Refresh** | Daily full reload (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (AffiliateID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked` |
| **UC Target (PII)** | `pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate` |
| **UC Masked Columns** | Email,City |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Affiliate` is the master dimension for eToro's affiliate marketing partners. Each row represents one affiliate partner (identified by `AffiliateID`), combining:

- **Profile data** from the AffWizz affiliate management system (contact, company, website, login credentials)
- **Channel classification** (SubChannel, Channel) from the unified channel mapping
- **Trading account linkage** — resolving up to 4 username variants to find the affiliate's own eToro trading account
- **Performance aggregates** — Registration, FTD (First Time Deposit), and FTDe (First Time Deposit equivalent) counts across 7 time windows each (Yesterday, ThisMonth, LastMonth, ThisQuarter, LastQuarter, ThisYear, LastYear, Lifetime)
- **Contract classification** — affiliate payment model derived from ContractName keywords

The table answers: "Who is this affiliate, how are they classified, what contract do they have, and what are their referral performance metrics?"

### Key Business Concepts

- **FTD vs FTDe**: FTD = First Time Deposit (real money). FTDe = First Time Deposit equivalent (includes demo-to-real conversions or other qualifying events)
- **SubChannel/Channel**: Marketing classification inherited from `Ext_Dim_SubChannel_UnifyCode` — same logic as `Dim_Channel` (see Dim_Channel.md)
- **MasterAffiliateID**: Hierarchical relationship — some affiliates operate under a master affiliate umbrella
- **ContractType**: Numerically encoded payment model (0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=0-Commission, 8=CPL/CPR)

---

## 2. Business Logic

### 2.1 ContractType Classification

**What**: Derives the affiliate payment model from the free-text `ContractName` field.

**Columns Involved**: ContractType, ContractName, AffiliateID, Channel

**Rules** (evaluated in order, first match wins):
```
AffiliateID IN (12306, 14596, 30122, 37665, 18230) → 6 (eCost — hardcoded overrides)
ContractName LIKE '%internal campaigns%'             → 6 (eCost)
ContractName LIKE '%rev%' AND '%cpa%'                → 4 (Hybrid)
ContractName LIKE '%rs%'  AND '%cpa%'                → 4 (Hybrid)
ContractName LIKE '%rev%' AND '%cpl%'                → 4 (Hybrid)
ContractName LIKE '%rs%'  AND '%cpl%'                → 4 (Hybrid)
ContractName LIKE '%rev%' AND '%cpr%'                → 4 (Hybrid)
ContractName LIKE '%rs%'  AND '%cpr%'                → 4 (Hybrid)
ContractName LIKE '%rev%'                            → 3 (RevShare)
ContractName LIKE '%rs%'                             → 3 (RevShare)
ContractName LIKE '%cpa%'                            → 2 (CPA)
ContractName LIKE '%plan%'                           → 2 (CPA)
ContractName LIKE '%mati%' AND '%cpl%'               → 8 (CPL)
ContractName LIKE '%mati%' AND '%%%'                 → 3 (RevShare)
ContractName LIKE '%cpl%'                            → 8 (CPL)
ContractName LIKE '%cpr%'                            → 8 (CPR)
Channel = 'Affiliate' AND ContractName LIKE '%0 commission%' → 7 (Zero Commission)
ELSE                                                 → 0 (N/A)
```

### 2.2 Trading Account Resolution

**What**: Links affiliate to their own eToro trading account using COALESCE across 4 username lookups.

**Columns Involved**: TradingAccount_RealCID, TradingAccount_UserName

**Rules**:
```
TradingAccount_RealCID = COALESCE(BO1.CID, BO2.CID, BO3.CID, BO4.CID)
TradingAccount_UserName = COALESCE(BO1.UserName, BO2.UserName, BO3.UserName, BO4.UserName)

Where BO1..BO4 = Ext_Dim_Affiliate_Customer joined on UserName1..UserName4
Collation: Latin1_General_BIN (case-sensitive, binary comparison)
```

### 2.3 SubChannel/Channel Inheritance

**What**: SubChannelID, SubChannel, and Channel are inherited from `Ext_Dim_SubChannel_UnifyCode`, joined on AffiliateID.

**Logic**: Same unified classification as Dim_Channel — see `Dim_Channel.md` for the full SubChannelID-to-Channel mapping rules.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is `REPLICATE` — a full copy exists on every compute node. JOINs with fact tables (which are typically HASH-distributed) will always use local data. The CLUSTERED INDEX on AffiliateID supports equality lookups and range scans.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Affiliate performance summary | `SELECT * FROM Dim_Affiliate WHERE AffiliateID = @id` |
| All affiliates in a channel | `WHERE Channel = 'Affiliate'` or `Channel = 'Organic'` |
| Active affiliates | `WHERE AccountActivated = 1` |
| Hierarchy — sub-affiliates | `WHERE MasterAffiliateID = @masterAffId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Channel | ON SubChannelID = SubChannelID | Channel attributes (but Dim_Affiliate already has SubChannel/Channel) |
| DWH_dbo.Dim_Customer | ON AffiliateID = AffiliateID | Customers referred by this affiliate |
| DWH_dbo.Dim_Country | ON CountryID = CountryID | Affiliate country name |
| DWH_dbo.Fact_AffiliateCommission | ON AffiliateID = AffiliateID | Commission payments |

### 3.4 Gotchas

- **Masked columns**: `Email` and `City` are masked with `default()` — users without UNMASK permission see obfuscated values
- **ContractType is computed**: Derived from ContractName pattern matching. Not a source value. If ContractName doesn't match any rule → 0 (N/A)
- **TradingAccount_RealCID can be NULL**: If none of the 4 username variants resolve to an eToro user
- **Registration/FTD metrics are pre-aggregated**: These are period-level counts, not row-level data. They come from separate staging tables (`Ext_Dim_Affiliate_Registrations`, `Ext_Dim_Affiliate_FTD`, `Ext_Dim_Affiliate_FTDe`)

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | int | NO | Unique affiliate partner identifier from AffWizz system. Primary key. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 2 | DateCreated | datetime | NO | Date the affiliate was created/registered in AffWizz. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |
| 3 | SubChannelID | tinyint | NO | Marketing sub-channel identifier. JOINs to Dim_Channel.SubChannelID. Values: 1=Affiliate Partners, 2=SEM, 3=SEO, etc. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |
| 4 | Contact | nvarchar(1000) | YES | Primary contact information for the affiliate partner. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 5 | ContractName | nvarchar(100) | YES | Free-text name of the affiliate's contract/payment agreement. Used as input for the ContractType classification logic. E.g., "Rev Share + CPA", "CPL Standard". (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 6 | ContractType | tinyint | YES | Computed affiliate payment model: 0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=Zero Commission, 8=CPL/CPR. Derived from ContractName via CASE expression. (Tier 2 — SP_Dim_Affiliate) |
| 7 | AffiliatesGroupsName | nvarchar(50) | YES | Marketing group the affiliate belongs to. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 8 | AccountActivated | bit | YES | Whether the affiliate account is active. 1=Active, 0/NULL=Inactive. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 9 | LoginName | nvarchar(1000) | YES | Affiliate's login name in the AffWizz system. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 10 | TradingAccount_RealCID | bigint | YES | Affiliate's own eToro real-money CID, resolved via COALESCE across 4 username lookups against Ext_Dim_Affiliate_Customer. NULL if no match. (Tier 2 — SP_Dim_Affiliate) |
| 11 | TradingAccount_UserName | varchar(50) | YES | eToro username that matched for the affiliate's trading account. First non-NULL from 4 UserName variants. (Tier 2 — SP_Dim_Affiliate) |
| 12 | Email | nvarchar(255) | YES | Affiliate's email address. **MASKED** with default() — requires UNMASK permission. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 13 | CompanyAddress | nvarchar(255) | YES | Affiliate's company street address. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 14 | City | nvarchar(255) | YES | Affiliate's city. **MASKED** with default() — requires UNMASK permission. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 15 | CountryID | int | YES | Affiliate's country. JOINs to Dim_Country.CountryID. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 16 | WebSiteURL | nvarchar(255) | YES | Affiliate's website URL used for referral traffic. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 17 | RegistrationFirstDate | datetime | YES | Date of the affiliate's first referred registration. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 18 | RegistrationLastDate | datetime | YES | Date of the affiliate's most recent referred registration. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 19 | RegistrationLifeTime | int | YES | Total registrations referred by this affiliate, all time. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 20 | RegistrationYesterday | int | YES | Registrations referred yesterday. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 21 | RegistrationLastMonth | int | YES | Registrations referred last calendar month. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 22 | RegistrationLastQuarter | int | YES | Registrations referred last calendar quarter. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 23 | RegistrationLastYear | int | YES | Registrations referred last calendar year. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 24 | FTDFirstDate | datetime | YES | Date of the affiliate's first referred FTD (First Time Deposit). (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 25 | FTDLastDate | datetime | YES | Date of the most recent referred FTD. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 26 | FTDLifeTime | int | YES | Total FTDs referred by this affiliate, all time. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 27 | FTDYesterday | int | YES | FTDs referred yesterday. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 28 | FTDLastMonth | int | YES | FTDs referred last calendar month. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 29 | FTDLastQuarter | int | YES | FTDs referred last calendar quarter. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 30 | FTDLastYear | int | YES | FTDs referred last calendar year. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 31 | FTDeFirstDate | datetime | YES | Date of the affiliate's first referred FTDe (FTD equivalent — includes qualifying non-deposit events). (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 32 | FTDeLastDate | datetime | YES | Date of the most recent referred FTDe. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 33 | FTDeLifeTime | int | YES | Total FTDe events referred all time. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 34 | FTDeYesterday | int | YES | FTDe events referred yesterday. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 35 | FTDeLastMonth | int | YES | FTDe events referred last calendar month. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 36 | FTDeLastQuarter | int | YES | FTDe events referred last calendar quarter. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 37 | FTDeLastYear | int | YES | FTDe events referred last calendar year. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 38 | MasterAffiliateID | int | YES | Parent/master affiliate in the hierarchy. NULL if this is a standalone or top-level affiliate. JOINs to Dim_Affiliate.AffiliateID (self-reference). (Tier 2 — Ext_Dim_Affiliate_MasterAffiliate) |
| 39 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() during SP_Dim_Affiliate execution. (Tier 2 — SP_Dim_Affiliate) |
| 40 | RegistrationThisMonth | int | YES | Registrations referred current calendar month to date. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 41 | RegistrationThisQuarter | int | YES | Registrations referred current calendar quarter to date. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 42 | RegistrationThisYear | int | YES | Registrations referred current calendar year to date. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 43 | FTDeThisMonth | int | YES | FTDe events referred current calendar month to date. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 44 | FTDeThisQuarter | int | YES | FTDe events referred current calendar quarter to date. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 45 | FTDeThisYear | int | YES | FTDe events referred current calendar year to date. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 46 | FTDThisMonth | int | YES | FTDs referred current calendar month to date. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 47 | FTDThisQuarter | int | YES | FTDs referred current calendar quarter to date. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 48 | FTDThisYear | int | YES | FTDs referred current calendar year to date. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 49 | LanguageName | nvarchar(255) | YES | Affiliate's preferred language. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 50 | WebSiteTitle | nvarchar(256) | YES | Title/name of the affiliate's website. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 51 | GCID | int | YES | Global Customer ID linking the affiliate to the eToro customer graph. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 52 | EntityName | nvarchar(510) | YES | Legal entity name for the affiliate company. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 53 | ContactPersonFullName | nvarchar(510) | YES | Full name of the affiliate's primary contact person. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 54 | Telephone | nvarchar(50) | YES | Affiliate contact phone number. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 55 | SubChannel | nvarchar(50) | NO | Marketing sub-channel name (e.g., "Affiliate Partners", "SEM Brand"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |
| 56 | Channel | nvarchar(50) | NO | Top-level marketing channel (e.g., "Paid", "Organic", "Affiliate"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |

---

## 5. Lineage

### 5.1 Source Architecture

```
fiktivo_dbo (AffWizz staging tables)
    │
    ├─ SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse
    │   → Ext_Dim_Channel_Affiliate_UnifyCode (base affiliate profile)
    │   → Ext_Dim_SubChannel_UnifyCode (channel classification)
    │
    ├─ Ext_Dim_Affiliate_Customer (trading account lookups)
    ├─ Ext_Dim_Affiliate_Registrations (registration metrics)
    ├─ Ext_Dim_Affiliate_FTD (FTD metrics)
    ├─ Ext_Dim_Affiliate_FTDe (FTDe metrics)
    └─ Ext_Dim_Affiliate_MasterAffiliate (hierarchy)
         │
         └─ SP_Dim_Affiliate → Dim_Affiliate
```

### 5.2 Staging Table Sources

| Staging Table | Role | Join Key |
|--------------|------|----------|
| Ext_Dim_Channel_Affiliate_UnifyCode | Base profile, contact, company data | AffiliateID (base) |
| Ext_Dim_SubChannel_UnifyCode | SubChannelID, SubChannel, Channel, DateCreated | AffiliateID |
| Ext_Dim_Affiliate_Customer (×4) | TradingAccount_RealCID, TradingAccount_UserName | UserName1..4 (COLLATE Latin1_General_BIN) |
| Ext_Dim_Affiliate_Registrations | Registration metrics (7 time windows) | AffiliateID |
| Ext_Dim_Affiliate_FTD | FTD metrics (7 time windows) | AffiliateID |
| Ext_Dim_Affiliate_FTDe | FTDe metrics (7 time windows) | AffiliateID |
| Ext_Dim_Affiliate_MasterAffiliate | MasterAffiliateID | AffiliateID |

---

## 6. Relationships

### 6.1 References To (this table points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| SubChannelID | DWH_dbo.Dim_Channel | Channel dimension (implicit FK) |
| CountryID | DWH_dbo.Dim_Country | Affiliate's country |
| MasterAffiliateID | DWH_dbo.Dim_Affiliate | Self-reference: parent affiliate |
| GCID | DWH_dbo.Dim_Customer | Affiliate as customer (implicit FK) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Join Key | Description |
|--------------|----------|-------------|
| DWH_dbo.Dim_Customer | AffiliateID | Customers referred by this affiliate |
| DWH_dbo.Fact_AffiliateCommission | AffiliateID | Commission payments |
| DWH_dbo.Dim_Channel | SubChannelID (shared) | Same channel classification |

---

## 7. Sample Queries

### 7.1 Top affiliates by lifetime FTDs

```sql
SELECT TOP 20
    a.AffiliateID,
    a.EntityName,
    a.ContractName,
    a.Channel,
    a.SubChannel,
    a.FTDLifeTime,
    a.RegistrationLifeTime,
    CASE WHEN a.RegistrationLifeTime > 0
         THEN CAST(a.FTDLifeTime AS FLOAT) / a.RegistrationLifeTime
         ELSE 0 END AS ConversionRate
FROM DWH_dbo.Dim_Affiliate a
WHERE a.AccountActivated = 1
ORDER BY a.FTDLifeTime DESC;
```

### 7.2 Affiliate hierarchy

```sql
SELECT
    child.AffiliateID,
    child.EntityName AS ChildEntity,
    master.AffiliateID AS MasterID,
    master.EntityName AS MasterEntity
FROM DWH_dbo.Dim_Affiliate child
JOIN DWH_dbo.Dim_Affiliate master ON child.MasterAffiliateID = master.AffiliateID
ORDER BY master.AffiliateID, child.AffiliateID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key knowledge extracted |
|--------|------|-------------------------|
| [Affiliates - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11497250033/Affiliates+-+System+Document) | Confluence | AffWizz / affiliate platform overview: registration links with affiliate id + campaign query strings; sub-affiliate hierarchy (up to 5 levels); Fiktivo as hosting context — aligns with `AffiliateID`, campaign-style identifiers, and `MasterAffiliateID`. |
| [Affiliate - Data migration](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11643322541/Affiliate+-Data+migration) | Confluence | Documents migration of affiliate commission data from legacy fiktivo tables — confirms `fiktivo` DB as the system of record for affiliate entities that feed DWH staging. |
| [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151/DWH+Process+Data+Sources) | Confluence | Lists `fiktivo.dbo.tblaff_*` (e.g. `tblaff_Affiliates`, `tblaff_MarketingExpense`, `tblaff_AffiliatesGroups`, `tblaff_AffiliateTypes`) as DWH pipeline sources — matches `Dim_Affiliate` lineage. |
| [PI As Affiliate](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13178109958/PI+As+Affiliate) | Confluence | Partners Portal proxies Affiliate API; notes use of existing SPs against Fiktivo DB — supports interpretation of affiliate profile and trading-account linkage fields as AffWizz/Fiktivo-sourced. |
| [Affiliates Compliance Review and Monitoring Procedure 2026](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/1593278467/Affiliates+Compliance+Review+and+Monitoring+Procedure+2026) | Confluence | Operational context: AffWizz login, search by Affiliate ID — mirrors `AffiliateID` as the operational key. |

---

*Generated: 2026-03-19 | Quality: 7.8/10 (★★★★☆) | Phases: 7/14 (P2,P3 skipped — Synapse MCP unavailable; P10 Atlassian refresh)*
*Tiers: 0 T1, 56 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10*
*Object: DWH_dbo.Dim_Affiliate | Type: Table | Production Source: fiktivo_dbo.tblaff_Affiliates (AffWizz)*


### Upstream `DWH_dbo.Dim_Channel` — synapse
- **Resolved as**: `DWH_dbo.Dim_Channel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Channel.md`

# DWH_dbo.Dim_Channel

> 36-row marketing channel dimension table mapping every sub-channel to its parent channel and organic/paid classification. Sourced from the affiliate system's sub-channel unify-code reference table (`Ext_Dim_SubChannel_UnifyCode`) via `SP_Dim_Channel`. Truncated and reloaded daily by `SP_Dictionaries_DL_To_Synapse`. 20 distinct channels, 36 sub-channels.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Ext_Dim_SubChannel_UnifyCode → SP_Dim_Channel (truncate-and-reload) |
| **Refresh** | Daily (1440 min) — full truncate-and-reload via SP_Dictionaries_DL_To_Synapse |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (SubChannelID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, parquet → delta) |

---

## 1. Business Meaning

Dim_Channel is a small reference/dimension table (36 rows) that defines the marketing channel hierarchy used across eToro's acquisition and attribution reporting. Each row represents a unique sub-channel (e.g., "Google Search", "Taboola", "Direct Mobile") identified by `SubChannelID`, grouped under a parent `Channel` (e.g., "SEM", "Direct", "Affiliate"), and classified as either "Organic" or "Paid".

The table is sourced from `Ext_Dim_SubChannel_UnifyCode`, which is an external table loaded from the affiliate system (fiktivo `tblaff_Affiliates`). The writer SP (`SP_Dim_Channel`) performs a `SELECT DISTINCT` to deduplicate, then applies a CASE-based organic/paid classification before truncating and reloading the target.

SP_Dim_Channel also contains an alerting mechanism: when new sub-channels appear in the source that are not yet in `Dim_Channel`, an HTML email is sent to BI Data Solutions and the BI Analysis Team requesting immediate mapping.

The table is heavily referenced by downstream BI_DB reporting procedures (15+ SPs) for marketing attribution, acquisition funnels, and affiliate analytics.

---

## 2. Business Logic

### 2.1 Organic/Paid Classification

**What**: Each sub-channel is classified as "Organic" or "Paid" based on channel name and sub-channel name rules.
**Columns Involved**: Channel, SubChannel, Organic/Paid
**Rules**:
- Channel IN ('Friend Referral', 'Direct', 'SEO') → 'Organic'
- SubChannel = 'Google Brand' → 'Organic' (even though Channel = 'SEM')
- All other combinations → 'Paid'
- Current distribution: 30 Paid, 6 Organic

### 2.2 Channel Hierarchy

**What**: Two-level marketing hierarchy — Channel (parent) → SubChannel (child).
**Columns Involved**: Channel, SubChannel, SubChannelID
**Rules**:
- SubChannelID is the grain — one row per sub-channel
- A Channel can have 1–13 sub-channels (SEM has 13, most channels have 1)
- SubChannelID values are non-sequential (range 1–52, 36 active)
- Some sub-channels share the same name as their parent channel (e.g., Channel="Events", SubChannel="Events")

### 2.3 Unmapped Channel Alert

**What**: SP_Dim_Channel sends an email alert when new sub-channels appear in the source but are missing from Dim_Channel after load.
**Columns Involved**: SubChannelID, Channel, SubChannel
**Rules**:
- After INSERT, a LEFT JOIN check identifies rows in the source that have no matching SubChannelID in Dim_Channel
- If count > 0, an HTML email is generated listing the unmapped channels
- Recipients: bi-datasolutions@etoro.com, BIAnalysisTeam@etoro.com
- Subject: "New Channels in Affwizz - Need mapping ASAP"

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — appropriate for a 36-row dimension table. No skew concerns.
- **Index**: CLUSTERED INDEX on SubChannelID — supports point lookups when joining from fact tables on SubChannelID.
- At 36 rows, full table scans are negligible. No query optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What channel does SubChannelID X belong to? | `SELECT * FROM DWH_dbo.Dim_Channel WHERE SubChannelID = @id` |
| List all organic channels | `SELECT * FROM DWH_dbo.Dim_Channel WHERE [Organic/Paid] = 'Organic'` |
| How many sub-channels per channel? | `SELECT Channel, COUNT(*) AS SubChannels FROM DWH_dbo.Dim_Channel GROUP BY Channel ORDER BY SubChannels DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact tables with SubChannelID | `ON fact.SubChannelID = dc.SubChannelID` | Resolve marketing channel for customer acquisition |
| Dim_Customer (via SubChannelID) | `ON cust.SubChannelID = dc.SubChannelID` | Attribute customer to acquisition channel |
| BI_DB reporting tables | Various | Marketing cube, acquisition funnel, affiliate reporting |

### 3.4 Gotchas

- **Column name with special character**: `[Organic/Paid]` contains a forward slash — always wrap in square brackets in SQL queries.
- **Google Brand exception**: SubChannelID=4 ("Google Brand") is under Channel="SEM" but classified as "Organic" — the only SEM sub-channel that is organic.
- **Social Organic is Paid**: Despite the name "Social Organic" (SubChannelID=49), it is classified as "Paid" because the CASE logic only checks Channel-level names, not SubChannel names.
- **Non-sequential IDs**: SubChannelID values range from 1 to 52 with gaps — do not assume contiguity.
- **Truncate-and-reload**: All InsertDate/UpdateDate values are identical (the last load timestamp). These columns do NOT track when a channel was first created or last modified historically.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code or DDL with evidence |
| Tier 3 | No upstream traceable; grounded in DDL + naming |
| Tier 4 | Inferred from name only (banned for this object) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | SubChannelID | int | NO | Primary key identifying a unique marketing sub-channel. Non-sequential integer (range 1–52, 36 active). Passthrough from Ext_Dim_SubChannel_UnifyCode.SubChannelID via SELECT DISTINCT. Clustered index key. Used as FK join key by downstream fact and BI_DB tables. (Tier 2 — SP_Dim_Channel) |
| 2 | Channel | nvarchar(50) | NO | Top-level marketing channel grouping (e.g., 'SEM', 'Direct', 'Affiliate', 'SEO', 'Friend Referral'). 20 distinct values. Passthrough from Ext_Dim_SubChannel_UnifyCode.Channel via SELECT DISTINCT. Also used as input to the Organic/Paid classification CASE logic. (Tier 2 — SP_Dim_Channel) |
| 3 | SubChannel | varchar(100) | NO | Granular marketing sub-channel name within a Channel (e.g., 'Google Search', 'Taboola', 'Direct Mobile', 'IBs'). 36 distinct values — one per row. Passthrough from Ext_Dim_SubChannel_UnifyCode.SubChannel via SELECT DISTINCT. Some sub-channels share their parent Channel name (e.g., Channel='Events', SubChannel='Events'). (Tier 2 — SP_Dim_Channel) |
| 4 | Organic/Paid | varchar(7) | YES | ETL-computed classification: 'Organic' when Channel IN ('Friend Referral', 'Direct', 'SEO') or SubChannel = 'Google Brand'; 'Paid' otherwise. 2 distinct values: Paid (30 rows), Organic (6 rows). NULL is allowed by DDL but not produced by current SP logic. (Tier 2 — SP_Dim_Channel) |
| 5 | InsertDate | datetime | YES | Row insert timestamp set to GETDATE() at SP execution time. Because the table uses truncate-and-reload, all rows share the same InsertDate equal to the last load run. Does not represent the original creation date of the channel. (Tier 2 — SP_Dim_Channel) |
| 6 | UpdateDate | datetime | YES | Row update timestamp set to GETDATE() at SP execution time. Identical to InsertDate on every load due to the truncate-and-reload pattern. Does not track incremental changes. (Tier 2 — SP_Dim_Channel) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| SubChannelID | Ext_Dim_SubChannel_UnifyCode | SubChannelID | Passthrough (SELECT DISTINCT) |
| Channel | Ext_Dim_SubChannel_UnifyCode | Channel | Passthrough (SELECT DISTINCT) |
| SubChannel | Ext_Dim_SubChannel_UnifyCode | SubChannel | Passthrough (SELECT DISTINCT) |
| Organic/Paid | — (computed) | — | CASE on Channel + SubChannel values |
| InsertDate | — (computed) | — | GETDATE() |
| UpdateDate | — (computed) | — | GETDATE() |

### 5.2 ETL Pipeline

```
fiktivo.dbo.tblaff_Affiliates (affiliate system, production)
  |-- External table load (SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) ---|
  v
DWH_dbo.Ext_Dim_SubChannel_UnifyCode (external/staging table)
  |-- SP_Dim_Channel (SELECT DISTINCT + CASE Organic/Paid) ---|
  v
DWH_dbo.Dim_Channel (36 rows, truncate-and-reload daily)
  |-- Generic Pipeline (Override, parquet → delta, daily) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel (Unity Catalog Gold)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (source) | DWH_dbo.Ext_Dim_SubChannel_UnifyCode | Source external table providing channel/sub-channel reference data |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Key | Purpose |
|-------------------|----------|---------|
| BI_DB_dbo.SP_CIDFirstDates | SubChannelID | Customer first-date acquisition channel attribution |
| BI_DB_dbo.SP_Marketing_Cube | SubChannelID | Marketing analytics cube |
| BI_DB_dbo.SP_H_LiveAcquisitionDashboard | SubChannelID | Live acquisition dashboard |
| BI_DB_dbo.SP_LiveAcquisitionDashboard_Daily | SubChannelID | Daily acquisition dashboard |
| BI_DB_dbo.SP_CIDFunnelFlow | SubChannelID | Customer funnel flow analysis |
| BI_DB_dbo.SP_H_Deposits | SubChannelID | Deposit reporting by channel |
| BI_DB_dbo.SP_PI_Affiliate | SubChannelID | Popular Investor affiliate reporting |
| BI_DB_dbo.SP_VerificationStatus | SubChannelID | Verification status by channel |
| BI_DB_dbo.SP_AffiliatePaymentsReport | SubChannelID | Affiliate payment reporting |
| BI_DB_dbo.SP_M_Active_Affiliate_Monthly | SubChannelID | Monthly active affiliate reporting |
| BI_DB_dbo.SP_M_Compliance_CDIM_Report | SubChannelID | Compliance CDIM reporting |
| BI_DB_dbo.SP_W_Mon_Compliance_CDIM_Report | SubChannelID | Weekly/monthly compliance reporting |
| BI_DB_dbo.QST | SubChannelID | QST reporting |
| BI_DB_dbo.SP_CIDFirstDates_HistoricalRun | SubChannelID | Historical first-dates backfill |
| BI_DB_dbo.SP_M_Active_Aff_Monthly_Region_GroupAff | SubChannelID | Regional affiliate monthly reporting |

---

## 7. Sample Queries

### 7.1 Channel Distribution Summary

```sql
SELECT
    Channel,
    [Organic/Paid],
    COUNT(*) AS SubChannelCount
FROM DWH_dbo.Dim_Channel
GROUP BY Channel, [Organic/Paid]
ORDER BY SubChannelCount DESC;
```

### 7.2 Find All Organic Sub-Channels

```sql
SELECT SubChannelID, Channel, SubChannel
FROM DWH_dbo.Dim_Channel
WHERE [Organic/Paid] = 'Organic'
ORDER BY Channel, SubChannel;
```

### 7.3 Join to Customer First-Dates for Acquisition Attribution

```sql
SELECT
    dc.Channel,
    dc.SubChannel,
    dc.[Organic/Paid],
    COUNT(DISTINCT cfd.CID) AS Customers
FROM BI_DB_dbo.BI_DB_CIDFirstDates cfd
JOIN DWH_dbo.Dim_Channel dc ON cfd.SubChannelID = dc.SubChannelID
GROUP BY dc.Channel, dc.SubChannel, dc.[Organic/Paid]
ORDER BY Customers DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources searched (regen harness mode — Phase 10 skipped).

---

*Generated: 2026-04-28 | Quality: pending/10 | Phases: 12/14*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 3/10*
*Object: DWH_dbo.Dim_Channel | Type: Table | Production Source: Ext_Dim_SubChannel_UnifyCode → SP_Dim_Channel*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_H_Deposits`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_H_Deposits.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_H_Deposits] AS      
Begin      
      
  
      
DECLARE @suffix_hc VARCHAR (100) = 'Yesterday'
DECLARE @Date DATE=GETDATE()-1
DECLARE @DateID INT= BI_DB_dbo.DateToDateID(@Date)
exec [BI_DB_dbo].[SP_Create_External_etoro_History_DepositAction] @Date, @suffix_hc
	
	
IF OBJECT_ID('tempdb..#AdvancedDeposit_Ext') IS NOT NULL DROP TABLE #AdvancedDeposit_Ext
CREATE TABLE #AdvancedDeposit_Ext
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
	
	
  SELECT       
  fbd.[DepositID] AS [DepositID],      
  fbd.[CID] AS [CID],      
  fbd.[FundingID] AS [FundingID],      
  FundingType.Name as FundingType,      
  fbd.[CurrencyID] AS [CurrencyID],      
  fbd.[PaymentStatusID] AS [PaymentStatusID],      
  fbd.[ManagerID] AS [ManagerID],      
  fbd.[RiskManagementStatusID] AS [RiskManagementStatusID],      
  fbd.[Amount] AS [Amount],      
  fbd.[ExchangeRate] AS [ExchangeRate],      
  fbd.[ModificationDate] AS [ModificationDate],      
  fbd.[TransactionIDAsString] AS [TransactionID],      
  fbd.[IPAddress] AS [IPAddress],      
  fbd.[Approved] AS [Approved],      
  fbd.[Commission] AS [Commission],      
  fbd.[PaymentDate] AS [PaymentDate],      
  fbd.[ClearingHouseEffectiveDate] AS [ClearingHouseEffectiveDate],      
  null AS [OldPaymentID],      
  
  fbd.[IsFTD] AS [IsFTD],      
  fbd.[ProcessorValueDate] AS [ProcessorValueDate],      
  fbd.[RefundVerificationCode] AS [RefundVerificationCode],      
  fbd.[DepotID] AS [DepotID],      
  fbd.[MatchStatusID] AS [MatchStatusID],      
  fbd.[FunnelID] AS [FunnelID],      
  null AS [Code],      
  fbd.[ExTransactionID] AS [ExTransactionID],      
  dps.[PaymentStatusID] AS [PaymentStatus_PaymentStatusID],      
  dps.Name AS [PaymentStatus_Name],  
  [RiskManagementStatus].[RiskManagementStatusID] AS [RiskManagementStatus_RiskManagementStatusID],      
  [RiskManagementStatus].Name AS [RiskManagementStatus_Name],      
  ------Chan.Channel,      
  ------Chan.SubChannel,      
  regions.Name as Region,      
  country.Name as Country,      
  [FirstTimeDepositAttemptDate]  as FirstDepositAttempt,      
  [FirstTimeDepositSuccessDate] as FirstDepositDate,      
  CC.RegisteredReal 'Registered',      
  CC.AffiliateID AS 'SerialID',
 
  df.Name as Funnel,      
  df2.Name as FunnelFrom,      
  df3.Name as AcquisitionFunnel,      
  fbd.BinCodeAsString	   As BinCode,      
  ct.CarTypeName As CreditCardType,      
  cb.CardSubType,      
  cb.CardCategory,      
  dc3.Name As BINCountry,      
  depo.Name DepoName      
   
  ,dr.ResponseName, 
  row_number() over (partition by fbd.DepositID order by hda.ModificationDate desc) ResponseRN,  
  fbd.ModificationDate AS [Date],
  fbd.ModificationDateID as DateID,
getdate () as UpdateDate      
      
  FROM DWH_dbo.Fact_BillingDeposit fbd  with(nolock)      
  INNER JOIN DWH_dbo.Dim_PaymentStatus dps  with(nolock)  ON fbd.[PaymentStatusID] = dps.[PaymentStatusID]      
  left JOIN DWH_dbo.Dim_Funnel df  with(nolock)  ON fbd.[FunnelID] = df.[FunnelID]      
  LEFT JOIN [BI_DB_dbo].[External_etoro_Dictionary_RiskManagementStatus] [RiskManagementStatus]  ON fbd.[RiskManagementStatusID] = [RiskManagementStatus].[RiskManagementStatusID]      
  left join [BI_DB_dbo].[External_etoro_Billing_Funding_Datafactory] Funding   on fbd.FundingID=Funding.FundingID      
  left join DWH_dbo.Dim_FundingType FundingType with(nolock)  on Funding.FundingTypeID=FundingType.FundingTypeID      
  left join [BI_DB_dbo].[External_etoro_BackOffice_CustomerAllTimeAggregatedData] Agg  on fbd.CID=Agg.CID      
  join DWH_dbo.Dim_Customer CC With(nolock) on fbd.CID=CC.RealCID      
  left join DWH_dbo.Dim_Country country with(nolock) on CC.CountryID=country.CountryID      
  left join [BI_DB_dbo].[External_etoro_Dictionary_MarketingRegion] regions  on country.MarketingRegionID=regions.MarketingRegionID      
       
  left join   DWH_dbo.Dim_Funnel df2 with(nolock) on    CC.FunnelFromID=df2.FunnelID      
  left join   DWH_dbo.Dim_Funnel df3 with(nolock) on    CC.FunnelID=df3.FunnelID      
  left join BI_DB_dbo.External_etoro_Billing_Funding fund  on fbd.FundingID = fund.FundingID      
  left join DWH_dbo.Dim_Country dc3      
  on dc3.CountryID = fbd.BinCountryIDAsInteger
  --Case When CHARINDEX(BinCountryIDAsInteger,Cast(fund.FundingData as nvarchar(max))) + 23 <> 23 then      
  --     (Convert(Integer, SUBSTRING(Cast(fund.FundingData as nvarchar(max)),      
  --     CHARINDEX(BinCountryIDAsInteger,Cast(fund.FundingData as nvarchar(max))) + 23,      
  --          CHARINDEX(BinCountryIDAsInteger,Cast(fund.FundingData as nvarchar(max))) - (CHARINDEX(BinCountryIDAsInteger,Cast(fund.FundingData as nvarchar(max))) + 23))))      
  --     Else NULL END      
  left join DWH_dbo.Dim_CardType ct      
  on ct.CardTypeID = fbd.CardTypeIDAsInteger
  --Case When CHARINDEX(CardTypeIDAsInteger,Cast(fund.FundingData as nvarchar(max))) + 21 <> 21 then      
  --     (Convert(Integer, SUBSTRING(Cast(fund.FundingData as nvarchar(max)),      
  --     CHARINDEX(CardTypeIDAsInteger,Cast(fund.FundingData as nvarchar(max))) + 21,      
  --          CHARINDEX(CardTypeIDAsInteger,Cast(fund.FundingData as nvarchar(max))) - (CHARINDEX(CardTypeIDAsInteger,Cast(fund.FundingData as nvarchar(max))) + 21))))      
  --     Else NULL END      
  left join DWH_dbo.Dim_CountryBin cb      
  on cb.BinCode = fbd.BinCodeAsString
  --Case When CHARINDEX(BinCodeAsString,Cast(fund.FundingData as nvarchar(max))) + 17 <> 17 then      
  --     (Convert(BigInt, SUBSTRING(Cast(fund.FundingData as nvarchar(max)),      
  --     CHARINDEX(BinCodeAsString,Cast(fund.FundingData as nvarchar(max))) + 17,      
  --          CHARINDEX(BinCodeAsString,Cast(fund.FundingData as nvarchar(max))) - (CHARINDEX(BinCodeAsString,Cast(fund.FundingData as nvarchar(max))) + 17))))      
  --     Else NULL END      
  left join DWH_dbo.Dim_BillingDepot  depo      
  on depo.DepotID = fbd.[DepotID]      
      
  left join [BI_DB_dbo].[External_etoro_History_DepositAction_Yesterday] hda      
  on hda.DepositID = fbd.[DepositID]      
  left join [BI_DB_dbo].[External_etoro_Dictionary_Response] dr      
  on dr.ResponseID = hda.ResponseID   
     
  where PlayerLevelID!=4  ---and [Deposit].[ModificationDate] >= ''20170101''      
  and fbd.ModificationDate >= @Date   
    
    
	    CREATE clustered INDEX #AdvancedDeposit_Ext ON #AdvancedDeposit_Ext (SerialID)  

  IF OBJECT_ID('tempdb..#BI_DB_Deposits_tmp') IS NOT NULL DROP TABLE #BI_DB_Deposits_tmp
CREATE TABLE #BI_DB_Deposits_tmp
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
	
  select CC.*,    Chan.Channel,      
  Chan.SubChannel      
  from #AdvancedDeposit_Ext CC      
  left join (SELECT aff.AffiliateID, aff.Channel, aff.SubChannel      
  FROM DWH_dbo.[Dim_Affiliate] aff       
  JOIN DWH_dbo.[Dim_Channel] chan      
  ON aff.SubChannelID= chan.SubChannelID      
  ) Chan      
  ON CC.SerialID=Chan.AffiliateID     
  
    CREATE CLUSTERED INDEX #BI_DB_Deposits_tmp ON #BI_DB_Deposits_tmp (ResponseRN)  
      

   IF OBJECT_ID('tempdb..#BI_DB_Deposits_updates') IS NOT NULL DROP TABLE #BI_DB_Deposits_updates
CREATE TABLE #BI_DB_Deposits_updates
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
	
 select *      
    
 from #BI_DB_Deposits_tmp      
 where ResponseRN=1      
      
    CREATE clustered INDEX #BI_DB_Deposits_updates ON #BI_DB_Deposits_updates (DepositID)  
 --select count (*)      
 --from #BI_DB_Deposits_tmp      
      
 --select count (*)      
 --from #BI_DB_Deposits_updates       
      
 --select count (*)--a.*      
 --from #BI_DB_Deposits_updates  a       
 --left join BI_DB_Deposits b      
 --on a.DepositID=b.DepositID      
 --where  b.DepositID is null      
      
 --select count (*)--a.*      
 --from #BI_DB_Deposits_updates  a       
 -- join BI_DB_Deposits b      
 --on a.DepositID=b.DepositID      
       
      
      
  update BI_DB_dbo.BI_DB_Deposits  set      
    [FundingID] =a.[FundingID]      
   ,[FundingType]=a.[FundingType]      
   ,[CurrencyID]=a.[CurrencyID]      
   ,[PaymentStatusID] = a.[PaymentStatusID]      
   ,[ManagerID]=a.[ManagerID]      
   ,[RiskManagementStatusID]= a.[RiskManagementStatusID]      
   ,[Amount] =a.[Amount]      
   ,[ExchangeRate] =a.[ExchangeRate]      
   ,[ModificationDate] =a.[ModificationDate]      
   ,[TransactionID] = a.[TransactionID]      
   ,[IPAddress] = a.[IPAddress]      
   ,[Approved] =a.[Approved]      
   ,[Commission] =a.[Commission]      
   ,[PaymentDate] = a.[PaymentDate]      
   ,[ClearingHouseEffectiveDate] = a.[ClearingHouseEffectiveDate]      
   ,[OldPaymentID] =a.[OldPaymentID]      
   ,[IsFTD] = a.[IsFTD]      
   ,[ProcessorValueDate] =a.[ProcessorValueDate]      
   ,[RefundVerificationCode] =a.[RefundVerificationCode]      
   ,[DepotID] =a.[DepotID]      
   ,[MatchStatusID] =a.[MatchStatusID]      
   ,[FunnelID] =a.[FunnelID]      
   ,[Code] =a.[Code]      
   ,[ExTransactionID] =a.[ExTransactionID]      
   ,[PaymentStatus_PaymentStatusID]=a.[PaymentStatus_PaymentStatusID]      
   ,[PaymentStatus_Name] =a.[PaymentStatus_Name]      
   ,[RiskManagementStatus_RiskManagementStatusID] =a.[RiskManagementStatus_RiskManagementStatusID]      
   ,[RiskManagementStatus_Name] =a.[RiskManagementStatus_Name]      
   ,[Channel] = a.[Channel]      
   ,[SubChannel] =a.[SubChannel]      
   ,[Region] =a.[Region]      
   ,[Country] =a.[Country]      
   ,[FirstDepositAttempt] =a.[FirstDepositAttempt]      
   ,[FirstDepositDate] = a.[FirstDepositDate]      
   ,[Registered] =a.[Registered]      
   ,[SerialID] =a.[SerialID]      
   ,[Funnel] =a.[Funnel]      
   ,[FunnelFrom] = a.[FunnelFrom]      
   ,[AcquisitionFunnel] = a.[AcquisitionFunnel]      
   ,[BinCode] =a.[BinCode]      
   ,[CreditCardType] =a.[CreditCardType]      
   ,[CardSubType] =a.[CardSubType]      
   ,[CardCategory] =a.[CardCategory]      
   ,[BINCountry] =a.[BINCountry]      
   ,[DepoName] =a.[DepoName]      
   ,[ResponseName] = a.[ResponseName]      
   ,[ResponseRN] =a.[ResponseRN]      
   ,[Date] =a.[Date]      
   ,[DateID] =a.[DateID]      
   ,[UpdateDate] =a.[UpdateDate]      
      from  #BI_DB_Deposits_updates   a      
        join BI_DB_dbo.BI_DB_Deposits b      
        on a.DepositID=b.DepositID      
       
      
      
 INSERT INTO BI_DB_dbo.BI_DB_Deposits   ([DepositID]      
           ,[CID]      
           ,[FundingID]      
           ,[FundingType]      
           ,[CurrencyID]      
           ,[PaymentStatusID]      
           ,[ManagerID]      
   ,[RiskManagementStatusID]      
           ,[Amount]      
           ,[ExchangeRate]      
           ,[ModificationDate]      
           ,[TransactionID]      
   ,[IPAddress]      
           ,[Approved]      
           ,[Commission]      
           ,[PaymentDate]      
           ,[ClearingHouseEffectiveDate]      
           ,[OldPaymentID]      
           ,[IsFTD]      
           ,[ProcessorValueDate]      
           ,[RefundVerificationCode]      
           ,[DepotID]      
           ,[MatchStatusID]      
           ,[FunnelID]      
           ,[Code]      
           ,[ExTransactionID]      
           ,[PaymentStatus_PaymentStatusID]      
           ,[PaymentStatus_Name]      
           ,[RiskManagementStatus_RiskManagementStatusID]      
           ,[RiskManagementStatus_Name]      
           ,[Channel]      
           ,[SubChannel]      
           ,[Region]      
           ,[Country]      
           ,[FirstDepositAttempt]      
           ,[FirstDepositDate]      
           ,[Registered]      
           ,[SerialID]      
           ,[Funnel]      
           ,[FunnelFrom]      
           ,[AcquisitionFunnel]      
           ,[BinCode]      
           ,[CreditCardType]      
           ,[CardSubType]      
           ,[CardCategory]      
           ,[BINCountry]      
        ,[DepoName]      
           ,[ResponseName]      
           ,[ResponseRN]      
           ,[Date]      
           ,[DateID]      
           ,[UpdateDate])      
    select       
   a.[DepositID]      
           ,a.[CID]      
           ,a.[FundingID]      
           ,a.[FundingType]      
           ,a.[CurrencyID]      
           ,a.[PaymentStatusID]      
           ,a.[ManagerID]      
           ,a.[RiskManagementStatusID]      
           ,a.[Amount]      
           ,a.[ExchangeRate]      
           ,a.[ModificationDate]      
           ,a.[TransactionID]      
           ,a.[IPAddress]      
           ,a.[Approved]      
           ,a.[Commission]      
           ,a.[PaymentDate]      
           ,a.[ClearingHouseEffectiveDate]      
           ,a.[OldPaymentID]      
           ,a.[IsFTD]      
           ,a.[ProcessorValueDate]      
           ,a.[RefundVerificationCode]      
           ,a.[DepotID]      
           ,a.[MatchStatusID]      
           ,a.[FunnelID]      
           ,a.[Code]      
           ,a.[ExTransactionID]      
           ,a.[PaymentStatus_PaymentStatusID]      
           ,a.[PaymentStatus_Name]      
           ,a.[RiskManagementStatus_RiskManagementStatusID]      
           ,a.[RiskManagementStatus_Name]      
           ,a.[Channel]      
           ,a.[SubChannel]      
           ,a.[Region]      
           ,a.[Country]      
           ,a.[FirstDepositAttempt]      
           ,a.[FirstDepositDate]      
           ,a.[Registered]      
           ,a.[SerialID]      
           ,a.[Funnel]      
           ,a.[FunnelFrom]      
           ,a.[AcquisitionFunnel]      
           ,a.[BinCode]      
           ,a.[CreditCardType]      
           ,a.[CardSubType]      
           ,a.[CardCategory]      
           ,a.[BINCountry]      
           ,a.[DepoName]      
           ,a.[ResponseName]      
           ,a.[ResponseRN]      
           ,a.[Date]      
           ,a.[DateID]      
           ,a.[UpdateDate]      
    FROM #BI_DB_Deposits_updates  a       
 left join BI_DB_dbo.BI_DB_Deposits b      
 on a.DepositID=b.DepositID      
 where  b.DepositID is null      
      
end       
      
             
         
      
      
       
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_H_Deposits` | synapse_sp | BI_DB_dbo | SP_H_Deposits | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_H_Deposits.sql` |
| `DWH_dbo.Fact_BillingDeposit` | synapse | DWH_dbo | Fact_BillingDeposit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `DWH_dbo.Dim_PaymentStatus` | synapse | DWH_dbo | Dim_PaymentStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PaymentStatus.md` |
| `DWH_dbo.Dim_Funnel` | synapse | DWH_dbo | Dim_Funnel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Funnel.md` |
| `BI_DB_dbo.External_etoro_Dictionary_RiskManagementStatus` | unresolved | BI_DB_dbo | External_etoro_Dictionary_RiskManagementStatus | `—` |
| `BI_DB_dbo.External_etoro_Billing_Funding_Datafactory` | unresolved | BI_DB_dbo | External_etoro_Billing_Funding_Datafactory | `—` |
| `DWH_dbo.Dim_FundingType` | synapse | DWH_dbo | Dim_FundingType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `BI_DB_dbo.External_etoro_BackOffice_CustomerAllTimeAggregatedData` | unresolved | BI_DB_dbo | External_etoro_BackOffice_CustomerAllTimeAggregatedData | `—` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `BI_DB_dbo.External_etoro_Dictionary_MarketingRegion` | unresolved | BI_DB_dbo | External_etoro_Dictionary_MarketingRegion | `—` |
| `BI_DB_dbo.External_etoro_Billing_Funding` | unresolved | BI_DB_dbo | External_etoro_Billing_Funding | `—` |
| `DWH_dbo.Dim_CardType` | synapse | DWH_dbo | Dim_CardType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CardType.md` |
| `DWH_dbo.Dim_CountryBin` | synapse | DWH_dbo | Dim_CountryBin | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CountryBin.md` |
| `DWH_dbo.Dim_BillingDepot` | synapse | DWH_dbo | Dim_BillingDepot | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md` |
| `BI_DB_dbo.External_etoro_History_DepositAction_Yesterday` | unresolved | BI_DB_dbo | External_etoro_History_DepositAction_Yesterday | `—` |
| `BI_DB_dbo.External_etoro_Dictionary_Response` | unresolved | BI_DB_dbo | External_etoro_Dictionary_Response | `—` |
| `DWH_dbo.Dim_Affiliate` | synapse | DWH_dbo | Dim_Affiliate | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Affiliate.md` |
| `DWH_dbo.Dim_Channel` | synapse | DWH_dbo | Dim_Channel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Channel.md` |
