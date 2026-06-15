SELECT *
FROM crm.silver_crm_ai_session__c
WHERE createddate>= current_date - interval '12 months'