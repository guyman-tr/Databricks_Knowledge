# eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239

> 2.9M-row raw Tribe settlement transaction child table storing detailed card payment clearing records from the eToro Money platform (FiatDwhDB.Tribe on prod-banking). Data spans 2021-09-05 to 2026-04-25, loaded daily via Generic Pipeline #538 (Append strategy, parquet). Contains multi-currency transaction amounts, merchant details, interchange fees, FX rates, and POS entry mode data. Consumed by SP_eMoney_Reconciliation_ETLs which INNER JOINs it to build ETL_SettlementsTransactions for eMoney reconciliation reporting.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 (prod-banking, Generic Pipeline #538) |
| **Refresh** | Daily (1440 min), Append strategy |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP + 4 NCIs (ClusteredIndex_ST_637239 on @Id, ClusteredIndex_ST_637239_c2 on @SettlementsTransactions@Id-333243, XI_partition_date on partition_date, idx_637239_Id on @Id) |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze raw export |

---

## 1. Business Meaning

This table is the **primary child entity** of the eMoney Tribe Settlements Transactions data feed, specifically the `SettlementTransaction` child element (XML entity ID 637239). It stores detailed settlement/clearing records for card-based transactions processed through the Tribe card payments platform (GPS Financial) for eToro Money UK.

The table contains **2,942,573 rows** spanning from **2021-09-05 to 2026-04-25**. Each row represents a single settlement transaction with full details including: amounts in transaction/holder/billing/settlement currencies, FX conversion rates, merchant information (name, address, country, MCC), interchange fee details, POS entry mode, card verification method indicators, and network classification.

**ETL pattern**: Data is exported daily from `FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239` on the `prod-banking` server via Generic Pipeline #538 (Append strategy, parquet format). There is no writer SP for this table — data flows directly from production. The table is then consumed as a read-only source by `SP_eMoney_Reconciliation_ETLs`, which INNER JOINs it to the parent `SettlementsTransactions-333243` table and LEFT JOINs sibling tables (`RiskActions-236807`, `SecurityChecks-426253`) to build the `ETL_SettlementsTransactions` reconciliation dataset.

**Data characteristics**: All business columns are stored as `varchar(max)` — raw ingestion with no type enforcement. The eToro Money UK program uses Visa network exclusively (BIN 459688). Sampled transactions are predominantly domestic GBP card-present payments (contactless, chip, e-commerce).

---

## 2. Business Logic

### 2.1 Multi-Currency Amount Groups

**What**: Each settlement transaction records amounts in up to four currency contexts: transaction, holder, billing, and settlement.
**Columns Involved**: TransactionAmount/TransactionCurrencyCode/TransactionCurrencyAlpha, HolderAmount/HolderCurrencyCode/HolderCurrencyAlpha, BillingAmount/BillingCurrencyCode/BillingCurrencyAlpha, SettlementAmount/SettlementCurrencyCode/SettlementCurrencyAlpha
**Rules**:
- Transaction amount is the original amount in the merchant's currency
- Holder amount is converted to the cardholder's account currency using FxRate
- Billing amount is in the billing currency (card scheme billing)
- Settlement amount is the final settled amount between issuer and acquirer
- For domestic GBP transactions, all four amounts are typically identical
- Negative amounts indicate debits (card purchases); positive amounts indicate credits (refunds)

### 2.2 Merchant Identification

**What**: Merchant details are captured at multiple levels of granularity.
**Columns Involved**: MerchantNumber, Merchant, MerchantName, MerchantAddress, MerchantCity, MerchantPostcode, MerchantCountryCodeAlpha, MerchantCountryName, Mcc
**Rules**:
- `Merchant` contains the raw merchant descriptor string (padded, includes city suffix)
- `MerchantName` is the cleaned merchant name (typically a substring of `Merchant`)
- `Mcc` is the ISO 18245 Merchant Category Code (e.g., 5411=Grocery, 5812=Restaurants, 6011=ATM)
- MerchantPostcode is often "00000" for UK transactions

### 2.3 Transaction Classification

