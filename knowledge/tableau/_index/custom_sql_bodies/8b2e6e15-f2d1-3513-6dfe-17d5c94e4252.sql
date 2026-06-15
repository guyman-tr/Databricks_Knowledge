SELECT *
FROM crm.silver_crm_messagingsession
WHERE createddate>= current_date - interval '12 months'