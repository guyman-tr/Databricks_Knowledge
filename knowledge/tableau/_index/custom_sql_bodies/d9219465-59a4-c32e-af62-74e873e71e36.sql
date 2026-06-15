SELECT eefsb.txhash
		,eefsb.date_time
		,eefsb.Date
		,eefsb.TranDate
		,eefsb.TranDateID
		,eefsb.txn_fee_eth
		,eefsb.historical_price_eth
		,eefsb.GCID
		,eefsb.RealCID
		,eefsb.BlockchainFees
		,eefsb.contract_address
		,eefsb.GCIDUnion
		,eefsb.CountryID
		,eefsb.Country
		,eefsb.RegulationID
		,eefsb.Regulation
		,eefsb.Activity
		,eefsb.UpdateDate
		,eefsb.method
		,ewe.WalletEntity
		,ewe.JoinDate
		  FROM   EXW_dbo.EXW_EthFeeSent_Blockchain eefsb 

LEFT JOIN  EXW_dbo.EXW_WalletEntity ewe
ON eefsb.Date = ewe.Date
AND ewe.GCID =eefsb.GCIDUnion

WHERE 
    eefsb.Date >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1) -- Start of year
    AND eefsb.Date < DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) -- Start of current month (exclusive)