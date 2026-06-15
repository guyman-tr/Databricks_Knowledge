-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ftd_funnel_kyc
-- Captured: 2026-05-19T15:15:11Z
-- ==========================================================================

select GCID,
min(OccurredAt) as First_KYC_Answer,
max(OccurredAt) as Last_KYC_Answer
 from main.compliance.bronze_userapidb_kyc_customeranswers
 where QuestionId not in (28,12) --- 28 = concent checkbox --- 12 = not us citizen checkbox
 group by GCID
