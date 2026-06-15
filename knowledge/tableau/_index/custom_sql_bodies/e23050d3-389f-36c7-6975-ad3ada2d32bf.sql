select * 
from (
select * 
,ROW_NUMBER() OVER (PARTITION BY a.GCID ORDER BY a.Message DESC) rn 
from (
SELECT DISTINCT a.*,b.UserName,b.RealCID
from main.sfmc.silver_sfmc_accountjourneylogtracking a 
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked b
on a.GCID=b.GCID
where Journey_Name='6451190453_CG24_TCsFormSubmissions'
and IsValidCustomer=1
and a.etr_ymd>'2024-05-15'
)a
 ) b
where rn=1