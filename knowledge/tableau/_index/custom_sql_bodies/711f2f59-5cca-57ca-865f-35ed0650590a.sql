SELECT 
    month__c,
    PI_Performance_Metric__c,
    TRIM(value) AS non_paid_reason
FROM (
    SELECT 
        TRIM(value) AS value,
        p.Month__c,
        p.PI_Performance_Metric__c
    FROM main.crm.silver_crm_payment__c p
    LATERAL VIEW explode(split(p.Non_Paid_Reason__c, ';')) AS value
) AS subquery
ORDER BY 
    month__c,
    PI_Performance_Metric__c,
    non_paid_reason