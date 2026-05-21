---
object_fqn: main.etoro_kpi_prep.v_copyfund_positions
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_copyfund_positions
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 9
row_count: null
generated_at: '2026-05-19T12:26:21Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
- main.dwh.dim_position
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_copyfund_positions.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_copyfund_positions.sql
concept_count: 2
formula_count: 9
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 4
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_copyfund_positions

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 9 of 9 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_copyfund_positions` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 9 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 4 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 24 10:58:29 UTC 2026 |

---

## 1. Business Meaning

`v_copyfund_positions` is a view in `main.etoro_kpi_prep` that composes 2 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 9 columns: 5 inherit byte-for-byte from upstream wikis (Tier 1), 4 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Filter on scope `copyfund_mirrors`: `MirrorTypeID = 4`
**What**: `WHERE` clause at the top of scope `copyfund_mirrors` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `MirrorTypeID`
**Rules**:
- `MirrorTypeID = 4`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_copyfund_positions.sql` L14

### 2.2 Filter on scope `copyfund_positions`: `MirrorID > 0`
**What**: `WHERE` clause at the top of scope `copyfund_positions` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `MirrorID`
**Rules**:
- `MirrorID > 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_copyfund_positions.sql` L30

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
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `copyfund_mirrors` applies `MirrorTypeID = 4` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `copyfund_positions` applies `MirrorID > 0` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | LONG | YES | Direct passthrough from upstream. Formula: `PositionID`. (Tier 2 — from `main.dwh.dim_position`) |
| 1 | CID | INT | YES | Copier customer ID. The user who allocates money to follow the leader. Trade.ValidateNumOfActiveMirrors counts mirrors per CID. (Tier 1 — Trade.Mirror) |
| 2 | MirrorID | INT | YES | Primary key. Allocated by identity on INSERT via Trade.RegisterMirror. Referenced by Trade.Position.MirrorID, History.Mirror. (Tier 1 — Trade.Mirror) |
| 3 | OpenDateID | INT | YES | yyyymmdd integer of OpenOccurred. Clustered index key -- use for efficient date-range filtering. ETL-computed: `convert(int, convert(varchar, dateadd(day, datediff(day, 0, Occurred), 0), 112))`. (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) |
| 4 | CloseDateID | INT | YES | Aggregate over upstream rows. Formula: `MAX(CloseDateID)`. (Tier 2 — literal) |
| 5 | ParentCID | INT | YES | Leader customer ID. The user whose trades are copied. Trade.GetActiveCopiersForParents filters by ParentCID. (Tier 1 — Trade.Mirror) |
| 6 | ParentUserName | STRING | YES | Leader username at mirror creation. Denormalized for display; Trade.RegisterMirror passes from caller. (Tier 1 — Trade.Mirror) |
| 7 | MirrorTypeID | INT | YES | 1=Regular, 2=CopyMe, 3=Social Index, 4=Fund (Dictionary.MirrorType). Determines mirror behavior. (Tier 1 — Trade.Mirror) |
| 8 | IsPartialCloseChild | INT | YES | Direct passthrough from upstream. Formula: `IsPartialCloseChild`. (Tier 5 — from `main.dwh.dim_position`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
main.dwh.dim_position
        │
        ▼
main.etoro_kpi_prep.v_copyfund_positions   ←── this object
        │
        ▼
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
main.etoro_kpi_prep.v_pnl_single_day
main.etoro_kpi_prep.v_trading_volume_and_amount
... (1 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=9 runtime=9 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 0/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl`
- `main.etoro_kpi_prep.v_pnl_single_day`
- `main.etoro_kpi_prep.v_trading_volume_and_amount`
- `main.etoro_kpi_prep.v_trading_volume_positionlevel`

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 9 | Tiers: 5 T1, 4 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 9/9 | Source: view_definition*
