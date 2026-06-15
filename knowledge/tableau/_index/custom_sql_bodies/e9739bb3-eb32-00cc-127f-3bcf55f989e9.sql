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
	   bdmdrd.Funnel,
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
	   --SUM(bdmdrd.NetRevenues) NetRevenues,
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
	   MAX(bdmdrd.UpdateDate) UpdateDate	   
FROM BI_DB_dbo.BI_DB_MarketingDailyRawData bdmdrd 
LEFT JOIN 
         (SELECT bdac.AffiliateID, bdac.FTD_Date Date, bdac.DB_CountryID,SUM(bdac.FirstDepositAmount) FTDE_Amount
          FROM BI_DB_dbo.BI_DB_AffiliateCOAbuse bdac
          WHERE bdac.AW_CPA>0
          GROUP BY bdac.AffiliateID,bdac.FTD_Date, bdac.DB_CountryID) a
ON bdmdrd.AffiliateID=a.AffiliateID AND bdmdrd.CountryID=a.DB_CountryID AND bdmdrd.Date=a.Date
WHERE bdmdrd.Date>='2022-01-01'
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
	   a.FTDE_Amount,
	   bdmdrd.Funnel