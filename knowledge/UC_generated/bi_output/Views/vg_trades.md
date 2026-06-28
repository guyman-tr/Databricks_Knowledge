---
object_fqn: main.bi_output.vg_trades
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_trades
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 23
row_count: null
generated_at: '2026-06-19T14:36:08Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql
concept_count: 8
formula_count: 23
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 20
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_trades

> View in `main.bi_output`. 8 business concept(s) in §2; 23 of 23 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_trades` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 23 |
| **Concepts** | 8 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Sun Oct 19 07:13:42 UTC 2025 |

---

## 1. Business Meaning

`vg_trades` is a view in `main.bi_output` that composes 2 CASE-based classifier flag(s) computed from upstream IDs, 6 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 7 object(s), listed in §5 Lineage.

Of its 23 columns: 3 inherit byte-for-byte from upstream wikis (Tier 1), 20 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `ActionType` discriminator: `MifidCategorizationID IN (2,3)`, `ActionTypeID IN (1, 4, 39, 40)` → set to '      ' else '    '
**What**: Computed flag on `ActionType` set to `'      '` when the predicates below hold, else `'    '`.
**Columns Involved**: `ActionType`
**Rules**:
- `MifidCategorizationID IN (2,3)`
- `ActionTypeID IN (1, 4, 39, 40)`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql` bi_output.sql L21-L24
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 `Real` discriminator: `IsSettled = 1`, `IsSettled = 0` → set to '   '
**What**: Computed flag on `Real` set to `'   '` when the predicates below hold, else `None`.
**Columns Involved**: `Real`
**Rules**:
- `IsSettled = 1`
- `IsSettled = 0`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql` bi_output.sql L25-L28

### 2.3 Dim lookup via alias `dmc` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fca.RealCID = dmc.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql` L73
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.4 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql` L75
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.5 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `di.InstrumentID = fca.InstrumentID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql` L77
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.6 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dpl.DWHPlayerLevelID = fsc.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql` L79
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.7 Dim lookup via alias `ps` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `ps.DWHPlayerStatusID = fsc.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql` L81
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.8 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dr.ID = fsc.RegulationID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_trades.sql` L83
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

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
| Filter on discriminator flags | Use `ActionType = 1`-style filters on the precomputed flag columns (`ActionType`, `Real`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `gold_sql_dp_prod_we_dwh_dbo_dim_country`, `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `fca.RealCID = dmc.RealCID` | Lookup via alias `dmc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `fsc.CountryID = dc.CountryID` | Lookup via alias `dc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `di.InstrumentID = fca.InstrumentID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `dpl.DWHPlayerLevelID = fsc.PlayerLevelID` | Lookup via alias `dpl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `ps.DWHPlayerStatusID = fsc.PlayerStatusID` | Lookup via alias `ps` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `dr.ID = fsc.RegulationID` | Lookup via alias `dr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | DATE | YES | Computed in source (transform kind not classified). Formula: `etr_ymd `Date``. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 1 | CID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Country | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 3 | Region | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegionManualName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 4 | InstrumentType | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentType`. (Tier 2 — computed in source) |
| 5 | InstrumentID | INT | YES | FK to `Trade.Instrument`. Financial instrument being traded when row is instrument-bearing. (Tier 1 — Trade.PositionTbl) |
| 6 | InstrumentDisplayName | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentDisplayName`. (Tier 2 — computed in source) |
| 7 | IsFuture | INT | YES | Direct passthrough from upstream. Formula: `IsFuture`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 8 | ClubTier | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`) |
| 9 | PlayerStatus | STRING | YES | Computed in source (transform kind not classified). Formula: `Name PlayerStatus`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 10 | Regulation | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`) |
| 11 | RegistrationDate | DATE | YES | Function call computed in source. Formula: `DATE(RegisteredReal)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 12 | FTDDate | DATE | YES | Function call computed in source. Formula: `DATE(FirstDepositDate)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 13 | IsProfessionalCustomer | INT | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN MifidCategorizationID in (2,3) THEN 1 else 0 END IsProfessionalCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 14 | ActionType | STRING | NO | `ActionType` discriminator: `MifidCategorizationID IN (2,3)`, `ActionTypeID IN (1, 4, 39, 40)` → set to '      ' else '    '. Formula: `CASE WHEN ActionTypeID IN (1, 4, 39, 40) THEN 'Manual' ELSE 'Copy' END`. (Tier 2 — computed in source) |
| 15 | Real/CFD | STRING | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN IsSettled = 1 THEN 'Real' WHEN IsSettled = 0 THEn 'CFD' END AS `Real/CFD``. (Tier 2 — computed in source) |
| 16 | OpenTrades | LONG | YES | Computed flag (CASE expression in source). Formula: `SUM( CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN 1 ELSE 0 END ) OpenTrades`. (Tier 2 — computed in source) |
| 17 | ClosedTrades | LONG | YES | Computed flag (CASE expression in source). Formula: `SUM( CASE WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN 1 ELSE 0 END ) ClosedTrades`. (Tier 2 — computed in source) |
| 18 | TotalTrades | LONG | YES | Computed flag (CASE expression in source). Formula: `SUM( CASE WHEN ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40) THEN 1 ELSE 0 end ) TotalTrades`. (Tier 2 — computed in source) |
| 19 | InvestedAmountOpen | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `SUM( CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN -1 * Amount ELSE 0 END )`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 20 | AmountClose | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `SUM( CASE WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN Amount ELSE 0 END )`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 21 | TotalAmount | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `SUM( CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN -1 * Amount WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN Amount ELSE 0 END )`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 22 | Leverage | INT | YES | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement posture. (Tier 1 — Trade.PositionTbl) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
... (5 more upstream(s))
        │
        ▼
main.bi_output.vg_trades   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=23 runtime=23 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
- **JOIN/UNION upstreams**: 7 additional object(s)
- **Wiki coverage**: 7/7 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 8 | Formulas: 23 | Tiers: 3 T1, 20 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 23/23 | Source: view_definition*
