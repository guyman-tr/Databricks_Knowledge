SELECT 
	r.Country,
	r.DesignatedRegulation,
	r.Regulation,
	r.LastModificationDateEOMonth,
	CAST(SUM(CASE WHEN r.SLAhrs = 1 THEN 1 ELSE 0 END) AS FLOAT) as [Redeems Processed in 1 hour],
	COUNT(r.CID) AS CountCIDs,
	CAST(SUM(CASE WHEN r.SLA = 1 THEN 1 ELSE 0 END) AS FLOAT) as [Redeems Processed in 24 hour]
FROM 
	#redeem r
GROUP BY 
	r.Country,
	r.DesignatedRegulation,
	r.Regulation,
	r.LastModificationDateEOMonth