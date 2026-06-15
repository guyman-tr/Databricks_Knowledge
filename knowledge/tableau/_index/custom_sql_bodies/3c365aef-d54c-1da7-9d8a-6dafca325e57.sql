SELECT
 Action
,Message
,GCID
,RealCID
,ActionDate
,Journey_Name
from (
SELECT DISTINCT a.Action
,a.Message
,a.GCID
,b.RealCID
,Journey_Name
,TO_DATE(TO_TIMESTAMP(a.Message, 'M/d/yyyy h:mm:ss a') ,'MM/dd/yyyy')   AS ActionDate
,ROW_NUMBER() OVER (PARTITION BY a.GCID ORDER BY a.Message DESC) rn 
from main.sfmc.silver_sfmc_accountjourneylogtracking a 
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked b
on a.GCID=b.GCID
where Journey_Name like ('CapitalGuarantee_%')
and IsValidCustomer=1 
--and TO_DATE(TO_TIMESTAMP(a.Message, 'M/d/yyyy h:mm:ss a') ,'MM/dd/yyyy')<='20250304'
)a
where a.rn=1