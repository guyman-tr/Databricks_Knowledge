select 
    sc.*, 
    case when sc.FraudulentStatusResult not in ('OK') OR 
    sc.ScReeningStatusResult not in  ('OK') 
    OR sc.kyc_data_mismatched='true' then 'Check' else  'OK'  
    end as OverallResult
 from details1 sc