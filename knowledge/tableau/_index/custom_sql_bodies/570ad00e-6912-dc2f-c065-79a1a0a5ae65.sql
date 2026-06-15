SELECT  dc.Name 'Country'
       ,bddfmap.MIMOPlatform
	   ,bddfmap.IsInternalTransfer
	   ,bddfmap.IsTradeFromIBAN
       ,dc2.Abbreviation'Currency'
       ,CASE WHEN bddfmap.MIMOPlatform='eMoney' AND bddfmap.IsInternalTransfer=0 AND bddfmap.IsTradeFromIBAN=0 
	    THEN o.Fundingtype_Txtype_7 ELSE dft.Name END AS MOP
       ,bddfmap.Date AS ModificationDate
       ,EOMONTH(bddfmap.Date) AS 'EOM'
       ,'Deposit' AS 'Ind'
       ,bddfmap.IsPlatformFTD AS IsFTD
       ,dpl.Name 'Club'
       ,dr1.Name 'Regulation'
       ,dc.MarketingRegionManualName
      ,SUM(bddfmap.AmountUSD) AmountUSD     
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms bddfmap 

INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON bddfmap.RealCID=fsc.RealCID AND fsc.IsValidCustomer=1
INNER JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID
INNER JOIN DWH_dbo.Dim_Currency dc2 ON bddfmap.CurrencyID = dc2.CurrencyID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID

INNER JOIN DWH_dbo.Dim_FundingType dft ON bddfmap.FundingTypeID = dft.FundingTypeID
--LEFT JOIN  BI_DB_dbo.BI_DB_DepositWithdrawFee bddwf ON bddfmap.TransactionID=bddwf.DepositWithdrawID 
--AND bddwf.TransactionType='Deposit'
LEFT JOIN 
(SELECT mdt.TransactionID
      ,CASE WHEN p.CID IS NOT NULL THEN 'OpenBanking' ELSE 'WireTransfer' END AS Fundingtype_Txtype_7
FROM eMoney_dbo.eMoney_Dim_Transaction mdt
LEFT JOIN BI_DB_dbo.External_MoneyTransfer_Billing_Transfers p ON LOWER(p.ExReferenceID) = LOWER(mdt.ReferenceNumber) AND p.TransferStatusID=10
WHERE  mdt.TxCreatedDateID>=20240101
) o ON o.TransactionID=bddfmap.TransactionID
WHERE bddfmap.DateID>=20240101 
AND bddfmap.MIMOAction='Deposit'
GROUP BY 
        dc.Name 
	    ,bddfmap.MIMOPlatform
	   ,bddfmap.IsInternalTransfer
	   ,bddfmap.IsTradeFromIBAN
       ,dc2.Abbreviation
       ,CASE WHEN bddfmap.MIMOPlatform='eMoney' AND bddfmap.IsInternalTransfer=0 AND bddfmap.IsTradeFromIBAN=0 
	    THEN o.Fundingtype_Txtype_7 ELSE dft.Name END 
       ,bddfmap.Date
       ,EOMONTH(bddfmap.Date) 
       --,'Deposit'
       ,bddfmap.IsPlatformFTD 
       ,dpl.Name 
       ,dr1.Name 
       ,dc.MarketingRegionManualName

UNION ALL


SELECT dc.Name 'Country'
       ,bddfmap.MIMOPlatform
	   ,bddfmap.IsInternalTransfer
	   ,bddfmap.IsTradeFromIBAN
       ,dc2.Abbreviation 'Currency'
       ,CASE WHEN bddfmap.MIMOPlatform='eMoney' AND bddfmap.IsInternalTransfer=0 AND bddfmap.IsTradeFromIBAN=0 
	    THEN 'WireTransfer' ELSE dft.Name END 
       ,bddfmap.Date  AS ModificationDate
       ,EOMONTH(bddfmap.Date) AS 'EOM'
       ,'CO' AS 'Ind'
       ,bddfmap.IsPlatformFTD AS IsFTD
       ,dpl.Name 'Club'
       ,dr1.Name 'Regulation'
       ,dc.MarketingRegionManualName
      ,SUM(bddfmap.AmountUSD) AmountUSD     
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms bddfmap 

INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON bddfmap.RealCID=fsc.RealCID AND fsc.IsValidCustomer=1
INNER JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID
INNER JOIN DWH_dbo.Dim_Currency dc2 ON bddfmap.CurrencyID = dc2.CurrencyID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID

INNER JOIN DWH_dbo.Dim_FundingType dft ON bddfmap.FundingTypeID = dft.FundingTypeID
--LEFT JOIN  BI_DB_dbo.BI_DB_DepositWithdrawFee bddwf 
--ON bddfmap.TransactionID=CAST(LEFT(bddwf.TransactionID, LEN(bddwf.TransactionID) - 1) AS BIGINT) 
--AND bddwf.TransactionType = 'Withdraw'
--LEFT JOIN DWH_dbo.Fact_BillingWithdraw fbw ON fbw.WithdrawID=bddfmap.TransactionID
WHERE bddfmap.DateID >= 20240101
AND bddfmap.MIMOAction = 'Withdraw'
--AND bddwf.PaymentMethod <>'eToroCryptoWallet'
GROUP BY  
        dc.Name 
	   ,bddfmap.MIMOPlatform
	   ,bddfmap.IsInternalTransfer
	   ,bddfmap.IsTradeFromIBAN
       ,dc2.Abbreviation
       ,dft.Name
       ,bddfmap.Date
       ,EOMONTH(bddfmap.Date) 
       --,'Deposit'
       ,bddfmap.IsPlatformFTD 
       ,dpl.Name 
       ,dr1.Name 
       ,dc.MarketingRegionManualName