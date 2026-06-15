select a.*,
CASE WHEN b.EOM_Club IN ('LowBronze','HighBronze') THEN 'Bronze' ELSE b.EOM_Club END AS EOM_Club_New,
b.Region,
b.Country,
 CASE
	   WHEN b.Seniority = 0 THEN 'ThisMonth'
	   WHEN b.Seniority = 1 THEN '1_Month'
       WHEN b.Seniority = 2 THEN '2_Months'
       WHEN b.Seniority = 3 THEN '3_Months'
       WHEN b.Seniority = 4 THEN '4_Months'
       WHEN b.Seniority = 5 THEN '5_Months'
       WHEN b.Seniority = 6 THEN '6_Months'
       WHEN b.Seniority = 7 THEN '7_Months'
       WHEN b.Seniority = 8 THEN '8_Months'
       WHEN b.Seniority = 9 THEN '9_Months'
       WHEN b.Seniority = 10 THEN '10_Months'
	   WHEN b.Seniority = 11 THEN '11_Months'
	    WHEN b.Seniority >= 12 AND b.Seniority <= 23 THEN '1-2Years'
        WHEN b.Seniority >= 24 AND b.Seniority <= 35 THEN '2-3Years'
        WHEN b.Seniority >= 36 AND b.Seniority <= 47 THEN '3-4Years'
        WHEN b.Seniority >= 48 AND b.Seniority <= 59 THEN '4-5Years'
	    WHEN b.Seniority >= 60 AND b.Seniority <= 71 THEN '6-7Years'
        WHEN b.Seniority >= 72 AND b.Seniority <= 83 THEN '7-8Years'
	    WHEN b.Seniority >= 84 AND b.Seniority <= 95 THEN '8-9Years'
		WHEN b.Seniority >= 96 THEN '9+Years'
        ELSE CAST(b.Seniority AS VARCHAR(10)) END AS Seniority_Seg2,
CASE WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) <= 24 THEN '18-24'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 25 AND 34 THEN '25-34'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 35 AND 44 THEN '35-44'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 45 AND 54 THEN '45-54'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) >= 55 THEN '55+'  
                  ELSE NULL END AS Age_Group,
                  dep.Name as DepositStatus,
                    di.Name as InstrumentName,
di.InstrumentDisplayName

from main.bi_output.bi_output_v_recurring_investment a
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc on fsc.RealCID=a.CID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr on dr.DateRangeID=fsc.DateRangeID and CAST(date_format(ActiveDate, 'yyyyMMdd') AS INT) between dr.FromDateID and dr.ToDateID and fsc.IsValidCustomer=1 and fsc.IsDepositor=TRUE
join main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata b on a.cid=b.cid and a.ActiveDate=b.ActiveDate
join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked bdcd on a.cid=bdcd.cid
left join main.general.bronze_etoro_dictionary_paymentstatus dep on a.depositstatusid=dep.PaymentStatusID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di on a.InstrumentID=di.InstrumentID

--where a.ActiveDate>=DATEADD(MONTH, -12, MAKE_DATE(YEAR(CURRENT_DATE()), MONTH(CURRENT_DATE()), 1))