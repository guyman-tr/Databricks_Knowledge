---
object_fqn: main.bi_output.vg_fact_billingwithdraw_for_genie
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_fact_billingwithdraw_for_genie
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 21
row_count: null
generated_at: '2026-06-19T14:36:06Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
- main.bi_db.bronze_etoro_dictionary_withdrawtype
- main.billing.bronze_etoro_billing_depot
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingwithdraw_for_genie.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingwithdraw_for_genie.sql
concept_count: 1
formula_count: 21
tier_breakdown:
  tier1_columns: 11
  tier2_columns: 10
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_fact_billingwithdraw_for_genie

> View in `main.bi_output`. 1 business concept(s) in §2; 21 of 21 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fact_billingwithdraw_for_genie` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 21 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Wed Feb 04 14:34:23 UTC 2026 |

---

## 1. Business Meaning

`vg_fact_billingwithdraw_for_genie` is a view in `main.bi_output` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md`. Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 21 columns: 11 inherit byte-for-byte from upstream wikis (Tier 1), 10 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `dft` → `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `bw.FundingTypeID_Withdraw = dft.FundingTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingwithdraw_for_genie.sql` L44
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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | `bw.FundingTypeID_Withdraw = dft.FundingTypeID` | Lookup via alias `dft` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Customer ID. FK to Customer.CustomerStatic. (Tier 1 — Billing.Withdraw) |
| 1 | WithdrawID | INT | YES | Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column. (Tier 1 — Billing.Withdraw) |
| 2 | FundingID | INT | YES | FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. (Tier 1 — Billing.Withdraw) |
| 3 | Amount_Withdraw | DECIMAL | YES | Gross withdrawal amount in CurrencyID denomination. Renamed from Amount to disambiguate from WithdrawToFunding Amount. (Tier 1 — Billing.Withdraw) |
| 4 | ExchangeRate | DECIMAL | YES | Exchange rate applied to convert from withdrawal currency to ProcessCurrencyID. NULL for same-currency payouts. (Tier 1 — Billing.WithdrawToFunding) |
| 5 | BaseExchangeRate | DECIMAL | YES | Reference exchange rate before fee markup. Spread = ExchangeRate minus BaseExchangeRate. (Tier 1 — Billing.WithdrawToFunding) |
| 6 | Fee | DECIMAL | YES | Platform fee charged for this withdrawal. Subtracted from the gross Amount_Withdraw. (Tier 1 — Billing.Withdraw) |
| 7 | CashoutStatusID_Withdraw | INT | YES | Withdrawal request-level status. FK to Dim_CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. Renamed from CashoutStatusID. (Tier 1 — Billing.Withdraw) |
| 8 | CashoutReasonID | INT | YES | Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason. (Tier 1 — Billing.Withdraw) |
| 9 | ErrorCodeAsString | STRING | YES | Provider error code if the payment leg failed or was rejected. Extracted from wtf.WithdrawData XML only. NULL for successful transactions. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 10 | ResponseMessageAsString | STRING | YES | Provider response message (success/failure details). Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 11 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the most recent status change or update on the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 12 | FundingType | STRING | YES | Arithmetic combination of upstream columns. Formula: `/* ===== Identity ===== */ CID , WithdrawID , FundingID /* ===== Amount & Currency ===== */ , Amount_Withdraw -- Amount , ExchangeRate , BaseExchan…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw`) |
| 13 | WithdrawType | STRING | YES | Arithmetic combination of upstream columns. Formula: `/* ===== Identity ===== */ CID , WithdrawID , FundingID /* ===== Amount & Currency ===== */ , Amount_Withdraw -- Amount , ExchangeRate , BaseExchan…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw`) |
| 14 | DepotName | STRING | YES | Arithmetic combination of upstream columns. Formula: `/* ===== Identity ===== */ CID , WithdrawID , FundingID /* ===== Amount & Currency ===== */ , Amount_Withdraw -- Amount , ExchangeRate , BaseExchan…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw`) |
| 15 | BankNameAsString | STRING | YES | Bank name from the bf.FundingData XML. Distinct from the enriched BankName (#82) which comes from Dim_CountryBin BIN-code lookup, and ClientBankNameAsString (#44) which is COALESCE from wtf/bf. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 16 | ProtocolMIDSettingsID | INT | YES | MID configuration profile used for this payment leg. FK to Dim_BillingProtocolMIDSettingsID. Default=0. (Tier 1 — Billing.WithdrawToFunding) |
| 17 | BinCodeAsString | STRING | YES | Bank Identification Number (first 6-8 digits of card). COALESCE from wtf/bf XML. CAST to INT for JOIN with Dim_CountryBin to populate BankName and CardCategory. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 18 | BinCountryIDAsInteger | STRING | YES | Country associated with the BIN code. COALESCE from wtf/bf XML. FK to Dim_Country after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 19 | CardTypeIDAsInteger | STRING | YES | Card type identifier (Visa, Mastercard, etc.). COALESCE from wtf/bf XML. FK to Dim_CardType after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 20 | CardCategory | STRING | YES | Card category (Debit, Credit, Prepaid, etc.) looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.CardCategory. NULL when BIN code not found. (Tier 2 — SP_Fact_BillingWithdraw) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `main.bi_db.bronze_etoro_dictionary_withdrawtype` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md` |
| `main.billing.bronze_etoro_billing_depot` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
main.bi_db.bronze_etoro_dictionary_withdrawtype
... (1 more upstream(s))
        │
        ▼
main.bi_output.vg_fact_billingwithdraw_for_genie   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=21 runtime=21 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 3/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 1 | Formulas: 21 | Tiers: 11 T1, 10 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 21/21 | Source: view_definition*
