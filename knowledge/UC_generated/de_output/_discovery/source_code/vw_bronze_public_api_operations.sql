-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.de_output.vw_bronze_public_api_operations
-- Captured: 2026-05-19T14:11:44Z
-- ==========================================================================

with base as (
SELECT distinct * EXCEPT(EventPayload, eventData,eventMetadata,eventData_query)
FROM main.de_output.vw_bronze_failed_public_api_operations_with_errors

UNION ALL

SELECT 
  distinct * EXCEPT (EventPayload, eventData,eventMetadata,eventData_query),
  -- api_endpoint: same logic as the failed view
  regexp_replace(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(eventData_externalPath,
            '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', ''),
          '/[0-9a-f]{10,}', ''),
        '/\\d+', ''),
      '/sim_[0-9]+', ''),
    '/(FAKE-ORDER-ID|healthcheck-trade-id)', ''
  ) AS api_endpoint,
  NULL AS error_field,
  NULL AS error_message
FROM main.de_output.bronze_event_hub_public_api_operations_evh_bkp_successfulpublicapioperation
)
select  * 
,   CASE WHEN eventData_externalPath LIKE '%demo%' THEN 'demo' ELSE 'real' END AS is_demo
,   regexp_extract(eventData_externalPath, '/positions/([^/]+)', 1) AS position_id
,   regexp_extract(eventData_externalPath, '(market-open-orders|market-close-orders)', 1) AS trading_action


from base
