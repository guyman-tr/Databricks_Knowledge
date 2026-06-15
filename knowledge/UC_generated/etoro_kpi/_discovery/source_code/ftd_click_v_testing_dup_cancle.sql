-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ftd_click_v_testing_dup_cancle
-- Captured: 2026-05-19T15:15:04Z
-- ==========================================================================

WITH pivoted AS (
  SELECT *
  FROM (
    SELECT a.gcid, coalesce(a.realcid,b.realcid) as realcid, a.step_key, a.last_event_time
    FROM main.etoro_kpi.de_output_ftd_click  a
    left  join (select distinct gcid,realcid from main.etoro_kpi.de_output_ftd_click where realcid is not null  ) b on a.gcid=b.gcid
  )
  PIVOT (
    MAX(last_event_time) FOR step_key IN (
      'initial_deposit_click' AS initial_deposit_click,
      'ftd_wizard_intro' AS ftd_wizard_intro,
      'ftd_wizard_amount' AS ftd_wizard_amount,
      'ftd_wizard_mean_of_payment' AS ftd_wizard_mean_of_payment,
      'final_deposit_click' AS final_deposit_click
    )
  )
),
logic_base AS (
  SELECT 
    *,
    GREATEST(
      initial_deposit_click, 
      ftd_wizard_intro, 
      ftd_wizard_amount, 
      ftd_wizard_mean_of_payment
    ) AS max_time
  FROM pivoted
)
SELECT
  gcid,
  realcid,
  initial_deposit_click,
  ftd_wizard_intro,
  ftd_wizard_amount,
  ftd_wizard_mean_of_payment,
  final_deposit_click,
  max_time AS initial_deposit_clicks_combined,
  CASE
    WHEN max_time IS NULL THEN NULL
    WHEN max_time = initial_deposit_click       THEN 'initial_deposit_click'
    WHEN max_time = ftd_wizard_intro           THEN 'ftd_wizard_intro'
    WHEN max_time = ftd_wizard_amount          THEN 'ftd_wizard_amount'
    WHEN max_time = ftd_wizard_mean_of_payment THEN 'ftd_wizard_mean_of_payment'
  END AS initial_deposit_click_type
FROM logic_base
