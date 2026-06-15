select 
	x.MarketingRegion, x.Country, x.ClusterDetail, x.Cashout_Behaviour, x.Month, x.Is_FTD_ThisM,
	SUM(x.Deposit_Amount) [Total_Deposit_Amount], 
	SUM(x.Cashout_Amount) [Total_Cashout_Amount],
	SUM(x.NetDeposit_Amount) [Total_NetDeposit_Amount],
	SUM(x.Deposit_count) [Total_Deposit_count],
	SUM(x.Cashout_count) [Total_Cashout_count],
	SUM(x.Uniq_Deposituser_count) [Total_Uniq_Deposituser_count],
	SUM(x.Uniq_Cashoutuser_count) [Total_Uniq_Cashoutuser_count],
	SUM(x.RealizedEquity_avg) [Total_RealizedEquity],

	-- all positions
	SUM(x.TotalPositionsAmount) [TotalPositionsAmount],
	SUM(x.PositionPnL) [PositionPnL],

	-- manual positions
	SUM(x.TotalManualPositionsAmount) [TotalManualPositionsAmount], -- Total Manual Position Amount
	SUM(x.ManualPositionPnL) [ManualPositionPnL],  -- PnL Manual

	-- copy positions
	SUM(x.TotalMirrorPositionsAmount) [TotalMirrorPositionsAmount], -- Total copy position amount
	SUM(x.CopyPositionPnL) [CopyPositionPnL], -- PnL copy

	-- stocks (all/manual)
	SUM(x.TotalStockPositionAmount) [TotalStockPositionAmount],
	SUM(x.TotalStockManualPosition) [TotalStockManualPosition],
	SUM(x.StocksPositionPnL) [StocksPositionPnL],
	SUM(x.ManualStockPositionPnL) [ManualStockPositionPnL],

	-- crypto (all/manual)
	SUM(x.TotalCryptoPositionAmount) [TotalCryptoPositionAmount],
	SUM(x.TotalCryptoManualPosition) [TotalCryptoManualPosition],
	SUM(x.CryptoPositionPnL) [CryptoPositionPnL],
	SUM(x.ManualCryptoPositionPnL) [ManualCryptoPositionPnL],

	SUM(x.NOP) [NOP]


--	SUM(x.Cashout_Amount)/SUM(x.PositionPnL) [TotalCO_TotalPnl_ratio], 
--	AVG(x.CO_PnL_ratio) [Avg_CO_PnL]
FROM
(
SELECT 
	mc.*,
	CASE
		WHEN mc.PositionPnL > 0 THEN ISNULL(mc.Cashout_Amount /  NULLIF(mc.PositionPnL,0) ,0) 
		WHEN mc.PositionPnL < 0 THEN ISNULL(mc.Cashout_Amount /  NULLIF(ABS(mc.PositionPnL),0) ,0)
	END [CO_PnL_ratio],
	CASE
		WHEN mc.NetDeposit_Amount < 0 AND mc.PositionPnL IS NULL THEN 'Cashing out & no positions'
		WHEN mc.NetDeposit_Amount < 0 AND mc.PositionPnL > 0 THEN 'Cashing out profits'
		WHEN mc.NetDeposit_Amount < 0 AND mc.PositionPnL < 0 THEN 'Reducing equity'

		WHEN mc.NetDeposit_Amount >= 0 AND mc.Cashout_Amount > 0 AND mc.Deposit_Amount > 0 THEN 'Both deposit & cashout'
		ELSE 'No significant cashout behaviour'
	END [Cashout_Behaviour]
FROM #monthly_cid mc
--WHERE mc.NetDeposit_Amount <= 0 AND mc.PositionPnL IS NULL AND mc.Month = 1 AND mc.ClusterDetail = 'Crypto'
--ORDER BY
--	 [CO_PnL_ratio]
) x
GROUP BY
	x.MarketingRegion,
	x.Country,
	x.ClusterDetail,
	x.Cashout_Behaviour,
	x.Month,
	x.Is_FTD_ThisM
--ORDER BY
--	x.ClusterDetail,
--	x.Cashout_Behaviour,
--	x.Month