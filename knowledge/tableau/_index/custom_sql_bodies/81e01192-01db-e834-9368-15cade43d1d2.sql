SELECT 
    Date_Month,
	Date_Week,
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
    Date_Month,
	Date_Week,
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