SELECT sp.*, di.Exchange
FROM Dealing.dbo.Dealing_ONFee_Positions sp WITH (NOLOCK)
JOIN DWH.dbo.Dim_Instrument di WITH (NOLOCK)
ON sp.InstrumentID = di.InstrumentID