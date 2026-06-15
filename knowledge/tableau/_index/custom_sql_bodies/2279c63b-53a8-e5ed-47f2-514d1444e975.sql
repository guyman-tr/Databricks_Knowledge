SELECT ISNULL(dcem.DateID, ddst.DateID) AS DateID,
       ISNULL(dcem.Date, ddst.Date) AS Date,
       ISNULL(dcem.HedgeServerID, ddst.HedgeServerID) AS HedgeServerID,
	   ISNULL(dcem.TranType, ddst.TranType) AS TranType,
	   ISNULL(dcem.InstrumentID, ddst.InstrumentID) AS InstrumentID,
	   ISNULL(dcem.Instrument, ddst.Instrument) AS InstrumentName,
	   di.Exchange,
	   ISNULL(dcem.IsBuy, ddst.IsBuy) AS IsBuy,
	   ISNULL(dcem.LiquidityAccountID, ddst.LiquidityAccountID) AS LiquidityAccountID,
	   ddst.InstrumentType,
	   ddst.NOP_Units,
	   ddst.NOP,
	   dcem.Volume,
	   dcem.Units as Volume_Units
FROM Dealing_dbo.Dealing_NOP_LPandClients ddst
FULL OUTER JOIN Dealing_dbo.Dealing_CEP_ExecutionMonitoring dcem
ON ddst.DateID = dcem.DateID AND ddst.InstrumentID = dcem.InstrumentID AND ddst.HedgeServerID = dcem.HedgeServerID 
AND ddst.TranType = dcem.TranType AND ddst.IsBuy = dcem.IsBuy
AND ISNULL(ddst.LiquidityAccountID,0)= ISNULL(dcem.LiquidityAccountID,0)
JOIN DWH_dbo.Dim_Instrument di
ON ISNULL(ddst.InstrumentID, dcem.InstrumentID) = di.InstrumentID
WHERE ISNULL(dcem.DateID, ddst.DateID)>20240101
AND ISNULL(dcem.TranType, ddst.TranType) IN ('Clients', 'LP')
AND ISNULL(dcem.Success,1)=1