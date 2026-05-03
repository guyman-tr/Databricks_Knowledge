# eMoney_Tribe.AccountsActivities_AccountActivity-833937

> ~29.7M-row raw account activity transaction table from the eToro Money (eMoney) card and payment platform, covering card transactions, EPM (electronic payment method) transfers, internal loads/unloads, and POS purchases from September 2021 to present. Loaded daily via Parquet ingestion from Azure Data Lake with append-based incremental refresh.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | eMoney Platform (GPS/Modulr) via SP_eMoney_FiatDwhETL (generic Parquet COPY INTO) |
| **Refresh** | Daily incremental append by @Created |
| **Synapse Distribution** | HASH(@Id) |
| **Synapse Index** | HEAP + 4 NCIs (@Id x2, @AccountsActivities@Id-862157, partition_date) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table stores raw account activity records from the eToro Money platform, representing every financial transaction processed through the eMoney card issuing and payment infrastructure. Each row is a single transaction event identified by a GUID (`@Id`), linked to a parent activity record in `AccountsActivities_862157` via the same `@Id`.

The table captures multiple transaction types:
- **Card transactions** (POS purchases, ATM withdrawals) — identified by CardNumber, Bin, Network (Visa)
- **Internal transfers** (LOAD/UNLOAD) — moving funds between eToro trading accounts and eToro Money wallets
- **EPM transfers** (EPM_INBOUND/EPM_OUTBOUND) — bank transfers via SEPA, Faster Payments, etc.
- **Balance adjustments** — administrative corrections

The data grows rapidly: 505K rows in 2021, 1.9M in 2022, 3.0M in 2023, 5.6M in 2024, 11.5M in 2025, and 7.3M in 2026 YTD. Transaction currencies are predominantly EUR (75%) and GBP (21%), with ~4% across AUD, USD, and other currencies.

The ETL is a generic Parquet loader (`SP_eMoney_FiatDwhETL`) that COPY INTOs from `dldataplatformprodwe.dfs.core.windows.net/internal-sources/` into a staging `_tmp` table, then INSERT SELECTs into the main table using append strategy with incremental date filtering on `@Created`.

---

## 2. Business Logic

### 2.1 Transaction Direction

**What**: Transactions are directional — credits (inflows) vs debits (outflows).
**Columns Involved**: Action, TransactionAmount, TransactionCode, TransactionCodeDescription
**Rules**:
- `Action = 'Credit'` with positive TransactionAmount indicates money flowing into the account (LOAD, EPM_INBOUND)
- `Action = 'Debit'` with negative TransactionAmount indicates money flowing out (UNLOAD, EPM_OUTBOUND, POS)
- TransactionCode values: 1=LOAD, 2=POS, 4=UNLOAD, 56=EPM_OUTBOUND, 57=EPM_INBOUND

### 2.2 Multi-Currency Handling

**What**: Each transaction can involve up to four currency contexts.
**Columns Involved**: TransactionCurrencyAlpha, HolderCurrencyAlpha, BillingCurrencyAlpha, SettlementCurrencyAlpha, FxRate, SettlementConversionRate, BillRateAmount
**Rules**:
- Transaction currency = the currency of the merchant/counterparty
- Holder currency = the cardholder's account currency
- Billing currency = the currency billed to the cardholder
- Settlement currency = the currency used for scheme settlement
- FxRate applies when transaction and holder currencies differ
- For same-currency transactions, FxRate is NULL and amounts are equal across all currency levels

### 2.3 EPM (Electronic Payment Method) Transactions

**What**: Bank transfers (SEPA, Faster Payments) have dedicated EPM fields.
**Columns Involved**: EpmMethodId, EpmTransactionId, EpmTransactionType, EpmTransactionStatusCode, EpmTransactionStatus, EpmMandateId, ExternalPaymentScheme
**Rules**:
- EpmMethodId identifies the payment method (4=Faster Payments UK, 5=SEPA EU)
- EpmTransactionType: 1=outbound, 2=inbound
- EpmTransactionStatusCode + EpmTransactionStatus track the bank transfer lifecycle
- ExternalPaymentScheme, ExternalIban, ExternalBban, ExternalBIC identify the counterparty bank account

### 2.4 Fee Structure

