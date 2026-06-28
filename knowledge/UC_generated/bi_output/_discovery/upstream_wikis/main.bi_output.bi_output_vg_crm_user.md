---
object_fqn: main.bi_output.bi_output_vg_crm_user
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_crm_user
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 21
row_count: null
generated_at: '2026-05-19T15:01:47Z'
upstreams:
- main.crm.silver_crm_user
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_crm_user.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_crm_user.sql
concept_count: 1
formula_count: 21
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 21
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_crm_user

> View in `main.bi_output`. 1 business concept(s) in §2; 21 of 21 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_crm_user` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | barar@etoro.com |
| **Row count** | n/a |
| **Column count** | 21 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jan 26 07:45:15 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_crm_user` is a view in `main.bi_output` that composes 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.crm.silver_crm_user` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`).

Of its 21 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 21 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Filter on scope `rm_choice`: `Position__c = '  '`
**What**: `WHERE` clause at the top of scope `rm_choice` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `Position__c`
**Rules**:
- `Position__c = '  '`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_crm_user.sql` L53

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

- Scope `rm_choice` applies `Position__c = '  '` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | UserId | STRING | YES | Arithmetic combination of upstream columns. Formula: `Id AS UserId, -- The original user we are resolving hierarchy for`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 1 | BO_User_ID | STRING | YES | Direct passthrough from upstream. Formula: `BO_User_ID__c`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 2 | FullName | STRING | YES | Function call computed in source. Formula: `concat(FirstName, ' ', LastName)`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 3 | Department | STRING | YES | Direct passthrough from upstream. Formula: `Department`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 4 | Title | STRING | YES | Direct passthrough from upstream. Formula: `Title`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 5 | Position | STRING | YES | Direct passthrough from upstream. Formula: `Position__c`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 6 | Desk | STRING | YES | Direct passthrough from upstream. Formula: `Desk__c`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 7 | Team | STRING | YES | Direct passthrough from upstream. Formula: `Team__c`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 8 | IsActive | BOOLEAN | YES | Direct passthrough from upstream. Formula: `IsActive`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 9 | ManagerId | STRING | YES | Direct passthrough from upstream. Formula: `ManagerId`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 10 | TimeZoneSidKeys | STRING | YES | Computed flag (CASE expression in source). Formula: `-- Override timezone for specific managers, otherwise use the user's timezone CASE WHEN ManagerId IN ('0050800000EE0zOAAT', '0050800000GyOLrAAN', '0050800000DArh6AAD') THEN 'Australia/Sy…`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 11 | Manager_BO_User_ID | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- Direct manager details (level 1) BO_User_ID__c`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 12 | Manager_FullName | STRING | YES | Function call computed in source. Formula: `concat(FirstName, ' ', LastName)`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 13 | Manager_Department | STRING | YES | Direct passthrough from upstream. Formula: `Department`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 14 | Manager_Title | STRING | YES | Direct passthrough from upstream. Formula: `Title`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 15 | Manager_Position | STRING | YES | Direct passthrough from upstream. Formula: `Position__c`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 16 | Manager_Desk | STRING | YES | Direct passthrough from upstream. Formula: `Desk__c`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 17 | Manager_Team | STRING | YES | Direct passthrough from upstream. Formula: `Team__c`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 18 | Manager_IsActive | BOOLEAN | YES | Direct passthrough from upstream. Formula: `IsActive`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 19 | RM_UserId | STRING | YES | Direct passthrough from upstream. Formula: `Id`. (Tier 2 — from `main.crm.silver_crm_user`) |
| 20 | RM_FullName | STRING | YES | Function call computed in source. Formula: `concat(FirstName, ' ', LastName)`. (Tier 2 — from `main.crm.silver_crm_user`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.crm.silver_crm_user` | Primary | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.crm.silver_crm_user
        │
        ▼
main.bi_output.bi_output_vg_crm_user   ←── this object
        │
        ▼
main.bi_output.bi_output_vg_cf_crm_contact
main.bi_output.bi_output_vg_customer_assignment
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=21 runtime=21 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.crm.silver_crm_user` (wiki: `(no wiki)`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_output.bi_output_vg_cf_crm_contact`
- `main.bi_output.bi_output_vg_customer_assignment`

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 21 | Tiers: 0 T1, 21 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 21/21 | Source: view_definition*
