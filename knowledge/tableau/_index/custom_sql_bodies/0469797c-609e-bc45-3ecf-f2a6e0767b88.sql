SELECT
	sc.*
  , year(Date) as Year
  , Name AS Country
  , dc.Name+','+dc.Abbreviation AS CountryFormatted
  , CASE WHEN dc1.AffiliateID IS NOT NULL THEN 'IsAffiliate' ELSE 'IsNotAffiliate' END AS IsAffiliate
FROM BI_DB_RBSF_Section_C sc
JOIN DWH..Fact_SnapshotCustomer fsc
	ON CID = fsc.RealCID
JOIN DWH..Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND sc.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH..Dim_Country dc
	ON fsc.CountryID = dc.CountryID
JOIN DWH..Dim_Customer dc1
	ON sc.CID = dc1.RealCID