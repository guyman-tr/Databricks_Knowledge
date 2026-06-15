SELECT b.*,
       dc.IsDepositor IsFTD,
	   dc.FirstDepositAmount,
	   dc1.Desk,
	   dc1.MarketingRegionManualName Region,
	   dc1.Name Country,
	   da.AffiliateID,
	   da.AffiliatesGroupsName,
	   dc2.[Organic/Paid],
	   dc2.Channel,
	   dc2.SubChannel,
	   DF.Name FunnelFrom,
	   dc.FunnelFromID,
	   CASE WHEN dc.FunnelFromID IN (51,54,56,57,58) THEN 'Funnels' ELSE 'Default' END FunnelFromGroup,
	   DP.Platform Funnel,
	   bdlba.Revenue8Y_LTV_New LTV,
	   bdlba.Revenue8Y_LTV_NoExtreme_New LTV_NoExtreme,
       bdfa.FirstAction,
       c.lps_for_registrations_dashboard,
       cast(c._fivetran_synced as date) fivetran_Update,
	   CASE WHEN pd.ACC_CountDeposits>1 THEN 1 END Redeposits,
	   pd.ACC_TotalDeposits
FROM (SELECT *
      FROM (
             SELECT s.*, ROW_NUMBER() OVER(PARTITION BY s.CID ORDER BY s.Date) Row
             FROM BI_DB_python.BI_DB_BigQueryGADataPageFirstSessionUsersReg s
             JOIN DWH_dbo.Dim_Customer dct ON s.CID=dct.RealCID AND CAST(dct.RegisteredReal AS DATE)=s.Date AND dct.IsValidCustomer=1
	     WHERE s.Date>=DATEADD(MONTH,-6,CAST(GETDATE()AS DATE))
		 AND [Source] NOT IN ('115088','114807','89099','72681','94116','97898','110361','97798','92938','95378','96459','94617','111771','65160','77518','99511','121769','92557','121819','105428')
) a
	   WHERE a.Row=1) b
LEFT JOIN DWH_dbo.Dim_Customer dc ON b.CID=dc.RealCID AND dc.IsValidCustomer=1
LEFT JOIN DWH_dbo.Dim_Country dc1 WITH(NOLOCK) ON dc.CountryID = dc1.CountryID
LEFT JOIN DWH_dbo.Dim_Channel dc2 WITH(NOLOCK) ON dc.SubChannelID = dc2.SubChannelID
LEFT JOIN DWH_dbo.Dim_Affiliate da WITH(NOLOCK) ON dc.AffiliateID = da.AffiliateID
LEFT JOIN DWH_dbo.[Dim_Funnel] DF WITH(NOLOCK) ON dc.FunnelFromID = DF.FunnelID  
LEFT JOIN DWH_dbo.[Dim_Platform] DP WITH(NOLOCK) ON DF.PlatformID = DP.PlatformID
LEFT JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual bdlba WITH(NOLOCK) ON b.CID = bdlba.CID
LEFT JOIN BI_DB_dbo.BI_DB_First5Actions bdfa ON b.CID = bdfa.CID
LEFT JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData pd ON b.CID = pd.CID AND pd.Active_Month=CONVERT(VARCHAR(6), GETDATE()-1,112)
LEFT JOIN [BI_DB_dbo].[External_Fivetran_google_sheets_lps_for_registrations_dashboard] c ON
                                               b.LPRegisterFirstSession COLLATE Latin1_General_CS_AS=c.lps_for_registrations_dashboard COLLATE Latin1_General_CS_AS