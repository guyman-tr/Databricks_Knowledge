SELECT main.AffiliateID, 
       main.CountryID, 
	   dc.Name Aff_Country,
	   dc.MarketingRegionManualName Aff_Region,
	   main.YearMonth, 
	   main.YearMonthID, 
	   main.CountryName, 
	   main.Region, 
	   main.Desk, 
	   main.Channel, 
	   main.SubChannel, 
	   main.[Organic/Paid], 
	   main.Contact, 
	   main.ContractName, 
	   main.ContractType, 
	   main.AffiliatesGroupsName,
	   (CASE WHEN main.CPA_Comm IS NOT NULL THEN main.CPA_Comm ELSE 0 END)+(CASE WHEN cost.Relative_eCost IS NOT NULL THEN cost.Relative_eCost ELSE 0 END) TotalCommission,
	   cost.Relative_eCost,
	   main.eCost,
	   main.Lead_Comm,
	   (CASE WHEN main.CPA_Comm IS NOT NULL THEN main.CPA_Comm ELSE 0 END)+(CASE WHEN main.eCost IS NOT NULL THEN main.eCost ELSE 0 END) TotalCommission_eCost,
	   main.RevShare_Comm, 
	   main.CPA_Comm, 
	   main.CPL_Comm, 
	   main.RAF_Comm, 
	   main.TotalCost,
	   main.Registration, 
	   main.FTD, main.EFTD, 
	   main.FTDA, 
	   main.NetRevenues,
	   rev.Revenue_Total,
	   main.VerificationLevelID2,
	   main.VerificationLevelID3, 
	   main.Installs, 
	   main.TotalDeposit, 
	   main.LTV_NoExtreme, 
	   main.GLTV,
	   main.FTDfromLTV, 
	   main.PastGRevenue, 
	   main.SameDayFTD, 
	   main.IsRev, 
	   main.UpdateDate,
	   a.FTDE_Amount,
	   h.EFTDs,
	   i.Rev5,
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
	   e.[Real Stocks/ETFs],
	   e.[CFD Stocks/ETFs],
	   e.[Null First Action],
	   e.IsCross,
	   f.UsersClubSilverUp_1M,
	   c.UsersClubSilverUp_3M,
	   g.Club [ClubSilver&Up],
	   e.OpenFirstPosition,
	   b.Funded,
	   b.UsersPanel,
	   b.ClusterCrypto,
	   b.ClusterInvestors,
	   b.ClusterTraders,
	   j.Funded30d,
	   j.EquityLess20030d,
	   g.[FTD<90],
	   g.[90<FTD<190],
	   g.[190<FTD<500],
	   g.[FTD>500],
	   m.RevForCostReturn,
	   LeadScore_LTV.LTV_LeadScore_Low LTV_Low,
	   LeadScore_LTV.LTV_LeadScore_Mid LTV_Mid,
	   LeadScore_LTV.LTV_LeadScore_High LTV_High,
	   LeadScore_LTV.Users_LeadScore_Low,
	   LeadScore_LTV.Users_LeadScore_Mid,
	   LeadScore_LTV.Users_LeadScore_High
FROM (SELECT bdmmrd.AffiliateID,
             bdmmrd.CountryID,
	         bdmmrd.YearMonth,
	         bdmmrd.YearMonthID,
	         bdmmrd.CountryName, 
	         bdmmrd.NewMarketingRegion Region,
	         bdmmrd.Desk,
	         bdmmrd.Channel,
	         bdmmrd.SubChannel,
	         bdmmrd.[Organic/Paid],
	         bdmmrd.Contact,
	         bdmmrd.ContractName,
	         bdmmrd.ContractType,
	         bdmmrd.AffiliatesGroupsName,
	         SUM(bdmmrd.RevShare_Comm) RevShare_Comm,
	         SUM(bdmmrd.CPA_Comm) CPA_Comm,
			 SUM(bdmmrd.eCost)eCost,
			 SUM(Lead_Comm)Lead_Comm,
	         SUM(bdmmrd.CPL_Comm) CPL_Comm,
	         SUM(bdmmrd.RAF_Comm) RAF_Comm,
			 SUM(bdmmrd.TotalCost) TotalCost,
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
	         MAX(bdmmrd.UpdateDate) UpdateDate
      FROM BI_DB..BI_DB_MarketingMonthlyRawData bdmmrd WITH (NOLOCK)
	  WHERE bdmmrd.YearMonthID>='202201' --AND bdmmrd.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
      GROUP BY bdmmrd.AffiliateID,
               bdmmrd.CountryID,
      	       bdmmrd.YearMonth,
      	       bdmmrd.YearMonthID,
      	       bdmmrd.CountryName, 
      	       bdmmrd.NewMarketingRegion,
      	       bdmmrd.Desk,
      	       bdmmrd.Channel,
      	       bdmmrd.SubChannel,
      	       bdmmrd.[Organic/Paid],
      	       bdmmrd.Contact,
      	       bdmmrd.ContractName,
      	       bdmmrd.ContractType,
      	       bdmmrd.AffiliatesGroupsName) main
