SELECT darh.Date
		,darh.AccountNumber
		,darh.ISIN as ISINCode
		,darh.Apex_Units t1_Units
		,LAG(darh.Apex_Units,1) OVER (PARTITION BY darh.ISIN, darh.AccountNumber ORDER BY Date asc) t0_Units
FROM bi_dealing.bi_output_dealing_apex_recon_trades darh