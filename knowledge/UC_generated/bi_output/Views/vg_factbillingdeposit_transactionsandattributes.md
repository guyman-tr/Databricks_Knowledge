---
object_fqn: main.bi_output.vg_factbillingdeposit_transactionsandattributes
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_factbillingdeposit_transactionsandattributes
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 27
row_count: null
generated_at: '2026-06-19T14:36:06Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus
- main.general.bronze_etoro_dictionary_riskmanagementstatus
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot
- main.general.bronze_etoro_dictionary_cardtype
- main.general.bronze_etoro_dictionary_country
- main.general.bronze_etoro_dictionary_regulation
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql
concept_count: 8
formula_count: 27
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 18
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_factbillingdeposit_transactionsandattributes

> View in `main.bi_output`. 8 business concept(s) in §2; 27 of 27 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_factbillingdeposit_transactionsandattributes` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 27 |
| **Concepts** | 8 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Wed May 06 17:52:57 UTC 2026 |

---

## 1. Business Meaning

`vg_factbillingdeposit_transactionsandattributes` is a view in `main.bi_output` that composes 4 CASE-based classifier flag(s) computed from upstream IDs, 4 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md`. Additional upstreams: 8 object(s), listed in §5 Lineage.

Of its 27 columns: 9 inherit byte-for-byte from upstream wikis (Tier 1), 18 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `ThreeDS_Result` discriminator: `ThreeDsResponseType = ' '`, `ThreeDsResponseType = ' '`, `ThreeDsResponseType = ' '` → set to '                      ' else '         '
**What**: Computed flag on `ThreeDS_Result` set to `'                      '` when the predicates below hold, else `'         '`.
**Columns Involved**: `ThreeDS_Result`
**Rules**:
- `ThreeDsResponseType = ' '`
- `ThreeDsResponseType = ' '`
- `ThreeDsResponseType = ' '`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql` bi_output.sql L44-L50
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`

### 2.2 `AFT_Supported` computed flag
**What**: Computed flag on `AFT_Supported` set to `'   '` when the predicates below hold, else `'  '`.
**Columns Involved**: `AFT_Supported`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql` bi_output.sql L80-L80
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`

### 2.3 `AFT_Eligible` computed flag
**What**: Computed flag on `AFT_Eligible` set to `'   '` when the predicates below hold, else `'  '`.
**Columns Involved**: `AFT_Eligible`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql` bi_output.sql L81-L81
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`

### 2.4 `AFT_Processed` computed flag
**What**: Computed flag on `AFT_Processed` set to `'   '` when the predicates below hold, else `'  '`.
**Columns Involved**: `AFT_Processed`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql` bi_output.sql L82-L82
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`

### 2.5 Dim lookup via alias `cur` → `gold_sql_dp_prod_we_dwh_dbo_dim_currency`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_currency` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fd.CurrencyID = cur.CurrencyID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql` L90
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`

### 2.6 Dim lookup via alias `ps` → `gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fd.PaymentStatusID = ps.PaymentStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql` L92
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus`

