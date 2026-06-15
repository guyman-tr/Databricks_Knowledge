---
object_fqn: main.bi_output.bi_output_vg_customer_assignment
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_customer_assignment
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 11
row_count: null
generated_at: '2026-05-19T15:01:48Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.crm.gold_crm_accountsmanager
- main.bi_output.bi_output_vg_crm_user
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_assignment.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_assignment.sql
concept_count: 2
formula_count: 11
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 11
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_customer_assignment

> View in `main.bi_output`. 2 business concept(s) in §2; 11 of 11 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_customer_assignment` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | barar@etoro.com |
| **Row count** | n/a |
| **Column count** | 11 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jan 19 12:21:38 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_customer_assignment` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 11 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 11 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsCurrentAssignment` computed flag
**What**: Computed flag on `IsCurrentAssignment` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCurrentAssignment`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_assignment.sql` bi_output.sql L18-L21
**Source(s)**: `main.crm.gold_crm_accountsmanager`

### 2.2 Dim lookup via alias `dcu` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `am.AccountId = dcu.SalesForceAccountID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_assignment.sql` L23
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
| Filter on discriminator flags | Use `IsCurrentAssignment = 1`-style filters on the precomputed flag columns (`IsCurrentAssignment`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `am.AccountId = dcu.SalesForceAccountID` | Lookup via alias `dcu` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 1 | SalesForceAccountID | STRING | YES | Direct passthrough from upstream. Formula: `AccountId`. (Tier 2 — from `main.crm.gold_crm_accountsmanager`) |
| 2 | AM_CID | STRING | YES | Direct passthrough from upstream. Formula: `BO_User_ID`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 3 | AM_ID | STRING | YES | Direct passthrough from upstream. Formula: `OwnerId`. (Tier 2 — from `main.crm.gold_crm_accountsmanager`) |
| 4 | AM_FullName | STRING | YES | Direct passthrough from upstream. Formula: `FullName`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 5 | AM_Department | STRING | YES | Direct passthrough from upstream. Formula: `Department`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 6 | AM_Position | STRING | YES | Direct passthrough from upstream. Formula: `Position`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 7 | AssignmentCreatedDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `CreatedDate`. (Tier 2 — from `main.crm.gold_crm_accountsmanager`) |
| 8 | AssignmentStartAt | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `__START_AT`. (Tier 2 — from `main.crm.gold_crm_accountsmanager`) |
| 9 | AssignmentEndAt | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `__END_AT`. (Tier 2 — from `main.crm.gold_crm_accountsmanager`) |
| 10 | IsCurrentAssignment | INT | NO | `IsCurrentAssignment` computed flag. Formula: `CASE WHEN __END_AT IS NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.crm.gold_crm_accountsmanager`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.crm.gold_crm_accountsmanager` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_output.bi_output_vg_crm_user` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_crm_user.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.crm.gold_crm_accountsmanager
main.bi_output.bi_output_vg_crm_user
        │
        ▼
main.bi_output.bi_output_vg_customer_assignment   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=11 runtime=11 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 1/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 11 | Tiers: 0 T1, 11 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 11/11 | Source: view_definition*