LEFT JOIN (SELECT bdac.AffiliateID, 
                  CONVERT(VARCHAR(7),bdac.FTD_Date,126) YearMonth, 
				  bdac.DB_CountryID,
				  SUM(bdac.FirstDepositAmount) FTDE_Amount
           FROM BI_DB_AffiliateCOAbuse bdac WITH (NOLOCK)
           WHERE bdac.AW_CPA>0 --AND Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
           GROUP BY bdac.AffiliateID,CONVERT(VARCHAR(7),bdac.FTD_Date,126), bdac.DB_CountryID) a
ON main.AffiliateID=a.AffiliateID AND main.CountryID=a.DB_CountryID AND main.YearMonth=a.YearMonth
LEFT JOIN (SELECT presentageFTD.AffiliateID, presentageFTD.YearMonthID, presentageFTD.CountryName, presentageFTD.Channel, presentageFTD.SubChannel,
                  presentageFTD.FTD_Ratio*ecost.eCost Relative_eCost
           FROM (SELECT b1.AffiliateID, b1.YearMonthID,b1.CountryName, b1.Channel, b1.SubChannel, SUM(b1.eCost)ecost,SUM(b1.FTD)FTD,
		                SUM(b1.FTD)*1.0/(SELECT SUM(b2.FTD)FTD 
                                         FROM BI_DB..BI_DB_MarketingMonthlyRawData b2 WITH (NOLOCK)
              		                     WHERE b2.YearMonthID=b1.YearMonthID
              			                   AND b2.AffiliateID=b1.AffiliateID) FTD_Ratio
                 FROM BI_DB..BI_DB_MarketingMonthlyRawData b1 WITH (NOLOCK)
                 WHERE b1.YearMonthID>='202201' --AND b1.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
                 GROUP BY b1.AffiliateID, b1.YearMonthID,b1.CountryName, b1.Channel, b1.SubChannel) presentageFTD
           LEFT JOIN (SELECT bd.AffiliateID,bd.YearMonthID, SUM(bd.eCost)eCost
                      FROM BI_DB..BI_DB_MarketingMonthlyRawData bd WITH (NOLOCK)
                      WHERE bd.Region='Unknown' 
					    --AND bd.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
					    AND bd.YearMonthID>='202201'
                      GROUP BY bd.AffiliateID,bd.YearMonthID) ecost ON ecost.YearMonthID=presentageFTD.YearMonthID AND ecost.AffiliateID=presentageFTD.AffiliateID) cost
ON main.YearMonthID=cost.YearMonthID AND main.AffiliateID=cost.AffiliateID AND main.CountryName=cost.CountryName AND main.Channel=cost.Channel
   AND main.SubChannel=cost.SubChannel
LEFT JOIN (SELECT CONVERT(VARCHAR(7),mp.ActiveDate,126) YearMonth,mp.AffiliateID,mp.Country, mp.Channel, mp.SubChannel,
                  SUM(mp.TotalCashouts) TotalCashout,
	              SUM(mp.TotalDeposits) TotalDeposits,
				  SUM(mp.IsEOM_Funded_NEW) Funded,
				  COUNT(mp.CID) UsersPanel,
				  SUM(CASE WHEN mp.ClusterDetail IN ('Equities Crypto','Crypto') THEN 1 END) ClusterCrypto,
				  SUM(CASE WHEN mp.ClusterDetail='Equities Investors' THEN 1 END) ClusterInvestors,
				  SUM(CASE WHEN mp.ClusterDetail IN ('Diversified Traders','Equities Traders','Leveraged Traders') THEN 1 END) ClusterTraders
           FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData mp WITH (NOLOCK)
           WHERE mp.Active_Month>=202201 --AND Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
           GROUP BY CONVERT(VARCHAR(7),mp.ActiveDate,126),mp.AffiliateID, mp.Country, mp.Channel, mp.SubChannel) b
