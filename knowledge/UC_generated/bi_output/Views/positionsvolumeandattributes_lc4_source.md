---
object_fqn: main.bi_output.positionsvolumeandattributes_lc4_source
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.positionsvolumeandattributes_lc4_source
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: '2026-06-19T14:36:00Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.dim_position
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/positionsvolumeandattributes_lc4_source.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/positionsvolumeandattributes_lc4_source.sql
concept_count: 3
formula_count: 15
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 14
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# positionsvolumeandattributes_lc4_source

> View in `main.bi_output`. 3 business concept(s) in §2; 15 of 15 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.positionsvolumeandattributes_lc4_source` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 15 |
| **Concepts** | 3 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Wed Dec 03 15:29:08 UTC 2025 |

---

## 1. Business Meaning

`positionsvolumeandattributes_lc4_source` is a view in `main.bi_output` that composes 3 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md`. Additional upstreams: 6 object(s), listed in §5 Lineage.

Of its 15 columns: 1 inherit byte-for-byte from upstream wikis (Tier 1), 14 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dp.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/positionsvolumeandattributes_lc4_source.sql` L20,L86
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.2 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dr.DateRangeID = fsc.DateRangeID        AND CAST(date_format(bse.Date_, '        '`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/positionsvolumeandattributes_lc4_source.sql` L58,L123
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.3 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/positionsvolumeandattributes_lc4_source.sql` L62,L127
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `gold_sql_dp_prod_we_dwh_dbo_dim_range`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `dp.InstrumentID = di.InstrumentID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `dr.DateRangeID = fsc.DateRangeID        AND CAST(date_format(bse.Date_, '        '` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `fsc.PlayerLevelID = dpl.PlayerLevelID` | Lookup via alias `dpl` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountTypeID | INT | YES | Account type (e.g., 7=Employee, 9=excluded). FK to Dim_AccountType. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 1 | CountryID | INT | YES | Customer's registered country. FK to Dim_Country. Key filter for valid customer segmentation. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 2 | Region | NULL | YES | Computed in source (transform kind not classified). Formula: `AccountTypeID , CountryID AS CountryID , NULL`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 3 | CountryName | NULL | YES | Computed in source (transform kind not classified). Formula: `AccountTypeID , CountryID AS CountryID , NULL AS Region , NULL`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 4 | SellCurrencyID | INT | YES | Direct passthrough from upstream. Formula: `SellCurrencyID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 5 | InstrumentType | STRING | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 6 | IsSettled | INT | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 7 | CID | INT | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 8 | Date_ | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , OpenOccurred`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 9 | position_event_flag | STRING | NO | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , OpenOccurred AS Date_ , 'OpenDataFlag'`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 10 | Amount_Total | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , OpenOccurred AS Date_ , 'OpenDataFlag' AS position_event_flag , SUM(Amount) AS Amo…`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 11 | Amount_lc | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , OpenOccurred AS Date_ , 'OpenDataFlag' AS position_event_flag , SUM(Amount) AS Amo…`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 12 | num_position_open_total | LONG | NO | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , OpenOccurred AS Date_ , 'OpenDataFlag' AS position_event_flag , SUM(Amount) AS Amo…`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 13 | num_position_open_lc | LONG | NO | Computed in source (transform kind not classified). Formula: `SellCurrencyID , InstrumentType , IsSettled , CID , OpenOccurred AS Date_ , 'OpenDataFlag' AS position_event_flag , SUM(Amount) AS Amo…`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 14 | Club | STRING | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
main.dwh.dim_position
... (4 more upstream(s))
        │
        ▼
main.bi_output.positionsvolumeandattributes_lc4_source   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=15 runtime=15 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md`)
- **JOIN/UNION upstreams**: 6 additional object(s)
- **Wiki coverage**: 5/6 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 3 | Formulas: 15 | Tiers: 1 T1, 14 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 15/15 | Source: view_definition*
