SELECT ISNULL(depl.Date, a.Date) AS Date
	  ,ISNULL(depl.HedgeServerID, a.HedgeServerID) AS HedgeServerID
	  ,ISNULL(depl.InstrumentID, a.InstrumentID) AS InstrumentID
	  ,ISNULL(depl.InstrumentType, a.InstrumentType) AS InstrumentType
	  ,ISNULL(depl.InstrumentDisplayName, a.InstrumentName) AS InstrumentName
	  ,ISNULL(SUM(depl.eToroPnL),0) AS eToroPnL
	  ,ISNULL(SUM(a.Zero),0) AS Zero
	  ,ISNULL(SUM(a.FullCommission),0) AS FullCommission
	  ,ISNULL(SUM(a.VariableSpread),0) AS VariableSpread
FROM Dealing.dbo.Dealing_EtoroPnL depl
LEFT JOIN
( 
SELECT  Date
	  ,HedgeServerID
	  ,InstrumentID
	  ,InstrumentType
	  ,InstrumentName
	  ,SUM(bddztsn.TotalZero) AS Zero
	  ,SUM(bddztsn.FullCommission) AS FullCommission
	  ,SUM(bddztsn.VariableSpread) AS VariableSpread
FROM Dealing.dbo.Dealing_DealingDashboard_Clients bddztsn
WHERE bddztsn.Date >= '2021-01-01'
GROUP BY  Date
	  ,HedgeServerID
	  ,InstrumentID
	  ,InstrumentType
	  ,InstrumentName) a
ON depl.HedgeServerID = a.HedgeServerID AND depl.InstrumentID = a.InstrumentID AND depl.Date = a.Date
GROUP BY ISNULL(depl.Date, a.Date) 
	  ,ISNULL(depl.HedgeServerID, a.HedgeServerID)
	  ,ISNULL(depl.InstrumentID, a.InstrumentID)
	  ,ISNULL(depl.InstrumentType, a.InstrumentType)
	  ,ISNULL(depl.InstrumentDisplayName, a.InstrumentName)