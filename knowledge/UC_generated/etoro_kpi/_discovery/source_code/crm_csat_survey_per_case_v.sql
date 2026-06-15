-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.crm_csat_survey_per_case_v
-- Captured: 2026-05-19T15:05:05Z
-- ==========================================================================

WITH ranked AS (
  SELECT s.Id
    ,s.CreatedDate AS cSAT_Date -- Date the survey was taken
    ,s.Case__c AS simplesurvey__Case__c -- Case ID
    ,s.Agent_Service_NumValue__c AS simplesurvey__Survey_Score__c -- Customer satisfaction score (Agent Service score, scale 1-5)
    ,ROW_NUMBER() OVER (PARTITION BY s.Case__c ORDER BY s.CreatedDate ASC) AS rn
  FROM main.crm.silver_crm_csat_survey_entry__c s
  WHERE s.Survey_Type__c = 'CS'
    AND s.Agent_Service_NumValue__c IS NOT NULL
)
SELECT Id, cSAT_Date, simplesurvey__Case__c, simplesurvey__Survey_Score__c
FROM ranked
WHERE rn = 1
