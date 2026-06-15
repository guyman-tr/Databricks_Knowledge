---
object_fqn: main.de_output.vw_bronze_failed_public_api_operations_with_errors
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.de_output.vw_bronze_failed_public_api_operations_with_errors
schema: de_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 39
row_count: null
generated_at: '2026-05-19T14:12:08Z'
upstreams:
- main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation
- main.de_output.bronze_event_hub_public_api_operations_evh_failedpublicapioperation
writer:
  kind: view_definition
  path: knowledge/UC_generated/de_output/_discovery/source_code/vw_bronze_failed_public_api_operations_with_errors.sql
  source_code_snapshot: knowledge/UC_generated/de_output/_discovery/source_code/vw_bronze_failed_public_api_operations_with_errors.sql
concept_count: 0
formula_count: 5
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 5
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 34
---

# vw_bronze_failed_public_api_operations_with_errors

> View in `main.de_output`. 0 business concept(s) in §2; 5 of 39 columns documented from anchored evidence; 34 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.vw_bronze_failed_public_api_operations_with_errors` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | meravhu@etoro.com |
| **Row count** | n/a |
| **Column count** | 39 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue May 19 09:00:35 UTC 2026 |

---

## 1. Business Meaning

`vw_bronze_failed_public_api_operations_with_errors` is a view in `main.de_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation` → this object. Canonical upstream documentation: `knowledge/UC_generated/de_output/<Tables|Views>/bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 39 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 5 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | schema_id | STRING | YES | Transform `unknown` for column `schema_id` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 1 | enqueuedTime | TIMESTAMP | YES | Transform `unknown` for column `enqueuedTime` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 2 | eventType | STRING | YES | Transform `unknown` for column `eventType` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 3 | fallbackEventType | STRING | YES | Transform `unknown` for column `fallbackEventType` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 4 | EventPayload | STRUCT | YES | Transform `unknown` for column `EventPayload` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 5 | eventData | STRUCT | YES | Transform `unknown` for column `eventData` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 6 | eventMetadata | STRUCT | YES | Transform `unknown` for column `eventMetadata` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 7 | eventData_correlationId | STRING | YES | Transform `unknown` for column `eventData_correlationId` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 8 | eventData_requestId | STRING | YES | Transform `unknown` for column `eventData_requestId` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 9 | eventData_gcid | LONG | YES | Transform `unknown` for column `eventData_gcid` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 10 | eventData_oauthClientId | STRING | YES | Transform `unknown` for column `eventData_oauthClientId` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 11 | eventData_applicationName | STRING | YES | Transform `unknown` for column `eventData_applicationName` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 12 | eventData_authenticationChannel | STRING | YES | Transform `unknown` for column `eventData_authenticationChannel` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 13 | eventData_ipAddress | STRING | YES | Transform `unknown` for column `eventData_ipAddress` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 14 | eventData_httpMethod | STRING | YES | Transform `unknown` for column `eventData_httpMethod` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 15 | eventData_externalPath | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- api_endpoint: base API path with dynamic IDs removed regexp_replace( regexp_replace( regexp_replace( regexp_replace( regexp_replace(eventData_externalPath`. (Tier 2 — computed in source) |
| 16 | eventData_apiGroup | STRING | YES | Transform `unknown` for column `eventData_apiGroup` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 17 | eventData_query | MAP | YES | Transform `unknown` for column `eventData_query` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 18 | eventData_body | STRING | YES | Transform `unknown` for column `eventData_body` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 19 | eventData_responseContent | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- Extract core error message COALESCE( get_json_object(eventData_responseContent, '$.errors')`. (Tier 2 — from `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation`) |
| 20 | eventData_httpStatusCode | LONG | YES | Transform `unknown` for column `eventData_httpStatusCode` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 21 | eventData_success | BOOLEAN | YES | Transform `unknown` for column `eventData_success` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 22 | eventData_errorCode | STRING | YES | Transform `unknown` for column `eventData_errorCode` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 23 | eventData_durationMs | LONG | YES | Transform `unknown` for column `eventData_durationMs` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 24 | eventMetadata_gcid | LONG | YES | Transform `unknown` for column `eventMetadata_gcid` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 25 | eventMetadata_correlationId | STRING | YES | Transform `unknown` for column `eventMetadata_correlationId` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 26 | eventMetadata_eventDataVersion | STRING | YES | Transform `unknown` for column `eventMetadata_eventDataVersion` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 27 | eventMetadata_durationInMilliseconds | LONG | YES | Transform `unknown` for column `eventMetadata_durationInMilliseconds` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 28 | eventMetadata_createdAt | STRING | YES | Transform `unknown` for column `eventMetadata_createdAt` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 29 | event_date | DATE | YES | Transform `unknown` for column `event_date` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 30 | ymd | STRING | YES | Transform `unknown` for column `ymd` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 31 | eventData_userAgent | STRING | YES | Transform `unknown` for column `eventData_userAgent` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 32 | eventData_agentName | STRING | YES | Transform `unknown` for column `eventData_agentName` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 33 | eventData_routeTemplate | STRING | YES | Transform `unknown` for column `eventData_routeTemplate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 34 | eventData_routeKey | STRING | YES | Transform `unknown` for column `eventData_routeKey` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 35 | eventData_operationId | STRING | YES | Transform `unknown` for column `eventData_operationId` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 36 | api_endpoint | STRING | YES | Arithmetic combination of upstream columns. Formula: `'/(FAKE-ORDER-ID\|healthcheck-trade-id)', '' )`. (Tier 2 — computed in source) |
| 37 | error_field | STRING | YES | Computed flag (CASE expression in source). Formula: `-- error_field: categorized error type CASE WHEN _error_code IS NOT NULL THEN _error_code WHEN _extracted_error RLIKE '^\\{"[A-Za-z_.]+":\\[' THEN regexp_extract(_extracted_error, '^\…`. (Tier 2 — computed in source) |
| 38 | error_message | STRING | YES | Arithmetic combination of upstream columns. Formula: `WHEN _error_title IS NOT NULL THEN _error_title WHEN _extracted_error RLIKE 'IsAuthenticationSucceeded' THEN 'Authentication failed - internal server error' ELSE SUBSTR(regexp_replace(_…`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation` | Primary | `knowledge/UC_generated/de_output/<Tables|Views>/bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation.md` |
| `main.de_output.bronze_event_hub_public_api_operations_evh_failedpublicapioperation` | JOIN/UNION | `knowledge/UC_generated/de_output/<Tables|Views>/bronze_event_hub_public_api_operations_evh_failedpublicapioperation.md` |

### 5.2 Pipeline ASCII Diagram

```
main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation
main.de_output.bronze_event_hub_public_api_operations_evh_failedpublicapioperation
        │
        ▼
main.de_output.vw_bronze_failed_public_api_operations_with_errors   ←── this object
        │
        ▼
main.de_output.vw_bronze_public_api_operations
main.de_output.vw_bronze_public_api_operations_last_7_days
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=39 runtime=39 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation` (wiki: `knowledge/UC_generated/de_output/<Tables|Views>/bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.de_output.vw_bronze_public_api_operations`
- `main.de_output.vw_bronze_public_api_operations_last_7_days`

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 5 | Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5, 0 TN, 34 U | Elements: 39/39 | Source: view_definition*
