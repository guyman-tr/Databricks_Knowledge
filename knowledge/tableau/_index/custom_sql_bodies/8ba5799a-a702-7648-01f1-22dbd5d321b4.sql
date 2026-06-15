SELECT darh.Date
		,darh.AccountNumber
		,darh.Symbol
		,darh.Apex_Units t1_Units
		,LAG(darh.Apex_Units,1) OVER (PARTITION BY darh.Symbol, darh.AccountNumber ORDER BY Date asc) t0_Units
FROM bi_dealing.bi_output_dealing_apex_recon_eod darh