ON main.YearMonth=b.YearMonth AND main.AffiliateID=b.AffiliateID AND main.CountryName=b.Country AND main.Channel=b.Channel
   AND main.SubChannel=b.SubChannel
LEFT JOIN (SELECT CONVERT(VARCHAR(7),mp1.FTDdate,126) YearMonth,mp1.AffiliateID,mp1.Country, mp1.Channel, mp1.SubChannel,
	              SUM(mp1.ACC_Revenue_Total) ACC_Revenue_Total_1M,
	              COUNT(DISTINCT mp1.CID) Distinct_CID_1M,
				  SUM(mp1.EOM_Equity) EOM_Equity_1M,
				  COUNT(CASE WHEN mp1.EOM_Club IN ('Silver','Gold','Platinum','Platinum Plus','Diamond') THEN mp1.CID END) UsersClubSilverUp_1M
           FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData mp1 WITH (NOLOCK)
           WHERE mp1.FTD_Month>=202201 AND mp1.Seniority=1 --AND Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
           GROUP BY CONVERT(VARCHAR(7),mp1.FTDdate,126),mp1.AffiliateID, mp1.Country, mp1.Channel, mp1.SubChannel) f
ON main.AffiliateID=f.AffiliateID AND main.YearMonth=f.YearMonth AND main.CountryName=f.Country AND main.Channel=f.Channel 
   AND main.SubChannel=f.SubChannel
LEFT JOIN (SELECT CONVERT(VARCHAR(7),mp3.FTDdate,126) YearMonth,mp3.AffiliateID,mp3.Country, mp3.Channel, mp3.SubChannel,
	              SUM(mp3.ACC_Revenue_Total) ACC_Revenue_Total_3M,
	              COUNT(DISTINCT mp3.CID) Distinct_CID_3M,
				  SUM(mp3.EOM_Equity) EOM_Equity_3M,
				  COUNT(CASE WHEN mp3.EOM_Club IN ('Silver','Gold','Platinum','Platinum Plus','Diamond') THEN mp3.CID END) UsersClubSilverUp_3M
           FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData mp3 WITH (NOLOCK)
           WHERE mp3.FTD_Month>=202201 AND mp3.Seniority=3 --AND Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
           GROUP BY CONVERT(VARCHAR(7),mp3.FTDdate,126),mp3.AffiliateID, mp3.Country, mp3.Channel, mp3.SubChannel) c
ON main.AffiliateID=c.AffiliateID AND main.YearMonth=c.YearMonth AND main.CountryName=c.Country AND main.Channel=c.Channel 
   AND main.SubChannel=c.SubChannel
LEFT JOIN (SELECT CONVERT(VARCHAR(7),mp6.FTDdate,126) YearMonth,mp6.AffiliateID,mp6.Country, mp6.Channel, mp6.SubChannel,
	              SUM(mp6.ACC_Revenue_Total) ACC_Revenue_Total_6M,
	              COUNT(DISTINCT mp6.CID) Distinct_CID_6M
           FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData mp6 WITH (NOLOCK)
           WHERE mp6.FTD_Month>=202201 AND mp6.Seniority=6 --AND Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
           GROUP BY CONVERT(VARCHAR(7),mp6.FTDdate,126),mp6.AffiliateID, mp6.Country, mp6.Channel, mp6.SubChannel) d
ON main.AffiliateID=d.AffiliateID AND main.YearMonth=d.YearMonth AND main.CountryName=d.Country AND main.Channel=d.Channel 
   AND main.SubChannel=d.SubChannel
