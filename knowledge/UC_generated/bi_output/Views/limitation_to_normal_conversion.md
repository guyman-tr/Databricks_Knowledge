---
object_fqn: main.bi_output.limitation_to_normal_conversion
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.limitation_to_normal_conversion
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 6
row_count: null
generated_at: '2026-06-19T14:35:59Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/limitation_to_normal_conversion.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/limitation_to_normal_conversion.sql
concept_count: 3
formula_count: 6
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 6
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# limitation_to_normal_conversion

> View in `main.bi_output`. 3 business concept(s) in §2; 6 of 6 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.limitation_to_normal_conversion` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | pavlinama@etoro.com |
| **Row count** | n/a |
| **Column count** | 6 |
| **Concepts** | 3 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Fri Mar 06 09:54:26 UTC 2026 |

---

## 1. Business Meaning

`limitation_to_normal_conversion` is a view in `main.bi_output` that composes 2 JOIN-enriched dimension lookup(s), 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 6 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 6 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/limitation_to_normal_conversion.sql` L19
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.2 Dim lookup via alias `dps` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = dps.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/limitation_to_normal_conversion.sql` L22
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.3 Filter on scope `status_changes`: `IsValidCustomer = 1`
**What**: `WHERE` clause at the top of scope `status_changes` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `IsValidCustomer`
**Rules**:
- `IsValidCustomer = 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/limitation_to_normal_conversion.sql` L25

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `fsc.PlayerStatusID = dps.PlayerStatusID` | Lookup via alias `dps` |

### 3.4 Gotchas

- Scope `status_changes` applies `IsValidCustomer = 1` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Event_Month | TIMESTAMP | YES | Function call computed in source. Formula: `DATE_TRUNC('month', Limited_Timestamp)`. (Tier 2 — literal) |
| 1 | Limitation_Type | STRING | YES | Direct passthrough from upstream. Formula: `Current_Status`. (Tier 2 — computed in source) |
| 2 | Total_Conversions | LONG | NO | Aggregate over upstream rows. Formula: `COUNT(*)`. (Tier 2 — literal) |
| 3 | Avg_Hours_To_Normal | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `-- Average time AVG(TIMESTAMPDIFF(HOUR, Limited_Timestamp, First_Normal_Timestamp))`. (Tier 2 — computed in source) |
| 4 | Avg_Days_To_Normal | DOUBLE | YES | Aggregate over upstream rows. Formula: `AVG(DATEDIFF(First_Normal_Timestamp, Limited_Timestamp))`. (Tier 2 — literal) |
| 5 | Median_Hours_To_Normal | LONG | YES | Literal constant set in this object. Formula: `0.5 )`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
        │
        ▼
main.bi_output.limitation_to_normal_conversion   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=6 runtime=6 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 3 | Formulas: 6 | Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: view_definition*
