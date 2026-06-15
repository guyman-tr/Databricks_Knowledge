SELECT a.*,
b.InstrumentDisplayName
FROM Dealing.dbo.Dealing_CommodityCircuitBreakers a WITH (NOLOCK)
JOIN DWH.dbo.Dim_Instrument b WITH (NOLOCK)
ON a.InstrumentID = b.InstrumentID