SELECT dp.CID
      ,di.InstrumentType
      ,di.PlatformSector
	  ,di.PlatformIndustry
	  ,di.InstrumentDisplayName
      ,Amount  InvestedAmount
	  ,dp.Volume Volume
          ,Leverage
          ,IsBuy
FROM [DWH].[dbo].[Dim_Position] dp WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Instrument] di WITH (NOLOCK)
ON dp.InstrumentID = di.InstrumentID
WHERE dp.CloseDateID = 0
AND dp.CID=<[Parameters].[Parameter 1]>