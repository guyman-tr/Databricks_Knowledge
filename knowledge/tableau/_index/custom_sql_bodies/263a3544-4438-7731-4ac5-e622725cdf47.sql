SELECT bdmmrd.AffiliateID,
	         bdmmrd.YearMonth,
	         bdmmrd.YearMonthID,
	         bdmmrd.CountryName, 
	         bdmmrd.NewMarketingRegion Region,
	         bdmmrd.Channel,
	         bdmmrd.SubChannel,
			 bdmmrd.Funnel,
	         SUM(bdmmrd.RevShare_Comm) RevShare_Comm,
	         SUM(bdmmrd.CPA_Comm) CPA_Comm,
			 SUM(bdmmrd.eCost)eCost,
			 SUM(Lead_Comm)Lead_Comm,
	         SUM(bdmmrd.CPL_Comm) CPL_Comm,
	         SUM(bdmmrd.RAF_Comm) RAF_Comm,
			 SUM(bdmmrd.Chargebacks)Chargebacks,
			 SUM(bdmmrd.TotalCost) TotalCost,
	         SUM(bdmmrd.Registration) Registration,
	         SUM(bdmmrd.FTD) FTD,
	         SUM(bdmmrd.EFTD) EFTD,
	         SUM(bdmmrd.FTDA) FTDA,
	         SUM(bdmmrd.NetRevenues) NetRevenues,
	         SUM(bdmmrd.VerificationLevelID2) VerificationLevelID2,
	         SUM(bdmmrd.VerificationLevelID3) VerificationLevelID3,
	         SUM(bdmmrd.Installs) Installs
      FROM BI_DB_dbo.BI_DB_MarketingMonthlyRawData bdmmrd WITH (NOLOCK)
	  WHERE bdmmrd.YearMonthID>='202201' 
      GROUP BY bdmmrd.AffiliateID,
      	       bdmmrd.YearMonth,
      	       bdmmrd.YearMonthID,
      	       bdmmrd.CountryName, 
      	       bdmmrd.NewMarketingRegion,
      	       bdmmrd.Channel,
      	       bdmmrd.SubChannel,
			   bdmmrd.Funnel