SELECT c.Club 
,CASE WHEN dc1.Name IN ('Denmark','Finland','Netherlands','Norway','Sweden')  THEN 'Nordic'
            WHEN dc1.Name IN ('Poland','Romania','Slovakia','Slovenia','Czech Republic') THEN 'EE'
            WHEN dc1.Region IN ('South & Central America','Spain') THEN 'Spanish'
            WHEN dc1.Region IN ('Other Asia','China') THEN 'SEA'
            WHEN dc1.Region IN ('Arabic Other','Arabic GCC') THEN 'Arabic'
            WHEN dc1.Region IN ('French','German','Italian','UK','USA','Australia','Canada') THEN dc1.Region END Region
,CASE WHEN ClusterDetail = 'Equities Investors' THEN 'Investors'
	         WHEN ClusterDetail IN ('Equities Traders', 'Diversified Traders', 'Leveraged Traders') THEN 'Traders' 
	         WHEN ClusterDetail IN ('Crypto', 'Equities Crypto') THEN  'Crypto' END Segment 
      ,COUNT(*) Users
	   ,SUM(mp.Revenue_Total) Revenue
	   ,SUM(mp.TotalDeposits) Deposits
	   ,SUM(mp.TotalCashouts) Cashout
	   ,SUM(mp.NetDeposits) NetDeposits
           ,SUM(mp.ActiveOpen) Active

FROM BI_DB.dbo.BI_DB_CID_MonthlyPanel_FullData mp
JOIN (SELECT fsc.RealCID
		,dpl.Name Club
FROM DWH.dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
INNER JOIN DWH.dbo.Dim_Range dr WITH (NOLOCK)
ON fsc.DateRangeID = dr.DateRangeID
INNER JOIN DWH.dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
ON fsc.PlayerLevelID = dpl.PlayerLevelID
WHERE dr.FromDateID <=CAST(CONVERT(CHAR(8),<[Parameters].[Last Day Parameter]>,112) AS INT)
AND dr.ToDateID >=CAST(CONVERT(CHAR(8),<[Parameters].[Last Day Parameter]>,112) AS INT)) c
ON c.RealCID = mp.CID
AND mp.ActiveDate = DATEFROMPARTS(YEAR(<[Parameters].[Last Day Parameter]>),MONTH(<[Parameters].[Last Day Parameter]>),1)
JOIN DWH.dbo.Dim_Country dc1
ON mp.CountryID = dc1.CountryID
GROUP BY c.Club
,CASE WHEN ClusterDetail = 'Equities Investors' THEN 'Investors'
	         WHEN ClusterDetail IN ('Equities Traders', 'Diversified Traders', 'Leveraged Traders') THEN 'Traders'
	         WHEN ClusterDetail IN ('Crypto', 'Equities Crypto') THEN  'Crypto' END
,CASE WHEN dc1.Name IN ('Denmark','Finland','Netherlands','Norway','Sweden')  THEN 'Nordic'
            WHEN dc1.Name IN ('Poland','Romania','Slovakia','Slovenia','Czech Republic') THEN 'EE'
            WHEN dc1.Region IN ('South & Central America','Spain') THEN 'Spanish'
            WHEN dc1.Region IN ('Other Asia','China') THEN 'SEA'
            WHEN dc1.Region IN ('Arabic Other','Arabic GCC') THEN 'Arabic'
            WHEN dc1.Region IN ('French','German','Italian','UK','USA','Australia','Canada') THEN dc1.Region END