SELECT fd.CID
      ,bdfa.Channel
	  ,bdfa.SubChannel
	  ,bdfa.AffiliateID
	  ,da.Contact
	  ,fd.FunnelName
	  ,fd.FunnelFromName
	  ,CAST(fd.registered AS DATE) AS RegistrationDate
	  ,CAST(fd.FirstDepositDate AS DATE) AS FTDdate
          -- ,DATEADD(DAY, 1 - DATEPART(WEEKDAY, DATEADD(day, -1, cast(fd.FirstDepositDate as date))), DATEADD(day, -1, cast(fd.FirstDepositDate as date))) as FTDweekDate
          ,DATEADD(dd, -(DATEPART(dw, CAST(fd.FirstDepositDate AS DATE))-1), CAST(fd.FirstDepositDate AS DATE)) as FTDweekDate
	  ,fd.FirstDepositAmount AS FTDA
	  ,bdfa.FirstAction
          ,bdfa.FirstInstrument
          ,fd.Region
FROM dbo.BI_DB_CIDFirstDates AS fd
JOIN DWH.dbo.Dim_Affiliate AS da
ON da.AffiliateID = fd.SerialID
 JOIN dbo.BI_DB_First5Actions AS bdfa
ON fd.CID = bdfa.CID AND bdfa.FirstAction = 'Crypto'
WHERE CAST(fd.FirstDepositDate AS DATE) >= '20190101'