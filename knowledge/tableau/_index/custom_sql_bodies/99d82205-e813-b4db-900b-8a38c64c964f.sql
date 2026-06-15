SELECT  eomonth(efrr.[etoro - ModificationDate]) AS EOM
       ,CAST(efrr.[etoro - ModificationDate] AS Date) AS [Date]
       ,efrr.CryptoName
       ,efrr.[eToro - AmountOnCloseUSD] AS [Gross_AmountOnClose_USD]
       ,efrr.[etoro - RedeemAmount] AS [Gross_Units]
       ,efrr.[eToro - AmountOnCloseUSD] / efrr.[etoro - RedeemAmount] AS [Gross_Rate]
       ,efrr.[etoro - RedeemFee] AS [Redeem_Fee]
       ,efrr.[etoro - BlockchainFee] AS [BlockChain_Fee]
       ,efrr.[etoro - Amount] AS [Net_Amount_USD]
       ,efrr.[etoro - RedeemAmount] - efrr.[etoro - RedeemFee] - efrr.[etoro - BlockchainFee] AS [Net_Units_Check]
       ,efrr.[etoro - Amount] / (efrr.[etoro - RedeemAmount] - efrr.[etoro - RedeemFee] - efrr.[etoro - BlockchainFee]) AS [Net_Rate]
       ,efrr.[eToro - AmountOnCloseUSD] - efrr.[etoro - Amount] AS 'Transfer Fee USD'
    
       ,efrr.[etoro - CID] AS CID
       ,efrr.[Wallet - RequestingGCID] AS GCID
       ,fsc.RegulationID
       ,dr.Name AS Regulation
       ,fsc.CountryID
       ,dc.Name AS Country
	   , ewe.WalletEntity
	   ,euswa.UserWalletAllowance
FROM EXW_dbo.EXW_RedeemReconciliation efrr
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
    ON fsc.RealCID = efrr.[etoro - CID]
JOIN DWH_dbo.Dim_Range dd
    ON dd.DateRangeID = fsc.DateRangeID 
    AND efrr.[etoro - ModificationDateID] BETWEEN dd.FromDateID AND dd.ToDateID
JOIN DWH_dbo.Dim_Regulation dr
    ON fsc.RegulationID = dr.DWHRegulationID
JOIN DWH_dbo.Dim_Country dc
    ON fsc.CountryID = dc.CountryID
LEFT JOIN EXW_dbo.EXW_WalletEntity ewe
ON efrr.[Wallet - RequestingGCID] = ewe.GCID
AND ewe.DateID =efrr.[etoro - ModificationDateID]
LEFT JOIN EXW_dbo.EXW_UserSettingsWalletAllowance euswa
ON efrr.[Wallet - RequestingGCID]= euswa.GCID
WHERE CAST(efrr.[etoro - ModificationDate] AS Date) >= <[Parameters].[Parameter 1]>

AND dc.Name  = <[Parameters].[Parameter 2]>
 
AND efrr.[etoro - RedeemStatus] = 'TransactionDone'
AND efrr.EntryAppears = 'BothSidesEntry'