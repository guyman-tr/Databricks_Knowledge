-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.de_output.vw_bronze_failed_public_api_operations_with_errors
-- Captured: 2026-05-19T14:11:37Z
-- ==========================================================================

WITH base AS (
  SELECT 
    *,
    -- Extract core error message
    COALESCE(
      get_json_object(eventData_responseContent, '$.errors'),
      get_json_object(eventData_responseContent, '$.errorMessage'),
      get_json_object(eventData_responseContent, '$.Exception.Message'),
      get_json_object(eventData_responseContent, '$.Message'),
      eventData_responseContent
    ) AS _extracted_error,
    -- Extract error code if available
    COALESCE(
      get_json_object(eventData_responseContent, '$.errorCode'),
      get_json_object(eventData_responseContent, '$.Exception.Reason')
    ) AS _error_code,
    -- Extract title field (for RFC-style errors)
    get_json_object(eventData_responseContent, '$.title') AS _error_title
  FROM main.de_output.bronze_event_hub_public_api_operations_evh_bkp_failedpublicapioperation
  
)
SELECT 
  * EXCEPT(_extracted_error, _error_code, _error_title),

  -- api_endpoint: base API path with dynamic IDs removed
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

  -- error_field: categorized error type
  CASE
    WHEN _error_code IS NOT NULL THEN _error_code
    WHEN _extracted_error RLIKE '^\\{"[A-Za-z_.]+":\\[' 
      THEN regexp_extract(_extracted_error, '^\\{"([A-Za-z_.]+)"', 1)
    WHEN _extracted_error RLIKE '^\\{"":\\[' 
      THEN 'DeserializationError'
    WHEN _extracted_error RLIKE '-- [A-Za-z]+:' 
      THEN regexp_extract(_extracted_error, '-- ([A-Za-z]+):', 1)
    WHEN _extracted_error RLIKE '-- :' 
      THEN 'ReferenceIDDuplicate'
    WHEN _error_title IS NOT NULL THEN _error_title
    WHEN _extracted_error RLIKE 'IsAuthenticationSucceeded' 
      THEN 'AuthenticationFailure'
    WHEN _extracted_error RLIKE '^[a-z]' 
      THEN regexp_extract(_extracted_error, '^([a-z ]+)', 1)
    ELSE 'Unmapped'
  END AS error_field,

  -- error_message: normalized human-readable error description
  CASE
    WHEN _error_code IS NOT NULL THEN
      COALESCE(
        get_json_object(eventData_responseContent, '$.errorMessage'),
        get_json_object(eventData_responseContent, '$.Exception.Message')
      )
    WHEN _extracted_error RLIKE '^\\{"[A-Za-z_.]+":\\[' 
      THEN regexp_replace(
        regexp_extract(_extracted_error, '\\["([^"]+)"', 1),
        '[0-9a-f]{10,}|\\d+', '<N>'
      )
    WHEN _extracted_error RLIKE '^\\{"":\\[' 
      THEN regexp_replace(
        regexp_extract(_extracted_error, '\\["([^"]+)"', 1),
        '[0-9a-f]{10,}|\\d+', '<N>'
      )
    WHEN _extracted_error RLIKE '-- [A-Za-z]+:' 
      THEN regexp_replace(
        regexp_extract(_extracted_error, '-- [A-Za-z]+: (.+?)(?:\\.|Severity)', 1),
        '[0-9a-f]{10,}|\\d+', '<N>'
      )
    WHEN _extracted_error RLIKE '-- :' 
      THEN regexp_replace(
        regexp_extract(_extracted_error, '-- : (.+?)(?:Severity)', 1),
        '[0-9a-f\\-]{10,}|\\d+', '<N>'
      )
    WHEN _error_title IS NOT NULL THEN _error_title
    WHEN _extracted_error RLIKE 'IsAuthenticationSucceeded' 
      THEN 'Authentication failed - internal server error'
    ELSE SUBSTR(regexp_replace(_extracted_error, '[0-9a-f]{10,}|\\d+', '<N>'), 1, 150)
  END AS error_message

FROM base
