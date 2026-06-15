SELECT da.AffiliateID,
	   da.Contact,
	   da.ContractName,
	   da.AccountActivated,
       bdmmrd.CountryID,
	   bdmmrd.YearMonth,
	   bdmmrd.YearMonthID,
	   bdmmrd.CountryName, 
	   bdmmrd.NewMarketingRegion as Region,
	   bdmmrd.Desk,
	   bdmmrd.Channel,
	   bdmmrd.SubChannel,
	   bdmmrd.[Organic/Paid],
	   bdmmrd.ContractType,
	   CASE WHEN da.AffiliatesGroupsName LIKE ('%Rory%') OR da.AffiliatesGroupsName='UK Affiliates' THEN 'Rory Hatherell'
					 WHEN da.AffiliatesGroupsName LIKE ('%Arie%') THEN 'Arie Cohen'
					 WHEN da.AffiliatesGroupsName LIKE ('%Luciano%') THEN 'Luciano lorens'
					 WHEN da.AffiliatesGroupsName LIKE ('%Monika%') THEN 'Monika Hakak'
					 WHEN da.AffiliatesGroupsName LIKE ('%Majd%') THEN 'Majd Dagash'
					 WHEN da.AffiliatesGroupsName LIKE ('%Mathieu%') THEN 'Mathieu Sommerfeld'
					 WHEN da.AffiliatesGroupsName LIKE ('%Nimrod%') THEN 'Nimrod Burla'
					 WHEN da.AffiliatesGroupsName LIKE ('%Nurith%') THEN 'Nurith Terracina'
					 WHEN da.AffiliatesGroupsName LIKE ('%Ran%') THEN 'Ran Regev'
					 WHEN da.AffiliatesGroupsName LIKE ('%Shiran%') THEN 'Shiran Herzberg'
					 WHEN da.AffiliatesGroupsName LIKE ('%Troy%') THEN 'Troy Mulder'
					 WHEN da.AffiliatesGroupsName LIKE ('%David%') THEN 'David Dahan'
					 END AS Affiliate_managers,
	   da.AffiliatesGroupsName,
	   SUM(bdmmrd.TotalCost) TotalCost,
	   SUM(bdmmrd.RevShare_Comm) RevShare_Comm,
	   SUM(bdmmrd.CPA_Comm) CPA_Comm,
	   SUM(bdmmrd.CPL_Comm) CPL_Comm,
	   SUM(bdmmrd.RAF_Comm) RAF_Comm,
	   SUM(bdmmrd.eCost) eCost,
	   SUM(bdmmrd.Registration) Registration,
	   SUM(bdmmrd.FTD) FTD,
	   SUM(bdmmrd.EFTD) EFTD,
	   SUM(bdmmrd.FTDA) FTDA,
	   SUM(bdmmrd.NetRevenues) NetRevenues,
	   SUM(bdmmrd.VerificationLevelID2) VerificationLevelID2,
	   SUM(bdmmrd.VerificationLevelID3) VerificationLevelID3,
	   SUM(bdmmrd.Installs) Installs,
	   SUM(bdmmrd.TotalDeposit) TotalDeposit,
	   SUM(bdmmrd.LTV_NoExtreme) LTV_NoExtreme,
	   SUM(bdmmrd.GLTV) GLTV,
	   SUM(bdmmrd.FTDfromLTV) FTDfromLTV,
	   SUM(bdmmrd.PastGRevenue) PastGRevenue,
	   SUM(bdmmrd.SameDayFTD) SameDayFTD,
	   SUM(bdmmrd.IsRev) IsRev,
	   SUM(bdmmrd.Rev10) Rev10,
	   a.FTDE_Amount,
	   h.EFTDs,
	   MAX(bdmmrd.UpdateDate) UpdateDate,
	   b.TotalCashout,
	   b.TotalDeposits,
	   f.ACC_Revenue_Total_1M,
	   f.EOM_Equity_1M,
	   f.Distinct_CID_1M,
	   c.ACC_Revenue_Total_3M,
	   c.EOM_Equity_3M,
	   c.Distinct_CID_3M,
	   d.ACC_Revenue_Total_6M,
	   d.Distinct_CID_6M,
	   e.Copy,
	   e.CopyFund,
	   e.[FX/Commodities/Indices],
	   e.Crypto,
	   e.[Stocks/ETFs],
	   e.[Null First Action],
	   e.IsCross,
	   f.UsersClubSilverUp_1M,
	   c.UsersClubSilverUp_3M,
	   g.Club [ClubSilver&Up],
	   e.OpenFirstPosition
