SELECT  DISTINCT 
	bdsajlt.Message
   ,bdsajlt.GCID
   ,dc.RealCID
   ,bdsajlt.TimeStamp 
   ,bdcd.NewMarketingRegion  
   ,dl.Name as Language
   ,bdcd.Country
	 ,ad.Amount
   ,dl.Name
   ,CASE
		WHEN bdsajlt.Message LIKE '%Test%' THEN 'Test'
		ELSE 'Control'
	  END AS Group
   ,CASE
		WHEN bdsajlt.Message LIKE '%FullyCashout%' THEN 'FullyCashout'
		WHEN bdsajlt.Message LIKE '%SignificantCashout%' THEN 'SignificantCashout'
		WHEN bdsajlt.Message LIKE '%CashOutInProcess%' THEN 'CashOutInProcess'
	END AS SubGroup 
	,CASE WHEN coalesce(ad.CID,0) <> 0 THEN 1 ELSE 0 END AS IsAirdrop
	,ad.PositionID
	,ad.ExecutionOccurred
	,bdcd.FirstNewFundedDate
	,CASE WHEN dp.CID is not null then 1 else 0 end as AO30Days
	,CASE WHEN fsc.RealCID is not null then 1 else 0 end as Deposit30Days
	,dp1.ACC_Revenue_Total Revenue_Total
	,ltv.Revenue8Y_LTV_New
	,ltv.Revenue8Y_LTV_NoExtreme_New



	
FROM main.sfmc.silver_sfmc_accountjourneylogtracking bdsajlt
JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
	ON bdsajlt.GCID = dc.GCID
JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked bdcd 
	ON bdsajlt.GCID = bdcd.GCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
 dl ON dc.LanguageID = dl.LanguageID
LEFT JOIN main.bi_db.bronze_etoro_trade_adminpositionlog ad
	ON ad.CID=dc.RealCID AND CompensationReasonID = 96 AND coalesce(ad.PositionID,0)<>0  
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fsc
    ON bdsajlt.GCID = fsc.GCID AND ActionTypeID=7 AND fsc.Occurred BETWEEN coalesce(ad.ExecutionOccurred,bdsajlt.TimeStamp) AND timestampadd(day, 30, coalesce(ad.ExecutionOccurred,bdsajlt.TimeStamp))
LEFT JOIN  main.dwh.dim_position dp  ON 	dp.CID=dc.RealCID
            AND coalesce(dp.IsAirDrop,0)=0	AND coalesce(dp.IsPartialCloseChild,0)=0
		    AND dp.OpenOccurred BETWEEN coalesce(ad.ExecutionOccurred,bdsajlt.TimeStamp) AND timestampadd(day, 30, coalesce(ad.ExecutionOccurred,bdsajlt.TimeStamp))
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata dp1
	ON dp1.CID=dc.RealCID and dp1.DateID = coalesce(date_format(ad.ExecutionOccurred,'yyyyMMdd') ,date_format(bdsajlt.TimeStamp,'yyyyMMdd')) 
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ltv 
	ON ltv.CID=dc.RealCID
WHERE bdsajlt.Journey_Name = '0602_Churn'
AND bdsajlt.etr_ymd >= '2024-04-19'
AND bdsajlt.Message IN
('JourneyTestGroupEntry_FullyCashout',
'JourneyTestGroupEntry_SignificantCashout',
'JourneyTestGroupEntry_CashOutInProcess',
'JourneyControlGroupEntry_FullyCashout',
'JourneyControlGroupEntry_SignificantCashout',
'JourneyControlGroupEntry_CashOutInProcess')