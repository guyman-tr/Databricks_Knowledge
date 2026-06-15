SELECT YearMonth
,Date
,COUNT(DISTINCT RealCID) MAU
FROM
 (SELECT  dc.RealCID
 ,LAST_DAY(l.`Timestamp`) Date  
 ,YEAR(l.`Timestamp`) * 100 + Month(l.`Timestamp`) AS YearMonth
  from main.mixpanel.login_events l
  JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
   ON  l.GCID=dc.GCID
   where l.DateID >= 20220101
	 AND l.DateID <=CAST(DATE_FORMAT(CURRENT_DATE - 1, 'yyyyMMdd') AS INT)
   AND dc.IsValidCustomer=1
   group by dc.RealCID
   ,LAST_DAY(l.`Timestamp`)
   ,YEAR(l.`Timestamp`) * 100 + Month(l.`Timestamp`)
union  
    select fca.RealCID
	,LAST_DAY(fca.Occurred) Date  
    ,YEAR(fca.Occurred) * 100 + Month(fca.Occurred) AS YearMonth
    from main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
	ON fca.RealCID=dc.RealCID
     where fca.DateID >=20220101 
     and DateID <=CAST(DATE_FORMAT(CURRENT_DATE - 1, 'yyyyMMdd') AS INT)
     and ActionTypeID = 14 
     AND dc.IsValidCustomer=1
group by fca.RealCID
	 ,LAST_DAY(fca.Occurred)   
 ,YEAR(fca.Occurred) * 100 + Month(fca.Occurred) 

)a
group by  YearMonth,Date