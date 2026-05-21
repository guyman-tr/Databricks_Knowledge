---
object_fqn: main.etoro_kpi_prep.v_moneyfarm_fees
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_moneyfarm_fees
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:26:27Z'
upstreams:
- main.bi_db.bronze_etoro_trade_adminpositionlog
- main.bi_db.bronze_moneybusdb_dictionary_accounttypes
- main.bi_db.bronze_sub_accounts_accounts
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_moneyfarm_fees.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_moneyfarm_fees.sql
concept_count: 0
formula_count: 5
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 5
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_moneyfarm_fees

> View in `main.etoro_kpi_prep`. 0 business concept(s) in §2; 5 of 5 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_moneyfarm_fees` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 5 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Mar 23 10:22:39 UTC 2026 |

---

## 1. Business Meaning

`v_moneyfarm_fees` is a view in `main.etoro_kpi_prep`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.bronze_etoro_trade_adminpositionlog` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md`. Additional upstreams: 82 object(s), listed in §5 Lineage.

Of its 5 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 5 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | date | DATE | YES | Arithmetic combination of upstream columns. Formula: `-- this is currently a placeholder, no fee logic exists yet CAST(NULL AS DATE)`. (Tier 2 — computed in source) |
| 1 | dateid | INT | YES | Cast of upstream column. Formula: `CAST(NULL AS INT)`. (Tier 2 — computed in source) |
| 2 | gcid | LONG | YES | Cast of upstream column. Formula: `CAST(NULL AS BIGINT)`. (Tier 2 — computed in source) |
| 3 | total_fees_gbp | DOUBLE | YES | Cast of upstream column. Formula: `CAST(NULL AS DOUBLE)`. (Tier 2 — computed in source) |
| 4 | total_fees_usd | DOUBLE | YES | Cast of upstream column. Formula: `CAST(NULL AS DOUBLE)`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.bronze_etoro_trade_adminpositionlog` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` |
| `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | JOIN/UNION | `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Daily_CreditLine.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee_Reversals.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | JOIN/UNION | `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Staking_Results.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Fact_Transaction_Status.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoneyClientBalance.md` |
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | JOIN/UNION | `knowledge\synapse\Wiki\EXW_dbo\Tables\EXW_C2F_E2E.md` |
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e` | JOIN/UNION | `knowledge\synapse\Wiki\EXW_dbo\Tables\EXW_C2P_E2E.md` |
| `main.bi_output._tmp_scd_merge_source` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/_tmp_scd_merge_source.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_opened_from_iban.md` |
| `main.bi_output_stg._tmp_scd_merge_source` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.bronze_etoro_trade_adminpositionlog
main.bi_db.bronze_moneybusdb_dictionary_accounttypes
main.bi_db.bronze_sub_accounts_accounts
... (17 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_moneyfarm_fees   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=5 runtime=5 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.bronze_etoro_trade_adminpositionlog` (wiki: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md`)
- **JOIN/UNION upstreams**: 19 additional object(s)
- **Wiki coverage**: 17/19 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 5 | Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: view_definition*
