SELECT *
FROM  bi_output.bi_output_customer_customer_support_case sc
WHERE sc.ActionType LIKE '%Privacy%' 
   OR sc.Type LIKE '%Privacy%'
   OR sc.Sub_Type IN ('GDPR','Privacy')
   OR sc.Sub_Type_2 = 'Delete my information'
AND CAST(sc.CreatedDate AS DATE)>= '2024-01-01'