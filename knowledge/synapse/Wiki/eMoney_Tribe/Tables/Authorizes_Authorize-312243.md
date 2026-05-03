# eMoney_Tribe.Authorizes_Authorize-312243

> 3.8M-row raw Tribe card authorization events table storing every Visa debit card authorization request for eToro Money (UK GBP program) from September 2021 to present. Ingested daily via Generic Pipeline (Append) from FiatDwhDB.Tribe on prod-banking. Consumed by `SP_eMoney_Reconciliation_ETLs` to build `eMoney_dbo.ETL_Authorize`.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.Authorizes_Authorize-312243 (prod-banking) via Generic Pipeline #542 |
| **Refresh** | Daily (1440 min), Append strategy |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (4 NCIs on @Authorizes@Id-837045, @Id x2, partition_date) |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (raw) |

---

## 1. Business Meaning

This table is a **raw Bronze-layer staging table** containing card authorization events from the Tribe Payments platform. Each row represents a single card authorization request (approval, decline, or verification) for an eToro Money UK Visa debit card.

The table holds **~3.8M rows** spanning **2021-09-05 to 2026-04-26** (partition_date range). Data arrives daily via Generic Pipeline (Append strategy, generic_id 542) from `FiatDwhDB.Tribe` on the `prod-banking` server.

The downstream ETL stored procedure `SP_eMoney_Reconciliation_ETLs` (Reconciliation Table 03 — Authorize) reads this table, INNER JOINs it with the parent `Authorizes-837045` table and LEFT JOINs with `Authorizes_RiskActions-796100` and `Authorizes_SecurityChecks-30662` to produce the reconciliation-ready `eMoney_dbo.ETL_Authorize` table.

All 80 columns are stored as `varchar(max)` (except metadata columns), reflecting the raw JSON-to-tabular extraction from Tribe's API with no type casting at the Bronze layer. The data is exclusively Visa network transactions for the eToro Money UK GBP program (IssuerIdentificationNumber = 10079563).

---

## 2. Business Logic

### 2.1 Authorization Response Handling

**What**: Each authorization carries a response code and description indicating whether the transaction was approved or declined.
**Columns Involved**: ResponseCode, ResponseCodeDescription, ResponseDeclineDescription
**Rules**:
- `00` = Approved (~85% of recent transactions)
- `85` = Address/CVV2 verification, no decline reason
- `51` = Insufficient funds
- `1A` = Additional customer authentication required (SCA)
- `43`/`41` = Stolen/Lost card (fraud)
- ResponseDeclineDescription is populated only for declined transactions

### 2.2 Transaction Type Classification

**What**: Transactions are classified by code identifying the payment channel or action type.
**Columns Involved**: TransactionCode, TransactionCodeDescription, MtiCode, Action
**Rules**:
- `2` = POS (point-of-sale, ~85% of volume)
- `17` = POS_VERIFICATION (card verification, ~7%)
- `9` = QUASI (quasi-cash, e.g., crypto purchases)
- `3` = ATM withdrawal
- `26`/`28`/`43`/`78`/`90` = P2P variants (account-to-account, person-to-person, gambling credit)
- `12` = REFUND
- MtiCode `0100` = standard authorization request

### 2.3 Multi-Currency Processing

**What**: Each authorization tracks amounts in three currency contexts: transaction, billing, and settlement.
**Columns Involved**: TransactionAmount/CurrencyCode/CurrencyAlpha, BillingAmount/CurrencyCode/CurrencyAlpha, SettlementAmount/CurrencyCode/CurrencyAlpha, FxRate, BillRateAmount, SettlementConversionRate
**Rules**:
- Transaction currency = merchant's local currency
- Billing currency = cardholder's account currency (typically GBP/826)
- Settlement currency = network settlement currency
- FxRate bridges transaction to billing; SettlementConversionRate bridges billing to settlement
- Amounts are signed: negative = debit (purchase/withdrawal), positive = credit (refund/P2P inbound)

### 2.4 MCC Padding (Pre-Authorization Hold)

**What**: Some MCCs (e.g., hotels, car rentals) trigger padding on the authorized amount to cover potential final charges.
**Columns Involved**: CumulativePaddingAmount, AppliedPaddingAmount, MccPaddingReason
**Rules**:
- Padding amounts are typically `0.00` for standard POS
- Non-zero values indicate the issuer or network applied an estimated hold above the transaction amount