FROM BI_DB_dbo.BI_DB_MarketingMonthlyRawData bdmmrd 
JOIN DWH_dbo.Dim_Affiliate da
	ON bdmmrd.AffiliateID = da.AffiliateID

LEFT JOIN (
			SELECT  bdac.AffiliateID, 
					CONVERT(VARCHAR(7),bdac.FTD_Date,126) YearMonth, 
					bdac.DB_CountryID,
					SUM(bdac.FirstDepositAmount) 
					FTDE_Amount
			FROM BI_DB_dbo.BI_DB_AffiliateCOAbuse bdac
			WHERE bdac.AW_CPA>0 
				AND Channel ='Affiliate'
			GROUP BY bdac.AffiliateID,
					 CONVERT(VARCHAR(7),bdac.FTD_Date,126), 
					 bdac.DB_CountryID
		  ) a
	ON bdmmrd.AffiliateID=a.AffiliateID 
	AND bdmmrd.CountryID=a.DB_CountryID 
	AND bdmmrd.YearMonth=a.YearMonth

LEFT JOIN (
			SELECT  CONVERT(VARCHAR(7),mp.ActiveDate,126) YearMonth,
					mp.AffiliateID,
					mp.Country, 
					mp.Channel,
					mp.SubChannel,
					SUM(mp.TotalCashouts) TotalCashout,
					SUM(mp.TotalDeposits) TotalDeposits
			FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
			WHERE mp.Active_Month BETWEEN YEAR( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))*100+
										 month( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))
									 AND YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+month( CAST( DATEADD(MONTH,- 1, GETDATE()) as DATE))
				AND Channel ='Affiliate'
			GROUP BY CONVERT(VARCHAR(7),mp.ActiveDate,126),
					mp.AffiliateID, 
					mp.Country, 
					mp.Channel, 
					mp.SubChannel
			) b
ON bdmmrd.YearMonth=b.YearMonth 
	AND bdmmrd.AffiliateID=b.AffiliateID 
	AND bdmmrd.CountryName=b.Country 
	AND bdmmrd.Channel=b.Channel
	AND bdmmrd.SubChannel=b.SubChannel

LEFT JOIN (
			SELECT  CONVERT(VARCHAR(7),mp1.FTDdate,126) YearMonth,
					mp1.AffiliateID,
					mp1.Country, 
					mp1.Channel, 
					mp1.SubChannel,
	                SUM(mp1.ACC_Revenue_Total) ACC_Revenue_Total_1M,
	                COUNT(DISTINCT mp1.CID) Distinct_CID_1M,
				    SUM(mp1.EOM_Equity) EOM_Equity_1M,
				    COUNT(CASE WHEN mp1.EOM_Club IN ('Silver','Gold','Platinum','Platinum Plus','Diamond') THEN mp1.CID END) UsersClubSilverUp_1M
           FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp1
           WHERE mp1.FTD_Month BETWEEN YEAR( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))*100+
										month( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))
								 AND YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+month( CAST( DATEADD(MONTH,- 1, GETDATE()) as DATE))
				AND mp1.Seniority=1 
				AND Channel ='Affiliate'
           GROUP BY  CONVERT(VARCHAR(7),mp1.FTDdate,126),
					 mp1.AffiliateID, 
					 mp1.Country, 
					 mp1.Channel, 
					 mp1.SubChannel
		   ) f
	ON bdmmrd.AffiliateID=f.AffiliateID 
	AND bdmmrd.YearMonth=f.YearMonth 
	AND bdmmrd.CountryName=f.Country 
	AND bdmmrd.Channel=f.Channel 
    AND bdmmrd.SubChannel=f.SubChannel