**What**: Transactions may incur FX fees and flat (F0) fees.
**Columns Involved**: FxFeeName, FxFeeAmount, FxFeeCurrency, FxFeeReason, F0FeeName, F0FeeAmount, F0FeeCurrency, F0FeeReason, FeeGroupId, FeeGroupName
**Rules**:
- FX fees apply to cross-currency transactions
- F0 fees are flat/fixed fees
- FeeGroupId/FeeGroupName categorize the fee schedule applied (e.g., "eToro Green")
- Fee columns are NULL for fee-free transactions

### 2.5 Risk and Compliance

**What**: Transactions carry risk assessment flags.
**Columns Involved**: Suspicious, RiskRuleCodes
**Rules**:
- `Suspicious = 'Yes'` flags transactions for compliance review
- `Suspicious = 'No'` is the normal state
- RiskRuleCodes contains comma-separated risk rule identifiers (e.g., "3PA-(False)", "3rdParty (False)")

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(@Id) — optimizes single-transaction lookups and joins to sibling tables (RiskActions, SecurityChecks) that also key on @Id
- **Index**: HEAP with NCIs on @Id (x2), @AccountsActivities@Id-862157, and partition_date
- **Note**: ~29.7M rows, growing ~10M/year. Always filter by partition_date for large scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| All transactions for a holder | `WHERE HolderId = '...' AND partition_date >= '...'` |
| Daily transaction volume by type | `GROUP BY CAST(WorkDate AS DATE), TransactionCodeDescription WHERE partition_date >= '...'` |
| EPM outbound transfers in a date range | `WHERE TransactionCodeDescription = 'EPM_OUTBOUND' AND partition_date BETWEEN '...' AND '...'` |
| Cross-currency transactions with FX fees | `WHERE FxFeeAmount IS NOT NULL AND FxFeeAmount <> '' AND partition_date >= '...'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.AccountsActivities_862157 | ON @Id = @Id | Parent activity record (account-level context) |
| eMoney_Tribe.AccountsActivities_RiskActions-322546 | ON @Id = @Id | Risk action details for the transaction |
| eMoney_Tribe.AccountsActivities_SecurityChecks-471048 | ON @Id = @Id | Security check results |
| eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | ON HolderCurrencyCode = CurrencyISO | Entity name resolution (UK/Malta/New) |

### 3.4 Gotchas

- **All business columns are varchar(max)**: TransactionAmount, FxRate, etc. are stored as strings. CAST to numeric before arithmetic operations.
- **Two WorkDate columns**: `WorkDate` (varchar) and `@WorkDate` (datetime2) hold the same value in different types. Prefer `@WorkDate` for date operations.
- **Two Created columns**: `@Created` (datetime2, record-level) and `Created` (datetime2, appears to be a duplicate or later-added column). Both exist in the DDL.
- **Negative amounts = debits**: Debit transactions store negative TransactionAmount, HolderAmount, BillingAmount values.
- **NULL vs empty string**: Many columns use empty strings rather than NULL for missing data. Check both conditions.
- **PII data**: ExternalAccountName, ExternalIban, ExternalBban, BankAccountNumber, BankAccountIban, CardNumber contain sensitive payment data.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Grounded in DDL + live data, no upstream wiki |
| Tier 4 | Inferred from name only (banned in this context) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Created | datetime2(7) | YES | Record creation timestamp from the eMoney platform. Used as the incremental load watermark by SP_eMoney_FiatDwhETL. Sample: 2026-03-13 00:00:00, 2025-06-11 05:11:42. (Tier 3 — eMoney Platform, no upstream wiki) |
| 2 | @Id | varchar(40) | YES | GUID primary key for the account activity record. Distribution key. Links to parent AccountsActivities_862157 and sibling tables (RiskActions, SecurityChecks) via same @Id. Sample: ce6c7cfc-34dd-43a2-855b-0b0dfc9f999f. (Tier 3 — eMoney Platform, no upstream wiki) |
| 3 | @AccountsActivities@Id-862157 | varchar(40) | YES | Foreign key to the parent AccountsActivities_862157 table. In observed data, this value equals @Id, suggesting a 1:1 relationship with the parent record. (Tier 3 — eMoney Platform, no upstream wiki) |
| 4 | FileDate | varchar(max) | YES | Date string of the source file from which this record was ingested. Typically matches the day of @Created. Sample: '2026-03-13', '2025-06-11'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 5 | WorkDate | varchar(max) | YES | Transaction work date as a string, typically the date and time the transaction was processed. Sample: '2026-03-12 08:08:14'. Use @WorkDate (datetime2) for date arithmetic. (Tier 3 — eMoney Platform, no upstream wiki) |
| 6 | @WorkDate | datetime2(7) | YES | Transaction work date as a typed datetime2 column. Same value as the varchar WorkDate column but in native datetime2 format for proper date operations. (Tier 3 — eMoney Platform, no upstream wiki) |
| 7 | IssuerIdentificationNumber | varchar(max) | YES | Issuer identification number for the card program. Identifies the card issuer (BIN-level). Sample: '10084368' (EU), '10079563' (UK). (Tier 3 — eMoney Platform, no upstream wiki) |
| 8 | ProgramName | varchar(max) | YES | Name of the eToro Money card program. Sample: 'eToro Money EU Account', 'eToro Money UK Account', 'eToro Money UK GBP'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 9 | ProgramId | varchar(max) | YES | Numeric identifier for the card program. Sample: '177' (EU Account), '175' (UK Account), '39' (UK GBP). (Tier 3 — eMoney Platform, no upstream wiki) |
| 10 | ProductName | varchar(max) | YES | Name of the card product. Populated for card-based transactions (e.g., 'eToro Money 459688 Consumer Debit Visa'). NULL/empty for non-card transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 11 | ProductId | varchar(max) | YES | Numeric identifier for the card product. Sample: '24' for Visa debit. NULL/empty for non-card transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 12 | SubProductId | varchar(max) | YES | Sub-product identifier within the card product. Sample: '351'. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 13 | HolderId | varchar(max) | YES | eToro Money account holder identifier. Links the transaction to a specific eMoney customer. Sample: '16469872', '10361541'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 14 | AccountId | varchar(max) | YES | eToro Money account identifier for the holder. Each holder may have multiple accounts. Sample: '17319872', '11222391'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 15 | BankAccountId | varchar(max) | YES | Internal bank account identifier within the eMoney platform. Populated for EPM transactions. NULL/empty for card and internal transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 16 | ExternalBankAccountId | varchar(max) | YES | External bank account identifier for EPM counterparty. Sample: '2699465910888910012'. Populated for bank transfers. (Tier 3 — eMoney Platform, no upstream wiki) |
| 17 | BankAccountNumber | varchar(max) | YES | Bank account number of the eToro Money holder's linked bank account. Sample: '03856978'. Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 18 | BankAccountSortCode | varchar(max) | YES | UK sort code of the holder's linked bank account. Sample: '041335'. Populated for UK bank transfers. (Tier 3 — eMoney Platform, no upstream wiki) |
| 19 | BankAccountIban | varchar(max) | YES | IBAN of the holder's linked bank account. Sample: 'GB14MRMI04133503856978'. Populated for SEPA/bank transfers. (Tier 3 — eMoney Platform, no upstream wiki) |
| 20 | BankAccountBic | varchar(max) | YES | BIC/SWIFT code of the holder's bank. Sample: 'MRMIGB22XXX'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 21 | CardNumber | varchar(max) | YES | Masked card number for card-based transactions. Sample: '************6483'. NULL/empty for non-card transactions. PII. (Tier 3 — eMoney Platform, no upstream wiki) |
| 22 | CardNumberId | varchar(max) | YES | Internal identifier for the card number record. Sample: '574911'. Populated for card transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 23 | CardRequestId | varchar(max) | YES | Identifier for the card issuance request. Sample: '695861'. Populated for card transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 24 | Bin | varchar(max) | YES | Bank Identification Number (first 6 digits of card). Sample: '459688'. Populated for card transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 25 | TransactionCode | varchar(max) | YES | Numeric code identifying the transaction type. Observed values: 1=LOAD, 2=POS, 4=UNLOAD, 56=EPM_OUTBOUND, 57=EPM_INBOUND. (Tier 3 — eMoney Platform, no upstream wiki) |
| 26 | TransactionCodeDescription | varchar(max) | YES | Human-readable description of the TransactionCode. Values: 'LOAD', 'POS', 'UNLOAD', 'EPM_OUTBOUND', 'EPM_INBOUND'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 27 | TransactionDateTime | varchar(max) | YES | Timestamp of the transaction as a string. Sample: '2026-03-12 08:08:14'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 28 | TransactionAmount | varchar(max) | YES | Transaction amount in the transaction currency. Positive for credits, negative for debits. Stored as varchar — CAST to numeric for arithmetic. Sample: '-9.00', '923.68', '-1.04'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 29 | TransactionCurrencyCode | varchar(max) | YES | ISO 4217 numeric currency code for the transaction currency. Sample: '978' (EUR), '826' (GBP). (Tier 3 — eMoney Platform, no upstream wiki) |
| 30 | TransactionCurrencyAlpha | varchar(max) | YES | ISO 4217 alpha currency code for the transaction currency. ~75% EUR, ~21% GBP, ~4% other (AUD, USD, CZK, CHF, etc.). (Tier 3 — eMoney Platform, no upstream wiki) |
| 31 | TransLink | varchar(max) | YES | Composite transaction link string used for deduplication and reconciliation. Contains concatenated identifiers including timestamps, account IDs, and hash fragments. (Tier 3 — eMoney Platform, no upstream wiki) |
| 32 | TraceId | varchar(max) | YES | Trace identifier for card network transaction tracing. Sample: '485276534264177'. Populated for card (POS) transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 33 | TransactionCodeIdentifier | varchar(max) | YES | Additional identifier qualifying the transaction code. Sample: '05'. Sparsely populated, appears for card transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 34 | HolderAmount | varchar(max) | YES | Transaction amount in the holder's account currency. For same-currency transactions, equals TransactionAmount. For cross-currency, reflects the FX-converted amount. Stored as varchar. (Tier 3 — eMoney Platform, no upstream wiki) |
| 35 | HolderCurrencyCode | varchar(max) | YES | ISO 4217 numeric currency code for the holder's account currency. Sample: '978' (EUR), '826' (GBP). (Tier 3 — eMoney Platform, no upstream wiki) |
| 36 | HolderCurrencyAlpha | varchar(max) | YES | ISO 4217 alpha currency code for the holder's account currency. Sample: 'EUR', 'GBP'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 37 | FxRate | varchar(max) | YES | Foreign exchange rate applied when transaction currency differs from holder currency. Sample: '1.000000000' (same currency), '0.875000000' (cross-currency). NULL when no FX conversion. Stored as varchar. (Tier 3 — eMoney Platform, no upstream wiki) |
| 38 | FeeGroupId | varchar(max) | YES | Identifier for the fee group/schedule applied to this transaction. Sample: '24'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 39 | FeeGroupName | varchar(max) | YES | Name of the fee group/schedule. Sample: 'eToro Green'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 40 | FxFeeName | varchar(max) | YES | Name of the FX fee applied to cross-currency transactions. NULL/empty when no FX fee. (Tier 3 — eMoney Platform, no upstream wiki) |
| 41 | FxFeeAmount | varchar(max) | YES | Amount of the FX fee charged. NULL/empty when no FX fee. Stored as varchar. (Tier 3 — eMoney Platform, no upstream wiki) |
| 42 | FxFeeCurrency | varchar(max) | YES | Currency code of the FX fee. NULL/empty when no FX fee. (Tier 3 — eMoney Platform, no upstream wiki) |
| 43 | FxFeeReason | varchar(max) | YES | Reason code or description for the FX fee. NULL/empty when no FX fee. (Tier 3 — eMoney Platform, no upstream wiki) |
| 44 | F0FeeName | varchar(max) | YES | Name of the flat/fixed fee (F0) applied to the transaction. NULL/empty when no flat fee. (Tier 3 — eMoney Platform, no upstream wiki) |
| 45 | F0FeeAmount | varchar(max) | YES | Amount of the flat/fixed fee charged. NULL/empty when no flat fee. Stored as varchar. (Tier 3 — eMoney Platform, no upstream wiki) |
| 46 | F0FeeCurrency | varchar(max) | YES | Currency code of the flat fee. NULL/empty when no flat fee. (Tier 3 — eMoney Platform, no upstream wiki) |
| 47 | F0FeeReason | varchar(max) | YES | Reason code or description for the flat fee. NULL/empty when no flat fee. (Tier 3 — eMoney Platform, no upstream wiki) |
| 48 | BillRateAmount | varchar(max) | YES | Billing exchange rate applied for billing currency conversion. Sample: '1.000000000'. NULL when billing currency matches transaction currency. Stored as varchar. (Tier 3 — eMoney Platform, no upstream wiki) |
| 49 | BillingDate | varchar(max) | YES | Date/time when the billing was processed. Typically matches TransactionDateTime. Sample: '2026-03-12 08:08:14'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 50 | BillingAmount | varchar(max) | YES | Transaction amount in the billing currency. Sign convention matches TransactionAmount. Stored as varchar. (Tier 3 — eMoney Platform, no upstream wiki) |
| 51 | BillingCurrencyCode | varchar(max) | YES | ISO 4217 numeric currency code for the billing currency. Sample: '978' (EUR), '826' (GBP). (Tier 3 — eMoney Platform, no upstream wiki) |
| 52 | BillingCurrencyAlpha | varchar(max) | YES | ISO 4217 alpha currency code for the billing currency. Sample: 'EUR', 'GBP'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 53 | SettlementAmount | varchar(max) | YES | Transaction amount in the card scheme settlement currency. Populated for card transactions. NULL/empty for non-card transactions. Stored as varchar. (Tier 3 — eMoney Platform, no upstream wiki) |
| 54 | SettlementCurrencyCode | varchar(max) | YES | ISO 4217 numeric currency code for the settlement currency. Populated for card transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 55 | SettlementCurrencyAlpha | varchar(max) | YES | ISO 4217 alpha currency code for the settlement currency. Populated for card transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 56 | SettlementConversionRate | varchar(max) | YES | Conversion rate between billing and settlement currencies. Sample: '1.000000000'. Populated for card transactions. Stored as varchar. (Tier 3 — eMoney Platform, no upstream wiki) |
| 57 | CardPresent | varchar(max) | YES | Whether the physical card was present at the point of sale. Values: 'Card not present', 'Card present'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 58 | TransactionId | varchar(max) | YES | Platform-generated transaction identifier. Numeric string. Sample: '17733028947799'. Unique per transaction within the eMoney platform. (Tier 3 — eMoney Platform, no upstream wiki) |
| 59 | TransactionClass | varchar(max) | YES | Geographic classification of the transaction. Values: 'Unknown' (~88%), 'Domestic' (~11%), 'Interregional' (~0.6%), 'Regional' (<0.1%). (Tier 3 — eMoney Platform, no upstream wiki) |
| 60 | Action | varchar(max) | YES | Transaction direction. 'Credit' = money into account, 'Debit' = money out of account. (Tier 3 — eMoney Platform, no upstream wiki) |
| 61 | Network | varchar(max) | YES | Card network or payment type. Observed values: 'Internal Payment', 'External Payment', 'Visa'. 'Internal Payment' for LOAD/UNLOAD, 'External Payment' for EPM transfers. (Tier 3 — eMoney Platform, no upstream wiki) |
| 62 | TransactionDescription | varchar(max) | YES | Human-readable description of the transaction type. Values: 'UNLOAD', 'LOAD', 'EPM_OUTBOUND', 'EPM_INBOUND', merchant name for POS. (Tier 3 — eMoney Platform, no upstream wiki) |
| 63 | EntryModeCode | varchar(max) | YES | Card entry mode code indicating how the card data was captured. Sample: '12' (UNKNOWN), '7' (ON-FILE). (Tier 3 — eMoney Platform, no upstream wiki) |
| 64 | EntryModeCodeDescription | varchar(max) | YES | Human-readable description of the entry mode code. Values: 'UNKNOWN', 'ON-FILE'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 65 | ReferenceNumber | varchar(max) | YES | Reference number for the transaction. Format varies: alphanumeric for card transactions (e.g., '74179805278252117073738'), 'P'-prefixed for internal (e.g., 'P64268369'). (Tier 3 — eMoney Platform, no upstream wiki) |
| 66 | CountryIson | varchar(max) | YES | ISO 3166 numeric country code. Sample: '203' (CZE), '826' (GBR), '056' (BEL), '470' (MLT). Represents the transaction or merchant country. (Tier 3 — eMoney Platform, no upstream wiki) |
| 67 | LoadType | varchar(max) | YES | Type of load operation. Values: '1' (~71%), '' (empty, ~29%), '2' (<0.1%), '0' (rare). Populated for internal and EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 68 | LoadSource | varchar(max) | YES | Source identifier for the load operation. Sample: '25', '30', '35'. Populated for LOAD/UNLOAD transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 69 | EpmMethodId | varchar(max) | YES | Electronic payment method identifier. Sample: '4' (Faster Payments/UK), '5' (SEPA/EU). Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 70 | EpmTransactionId | varchar(max) | YES | Platform-internal EPM transaction identifier. Sample: '17495550299092'. Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 71 | ExternalEpmTransactionId | varchar(max) | YES | External EPM transaction identifier from the banking provider. Sample: '3585753700083840452'. Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 72 | EpmTransactionType | varchar(max) | YES | EPM transaction direction. '1' = outbound, '2' = inbound. Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 73 | EpmTransactionStatusCode | varchar(max) | YES | Numeric status code for the EPM transaction lifecycle. Sample: '0'. Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 74 | EpmMandateId | varchar(max) | YES | Direct debit mandate identifier for recurring EPM transactions. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 75 | Reference | varchar(max) | YES | Free-text reference field. For EPM transactions, contains the payment reference (e.g., 'Rr', 'den', '20240304-CMCM4X'). For internal transactions, typically NULL/empty. (Tier 3 — eMoney Platform, no upstream wiki) |
| 76 | TransactionIdentifier | varchar(max) | YES | GUID or encoded identifier for the transaction. Sample: '0b204f76-af14-493f-9eb7-47538c5a878d'. Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 77 | EndToEndIdentifier | varchar(max) | YES | End-to-end identifier for payment tracking across systems. Sample: '950fc243f9fb4f43b2b86bcbe7294d16'. Used in SEPA/Faster Payments for cross-bank tracing. (Tier 3 — eMoney Platform, no upstream wiki) |
| 78 | Suspicious | varchar(max) | YES | Risk flag indicating whether the transaction was flagged as suspicious. Values: 'Yes', 'No'. (Tier 3 — eMoney Platform, no upstream wiki) |
| 79 | RiskRuleCodes | varchar(max) | YES | Comma-separated risk rule codes that triggered during transaction screening. Sample: '3PA-(False)', '3rdParty (False)'. NULL/empty when no risk rules triggered. (Tier 3 — eMoney Platform, no upstream wiki) |
| 80 | BalanceAdjustmentType | varchar(max) | YES | Type of balance adjustment when the transaction is an administrative correction. NULL/empty for standard transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 81 | EpmTransactionStatus | varchar(max) | YES | Human-readable status of the EPM transaction. Sample: '1'. Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 82 | EpmTransactionReasonDescription | varchar(max) | YES | Description of the reason for EPM transaction status (e.g., rejection reasons from the bank). NULL/empty for successful transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 83 | EpmTransactionBankProviderReasonCode | varchar(max) | YES | Bank provider-specific reason code for EPM transaction outcomes. NULL/empty for successful transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 84 | ParentTransactionId | varchar(max) | YES | Reference to a parent transaction when this transaction is a child (e.g., fee transaction linked to the original). NULL/empty for root transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 85 | DisputeId | varchar(max) | YES | Internal dispute identifier when a transaction is under chargeback/dispute. NULL/empty when no dispute. (Tier 3 — eMoney Platform, no upstream wiki) |
| 86 | ExternalDisputeId | varchar(max) | YES | External (card scheme) dispute identifier. NULL/empty when no dispute. (Tier 3 — eMoney Platform, no upstream wiki) |
| 87 | ExternalPaymentScheme | varchar(max) | YES | Payment scheme used for external transfers. Sample: 'SEPA (SCT Inst) - LFL'. Populated for EPM and some internal transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 88 | ExternalIbanCountry | varchar(max) | YES | ISO numeric country code of the external IBAN. Sample: '826' (GBR), '276' (DEU). Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 89 | InternalIbanCountry | varchar(max) | YES | ISO numeric country code of the internal (eToro Money) IBAN. Sample: '826' (GBR), '470' (MLT). Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 90 | ExternalIban | varchar(max) | YES | IBAN of the external counterparty bank account. Sample: 'DE93710520500008308025', 'GB66LOYD77210216117468'. PII. Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 91 | ExternalBban | varchar(max) | YES | BBAN (Basic Bank Account Number) of the external counterparty. Sample: 'LOYD77210216117468'. Populated for UK bank transfers. PII. (Tier 3 — eMoney Platform, no upstream wiki) |
| 92 | ExternalAccountName | varchar(max) | YES | Name on the external counterparty bank account. Sample: 'Robert Rickard', 'Marco Worl'. PII. Populated for EPM transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 93 | ExternalAccountNumber | varchar(max) | YES | Account number of the external counterparty (non-IBAN format). Sample: '42924202'. PII. Populated for UK Faster Payments. (Tier 3 — eMoney Platform, no upstream wiki) |
| 94 | ExternalSortCode | varchar(max) | YES | UK sort code of the external counterparty bank. Sample: '090126'. Populated for UK bank transfers. (Tier 3 — eMoney Platform, no upstream wiki) |
| 95 | ExternalBIC | varchar(max) | YES | BIC/SWIFT code of the external counterparty bank. Sample: 'BYLADEM1TST'. Populated for SEPA transfers. (Tier 3 — eMoney Platform, no upstream wiki) |
| 96 | OriginatorId | varchar(max) | YES | Identifier of the originator for inbound payments. Populated for EPM_INBOUND transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 97 | OriginatorName | varchar(max) | YES | Name of the originator for inbound payments. PII. Populated for EPM_INBOUND transactions. (Tier 3 — eMoney Platform, no upstream wiki) |
| 98 | OriginatorServiceUserNumber | varchar(max) | YES | Service user number of the originator (used in Direct Debit/BACS schemes). Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 99 | TransactionReferenceNumber | varchar(max) | YES | Additional transaction reference number. Sample: 'PI1377980263440070'. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 100 | ActualEndToEndIdentifier | varchar(max) | YES | Actual end-to-end identifier as received from the payment scheme, before any platform normalization. Sample: 'PI13779802634400701020251216826301332'. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 101 | etr_y | varchar(max) | YES | ETL partition year string from the Azure Data Lake bronze export. Used by SP_eMoney_FiatDwhETL for incremental file path construction. Sample: '2025', '2026'. (Tier 3 — Data Lake export pipeline, no upstream wiki) |
| 102 | etr_ym | varchar(max) | YES | ETL partition year-month string from the Azure Data Lake bronze export. Format not consistently observed in sample. (Tier 3 — Data Lake export pipeline, no upstream wiki) |
| 103 | etr_ymd | varchar(max) | YES | ETL partition year-month-day string from the Azure Data Lake bronze export. Format not consistently observed in sample. (Tier 3 — Data Lake export pipeline, no upstream wiki) |
| 104 | SynapseUpdateDate | datetime | YES | Timestamp when the record was last loaded or updated in Synapse. Set during the COPY INTO / INSERT pipeline. Sample: 2026-03-14 06:34:38.003. (Tier 3 — ETL pipeline metadata, no upstream wiki) |
| 105 | partition_date | date | YES | Partition date used for incremental data management in Synapse. Indexed (XI_partition_date). Typically aligns with FileDate. Range: 2021-09-05 to 2026-04-27. (Tier 3 — ETL pipeline metadata, no upstream wiki) |
| 106 | Created | datetime2(7) | YES | Alternative creation timestamp. Appears to duplicate @Created with minor precision differences. Sample: 2026-03-13 00:00:00, 2025-06-11 05:11:42.274. (Tier 3 — eMoney Platform, no upstream wiki) |
| 107 | ProductCode | varchar(max) | YES | Product code identifying the payment product type. Sample: 'SEPA (SCT Inst) - LFL'. Sparsely populated, appears on newer records. (Tier 3 — eMoney Platform, no upstream wiki) |
| 108 | MasterAccountId | varchar(max) | YES | Master account identifier for multi-account structures. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 109 | MasterAccountName | varchar(max) | YES | Name of the master account. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 110 | MasterAccountIban | varchar(max) | YES | IBAN of the master account. Sparsely populated. PII. (Tier 3 — eMoney Platform, no upstream wiki) |
| 111 | RequestReferenceId | varchar(max) | YES | GUID reference for the originating request. Sample: '90a7f23e-99fc-4770-a0c8-3dd2e1f582fc'. Sparsely populated on newer records. (Tier 3 — eMoney Platform, no upstream wiki) |
| 112 | ExternalEndToEndIdentifier | varchar(max) | YES | External end-to-end identifier as provided by the originating payment system. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 113 | BankAccountBankStateBranch | varchar(max) | YES | Bank State Branch (BSB) code for the holder's bank account. Used in Australian banking. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 114 | ExternalBankStateBranch | varchar(max) | YES | Bank State Branch (BSB) code for the external counterparty. Used in Australian banking. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 115 | BankAccountBankBranchCode | varchar(max) | YES | Branch code for the holder's bank account. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |
| 116 | ExternalBankBranchCode | varchar(max) | YES | Branch code for the external counterparty bank. Sparsely populated. (Tier 3 — eMoney Platform, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All 116 columns | eMoney Platform (GPS/Modulr) | Same names | None — raw Parquet passthrough via SP_eMoney_FiatDwhETL |
| etr_y, etr_ym, etr_ymd | Azure Data Lake partition | Partition keys | Added by bronze export pipeline |
| SynapseUpdateDate, partition_date | ETL pipeline | Generated | Added during Synapse load |

### 5.2 ETL Pipeline

```
eMoney Platform (GPS/Modulr card issuer)
  |-- Bronze export to Azure Data Lake (Parquet) ---|
  v
