-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.de_output.customer_segments_mail_v
-- Captured: 2026-05-19T13:46:23Z
-- ==========================================================================

SELECT
  SubscriberID,
  GCID,
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
  etr_y,
  etr_ym,
  etr_ymd
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_report