**What**: Multiple classification dimensions categorize each settlement transaction.
**Columns Involved**: TransactionClass, Action, Network, TransactionCode, TransactionCodeDescription, EntryModeCode, EntryModeCodeDescription, CardPresent
**Rules**:
- TransactionClass: Domestic (94%), Interregional (5%), Regional (<1%), Unknown (<0.1%)
- Action: "Debit" for purchases, other values for credits/refunds
- Network: "Visa" exclusively for eToro Money UK
- TransactionCode: 2=POS, 3=ATM, other codes for loads/adjustments
- CardPresent: "Card present" or "Card not present"
- EntryModeCodeDescription: CONTACTLESS, ICC (chip), E-COMMERCE, ON-FILE

### 2.4 Fee Structure

**What**: Two fee groups (Fx fee and F0 fee) capture any fees applied to the transaction.
**Columns Involved**: FxFeeName, FxFeeCode, FxFeeAmount, FxFeeCurrency, FxFeeReason, F0FeeName, F0FeeCode, F0FeeAmount, F0FeeCurrency, F0FeeReason, FeeGroupId, FeeGroupName
**Rules**:
- FeeGroupName indicates the fee tier (e.g., "eToro Green", "eToro Black")
- FX fees apply to cross-currency transactions
- F0 fees are additional processing fees
- Both fee groups are typically empty for domestic same-currency transactions

### 2.5 Interchange and Settlement

**What**: Interchange fee details and settlement identifiers for clearing between issuer and acquirer.
**Columns Involved**: InterchangeFeeAmount, InterchangeFeeCurrency, InterchangeFeeDirection, InterchangeRateDesignator, InterchangeFeeAmountRounded, SettlementConversionRate, SettlementFlag
**Rules**:
- InterchangeFeeDirection: "Credit" (issuer receives) or "Debit" (issuer pays)
- InterchangeFeeAmount is the precise value; InterchangeFeeAmountRounded is the rounded display value
- SettlementConversionRate is 1.000000000 for same-currency settlements

### 2.6 Parent-Child Relationship

**What**: This table is linked to its parent container and sibling child tables via GUID identifiers.
**Columns Involved**: @Id, @SettlementsTransactions@Id-333243
**Rules**:
- @Id is the unique identifier for this settlement transaction record
- @SettlementsTransactions@Id-333243 links to the parent SettlementsTransactions-333243 container
- In sampled data, @Id and @SettlementsTransactions@Id-333243 contain identical GUID values (1:1 relationship)
- Sibling tables RiskActions-236807 and SecurityChecks-426253 share the same @Id

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table uses **REPLICATE** distribution (full copy on every compute node) with a **HEAP** storage structure. This is appropriate for a ~2.9M-row raw source table. Four NCIs exist: two on `@Id` (redundant — ClusteredIndex_ST_637239 and idx_637239_Id), one on the FK column `@SettlementsTransactions@Id-333243`, and one on `partition_date`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Settlement transactions for a date range | Filter on `partition_date` (indexed) |
| Transaction details by ID | Filter on `@Id` (indexed) |
| Merchant spending patterns | GROUP BY MerchantName, Mcc with date range filter on partition_date |
| Cross-currency transaction volume | Filter WHERE TransactionCurrencyAlpha <> HolderCurrencyAlpha |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.SettlementsTransactions-333243 | ON @Id = @Id | Parent container — get source file name |
| eMoney_Tribe.SettlementsTransactions_RiskActions-236807 | ON @Id = @Id | Risk action flags for this transaction |
| eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253 | ON @Id = @Id | Card verification method flags |
| eMoney_dbo.ETL_SettlementsTransactions | Downstream consumer | Reconciliation dataset built by SP_eMoney_Reconciliation_ETLs |

### 3.4 Gotchas

- **All varchar(max)**: Every business column is varchar(max) — numeric comparisons require CAST/CONVERT. `TransactionAmount` is a string like "-11.50", not a numeric type.
- **Duplicate @Id indexes**: ClusteredIndex_ST_637239 and idx_637239_Id are both NCIs on `@Id` — functionally redundant.
- **Masked card numbers**: `CardNumber` is masked (e.g., "************4945"). Only last 4 digits visible.
- **Padded merchant strings**: `Merchant` field is space-padded to fixed width and includes city suffix separated by "/".
- **MerchantPostcode often "00000"**: UK transactions frequently show "00000" rather than actual postcodes.
- **NOLOCK in SP**: SP_eMoney_Reconciliation_ETLs uses `WITH (NOLOCK)` though Synapse uses snapshot isolation by default.
- **@Id = FK**: In sampled data, `@Id` and `@SettlementsTransactions@Id-333243` hold identical GUIDs — the child record inherits the parent's identifier.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | ETL-computed or Generic Pipeline framework-generated column |
| Tier 3 | Grounded in DDL + SP code + sample data, no upstream column-level wiki available |

