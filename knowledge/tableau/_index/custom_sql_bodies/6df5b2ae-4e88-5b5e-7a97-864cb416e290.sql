SELECT dd.CalendarYear
        ,dd.CalendarYearMonth
		,dd.FullDate
		,gs.GuruStatusName
		,di.InstrumentType
		,di.InstrumentDisplayName
		,sac.Symbol
                ,sac.RealCID
,dc.CountryID
  FROM [BI_DB].[dbo].[BI_DB_Social_Activity_Instrument_Feed] sac WITH (NOLOCK)
  INNER JOIN [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
  ON sac.RealCID = dc.RealCID
  INNER JOIN DWH.dbo.Dim_GuruStatus gs WITH (NOLOCK)
  ON dc.GuruStatusID = gs.GuruStatusID
  INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
  ON sac.ActionDateID = dd.DateKey
  INNER JOIN [DWH].[dbo].[Dim_Instrument] di WITH (NOLOCK)
  ON sac.InstrumentID = di.InstrumentID