SELECT bdtfr.Date,
    bdtfr.InstrumentID,
    bdtfr.ErrorCode,
    bdtfr.Regulation,
    bdtfr.Copy_Manual, 
    bdtfr.Type, 
    SUM(bdtfr.Orders_Positions) AS NumberOfTransactions
FROM BI_DB_dbo.BI_DB_Trading_Failures_Risk bdtfr
GROUP BY Date,
    bdtfr.InstrumentID,
    bdtfr.ErrorCode,
    bdtfr.Regulation,
    bdtfr.Copy_Manual, 
    bdtfr.Type