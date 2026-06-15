-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.crm_quality_assessment_per_case_v
-- Captured: 2026-05-19T15:05:33Z
-- ==========================================================================

WITH ranked AS (
  SELECT Case__c -- CaseID
    ,Survey__c -- Id of the survey
    ,Agent_Under_Assessment__c -- CS agent that is under assessment
    ,TRY_CAST(Quality_Score__c AS DOUBLE) AS Quality_Score__c -- Grade the agent received regarding his service to the customer based on understanding, patience and good communication
    ,Compliance_a__c -- grade that measures how strictly an agent adheres to company policies, industry regulations, and legal standards during customer interactions
    ,Type_of_Communication__c -- Type of case the agent handled
    ,Team__c -- Team of assessing agent
    ,CreatedDate -- Date the survey was taken
    ,ROW_NUMBER() OVER (PARTITION BY Case__c ORDER BY CreatedDate DESC) AS rn
  FROM main.crm.silver_crm_surveytaker__c
  WHERE Case__c IS NOT NULL
)
SELECT Case__c, Survey__c, Agent_Under_Assessment__c, Quality_Score__c, Compliance_a__c, Type_of_Communication__c, Team__c, CreatedDate
FROM ranked
WHERE rn = 1