### 2.7 Dim lookup via alias `depot` → `gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fd.DepotID = depot.DepotID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql` L94
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`

### 2.8 Dim lookup via alias `x` → `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fd.FundingTypeID = x.FundingTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingdeposit_transactionsandattributes.sql` L98
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`

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
| Filter on discriminator flags | Use `AFT_Eligible = 1`-style filters on the precomputed flag columns (`AFT_Eligible`, `AFT_Processed`, `AFT_Supported`, `ThreeDS_Result`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_currency`, `gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus`, `gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`, `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | `fd.CurrencyID = cur.CurrencyID` | Lookup via alias `cur` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` | `fd.PaymentStatusID = ps.PaymentStatusID` | Lookup via alias `ps` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | `fd.DepotID = depot.DepotID` | Lookup via alias `depot` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | `fd.FundingTypeID = x.FundingTypeID` | Lookup via alias `x` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Passthrough `d.CID` from `DWH_staging.etoro_Billing_Deposit`. Production `Billing.Deposit.CID` (same semantics as upstream wiki §4). (Tier 1 — Billing.Deposit) |
| 1 | DepositID | INT | YES | Passthrough `d.DepositID`. `HASH(DepositID)` distribution + clustered index. (Tier 1 — Billing.Deposit) |
| 2 | FundingType | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`) |
| 3 | PaymentDate | TIMESTAMP | YES | Passthrough `d.PaymentDate` (submission UTC). (Tier 1 — Billing.Deposit) |
| 4 | ModificationDate | TIMESTAMP | YES | Passthrough `d.ModificationDate`. ETL incremental watermark. (Tier 1 — Billing.Deposit) |
| 5 | Amount_OriginalCurrency | DECIMAL | YES | ETL `CASE WHEN d.Amount >= 1000000000 THEN 99999999 WHEN d.Amount <= -1000000000 THEN -99999999 ELSE d.Amount END` (2025-04-17 cap). (Tier 2 — Billing.Deposit.Amount) |
| 6 | AmountUSD | DECIMAL | YES | Second INSERT: `Amount * ExchangeRate AS AmountUSD` from `Ext_FBD_Fact_BillingDeposit` snapshot (post-cap `Amount`). (Tier 2 — Billing.Deposit.Amount/ExchangeRate) |
| 7 | Currency | STRING | YES | Direct passthrough from upstream. Formula: `Abbreviation`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`) |
| 8 | BaseExchangeRate | DECIMAL | YES | Passthrough `d.BaseExchangeRate`. Upstream: reference rate before fee markup. (Tier 1 — Billing.Deposit) |
| 9 | ExchangeFee | INT | YES | Passthrough `d.ExchangeFee`. (Tier 1 — Billing.Deposit) |
| 10 | IsFTD | INT | YES | ETL `ISNULL(CAST(d.IsFTD AS int),0)` (bit→int). FTD rules upstream wiki §2.2. (Tier 1 — Billing.Deposit) |
| 11 | PaymentStatus | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus`) |
| 12 | RRE_DeclineReason | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- RRE (Risk Rule Engine) - pre-PSP decline -- ====================== Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_riskmanagementstatus`) |
| 13 | ThreeDS_Result | STRING | NO | `ThreeDS_Result` discriminator: `ThreeDsResponseType = ' '`, `ThreeDsResponseType = ' '`, `ThreeDsResponseType = ' '` → set to '                      ' else '         '. Formula: `-- ====================== -- 3D Secure -- ====================== CASE WHEN ThreeDsAsJson IS NULL AND ThreeDsResponseType IS NULL THEN 'No 3DS' WHEN ThreeDsResponseType = '1' THE…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`) |
| 14 | ThreeDS_FullJson | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('ThreeDsAsJson',d.PaymentData)`. Raw 3DS payload JSON string. (Tier 2 — Billing.Deposit.PaymentData) |
| 15 | PSP_Name | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- PSP / Provider -- ====================== Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`) |
| 16 | MerchantAccountID | INT | YES | Passthrough `d.MerchantAccountID`. (Tier 1 — Billing.Deposit) |
| 17 | MID_SettingsID | INT | YES | Passthrough `d.ProtocolMIDSettingsID`. (Tier 1 — Billing.Deposit) |
| 18 | CardBrand_Visa_MC_Amex | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- Card - Brand (Visa / MasterCard / Amex / Diners) -- ====================== Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_cardtype`) |
| 19 | CardCategory_Tier_And_Product | STRING | YES | `UPDATE fbw SET CardCategory = cb.CardCategory` same JOIN as `BankName` (`SP_Fact_BillingDeposit`). (Tier 2 — Dim_CountryBin.CardCategory) |
| 20 | BIN_Code | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('BinCodeAsString',f.FundingData)`. Downstream `SP_Fact_BillingDeposit`: `CAST(BinCodeAsString AS INT) = Dim_CountryBin.BinCode`. (Tier 2 — Billing.Funding.FundingData) |
| 21 | IssuingBank | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('BankNameAsString',f.FundingData)` (XML). Distinct from `BankName` column enriched from `Dim_CountryBin`. (Tier 2 — Billing.Funding.FundingData) |
| 22 | CardIssuingCountry_BIN | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_country`) |
| 23 | AFT_Supported | STRING | NO | `AFT_Supported` computed flag. Formula: `-- ====================== -- AFT (Account Funding Transaction) -- ====================== CASE WHEN IsAftSupportedAsBool = true THEN 'Yes' ELSE 'No' END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`) |
| 24 | AFT_Eligible | STRING | NO | `AFT_Eligible` computed flag. Formula: `CASE WHEN IsAftEligibleAsBool = true THEN 'Yes' ELSE 'No' END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`) |
| 25 | AFT_Processed | STRING | NO | `AFT_Processed` computed flag. Formula: `CASE WHEN IsAftProcessedAsBool = true THEN 'Yes' ELSE 'No' END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`) |
| 26 | Regulation | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- Regulation -- ====================== Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_regulation`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PaymentStatus.md` |
| `main.general.bronze_etoro_dictionary_riskmanagementstatus` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskManagementStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md` |
| `main.general.bronze_etoro_dictionary_cardtype` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md` |
| `main.general.bronze_etoro_dictionary_country` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |
| `main.general.bronze_etoro_dictionary_regulation` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
... (6 more upstream(s))
        │
        ▼
main.bi_output.vg_factbillingdeposit_transactionsandattributes   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=27 runtime=27 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md`)
- **JOIN/UNION upstreams**: 8 additional object(s)
- **Wiki coverage**: 8/8 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 8 | Formulas: 27 | Tiers: 9 T1, 18 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 27/27 | Source: view_definition*