### 2.5 Card Entry Mode and Security

**What**: Tracks how the card was presented and what security checks were applied.
**Columns Involved**: CardPresent, EntryModeCode, EntryModeCodeDescription, ECIIndicator, PosDataDe22, PosDataDe61, PosDataExtendedDe61
**Rules**:
- `Card present` / `Card not present` classifies the physical presence
- EntryModeCode: `2` = CONTACTLESS, `7` = ON-FILE (card-on-file recurring), `3` = E-COMMERCE, `6` = ICC (chip)
- ECIIndicator: `05`/`07` = 3D-Secure authenticated

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **REPLICATE** distribution — full copy on every compute node. Suitable for this table's moderate size (~3.8M rows).
- **HEAP** — no clustered index. Use nonclustered indexes on `@Id`, `@Authorizes@Id-837045`, and `partition_date` for filtering.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Daily authorization approval rate | `WHERE partition_date BETWEEN ... GROUP BY partition_date, ResponseCode` |
| Transaction volume by type | `GROUP BY TransactionCode, TransactionCodeDescription` |
| Merchant-level spending analysis | `GROUP BY MerchantName, Mcc, MerchantCountryName` |
| Declined transaction investigation | `WHERE ResponseCode <> '00' AND partition_date >= ...` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.Authorizes-837045 | `[@Id] = [@Id]` | Parent file-level record |
| eMoney_Tribe.Authorizes_RiskActions-796100 | `[@Id] = [@Id]` | Risk action flags (MarkAsSuspicious, RejectTransaction, etc.) |
| eMoney_Tribe.Authorizes_SecurityChecks-30662 | `[@Id] = [@Id]` | Security check results (OnlinePIN, 3DS, CVV2, ChipData, etc.) |
| eMoney_dbo.ETL_Authorize | downstream | Reconciled/cleaned version built by SP_eMoney_Reconciliation_ETLs |

### 3.4 Gotchas

