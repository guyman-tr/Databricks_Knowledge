SELECT bddcria.InstrumentID
	 , bddcria.Instrument
	 , bddcria.InstrumentTypeID
	 , bddcria.InstrumentType
	 , bddcria.Region
	 , bddcria.Club
	 , bddcria.FullDate
	 , bddcria.DateID
	 , bddcria.[FTD Year]
	 , bddcria.VolumeOnOpen
	 , bddcria.VolumeOnClose
	 , bddcria.RollOverFee
	 , ISNULL(bddcria.FullCommissions,0) + ISNULL(bddcria.TradingFees,0) AS FullCommissions
	 , bddcria.Commissions
	 , bddcria.IsValidCustomer
	 , bddcria.Regulation
	 , bddcria.IsSettled
	 , bddcria.RollOverFee_SDRT
	 , bddcria.TradingFees
	 , bddcria.IsDLTUser
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg bddcria
WHERE bddcria.DateID >= 20240101