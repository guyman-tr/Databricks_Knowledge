SELECT q0.CalendarYearMonth
	  ,q0.FullDate
	  ,q0.Region
	  ,q0.InstrumentType
	  ,q0.Club
	  ,q0.ExchangeCountry
	  ,q0.IsSettled
	  ,SUM(q0.Volume       ) Volume
	  ,SUM(q0.Transactions ) Transactions
	  ,SUM(q0.Commission   ) Commission
	  ,SUM(q0.RolloverFee  ) RolloverFee 
FROM 
(
SELECT dd.CalendarYearMonth
      ,MIN(dd.FullDate) FullDate
      ,dc1.MarketingRegionManualName Region
	  ,di.InstrumentType
	  ,dpl.Name Club
      ,CASE WHEN di.Exchange IN ('Bolsa De Madrid','Euronext Lisbon') THEN 'Spain'
			WHEN di.Exchange = 'Borsa Italiana' THEN 'Italian'
			WHEN di.Exchange = 'LSE' THEN 'UK'
			WHEN di.Exchange IN ('Chicago Board Options Exchange','Extended Hours Trading','NYSE','Nasdaq','OTC Markets Stock Exchange') THEN 'USA'
			WHEN di.Exchange IN ('Copenhagen Stock Exchange','Euronext Lisbon','Helsinki Stock Exchange','Oslo Stock Exchange','Stockholm  Stock Exchange') THEN 'Nordics'
			WHEN di.Exchange IN ('Euronext Brussels','Euronext Paris') THEN 'French'
			WHEN di.Exchange IN ('FRA','SIX') THEN 'German'
			WHEN di.Exchange IN ('Hong Kong Exchanges') THEN 'SEA'
			WHEN di.Exchange IN ('Sydney') THEN 'Australia'
			WHEN di.Exchange IN ('Tadawul') THEN 'Arabic'
			WHEN di.Exchange IN ('CFD','Digital Currency','Commodity','FX') THEN 'No Exchange'
			ELSE 'Others' END ExchangeCountry
	  ,dp.IsSettled
	  ,SUM(CONVERT(BIGINT,dp.VolumeOnClose)) Volume
      ,COUNT(*) Transactions
	  ,0 Commission
	  ,0 RolloverFee
FROM [DWH_dbo].[Dim_Position] dp WITH (NOLOCK)
INNER JOIN [DWH_dbo].[Dim_Instrument] di WITH (NOLOCK)
ON dp.InstrumentID = di.InstrumentID
INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
ON dp.CID = dc.RealCID
INNER JOIN [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
ON dp.CloseDateID = dd.DateKey
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE dd.DateKey >= 20230101
AND IsValidCustomer = 1
GROUP BY dc1.MarketingRegionManualName 
      ,dd.CalendarYearMonth
	  ,di.InstrumentType
	  ,dpl.Name 
      ,CASE WHEN di.Exchange IN ('Bolsa De Madrid','Euronext Lisbon') THEN 'Spain'
			WHEN di.Exchange = 'Borsa Italiana' THEN 'Italian'
			WHEN di.Exchange = 'LSE' THEN 'UK'
			WHEN di.Exchange IN ('Chicago Board Options Exchange','Extended Hours Trading','NYSE','Nasdaq','OTC Markets Stock Exchange') THEN 'USA'
			WHEN di.Exchange IN ('Copenhagen Stock Exchange','Euronext Lisbon','Helsinki Stock Exchange','Oslo Stock Exchange','Stockholm  Stock Exchange') THEN 'Nordics'
			WHEN di.Exchange IN ('Euronext Brussels','Euronext Paris') THEN 'French'
			WHEN di.Exchange IN ('FRA','SIX') THEN 'German'
			WHEN di.Exchange IN ('Hong Kong Exchanges') THEN 'SEA'
			WHEN di.Exchange IN ('Sydney') THEN 'Australia'
			WHEN di.Exchange IN ('Tadawul') THEN 'Arabic'
			WHEN di.Exchange IN ('CFD','Digital Currency','Commodity','FX') THEN 'No Exchange'
			ELSE 'Others' END
	  ,dp.IsSettled
UNION all
SELECT dd.CalendarYearMonth
      ,MIN(dd.FullDate) FullDate
      ,dc1.MarketingRegionManualName Region
	  ,di.InstrumentType
	  ,dpl.Name Club
      ,CASE WHEN di.Exchange IN ('Bolsa De Madrid','Euronext Lisbon') THEN 'Spain'
			WHEN di.Exchange = 'Borsa Italiana' THEN 'Italian'
			WHEN di.Exchange = 'LSE' THEN 'UK'
			WHEN di.Exchange IN ('Chicago Board Options Exchange','Extended Hours Trading','NYSE','Nasdaq','OTC Markets Stock Exchange') THEN 'USA'
			WHEN di.Exchange IN ('Copenhagen Stock Exchange','Euronext Lisbon','Helsinki Stock Exchange','Oslo Stock Exchange','Stockholm  Stock Exchange') THEN 'Nordics'
			WHEN di.Exchange IN ('Euronext Brussels','Euronext Paris') THEN 'French'
			WHEN di.Exchange IN ('FRA','SIX') THEN 'German'
			WHEN di.Exchange IN ('Hong Kong Exchanges') THEN 'SEA'
			WHEN di.Exchange IN ('Sydney') THEN 'Australia'
			WHEN di.Exchange IN ('Tadawul') THEN 'Arabic'
			WHEN di.Exchange IN ('CFD','Digital Currency','Commodity','FX') THEN 'No Exchange'
			ELSE 'Others' END ExchangeCountry
	  ,dp.IsSettled
	  ,SUM(CONVERT(BIGINT,dp.Volume)) Volume
      ,COUNT(CASE WHEN ISNULL(dp.IsPartialCloseChild,0) = 0 THEN dp.PositionID END) Transactions
	  ,0 Commission
	  ,0 RolloverFee
FROM [DWH_dbo].[Dim_Position] dp WITH (NOLOCK)
INNER JOIN [DWH_dbo].[Dim_Instrument] di WITH (NOLOCK)
ON dp.InstrumentID = di.InstrumentID
INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
ON dp.CID = dc.RealCID
INNER JOIN [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
ON dp.OpenDateID = dd.DateKey
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE dd.DateKey >=20230101
AND IsValidCustomer = 1
GROUP BY dc1.MarketingRegionManualName
      ,dd.CalendarYearMonth
	  ,di.InstrumentType
	  ,dpl.Name
      ,CASE WHEN di.Exchange IN ('Bolsa De Madrid','Euronext Lisbon') THEN 'Spain'
			WHEN di.Exchange = 'Borsa Italiana' THEN 'Italian'
			WHEN di.Exchange = 'LSE' THEN 'UK'
			WHEN di.Exchange IN ('Chicago Board Options Exchange','Extended Hours Trading','NYSE','Nasdaq','OTC Markets Stock Exchange') THEN 'USA'
			WHEN di.Exchange IN ('Copenhagen Stock Exchange','Euronext Lisbon','Helsinki Stock Exchange','Oslo Stock Exchange','Stockholm  Stock Exchange') THEN 'Nordics'
			WHEN di.Exchange IN ('Euronext Brussels','Euronext Paris') THEN 'French'
			WHEN di.Exchange IN ('FRA','SIX') THEN 'German'
			WHEN di.Exchange IN ('Hong Kong Exchanges') THEN 'SEA'
			WHEN di.Exchange IN ('Sydney') THEN 'Australia'
			WHEN di.Exchange IN ('Tadawul') THEN 'Arabic'
			WHEN di.Exchange IN ('CFD','Digital Currency','Commodity','FX') THEN 'No Exchange'
			ELSE 'Others' END
	  ,dp.IsSettled
UNION ALL
SELECT dd.CalendarYearMonth
      ,MIN(dd.FullDate) FullDate
	  ,bddcria.Region 
	  ,bddcria.InstrumentType
	  ,bddcria.Club
	  ,CASE WHEN di.Exchange IN ('Bolsa De Madrid','Euronext Lisbon') THEN 'Spain'
			WHEN di.Exchange = 'Borsa Italiana' THEN 'Italian'
			WHEN di.Exchange = 'LSE' THEN 'UK'
			WHEN di.Exchange IN ('Chicago Board Options Exchange','Extended Hours Trading','NYSE','Nasdaq','OTC Markets Stock Exchange') THEN 'USA'
			WHEN di.Exchange IN ('Copenhagen Stock Exchange','Euronext Lisbon','Helsinki Stock Exchange','Oslo Stock Exchange','Stockholm  Stock Exchange') THEN 'Nordics'
			WHEN di.Exchange IN ('Euronext Brussels','Euronext Paris') THEN 'French'
			WHEN di.Exchange IN ('FRA','SIX') THEN 'German'
			WHEN di.Exchange IN ('Hong Kong Exchanges') THEN 'SEA'
			WHEN di.Exchange IN ('Sydney') THEN 'Australia'
			WHEN di.Exchange IN ('Tadawul') THEN 'Arabic'
			WHEN di.Exchange IN ('CFD','Digital Currency','Commodity','FX') THEN 'No Exchange'
			ELSE 'Others' END ExchangeCounty
	  ,bddcria.IsSettled
	  ,0 Volume
	  ,0 Transactions
	  ,SUM(bddcria.FullCommissions) Commission
	  ,SUM(bddcria.RollOverFee) RolloverFee
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg bddcria
INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
ON bddcria.DateID = dd.DateKey
INNER JOIN [DWH_dbo].[Dim_Instrument] di WITH (NOLOCK)
ON bddcria.InstrumentID = di.InstrumentID
WHERE dd.DateKey >=20230101
AND bddcria.IsValidCustomer = 1
GROUP BY dd.CalendarYearMonth
	  ,bddcria.Region 
	  ,bddcria.InstrumentType
	  ,bddcria.Club
	  ,CASE WHEN di.Exchange IN ('Bolsa De Madrid','Euronext Lisbon') THEN 'Spain'
			WHEN di.Exchange = 'Borsa Italiana' THEN 'Italian'
			WHEN di.Exchange = 'LSE' THEN 'UK'
			WHEN di.Exchange IN ('Chicago Board Options Exchange','Extended Hours Trading','NYSE','Nasdaq','OTC Markets Stock Exchange') THEN 'USA'
			WHEN di.Exchange IN ('Copenhagen Stock Exchange','Euronext Lisbon','Helsinki Stock Exchange','Oslo Stock Exchange','Stockholm  Stock Exchange') THEN 'Nordics'
			WHEN di.Exchange IN ('Euronext Brussels','Euronext Paris') THEN 'French'
			WHEN di.Exchange IN ('FRA','SIX') THEN 'German'
			WHEN di.Exchange IN ('Hong Kong Exchanges') THEN 'SEA'
			WHEN di.Exchange IN ('Sydney') THEN 'Australia'
			WHEN di.Exchange IN ('Tadawul') THEN 'Arabic'
			WHEN di.Exchange IN ('CFD','Digital Currency','Commodity','FX') THEN 'No Exchange'
			ELSE 'Others' END
	  ,bddcria.IsSettled
	  )q0
	  GROUP BY q0.CalendarYearMonth
	  ,q0.FullDate
	  ,q0.Region
	  ,q0.InstrumentType
	  ,q0.Club
	  ,q0.ExchangeCountry
	  ,q0.IsSettled