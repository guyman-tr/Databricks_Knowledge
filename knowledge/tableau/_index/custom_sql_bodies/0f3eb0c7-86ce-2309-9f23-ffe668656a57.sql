SELECT di.InstrumentID
	  ,di.InstrumentType
	  ,di.Name
	  ,di.IsMajor
	  ,di.InstrumentDisplayName Instrument
          ,PlatformSector
      ,PlatformIndustry 
,di.MKTcap
FROM [DWH].[dbo].[Dim_Instrument] di WITH (NOLOCK)