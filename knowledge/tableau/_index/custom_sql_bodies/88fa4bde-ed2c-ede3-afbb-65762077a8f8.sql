SELECT di.Symbol, di.InstrumentDisplayName
FROM DWH_dbo.Dim_Instrument di
WHERE di.InstrumentTypeID = 10
AND di.Symbol IN ('EOS','FIL','HBAR','MIOTA','NEO','TRX','API3','ARB','BICO','CTSI','CELO','FET','FLR','FTT','IMX','LPT','MKR','ALICE','OXT','OGN','REN','SRM','SGB','STORJ','LUNC','LUNA2','THETA','UMA','ZEC','OP','RNDR','LDO','NEAR','TIA','JTO','TRB','RONIN','AXL','ONDO','SEI','INJ','OCEAN','ORCA','OSMO','IOTX','COTI','JASMY','HNT','METIS','PYR','STX','STRK','KSM','GHST'
)