LEFT JOIN (
			SELECT  CONVERT(VARCHAR(7),mp3.FTDdate,126) YearMonth,
					mp3.AffiliateID,
					mp3.Country, 
					mp3.Channel, 
					mp3.SubChannel,
	                SUM(mp3.ACC_Revenue_Total) ACC_Revenue_Total_3M,
	                COUNT(DISTINCT mp3.CID) Distinct_CID_3M,
				    SUM(mp3.EOM_Equity) EOM_Equity_3M,
				    COUNT(CASE WHEN mp3.EOM_Club IN ('Silver','Gold','Platinum','Platinum Plus','Diamond') THEN mp3.CID END) UsersClubSilverUp_3M
            FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp3
            WHERE mp3.FTD_Month BETWEEN YEAR( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))*100+
										 month( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))
									AND YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+month( CAST( DATEADD(MONTH,- 1, GETDATE()) as DATE))
				AND mp3.Seniority=3 
				AND Channel ='Affiliate'
            GROUP BY CONVERT(VARCHAR(7),mp3.FTDdate,126),
					 mp3.AffiliateID, 
					 mp3.Country, 
					 mp3.Channel, 
					 mp3.SubChannel
			) c
	ON bdmmrd.AffiliateID=c.AffiliateID 
	AND bdmmrd.YearMonth=c.YearMonth 
	AND bdmmrd.CountryName=c.Country 
	AND bdmmrd.Channel=c.Channel 
    AND bdmmrd.SubChannel=c.SubChannel

LEFT JOIN (
			SELECT CONVERT(VARCHAR(7),
					mp6.FTDdate,126) YearMonth,
					mp6.AffiliateID,
					mp6.Country, 
					mp6.Channel, mp6.SubChannel,
					SUM(mp6.ACC_Revenue_Total) ACC_Revenue_Total_6M,
					COUNT(DISTINCT mp6.CID) Distinct_CID_6M
            FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp6
            WHERE mp6.FTD_Month BETWEEN YEAR( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))*100+
										month( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))
									AND YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+month( CAST( DATEADD(MONTH,- 1, GETDATE()) as DATE))
				AND mp6.Seniority=6 
				AND Channel ='Affiliate'
            GROUP BY CONVERT(VARCHAR(7),
					 mp6.FTDdate,126),
					 mp6.AffiliateID, 
					 mp6.Country, 
					 mp6.Channel, 
					 mp6.SubChannel
		   ) d
	ON bdmmrd.AffiliateID=d.AffiliateID 
	AND bdmmrd.YearMonth=d.YearMonth 
	AND bdmmrd.CountryName=d.Country 
	AND bdmmrd.Channel=d.Channel 
    AND bdmmrd.SubChannel=d.SubChannel

LEFT JOIN (
			SELECT bdfa.AffiliateID, 
                   CASE WHEN bdfa.FirstAction IS NOT NULL THEN CONVERT(VARCHAR(7),bdfa.FirstActionDate,126) 
				        WHEN bdfa.FirstAction IS NULL THEN CONVERT(VARCHAR(7),bdfa.FirstDepositDate,126) END YearMonth,
	               bdfa.Country,
	               bdfa.Channel,
	               bdfa.SubChannel,
	               COUNT(CASE WHEN bdfa.FirstAction='Copy' THEN bdfa.FirstAction END) Copy,
	               COUNT(CASE WHEN bdfa.FirstAction='Copy Fund' THEN bdfa.FirstAction END) CopyFund,
	               COUNT(CASE WHEN bdfa.FirstAction='FX/Commodities/Indices' THEN bdfa.FirstAction END) 'FX/Commodities/Indices',
	               COUNT(CASE WHEN bdfa.FirstAction='Crypto' THEN bdfa.FirstAction END) Crypto,
	               COUNT(CASE WHEN bdfa.FirstAction='Stocks/ETFs' THEN bdfa.FirstAction END) 'Stocks/ETFs',
				   COUNT(CASE WHEN bdfa.FirstAction IS NULL THEN bdfa.CID END) 'Null First Action',
	               COUNT(CASE WHEN bdfa.FirstCross IS NOT NULL THEN bdfa.CID END)*1.0/COUNT(*) 'IsCross',
				   COUNT(bdfa.FirstAction) OpenFirstPosition
			FROM BI_DB_dbo.BI_DB_First5Actions bdfa
			WHERE YEAR(bdfa.FirstDepositDate)*100+MONTH(bdfa.FirstDepositDate) BETWEEN YEAR( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))*100+
																						month( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))
																					AND YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+
																						month( CAST( DATEADD(MONTH,- 1, GETDATE()) as DATE))
				AND bdfa.Channel='Affiliate'
			GROUP BY bdfa.AffiliateID, 
					 CASE WHEN bdfa.FirstAction IS NOT NULL THEN CONVERT(VARCHAR(7),bdfa.FirstActionDate,126) 
			              WHEN bdfa.FirstAction IS NULL THEN CONVERT(VARCHAR(7),bdfa.FirstDepositDate,126) END,
					 bdfa.Country,
	                 bdfa.Channel,
	                 bdfa.SubChannel
			 ) e
	ON bdmmrd.AffiliateID=e.AffiliateID 
	AND bdmmrd.YearMonth=e.YearMonth 
	AND bdmmrd.CountryName=e.Country 
	AND bdmmrd.Channel=e.Channel 
    AND bdmmrd.SubChannel=e.SubChannel

