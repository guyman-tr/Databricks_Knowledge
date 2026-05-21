---
object_fqn: main.etoro_kpi_prep.v_revenue_stakingfee
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_stakingfee
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 22
row_count: null
generated_at: '2026-05-19T12:26:40Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_stakingfee.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_stakingfee.sql
concept_count: 2
formula_count: 22
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 22
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_stakingfee

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 22 of 22 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_stakingfee` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 22 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 3 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:52 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_stakingfee` is a view in `main.etoro_kpi_prep` that composes 2 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Staking_Results.md`. Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 22 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 22 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dss.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_stakingfee.sql` L36
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.2 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID     AND CAST(DATE_FORMAT(CAST(LAST_DAY(ADD_MONTHS(dss.UpdateDate, -1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_stakingfee.sql` L40
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `gold_sql_dp_prod_we_dwh_dbo_dim_range`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `dss.InstrumentID = di.InstrumentID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID     AND CAST(DATE_FORMAT(CAST(LAST_DAY(ADD_MONTHS(dss.UpdateDate, -1` | Lookup via alias `dr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | StakingMonthID | STRING | YES | Function call computed in source. Formula: `LEFT(CAST(StakingMonthID AS STRING), 6)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 1 | Date | DATE | YES | Arithmetic combination of upstream columns. Formula: `ADD_MONTHS(UpdateDate, -1)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 2 | DateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(CAST(ADD_MONTHS(UpdateDate, -1) AS DATE), 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 3 | StakingMonth | STRING | YES | Direct passthrough from upstream. Formula: `StakingMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 4 | StakingYear | INT | YES | Direct passthrough from upstream. Formula: `StakingYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 5 | InstrumentID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 6 | Instrument | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 7 | CID | LONG | YES | Direct passthrough from upstream. Formula: `CID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 8 | GCID | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 9 | IsEligible | INT | YES | Direct passthrough from upstream. Formula: `IsEligible`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 10 | NonEligible_PrimaryReason | STRING | YES | Direct passthrough from upstream. Formula: `NonEligible_PrimaryReason`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 11 | IneligibleCustomerRewards | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN IsEligible = 0 THEN Etoro_Amount ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 12 | RevShareCommission | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN IsEligible = 1 THEN Etoro_Amount ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 13 | ClientPercent | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `Client_Airdrop / NULLIF(Client_Airdrop + Etoro_Amount, 0)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 14 | EtoroPercent | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `Etoro_Amount / NULLIF(Client_Airdrop + Etoro_Amount, 0)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 15 | ClientUSDDistributed | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN IsEligible = 1 THEN USD_Compensation ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 16 | EtoroUSDDistributed | DECIMAL | YES | Direct passthrough from upstream. Formula: `Etoro_Amount_USD`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 17 | TotalUSDDistributed | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN IsEligible = 1 THEN USD_Compensation ELSE 0 END + Etoro_Amount_USD`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 18 | AirDropDateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(CAST(AirdropOccurred AS DATE), 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 19 | ActualCompensationType | STRING | YES | Direct passthrough from upstream. Formula: `ActualCompensationType`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 20 | ClubCategory | STRING | YES | Direct passthrough from upstream. Formula: `ClubCategory`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 21 | IsValidCustomer | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | Primary | `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Staking_Results.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
... (1 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_revenue_stakingfee   ←── this object
        │
        ▼
main.de_output_stg.qa_ddr_fact_revenue_generating_actions
main.etoro_kpi_prep.v_ddr_revenues
main.etoro_kpi_prep_stg.v_ddr_revenues
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=22 runtime=22 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` (wiki: `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Staking_Results.md`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 3/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.de_output_stg.qa_ddr_fact_revenue_generating_actions`
- `main.etoro_kpi_prep.v_ddr_revenues`
- `main.etoro_kpi_prep_stg.v_ddr_revenues`

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 22 | Tiers: 0 T1, 22 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 22/22 | Source: view_definition*
