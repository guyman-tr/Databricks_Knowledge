select b.Action,b.Message,b.GCID,b.UserName,b.RealCID,b.Manager,b.Club,b.Name
,vl.Credit  Available_Balance
,vl1.Credit as Credit_20240430	
,COALESCE(SUM(CASE WHEN fca1.ActionTypeID IN (7) THEN fca1.Amount END),0) AS Deposit
,COALESCE(SUM(CASE WHEN fca1.ActionTypeID IN (8) THEN (-1*fca1.Amount) END),0) AS Cashout
,COALESCE(CopyAUC,0) Portfolio_CopyAUC
from (
select * 
,ROW_NUMBER() OVER (PARTITION BY a.GCID ORDER BY a.Message DESC) rn 
from (
SELECT DISTINCT a.*
,b.UserName
,b.RealCID
,CONCAT(dm1.FirstName, ' ', dm1.LastName) AS Manager	
,dpl.Name AS Club
,dc.Name
from main.sfmc.silver_sfmc_accountjourneylogtracking a 
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked b
on a.GCID=b.GCID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm1
ON b.AccountManagerID = dm1.ManagerID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
ON b.PlayerLevelID = dpl.PlayerLevelID
join  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
on dc.CountryID=b.CountryID
where Journey_Name='6451190453_CG24_TCsFormSubmissions'
and IsValidCustomer=1
--and a.etr_ymd>'2024-05-19'
)a
 ) b
 left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
on vl.CID=b.RealCID and vl.DateID= date_format(DATEADD(day, -1, GETDATE()), 'yyyyMMdd')
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl1
on vl1.CID=b.RealCID and vl1.DateID=20240430
left join  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca1 
on fca1.RealCID=b.RealCID and fca1.ActionTypeID IN (7,8)
AND fca1.DateID>=20240501
AND fca1.DateID<=20240708
LEFT JOIN 
(select gc.CID 
	   ,SUM(COALESCE(gc.Cash, 0) + COALESCE(gc.Investment, 0) + COALESCE(gc.PnL, 0) + COALESCE(gc.DetachedPosInvestment, 0) + COALESCE(gc.Dit_PnL, 0)) AS CopyAUC
from main.general.bronze_etorogeneral_history_gurucopiers gc
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked b
on gc.ParentCID=b.RealCID and AccountTypeID = 9
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked b2
on gc.CID=b2.RealCID
where  gc.Timestamp = cast(GETDATE() as date)
and b2.IsValidCustomer=1
group by gc.CID
) gc
on gc.CID=b.RealCID
where rn=1
group by b.Action,b.Message,b.GCID,UserName,b.RealCID,b.Manager,b.Club,b.Name
,vl.Credit ,vl1.Credit ,CopyAUC