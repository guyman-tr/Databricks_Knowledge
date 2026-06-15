SELECT affdata.AffiliateID,
       affdata.TradingAccount_RealCID,
       affdata.Contact,
       affdata.Country,
       affdata.TradingAccount_UserName,
       affdata.Affiliate_Email,
       affdata.User_Email,
       affdata.WebSiteURL,
       affdata.Channel,
       affdata.AffiliatesGroupsName,
       affdata.VerificationLevelID,
       affdata.DateCreated,
       affdata.AccountActivated,
       allcost.Payment_LifeTime,
       KPIdata.LastMonthPayment,
       KPIdata.LastMonthRegUS,
       regulation_reg.LastMonthRegASIC,
       KPIdata.LastMonthRegEU,
       KPIdata.LastMonthRegUK,
       regulation_reg.LastMonthRegFCA,
       affdata.RegistrationLifeTime,
       KPIdata.LastMonthFTD_US,
       regulation_ftd.LastMonthFTD_ASIC,
       KPIdata.LastMonthFTD_EU, 
	   KPIdata.LastMonthFTD_UK,
       regulation_ftd.LastMonthFTD_FCA, 
	   KPIdata.LastMonthFTD_Belgium, 
	   KPIdata.LastMonthFTD_Portugal, 
	   KPIdata.LastMonthFTD_Spain,
	   KPIdata.LastMonthFTD_French, 
	   regulation_ftd.LastMonthFTD_Fincen, 
	   regulation_ftd.[LastMonthFTD_FinCEN+FINRA], 
	   affdata.FTDLifeTime,
	   CONVERT(VARCHAR(7),DATEADD(MONTH,-1,GETDATE()),126) DataForYearMonth
FROM (SELECT da.AffiliateID,
             da.TradingAccount_RealCID,
             da.Contact,
             dc.Name Country,
             da.TradingAccount_UserName,
             da.Email Affiliate_Email,
             dc1.Email User_Email,
             da.WebSiteURL,
             da.Channel,
             da.AffiliatesGroupsName,
             dc1.VerificationLevelID,
             da.DateCreated,
             da.AccountActivated,
             da.RegistrationLifeTime,
             da.FTDLifeTime
      FROM DWH..Dim_Affiliate da
	  JOIN [ThirdParty_Fivetran].[Fivetran].google_sheets.multiregulationaffiliatecompliance a ON da.AffiliateID=a.aff_id
      JOIN DWH..Dim_Country dc ON da.CountryID = dc.CountryID
      JOIN DWH..Dim_Customer dc1 ON da.TradingAccount_RealCID=dc1.RealCID
      JOIN DWH..Dim_PlayerLevel dpl ON dc1.PlayerLevelID = dpl.PlayerLevelID) affdata
LEFT JOIN (SELECT b1.AffiliateID,
                  SUM(b1.TotalCost)LastMonthPayment,
                  SUM(CASE WHEN b1.Region='USA' THEN b1.Registration END)LastMonthRegUS,
                  SUM(CASE WHEN b1.Region='UK' THEN b1.Registration END)LastMonthRegUK,
                  SUM(CASE WHEN dc.IsEuropeanCountry=1 THEN b1.Registration END)LastMonthRegEU,
                  SUM(CASE WHEN b1.Region='USA' THEN b1.FTD END)LastMonthFTD_US,
                  SUM(CASE WHEN b1.Region='UK' THEN b1.FTD END)LastMonthFTD_UK,
                  SUM(CASE WHEN dc.IsEuropeanCountry=1 THEN b1.FTD END)LastMonthFTD_EU,
                  SUM(CASE WHEN b1.CountryName='Belgium' THEN b1.FTD END)LastMonthFTD_Belgium,
                  SUM(CASE WHEN b1.CountryName='Portugal' THEN b1.FTD END)LastMonthFTD_Portugal,
                  SUM(CASE WHEN b1.Region='French' THEN b1.FTD END)LastMonthFTD_French,
                  SUM(CASE WHEN b1.Region='Spain' THEN b1.FTD END)LastMonthFTD_Spain
           FROM BI_DB..BI_DB_MarketingMonthlyRawData b1
           JOIN DWH..Dim_Country dc ON b1.CountryID = dc.CountryID
		   JOIN [ThirdParty_Fivetran].[Fivetran].google_sheets.multiregulationaffiliatecompliance a ON b1.AffiliateID=a.aff_id
           WHERE b1.YearMonth =CONVERT(VARCHAR(7),DATEADD(MONTH,-1,GETDATE()),126)
           GROUP BY b1.AffiliateID) KPIdata ON affdata.AffiliateID=KPIdata.AffiliateID
LEFT JOIN (SELECT b2.AffiliateID,
                  SUM(b2.TotalCost)Payment_LifeTime
           FROM BI_DB..BI_DB_MarketingMonthlyRawData b2
           JOIN [ThirdParty_Fivetran].[Fivetran].google_sheets.multiregulationaffiliatecompliance b ON b2.AffiliateID=b.aff_id
           GROUP BY b2.AffiliateID) allcost ON affdata.AffiliateID=allcost.AffiliateID
LEFT JOIN (SELECT dc1.AffiliateID,
                  COUNT(CASE WHEN dr.ID IN (4,10) THEN dc1.RealCID END)LastMonthRegASIC,
                  COUNT(CASE WHEN dr.ID IN (2,9) THEN dc1.RealCID END)LastMonthRegFCA
           FROM DWH..Dim_Customer dc1
		   JOIN [ThirdParty_Fivetran].[Fivetran].google_sheets.multiregulationaffiliatecompliance a ON dc1.AffiliateID=a.aff_id
           JOIN DWH..Dim_Regulation dr ON dc1.RegulationID = dr.ID
           WHERE YEAR(dc1.RegisteredReal)=YEAR(DATEADD(MONTH,-1,GETDATE())) AND MONTH(dc1.RegisteredReal)=MONTH((DATEADD(MONTH,-1,GETDATE())))
           GROUP BY dc1.AffiliateID) regulation_reg ON affdata.AffiliateID=regulation_reg.AffiliateID
LEFT JOIN (SELECT dc2.AffiliateID,
                  COUNT(CASE WHEN dr.ID IN (4,10) THEN dc2.RealCID END)LastMonthFTD_ASIC,
                  COUNT(CASE WHEN dr.ID IN (2,9) THEN dc2.RealCID END)LastMonthFTD_FCA,
                  COUNT(CASE WHEN dr.ID=7 THEN dc2.RealCID END)LastMonthFTD_Fincen,
                  COUNT(CASE WHEN dr.ID=8 THEN dc2.RealCID END)'LastMonthFTD_FinCEN+FINRA'
           FROM DWH..Dim_Customer dc2
		   JOIN [ThirdParty_Fivetran].[Fivetran].google_sheets.multiregulationaffiliatecompliance a ON dc2.AffiliateID=a.aff_id
           JOIN DWH..Dim_Regulation dr ON dc2.RegulationID = dr.ID
           WHERE YEAR(dc2.FirstDepositDate)=YEAR((DATEADD(MONTH,-1,GETDATE()))) AND MONTH(dc2.FirstDepositDate)=MONTH((DATEADD(MONTH,-1,GETDATE())))
           GROUP BY dc2.AffiliateID) regulation_ftd ON affdata.AffiliateID=regulation_ftd.AffiliateID