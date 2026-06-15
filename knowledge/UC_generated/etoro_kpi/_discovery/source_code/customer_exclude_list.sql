-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.customer_exclude_list
-- Captured: 2026-05-19T15:05:54Z
-- ==========================================================================

select
  cc.CID,
  cc.GCID,
  case
      when lower(cc.Comments) LIKE '%abuse%' and PlayerStatusID = 2 then 'Abuser'
      when PlayerStatusReasonID = 4 then 'High risk'
      when PlayerLevelID = 4 then 'Internal'
      when lower(UserName) like 'autouser%' then 'Automation'
  end as excludeReason,
  cc.Registered as RegisterationDate
FROM
  main.general.bronze_etoro_customer_customer_masked as cc
WHERE
  (
    (lower(cc.Comments) LIKE '%abuse%' and PlayerStatusID = 2)
    or PlayerStatusReasonID = 4
    or PlayerLevelID = 4
    or lower(UserName) like 'autouser%'
  )
  AND cc.Registered >= '2025-01-01'
