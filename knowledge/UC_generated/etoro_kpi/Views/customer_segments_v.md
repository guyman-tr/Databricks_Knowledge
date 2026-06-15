---
object_fqn: main.etoro_kpi.customer_segments_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.customer_segments_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: '2026-05-19T15:20:35Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
- main.bi_dealing.bi_output_dealing_cidage_data
- main.etoro_kpi.ddr_aum_v
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition
- main.etoro_kpi_stg.bi_output_vg_aum_slim
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/customer_segments_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/customer_segments_v.sql
concept_count: 1
formula_count: 15
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 6
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# customer_segments_v

> View in `main.etoro_kpi`. 1 business concept(s) in §2; 15 of 15 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.customer_segments_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 15 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Mon May 04 08:38:27 UTC 2026 |

---

## 1. Business Meaning

`customer_segments_v` is a view in `main.etoro_kpi` that composes 1 CASE-based classifier flag(s) computed from upstream IDs.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md`. Additional upstreams: 4 object(s), listed in §5 Lineage.

Of its 15 columns: 9 inherit byte-for-byte from upstream wikis (Tier 1), 6 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `EquityScore` discriminator: `FirstDepositDate = '                             '`, `EquityGlobal >= 10000` → set to '   ' else '         '
**What**: Computed flag on `EquityScore` set to `'   '` when the predicates below hold, else `'         '`.
**Columns Involved**: `EquityScore`
**Rules**:
- `FirstDepositDate = '                             '`
- `EquityGlobal >= 10000`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/customer_segments_v.sql` etoro_kpi.sql L14-L29
**Source(s)**: `bi_dealing.bi_output_dealing_cidage_data`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.etoro_kpi.ddr_aum_v`

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
| Filter on discriminator flags | Use `EquityScore = 1`-style filters on the precomputed flag columns (`EquityScore`) instead of recomputing the underlying CASE predicates downstream. |

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
| 1 | GCID | INT | YES | Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 1 | CID | INT | YES | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 2 | Club | STRING | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. (Tier 1 -Dictionary.PlayerLevel) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 3 | Channel | STRING | YES | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' -> 'Affiliate', AffiliateID IN (56662,56663) -> 'Direct'. Dim-lookup via Dim_Affiliate.SubChannelID -> Dim_Channel.Channel. ISNULL default 'Direct' for customers without affiliate mapping. (Tier 2 -SP_CIDFirstDates via Dim_Channel) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 4 | Country | STRING | YES | Full country name in English. Dim-lookup from Dim_Country.Name via CountryID. (Tier 1 -Dictionary.Country) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 5 | registered | TIMESTAMP | YES | Earliest registration date across demo and real accounts. ETL-computed: MIN(RegisteredDemo, RegisteredReal). Not the real-account-only date. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 6 | FirstDepositDate | TIMESTAMP | YES | Computed flag (CASE expression in source). Formula: `Case when FirstDepositDate = '1900-01-01T00:00:00.000+00:00' Then NULL ELSE FirstDepositDate End`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 7 | FirstCashoutDate | TIMESTAMP | YES | First withdrawal timestamp. MIN(Occurred) WHERE ActionTypeID=8. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 8 | FirstOpenPositionDate | TIMESTAMP | YES | First manual (non-copy) position open timestamp. MIN(Occurred) WHERE ActionTypeID=1. Note: column name has typo 'Menual' (not 'Manual'). (Tier 2 -SP_CIDFirstDates) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 9 | CommunicationLanguage | STRING | YES | Language for customer communications (emails, notifications). Dim-lookup from Dim_Language.Name via CommunicationLanguageID. May differ from Language (UI language). (Tier 1 -Dictionary.Language) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 10 | CustomerAge | LONG | YES | Direct passthrough from upstream. Formula: `Age`. (Tier 2 — from `bi_dealing.bi_output_dealing_cidage_data`) |
| 11 | Is_Churn_over_14 | BOOLEAN | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN LSD IN('Churn 14-30 days' , 'Churn 31-60 days', 'Churn over 60 days' ) Then True else False End Is_Churn_over_14`. (Tier 2 — computed in source) |
| 12 | Is_Churn_over_30 | BOOLEAN | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN LSD IN('Churn 31-60 days', 'Churn over 60 days' ) Then True else False End Is_Churn_over_30`. (Tier 2 — computed in source) |
| 13 | Is_Churn_over_60 | BOOLEAN | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN LSD IN('Churn over 60 days' ) Then True else False End Is_Churn_over_60`. (Tier 2 — computed in source) |
| 14 | EquityScore | STRING | NO | `EquityScore` discriminator: `FirstDepositDate = '                             '`, `EquityGlobal >= 10000` → set to '   ' else '         '. Formula: `CASE WHEN EquityGlobal >= 10000 Then 'High' WHEN EquityGlobal Between 150 and 10000 Then 'Medium' WHEN EquityGlobal Between 0.5 and 150 Then 'Low' Else 'No Equity' End as Equi…`. (Tier 2 — from `main.etoro_kpi.ddr_aum_v`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.bi_dealing.bi_output_dealing_cidage_data` | JOIN/UNION | `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_cidage_data.md` |
| `main.etoro_kpi.ddr_aum_v` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi/<Tables|Views>/ddr_aum_v.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_LifeStageDefinition.md` |
| `main.etoro_kpi_stg.bi_output_vg_aum_slim` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
main.bi_dealing.bi_output_dealing_cidage_data
main.etoro_kpi.ddr_aum_v
... (2 more upstream(s))
        │
        ▼
main.etoro_kpi.customer_segments_v   ←── this object
        │
        ▼
main.etoro_kpi.winback_daily_segments
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=15 runtime=15 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md`)
- **JOIN/UNION upstreams**: 4 additional object(s)
- **Wiki coverage**: 3/4 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi.winback_daily_segments`

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 15 | Tiers: 9 T1, 6 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 15/15 | Source: view_definition*
