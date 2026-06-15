---
object_fqn: main.bi_output.bi_output_vg_case_event
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_case_event
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 22
row_count: null
generated_at: '2026-05-19T15:01:46Z'
upstreams:
- main.bi_output.bi_output_customer_customer_support_case_event
- main.bi_output.bi_output_customer_customer_support_agent_user
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_case_event.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_case_event.sql
concept_count: 0
formula_count: 22
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 2
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 20
  unverified_columns: 0
---

# bi_output_vg_case_event

> View in `main.bi_output`. 0 business concept(s) in §2; 22 of 22 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_case_event` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 22 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 11 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Mon Mar 16 16:48:19 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_case_event` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output.bi_output_customer_customer_support_case_event` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_customer_customer_support_case_event.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 22 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 2 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 20 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | EventID | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.EventID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 1 | EventName | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.EventName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 2 | CreatedById | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.CreatedById`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 3 | CaseID | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.CaseID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 4 | EventType | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.EventType`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 5 | OldStatus | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.OldStatus`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 6 | NewStatus | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.NewStatus`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 7 | DoneBy | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.DoneBy`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 8 | DoneByCSDesk | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.DoneByCSDesk`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 9 | DoneByRole | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.DoneByRole`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 10 | UpdatedByAutomaticProcess | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.UpdatedByAutomaticProcess`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 11 | FromDate | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.Occurred`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 12 | ToDate | STRING | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.ToDate`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 13 | UpdateDate | TIMESTAMP | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.UpdateDate`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 14 | EventNumber | INT | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.EventNumber`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 15 | Touches | LONG | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.Touches`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 16 | IsWorkload | DOUBLE | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.IsWorkload`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 17 | Converteddate | DATE | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.Occurred`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 18 | CaseNumber | INT | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.CaseNumber`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 19 | IsReopen | INT | YES | Source: `main.bi_output.bi_output_customer_customer_support_case_event.IsReopen`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_customer_customer_support_case_event`). |
| 20 | FromDateTimeZone | TIMESTAMP_NTZ | YES | Function call computed in source. Formula: `convert_timezone('UTC',u.TimeZoneSidKeys,Occurred)`. (Tier 2 — from `main.bi_output.bi_output_customer_customer_support_case_event`) |
| 21 | IsSolved | INT | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN LAST(CASE WHEN NewStatus != 'Closed' THEN NewStatus END) over (partition by CaseID order by Occurred ) = 'Solved' THEN 1 else 0 END IsSolved`. (Tier 2 — from `main.bi_output.bi_output_customer_customer_support_case_event`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output.bi_output_customer_customer_support_case_event` | Primary | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_customer_customer_support_case_event.md` |
| `main.bi_output.bi_output_customer_customer_support_agent_user` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_customer_customer_support_agent_user.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_output.bi_output_customer_customer_support_case_event
main.bi_output.bi_output_customer_customer_support_agent_user
        │
        ▼
main.bi_output.bi_output_vg_case_event   ←── this object
        │
        ▼
main.bi_output_stg.bi_output_vg_case
main.de_output_stg.vg_cs_cases
main.de_output_stg.vg_cs_solved
... (8 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=22 runtime=22 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output.bi_output_customer_customer_support_case_event` (wiki: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_customer_customer_support_case_event.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_output_stg.bi_output_vg_case`
- `main.de_output_stg.vg_cs_cases`
- `main.de_output_stg.vg_cs_solved`
- `main.de_output_stg.vg_cs_solved_silver`
- `main.de_output_stg.vw_case_genie_gold`
- `main.de_output_stg.vw_case_genie_silver`
- `main.de_output_stg.vw_sc_genie_dlt`
- `main.de_output_stg.vw_sc_genie_original`
- `main.etoro_kpi.crm_case_v`
- `main.etoro_kpi.vg_crm_case`
- `main.etoro_kpi.vg_cs_case`

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 22 | Tiers: 0 T1, 2 T2, 0 T3, 0 T4, 0 T5, 20 TN, 0 U | Elements: 22/22 | Source: view_definition*