dldataplatformprodwe.dfs.core.windows.net/internal-sources/.../AccountsActivities_AccountActivity-833937/
  |-- SP_eMoney_FiatDwhETL: COPY INTO (Parquet → _tmp) ---|
  v
eMoney_Tribe_tmp.AccountsActivities_AccountActivity-833937_tmp
  |-- SP_eMoney_FiatDwhETL: INSERT SELECT * (append, @Created watermark) ---|
  v
eMoney_Tribe.AccountsActivities_AccountActivity-833937 (~29.7M rows)
  |-- SP_eMoney_Reconciliation_ETLs (reader: JOIN to 862157 → ETL_AccountsActivities) ---|
  |-- SP_CMR_eMoney_Client_Adjustments_Report (reader: BI reporting) ---|
  v
eMoney_dbo.ETL_AccountsActivities (reconciliation output)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @Id | eMoney_Tribe.AccountsActivities_862157 | Parent activity record (INNER JOIN on @Id) |
| @Id | eMoney_Tribe.AccountsActivities_RiskActions-322546 | Risk action details (LEFT JOIN on @Id) |
| @Id | eMoney_Tribe.AccountsActivities_SecurityChecks-471048 | Security check results (LEFT JOIN on @Id) |
| HolderCurrencyCode | eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | Entity name mapping (UK/Malta) by CurrencyISO |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | JOIN on @Id | Builds reconciliation table ETL_AccountsActivities |
| BI_DB_dbo.SP_CMR_eMoney_Client_Adjustments_Report | FROM with date filter | Client adjustment reporting |
| DE_dbo.SP_Extract_eMoney_CMR_to_lake_for_snapshot | SELECT * | Snapshot export to data lake |
| DE_dbo.SP_Import_eMoney_CMR_to_snapshot_From_Lake | COPY INTO | Snapshot import from data lake |

