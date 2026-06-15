/*SELECT efb.GCID, efb.FullDate, efb.FullDateID, efb.CryptoId, efb.BalanceUSD
		FROM EXW_FactBalance efb
		where efb.FullDate>=DATEADD(month, -1, GETDATE())
and efb.GCID>0
		--group by efb.GCID, efb.FullDate, efb.FullDateID, efb.CryptoId
*/
SELECT efb.GCID, efb.FullDate, efb.FullDateID, efb.CryptoId, efb.BalanceUSD
		FROM EXW.dbo.EXW_FactBalance efb
		where efb.FullDate =cast(getdate() as date)
and efb.GCID>0