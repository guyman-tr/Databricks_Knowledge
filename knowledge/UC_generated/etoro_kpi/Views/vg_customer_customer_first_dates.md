---
object_fqn: main.etoro_kpi.vg_customer_customer_first_dates
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.vg_customer_customer_first_dates
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 23
row_count: null
generated_at: '2026-05-19T15:20:43Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.bi_db.bronze_moneybusdb_dictionary_accounttypes
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions
- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_customer_first_dates.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_customer_first_dates.sql
concept_count: 1
formula_count: 23
tier_breakdown:
  tier1_columns: 11
  tier2_columns: 12
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_customer_customer_first_dates

> View in `main.etoro_kpi`. 1 business concept(s) in §2; 23 of 23 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_customer_customer_first_dates` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 23 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Tue Apr 14 15:47:16 UTC 2026 |

---

## 1. Business Meaning

`vg_customer_customer_first_dates` is a view in `main.etoro_kpi` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md`. Additional upstreams: 4 object(s), listed in §5 Lineage.

Of its 23 columns: 11 inherit byte-for-byte from upstream wikis (Tier 1), 12 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `cfd.CID = dc.RealCID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_customer_first_dates.sql` L34
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `cfd.CID = dc.RealCID` | Lookup via alias `dc` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 1 | GCID | INT | YES | Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 2 | RegistrationDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `, GCID , RegisteredReal`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 3 | FirstDepositDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 4 | FirstDepositAmount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 5 | FTDPlatformID | INT | YES | Computed in source (transform kind not classified). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount , ID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 6 | FTDPlatformName | STRING | YES | Computed flag (CASE expression in source). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount , ID AS FTDPlatformID , CASE WHEN Name = 'Trading' THEN 'TradingPlatform…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 7 | FirstPosOpenDate | TIMESTAMP | YES | First position open timestamp (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 8 | LastDepositDate | TIMESTAMP | YES | Most recent deposit date. From Fact_BillingDeposit.ModificationDate for today's deposits. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 9 | LastDepositAmount | DECIMAL | YES | Most recent deposit amount in USD (Amount * ExchangeRate). (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 10 | VerificationLevel1Date | TIMESTAMP | YES | Date customer first reached KYC verification level 1 (basic). From Fact_SnapshotCustomer + Dim_Range: MIN(FromDateID) WHERE VerificationLevelID=1. Backfilled from Level 2/3 dates if missing. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 11 | VerificationLevel2Date | TIMESTAMP | YES | Date customer first reached KYC verification level 2 (intermediate). MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from Level 3 date if missing. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 12 | VerificationLevel3Date | TIMESTAMP | YES | Date customer first reached KYC verification level 3 (full KYC). MIN(FromDateID) WHERE VerificationLevelID=3. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 13 | FirstFundedDate | TIMESTAMP | YES | Permanent graduation date -- the LATEST of the three funded milestones. Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)). Set once (WHERE NULL guard). Source: Function_Population_First_Time_Funded. (Tier 2 — Function_Population_First_Time_Funded) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 14 | LastNewFundedDate | TIMESTAMP | YES | Most recent date the customer was funded. COALESCE of MAX(Date) from DDR_Customer_Daily_Status WHERE IsFunded=1 and current Function_Population_Funded result. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 15 | LastCashoutDate | TIMESTAMP | YES | Most recent withdrawal timestamp. MAX(Occurred) WHERE ActionTypeID=8. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 16 | FirstAction | STRING | YES | Computed flag (CASE expression in source). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount , ID AS FTDPlatformID , CASE WHEN Name = 'Trading' THEN 'TradingPlatform…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 17 | FirstActionDate | TIMESTAMP | YES | Computed flag (CASE expression in source). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount , ID AS FTDPlatformID , CASE WHEN Name = 'Trading' THEN 'TradingPlatform…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 18 | FirstInstrument | STRING | YES | Computed flag (CASE expression in source). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount , ID AS FTDPlatformID , CASE WHEN Name = 'Trading' THEN 'TradingPlatform…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 19 | FirstCross | STRING | YES | Computed flag (CASE expression in source). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount , ID AS FTDPlatformID , CASE WHEN Name = 'Trading' THEN 'TradingPlatform…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 20 | FirstCrossDate | TIMESTAMP | YES | Computed flag (CASE expression in source). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount , ID AS FTDPlatformID , CASE WHEN Name = 'Trading' THEN 'TradingPlatform…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 21 | FirstClub | STRING | YES | Computed flag (CASE expression in source). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount , ID AS FTDPlatformID , CASE WHEN Name = 'Trading' THEN 'TradingPlatform…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 22 | FirstClubDate | TIMESTAMP | YES | Computed flag (CASE expression in source). Formula: `, GCID , RegisteredReal AS RegistrationDate , FirstDepositDate , FirstDepositAmount , ID AS FTDPlatformID , CASE WHEN Name = 'Trading' THEN 'TradingPlatform…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | JOIN/UNION | `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_First5Actions.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_ClubChangeLogProduct.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.bi_db.bronze_moneybusdb_dictionary_accounttypes
... (2 more upstream(s))
        │
        ▼
main.etoro_kpi.vg_customer_customer_first_dates   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=23 runtime=23 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md`)
- **JOIN/UNION upstreams**: 4 additional object(s)
- **Wiki coverage**: 4/4 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 23 | Tiers: 11 T1, 12 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 23/23 | Source: view_definition*