LEFT JOIN (SELECT bdfa.AffiliateID, 
                  CASE WHEN bdfa.FirstAction IS NOT NULL THEN CONVERT(VARCHAR(7),bdfa.FirstActionDate,126) 
				       WHEN bdfa.FirstAction IS NULL THEN CONVERT(VARCHAR(7),bdfa.FirstDepositDate,126) END YearMonth,
	              bdfa.Country,
	              bdfa.Channel,
	              bdfa.SubChannel,
	              COUNT(CASE WHEN bdfa.FirstAction_Detailed='Copy' THEN bdfa.FirstAction_Detailed END) Copy,
	              COUNT(CASE WHEN bdfa.FirstAction_Detailed='Copy Fund' THEN bdfa.FirstAction_Detailed END) CopyFund,
	              COUNT(CASE WHEN bdfa.FirstAction_Detailed='FX/Commodities/Indices' THEN bdfa.FirstAction_Detailed END) 'FX/Commodities/Indices',
	              COUNT(CASE WHEN bdfa.FirstAction_Detailed='Crypto' THEN bdfa.FirstAction_Detailed END) Crypto,
	              COUNT(CASE WHEN bdfa.FirstAction_Detailed='Real Stocks/ETFs' THEN bdfa.FirstAction_Detailed END) 'Real Stocks/ETFs',
				  COUNT(CASE WHEN bdfa.FirstAction_Detailed='CFD Stocks/ETFs' THEN bdfa.FirstAction_Detailed END) 'CFD Stocks/ETFs',
				  COUNT(CASE WHEN bdfa.FirstAction_Detailed IS NULL THEN bdfa.CID END) 'Null First Action',
	              COUNT(CASE WHEN bdfa.FirstCross IS NOT NULL THEN bdfa.CID END)*1.0/COUNT(*) 'IsCross',
				  COUNT(bdfa.FirstAction) OpenFirstPosition
           FROM BI_DB..BI_DB_First5Actions bdfa WITH (NOLOCK)
           WHERE YEAR(FirstDepositDate)>=2022
		     --AND bdfa.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
           GROUP BY bdfa.AffiliateID, 
                    CASE WHEN bdfa.FirstAction IS NOT NULL THEN CONVERT(VARCHAR(7),bdfa.FirstActionDate,126) 
           		         WHEN bdfa.FirstAction IS NULL THEN CONVERT(VARCHAR(7),bdfa.FirstDepositDate,126) END,
           	        bdfa.Country,
           	        bdfa.Channel,
           	        bdfa.SubChannel) e
ON main.AffiliateID=e.AffiliateID AND main.YearMonth=e.YearMonth AND main.CountryName=e.Country AND main.Channel=e.Channel 
   AND main.SubChannel=e.SubChannel
LEFT JOIN (SELECT dc.AffiliateID,
                  CONVERT(VARCHAR(7),dc.FirstDepositDate,126) YearMonth,
				  dc2.Name Country,
				  dc1.Channel,
				  dc1.SubChannel,
                  COUNT(CASE WHEN dc.PlayerLevelID IN (2,3,5,6,7) THEN dc.RealCID END ) Club,
				  SUM(CASE WHEN dc.FirstDepositAmount<=90 THEN 1 END) 'FTD<90',
				  SUM(CASE WHEN dc.FirstDepositAmount>90 AND dc.FirstDepositAmount<=190 THEN 1 END) '90<FTD<190',
				  SUM(CASE WHEN dc.FirstDepositAmount>190 AND dc.FirstDepositAmount<=500 THEN 1 END) '190<FTD<500',
				  SUM(CASE WHEN dc.FirstDepositAmount>500 THEN 1 END) 'FTD>500'
           FROM DWH..Dim_Customer dc WITH (NOLOCK)
		   JOIN DWH..Dim_Channel dc1 WITH (NOLOCK) ON dc.SubChannelID = dc1.SubChannelID --AND dc1.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
		   JOIN DWH..Dim_Country dc2 WITH (NOLOCK) ON dc.CountryID = dc2.CountryID
		   WHERE dc.IsValidCustomer=1 AND YEAR(dc.FirstDepositDate)>=2022
		   GROUP BY dc.AffiliateID, CONVERT(VARCHAR(7),dc.FirstDepositDate,126),dc2.Name, dc1.Channel, dc1.SubChannel) g 
ON main.AffiliateID=g.AffiliateID AND main.YearMonth=g.YearMonth AND main.CountryName=g.Country AND main.Channel=g.Channel AND
   main.SubChannel=g.SubChannel
