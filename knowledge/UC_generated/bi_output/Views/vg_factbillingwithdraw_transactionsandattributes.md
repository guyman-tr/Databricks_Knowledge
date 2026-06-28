---
object_fqn: main.bi_output.vg_factbillingwithdraw_transactionsandattributes
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_factbillingwithdraw_transactionsandattributes
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 17
row_count: null
generated_at: '2026-06-19T14:36:06Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus
- main.general.bronze_etoro_dictionary_cashoutreason
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot
- main.general.bronze_etoro_dictionary_cardtype
- main.general.bronze_etoro_dictionary_country
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingwithdraw_transactionsandattributes.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingwithdraw_transactionsandattributes.sql
concept_count: 4
formula_count: 17
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 10
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_factbillingwithdraw_transactionsandattributes

> View in `main.bi_output`. 4 business concept(s) in §2; 17 of 17 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_factbillingwithdraw_transactionsandattributes` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 17 |
| **Concepts** | 4 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Thu May 14 12:42:17 UTC 2026 |

---

## 1. Business Meaning

`vg_factbillingwithdraw_transactionsandattributes` is a view in `main.bi_output` that composes 4 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md`. Additional upstreams: 7 object(s), listed in §5 Lineage.

Of its 17 columns: 7 inherit byte-for-byte from upstream wikis (Tier 1), 10 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `cur` → `gold_sql_dp_prod_we_dwh_dbo_dim_currency`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_currency` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fw.CurrencyID = cur.CurrencyID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingwithdraw_transactionsandattributes.sql` L51
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`

### 2.2 Dim lookup via alias `cs` → `gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fw.CashoutStatusID_Withdraw = cs.CashoutStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingwithdraw_transactionsandattributes.sql` L53
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus`

### 2.3 Dim lookup via alias `depot` → `gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fw.DepotID = depot.DepotID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingwithdraw_transactionsandattributes.sql` L57
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`

### 2.4 Dim lookup via alias `x` → `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fw.FundingTypeID_Withdraw = x.FundingTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_factbillingwithdraw_transactionsandattributes.sql` L61
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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_currency`, `gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus`, `gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`, `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | `fw.CurrencyID = cur.CurrencyID` | Lookup via alias `cur` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus` | `fw.CashoutStatusID_Withdraw = cs.CashoutStatusID` | Lookup via alias `cs` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | `fw.DepotID = depot.DepotID` | Lookup via alias `depot` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | `fw.FundingTypeID_Withdraw = x.FundingTypeID` | Lookup via alias `x` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Customer ID. FK to Customer.CustomerStatic. (Tier 1 — Billing.Withdraw) |
| 1 | WithdrawPaymentID | INT | YES | Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID. (Tier 1 — Billing.WithdrawToFunding) |
| 2 | FundingType | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`) |
| 3 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the most recent status change or update on the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 4 | Amount_OriginalCurrency | DECIMAL | YES | Gross withdrawal amount in CurrencyID denomination. Renamed from Amount to disambiguate from WithdrawToFunding Amount. (Tier 1 — Billing.Withdraw) |
| 5 | Currency | STRING | YES | Direct passthrough from upstream. Formula: `Abbreviation`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`) |
| 6 | BaseExchangeRate | DECIMAL | YES | Reference exchange rate before fee markup. Spread = ExchangeRate minus BaseExchangeRate. (Tier 1 — Billing.WithdrawToFunding) |
| 7 | ExchangeFee | INT | YES | Exchange fee in provider-specific integer units. (Tier 1 — Billing.WithdrawToFunding) |
| 8 | WithdrawStatus | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- Status -- ====================== Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus`) |
| 9 | CashoutReason | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_cashoutreason`) |
| 10 | PSP_Name | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- PSP / Provider -- ====================== Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`) |
| 11 | MID_SettingsID | INT | YES | MID configuration profile used for this payment leg. FK to Dim_BillingProtocolMIDSettingsID. Default=0. (Tier 1 — Billing.WithdrawToFunding) |
| 12 | CardBrand_Visa_MC_Amex | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- Card - Brand (Visa / MasterCard / Amex / Diners) -- ====================== Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_cardtype`) |
| 13 | CardCategory_Tier_And_Product | STRING | YES | Card category (Debit, Credit, Prepaid, etc.) looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.CardCategory. NULL when BIN code not found. (Tier 2 — SP_Fact_BillingWithdraw) |
| 14 | BIN_Code | STRING | YES | Bank Identification Number (first 6-8 digits of card). COALESCE from wtf/bf XML. CAST to INT for JOIN with Dim_CountryBin to populate BankName and CardCategory. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 15 | IssuingBank | STRING | YES | Bank name from the bf.FundingData XML. Distinct from the enriched BankName (#82) which comes from Dim_CountryBin BIN-code lookup, and ClientBankNameAsString (#44) which is COALESCE from wtf/bf. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 16 | CardIssuingCountry_BIN | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_country`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CashoutStatus.md` |
| `main.general.bronze_etoro_dictionary_cashoutreason` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutReason.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md` |
| `main.general.bronze_etoro_dictionary_cardtype` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md` |
| `main.general.bronze_etoro_dictionary_country` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
... (5 more upstream(s))
        │
        ▼
main.bi_output.vg_factbillingwithdraw_transactionsandattributes   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=17 runtime=17 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md`)
- **JOIN/UNION upstreams**: 7 additional object(s)
- **Wiki coverage**: 7/7 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 4 | Formulas: 17 | Tiers: 7 T1, 10 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 17/17 | Source: view_definition*
