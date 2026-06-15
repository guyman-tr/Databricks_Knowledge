--dwh 

SELECT 
      fbd.CID
     ,CAST (fbd.ModificationDate AS DATE) AS ModificationDate
	 ,CAST(DATEADD(DAY, 1, EOMONTH(fbd.ModificationDate, -1)) AS DATE) AS Month_
	 ,fbd.ModificationDateID
	 ,CAST(DATEADD(WEEK, DATEDIFF(WEEK, -1, fbd.ModificationDate), -1) AS DATE) AS Week_
	 ,dc.Name AS Country
     ,frst.NewMarketingRegion
     ,frst.Channel
     ,frst.SubChannel
     ,dft.Name AS FundingType
  ,fbd.DepositID
	 ,depo.Name AS 'Provider'
	 ,dr.Name AS Regulation
	 ,dc1.Abbreviation AS Currency
	 ,dps.Name AS PaymentStatus
	 ,SUM(CASE WHEN dps.Name = 'Approved' THEN 1 ELSE 0 END) AS Approved
     ,SUM(CASE WHEN dps.Name != 'Approved' THEN 1 ELSE 0 END) AS Declined
	 ,dct.CarTypeName
	 ,cbin.CardSubType
	 ,fbd.BinCodeAsString AS BIN
	 ,dc2.Name AS BIN_Country

	 ,fbd.BankName
	 ,fbd.Amount AS Amount_Origin_CYY
	 ,fbd.AmountUSD
	 ,CASE WHEN fbd.IsFTD  = 1 THEN 'FTD' WHEN fbd.IsFTD=0 THEN 'Redeposits' ELSE 'Error' END AS DepositType
	 ,COUNT(fbd.DepositID) AS _Try
  
FROM DWH_dbo.Fact_BillingDeposit fbd
LEFT JOIN DWH_dbo.Dim_BillingDepot depo  ON depo.DepotID = fbd.DepotID
LEFT JOIN DWH_dbo.Dim_FundingType dft ON fbd.FundingTypeID = dft.FundingTypeID 
JOIN DWH_dbo.Dim_Customer as dmc ON dmc.RealCID = fbd.CID
JOIN BI_DB_dbo.BI_DB_CIDFirstDates as frst ON frst.CID = fbd.CID
LEFT JOIN DWH_dbo.Dim_CountryBin cbin ON cbin.BinCode = fbd.BinCodeAsString
LEFT JOIN DWH_dbo.Dim_Country dc ON dmc.CountryID = dc.CountryID
LEFT JOIN DWH_dbo.Dim_Country dc2 ON fbd.BinCountryIDAsInteger = dc2.CountryID
LEFT JOIN DWH_dbo.Dim_Regulation dr ON dmc.RegulationID=dr.ID
LEFT JOIN DWH_dbo.Dim_Currency dc1 ON fbd.CurrencyID = dc1.CurrencyID
LEFT JOIN DWH_dbo.Dim_PaymentStatus dps ON fbd.PaymentStatusID = dps.PaymentStatusID
LEFT JOIN DWH_dbo.Dim_CardType dct ON fbd.CardTypeIDAsInteger=dct.CardTypeID

WHERE fbd.ModificationDateID>=20241006  
  AND dmc.IsValidCustomer=1
  and dmc.FirstDepositAmount != 1

  GROUP BY      
      fbd.CID
     ,CAST(fbd.ModificationDate AS DATE)
	 ,fbd.ModificationDateID
	 ,CAST(DATEADD(WEEK, DATEDIFF(WEEK, -1, fbd.ModificationDate), -1) AS DATE)
	 ,CAST(DATEADD(DAY, 1, EOMONTH(fbd.ModificationDate, -1)) AS DATE) 
	 ,dc.Name
     ,frst.NewMarketingRegion
     ,frst.Channel
     ,frst.SubChannel
     ,dft.Name
	  ,fbd.DepositID
	 ,depo.Name
	 ,dr.Name
	 ,dc1.Abbreviation
	 ,dps.Name
	 ,dct.CarTypeName
	 ,cbin.CardSubType
 	 ,fbd.BinCodeAsString
	 ,dc2.Name
	 ,fbd.BankName
	 ,fbd.Amount 
	 ,fbd.AmountUSD
	 ,CASE WHEN fbd.IsFTD=1  THEN 'FTD' WHEN fbd.IsFTD=0 THEN 'Redeposits' ELSE 'Error' END