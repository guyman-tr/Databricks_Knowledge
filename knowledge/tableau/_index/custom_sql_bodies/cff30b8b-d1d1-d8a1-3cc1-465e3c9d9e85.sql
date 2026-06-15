select dc.GCID
    ,dc.RealCID
    ,CONCAT(ag.FirstName, ' ', ag.LastName) AM
      ,ag.Team
    ,ag.Position
    ,etr_ymd
    ,sum(ubl.Amount)
    ,50000 - sum(ubl.Amount) as Amount_to_Upgrade
from bi_db.bronze_clubservice_clubs_userbalances ubl
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on dc.GCID=ubl.GCID
join  bi_output.BI_OUTPUT_Customer_Customer_Support_Agent_User ag
on ag.AccountManagerID=dc.AccountManagerID
where etr_ymd=CAST(DATEADD(day, -1, GETDATE()) as date)
and dc.PlayerLevelID=2
group by all