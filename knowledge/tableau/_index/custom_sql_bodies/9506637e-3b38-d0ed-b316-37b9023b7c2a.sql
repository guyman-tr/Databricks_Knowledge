SELECT coalesce (n.DateID, o.DateID) AS DateID
	 , n.InstrumentID AS InstrumentID_New
	 , n.ISINCode AS ISINCode_New
	 , n.ISINCountryCode AS ISINCountryCode_New
	 , n.Exchange AS Exchange_New
	 , o.InstrumentID AS InstrumentID_Old
	 , o.ISINCode AS ISINCode_Old
	 , o.ISINCountryCode AS ISINCountryCode_Old
	 , o.Exchange AS Exchange_Old
FROM #new n
FULL OUTER JOIN #old o
	ON n.InstrumentID = o.InstrumentID
WHERE n.InstrumentID IS NULL OR o.InstrumentID IS null