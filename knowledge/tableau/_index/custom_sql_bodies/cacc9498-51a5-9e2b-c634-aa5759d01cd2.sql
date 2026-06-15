select    bdduftp.* , 
cast(dmmc.RegisteredReal as date) as RegDate,
 (DATEPART(WEEKDAY, dmmc.RegisteredReal) + @@DATEFIRST - 1) % 7 + 1 AS WeekdayNum,
	       dc.MarketingRegionManualName,
	

		   YEAR(bdcd.registered) AS RegisteredYear,
                GETDATE() as DateU ,
ps.Name as PlayerStatus
		  
FROM  DWH_dbo.Dim_Customer dmmc
JOIN BI_DB_dbo.BI_DB_CIDFirstDates  bdcd                        ON dmmc.RealCID = bdcd.CID
JOIN BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints bdduftp                            ON bdduftp.CID = dmmc.RealCID
LEFT JOIN DWH_dbo.Dim_Country  dc                               ON dc.Name=bdduftp.Country
join DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=dmmc.PlayerStatusID
LEFT JOIN BI_DB_dbo.BI_DB_First5Actions	ffa   ON dmmc.RealCID = ffa.CID
                     

WHERE  dmmc.RegisteredReal>=CAST(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -12,GETDATE())), 0) AS DATE)
AND bdcd.Region <> 'Unknown'