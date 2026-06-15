SELECT dc.RealCID
		,dc1.Name Country
		,dpl.Name Club
		,dp.OpenOccurred
		,di.Symbol
		,di.InstrumentDisplayName
		,dp.Amount
		,dp.PositionID
        ,case when dp.MirrorID = 0 THEN 'Manual' ELSE 'Copy' END IsCopy
		,CASE WHEN dp.IsSettled = 1 THEN 'Real' ELSE 'CFD' END IsCFD
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Customer dc
ON dc.RealCID = dp.CID
JOIN DWH_dbo.Dim_Instrument di
ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Dim_Country dc1
ON dc.CountryID = dc1.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE dp.CloseDateID = 0
AND di.Symbol IN ('EOS','FIL','HBAR','MIOTA','NEO','TRX','API3','ARB','BICO','CTSI','CELO','FET','FLR','FTT','IMX','LPT','MKR','ALICE','OXT','OGN','REN','SRM','SGB','STORJ','LUNC','LUNA2','THETA','UMA','ZEC','OP','RNDR','LDO','NEAR','TIA','JTO','TRB','RONIN','AXL','ONDO','SEI','INJ','OCEAN','ORCA','OSMO','IOTX','COTI','JASMY','HNT','METIS','PYR','STX','STRK','KSM','GHST'
)

AND dc.IsDepositor = 1
AND dc.IsValidCustomer = 1
AND dc.RegulationID = 11