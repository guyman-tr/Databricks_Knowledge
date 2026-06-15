# Column Lineage: main.de_output.vw_bronze_public_api_operations

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.vw_bronze_public_api_operations` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\de_output\_discovery\source_code\vw_bronze_public_api_operations.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\de_output\_discovery\column_lineage\vw_bronze_public_api_operations.json` (rows: 4, mismatches: 3) |
| **Primary upstream** | `main.de_output.vw_bronze_failed_public_api_operations_with_errors` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_successfulpublicapioperation` | JOIN / referenced | ✗ `knowledge/UC_generated/de_output/<Tables|Views>/bronze_event_hub_public_api_operations_evh_bkp_successfulpublicapioperation.md` |
| `main.de_output.vw_bronze_failed_public_api_operations_with_errors` | Primary (FROM) | ✗ `knowledge/UC_generated/de_output/<Tables|Views>/vw_bronze_failed_public_api_operations_with_errors.md` |

## Lineage Chain

```
main.de_output.vw_bronze_failed_public_api_operations_with_errors   ←── primary upstream
  + main.de_output.bronze_event_hub_public_api_operations_evh_bkp_successfulpublicapioperation   (JOIN)
        │
        ▼
main.de_output.vw_bronze_public_api_operations   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `schema_id` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `enqueuedTime` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `eventType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `fallbackEventType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `eventData_correlationId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `eventData_requestId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `eventData_gcid` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `eventData_oauthClientId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `eventData_applicationName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 10 | `eventData_authenticationChannel` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 11 | `eventData_ipAddress` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 12 | `eventData_httpMethod` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 13 | `eventData_externalPath` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 14 | `eventData_apiGroup` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 15 | `eventData_body` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 16 | `eventData_responseContent` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 17 | `eventData_httpStatusCode` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 18 | `eventData_success` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 19 | `eventData_errorCode` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 20 | `eventData_durationMs` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 21 | `eventMetadata_gcid` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 22 | `eventMetadata_correlationId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 23 | `eventMetadata_eventDataVersion` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 24 | `eventMetadata_durationInMilliseconds` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 25 | `eventMetadata_createdAt` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 26 | `event_date` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 27 | `ymd` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 28 | `eventData_userAgent` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 29 | `eventData_agentName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 30 | `eventData_routeTemplate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 31 | `eventData_routeKey` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 32 | `eventData_operationId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 33 | `api_endpoint` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 34 | `error_field` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 35 | `error_message` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 36 | `is_demo` | `main.de_output.vw_bronze_failed_public_api_operations_with_errors` | `—` | `case` | — | CASE WHEN eventData_externalPath LIKE '%demo%' THEN 'demo' ELSE 'real' END AS is_demo |
| 37 | `position_id` | `main.de_output.vw_bronze_failed_public_api_operations_with_errors` | `—` | `unknown` | — | REGEXP_EXTRACT(eventData_externalPath, '/positions/([^/]+)') AS position_id |
| 38 | `trading_action` | `main.de_output.vw_bronze_failed_public_api_operations_with_errors` | `—` | `unknown` | — | REGEXP_EXTRACT(eventData_externalPath, '(market-open-orders\|market-close-orders)') AS trading_action |

## Cross-check vs system.access.column_lineage

- Total target columns: **4**
- OK: **1**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `is_demo` | — | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_successfulpublicapioperation.eventdata_externalpath`, `main.de_output.bronze_event_hub_public_api_operations_evh_successfulpublicapioperation.eventdata_externalpath`, `main.de_output.vw_bronze_failed_public_api_operations_with_errors.eventdata_externalpath` | ERROR |
| `position_id` | — | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_successfulpublicapioperation.eventdata_externalpath`, `main.de_output.bronze_event_hub_public_api_operations_evh_successfulpublicapioperation.eventdata_externalpath`, `main.de_output.vw_bronze_failed_public_api_operations_with_errors.eventdata_externalpath` | ERROR |
| `trading_action` | — | `main.de_output.bronze_event_hub_public_api_operations_evh_bkp_successfulpublicapioperation.eventdata_externalpath`, `main.de_output.bronze_event_hub_public_api_operations_evh_successfulpublicapioperation.eventdata_externalpath`, `main.de_output.vw_bronze_failed_public_api_operations_with_errors.eventdata_externalpath` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **1**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **3**
