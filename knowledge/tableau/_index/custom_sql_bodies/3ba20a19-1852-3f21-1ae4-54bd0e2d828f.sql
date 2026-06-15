SELECT 'Actual' TimeStamp
      ,dp.CID
      ,di.InstrumentType
      ,UPPER(di.PlatformSector  )PlatformSector
	  ,UPPER(di.PlatformIndustry)PlatformIndustry
	  ,di.InstrumentDisplayName
	  ,UPPER(di.Exchange       )Exchange
	  ,UPPER(di.ISINCountryCode)ISINCountryCode
      ,SUM(dp.Amount)  InvestedAmount
	  ,SUM(dp.Volume) Volume
      ,Leverage
      ,IsBuy
	  ,CASE WHEN dm.IsCopyFundMirror = 1 THEN 'CP'
	  WHEN dm.MirrorID IS NOT NULL THEN 'Copy'
	  ELSE 'Direct' END ActionType
FROM DWH_dbo.Dim_Position dp WITH (NOLOCK)
INNER JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK)
ON dp.InstrumentID = di.InstrumentID 
LEFT JOIN DWH_dbo.Dim_Mirror dm WITH (NOLOCK)
ON dp.MirrorID = dm.MirrorID AND dp.CID = dm.CID
WHERE dp.CloseDateID = 0 
Group by dp.CID, CASE WHEN dm.IsCopyFundMirror = 1 THEN 'CP'
	  WHEN dm.MirrorID IS NOT NULL THEN 'Copy'
	  ELSE 'Direct' END,Leverage
      ,IsBuy
	  ,di.InstrumentType
      ,di.PlatformSector 
	  ,di.PlatformIndustry
	  ,di.InstrumentDisplayName
	  ,di.Exchange
	  ,di.ISINCountryCode