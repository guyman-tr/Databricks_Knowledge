# DWH_dbo.Fact_BillingDeposit

> The central deposit fact table, recording every monetary deposit transaction made by customers on the eToro trading platform. Each row represents a single deposit attempt (successful or failed) by a customer (CID), capturing the full payment lifecycle from initiation through approval/decline, along with payment method details, risk management checks, and payment provider responses.


| Property                 | Value                                                                                                                                                                   |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Schema**               | DWH_dbo                                                                                                                                                                 |
| **Object Type**          | Table                                                                                                                                                                   |
| **Production Source**    | `etoroDB.Billing.Deposit` + `etoroDB.Billing.Funding`                                                                                                                   |
| **Refresh**              | Daily (ETL SP: SP_Fact_BillingDeposit_DL_To_Synapse)                                                                                                                   |
|                          |                                                                                                                                                                         |
| **Synapse Distribution** | HASH(DepositID)                                                                                                                                                         |
| **Synapse Index**        | CLUSTERED INDEX (DepositID), NONCLUSTERED INDEX (PaymentStatusID, ExpirationDateID)                                                                                     |
|                          |                                                                                                                                                                         |
| **UC Target**            | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`                                                                                                             |
| **UC Format**            | Delta                                                                                                                                                                   |
| **UC Partitioned By**    | `etr_y`, `etr_ym`, `etr_ymd`                                                                                                                                            |
| **UC Table Type**        | EXTERNAL                                                                                                                                                                |
| **Row Count**            | ~73.9 million                                                                                                                                                           |
| **Date Span**            | 2007-08-27 to 2026-03-10 (active, ongoing)                                                                                                                              |


---

## 1. Business Meaning

`DWH_dbo.Fact_BillingDeposit` is the central deposit fact table in the Synapse DWH, recording every monetary deposit transaction made by customers on the eToro trading platform. Each row represents a single deposit attempt (successful or failed) by a customer (CID), capturing the full payment lifecycle from initiation through approval/decline, along with payment method details, risk management checks, and payment provider responses.

The BI Dictionary on Confluence confirms: "Stores financial records of client deposits, including type, amount, and date. CID, Deposit Time, Modification Date level. Filter PaymentStatusID = 2 for Approved."

Data flows: `etoroDB.Billing.Deposit` + `etoroDB.Billing.Funding` → Data Lake → `DWH_staging.etoro_Billing_Deposit` + `DWH_staging.etoro_Billing_Funding` → `SP_Fact_BillingDeposit_DL_To_Synapse` → `Ext_FBD_Fact_BillingDeposit` (staging buffer) → `Fact_BillingDeposit` → `SP_Fact_BillingDeposit` (post-processing: MOPCountry, BankName, CardCategory enrichment).

The ~70 `nvarchar(max)` columns suffixed with AsString/AsDecimal/AsInteger/AsDateTime/AsBool are extracted from XML blob fields (FundingData and PaymentData) in the source Billing tables using the `DWH_dbo.ExtractXMLValue` function. They contain payment provider response data.

---

## 2. Business Logic

### 2.1 Payment Lifecycle

- **PaymentStatusID** tracks the deposit's state: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE, 37=ChargebackReversal, 38=RefundReversal, 39=ReversedDeposit
- **PaymentStatusID=2 (Approved)** is the main filter for successful deposits (65.5% of all records)
- **RiskManagementStatusID**: 1=Success, 2–69=various decline/block reasons (KYC, velocity, country blocks, etc.)
- **MatchStatusID** (electronic verification): 0=None (97.4%), 2=Verified, 3=NotVerified

### 2.2 Financial Amounts

- **Amount**: deposit amount in the deposit currency (CurrencyID)
- **AmountUSD**: computed as Amount × ExchangeRate during ETL (USD-equivalent)
- **Commission**: commission charged on the deposit
- **ExchangeRate**: conversion rate to USD at time of deposit
- **BaseExchangeRate**: base rate before exchange fee markup
- **ExchangeFee**: fee in basis points applied to the exchange rate
- **BonusAmount**: bonus credited (mostly NULL — only ~11K non-null out of 73.9M)
- Amount values are capped at ±99,999,999 in ETL (amounts ≥ ±1,000,000,000 → 99,999,999) — fix added 2025-04-17 after a DWH process failure

### 2.3 Payment Method (MOP)

- **FundingTypeID**: payment method (1=CreditCard, 2=WireTransfer, 3=PayPal, 8=MoneyBookers/Skrill, 11=Giropay, 22=UnionPay, 28=OnlineBanking, 29=ACH, 33=eToroMoney, 34=iDEAL, 35=Trustly, etc.)
- **DepotID**: payment processor/depot combination (87=CyberSource, 92=Checkout.com, 12=PayPal, 88=eToroMoney/PWMB, etc.)
- **CardTypeIDAsInteger**: card network (1=Visa, 2=MasterCard, 3=Diners, etc.)
- **CardCategory**: card tier (CLASSIC, STANDARD, PLATINUM, GOLD, PREPAID, etc. — 171 distinct values; note STANDART typo exists)
- **BinCodeAsString**: first 6–8 digits of card number (BIN code)
- **BankName**: issuing bank name (enriched from Dim_CountryBin via BinCode)
- **MOPCountry**: country of the payment method (enriched from CountryIDAsString via Dim_Country)

### 2.4 Customer & Session Context

- **CID**: customer ID (FK to Dim_Customer)
- **IsFTD**: 1=First Time Deposit for this customer, 0=subsequent deposit (8% are FTD)
- **PlatformID**: platform used for the deposit session (resolved from Fact_CustomerAction where ActionTypeID=14, matched on CID+SessionID; values like 99, 102, 105, 108, 111, 115, 117 — internal platform IDs, not Dim_Platform values)
- **SessionID**: session identifier (always populated, 0 NULLs)
- **FunnelID**: deposit funnel (36=default/93.8%, 9=Cashier, 43=GCC, etc. — FK to Dim_Funnel)

### 2.5 Regulatory & Compliance

- **ProcessRegulationID**: regulatory entity processing the deposit (1=CySEC, 2=FCA, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, etc. — FK to Dim_Regulation; 63.7% NULL for older records)
- **DocumentRequired**: 1=document required for this deposit (56.7%), 0=not required
- **IsRefundExcluded**: 1=deposit excluded from refund eligibility (1.3%)

### 2.6 Time Dimensions

- **ModificationDate** + **ModificationDateID** (YYYYMMDD): when the deposit record was last modified — primary date dimension
- **PaymentDate**: when the payment was initiated
- **ProcessorValueDate**: when the processor settled the transaction (~29% populated)
- **ExpirationDateID**: card expiration date encoded as YYYYMM (computed from ExpirationDateAsString XML field; 190001=missing/invalid)
- **UpdateDate**: ETL load timestamp (note: for pre-2020 migrated records, many show 2020-02-09 08:58:22.800 = migration date)
- **ClearingHouseEffectiveDate**: clearing house settlement date

### 2.7 Recurring & Modern Features

- **IsRecurring**: 1=recurring deposit (0.9%), 0=not recurring (55.6%), NULL=pre-feature (43.4%). Derived via OUTER APPLY to `DWH_staging.etoro_Billing_RecurringDeposit`
- **PaymentGeneration**: NULL=pre-feature (43.4%), 0=legacy (20.2%), 1=new generation (36.3%)
- **IsAftSupportedAsBool**, **IsAftEligibleAsBool**, **IsAftProcessedAsBool**: Account Funding Transaction (AFT) flags, added 2025-03-02. ~14% populated.
- **FlowID**: deposit flow identifier (NULL=95.7%, 1=standard flow, 3=alternative flow)

### 2.8 ETL-Enriched Columns

- **BankName**: enriched from Dim_CountryBin via BinCodeAsString (in SP_Fact_BillingDeposit)
- **CardCategory**: enriched from Dim_CountryBin via BinCodeAsString
- **MOPCountry**: enriched from CountryIDAsString via Dim_Country (3-way resolution: numeric ID → LongAbbreviation → Abbreviation)

### 2.9 Column `v` (Truncated Alias Bug)

The column named `v` is actually `ClientBankNameAsString` extracted from the FundingData XML. In the ETL SP (`SP_Fact_BillingDeposit_DL_To_Synapse`), the code reads: `[DWH_dbo].[ExtractXMLValue]('ClientBankNameAsString',f.FundingData) as v` — the alias was accidentally truncated. This column contains the client's bank name as provided by the payment provider.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

In Synapse, HASH(DepositID) with CLUSTERED INDEX. Always include DepositID in JOINs/WHERE for optimal performance. The secondary NONCLUSTERED INDEX on (PaymentStatusID, ExpirationDateID) supports status-based queries.

### 3.1b UC Storage

In Databricks, Delta EXTERNAL table partitioned by `etr_y`, `etr_ym`, `etr_ymd`. Always filter on partition columns for pruning.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
| --- | --- |
| All approved deposits for a customer | `WHERE PaymentStatusID = 2 AND CID = @cid` |
| Daily deposit volume by payment method | `GROUP BY ModificationDateID, FundingTypeID WHERE PaymentStatusID = 2` |
| First-time deposits | `WHERE IsFTD = 1 AND PaymentStatusID = 2` |
| Chargeback analysis | `WHERE PaymentStatusID IN (11, 37)` — 11=Chargeback, 37=ChargebackReversal |
| Deposits by regulation | `JOIN Dim_Regulation ON ProcessRegulationID = ID WHERE PaymentStatusID = 2` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
| --- | --- | --- |
| Dim_Customer | ON CID = RealCID | Customer details |
| Dim_Currency | ON CurrencyID = CurrencyID | Currency name |
| Dim_PaymentStatus | ON PaymentStatusID = PaymentStatusID | Payment status name |
| Dim_FundingType | ON FundingTypeID = FundingTypeID | Payment method name |
| Dim_BillingDepot | ON DepotID = DepotID | Processor/depot details |
| Dim_CardType | ON CardTypeIDAsInteger = CardTypeID | Card network name |
| Dim_Country | ON CountryIDAsInteger = CountryID | Customer's country (from payment provider) |
| Dim_CountryBin | ON CAST(BinCodeAsString AS INT) = BinCode | BIN code → issuing bank, card category |
| Dim_Regulation | ON ProcessRegulationID = ID | Regulatory entity |
| Dim_Date | ON ModificationDateID = DateID | Date dimension |
| Dim_RiskManagementStatus | ON RiskManagementStatusID = RiskManagementStatusID | Risk check result |
| Dim_EvMatchStatus | ON MatchStatusID = EvMatchStatusID | Electronic verification status |
| Dim_Funnel | ON FunnelID = FunnelID | Deposit funnel |
| Dim_BillingProtocolMIDSettingsID | ON ProtocolMIDSettingsID = ProtocolMIDSettingsID | MID/protocol settings |

### 3.4 Gotchas

- **Always filter PaymentStatusID = 2** for approved deposits. The table contains ALL attempts (approved, declined, technical, canceled, etc.)
- **Column `v`** is actually `ClientBankNameAsString` — a truncated alias bug in the ETL SP. Don't ignore it or treat it as meaningless.
- **PlatformID** values (99, 102, 105, etc.) do NOT map to Dim_Platform (0–3). They come from Fact_CustomerAction and are internal platform IDs. Many are NULL for older records.
- **UpdateDate = 2020-02-09** for ~30M+ records doesn't mean they were updated that day — it's the data lake migration date for historical records.
- **ExpirationDateID = 190001** means missing/invalid card expiration. Valid values are in YYYYMM format (e.g., 202406).
- **STANDART** vs **STANDARD** in CardCategory — both exist due to upstream data quality issue. Treat as equivalent.
- **AmountUSD** = Amount × ExchangeRate — it's the USD-equivalent, NOT the exchange rate markup.
- **BonusAmount** is almost entirely NULL (99.98%). Don't rely on it for bonus analysis — use separate bonus tables.
- **Approved** column is almost entirely NULL (99.99%). Use PaymentStatusID instead.

---

## 4. Elements

### Confidence Tier Legend

Each column description includes a confidence tier indicating how the description was derived and validated.

| Tier | Stars | Source | Meaning |
| --- | --- | --- | --- |
| 5 | ★★★★★ | Domain expert / Glossary | Confirmed by human expert |
| 4 | ★★★★☆ | Upstream production wiki | Validated via code-is-king pipeline |
| 3 | ★★★☆☆ | Synapse SP code / CASE patterns | Extracted from ETL logic |
| 2 | ★★☆☆☆ | Live data distribution | Inferred from data patterns |
| 1 | ★☆☆☆☆ | Column name inference | [UNVERIFIED] — needs review |

The parenthetical at the end of each description shows `(Tier N — source)` where *source* is the production table, ETL SP, or "domain expert" that the description was derived from.


| # | Element | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 1 | CID | int | YES | Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code) |
| 2 | CurrencyID | int | YES | Deposit currency: 1=USD, 2=EUR, 3=GBP, 5=AUD, 6=CHF, etc. (FK to Dim_Currency). 33 distinct values. (Tier 2 — Dim_Currency lookup) |
| 3 | Commission | money | YES | Commission charged on the deposit transaction, in deposit currency. Typically 0. (Tier 3 — SP code) |
| 4 | Approved | bit | YES | [DEPRECATED] Legacy approval flag. Almost entirely NULL (99.99%). Use PaymentStatusID instead. (Tier 3 — live data) |
| 5 | ModificationDate | datetime | YES | Timestamp of last modification to the deposit record. Primary date column for filtering. (Tier 3 — SP code) |
| 6 | ModificationDateID | int | YES | Integer date key in YYYYMMDD format derived from ModificationDate. ETL-computed: `CONVERT(INT, CONVERT(VARCHAR, ModificationDate, 112))`. FK to Dim_Date. (Tier 3 — SP code) |
| 7 | FundingID | int | YES | Unique identifier for the funding instrument used. FK to source staging table etoro_Billing_Funding. (Tier 3 — SP code) |
| 8 | ExchangeRate | numeric(16,8) | YES | Conversion rate from deposit currency to USD at time of deposit. Used to compute AmountUSD. (Tier 3 — SP code) |
| 9 | DepositID | int | YES | Unique identifier for the deposit transaction. Distribution key and clustered index column. Effectively the primary key. (Tier 3 — SP code) |
| 10 | ProcessorValueDate | datetime | YES | Date when the payment processor settled the transaction. ~29% populated (only for certain payment methods). (Tier 2 — live data) |
| 11 | DepotID | int | YES | Payment processor/depot: 87=CyberSource, 92=Checkout.com, 12=PayPal, 88=eToroMoney/PWMB, 114=Worldpay, etc. FK to Dim_BillingDepot. (Tier 2 — Dim_BillingDepot lookup) |
| 12 | SecuredCardDataAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Secured or tokenized card data from payment provider. (Tier 3 — SP code) |
| 13 | BinCodeAsString | nvarchar(max) | YES | Extracted from FundingData XML via ExtractXMLValue. First 6–8 digits of card number (BIN code). Used for BankName/CardCategory enrichment via Dim_CountryBin. (Tier 5 — domain expert) |
| 14 | BinCountryIDAsInteger | int | YES | Extracted from FundingData XML via ExtractXMLValue. Country ID associated with the BIN code. (Tier 3 — SP code) |
| 15 | CardTypeIDAsInteger | int | YES | Extracted from FundingData XML via ExtractXMLValue. Card network: 1=Visa, 2=MasterCard, 3=Diners, etc. FK to Dim_CardType. (Tier 3 — SP code) |
| 16 | PaymentStatusID | int | YES | Payment lifecycle status: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE, 37=ChargebackReversal, 38=RefundReversal, 39=ReversedDeposit. FK to Dim_PaymentStatus. Filter 2 for approved. (Tier 3 — SP code) |
| 17 | ManagerID | int | YES | Manager ID from production source. (Tier 3 — SP code) |
| 18 | RiskManagementStatusID | int | YES | Risk check outcome: 1=Success, 2–69=various decline/block reasons (KYC, velocity, country blocks). FK to Dim_RiskManagementStatus. (Tier 3 — SP code) |
| 19 | Amount | money | YES | Deposit amount in deposit currency. Capped at ±99,999,999 in ETL (fix 2025-04-17). (Tier 3 — SP code) |
| 20 | PaymentDate | datetime | YES | When the payment was initiated. (Tier 3 — SP code) |
| 21 | IPAddress | numeric | YES | IP address of the customer at deposit time (numeric representation). (Tier 3 — SP code) |
| 22 | ClearingHouseEffectiveDate | datetime | YES | Clearing house settlement date. (Tier 3 — SP code) |
| 23 | IsFTD | int | YES | First-time deposit flag: 1=FTD for this customer, 0=subsequent deposit. 8% are FTD. (Tier 3 — SP code) |
| 24 | RefundVerificationCode | varchar | YES | Verification code for refund processing. (Tier 3 — SP code) |
| 25 | MatchStatusID | tinyint | YES | Electronic verification status: 0=None (97.4%), 2=Verified, 3=NotVerified. FK to Dim_EvMatchStatus. (Tier 3 — SP code) |
| 26 | BonusStatusID | int | YES | Bonus status for this deposit. (Tier 3 — SP code) |
| 27 | BonusAmount | money | YES | Bonus credited. Almost entirely NULL (99.98%). Don't rely for bonus analysis. (Tier 3 — live data) |
| 28 | BonusErrorCode | int | YES | Error code if bonus processing failed. (Tier 3 — SP code) |
| 29 | ExTransactionID | varchar | YES | External transaction ID from payment provider. (Tier 3 — SP code) |
| 30 | FundingTypeID | int | YES | Payment method: 1=CreditCard, 2=WireTransfer, 3=PayPal, 8=MoneyBookers/Skrill, 11=Giropay, 22=UnionPay, 28=OnlineBanking, 29=ACH, 33=eToroMoney, 34=iDEAL, 35=Trustly, etc. FK to Dim_FundingType. (Tier 2 — Dim_FundingType lookup) |
| 31 | IsRefundExcluded | int | YES | 1=deposit excluded from refund eligibility (1.3%), 0=eligible. (Tier 3 — SP code) |
| 32 | DocumentRequired | int | YES | 1=document required for this deposit (56.7%), 0=not required. (Tier 3 — SP code) |
| 33 | UpdateDate | datetime | YES | ETL load timestamp. For pre-2020 migrated records, many show 2020-02-09 08:58:22.800 = migration date. (Tier 3 — SP code) |
| 34 | ExpirationDateID | int | YES | Card expiration encoded as YYYYMM. Computed from ExpirationDateAsString XML. 190001=missing/invalid. (Tier 3 — SP code) |
| 35 | CountryIDAsInteger | int | YES | Extracted from FundingData/PaymentData XML. Country ID from payment provider. FK to Dim_Country. (Tier 3 — SP code) |
| 36 | StateIDAsInteger | int | YES | Extracted from FundingData/PaymentData XML. State/region ID from payment provider. (Tier 3 — SP code) |
| 37 | BankIDAsInteger | int | YES | Extracted from FundingData/PaymentData XML. Bank identifier. (Tier 3 — SP code) |
| 38 | AccountNameAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Account name from payment provider. (Tier 3 — SP code) |
| 39 | AccountTypeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Account type (e.g., checking, savings). (Tier 3 — SP code) |
| 40 | BankAccountAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Bank account identifier. (Tier 3 — SP code) |
| 41 | BankAddressAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Bank address. (Tier 3 — SP code) |
| 42 | BankCodeAsDecimal | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Bank code (numeric). (Tier 3 — SP code) |
| 43 | BankDetailsAccountIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Bank details account identifier. (Tier 3 — SP code) |
| 44 | BankIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Bank ID as string. (Tier 3 — SP code) |
| 45 | BankNameAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Bank name from payment provider. (Tier 3 — SP code) |
| 46 | BICCodeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. BIC/SWIFT code. (Tier 3 — SP code) |
| 47 | CIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Customer ID as string from payment provider. (Tier 3 — SP code) |
| 48 | v | nvarchar(max) | YES | [Truncated alias bug] Client bank name. Extracted from FundingData XML via ExtractXMLValue('ClientBankNameAsString',f.FundingData) as v. (Tier 3 — SP code) |
| 49 | CustomerAddressAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Customer address from payment provider. (Tier 3 — SP code) |
| 50 | CustomerNameAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Customer name from payment provider. (Tier 3 — SP code) |
| 51 | FundingType | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Funding type name from payment provider. (Tier 3 — SP code) |
| 52 | MaskedAccountIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Masked account identifier. (Tier 3 — SP code) |
| 53 | PurseAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. E-wallet purse identifier. (Tier 3 — SP code) |
| 54 | RoutingNumberAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. ACH routing number. (Tier 3 — SP code) |
| 55 | SecureIDAsDecimal | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Secure identifier. (Tier 3 — SP code) |
| 56 | SortCodeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. UK sort code. (Tier 3 — SP code) |
| 57 | AccountBalanceAsDecimal | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Account balance from payment provider. (Tier 3 — SP code) |
| 58 | AccountHolderAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Account holder name. (Tier 3 — SP code) |
| 59 | AccountIDAsDecimal | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Account identifier. (Tier 3 — SP code) |
| 60 | ACHBankAccountIDAsInteger | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. ACH bank account identifier. (Tier 3 — SP code) |
| 61 | Address1AsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Address line 1. (Tier 3 — SP code) |
| 62 | Address2AsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Address line 2. (Tier 3 — SP code) |
| 63 | AdviseAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Advice message from payment provider. (Tier 3 — SP code) |
| 64 | AvailableBalanceAsDecimal | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Available balance from payment provider. (Tier 3 — SP code) |
| 65 | BankCodeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Bank code as string. (Tier 3 — SP code) |
| 66 | BillNumberAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Bill number. (Tier 3 — SP code) |
| 67 | BuildingNumberAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Building number. (Tier 3 — SP code) |
| 68 | CardHolderPhoneNumberBodyAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Cardholder phone number. (Tier 3 — SP code) |
| 69 | CardHolderPhoneNumberPrefixAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Cardholder phone prefix. (Tier 3 — SP code) |
| 70 | CardNumberAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Card number (masked or tokenized). (Tier 3 — SP code) |
| 71 | CityAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. City from payment provider. (Tier 3 — SP code) |
| 72 | CountryIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Country ID as string. Used for MOPCountry enrichment via Dim_Country. (Tier 3 — SP code) |
| 73 | CountryNameAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Country name from payment provider. (Tier 3 — SP code) |
| 74 | CreatedAtAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Creation timestamp from payment provider. (Tier 3 — SP code) |
| 75 | CurrentBalanceAsDecimal | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Current balance from payment provider. (Tier 3 — SP code) |
| 76 | CustomerIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Customer ID from payment provider. (Tier 3 — SP code) |
| 77 | EmailAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Email from payment provider. (Tier 3 — SP code) |
| 78 | EndPointIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Endpoint identifier. (Tier 3 — SP code) |
| 79 | ErrorCodeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Error code from payment provider. (Tier 3 — SP code) |
| 80 | ErrorTypeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Error type from payment provider. (Tier 3 — SP code) |
| 81 | FirstNameAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. First name from payment provider. (Tier 3 — SP code) |
| 82 | IBANCodeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. IBAN code. (Tier 3 — SP code) |
| 83 | InitialTransactionIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Initial transaction ID from payment provider. (Tier 3 — SP code) |
| 84 | IPAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. IP address as string. (Tier 3 — SP code) |
| 85 | LanguageIDAsInteger | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Language ID from payment provider. (Tier 3 — SP code) |
| 86 | LastNameAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Last name from payment provider. (Tier 3 — SP code) |
| 87 | MD5AsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. MD5 hash from payment provider. (Tier 3 — SP code) |
| 88 | PayerAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payer identifier. (Tier 3 — SP code) |
| 89 | PayerBusiness | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payer business indicator. (Tier 3 — SP code) |
| 90 | PayerIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payer ID from payment provider. (Tier 3 — SP code) |
| 91 | PayerPurseAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payer purse identifier. (Tier 3 — SP code) |
| 92 | PayerStatus | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payer status from payment provider. (Tier 3 — SP code) |
| 93 | PaymentAmountAsDecimal | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payment amount from payment provider. (Tier 3 — SP code) |
| 94 | PaymentDateAsDateTime | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payment date from payment provider. (Tier 3 — SP code) |
| 95 | PaymentGuaranteeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payment guarantee indicator. (Tier 3 — SP code) |
| 96 | PaymentModeAsInteger | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payment mode from payment provider. (Tier 3 — SP code) |
| 97 | PaymentProviderTransactionStatusAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Transaction status from payment provider. (Tier 3 — SP code) |
| 98 | PaymentStatusAsInteger | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payment status from payment provider (raw). (Tier 3 — SP code) |
| 99 | PaymentTypeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payment type from payment provider. (Tier 3 — SP code) |
| 100 | PlaidItemIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Plaid item identifier for bank linking. (Tier 3 — SP code) |
| 101 | PlaidNamesAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Plaid account names. (Tier 3 — SP code) |
| 102 | PlatformIDAsInteger | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Platform ID from payment provider (raw). (Tier 3 — SP code) |
| 103 | PromotionCodeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Promotion code used. (Tier 3 — SP code) |
| 104 | PSPCodeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payment service provider code. (Tier 3 — SP code) |
| 105 | RapidFirstNameAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. First name from Rapid payment flow. (Tier 3 — SP code) |
| 106 | RapidLastNameAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Last name from Rapid payment flow. (Tier 3 — SP code) |
| 107 | ResponseMessageAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Response message from payment provider. (Tier 3 — SP code) |
| 108 | ResponseTimeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Response time from payment provider. (Tier 3 — SP code) |
| 109 | SecretKeyAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Secret key or token reference. (Tier 3 — SP code) |
| 110 | ThreeDsAsJson | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. 3DS authentication data from payment provider. (Tier 3 — SP code) |
| 111 | ThreeDsResponseType | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. 3DS response type. (Tier 3 — SP code) |
| 112 | TokenAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Payment token reference. (Tier 3 — SP code) |
| 113 | TransactionIDAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Transaction ID from payment provider. (Tier 3 — SP code) |
| 114 | ZipCodeAsString | nvarchar(max) | YES | Extracted from FundingData/PaymentData XML via ExtractXMLValue. Zip/postal code. (Tier 3 — SP code) |
| 115 | BaseExchangeRate | numeric(16,8) | YES | Base conversion rate before exchange fee markup. BaseExchangeRate + ExchangeFee markup = ExchangeRate. (Tier 3 — SP code) |
| 116 | ExchangeFee | int | YES | Exchange fee in basis points. Common values: 0 (no fee, 34%), 150 (1.5%, 29%), 50 (0.5%, 10%). (Tier 2 — live data) |
| 117 | ProtocolMIDSettingsID | int | YES | Merchant ID / protocol settings configuration. FK to Dim_BillingProtocolMIDSettingsID. Maps depot + regulation + currency to processor-specific parameters. (Tier 2 — Dim lookup) |
| 118 | FunnelID | int | YES | Deposit funnel/entry point: 36=Default (93.8%), 9=Cashier, 43=GCCInstantBankTransfer, etc. FK to Dim_Funnel. (Tier 2 — Dim_Funnel lookup) |
| 119 | AmountUSD | decimal(11,2) | YES | Deposit amount in USD. ETL-computed: Amount × ExchangeRate. (Tier 3 — SP code) |
| 120 | SessionID | bigint | YES | Session identifier for the deposit attempt. Always populated (0 NULLs). Used to resolve PlatformID via Fact_CustomerAction. (Tier 3 — SP code) |
| 121 | PlatformID | int | YES | Internal platform ID resolved from Fact_CustomerAction (ActionTypeID=14, matched on CID+SessionID). Values: 111, 105, 117, 108, 115, 102, etc. Does NOT map to Dim_Platform. 40.6% NULL. (Tier 3 — SP code) |
| 122 | MOPCountry | varchar(50) | YES | Country of the payment method. ETL-enriched from CountryIDAsString via Dim_Country (3-way resolution: numeric ID → LongAbbreviation → Abbreviation). ~14.5% populated. (Tier 3 — SP code) |
| 123 | SwiftCodeAsString | nvarchar(max) | YES | SWIFT/BIC code from FundingData XML. (Tier 3 — SP code) |
| 124 | ClientBankNameAsString | nvarchar(max) | YES | Client bank name from FundingData XML. (Tier 3 — SP code) |
| 125 | BankName | varchar(100) | YES | Issuing bank name. ETL-enriched from Dim_CountryBin by matching BinCodeAsString. (Tier 3 — SP code) |
| 126 | CardCategory | varchar(50) | YES | Card tier/category (CLASSIC, STANDARD, PLATINUM, GOLD, PREPAID, etc.). ETL-enriched from Dim_CountryBin. 171 distinct values. Note: STANDART typo exists alongside STANDARD. (Tier 3 — SP code + live data) |
| 127 | PaymentGeneration | int | YES | Payment system generation: NULL=pre-feature, 0=legacy payment system, 1=new generation. (Tier 2 — live data) |
| 128 | ProcessRegulationID | int | YES | Regulatory entity: 1=CySEC, 2=FCA, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 13=MAS. FK to Dim_Regulation. 63.7% NULL. (Tier 2 — Dim_Regulation lookup) |
| 129 | MerchantAccountID | int | YES | Merchant account used for processing. High cardinality (~40+ values). 49.4% NULL. (Tier 2 — live data) |
| 130 | IsSetBalanceCompleted | int | YES | Whether the balance update completed after deposit: 1=completed (40.1%), 0=not completed (16.5%), NULL=pre-feature (43.4%). (Tier 2 — live data) |
| 131 | RoutingReasonID | int | YES | Reason for payment routing decision: 1=default routing, 3/5/6/7=various routing rules. 67.9% NULL. (Tier 2 — live data) |
| 132 | IsRecurring | int | YES | Whether this is a recurring deposit: 1=recurring (0.9%), 0=not recurring (55.6%), NULL=pre-feature (43.4%). Derived from etoro_Billing_RecurringDeposit. (Tier 3 — SP code) |
| 133 | FlowID | int | YES | Deposit flow type: 1=standard flow, 2/3=alternative flows, 0=unknown. 95.7% NULL. (Tier 2 — live data) |
| 134 | IsAftSupportedAsBool | bit | YES | Whether Account Funding Transaction (AFT) is supported. Added 2025-03-02. ~14% populated. (Tier 3 — SP code) |
| 135 | IsAftEligibleAsBool | bit | YES | Whether the transaction is eligible for AFT. Added 2025-03-02. ~14% populated. (Tier 3 — SP code) |
| 136 | IsAftProcessedAsBool | bit | YES | Whether AFT was actually processed. Added 2025-03-02. ~14% populated. (Tier 3 — SP code) |
| 137 | etr_y | string | YES | Year partition column (Databricks-layer). Filter for partition pruning in UC queries. (Tier 3 — UC metadata) |
| 138 | etr_ym | string | YES | Year-month partition column (Databricks-layer). (Tier 3 — UC metadata) |
| 139 | etr_ymd | string | YES | Year-month-day partition column (Databricks-layer). Most granular partition key. (Tier 3 — UC metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
| --- | --- | --- | --- |
| CID, PaymentStatusID, ManagerID, etc. | etoroDB.Billing.Deposit | Direct | None — carried from staging |
| FundingTypeID, DepotID, IsRefundExcluded, etc. | etoroDB.Billing.Funding | Direct | Joined on FundingID |
| All *AsString columns | etoroDB.Billing.Funding.FundingData + Billing.Deposit.PaymentData | XML extraction | ExtractXMLValue('FieldName', XML) |
| IsRecurring | etoroDB.Billing.RecurringDeposit | OUTER APPLY | 1 if exists, 0 otherwise |
| PlatformID | DWH_dbo.Fact_CustomerAction | ActionTypeID=14, CID+SessionID match | Post-insert UPDATE |
| MOPCountry | DWH_dbo.Dim_Country | CountryIDAsString → CountryID/Abbreviation/LongAbbreviation | 3-way COALESCE |
| BankName, CardCategory | DWH_dbo.Dim_CountryBin | BinCodeAsString → BinCode | Post-insert UPDATE |
| AmountUSD | Computed | Amount × ExchangeRate | ETL-computed |
| ModificationDateID | Computed | CONVERT(INT, CONVERT(VARCHAR, ModificationDate, 112)) | ETL-computed |
| ExpirationDateID | Computed | From ExpirationDateAsString XML field, encoded YYYYMM | ETL-computed, 190001=missing |

### 5.2 ETL Pipeline

```
etoroDB.Billing.Deposit + Billing.Funding → Data Lake (ADF) → DWH_staging.etoro_Billing_Deposit + etoro_Billing_Funding → SP_Fact_BillingDeposit_DL_To_Synapse → Ext_FBD_Fact_BillingDeposit (staging buffer) → Fact_BillingDeposit → SP_Fact_BillingDeposit (post-processing enrichment)
```

| Step | Object | Description |
| --- | --- | --- |
| Source | etoroDB.Billing.Deposit + Billing.Funding | Production billing tables (SQL Server) |
| Lake | ADF Pipeline: DWH.DL.etoro.Billing.etoroBillingToDataLake | Daily export to Azure Data Lake |
| Staging | DWH_staging.etoro_Billing_Deposit + etoro_Billing_Funding | Raw data landing in Synapse |
| ETL | SP_Fact_BillingDeposit_DL_To_Synapse | XML extraction, computed columns, delete+insert by ModificationDateID |
| Post | SP_Fact_BillingDeposit | Enriches MOPCountry (Dim_Country), BankName+CardCategory (Dim_CountryBin), PlatformID (Fact_CustomerAction) |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
| --- | --- | --- |
| CID | DWH_dbo.Dim_Customer | Customer who made the deposit |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency |
| DepotID | DWH_dbo.Dim_BillingDepot | Payment processor/depot |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Payment lifecycle status |
| FundingTypeID | DWH_dbo.Dim_FundingType | Payment method type |
| CardTypeIDAsInteger | DWH_dbo.Dim_CardType | Card network |
| RiskManagementStatusID | DWH_dbo.Dim_RiskManagementStatus | Risk check outcome |
| MatchStatusID | DWH_dbo.Dim_EvMatchStatus | Electronic verification |
| ProcessRegulationID | DWH_dbo.Dim_Regulation | Regulatory entity |
| FunnelID | DWH_dbo.Dim_Funnel | Deposit funnel/entry point |
| ProtocolMIDSettingsID | DWH_dbo.Dim_BillingProtocolMIDSettingsID | MID/protocol configuration |
| ModificationDateID | DWH_dbo.Dim_Date | Date dimension |
| CountryIDAsInteger | DWH_dbo.Dim_Country | Payment provider country |
| BinCodeAsString | DWH_dbo.Dim_CountryBin | BIN code → bank + card category |

### 6.2 Referenced By

| Source Object | Source Element | Description |
| --- | --- | --- |
| DWH_dbo.VU_FactBilling_ForBigQuery | All columns | View exposing deposit data to BigQuery (applies RemoveSpecialChars) |
| BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms | IsFTD, FundingTypeID, DepositID | FTD resolution function |
| BI_DB_dbo.Function_Revenue_ConversionFee | DepositID, ExchangeFee | Revenue/conversion fee calculation |
| BI_DB_dbo.SP_AllDeposits | Multiple | Aggregated deposit report |
| BI_DB_dbo.SP_ChargebackReport | PaymentStatusID | Chargeback analysis |
| BI_DB_dbo.SP_DDR_Fact_MIMO_Trading_Platform | DepositID | Daily Data Report (MIMO) |
| BI_DB_dbo.SP_AML_* (multiple) | CID, Amount, PaymentStatusID | AML compliance reports |
| 50+ additional SPs in BI_DB_dbo | Various | Various BI reports and compliance |

---

## 7. Sample Queries

### 7.1 Total approved deposits by customer with payment method

```sql
SELECT fbd.CID, dft.Name AS FundingType, SUM(fbd.AmountUSD) AS TotalUSD, COUNT(*) AS DepositCount
FROM DWH_dbo.Fact_BillingDeposit fbd
JOIN DWH_dbo.Dim_FundingType dft ON fbd.FundingTypeID = dft.FundingTypeID
WHERE fbd.PaymentStatusID = 2
GROUP BY fbd.CID, dft.Name
ORDER BY TotalUSD DESC
```

### 7.2 Daily deposit volume by regulation

```sql
SELECT fbd.ModificationDateID, dr.Name AS Regulation, COUNT(*) AS Deposits, SUM(fbd.AmountUSD) AS VolumeUSD
FROM DWH_dbo.Fact_BillingDeposit fbd
JOIN DWH_dbo.Dim_Regulation dr ON fbd.ProcessRegulationID = dr.ID
WHERE fbd.PaymentStatusID = 2 AND fbd.ModificationDateID >= 20250101
GROUP BY fbd.ModificationDateID, dr.Name
ORDER BY fbd.ModificationDateID
```

### 7.3 First-time deposit analysis with customer details

```sql
SELECT fbd.CID, dc.CountryID, dcountry.Name AS Country, dft.Name AS FundingType,
       fbd.AmountUSD, fbd.PaymentDate, dps.Name AS PaymentStatus
