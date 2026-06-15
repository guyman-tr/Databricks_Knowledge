SELECT FullData.*, d.Sessions,c.lps_for_registrations_dashboard 'Filter_LP''s'
FROM (SELECT  b.Date,
       b.LPSessionRegister,
	   b.PageTypeContentGroup,
	   b.FunnelPageCategory,
	   b.Medium,
	   b.Source,
	   b.DeviceCategory,
	   b.Platform,
       COUNT(CASE WHEN CAST(dc.FirstDepositDate AS DATE)>='2000-01-01' THEN b.CID END) FTDs,
	   COUNT(b.CID) Registrations,
       SUM(dc.FirstDepositAmount) FirstDepositAmount,
	   SUM(bdlba.Revenue8Y_LTV_New) LTV,
	   SUM(bdlba.Revenue8Y_LTV_NoExtreme_New) LTV_NoExtreme,
       COUNT(CASE WHEN bdfa.FirstAction='Stocks/ETFs' THEN b.CID END) 'Stocks/ETFs',
	   COUNT(CASE WHEN bdfa.FirstAction='Crypto' THEN b.CID END) 'Crypto',
	   COUNT(CASE WHEN bdfa.FirstAction='FX/Commodities/Indices' THEN b.CID END) 'FX/Commodities/Indices',
	   COUNT(CASE WHEN bdfa.FirstAction='Copy' THEN b.CID END) 'Copy',
	   COUNT(CASE WHEN bdfa.FirstAction='Copy Fund' THEN b.CID END) 'Copy Fund',
	   COUNT(CASE WHEN bdfa.FirstAction IS NULL AND CAST(dc.FirstDepositDate AS DATE)>='2000-01-01' THEN b.CID END) NotFirstAction,
	   SUM(CASE WHEN pd.ACC_CountDeposits>1 THEN 1 END)Redeposits,
	   SUM(pd.ACC_TotalDeposits)TotalDeposits
       FROM (SELECT *
             FROM (SELECT s.*, ROW_NUMBER() OVER(PARTITION BY s.CID ORDER BY s.Date) Row
                   FROM BI_DB_python.BI_DB_BigQueryGADataFirstPageRegistered s
                   JOIN DWH_dbo.Dim_Customer dct ON s.CID=dct.RealCID AND CAST(dct.RegisteredReal AS DATE)=s.Date AND dct.IsValidCustomer=1
	               WHERE s.Date>=DATEADD(MONTH,-6,CAST(GETDATE()AS DATE))
				   AND [Source] NOT IN ('115088','114807','89099','72681','94116','97898','110361','97798','92938','95378','96459','94617','111771','65160','77518','99511','121769','92557','121819','105428')
	               ) a
	         WHERE a.Row=1
			 ) b
       JOIN DWH_dbo.Dim_Customer dc ON b.CID=dc.RealCID AND dc.IsValidCustomer=1
       LEFT JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual bdlba ON b.CID = bdlba.CID
       LEFT JOIN BI_DB_dbo.BI_DB_First5Actions bdfa ON b.CID = bdfa.CID
	   LEFT JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData pd ON pd.CID=b.CID AND pd.Active_Month=CONVERT(VARCHAR(6), GETDATE()-1,112)
       GROUP BY b.Date,
                b.LPSessionRegister,
       	        b.PageTypeContentGroup,
       		    b.FunnelPageCategory,
				b.Medium,
				b.Source,
				b.DeviceCategory,
				b.Platform) FullData
LEFT JOIN [BI_DB_dbo].[External_Fivetran_google_sheets_lps_for_registrations_dashboard] c ON
          FullData.LPSessionRegister COLLATE Latin1_General_CS_AS=c.lps_for_registrations_dashboard COLLATE Latin1_General_CS_AS 
LEFT JOIN [BI_DB_python].[BI_DB_BigQueryGADataLPSessions] d ON FullData.Date = d.Date
                                             AND FullData.PageTypeContentGroup = d.PageTypeContentGroup 
											 AND FullData.LPSessionRegister=d.LandingPage
											 AND FullData.FunnelPageCategory=d.FunnelPageCategory
											 AND FullData.Medium=d.Medium
											 AND FullData.Source=d.Source
											 AND FullData.DeviceCategory=d.DeviceCategory
											 AND FullData.Platform=d.Platform