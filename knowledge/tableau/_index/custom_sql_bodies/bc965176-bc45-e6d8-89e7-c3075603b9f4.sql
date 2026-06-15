select b.cid,case when a.Education_Status__c is not null then a.Education_Status__c 
else c.newvalue end as Education_Status__c
from crm.silver_crm_baseline_accounteducationstatus a
join  main.crm.gold_crm_idmaptopology b
on a.id = b.SF_ID
left join main.crm.silver_crm_accounthistory c
on a.id = c.AccountId
and c.AccountId = b.SF_ID
AND c.field = 'Education_Status__c'
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cd
on cd.realCID =b.cid
where  cd.gurustatusid> 0