SELECT di.InstrumentID
      ,di.InstrumentDisplayName
      ,di.InstrumentType
	  ,di.Symbol
FROM [DWH].[dbo].[Dim_Instrument] di WITH (NOLOCK)