---
object_fqn: main.bi_output.vg_positionsvolumeandattributes_lc4_source_test1
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_positionsvolumeandattributes_lc4_source_test1
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: '2026-05-19T15:02:05Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
- main.dwh.dim_position
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_positionsvolumeandattributes_lc4_source_test1.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_positionsvolumeandattributes_lc4_source_test1.sql
concept_count: 7
formula_count: 15
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 12
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_positionsvolumeandattributes_lc4_source_test1

> View in `main.bi_output`. 7 business concept(s) in §2; 15 of 15 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_positionsvolumeandattributes_lc4_source_test1` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 15 |
| **Concepts** | 7 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Dec 15 14:17:50 UTC 2025 |

---

## 1. Business Meaning

`vg_positionsvolumeandattributes_lc4_source_test1` is a view in `main.bi_output` that composes 2 CASE-based classifier flag(s) computed from upstream IDs, 5 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md`. Additional upstreams: 8 object(s), listed in §5 Lineage.

Of its 15 columns: 3 inherit byte-for-byte from upstream wikis (Tier 1), 12 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `HasEMoneyAccount` discriminator: `IsPartialCloseChild = 0`, `MirrorID = 0` → set to 1 else 0
**What**: Computed flag on `HasEMoneyAccount` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `HasEMoneyAccount`
**Rules**:
- `IsPartialCloseChild = 0`
- `MirrorID = 0`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positionsvolumeandattributes_lc4_source_test1.sql` bi_output.sql L16-L52
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet`

### 2.2 `HasEMoneyAccount` discriminator: `MirrorID = 0` → set to 1 else 0
**What**: Computed flag on `HasEMoneyAccount` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `HasEMoneyAccount`
**Rules**:
- `MirrorID = 0`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positionsvolumeandattributes_lc4_source_test1.sql` bi_output.sql L82-L117
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet`

### 2.3 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dp.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positionsvolumeandattributes_lc4_source_test1.sql` L20,L86
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.4 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dr.DateRangeID = fsc.DateRangeID        AND CAST(date_format(bse.Date_, '        '`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positionsvolumeandattributes_lc4_source_test1.sql` L56,L121
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.5 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positionsvolumeandattributes_lc4_source_test1.sql` L60,L125
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.6 Dim lookup via alias `c` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = c.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positionsvolumeandattributes_lc4_source_test1.sql` L62,L127
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.7 Dim lookup via alias `ema` → `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `bse.CID = ema.CID        AND ema.GCID_Unique_Count = 1        AND ema.IsValidCustomer = 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positionsvolumeandattributes_lc4_source_test1.sql` L64,L129
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`

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
| Filter on discriminator flags | Use `HasEMoneyAccount = 1`-style filters on the precomputed flag columns (`HasEMoneyAccount`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `gold_sql_dp_prod_we_dwh_dbo_dim_range`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_country`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `dp.InstrumentID = di.InstrumentID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `dr.DateRangeID = fsc.DateRangeID        AND CAST(date_format(bse.Date_, '        '` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `fsc.PlayerLevelID = dpl.PlayerLevelID` | Lookup via alias `dpl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `fsc.CountryID = c.CountryID` | Lookup via alias `c` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `bse.CID = ema.CID        AND ema.GCID_Unique_Count = 1        AND ema.IsValidCustomer = 1` | Lookup via alias `ema` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountTypeID | INT | YES | Account type (e.g., 7=Employee, 9=excluded). FK to Dim_AccountType. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 1 | Region | STRING | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 2 | CountryName | STRING | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki) |
| 3 | SellCurrencyID | INT | YES | Direct passthrough from upstream. Formula: `SellCurrencyID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 4 | InstrumentType | STRING | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 5 | IsSettled | INT | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 6 | CID | INT | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 7 | Date_ | DATE | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , CAST(OpenOccurred AS DATE)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 8 | position_event_flag | STRING | NO | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , CAST(OpenOccurred AS DATE) AS Date_ , 'OpenDataFlag'`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 9 | Amount_Total | DECIMAL | NO | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , CAST(OpenOccurred AS DATE) AS Date_ , 'OpenDataFlag' AS position_event_flag , COALESC…`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 10 | Amount_lc | DECIMAL | NO | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , CAST(OpenOccurred AS DATE) AS Date_ , 'OpenDataFlag' AS position_event_flag , COALESC…`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 11 | num_positions_total | LONG | NO | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , CAST(OpenOccurred AS DATE) AS Date_ , 'OpenDataFlag' AS position_event_flag , COALESC…`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 12 | num_positions_lc | LONG | NO | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , CAST(OpenOccurred AS DATE) AS Date_ , 'OpenDataFlag' AS position_event_flag , COALESC…`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 13 | Club | STRING | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 14 | HasEMoneyAccount | INT | NO | `HasEMoneyAccount` discriminator: `IsPartialCloseChild = 0`, `MirrorID = 0` → set to 1 else 0. Formula: `AccountTypeID , Region , Name AS CountryName , SellCurrencyID , InstrumentType , IsSettled , CID , Date_ , b…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (+2 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
... (6 more upstream(s))
        │
        ▼
main.bi_output.vg_positionsvolumeandattributes_lc4_source_test1   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=15 runtime=15 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md`)
- **JOIN/UNION upstreams**: 8 additional object(s)
- **Wiki coverage**: 7/8 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 7 | Formulas: 15 | Tiers: 3 T1, 12 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 15/15 | Source: view_definition*
