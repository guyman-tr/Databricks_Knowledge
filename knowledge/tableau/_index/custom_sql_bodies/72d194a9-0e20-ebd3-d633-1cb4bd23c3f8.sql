SELECT bdmdrd.AffiliateID,
       bdmdrd.CountryID,
	   bdmdrd.Date,
	   bdmdrd.DateID,
	   bdmdrd.CountryName, 
	   bdmdrd.Region,
	   bdmdrd.Desk,
	   bdmdrd.Channel,
	   bdmdrd.SubChannel,
	   bdmdrd.[Organic/Paid],
	   bdmdrd.Contact,
	   bdmdrd.ContractName,
	   bdmdrd.ContractType,
	   bdmdrd.AffiliatesGroupsName,
	   SUM(bdmdrd.TotalCost) TotalCost,
	   SUM(bdmdrd.RevShare_Comm) RevShare_Comm,
	   SUM(bdmdrd.CPA_Comm) CPA_Comm,
	   SUM(bdmdrd.CPL_Comm) CPL_Comm,
	   SUM(bdmdrd.RAF_Comm) RAF_Comm,
	   SUM(bdmdrd.eCost) eCost,
	   SUM(bdmdrd.Registration) Registration,
	   SUM(bdmdrd.FTD) FTD,
	   SUM(bdmdrd.EFTD) EFTD,
	   SUM(bdmdrd.FTDA) FTDA,
	   SUM(bdmdrd.NetRevenues) NetRevenues,
	   SUM(bdmdrd.VerificationLevelID2) VerificationLevelID2,
	   SUM(bdmdrd.VerificationLevelID3) VerificationLevelID3,
	   SUM(bdmdrd.TotalDeposit) TotalDeposit,
	   SUM(bdmdrd.Redeposits) Redeposits,
	   AVG(bdmdrd.LTV_NoExtreme) LTV_NoExtreme,
	   SUM(bdmdrd.GLTV) GLTV,
	   SUM(bdmdrd.FTDfromLTV) FTDfromLTV,
	   SUM(bdmdrd.PastGRevenue) PastGRevenue,
	   SUM(bdmdrd.SameDayFTD) SameDayFTD,
	   a.FTDE_Amount,
	   MAX(bdmdrd.UpdateDate) UpdateDate,
	   SUM(cost.Relative_eCost) Relative_eCost
FROM [BI_DB_dbo].BI_DB_MarketingDailyRawData bdmdrd 
LEFT JOIN 
         (SELECT bdac.AffiliateID, bdac.FTD_Date Date, bdac.DB_CountryID,SUM(bdac.FirstDepositAmount) FTDE_Amount
          FROM [BI_DB_dbo].BI_DB_AffiliateCOAbuse bdac
          WHERE bdac.AW_CPA>0
          GROUP BY bdac.AffiliateID,bdac.FTD_Date, bdac.DB_CountryID) a
ON bdmdrd.AffiliateID=a.AffiliateID AND bdmdrd.CountryID=a.DB_CountryID AND bdmdrd.Date=a.Date

--Manually added in
LEFT JOIN (SELECT presentageFTD.AffiliateID, presentageFTD.[DateID], presentageFTD.CountryName, presentageFTD.Channel, presentageFTD.SubChannel,
                  presentageFTD.FTD_Ratio*ecost.eCost Relative_eCost
           FROM (SELECT b1.AffiliateID, b1.[DateID],b1.CountryName, b1.Channel, b1.SubChannel, SUM(b1.eCost)ecost,SUM(b1.FTD)FTD,
		                SUM(b1.FTD)*1.0/(SELECT SUM(b2.FTD)FTD 
                                         FROM [BI_DB_dbo].BI_DB_MarketingDailyRawData b2 
              		                     WHERE b2.[DateID]=b1.[DateID]
              			                   AND b2.AffiliateID=b1.AffiliateID) FTD_Ratio
                 FROM [BI_DB_dbo].BI_DB_MarketingDailyRawData b1
                 WHERE b1.[DateID]>=202101 AND b1.Channel='Affiliate'
                 GROUP BY b1.AffiliateID, b1.[DateID],b1.CountryName, b1.Channel, b1.SubChannel) presentageFTD
           LEFT JOIN (SELECT bd.AffiliateID,bd.[DateID], SUM(bd.eCost)eCost
                      FROM [BI_DB_dbo].BI_DB_MarketingDailyRawData bd 
                      WHERE bd.Region='Unknown' AND bd.Channel='Affiliate' AND bd.[DateID]>=202101
                      GROUP BY bd.AffiliateID,bd.[DateID]) ecost ON ecost.[DateID]=presentageFTD.[DateID] AND ecost.AffiliateID=presentageFTD.AffiliateID) cost
ON bdmdrd.[DateID]=cost.[DateID] AND bdmdrd.AffiliateID=cost.AffiliateID AND bdmdrd.CountryName=cost.CountryName AND bdmdrd.Channel=cost.Channel
   AND bdmdrd.SubChannel=cost.SubChannel

WHERE bdmdrd.Date>='2023-01-01' --AND bdmdrd.Channel IN ('Affiliate','Introducing Agents','Mobile Acquisition','Media')
GROUP BY bdmdrd.AffiliateID,
       bdmdrd.CountryID,
	   bdmdrd.Date,
	   bdmdrd.DateID,
	   bdmdrd.CountryName, 
	   bdmdrd.Region,
	   bdmdrd.Desk,
	   bdmdrd.Channel,
	   bdmdrd.SubChannel,
	   bdmdrd.[Organic/Paid],
	   bdmdrd.Contact,
	   bdmdrd.ContractName,
	   bdmdrd.ContractType,
	   bdmdrd.AffiliatesGroupsName,
	   a.FTDE_Amount