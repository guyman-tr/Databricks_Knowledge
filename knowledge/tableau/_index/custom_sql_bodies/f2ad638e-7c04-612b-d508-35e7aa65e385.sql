SELECT
    p.*,
    DATE_TRUNC('MONTH', p.CreatedDate) - INTERVAL '1 MONTH' AS previous_month_first_day
FROM main.crm.silver_crm_payment__c p