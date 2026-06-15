---
object_fqn: main.bi_output.bi_output_vg_cf_crm_contact
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_cf_crm_contact
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 58
row_count: null
generated_at: '2026-05-19T15:01:46Z'
upstreams:
- main.bi_output_stg.
- main.bi_output.bi_output_vg_crm_user
- main.crm.silver_crm_emailmessage
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_cf_crm_contact.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_cf_crm_contact.sql
concept_count: 0
formula_count: 26
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 26
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 32
---

# bi_output_vg_cf_crm_contact

> View in `main.bi_output`. 0 business concept(s) in §2; 26 of 58 columns documented from anchored evidence; 32 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_cf_crm_contact` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | barar@etoro.com |
| **Row count** | n/a |
| **Column count** | 58 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jan 19 12:20:11 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_cf_crm_contact` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output_stg.` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 58 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 26 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

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
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

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
| 1 | Id_Source | STRING | YES | Transform `unknown` for column `Id_Source` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 1 | Id | STRING | YES | Transform `unknown` for column `Id` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 2 | CreatedDate | DATE | YES | Arithmetic combination of upstream columns. Formula: `-- Derived date key CAST(date_format(tfcrm.CreatedDate, 'yyyyMMdd') AS INT)`. (Tier 2 — computed in source) |
| 3 | CreatedDateTime | TIMESTAMP | YES | Transform `unknown` for column `CreatedDateTime` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 4 | Task_Id | STRING | YES | Transform `unknown` for column `Task_Id` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 5 | CustEng_Id | STRING | YES | Transform `unknown` for column `CustEng_Id` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 6 | Email_Id | STRING | YES | Transform `unknown` for column `Email_Id` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 7 | Case_Id | STRING | YES | Transform `unknown` for column `Case_Id` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 8 | Case_Number | STRING | YES | Transform `unknown` for column `Case_Number` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 9 | CID | STRING | YES | Transform `unknown` for column `CID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 10 | Task_CreatedDate | TIMESTAMP | YES | Transform `unknown` for column `Task_CreatedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 11 | Task_LastModifiedDate | TIMESTAMP | YES | Transform `unknown` for column `Task_LastModifiedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 12 | CustEng_CreatedDate | TIMESTAMP | YES | Transform `unknown` for column `CustEng_CreatedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 13 | CustEng_LastModifiedDate | TIMESTAMP | YES | Transform `unknown` for column `CustEng_LastModifiedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 14 | Email_CreatedDate | TIMESTAMP | YES | Transform `unknown` for column `Email_CreatedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 15 | Email_LastModifiedDate | TIMESTAMP | YES | Transform `unknown` for column `Email_LastModifiedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 16 | Task_Subject | STRING | YES | Transform `unknown` for column `Task_Subject` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 17 | Task_Subtype | STRING | YES | Transform `unknown` for column `Task_Subtype` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 18 | Task_Status | STRING | YES | Transform `unknown` for column `Task_Status` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 19 | CustEng_CallSummary | STRING | YES | Transform `unknown` for column `CustEng_CallSummary` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 20 | CustEng_ZoomCall | BOOLEAN | YES | Transform `unknown` for column `CustEng_ZoomCall` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 21 | OwnerId | STRING | YES | Transform `unknown` for column `OwnerId` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 22 | Owner | STRING | YES | Transform `unknown` for column `Owner` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 23 | AccountManagerId | STRING | YES | Transform `unknown` for column `AccountManagerId` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 24 | AccountManager | STRING | YES | Transform `unknown` for column `AccountManager` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 25 | CallDurationInSeconds | DECIMAL | YES | Transform `unknown` for column `CallDurationInSeconds` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 26 | Vonage_CallDuration | DECIMAL | YES | Transform `unknown` for column `Vonage_CallDuration` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 27 | Task_CallDuration | INT | YES | Transform `unknown` for column `Task_CallDuration` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 28 | CustEng_CallDuration | DECIMAL | YES | Transform `unknown` for column `CustEng_CallDuration` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 29 | ContactDirection | STRING | YES | Transform `unknown` for column `ContactDirection` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 30 | ContactType | STRING | YES | Transform `unknown` for column `ContactType` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 31 | ContactType_Group | STRING | YES | Transform `unknown` for column `ContactType_Group` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 32 | CF_Terminology | STRING | YES | Transform `unknown` for column `CF_Terminology` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 33 | CreatedDateId | INT | YES | Arithmetic combination of upstream columns. Formula: `-- Derived date key CAST(date_format(tfcrm.CreatedDate, 'yyyyMMdd') AS INT)`. (Tier 2 — computed in source) |
| 34 | AM_BO_User_ID | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- AM enrichment BO_User_ID`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 35 | AM_FullName | STRING | YES | Direct passthrough from upstream. Formula: `FullName`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 36 | AM_Department | STRING | YES | Direct passthrough from upstream. Formula: `Department`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 37 | AM_Title | STRING | YES | Direct passthrough from upstream. Formula: `Title`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 38 | AM_Position | STRING | YES | Direct passthrough from upstream. Formula: `Position`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 39 | AM_Desk | STRING | YES | Direct passthrough from upstream. Formula: `Desk`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 40 | AM_Team | STRING | YES | Direct passthrough from upstream. Formula: `Team`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 41 | AM_IsActive | BOOLEAN | YES | Direct passthrough from upstream. Formula: `IsActive`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 42 | AM_TimeZoneSidKeys | STRING | YES | Direct passthrough from upstream. Formula: `TimeZoneSidKeys`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 43 | Manager_FullName | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- AM manager hierarchy Manager_FullName`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 44 | Manager_Department | STRING | YES | Direct passthrough from upstream. Formula: `Manager_Department`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 45 | Manager_Title | STRING | YES | Direct passthrough from upstream. Formula: `Manager_Title`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 46 | Manager_Position | STRING | YES | Direct passthrough from upstream. Formula: `Manager_Position`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 47 | Manager_Desk | STRING | YES | Direct passthrough from upstream. Formula: `Manager_Desk`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 48 | Manager_Team | STRING | YES | Direct passthrough from upstream. Formula: `Manager_Team`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 49 | Owner_BO_User_ID | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- Owner enrichment BO_User_ID`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 50 | Owner_FullName | STRING | YES | Direct passthrough from upstream. Formula: `FullName`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 51 | Owner_Department | STRING | YES | Direct passthrough from upstream. Formula: `Department`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 52 | Owner_Title | STRING | YES | Direct passthrough from upstream. Formula: `Title`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 53 | Owner_Position | STRING | YES | Direct passthrough from upstream. Formula: `Position`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 54 | Owner_Desk | STRING | YES | Direct passthrough from upstream. Formula: `Desk`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 55 | Owner_Team | STRING | YES | Direct passthrough from upstream. Formula: `Team`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 56 | Owner_IsActive | BOOLEAN | YES | Direct passthrough from upstream. Formula: `IsActive`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |
| 57 | Owner_TimeZoneSidKeys | STRING | YES | Direct passthrough from upstream. Formula: `TimeZoneSidKeys`. (Tier 2 — from `main.bi_output.bi_output_vg_crm_user`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output_stg.` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.bi_output.bi_output_vg_crm_user` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_crm_user.md` |
| `main.crm.silver_crm_emailmessage` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_output_stg.
main.bi_output.bi_output_vg_crm_user
main.crm.silver_crm_emailmessage
... (1 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_cf_crm_contact   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=58 runtime=58 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output_stg.` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 2/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 26 | Tiers: 0 T1, 26 T2, 0 T3, 0 T4, 0 T5, 0 TN, 32 U | Elements: 58/58 | Source: view_definition*
