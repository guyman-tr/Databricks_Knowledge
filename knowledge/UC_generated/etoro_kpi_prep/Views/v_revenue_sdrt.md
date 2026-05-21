---
object_fqn: main.etoro_kpi_prep.v_revenue_sdrt
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_sdrt
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 14
row_count: null
generated_at: '2026-05-19T12:26:39Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_sdrt.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_sdrt.sql
concept_count: 4
formula_count: 14
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 4
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 1
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_sdrt

> View in `main.etoro_kpi_prep`. 4 business concept(s) in §2; 13 of 14 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_sdrt` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 14 |
| **Concepts** | 4 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:49 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_sdrt` is a view in `main.etoro_kpi_prep` that composes a UNION ALL with sign-flipped amount legs (deposit/withdraw composition), 2 CASE-based classifier flag(s) computed from upstream IDs, 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 14 columns: 9 inherit byte-for-byte from upstream wikis (Tier 1), 4 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsMarginTrade` discriminator: `SettlementTypeID = 5` (MARGIN_TRADE per upstream wiki) → set to 1 else 0
**What**: Computed flag on `IsMarginTrade` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsMarginTrade`
**Rules**:
- `SettlementTypeID = 5` (MARGIN_TRADE per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_sdrt.sql` etoro_kpi_prep.sql L18-L18
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`

### 2.2 `IsCopy` discriminator: `MirrorID <> 0` → set to 1 else 0
**What**: Computed flag on `IsCopy` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopy`
**Rules**:
- `MirrorID <> 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_sdrt.sql` etoro_kpi_prep.sql L19-L19
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`

### 2.3 Sign-flip leg `main` (multiplies `SDRT` by -1)
**What**: This subselect contributes the negative-sign leg of a UNION ALL composition — amount columns are multiplied by -1 so the downstream rollup nets to (deposit - withdraw).
**Columns Involved**: `SDRT`
**Rules**:
- `-1 * fca.Amount` (sign-flip on amount)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_sdrt.sql` L12
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.4 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fca.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_sdrt.sql` L23
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

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
| Filter on discriminator flags | Use `IsCopy = 1`-style filters on the precomputed flag columns (`IsCopy`, `IsMarginTrade`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`). |
| Sum amounts directly for net flow | Amount columns are already sign-flipped per leg — summing them yields net flow (deposits - withdraws). No need to subset by MIMOAction unless you want gross flow. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `fca.InstrumentID = di.InstrumentID` | Lookup via alias `di` |

### 3.4 Gotchas

- Sign flip in scope(s) `main` means summing amount columns nets to (deposit - withdraw). Multiply by -1 again if you want gross withdraw amounts.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | LONG | YES | Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 1 | GCID | LONG | YES | Global Customer ID — cross-platform identifier linking RealCID to demo and external systems. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 2 | DateID | INT | YES | Integer date key in YYYYMMDD format. DELETE+INSERT keyed on this column. 6,356 distinct dates from April 2008 to present. Passthrough from Fact_CustomerAction.DateID. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| 3 | Occurred | TIMESTAMP | YES | UTC timestamp when the action occurred. Passthrough from Fact_CustomerAction. (Tier 1 — source-dependent) |
| 4 | SDRT | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `-1 * Amount`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`) |
| 5 | InstrumentID | INT | YES | Tradeable instrument pair identifier. FK to Dim_Instrument. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 — Trade.Instrument) |
| 6 | PositionID | LONG | YES | Position identifier. Allocated by Internal.GetPositionID_Bigint. Unique per position. HASH distribution key. DWH note: for ActionTypeID=36 + CompensationReasonID IN (117,118), extracted from Description field via reverse string parsing with TRY_CAST fallback. COALESCE prefers Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 7 | IsBuy | INT | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. Always NULL from Fact_CustomerAction, resolved entirely from Dim_Position. NULL if no Dim_Position match. (Tier 1 — Trade.PositionTbl) |
| 8 | IsSettled | INT | YES | 1 = real asset, 0 = CFD asset. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 5 — Expert Review) |
| 9 | SettlementTypeID | INT | YES | Modern settlement classification from Dim_Position. 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. DWH note: switched from FCA to Dim_Position source (2025-10-15) because FCA shows NULL on overnights. (Tier 1 — Trade.PositionTbl) |
| 10 | IsMarginTrade | INT | NO | `IsMarginTrade` discriminator: `SettlementTypeID = 5` (MARGIN_TRADE per upstream wiki) → set to 1 else 0. Formula: `CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`) |
| 11 | IsCopy | INT | NO | `IsCopy` discriminator: `MirrorID <> 0` → set to 1 else 0. Formula: `CASE WHEN MirrorID <> 0 THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`) |
| 12 | InstrumentTypeID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentTypeID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 13 | IsValidCustomer | INT | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID in Fact_SnapshotCustomer. Passthrough via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
        │
        ▼
main.etoro_kpi_prep.v_revenue_sdrt   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=14 runtime=14 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 4 | Formulas: 14 | Tiers: 9 T1, 4 T2, 0 T3, 0 T4, 1 T5, 0 TN, 0 U | Elements: 14/14 | Source: view_definition*
