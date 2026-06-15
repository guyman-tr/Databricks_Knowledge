SELECT 
     bdsr.etr_ym as YearMonth
    ,bdsr.GCID
    ,CASE WHEN bdsr.LSD LIKE '%Churn%' THEN 'Churn' 
          WHEN bdsr.LSD LIKE '%No Activity%' THEN 'No Activity'
	  WHEN bdsr.LSD LIKE '%Holder%' THEN 'Holder'
	  WHEN bdsr.LSD LIKE '%Win Back%' THEN 'Win Back'
	  WHEN bdsr.LSD LIKE '%Active Open 30-90 %' THEN 'Active Open 30-90'
	  WHEN bdsr.LSD IN ('New Funded','New Depositor Only') THEN 'New FTD'
          WHEN (bdsr.LSD= 'Dump Lead') AND (date_format(fd.VerificationLevel3Date,'yyyy-MM-dd')<=date_format(bdsr.etr_ymd,'yyyy-MM-dd')) THEN 'Dump Lead V3'
	  WHEN (bdsr.LSD= 'Dump Lead') AND (date_format(fd.VerificationLevel2Date,'yyyy-MM-dd')<=date_format(bdsr.etr_ymd,'yyyy-MM-dd')) THEN 'Dump Lead V2'
	  WHEN (bdsr.LSD= 'Dump Lead') AND (date_format(fd.VerificationLevel1Date,'yyyy-MM-dd')<=date_format(bdsr.etr_ymd,'yyyy-MM-dd')) THEN 'Dump Lead V1'
	  WHEN (bdsr.LSD= 'Dump Lead') AND (fd.VerificationLevel1Date IS NULL OR (date_format(fd.VerificationLevel1Date,'yyyy-MM-dd')>date_format(bdsr.etr_ymd,'yyyy-MM-dd')))  THEN 'Dump Lead V0'
	
	   ELSE bdsr.LSD END AS LifeStage
    ,bdcmpfd.EOD_Club  AS  ClubTier
    ,fd.NewMarketingRegion AS Region
    ,bdsr.EmailName
    ,bdsr.CountBounce
    ,case when bdsr.Delivered<0 then 0 else bdsr.Delivered END AS Delivered
    ,bdsr.CountSend
    ,CASE WHEN bdsr.CountOpen>0 THEN 1 ELSE 0 END AS UniqueOpen
    ,bdsr.UniqueClicks
    ,bdsr.CountOpen
    ,fd.SubChannel
    ,bdsr.CountClicks
    ,bdsr.CampaignNumber 
    ,bdsr.CampaignGroup
    ,bdcmpfd.IsFunded_New
    --,CASE WHEN fd.FirstDepositDate IS NOT NULL THEN 1 ELSE 0 END AS IsDepositor
    ,bdsr.CampaignSubGroup
     ,bdcmpfd.Equity
     ,fd.SerialID AffiliateID

    
FROM bi_output.bi_output_marketing_sfmc_sfmc_report       bdsr    
 
    JOIN bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked      fd

        ON bdsr.GCID=fd.GCID

    LEFT JOIN  bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata      bdcmpfd 

        ON  bdcmpfd.CID=fd.CID  AND bdcmpfd.DateID=bdsr.SendDateID

 


WHERE

 bdsr.etr_ym >= dateadd(month, -4, current_date())