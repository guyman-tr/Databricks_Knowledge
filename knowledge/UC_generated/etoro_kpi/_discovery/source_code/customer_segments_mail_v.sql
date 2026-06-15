-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.customer_segments_mail_v
-- Captured: 2026-05-19T15:06:15Z
-- ==========================================================================

SELECT
  SubscriberID,
  sfmc.GCID,
  SentTime,
  SendDateID,
  Subject,
  SendID,
  EmailName,
  CampaignGroup,
  CampaignSubGroup,
  CampaignName,
  CampaignNumber,
  CountOpen,
  UniqueOpen,
  CountClicks,
  UniqueClicks,
  CountBounce,
  Delivered,
  OpenDate,
  ClickDate,
  CountSend,
  LSD,
  le.last_login,
  etr_y,
  etr_ym,
  etr_ymd
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_report sfmc
LEFT JOIN 
  (
    Select GCID , MAX(timestamp) as last_login from main.mixpanel.login_events
    Where EventName like 'Login - Success' and DateID > 20250101 and etr_ymd > '2025-01-01'
    Group by GCID
  ) le on(sfmc.GCID = le.GCID)