FROM DWH_dbo.Fact_BillingDeposit fbd
JOIN DWH_dbo.Dim_Customer dc ON fbd.CID = dc.RealCID
JOIN DWH_dbo.Dim_Country dcountry ON dc.CountryID = dcountry.CountryID
JOIN DWH_dbo.Dim_FundingType dft ON fbd.FundingTypeID = dft.FundingTypeID
JOIN DWH_dbo.Dim_PaymentStatus dps ON fbd.PaymentStatusID = dps.PaymentStatusID
WHERE fbd.IsFTD = 1 AND fbd.PaymentStatusID = 2 AND fbd.ModificationDateID >= 20250101
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
| --- | --- | --- |
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862/BI+Dictionary) | Confluence | Official table description: "Stores financial records of client deposits. Filter PaymentStatusID=2 for Approved." |
| [DWH Daily Process Failure 2025-04-17](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/13120503818) | Confluence | Amount column extreme value handling — CASE added to cap at ±99,999,999 |
| [DWH Migration Fact Tables](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11445699041) | Confluence | Migration tracking — completed by Boris, "1 column a problem from Fact_CustomerAction" |
| [Deposits and withdrawals - DWH](https://etoro-jira.atlassian.net/wiki/spaces/REGTECH/pages/11894162707) | Confluence | Example queries with Dim_FundingType and Dim_BillingDepot joins |
| [Deposit in BO and statuses](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11705024980) | Confluence | PaymentStatus business meanings from CS perspective |
| [DS-2211: Quality Gates for Deposit Process](https://etoro-jira.atlassian.net/browse/DS-2211) | Jira | ADF pipeline: DWH.DL.etoro.Billing.etoroBillingToDataLake |

---

*Generated: 2026-03-15 | Quality: 8.5/10 (★★★★☆) | Phases: 13/15*
*Tiers: 0 T1, 14 T2, 110 T3, 12 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 10/10*
*Object: DWH_dbo.Fact_BillingDeposit | Type: Table | Production Source: etoroDB.Billing.Deposit + Billing.Funding*
