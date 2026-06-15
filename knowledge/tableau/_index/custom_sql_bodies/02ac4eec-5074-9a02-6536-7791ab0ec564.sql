select dh.*
	,DENSE_RANK() OVER (partition by dh.`Date`  ORDER BY dh.CO_Amount desc) AS RN
from(
		SELECT 
	date(bw.CreatedDate) Date,
	bw.RealCID, 
	SUM(Trigger_Cashouts_Sum__c) AS CO_Amount,
	CASE WHEN SUM(Trigger_Cashouts_Sum__c)>=50000 AND SUM(Trigger_Cashouts_Sum__c)<100000 THEN '50K TO 100K' 
		WHEN SUM(Trigger_Cashouts_Sum__c)>=100000 AND SUM(Trigger_Cashouts_Sum__c)<250000 THEN '100K to 250k'
		WHEN SUM(Trigger_Cashouts_Sum__c)>=250000 THEN '>250K' END as Category
	FROM (select a.*
              ,dc.RealCID
              ,row_number() over (partition by a.Id order by date(a.CreatedDate) desc) as rn
        from main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        join  main.crm.silver_crm_call_to_action__c a
        on a.Account__c=dc.SalesForceAccountID
        and a.Trigger_Definition__c='a480800000GWrRQAA1'
        where date(a.CreatedDate)>='2025-02-01') bw
    where bw.rn=1
	GROUP BY 
      date(bw.CreatedDate),
	  bw.RealCID
	HAVING SUM(Trigger_Cashouts_Sum__c)>=50000) dh