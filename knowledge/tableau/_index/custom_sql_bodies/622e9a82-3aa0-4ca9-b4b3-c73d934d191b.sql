SELECT	a.*
		,bdcd.NewMarketingRegion
		,bdcd.Region
		,bdcd.Country
		,bdcd.Club
		,bdcd.Manager
		,bdsu.ReportsTo_BOB [Reporting Manager]
		,bdcd.Language
		,bdcd.RegulationID
		,dr.Name [Regulation]
		,bdcd.Blocked
FROM
(SELECT DISTINCT	tf.person_id
		,CASE WHEN dc1.GCID IS NOT NULL THEN dc1.GCID ELSE dc2.GCID END AS GCID
		,CASE WHEN dc1.RealCID IS NOT NULL THEN dc1.RealCID ELSE dc2.RealCID END AS RealCID
		,CASE WHEN dc1.UserName IS NOT NULL THEN dc1.UserName ELSE dc2.UserName END AS UserName
		,tfdp.name [NPS_name]
FROM [ThirdParty_Fivetran].[Fivetran].[delighted].[response] tf
LEFT JOIN [ThirdParty_Fivetran].[Fivetran].[delighted].[person] tfdp ON tf.person_id = tfdp.id
LEFT JOIN DWH..Dim_Customer dc1 ON tfdp.name = dc1.UserName COLLATE database_default
LEFT JOIN DWH..Dim_Customer dc2 on tfdp.name = (dc2.FirstName + ' ' + dc2.LastName) COLLATE database_default
) a
LEFT JOIN BI_DB..BI_DB_CIDFirstDates bdcd ON a.GCID = bdcd.GCID
LEFT JOIN DWH..Dim_Regulation dr ON bdcd.RegulationID = dr.DWHRegulationID
LEFT JOIN BI_DB..BI_DB_SF_Users bdsu ON bdcd.Manager = bdsu.FullName COLLATE database_default