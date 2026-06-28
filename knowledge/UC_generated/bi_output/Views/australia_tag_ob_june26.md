---
object_fqn: main.bi_output.australia_tag_ob_june26
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.australia_tag_ob_june26
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 8
row_count: null
generated_at: '2026-06-19T14:35:41Z'
upstreams:
- main.bi_db.bronze_clubservice_clubs_userbalances
- main.bi_db.bronze_clubservice_dictionary_balancesourcetypes
- main.bi_db.bronze_compliancestatedb_compliance_customerconsents
- main.bi_db.bronze_customerfinancedb_customer_globalftds
- main.bi_db.bronze_deltaapp_bronze_subscriptions
- main.bi_db.bronze_etoro_dictionary_withdrawtype
- main.bi_db.bronze_etoro_dwh_hedgenetting
- main.bi_db.bronze_etoro_dwh_v_historymirrorhourly
- main.bi_db.bronze_etoro_history_instrumentmetadata
- main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/australia_tag_ob_june26.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/australia_tag_ob_june26.sql
concept_count: 0
formula_count: 8
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 8
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# australia_tag_ob_june26

> View in `main.bi_output`. 0 business concept(s) in §2; 8 of 8 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.australia_tag_ob_june26` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | barar@etoro.com |
| **Row count** | n/a |
| **Column count** | 8 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Sun Jun 14 12:11:12 UTC 2026 |

---

## 1. Business Meaning

`australia_tag_ob_june26` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.bronze_clubservice_clubs_userbalances` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_clubservice_clubs_userbalances.md`. Additional upstreams: 210 object(s), listed in §5 Lineage.

Of its 8 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 8 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.bi_db.bronze_clubservice_clubs_userbalances` (and 210 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

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
| 1 | $distinct_id | STRING | YES | Computed in source (transform kind not classified). Formula: ``$distinct_id``. (Tier 2 — literal) |
| 1 | $name | STRING | YES | Computed in source (transform kind not classified). Formula: ``$name``. (Tier 2 — literal) |
| 2 | $email | STRING | YES | Computed in source (transform kind not classified). Formula: ``$email``. (Tier 2 — literal) |
| 3 | $last_seen | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: ``$last_seen``. (Tier 2 — literal) |
| 4 | $country_code | STRING | YES | Computed in source (transform kind not classified). Formula: ``$country_code``. (Tier 2 — literal) |
| 5 | $region | STRING | YES | Computed in source (transform kind not classified). Formula: ``$region``. (Tier 2 — literal) |
| 6 | $city | STRING | YES | Computed in source (transform kind not classified). Formula: ``$city``. (Tier 2 — literal) |
| 7 | $GCID | INT | YES | Computed in source (transform kind not classified). Formula: ``$GCID``. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.bronze_clubservice_clubs_userbalances` | Primary | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_clubservice_clubs_userbalances.md` |
| `main.bi_db.bronze_clubservice_dictionary_balancesourcetypes` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_clubservice_dictionary_balancesourcetypes.md` |
| `main.bi_db.bronze_compliancestatedb_compliance_customerconsents` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_compliancestatedb_compliance_customerconsents.md` |
| `main.bi_db.bronze_customerfinancedb_customer_globalftds` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_customerfinancedb_customer_globalftds.md` |
| `main.bi_db.bronze_deltaapp_bronze_subscriptions` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_deltaapp_bronze_subscriptions.md` |
| `main.bi_db.bronze_etoro_dictionary_withdrawtype` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md` |
| `main.bi_db.bronze_etoro_dwh_hedgenetting` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_etoro_dwh_hedgenetting.md` |
| `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_etoro_dwh_v_historymirrorhourly.md` |
| `main.bi_db.bronze_etoro_history_instrumentmetadata` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` |
| `main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md` |
| `main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` |
| `main.bi_db.bronze_fivetran_dealing_active_hs_mappings` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_fivetran_dealing_active_hs_mappings.md` |
| `main.bi_db.bronze_interest_history_interestconsent` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_interest_history_interestconsent.md` |
| `main.bi_db.bronze_interest_trade_interestconsent` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_interest_trade_interestconsent.md` |
| `main.bi_db.bronze_kycanalyzer_analyzer_instrumentstatus` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_kycanalyzer_analyzer_instrumentstatus.md` |
| `main.bi_db.bronze_moneytransfer_billing_transfers` | JOIN/UNION | `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` |
| `main.bi_db.bronze_navigationservice_ns_stephistory` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_navigationservice_ns_stephistory.md` |
| `main.bi_db.bronze_navigationservice_ns_userflows` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_navigationservice_ns_userflows.md` |
| `main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.InstanceStatusID.md` |
| `main.bi_db.bronze_recurringinvestment_dictionary_planeventcode` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanEventCode.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.bronze_clubservice_clubs_userbalances
main.bi_db.bronze_clubservice_dictionary_balancesourcetypes
main.bi_db.bronze_compliancestatedb_compliance_customerconsents
... (17 more upstream(s))
        │
        ▼
main.bi_output.australia_tag_ob_june26   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=8 runtime=8 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.bronze_clubservice_clubs_userbalances` (wiki: `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_clubservice_clubs_userbalances.md`)
- **JOIN/UNION upstreams**: 19 additional object(s)
- **Wiki coverage**: 19/19 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 0 | Formulas: 8 | Tiers: 0 T1, 8 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: view_definition*