LEFT JOIN (SELECT CONVERT(VARCHAR(7),bdftr.Date,126) YearMonth,
                  dc.AffiliateID,
				  dc1.Name Country,
				  dc2.Channel,
				  dc2.SubChannel,
				  COUNT(*) EFTDs
           FROM BI_DB..BI_DB_FirstTimeRev10 bdftr WITH (NOLOCK)
		   JOIN DWH..Dim_Customer dc WITH (NOLOCK) ON bdftr.CID=dc.RealCID AND dc.IsValidCustomer=1
		   JOIN DWH..Dim_Country dc1 WITH (NOLOCK) ON dc.CountryID = dc1.CountryID
		   JOIN DWH..Dim_Channel dc2 WITH (NOLOCK) ON dc.SubChannelID = dc2.SubChannelID --AND dc2.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
		   WHERE YEAR(bdftr.Date)>=2022
		   GROUP BY CONVERT(VARCHAR(7),bdftr.Date,126), dc.AffiliateID, dc1.Name, dc2.Channel, dc2.SubChannel) h 
ON main.AffiliateID=h.AffiliateID AND main.YearMonth=h.YearMonth AND main.CountryName=h.Country AND main.Channel=h.Channel AND
   main.SubChannel=h.SubChannel
LEFT JOIN (SELECT CONVERT(VARCHAR(7),bdftr.Date,126) YearMonth,
                  dc.AffiliateID,
				  dc1.Name Country,
				  dc2.Channel,
				  dc2.SubChannel,
				  COUNT(*) Rev5
           FROM BI_DB..BI_DB_FirstTimeRev5 bdftr WITH (NOLOCK)
		   JOIN DWH..Dim_Customer dc WITH (NOLOCK) ON bdftr.CID=dc.RealCID AND dc.IsValidCustomer=1
		   JOIN DWH..Dim_Country dc1 WITH (NOLOCK) ON dc.CountryID = dc1.CountryID
		   JOIN DWH..Dim_Channel dc2 WITH (NOLOCK) ON dc.SubChannelID = dc2.SubChannelID --AND dc2.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
		   WHERE YEAR(bdftr.Date)>=2022
		   GROUP BY CONVERT(VARCHAR(7),bdftr.Date,126), dc.AffiliateID, dc1.Name, dc2.Channel, dc2.SubChannel) i 
ON main.AffiliateID=i.AffiliateID AND main.YearMonth=i.YearMonth AND main.CountryName=i.Country AND main.Channel=i.Channel AND
   main.SubChannel=i.SubChannel
LEFT JOIN (SELECT dc.AffiliateID,
                  CONVERT(VARCHAR(7),dc.FirstDepositDate,126) YearMonth,
				  dc2.Name Country,
				  dc1.Channel,
				  dc1.SubChannel,
                  SUM(panel.IsFunded_New) Funded30d,
				  SUM(CASE WHEN panel.Equity<=200 THEN 1 END) EquityLess20030d
           FROM DWH..Dim_Customer dc WITH (NOLOCK)
		   JOIN DWH..Dim_Channel dc1 WITH (NOLOCK) ON dc.SubChannelID = dc1.SubChannelID --AND dc1.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
		   JOIN DWH..Dim_Country dc2 WITH (NOLOCK) ON dc.CountryID = dc2.CountryID
		   JOIN BI_DB..BI_DB_CID_DailyPanel_FullData panel WITH (NOLOCK) ON panel.CID=dc.RealCID AND DATEDIFF(DAY,CAST(dc.FirstDepositDate AS DATE),panel.ActiveDate)=30
		   WHERE dc.IsValidCustomer=1 AND YEAR(dc.FirstDepositDate)>=2022
		   GROUP BY dc.AffiliateID, CONVERT(VARCHAR(7),dc.FirstDepositDate,126),dc2.Name, dc1.Channel, dc1.SubChannel) j
ON main.YearMonth=j.YearMonth AND main.AffiliateID=j.AffiliateID AND main.CountryName=j.Country AND main.Channel=j.Channel
   AND main.SubChannel=j.SubChannel
