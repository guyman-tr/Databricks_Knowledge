SELECT di.InstrumentID, di.Name, di.InstrumentDisplayName, fsp.SettlementDate, fsp.SettlementPrice
FROM DWH_dbo.Fact_Settlement_Prices fsp 
    JOIN DWH_dbo.Dim_Instrument di
        ON fsp.InstrumentID = di.InstrumentID
WHERE fsp.SettlementDate BETWEEN <[Parameters].[Parameter 2]>AND <[Parameters].[Parameter 3]>