LEFT JOIN (
			SELECT dc.AffiliateID,
                  CONVERT(VARCHAR(7),dc.FirstDepositDate,126) YearMonth,
				  dc2.Name Country,
				  dc1.Channel,
				  dc1.SubChannel,
                  COUNT(CASE WHEN dc.PlayerLevelID IN (2,3,5,6,7) THEN dc.RealCID END ) Club
            FROM DWH_dbo.Dim_Customer dc 
		    JOIN DWH_dbo.Dim_Channel dc1 
				ON dc.SubChannelID = dc1.SubChannelID AND dc1.Channel ='Affiliate'
		    JOIN DWH_dbo.Dim_Country dc2 
				ON dc.CountryID = dc2.CountryID
		    WHERE dc.IsValidCustomer=1 
				AND YEAR(dc.FirstDepositDate)*100+MONTH(dc.FirstDepositDate) BETWEEN YEAR( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))*100+
																						month( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))
																					AND YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+
																						month( CAST( DATEADD(MONTH,- 1, GETDATE()) as DATE))
		    GROUP BY dc.AffiliateID, 
					 CONVERT(VARCHAR(7),
					 dc.FirstDepositDate,126),
					 dc2.Name, 
					 dc1.Channel, 
					 dc1.SubChannel
			) g 
	ON bdmmrd.AffiliateID=g.AffiliateID 
	AND bdmmrd.YearMonth=g.YearMonth 
	AND bdmmrd.CountryName=g.Country 
	AND bdmmrd.Channel=g.Channel 
	AND bdmmrd.SubChannel=g.SubChannel

LEFT JOIN (
			SELECT CONVERT(VARCHAR(7),bdftr.Date,126) YearMonth,
                   dc.AffiliateID,
				   dc1.Name Country,
				   dc2.Channel,
				   dc2.SubChannel,
				   COUNT(*) EFTDs
            FROM BI_DB_dbo.BI_DB_FirstTimeRev10 bdftr
		    JOIN DWH_dbo.Dim_Customer dc 
				ON bdftr.CID=dc.RealCID AND dc.IsValidCustomer=1
		    JOIN DWH_dbo.Dim_Country dc1 
				ON dc.CountryID = dc1.CountryID
		    JOIN DWH_dbo.Dim_Channel dc2 
				ON dc.SubChannelID = dc2.SubChannelID
		    WHERE YEAR(bdftr.Date)*100+MONTH(bdftr.Date) BETWEEN YEAR( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))*100+
																month( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))
															AND YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+
																month( CAST( DATEADD(MONTH,- 1, GETDATE()) as DATE))
		    GROUP BY CONVERT(VARCHAR(7),bdftr.Date,126), 
					 dc.AffiliateID, 
					 dc1.Name, 
					 dc2.Channel, 
					 dc2.SubChannel
			) h 
	ON bdmmrd.AffiliateID=h.AffiliateID 
	AND bdmmrd.YearMonth=h.YearMonth 
	AND bdmmrd.CountryName=h.Country 
	AND bdmmrd.Channel=h.Channel 
	AND bdmmrd.SubChannel=h.SubChannel

