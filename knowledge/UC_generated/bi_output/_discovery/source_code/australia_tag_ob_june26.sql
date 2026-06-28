-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.australia_tag_ob_june26
-- Captured: 2026-06-19T14:32:20Z
-- ==========================================================================

SELECT
  `$distinct_id`,
  `$name`,
  `$email`,
  `$last_seen`,
  `$country_code`,
  `$region`,
  `$city`,
  `$GCID`
FROM read_files(
  'abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/Marketing/Bar/Australia_Tag_OB_June26.csv',
  format => 'csv',
  header => true
)