LEFT JOIN (SELECT CONVERT(VARCHAR(7),bdc.FTDdate,126) YearMonth, bdc.AffiliateID, bdc.Country, bdc.Channel, bdc.SubChannel,
				  SUM(bdc.Revenue_Total) RevForCostReturn
           FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData bdc
		   WHERE YEAR(bdc.FTDdate)>=2022
		     --AND bdc.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
		   GROUP BY CONVERT(VARCHAR(7),bdc.FTDdate,126), bdc.AffiliateID, bdc.Country, bdc.Channel, bdc.SubChannel) m 
ON m.YearMonth=main.YearMonth AND main.AffiliateID=m.AffiliateID AND main.CountryName=m.Country AND main.Channel=m.Channel
   AND main.SubChannel=m.SubChannel
LEFT JOIN DWH..Dim_Affiliate da WITH (NOLOCK) ON main.AffiliateID=da.AffiliateID
LEFT JOIN DWH..Dim_Country dc WITH (NOLOCK) ON da.CountryID = dc.CountryID
LEFT JOIN (SELECT CONVERT(VARCHAR(7),bdcm.ActiveDate,126) YearMonth,
                  bdcm.AffiliateID,
				  bdcm.Country,
				  bdcm.Channel,
				  bdcm.SubChannel,
				  SUM(bdcm.Revenue_Total) Revenue_Total
           FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData bdcm WITH (NOLOCK)
		   WHERE YEAR(bdcm.ActiveDate)>=2022
		     --AND bdcm.Channel IN ('Affiliate','SEM','Mobile Acquisition','Media Programmatic','Media Performance','Content Partnerships','SEO')
		   GROUP BY CONVERT(VARCHAR(7),bdcm.ActiveDate,126), bdcm.AffiliateID,bdcm.Country,bdcm.Channel,bdcm.SubChannel) rev 
ON rev.YearMonth=main.YearMonth AND main.AffiliateID=rev.AffiliateID AND main.CountryName=rev.Country AND main.Channel=rev.Channel
   AND main.SubChannel=rev.SubChannel
LEFT JOIN (SELECT bdc.SerialID AffiliateID,
				  bdc.Country,
				  bdc.Channel,
				  bdc.SubChannel,
				  SUM(CASE WHEN scl.Cluster IN ('1','2','3') THEN bdlp.Revenue8Y_LTV_New END) LTV_LeadScore_Low,
				  SUM(CASE WHEN scl.Cluster IN ('4','5','6') THEN bdlp.Revenue8Y_LTV_New END) LTV_LeadScore_Mid,
				  SUM(CASE WHEN scl.Cluster IN ('7','8','9','10') THEN bdlp.Revenue8Y_LTV_New END) LTV_LeadScore_High,
				  COUNT(CASE WHEN scl.Cluster IN ('1','2','3') THEN scl.RealCID END) Users_LeadScore_Low,
				  COUNT(CASE WHEN scl.Cluster IN ('4','5','6') THEN scl.RealCID END) Users_LeadScore_Mid,
				  COUNT(CASE WHEN scl.Cluster IN ('7','8','9','10') THEN scl.RealCID END) Users_LeadScore_High
           FROM BI_DB..BI_DB_KYC_Score_CID_Level scl WITH (NOLOCK)
		   JOIN BI_DB..BI_DB_CIDFirstDates bdc WITH (NOLOCK) ON scl.RealCID=bdc.CID AND bdc.FirstDepositDate IS NOT NULL
           JOIN BI_DB..BI_DB_LTV_BI_Actual bdlp WITH (NOLOCK) ON scl.RealCID = bdlp.CID AND bdlp.Revenue8Y_LTV_New IS NOT NULL
           WHERE CAST(bdlp.FirstDepositDate AS DATE) >=DATEADD(MONTH,-7,CAST(CONCAT(CONVERT(VARCHAR(7),GETDATE(),126),'-01') AS DATE)) AND scl.Cluster!='No Cluster'
           GROUP BY bdc.SerialID, bdc.Country, bdc.Channel, bdc.SubChannel) LeadScore_LTV
ON main.AffiliateID=LeadScore_LTV.AffiliateID AND main.CountryName=LeadScore_LTV.Country AND main.Channel=LeadScore_LTV.Channel AND main.SubChannel=LeadScore_LTV.SubChannel