> **Note**: No Tier 1 columns exist for this table. The upstream production wiki for FiatDwhDB.Tribe was not resolvable in the bundle — all business columns are documented from DDL structure, SP code analysis, and live data sampling.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Created | datetime2(7) | YES | DWH ingestion timestamp set during Generic Pipeline load. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 2 | @Id | varchar(40) | YES | PK. Unique GUID identifier for this settlement transaction record. Indexed by ClusteredIndex_ST_637239 and idx_637239_Id. Used as the primary JOIN key to sibling tables (RiskActions-236807, SecurityChecks-426253) and parent table (SettlementsTransactions-333243). (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 3 | @SettlementsTransactions@Id-333243 | varchar(40) | YES | FK to parent. Links to the parent SettlementsTransactions-333243 container record. Contains identical GUID values to @Id in sampled data (1:1 relationship). Indexed by ClusteredIndex_ST_637239_c2. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 4 | FileDate | varchar(max) | YES | Date when the settlement file was generated by the Tribe platform. Formatted as "YYYY-MM-DD" string. Typically matches or is one day after the actual transaction date. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 5 | WorkDate | varchar(max) | YES | Working date and time when the settlement record was processed. Formatted as "YYYY-MM-DD HH:MM:SS" string. Used by SP_eMoney_Reconciliation_ETLs as the basis for the Date and DateID columns in ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 6 | @WorkDate | datetime2(7) | YES | Typed datetime2 version of the WorkDate field. Set during ingestion for strongly-typed date operations. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 7 | IssuerIdentificationNumber | varchar(max) | YES | Issuer identification number for the card program. Sampled data shows "10079563" for eToro Money UK. Passed through to ETL_SettlementsTransactions by SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 8 | ProgramName | varchar(max) | YES | Name of the card program under which the transaction was processed. Sampled data shows "eToro Money UK GBP". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 9 | ProgramId | varchar(max) | YES | Numeric identifier for the card program. Sampled data shows "39" for eToro Money UK GBP. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 10 | ProductName | varchar(max) | YES | Name of the card product associated with the transaction. Sampled data shows "eToro Money 459688 Consumer Debit Visa". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 11 | ProductId | varchar(max) | YES | Numeric identifier for the card product. Sampled data shows "24". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 12 | SubProductId | varchar(max) | YES | Sub-product identifier within the card product hierarchy. Sampled data shows "351". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 13 | HolderId | varchar(max) | YES | Unique identifier for the cardholder within the Tribe platform. Numeric string. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 14 | AccountId | varchar(max) | YES | Identifier for the cardholder's account within the Tribe platform. Numeric string. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 15 | BankAccountId | varchar(max) | YES | Identifier for the linked bank account. Often empty in sampled data. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 16 | CardNumber | varchar(max) | YES | Masked card number showing only the last 4 digits (e.g., "************4945"). PCI-compliant masking applied at source. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 17 | CardNumberId | varchar(max) | YES | Internal Tribe identifier for the card number. Numeric string. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 18 | CardRequestId | varchar(max) | YES | Identifier linking to the original card issuance request. Numeric string. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 19 | MtiCode | varchar(max) | YES | ISO 8583 Message Type Indicator code. Sampled data shows "0100" (authorization request). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 20 | MessageReasonCode | varchar(max) | YES | Reason code associated with the message. Sampled data shows "00" for standard transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 21 | Bin | varchar(max) | YES | Bank Identification Number (first 6 digits of card). Sampled data shows "459688" for eToro Money UK Visa. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 22 | TransactionCode | varchar(max) | YES | Tribe transaction type code. 2=POS (point of sale), 3=ATM, other values for loads/adjustments. Predominant value is "2". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 23 | TransactionCodeDescription | varchar(max) | YES | Human-readable description of the TransactionCode. Sampled values: "POS", "ATM". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 24 | AuthorizationCode | varchar(max) | YES | Authorization approval code returned by the card network for the transaction. Numeric string. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 25 | TransactionDateTime | varchar(max) | YES | Date and time when the original transaction occurred. Formatted as "YYYY-MM-DD HH:MM:SS" string. Typically one day before FileDate. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 26 | TransactionAmount | varchar(max) | YES | Transaction amount in the merchant's currency. Stored as string (e.g., "-11.50"). Negative values indicate debits (purchases); positive values indicate credits (refunds). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 27 | TransactionCurrencyCode | varchar(max) | YES | ISO 4217 numeric currency code for the transaction amount. Sampled data shows "826" (GBP). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 28 | TransactionCurrencyAlpha | varchar(max) | YES | ISO 4217 alphabetic currency code for the transaction amount. Sampled data shows "GBP". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 29 | TransLink | varchar(max) | YES | Unique transaction link identifier used for reconciliation and matching across settlement files. Long alphanumeric string combining authorization and trace data. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 30 | TraceId | varchar(max) | YES | Trace identifier for the transaction, used for end-to-end tracking through the payment network. Numeric string. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 31 | TransactionCodeIdentifier | varchar(max) | YES | Sub-code identifier qualifying the TransactionCode. Sampled values: "05" (POS purchase), "07" (ATM withdrawal). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 32 | HolderAmount | varchar(max) | YES | Transaction amount converted to the cardholder's account currency. Stored as string. For domestic transactions, matches TransactionAmount. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 33 | HolderCurrencyCode | varchar(max) | YES | ISO 4217 numeric currency code for the cardholder's account currency. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 34 | HolderCurrencyAlpha | varchar(max) | YES | ISO 4217 alphabetic currency code for the cardholder's account currency. Sampled data shows "GBP". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 35 | FxRate | varchar(max) | YES | Foreign exchange rate applied to convert transaction amount to holder amount. "1.000000000" for same-currency transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 36 | FeeGroupId | varchar(max) | YES | Identifier for the fee group applied to this transaction. Sampled values: "23" (eToro Black), "24" (eToro Green). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 37 | FeeGroupName | varchar(max) | YES | Name of the fee group. Sampled values: "eToro Green", "eToro Black". Determines the fee schedule applied to the transaction. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 38 | FxFeeName | varchar(max) | YES | Name of the FX fee applied to cross-currency transactions. Empty for same-currency transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 39 | FxFeeCode | varchar(max) | YES | Code identifying the type of FX fee. Empty for same-currency transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 40 | FxFeeAmount | varchar(max) | YES | Amount of the FX fee charged. Stored as string. Empty for same-currency transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 41 | FxFeeCurrency | varchar(max) | YES | Currency of the FX fee amount. Empty for same-currency transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 42 | FxFeeReason | varchar(max) | YES | Reason code or description for the FX fee. Empty for same-currency transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 43 | F0FeeName | varchar(max) | YES | Name of the F0 (additional processing) fee applied to the transaction. Empty for most transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 44 | F0FeeCode | varchar(max) | YES | Code identifying the type of F0 fee. Empty for most transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 45 | F0FeeAmount | varchar(max) | YES | Amount of the F0 fee charged. Stored as string. Empty for most transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 46 | F0FeeCurrency | varchar(max) | YES | Currency of the F0 fee amount. Empty for most transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 47 | F0FeeReason | varchar(max) | YES | Reason code or description for the F0 fee. Empty for most transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 48 | BillRateAmount | varchar(max) | YES | Billing exchange rate applied by the card network. "1.000000000" for same-currency transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 49 | BillingDate | varchar(max) | YES | Date when the transaction was billed by the card network. Formatted as "YYYY-MM-DD HH:MM:SS" string. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 50 | BillingAmount | varchar(max) | YES | Transaction amount in the card network's billing currency. Stored as string. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 51 | BillingCurrencyCode | varchar(max) | YES | ISO 4217 numeric currency code for the billing amount. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 52 | BillingCurrencyAlpha | varchar(max) | YES | ISO 4217 alphabetic currency code for the billing amount. Sampled data shows "GBP". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 53 | ReconciliationDate | varchar(max) | YES | Date when the transaction was reconciled. Often empty in sampled data. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 54 | SettlementDate | varchar(max) | YES | Date when funds were settled between issuer and acquirer. Formatted as "YYYY-MM-DD". Typically matches or is one day after the transaction date. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 55 | SettlementAmount | varchar(max) | YES | Final settled amount between issuer and acquirer. Stored as string. For domestic transactions, typically matches TransactionAmount. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 56 | SettlementCurrencyCode | varchar(max) | YES | ISO 4217 numeric currency code for the settlement amount. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 57 | SettlementCurrencyAlpha | varchar(max) | YES | ISO 4217 alphabetic currency code for the settlement amount. Sampled data shows "GBP". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 58 | SettlementConversionRate | varchar(max) | YES | Exchange rate used for settlement conversion. "1.000000000" for same-currency settlements. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 59 | MerchantNumber | varchar(max) | YES | Acquirer-assigned merchant identifier. Variable format. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 60 | Merchant | varchar(max) | YES | Raw merchant descriptor string including name, city, and postcode. Space-padded to fixed width with "/" delimiters. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 61 | MerchantName | varchar(max) | YES | Cleaned merchant name extracted from the Merchant descriptor. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 62 | MerchantAddress | varchar(max) | YES | Merchant street address. Often empty in sampled data. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 63 | MerchantCity | varchar(max) | YES | City where the merchant is located. Space-padded in raw data. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 64 | MerchantPostcode | varchar(max) | YES | Merchant postcode. Frequently "00000" for UK transactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 65 | MerchantCountryCodeAlpha | varchar(max) | YES | ISO 3166-1 alpha-3 country code for the merchant's country. Sampled data shows "GBR". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 66 | MerchantCountryName | varchar(max) | YES | Full country name of the merchant. Sampled data shows "United Kingdom". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 67 | Mcc | varchar(max) | YES | ISO 18245 Merchant Category Code classifying the merchant's business type. Sampled values: 5411=Grocery, 5812=Restaurants, 6011=ATM, 7542=Car Wash. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 68 | CardPresent | varchar(max) | YES | Indicates whether the physical card was present during the transaction. Values: "Card present", "Card not present". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 69 | CardInputMode | varchar(max) | YES | Method used to capture card data at the point of sale. Often empty in sampled data. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 70 | CardholderAuthenticationMethod | varchar(max) | YES | Method used to authenticate the cardholder during the transaction. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 71 | PosDataDe22 | varchar(max) | YES | ISO 8583 Data Element 22 — POS entry mode. Encodes how card data was read (e.g., "07"=contactless, "05"=chip, "01"=manual, "10"=credential on file). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 72 | PosDataDe61 | varchar(max) | YES | ISO 8583 Data Element 61 — additional POS data. Variable-length coded field with terminal capability and cardholder verification indicators. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 73 | AcquirerId | varchar(max) | YES | Identifier for the acquiring bank or processor that processed the transaction. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 74 | AcquirerReferenceNumber | varchar(max) | YES | Reference number assigned by the acquirer for this transaction. Long numeric string. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 75 | TransactionId | varchar(max) | YES | Tribe platform's internal transaction identifier. Numeric string. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 76 | InterchangeFeeAmount | varchar(max) | YES | Interchange fee amount charged for this transaction. Stored as string with decimal precision (e.g., "0.023000"). Positive for Credit direction, negative for Debit direction. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 77 | InterchangeFeeCurrency | varchar(max) | YES | ISO 4217 numeric currency code for the interchange fee. Sampled data shows "826" (GBP). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 78 | InterchangeFeeDirection | varchar(max) | YES | Direction of the interchange fee flow. "Credit" = issuer receives fee; "Debit" = issuer pays fee. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 79 | InterchangeRateDesignator | varchar(max) | YES | Code identifying which interchange rate table was applied. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 80 | CycleNumber | varchar(max) | YES | Settlement cycle number within the processing period. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 81 | CycleFileId | varchar(max) | YES | Identifier for the settlement cycle file containing this transaction. Formatted as "YYYYMMDD-HH-BIN" (e.g., "20220505-08-459688"). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 82 | TransactionClass | varchar(max) | YES | Geographic classification of the transaction. Values: "Domestic" (94%), "Interregional" (5%), "Regional" (<1%), "Unknown" (<0.1%). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 83 | Action | varchar(max) | YES | Transaction action type. Sampled values: "Debit" for card purchases. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 84 | Network | varchar(max) | YES | Card payment network. All sampled data shows "Visa" exclusively for eToro Money UK. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 85 | TransactionDescription | varchar(max) | YES | Human-readable description of the transaction type. Sampled values: "Visa". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 86 | EntryModeCode | varchar(max) | YES | Numeric code for the card entry mode. Sampled values: "2"=CONTACTLESS, "3"=E-COMMERCE, "6"=ICC (chip), "7"=ON-FILE. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 87 | EntryModeCodeDescription | varchar(max) | YES | Human-readable description of the card entry mode. Sampled values: "CONTACTLESS", "ICC", "E-COMMERCE", "ON-FILE". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 88 | ECIIndicator | varchar(max) | YES | Electronic Commerce Indicator — indicates the level of authentication for e-commerce transactions. Sampled values: "5" (3DS authenticated), "7" (non-authenticated e-commerce). Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 89 | Suspicious | varchar(max) | YES | Flag indicating whether the transaction was flagged as suspicious. Sampled values: "No", "Yes". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 90 | RiskRuleCodes | varchar(max) | YES | Comma-separated list of risk rule codes that were triggered for this transaction. Empty when no risk rules fired. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 91 | FunctionCode | varchar(max) | YES | ISO 8583 function code indicating the message function. Sampled value: "1". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 92 | LoadType | varchar(max) | YES | Type of card load/top-up if applicable. Empty for standard purchase transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 93 | LoadSource | varchar(max) | YES | Source of the card load/top-up if applicable. Empty for standard purchase transactions. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 94 | SettlementFlag | varchar(max) | YES | Flag indicating the settlement status or type. Sampled values: "8", "0". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 95 | TransactionCodeQualifier | varchar(max) | YES | Qualifier for the TransactionCode providing additional context. Sampled value: "0". Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 96 | BusinessFormatCode | varchar(max) | YES | Code identifying the business format of the transaction. Sampled values: "SD" (standard), empty. Passed through to ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 97 | CardType | varchar(max) | YES | Type of card used for the transaction. Sampled data shows "1" exclusively. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 98 | ParentTransactionId | varchar(max) | YES | Identifier linking to a parent transaction (e.g., for reversal, representment, or chargeback). Contains the TransactionId of the original transaction when applicable. Empty for original transactions. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 99 | DisputeId | varchar(max) | YES | Internal dispute case identifier if the transaction is involved in a chargeback or dispute. Empty when no dispute. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 100 | ExternalDisputeId | varchar(max) | YES | External (card network) dispute case identifier. Empty when no dispute. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 101 | ActualAuthorizationId | varchar(max) | YES | Identifier of the actual authorization that was matched to this settlement transaction. Used for auth-settlement matching. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 102 | FirstAuthorizationDate | varchar(max) | YES | Date when the first authorization for this transaction was obtained. Formatted as "YYYY-MM-DD HH:MM:SS". Empty for older records. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 103 | InterchangeFeeAmountRounded | varchar(max) | YES | Interchange fee amount rounded to display precision (e.g., "0.05", "0.07"). Stored as string. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 104 | ReferenceNumber | varchar(max) | YES | Reference number for the transaction. Used for reconciliation and dispute resolution. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 105 | etr_y | varchar(max) | YES | Year component extracted from Created timestamp by the Generic Pipeline ETL framework. String format (e.g., "2023"). Used for date-based partitioning. (Tier 2 — Generic Pipeline) |
| 106 | etr_ym | varchar(max) | YES | Year-month component extracted from Created timestamp by the Generic Pipeline ETL framework. String format (e.g., "2023-12"). Used for date-based partitioning. (Tier 2 — Generic Pipeline) |
| 107 | etr_ymd | varchar(max) | YES | Year-month-day component extracted from Created timestamp by the Generic Pipeline ETL framework. String format (e.g., "2023-12-20"). Matches partition_date values. (Tier 2 — Generic Pipeline) |
| 108 | SynapseUpdateDate | datetime | YES | Timestamp recording when the row was last loaded or updated in Synapse. Set by the Generic Pipeline at ingestion time. (Tier 2 — Generic Pipeline) |
| 109 | partition_date | date | YES | Date-based partition key derived from Created by the Generic Pipeline. Indexed by XI_partition_date for efficient date-range filtering. (Tier 2 — Generic Pipeline) |
| 110 | PosDataExtendedDe61 | varchar(max) | YES | Extended version of POS Data Element 61, providing additional terminal capability and transaction context data. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 111 | Created | datetime2(7) | YES | Source system timestamp of when the settlement record was created in FiatDwhDB.Tribe. Used as the incremental load watermark by SP_eMoney_Reconciliation_ETLs (`WHERE @Created >= @SettlementsTransactions_DATE`). (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |
| 112 | TokenizedRequest | varchar(max) | YES | Tokenized version of the original transaction request payload. Empty in most sampled data. (Tier 3 — FiatDwhDB.Tribe, no upstream column-level wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Created | FiatDwhDB.Tribe | @Created | Passthrough |
| @Id | FiatDwhDB.Tribe | @Id | Passthrough |
| @SettlementsTransactions@Id-333243 | FiatDwhDB.Tribe | @SettlementsTransactions@Id-333243 | Passthrough |
| FileDate through TokenizedRequest | FiatDwhDB.Tribe | Same column names | Passthrough (all 109 business columns) |
| etr_y / etr_ym / etr_ymd | Generic Pipeline | Created | Date component extraction |
| SynapseUpdateDate | Generic Pipeline | N/A | GETDATE() at ingestion |
| partition_date | Generic Pipeline | Created | CAST AS DATE |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 (prod-banking)
  |-- Generic Pipeline #538 (Append, daily, parquet) ---|
  v
Bronze Data Lake: Bronze/FiatDwhDB/Tribe/SettlementsTransactions_SettlementTransaction-637239/
  |-- Synapse COPY / External Table ---|
  v
eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239 (2.9M rows, REPLICATE)
  |-- SP_eMoney_Reconciliation_ETLs (INNER JOIN on @Id with parent, SELECT DISTINCT) ---|
  v
eMoney_dbo.ETL_SettlementsTransactions (reconciliation target)
  |-- Generic Pipeline (Bronze export) ---|
  v
emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239 (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @SettlementsTransactions@Id-333243 | eMoney_Tribe.SettlementsTransactions-333243 | Parent container table holding settlement file metadata |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element | Description |
|---|---|---|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | INNER JOIN on @Id | Reads most columns into ETL_SettlementsTransactions via SELECT DISTINCT |
| eMoney_Tribe.SettlementsTransactions_RiskActions-236807 | @SettlementsTransactions_SettlementTransaction@Id-637239 | Sibling child table — risk action flags (LEFT JOIN) |
| eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253 | @SettlementsTransactions_SettlementTransaction@Id-637239 | Sibling child table — card verification method flags (LEFT JOIN) |
| eMoney_Tribe_tmp.SettlementsTransactions_SettlementTransaction-637239_tmp | N/A | Temporary staging copy |

---

## 7. Sample Queries

### 7.1 Settlement Volume by Month and Transaction Class

```sql
SELECT
    LEFT(partition_date, 7) AS month,
    TransactionClass,
    COUNT(*) AS txn_count,
    SUM(CAST(TransactionAmount AS DECIMAL(18,2))) AS total_amount
FROM [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
WHERE partition_date >= '2026-01-01'
GROUP BY LEFT(partition_date, 7), TransactionClass
ORDER BY month DESC, txn_count DESC
```

### 7.2 Merchant Spending Analysis

```sql
SELECT TOP 20
    MerchantName,
    Mcc,
    COUNT(*) AS txn_count,
    SUM(CAST(TransactionAmount AS DECIMAL(18,2))) AS total_amount
FROM [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
WHERE partition_date >= '2026-01-01'
  AND TransactionCode = '2'
GROUP BY MerchantName, Mcc
ORDER BY txn_count DESC
```

### 7.3 Full Settlement Transaction with Risk and Security Checks

```sql
SELECT TOP 50
    st.TransactionId,
    st.TransactionDateTime,
    st.MerchantName,
    st.TransactionAmount,
    st.TransactionCurrencyAlpha,
    st.EntryModeCodeDescription,
    ra.MarkTransactionAsSuspicious,
    sc.ThreeDomainSecure,
    sc.ChipData
FROM [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239] st
LEFT JOIN [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807] ra
    ON st.[@Id] = ra.[@Id]
LEFT JOIN [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253] sc
    ON st.[@Id] = sc.[@Id]
WHERE st.partition_date >= '2026-04-01'
ORDER BY st.[@Created] DESC
```

---

## 8. Atlassian Knowledge Sources

- Freshservice change request #20353 — original migration of eMoney reconciliation tables to Synapse (referenced in SP_eMoney_Reconciliation_ETLs header comment)
- No Jira or Confluence pages found specific to this settlement transaction table

---

*Generated: 2026-04-30 | Quality: 7/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 107 T3, 0 T4, 0 T5 | Elements: 112/112, Logic: 7/10, Lineage: 8/10*
*Object: eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239 | Type: Table | Production Source: FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 (prod-banking)*
