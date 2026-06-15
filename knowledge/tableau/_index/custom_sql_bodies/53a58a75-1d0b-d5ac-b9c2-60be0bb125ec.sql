/*********************************** FINAL: Weekly new & rolling trader count (manual and CFD crypto) ***********************************/


SELECT
	rm.*,
	rc.NewCFDcryptoTraders,
	rc.RollingCFDcryptoTraders
--	,(rc.RollingCFDcryptoTraders*1.0) / (rm.RollingManualTraders *1.0)
FROM 
	#rolling_manual rm 
	LEFT JOIN #rolling_cfdcrypto rc ON rm.StartOfWeekDate = rc.StartOfWeekDate AND rm.EndOfWeekDate = rc.EndOfWeekDate
--ORDER BY rm.StartOfWeekDate