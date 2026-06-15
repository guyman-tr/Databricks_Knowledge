# Column Lineage: main.de_output.vw_bronze_failed_public_api_operations_with_errors

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.vw_bronze_failed_public_api_operations_with_errors` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\de_output\_discovery\source_code\vw_bronze_failed_public_api_operations_with_errors.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\de_output\_discovery\column_lineage\vw_bronze_failed_public_api_operations_with_errors.json` (rows: 4, mismatches: 3) |
| **Primary upstream** | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation` | Primary (FROM) | ✗ `knowledge/UC_generated/de_output/<Tables|Views>/bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation.md` |

## Lineage Chain

```
main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation   ←── primary upstream
        │
        ▼
main.de_output.vw_bronze_failed_public_api_operations_with_errors   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `schema_id` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `enqueuedTime` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `eventType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `fallbackEventType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `EventPayload` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `eventData` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `eventMetadata` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `eventData_correlationId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `eventData_requestId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 10 | `eventData_gcid` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 11 | `eventData_oauthClientId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 12 | `eventData_applicationName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 13 | `eventData_authenticationChannel` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 14 | `eventData_ipAddress` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 15 | `eventData_httpMethod` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 16 | `eventData_externalPath` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 17 | `eventData_apiGroup` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 18 | `eventData_query` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 19 | `eventData_body` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 20 | `eventData_responseContent` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 21 | `eventData_httpStatusCode` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 22 | `eventData_success` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 23 | `eventData_errorCode` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 24 | `eventData_durationMs` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 25 | `eventMetadata_gcid` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 26 | `eventMetadata_correlationId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 27 | `eventMetadata_eventDataVersion` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 28 | `eventMetadata_durationInMilliseconds` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 29 | `eventMetadata_createdAt` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 30 | `event_date` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 31 | `ymd` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 32 | `eventData_userAgent` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 33 | `eventData_agentName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 34 | `eventData_routeTemplate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 35 | `eventData_routeKey` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 36 | `eventData_operationId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 37 | `api_endpoint` | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation` | `—` | `unknown` | — | REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(eventData_externalPath, '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0- |
| 38 | `error_field` | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation` | `—` | `case` | — | CASE WHEN NOT _error_code IS NULL THEN _error_code WHEN REGEXP_LIKE(_extracted_error, '^\\{"[A-Za-z_.]+":\\[') THEN REGEXP_EXTRACT(_extracte |
| 39 | `error_message` | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation` | `—` | `case` | — | CASE WHEN NOT _error_code IS NULL THEN COALESCE(eventData_responseContent:errorMessage, eventData_responseContent:Exception.Message) WHEN RE |

## Cross-check vs system.access.column_lineage

- Total target columns: **4**
- OK: **1**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `api_endpoint` | — | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation.eventdata_externalpath`, `main.de_output.bronze_event_hub_public_api_operations_evh_failedpublicapioperation.eventdata_externalpath` | ERROR |
| `error_field` | — | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation.eventdata_responsecontent`, `main.de_output.bronze_event_hub_public_api_operations_evh_failedpublicapioperation.eventdata_responsecontent` | ERROR |
| `error_message` | — | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation.eventdata_responsecontent`, `main.de_output.bronze_event_hub_public_api_operations_evh_failedpublicapioperation.eventdata_responsecontent` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**