---

## 7. Sample Queries

### 7.1 Daily Transaction Volume by Type

```sql
SELECT
    CAST([@WorkDate] AS DATE) AS TransactionDate,
    TransactionCodeDescription,
    Action,
    COUNT(*) AS TxnCount,
    SUM(CAST(TransactionAmount AS DECIMAL(18,2))) AS TotalAmount,
    TransactionCurrencyAlpha
FROM [eMoney_Tribe].[AccountsActivities_AccountActivity-833937]
WHERE partition_date >= '2026-04-01'
GROUP BY CAST([@WorkDate] AS DATE), TransactionCodeDescription, Action, TransactionCurrencyAlpha
ORDER BY TransactionDate DESC, TxnCount DESC
```

### 7.2 EPM Outbound Transfers for a Holder

```sql
SELECT
    [@WorkDate],
    CAST(TransactionAmount AS DECIMAL(18,2)) AS Amount,
    TransactionCurrencyAlpha,
    ExternalIban,
    ExternalAccountName,
    EpmTransactionStatus,
    Reference
FROM [eMoney_Tribe].[AccountsActivities_AccountActivity-833937]
WHERE HolderId = '10361541'
  AND TransactionCodeDescription = 'EPM_OUTBOUND'
  AND partition_date >= '2025-01-01'
ORDER BY [@WorkDate] DESC
```

### 7.3 Suspicious Transactions

```sql
SELECT
    [@WorkDate],
    HolderId,
    AccountId,
    TransactionCodeDescription,
    CAST(TransactionAmount AS DECIMAL(18,2)) AS Amount,
    TransactionCurrencyAlpha,
    RiskRuleCodes
FROM [eMoney_Tribe].[AccountsActivities_AccountActivity-833937]
WHERE Suspicious = 'Yes'
  AND partition_date >= '2026-01-01'
ORDER BY [@WorkDate] DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 6.5/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 116 T3, 0 T4, 0 T5 | Elements: 116/116, Logic: 5/10, Coverage: Complete*
*Object: eMoney_Tribe.AccountsActivities_AccountActivity-833937 | Type: Table | Production Source: eMoney Platform (GPS/Modulr) via SP_eMoney_FiatDwhETL*
