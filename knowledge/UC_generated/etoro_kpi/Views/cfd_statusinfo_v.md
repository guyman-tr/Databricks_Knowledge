---
object_fqn: main.etoro_kpi.cfd_statusinfo_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.cfd_statusinfo_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T15:20:32Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/cfd_statusinfo_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/cfd_statusinfo_v.sql
concept_count: 0
formula_count: 8
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 6
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# cfd_statusinfo_v

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 8 of 8 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.cfd_statusinfo_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 8 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 15 08:54:27 UTC 2026 |

---

## 1. Business Meaning

`cfd_statusinfo_v` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Scored_Appropriateness_Negative_Market.md`.

Of its 8 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 6 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` (and 0 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

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
| 1 | RealCID | INT | YES | Customer Real account ID. Maps to Dim_Customer.RealCID. (Tier 1 — etoro.Account.Customer.RealCID) |
| 1 | GCID | INT | YES | Global Customer ID. Distribution key and clustered index column. Maps to Dim_Customer.GCID. (Tier 1 — Account.Customer) |
| 2 | CFD_Status | STRING | YES | Derived CFD trading status. `CASE WHEN CFDRestrictionStatusID=1 THEN 'CFD_Blocked' ELSE 'CFD_Allowed'`. 2-value enum: "CFD_Blocked" (20%, 3.6M), "CFD_Allowed" (80%, 14.3M). (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 3 | ApproprietnessScore_Status | STRING | YES | Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Distribution: "Failed" 75% (13.4M), "Passed" 24% (4.2M), blank 1%, "Borderline Pass" <0.1%. Note: column name contains typo ("Approprietness" vs "Appropriateness"). (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 4 | ReleaseReasonDesc | STRING | YES | Release reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if not released. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 5 | ReleaseDate | TIMESTAMP | YES | Date when CFD block was released. Only populated when `CFDRestrictionStatusID = 2` (currently allowed after prior block). NULL if still blocked or never blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 6 | BlockDate | TIMESTAMP | YES | Date when CFD trading was blocked. From ComplianceStateDB UserTradingData. NULL if never blocked. Source depends on current status: if currently blocked → current.ReasonDate; if released → history.ReasonDate. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 7 | BlockReasonDesc | STRING | YES | Block reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if never blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Scored_Appropriateness_Negative_Market.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market
        │
        ▼
main.etoro_kpi.cfd_statusinfo_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=8 runtime=8 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Scored_Appropriateness_Negative_Market.md`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 8 | Tiers: 2 T1, 6 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: view_definition*
