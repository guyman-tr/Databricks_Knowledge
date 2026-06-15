select    bdduftp.* , 
 (DATEPART(WEEKDAY, Date) + @@DATEFIRST - 1) % 7 + 1 AS WeekdayNum,
           daff.Contact,
	       dc.MarketingRegionManualName,
	 	   bdkscl.Cluster,
		   ffa.FirstInstrument, 
		   YEAR(bdcd.registered) AS RegisteredYear,
           CAST(bdcd.FirstDepositAmount AS INT) FTDA,
		   plt.FTDPlatformName AS FTDPlatform,
           CASE WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) <= 24 THEN '18-24'  
                WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 25 AND 34 THEN '25-34'  
                WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 35 AND 44 THEN '35-44'  
                WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 45 AND 54 THEN '45-54'  
                WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) >= 55 THEN '55+'  
                ELSE NULL END AS Age_Group,
                GETDATE() as DateU 
		  
FROM BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints bdduftp
JOIN BI_DB_dbo.BI_DB_CIDFirstDates  bdcd                        ON bdduftp.CID = bdcd.CID
JOIN DWH_dbo.Dim_Customer as dmmc                               ON bdduftp.CID = dmmc.RealCID
LEFT JOIN DWH_dbo.Dim_FTDPlatform AS plt                        ON plt.FTDPlatformID = dmmc.FTDPlatformID
LEFT JOIN DWH_dbo.Dim_Country  dc                               ON dc.Name=bdduftp.Country
LEFT JOIN BI_DB_dbo.BI_DB_KYC_Score_CID_Level bdkscl            ON bdkscl.RealCID = bdduftp.CID
LEFT JOIN BI_DB_dbo.BI_DB_First5Actions	ffa                     ON bdduftp.CID = ffa.CID
LEFT JOIN DWH_dbo.Dim_Affiliate daff                            ON daff.AffiliateID = bdduftp.AffiliateID

WHERE  bdduftp.Date>=CAST(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -6,GETDATE())), 0) AS DATE)
AND bdcd.Region <> 'Unknown'
AND bdduftp.Date <= getdate()-1