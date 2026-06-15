---
object_fqn: main.bi_output.vg_fact_billingdeposit_for_genie
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_fact_billingdeposit_for_genie
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 139
row_count: null
generated_at: '2026-05-19T15:02:01Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingdeposit_for_genie.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingdeposit_for_genie.sql
concept_count: 0
formula_count: 0
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 139
---

# vg_fact_billingdeposit_for_genie

> View in `main.bi_output`. 0 business concept(s) in §2; 0 of 139 columns documented from anchored evidence; 139 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fact_billingdeposit_for_genie` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 139 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu Jan 29 11:08:21 UTC 2026 |

---

## 1. Business Meaning

`vg_fact_billingdeposit_for_genie` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md`.

Of its 139 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 0 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Transform `unknown` for column `CID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 1 | CurrencyID | INT | YES | Transform `unknown` for column `CurrencyID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 2 | Commission | DECIMAL | YES | Transform `unknown` for column `Commission` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 3 | Approved | BOOLEAN | YES | Transform `unknown` for column `Approved` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 4 | ModificationDate | TIMESTAMP | YES | Transform `unknown` for column `ModificationDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 5 | ModificationDateID | INT | YES | Transform `unknown` for column `ModificationDateID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 6 | FundingID | INT | YES | Transform `unknown` for column `FundingID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 7 | ExchangeRate | DECIMAL | YES | Transform `unknown` for column `ExchangeRate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 8 | DepositID | INT | YES | Transform `unknown` for column `DepositID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 9 | ProcessorValueDate | TIMESTAMP | YES | Transform `unknown` for column `ProcessorValueDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 10 | DepotID | INT | YES | Transform `unknown` for column `DepotID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 11 | SecuredCardDataAsString | STRING | YES | Transform `unknown` for column `SecuredCardDataAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 12 | BinCodeAsString | STRING | YES | Transform `unknown` for column `BinCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 13 | BinCountryIDAsInteger | INT | YES | Transform `unknown` for column `BinCountryIDAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 14 | CardTypeIDAsInteger | INT | YES | Transform `unknown` for column `CardTypeIDAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 15 | PaymentStatusID | INT | YES | Transform `unknown` for column `PaymentStatusID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 16 | ManagerID | INT | YES | Transform `unknown` for column `ManagerID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 17 | RiskManagementStatusID | INT | YES | Transform `unknown` for column `RiskManagementStatusID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 18 | Amount | DECIMAL | YES | Transform `unknown` for column `Amount` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 19 | PaymentDate | TIMESTAMP | YES | Transform `unknown` for column `PaymentDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 20 | IPAddress | DECIMAL | YES | Transform `unknown` for column `IPAddress` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 21 | ClearingHouseEffectiveDate | TIMESTAMP | YES | Transform `unknown` for column `ClearingHouseEffectiveDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 22 | IsFTD | INT | YES | Transform `unknown` for column `IsFTD` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 23 | RefundVerificationCode | STRING | YES | Transform `unknown` for column `RefundVerificationCode` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 24 | MatchStatusID | INT | YES | Transform `unknown` for column `MatchStatusID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 25 | BonusStatusID | INT | YES | Transform `unknown` for column `BonusStatusID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 26 | BonusAmount | DECIMAL | YES | Transform `unknown` for column `BonusAmount` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 27 | BonusErrorCode | INT | YES | Transform `unknown` for column `BonusErrorCode` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 28 | ExTransactionID | STRING | YES | Transform `unknown` for column `ExTransactionID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 29 | FundingTypeID | INT | YES | Transform `unknown` for column `FundingTypeID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 30 | IsRefundExcluded | INT | YES | Transform `unknown` for column `IsRefundExcluded` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 31 | DocumentRequired | INT | YES | Transform `unknown` for column `DocumentRequired` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 32 | UpdateDate | TIMESTAMP | YES | Transform `unknown` for column `UpdateDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 33 | ExpirationDateID | INT | YES | Transform `unknown` for column `ExpirationDateID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 34 | CountryIDAsInteger | INT | YES | Transform `unknown` for column `CountryIDAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 35 | StateIDAsInteger | INT | YES | Transform `unknown` for column `StateIDAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 36 | BankIDAsInteger | INT | YES | Transform `unknown` for column `BankIDAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 37 | AccountNameAsString | STRING | YES | Transform `unknown` for column `AccountNameAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 38 | AccountTypeAsString | STRING | YES | Transform `unknown` for column `AccountTypeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 39 | BankAccountAsString | STRING | YES | Transform `unknown` for column `BankAccountAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 40 | BankAddressAsString | STRING | YES | Transform `unknown` for column `BankAddressAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 41 | BankCodeAsDecimal | STRING | YES | Transform `unknown` for column `BankCodeAsDecimal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 42 | BankDetailsAccountIDAsString | STRING | YES | Transform `unknown` for column `BankDetailsAccountIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 43 | BankIDAsString | STRING | YES | Transform `unknown` for column `BankIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 44 | BankNameAsString | STRING | YES | Transform `unknown` for column `BankNameAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 45 | BICCodeAsString | STRING | YES | Transform `unknown` for column `BICCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 46 | CIDAsString | STRING | YES | Transform `unknown` for column `CIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 47 | v | STRING | YES | Transform `unknown` for column `v` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 48 | CustomerAddressAsString | STRING | YES | Transform `unknown` for column `CustomerAddressAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 49 | CustomerNameAsString | STRING | YES | Transform `unknown` for column `CustomerNameAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 50 | FundingType | STRING | YES | Transform `unknown` for column `FundingType` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 51 | MaskedAccountIDAsString | STRING | YES | Transform `unknown` for column `MaskedAccountIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 52 | PurseAsString | STRING | YES | Transform `unknown` for column `PurseAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 53 | RoutingNumberAsString | STRING | YES | Transform `unknown` for column `RoutingNumberAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 54 | SecureIDAsDecimal | STRING | YES | Transform `unknown` for column `SecureIDAsDecimal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 55 | SortCodeAsString | STRING | YES | Transform `unknown` for column `SortCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 56 | AccountBalanceAsDecimal | STRING | YES | Transform `unknown` for column `AccountBalanceAsDecimal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 57 | AccountHolderAsString | STRING | YES | Transform `unknown` for column `AccountHolderAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 58 | AccountIDAsDecimal | STRING | YES | Transform `unknown` for column `AccountIDAsDecimal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 59 | ACHBankAccountIDAsInteger | STRING | YES | Transform `unknown` for column `ACHBankAccountIDAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 60 | Address1AsString | STRING | YES | Transform `unknown` for column `Address1AsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 61 | Address2AsString | STRING | YES | Transform `unknown` for column `Address2AsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 62 | AdviseAsString | STRING | YES | Transform `unknown` for column `AdviseAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 63 | AvailableBalanceAsDecimal | STRING | YES | Transform `unknown` for column `AvailableBalanceAsDecimal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 64 | BankCodeAsString | STRING | YES | Transform `unknown` for column `BankCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 65 | BillNumberAsString | STRING | YES | Transform `unknown` for column `BillNumberAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 66 | BuildingNumberAsString | STRING | YES | Transform `unknown` for column `BuildingNumberAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 67 | CardHolderPhoneNumberBodyAsString | STRING | YES | Transform `unknown` for column `CardHolderPhoneNumberBodyAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 68 | CardHolderPhoneNumberPrefixAsString | STRING | YES | Transform `unknown` for column `CardHolderPhoneNumberPrefixAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 69 | CardNumberAsString | STRING | YES | Transform `unknown` for column `CardNumberAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 70 | CityAsString | STRING | YES | Transform `unknown` for column `CityAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 71 | CountryIDAsString | STRING | YES | Transform `unknown` for column `CountryIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 72 | CountryNameAsString | STRING | YES | Transform `unknown` for column `CountryNameAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 73 | CreatedAtAsString | STRING | YES | Transform `unknown` for column `CreatedAtAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 74 | CurrentBalanceAsDecimal | STRING | YES | Transform `unknown` for column `CurrentBalanceAsDecimal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 75 | CustomerIDAsString | STRING | YES | Transform `unknown` for column `CustomerIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 76 | EmailAsString | STRING | YES | Transform `unknown` for column `EmailAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 77 | EndPointIDAsString | STRING | YES | Transform `unknown` for column `EndPointIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 78 | ErrorCodeAsString | STRING | YES | Transform `unknown` for column `ErrorCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 79 | ErrorTypeAsString | STRING | YES | Transform `unknown` for column `ErrorTypeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 80 | FirstNameAsString | STRING | YES | Transform `unknown` for column `FirstNameAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 81 | IBANCodeAsString | STRING | YES | Transform `unknown` for column `IBANCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 82 | InitialTransactionIDAsString | STRING | YES | Transform `unknown` for column `InitialTransactionIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 83 | IPAsString | STRING | YES | Transform `unknown` for column `IPAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 84 | LanguageIDAsInteger | STRING | YES | Transform `unknown` for column `LanguageIDAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 85 | LastNameAsString | STRING | YES | Transform `unknown` for column `LastNameAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 86 | MD5AsString | STRING | YES | Transform `unknown` for column `MD5AsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 87 | PayerAsString | STRING | YES | Transform `unknown` for column `PayerAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 88 | PayerBusiness | STRING | YES | Transform `unknown` for column `PayerBusiness` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 89 | PayerIDAsString | STRING | YES | Transform `unknown` for column `PayerIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 90 | PayerPurseAsString | STRING | YES | Transform `unknown` for column `PayerPurseAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 91 | PayerStatus | STRING | YES | Transform `unknown` for column `PayerStatus` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 92 | PaymentAmountAsDecimal | STRING | YES | Transform `unknown` for column `PaymentAmountAsDecimal` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 93 | PaymentDateAsDateTime | STRING | YES | Transform `unknown` for column `PaymentDateAsDateTime` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 94 | PaymentGuaranteeAsString | STRING | YES | Transform `unknown` for column `PaymentGuaranteeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 95 | PaymentModeAsInteger | STRING | YES | Transform `unknown` for column `PaymentModeAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 96 | PaymentProviderTransactionStatusAsString | STRING | YES | Transform `unknown` for column `PaymentProviderTransactionStatusAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 97 | PaymentStatusAsInteger | STRING | YES | Transform `unknown` for column `PaymentStatusAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 98 | PaymentTypeAsString | STRING | YES | Transform `unknown` for column `PaymentTypeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 99 | PlaidItemIDAsString | STRING | YES | Transform `unknown` for column `PlaidItemIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 100 | PlaidNamesAsString | STRING | YES | Transform `unknown` for column `PlaidNamesAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 101 | PlatformIDAsInteger | STRING | YES | Transform `unknown` for column `PlatformIDAsInteger` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 102 | PromotionCodeAsString | STRING | YES | Transform `unknown` for column `PromotionCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 103 | PSPCodeAsString | STRING | YES | Transform `unknown` for column `PSPCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 104 | RapidFirstNameAsString | STRING | YES | Transform `unknown` for column `RapidFirstNameAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 105 | RapidLastNameAsString | STRING | YES | Transform `unknown` for column `RapidLastNameAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 106 | ResponseMessageAsString | STRING | YES | Transform `unknown` for column `ResponseMessageAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 107 | ResponseTimeAsString | STRING | YES | Transform `unknown` for column `ResponseTimeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 108 | SecretKeyAsString | STRING | YES | Transform `unknown` for column `SecretKeyAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 109 | ThreeDsAsJson | STRING | YES | Transform `unknown` for column `ThreeDsAsJson` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 110 | ThreeDsResponseType | STRING | YES | Transform `unknown` for column `ThreeDsResponseType` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 111 | TokenAsString | STRING | YES | Transform `unknown` for column `TokenAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 112 | TransactionIDAsString | STRING | YES | Transform `unknown` for column `TransactionIDAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 113 | ZipCodeAsString | STRING | YES | Transform `unknown` for column `ZipCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 114 | BaseExchangeRate | DECIMAL | YES | Transform `unknown` for column `BaseExchangeRate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 115 | ExchangeFee | INT | YES | Transform `unknown` for column `ExchangeFee` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 116 | ProtocolMIDSettingsID | INT | YES | Transform `unknown` for column `ProtocolMIDSettingsID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 117 | FunnelID | INT | YES | Transform `unknown` for column `FunnelID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 118 | AmountUSD | DECIMAL | YES | Transform `unknown` for column `AmountUSD` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 119 | SessionID | LONG | YES | Transform `unknown` for column `SessionID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 120 | PlatformID | INT | YES | Transform `unknown` for column `PlatformID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 121 | MOPCountry | STRING | YES | Transform `unknown` for column `MOPCountry` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 122 | SwiftCodeAsString | STRING | YES | Transform `unknown` for column `SwiftCodeAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 123 | ClientBankNameAsString | STRING | YES | Transform `unknown` for column `ClientBankNameAsString` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 124 | BankName | STRING | YES | Transform `unknown` for column `BankName` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 125 | CardCategory | STRING | YES | Transform `unknown` for column `CardCategory` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 126 | PaymentGeneration | INT | YES | Transform `unknown` for column `PaymentGeneration` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 127 | ProcessRegulationID | INT | YES | Transform `unknown` for column `ProcessRegulationID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 128 | MerchantAccountID | INT | YES | Transform `unknown` for column `MerchantAccountID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 129 | IsSetBalanceCompleted | INT | YES | Transform `unknown` for column `IsSetBalanceCompleted` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 130 | RoutingReasonID | INT | YES | Transform `unknown` for column `RoutingReasonID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 131 | IsRecurring | INT | YES | Transform `unknown` for column `IsRecurring` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 132 | FlowID | INT | YES | Transform `unknown` for column `FlowID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 133 | IsAftSupportedAsBool | BOOLEAN | YES | Transform `unknown` for column `IsAftSupportedAsBool` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 134 | IsAftEligibleAsBool | BOOLEAN | YES | Transform `unknown` for column `IsAftEligibleAsBool` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 135 | IsAftProcessedAsBool | BOOLEAN | YES | Transform `unknown` for column `IsAftProcessedAsBool` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 136 | etr_y | STRING | YES | Transform `unknown` for column `etr_y` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 137 | etr_ym | STRING | YES | Transform `unknown` for column `etr_ym` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 138 | etr_ymd | STRING | YES | Transform `unknown` for column `etr_ymd` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
        │
        ▼
main.bi_output.vg_fact_billingdeposit_for_genie   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=139 runtime=139 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 0 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 139 U | Elements: 139/139 | Source: view_definition*
