SELECT  * 
FROM main.bi_output.bi_output_customer_customer_support_agent_user eboccsau
WHERE eboccsau.ToDate = '9999-12-31T00:00:00.000Z'
AND IsActive = 'true'