WHERE bdmmrd.YearMonthID BETWEEN YEAR( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))*100+
								 month( CAST( DATEFROMPARTS (DATEPART(yyyy, GETDATE()) - 1, 1, 1 ) as date))
							 AND YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+month( CAST( DATEADD(MONTH,- 1, GETDATE()) as DATE))
	AND (da.AffiliatesGroupsName LIKE ('%Rory%') OR  da.AffiliatesGroupsName LIKE ('%Arie%') or da.AffiliatesGroupsName LIKE ('%Luciano%')  
				OR da.AffiliatesGroupsName LIKE ('%Monika%') or da.AffiliatesGroupsName LIKE ('%Majd%') OR da.AffiliatesGroupsName LIKE ('%Mathieu%') 
				OR da.AffiliatesGroupsName LIKE ('%Nimrod%') or da.AffiliatesGroupsName LIKE ('%Nurith%') or da.AffiliatesGroupsName LIKE ('%Ran%') 
				or da.AffiliatesGroupsName LIKE ('%Shiran%') or da.AffiliatesGroupsName LIKE ('%Troy%') or da.AffiliatesGroupsName LIKE ('%David%') 
				OR da.AffiliatesGroupsName='UK Affiliates')
			AND da.AffiliatesGroupsName NOT IN ('Ariela','Ranit')
			AND da.Channel IN ('Affiliate')
			AND da.ContractName NOT LIKE ('%Terminated%')
GROUP BY da.AffiliateID,
	   da.Contact,
	   da.ContractName,
	   da.AccountActivated,
       bdmmrd.CountryID,
	   bdmmrd.YearMonth,
	   bdmmrd.YearMonthID,
	   bdmmrd.CountryName, 
	   bdmmrd.NewMarketingRegion,
	   bdmmrd.Desk,
	   bdmmrd.Channel,
	   bdmmrd.SubChannel,
	   bdmmrd.[Organic/Paid],
	   bdmmrd.ContractType,
	   CASE WHEN da.AffiliatesGroupsName LIKE ('%Rory%') OR da.AffiliatesGroupsName='UK Affiliates' THEN 'Rory Hatherell'
					 WHEN da.AffiliatesGroupsName LIKE ('%Arie%') THEN 'Arie Cohen'
					 WHEN da.AffiliatesGroupsName LIKE ('%Luciano%') THEN 'Luciano lorens'
					 WHEN da.AffiliatesGroupsName LIKE ('%Monika%') THEN 'Monika Hakak'
					 WHEN da.AffiliatesGroupsName LIKE ('%Majd%') THEN 'Majd Dagash'
					 WHEN da.AffiliatesGroupsName LIKE ('%Mathieu%') THEN 'Mathieu Sommerfeld'
					 WHEN da.AffiliatesGroupsName LIKE ('%Nimrod%') THEN 'Nimrod Burla'
					 WHEN da.AffiliatesGroupsName LIKE ('%Nurith%') THEN 'Nurith Terracina'
					 WHEN da.AffiliatesGroupsName LIKE ('%Ran%') THEN 'Ran Regev'
					 WHEN da.AffiliatesGroupsName LIKE ('%Shiran%') THEN 'Shiran Herzberg'
					 WHEN da.AffiliatesGroupsName LIKE ('%Troy%') THEN 'Troy Mulder'
					 WHEN da.AffiliatesGroupsName LIKE ('%David%') THEN 'David Dahan'
					 END,
	   da.AffiliatesGroupsName,
	   a.FTDE_Amount,
	   h.EFTDs,
	   b.TotalCashout,
	   b.TotalDeposits,
	   f.ACC_Revenue_Total_1M,
	   f.EOM_Equity_1M,
	   f.Distinct_CID_1M,
	   c.ACC_Revenue_Total_3M,
	   c.EOM_Equity_3M,
	   c.Distinct_CID_3M,
	   d.ACC_Revenue_Total_6M,
	   d.Distinct_CID_6M,
	   e.Copy,
	   e.CopyFund,
	   e.[FX/Commodities/Indices],
	   e.Crypto,
	   e.[Stocks/ETFs],
	   e.[Null First Action],
	   e.IsCross,
	   f.UsersClubSilverUp_1M,
	   c.UsersClubSilverUp_3M,
	   g.Club ,
	   e.OpenFirstPosition