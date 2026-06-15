SELECT
	sc.*
  , year(Date) as Year
  , dc.Name AS Country
  , dc.Name+','+dc.Abbreviation AS CountryFormatted
  , CASE WHEN dc1.AffiliateID IS NOT NULL THEN 'IsAffiliate' ELSE 'IsNotAffiliate' END AS IsAffiliate
  , dat.Name as AccountType
  , fsc.IsCreditReportValidCB
FROM BI_DB..BI_DB_RBSF_Section_C sc
JOIN DWH..Fact_SnapshotCustomer fsc
	ON CID = fsc.RealCID
JOIN DWH..Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND sc.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH..Dim_Country dc
	ON fsc.CountryID = dc.CountryID
LEFT JOIN DWH..Dim_Affiliate dc1
	ON fsc.GCID = dc1.GCID
join DWH..Dim_AccountType dat
    on fsc.AccountTypeID = dat.AccountTypeID
-- where year(Date) = 2021