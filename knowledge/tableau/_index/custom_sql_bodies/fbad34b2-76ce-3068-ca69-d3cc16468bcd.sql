SELECT ISNULL(costfinance.YearMonth, LTV_Data.YearMonth)YearMonth,
       ISNULL(costfinance.Channel, LTV_Data.Channel)Channel,
	   ISNULL(costfinance.Region, LTV_Data.Region)Region,
	   LTV_Data.FTDs,
	   LTV_Data.LTV,
	   LTV_Data.LTV_FTDs,
	   costfinance.Cost,
	   leadscore.LTV_LeadScore,
	   leadscore.Users_LeadScore
FROM (SELECT CONVERT(VARCHAR(7),dc.FirstDepositDate,126) YearMonth,
             CASE WHEN dc1.SubChannel='FB' THEN 'Facebook'
      	          WHEN dc1.SubChannel='ASA' THEN 'ASA'
      			  WHEN dc1.SubChannel='Twitter' THEN 'Twitter'
      			  WHEN dc1.SubChannel='Outbrain' THEN 'Outbrain'
      			  WHEN dc1.SubChannel='Taboola' THEN 'Taboola'
      			  WHEN dc1.SubChannel IN ('Media Performance') THEN 'Media Performance'
      			  WHEN dc1.SubChannel='Media Programmatic' THEN 'Media Programmatic'
      			  WHEN dc1.SubChannel IN ('Mobile Non-CPA','Mobile CPA') THEN 'Mobile'
      			  WHEN dc1.SubChannel IN ('SMM','Direct','Direct Mobile') THEN 'Direct'
      			  WHEN dc1.SubChannel IN ('Google Brand','Google Search','Google UAC','YT') THEN 'Google'
      			  WHEN dc1.SubChannel IN ('SEM Other','Bing Search') THEN 'SEM'
				  WHEN dc1.SubChannel IN ('Discovery') THEN 'Google'
      			  WHEN dc1.SubChannel IN ('IBs','Affiliate') THEN 'Affiliate'
      	     ELSE dc1.Channel END Channel,
      	     dc2.MarketingRegionManualName Region,
			 COUNT(dc.RealCID) FTDs,
             SUM(ltv.Revenue8Y_LTV_New) LTV,
      	     COUNT(ltv.CID) LTV_FTDs
      FROM DWH_dbo.Dim_Customer dc
      LEFT JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual ltv ON dc.RealCID=ltv.CID AND dc.IsValidCustomer=1
      JOIN DWH_dbo.Dim_Channel dc1 ON dc.SubChannelID = dc1.SubChannelID
      JOIN DWH_dbo.Dim_Country dc2 ON dc.CountryID = dc2.CountryID
      WHERE YEAR(dc.FirstDepositDate)>=2023
	  AND dc.IsValidCustomer = 1
      GROUP BY CONVERT(VARCHAR(7),dc.FirstDepositDate,126),
               CASE WHEN dc1.SubChannel='FB' THEN 'Facebook'
      	            WHEN dc1.SubChannel='ASA' THEN 'ASA'
      			    WHEN dc1.SubChannel='Twitter' THEN 'Twitter'
      			    WHEN dc1.SubChannel='Outbrain' THEN 'Outbrain'
      			    WHEN dc1.SubChannel='Taboola' THEN 'Taboola'
      			    WHEN dc1.SubChannel IN ('Media Performance') THEN 'Media Performance'
      			    WHEN dc1.SubChannel='Media Programmatic' THEN 'Media Programmatic'
      			    WHEN dc1.SubChannel IN ('Mobile Non-CPA','Mobile CPA') THEN 'Mobile'
      			    WHEN dc1.SubChannel IN ('SMM','Direct','Direct Mobile') THEN 'Direct'
      			    WHEN dc1.SubChannel IN ('Google Brand','Google Search','Google UAC','YT') THEN 'Google'
      			    WHEN dc1.SubChannel IN ('SEM Other','Bing Search') THEN 'SEM'
					WHEN dc1.SubChannel IN ('Discovery') THEN 'Google'
      			    WHEN dc1.SubChannel IN ('IBs','Affiliate') THEN 'Affiliate'
      	       ELSE dc1.Channel END,
      			dc2.MarketingRegionManualName) LTV_Data
FULL OUTER JOIN (SELECT [month] YearMonth,
                        channel Channel,
	                    region Region,
	                    cost Cost
                 FROM [BI_DB_dbo].[External_Fivetran_gsheet_costfinance]) costfinance 
				 ON costfinance.YearMonth=LTV_Data.YearMonth
				 AND costfinance.Channel COLLATE Latin1_General_CS_AS=LTV_Data.Channel COLLATE Latin1_General_CS_AS
				 AND costfinance.Region COLLATE Latin1_General_CS_AS=LTV_Data.Region COLLATE Latin1_General_CS_AS
																						 
LEFT JOIN (SELECT bdc.NewMarketingRegion Region,
                  bdc.Channel,
                  SUM(bdlp.Revenue8Y_LTV_New) LTV_LeadScore,
                  COUNT(scl.RealCID) Users_LeadScore
           FROM BI_DB_dbo.BI_DB_KYC_Score_CID_Level scl
		   JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdc ON scl.RealCID=bdc.CID AND bdc.FirstDepositDate IS NOT NULL
           JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual  bdlp ON scl.RealCID = bdlp.CID AND bdlp.Revenue8Y_LTV_New IS NOT NULL
           WHERE CAST(bdc.FirstDepositDate AS DATE) >=DATEADD(MONTH,-7,CAST(CONCAT(CONVERT(VARCHAR(7),GETDATE(),126),'-01') AS DATE)) 
		     AND scl.Cluster!='No Cluster'
           GROUP BY bdc.NewMarketingRegion, bdc.Channel) leadscore ON LTV_Data.Region=leadscore.Region AND LTV_Data.Channel=leadscore.Channel