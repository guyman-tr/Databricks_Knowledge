SELECT 
     CAST(CONVERT(char(8), DateID) AS DATE) AS Date_Day ,
	 (DATEPART(WEEKDAY, CAST(CONVERT(char(8), DateID) AS DATE)) + @@DATEFIRST - 1) % 7 + 1 AS Weekday,
    dn.InstrumentID, 
    Country, 
    NewMarketingRegion,
    Club,
    Channel,
    IsSettled,
    IsBuy,
    Leverage,
	inst.Exchange, 
    inst.InstrumentType, 
    inst.InstrumentDisplayName AS Instrument,
	SUM(Total_Positions) AS Positions,
	SUM(Total_Amount) as Amount,
	SUM(Total_Revenue) as Revenue

FROM #dn AS dn
JOIN DWH_dbo.Dim_Instrument as inst ON dn.InstrumentID = inst.InstrumentID

GROUP BY 
    CAST(CONVERT(char(8), DateID) AS DATE),
	(DATEPART(WEEKDAY, CAST(CONVERT(char(8), DateID) AS DATE)) + @@DATEFIRST - 1) % 7 + 1,
    dn.InstrumentID, 
    Country, 
    NewMarketingRegion,
    Club,
    Channel,
    IsSettled,
    IsBuy,
    Leverage,
	inst.Exchange, 
    inst.InstrumentType, 
    inst.InstrumentDisplayName