- **All value columns are `varchar(max)`** — amounts, codes, dates are all strings. Cast before arithmetic (`CAST(TransactionAmount AS DECIMAL(18,2))`).
- **Duplicate column names**: `PosDatDe61` (legacy typo) and `PosDataDe61` (corrected) both exist. Newer rows populate `PosDataDe61`; older rows use `PosDatDe61`.
- **`@Created` vs `Created`**: `@Created` is `datetime2(7)` and appears on all rows. `Created` is a later-added `datetime2(7)` column — NULL on older rows (pre-~2024).
- **`PosDataExtendedDe61`**: Added later, NULL on older rows. Contains extended POS data element 61.
- **Masked card numbers**: `CardNumber` is always masked (`************NNNN`), showing only last 4 digits.
- **Single network**: All data is Visa. No Mastercard or other networks.
- **Negative amounts = debits**: Purchases and withdrawals are negative; refunds and credits are positive.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL transform logic |
| Tier 3 | Grounded in DDL + live data + SP code, no upstream wiki available |
| Tier 4 | Inferred from column name only (banned for this object) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Created | datetime2(7) | YES | Tribe record creation timestamp. Marks when this authorization event was exported from the Tribe platform. Used as the incremental load watermark in SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 2 | @Id | varchar(40) | YES | Unique authorization event identifier (UUID format). Primary key for this record. Indexed (2 NCIs). Used as the JOIN key to parent Authorizes-837045 and sibling RiskActions/SecurityChecks tables. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 3 | @Authorizes@Id-837045 | varchar(40) | YES | Foreign key to the parent Authorizes-837045 table. Links this authorization detail record to its parent file-level record. Indexed. In practice, observed to equal @Id (1:1 relationship). (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 4 | FileDate | varchar(max) | YES | Date string of the Tribe export file that contained this record (e.g., '2022-04-11'). Represents the file delivery date, typically one day after the transaction. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 5 | WorkDate | varchar(max) | YES | Business working date of the authorization as a string (e.g., '2022-04-10 04:24:47'). Includes time component. Represents the actual date/time the transaction was processed by Tribe. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 6 | @WorkDate | datetime2(7) | YES | Typed datetime2 version of WorkDate. Same value as the varchar WorkDate column but stored as a proper datetime2 for query efficiency. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 7 | IssuerIdentificationNumber | varchar(max) | YES | Issuer identification number for the card program. Observed value: 10079563 (eToro Money UK). Identifies the issuing institution within the Tribe platform. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 8 | ProgramName | varchar(max) | YES | Tribe card program name. Observed values: 'eToro Money UK GBP'. Identifies the eToro Money program this card belongs to. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 9 | ProgramId | varchar(max) | YES | Tribe card program numeric identifier. Observed value: '39' (eToro Money UK GBP). (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 10 | ProductName | varchar(max) | YES | Card product name within the program. Observed: 'eToro Money 459688 Consumer Debit Visa'. Describes the specific card product type. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 11 | ProductId | varchar(max) | YES | Numeric identifier for the card product. Observed: '24'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 12 | SubProductId | varchar(max) | YES | Sub-product identifier within the card product. Observed: '351'. Further granularity below ProductId. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 13 | HolderId | varchar(max) | YES | Tribe cardholder identifier. Numeric ID uniquely identifying the person who holds the card. Used to link authorizations to cardholder profiles. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 14 | AccountId | varchar(max) | YES | Tribe account identifier. Numeric ID for the account associated with the card. One holder may have multiple accounts. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 15 | CardLimitsGroupName | varchar(max) | YES | Name of the card-level limits group applied. Observed: 'eToro Green Account', 'eToro Black Account'. Controls card transaction limits. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 16 | CardLimitsGroupId | varchar(max) | YES | Numeric identifier for the card-level limits group. Observed: '44' (Green), '45' (Black). (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 17 | AccountLimitsGroupName | varchar(max) | YES | Name of the account-level limits group applied. Observed: 'eToro Green Account', 'eToro Black Account'. Controls account-wide transaction limits. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 18 | AccountLimitsGroupId | varchar(max) | YES | Numeric identifier for the account-level limits group. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 19 | HolderLimitsGroupName | varchar(max) | YES | Name of the holder-level limits group applied. Observed: 'eToro Green Account', 'eToro Black Account'. Controls holder-wide transaction limits across all their cards. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 20 | HolderLimitsGroupId | varchar(max) | YES | Numeric identifier for the holder-level limits group. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 21 | FeeGroupName | varchar(max) | YES | Name of the fee group applied to this card. Observed: 'eToro Green', 'eToro Black'. Determines fee schedule for transactions. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 22 | FeeGroupId | varchar(max) | YES | Numeric identifier for the fee group. Observed: '24' (Green), '23' (Black). (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 23 | CardNumber | varchar(max) | YES | Masked card number showing only last 4 digits (e.g., '************8928'). PII-masked at source. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 24 | CardNumberId | varchar(max) | YES | Tribe internal numeric identifier for the card number. Unique per physical/virtual card. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 25 | CardRequestId | varchar(max) | YES | Identifier for the card issuance request that created this card. Links back to the card ordering/provisioning process. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 26 | MtiCode | varchar(max) | YES | ISO 8583 Message Type Indicator code. Observed: '0100' = authorization request. Classifies the type of ISO 8583 message. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 27 | ResponseCode | varchar(max) | YES | ISO 8583 authorization response code from the issuer. Key values: '00' = Approved (~85%), '51' = Insufficient funds, '1A' = SCA required, '54' = Expired card, '43'/'41' = Fraud (stolen/lost). See Section 2.1. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 28 | ResponseCodeDescription | varchar(max) | YES | Human-readable description of the ResponseCode. E.g., 'Approved or completed successfully', 'Not sufficient funds', 'Expired card or expiration date is missing'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 29 | ResponseDeclineDescription | varchar(max) | YES | Additional decline detail when the authorization is refused. NULL or empty for approved transactions. E.g., 'Insufficient funds/over credit limit', 'Unknown limit error; Limit ID failed: 488'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 30 | TransactionCode | varchar(max) | YES | Tribe transaction type code. Key values: 2=POS, 3=ATM, 6=BALANCE_INQUIRY, 9=QUASI, 12=REFUND, 17=POS_VERIFICATION, 26=P2P_ACCOUNT_TO_ACCOUNT_DEBIT, 43=P2P_ONLINE_GAMING_GAMBLING_CREDIT. See Section 2.2. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 31 | TransactionCodeDescription | varchar(max) | YES | Human-readable description of TransactionCode. E.g., 'POS', 'ATM', 'QUASI', 'REFUND', 'POS_VERIFICATION'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 32 | Bin | varchar(max) | YES | Bank Identification Number (first 6 digits of the card). Identifies the issuing bank and card program. Observed values include 459688, which maps to eToro Money Visa. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 33 | AuthorizationCode | varchar(max) | YES | Unique authorization approval code returned by the issuer for approved transactions. Used for transaction matching in settlement. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 34 | TransactionDateTime | varchar(max) | YES | Date and time of the transaction as a string (e.g., '2022-04-10 03:24:47'). Represents the merchant-local or UTC timestamp of the authorization. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 35 | TransactionAmount | varchar(max) | YES | Authorization amount in the transaction currency (varchar). Negative for debits (purchases, withdrawals), positive for credits (refunds). Cast to decimal for arithmetic. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 36 | TransactionCurrencyCode | varchar(max) | YES | ISO 4217 numeric currency code of the transaction. E.g., '826' = GBP, '978' = EUR, '702' = SGD. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 37 | TransactionCurrencyAlpha | varchar(max) | YES | ISO 4217 alphabetic currency code of the transaction. E.g., 'GBP', 'EUR', 'SGD'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 38 | TransactionCountryCode | varchar(max) | YES | Numeric country code where the transaction originated. E.g., '826' = UK, '233' = Estonia, '470' = Malta. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 39 | TransLink | varchar(max) | YES | Transaction link identifier. A long composite string used by Tribe to link related authorization messages (e.g., original auth + reversal). (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 40 | Stan | varchar(max) | YES | System Trace Audit Number. A 6-digit number assigned by the acquirer to uniquely identify a transaction within a processing day. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 41 | TribeTransactionReference | varchar(max) | YES | Tribe-assigned unique transaction reference number. A long numeric string (e.g., '16495610879544') used for end-to-end traceability within Tribe's systems. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 42 | FxRate | varchar(max) | YES | Foreign exchange rate applied to convert from transaction currency to billing currency. '1.000000000' when transaction and billing currencies match. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 43 | CumulativePaddingAmount | varchar(max) | YES | Cumulative MCC padding (pre-authorization hold) amount. Typically '0.00' for standard POS. Non-zero for hotel/car rental MCCs where the final amount may exceed the initial auth. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 44 | AppliedPaddingAmount | varchar(max) | YES | Padding amount actually applied on this specific authorization. Typically '0.00'. See Section 2.4. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 45 | MccPaddingReason | varchar(max) | YES | Reason code or description for why MCC padding was applied. Empty/NULL for most transactions. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 46 | BillRateAmount | varchar(max) | YES | Billing exchange rate amount. The rate used to convert from transaction currency to the cardholder's billing currency. Often equals FxRate. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 47 | BillingDate | varchar(max) | YES | Date when the billing conversion was applied (string). Typically matches the WorkDate/TransactionDateTime. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 48 | BillingAmount | varchar(max) | YES | Transaction amount converted to the cardholder's billing currency. Negative for debits, positive for credits. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 49 | BillingCurrencyCode | varchar(max) | YES | ISO 4217 numeric code for the billing currency. Typically '826' (GBP) for eToro Money UK cardholders. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 50 | BillingCurrencyAlpha | varchar(max) | YES | ISO 4217 alphabetic code for the billing currency. Typically 'GBP'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 51 | SettlementAmount | varchar(max) | YES | Transaction amount in the network settlement currency. Used for inter-bank settlement between acquirer and issuer. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 52 | SettlementCurrencyCode | varchar(max) | YES | ISO 4217 numeric code for the settlement currency. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 53 | SettlementCurrencyAlpha | varchar(max) | YES | ISO 4217 alphabetic code for the settlement currency. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 54 | SettlementConversionRate | varchar(max) | YES | Exchange rate from billing currency to settlement currency. '1.000000000' when they match. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 55 | MerchantNumber | varchar(max) | YES | Merchant identification number assigned by the acquirer. Uniquely identifies the merchant within the payment network. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 56 | MerchantName | varchar(max) | YES | Merchant name and location as reported in the authorization message. Freeform text, e.g., 'BOLT.EU/O/2204100324     Tallinn      EE', 'TfL Travel Charge        TFL.gov.uk/CPGB'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 57 | MerchantCountryCodeAlpha | varchar(max) | YES | ISO 3166-1 alpha-3 country code of the merchant. E.g., 'GBR', 'EST', 'MLT'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 58 | MerchantCountryName | varchar(max) | YES | Full country name of the merchant. E.g., 'United Kingdom', 'Estonia', 'Malta'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 59 | Mcc | varchar(max) | YES | Merchant Category Code (ISO 18245). 4-digit code classifying the merchant's business type. E.g., '4121' = Taxicabs/Limousines, '5541' = Service Stations, '6011' = ATM, '5812' = Restaurants. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 60 | CardPresent | varchar(max) | YES | Whether the physical card was present at the point of sale. Values: 'Card present', 'Card not present'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 61 | PosDataDe22 | varchar(max) | YES | ISO 8583 Data Element 22 — Point of Service entry mode. Raw code string (e.g., '0710' = contactless, '1000' = e-commerce, '0510' = ICC chip). (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 62 | PosDatDe61 | varchar(max) | YES | Legacy column for POS Data Element 61 (contains a typo in name — missing 'a' in 'Data'). Populated on older rows. Newer rows use PosDataDe61 instead. Contains additional POS terminal capability data. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 63 | AcquirerId | varchar(max) | YES | Identifier of the acquiring bank/processor that handled the merchant side of the transaction. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 64 | ReferenceNumber | varchar(max) | YES | Acquirer reference number for the transaction. Used for reconciliation between acquirer and network. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 65 | TraceNumber | varchar(max) | YES | End-to-end trace number for the authorization. Composite string used to track the transaction across all participants. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 66 | Action | varchar(max) | YES | Transaction action type descriptor. Observed values: 'Debit', 'Credit'. Indicates the direction of the funds movement on the cardholder's account. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 67 | Network | varchar(max) | YES | Card payment network. All observed values: 'Visa'. This table contains only Visa network transactions. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 68 | EntryModeCode | varchar(max) | YES | Numeric code for how the card credentials were captured. Observed: '2' = CONTACTLESS, '3' = E-COMMERCE, '6' = ICC (chip), '7' = ON-FILE (card-on-file/recurring). (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 69 | EntryModeCodeDescription | varchar(max) | YES | Human-readable description of EntryModeCode. Values: 'CONTACTLESS', 'E-COMMERCE', 'ICC', 'ON-FILE'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 70 | ECIIndicator | varchar(max) | YES | Electronic Commerce Indicator. Indicates the level of authentication for e-commerce/card-not-present transactions. '05'/'07' = 3D-Secure authenticated. NULL or empty for card-present transactions. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 71 | Suspicious | varchar(max) | YES | Flag indicating whether the transaction was flagged as suspicious by Tribe's risk engine. Observed values: 'No', 'Yes'. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 72 | RiskRuleCodes | varchar(max) | YES | Comma-separated list of risk rule codes that were triggered for this authorization. Empty/NULL when no risk rules fired. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 73 | etr_y | varchar(max) | YES | ETL partition key — year component. Populated by the Generic Pipeline Bronze extraction process. NULL on older rows. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 74 | etr_ym | varchar(max) | YES | ETL partition key — year-month component. Populated by the Generic Pipeline Bronze extraction process. NULL on older rows. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 75 | etr_ymd | varchar(max) | YES | ETL partition key — year-month-day component. Populated by the Generic Pipeline Bronze extraction process. NULL on older rows. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 76 | SynapseUpdateDate | datetime | YES | Timestamp when this row was last loaded/updated in Synapse by the Generic Pipeline. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 77 | partition_date | date | YES | Date-based partition key used by the Generic Pipeline for incremental loads. Indexed (NCI). Aligns with FileDate. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 78 | PosDataExtendedDe61 | varchar(max) | YES | Extended POS Data Element 61. Added in a later schema revision. NULL on older rows (pre-~2024). Contains additional terminal capability information. Replaces the legacy PosDatDe61 typo column. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 79 | Created | datetime2(7) | YES | Record creation timestamp (datetime2 version). Added in a later schema revision. NULL on rows loaded before ~2024. For older rows, use @Created instead. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 80 | PosDataDe61 | varchar(max) | YES | POS Data Element 61 with corrected column name (fixes the PosDatDe61 typo). Added in a later schema revision. Populated on newer rows. Contains additional POS terminal data. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |
| 81 | TokenizedRequest | varchar(max) | YES | Tokenization request data associated with the authorization. NULL on most rows. Populated when a tokenization event is linked to this authorization. (Tier 3 — FiatDwhDB.Tribe.Authorizes_Authorize-312243) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All 80 columns | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | Same name | Passthrough (no transform — raw Bronze ingest) |

### 5.2 ETL Pipeline

```
Tribe Payments API (eToro Money UK — Visa authorizations)
  |-- Tribe data export (daily files) ---|
  v
FiatDwhDB.Tribe.Authorizes_Authorize-312243 (prod-banking)
  |-- Generic Pipeline #542 (Append, daily 1440 min, parquet) ---|
  v
Bronze/FiatDwhDB/Tribe/Authorizes_Authorize-312243/ (Data Lake)
  |-- Generic Pipeline Bronze load ---|
  v
eMoney_Tribe.Authorizes_Authorize-312243 (Synapse, 3.8M rows, REPLICATE)
  |-- SP_eMoney_Reconciliation_ETLs (Reconciliation Table 03) ---|
  |   INNER JOIN Authorizes-837045 ON @Id
  |   LEFT JOIN  Authorizes_RiskActions-796100 ON @Id
  |   LEFT JOIN  Authorizes_SecurityChecks-30662 ON @Id
  v
eMoney_dbo.ETL_Authorize (reconciled authorization data)
  |-- Generic Pipeline (Bronze export) ---|
  v
emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243 (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @Authorizes@Id-837045 | eMoney_Tribe.Authorizes-837045 | Parent file-level authorization record |

### 6.2 Referenced By (other objects point to this)

| Related Object | Element | Description |
|---|---|---|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | INNER JOIN on @Id | Reads all transaction columns to build ETL_Authorize |
| eMoney_Tribe_tmp.Authorizes_Authorize-312243_tmp | — | Temporary staging copy of this table |

---

## 7. Sample Queries

### 7.1 Daily Authorization Approval Rate

```sql
SELECT
    partition_date,
    COUNT(*) AS total_auths,
    SUM(CASE WHEN ResponseCode = '00' THEN 1 ELSE 0 END) AS approved,
    CAST(SUM(CASE WHEN ResponseCode = '00' THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,2)) AS approval_pct
FROM [eMoney_Tribe].[Authorizes_Authorize-312243]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.2 Top Decline Reasons (Last 30 Days)

```sql
SELECT
    ResponseCode,
    ResponseCodeDescription,
    COUNT(*) AS decline_count
FROM [eMoney_Tribe].[Authorizes_Authorize-312243]
WHERE ResponseCode <> '00'
  AND partition_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY ResponseCode, ResponseCodeDescription
ORDER BY decline_count DESC;
```

### 7.3 Spending by Merchant Category (MCC)

```sql
SELECT
    Mcc,
    COUNT(*) AS txn_count,
    SUM(CAST(TransactionAmount AS DECIMAL(18,2))) AS total_amount,
    COUNT(DISTINCT HolderId) AS unique_cardholders
FROM [eMoney_Tribe].[Authorizes_Authorize-312243]
WHERE ResponseCode = '00'
  AND partition_date >= '2026-01-01'
GROUP BY Mcc
ORDER BY total_amount;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this raw Tribe staging table. Business context is derived from the Tribe Payments platform API documentation and the downstream reconciliation SP (`SP_eMoney_Reconciliation_ETLs`, referenced in Freshservice change #20353).

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 81 T3, 0 T4, 0 T5 | Elements: 81/81, Logic: 7/10, Lineage: 8/10*
*Object: eMoney_Tribe.Authorizes_Authorize-312243 | Type: Table | Production Source: FiatDwhDB.Tribe (prod-banking, dormant upstream wiki)*
