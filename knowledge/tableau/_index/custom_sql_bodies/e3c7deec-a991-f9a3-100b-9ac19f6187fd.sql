SELECT     dc.CountryID 
	  ,dc.Name AS Country
	  ,dc.IsHighRiskCountry
	  ,dc.RiskGroupID
	  ,CASE WHEN dc.RiskGroupID =1 THEN 'NULL' ELSE dr.Name END AS Designated_Regulation
	  ,ft.aml_compliance
	  ,ft.risk_list
          ,GETDATE() AS UpdateDate
FROM DWH_dbo.Dim_Country dc
LEFT JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
LEFT JOIN [BI_DB_dbo].[External_Fivetran_google_sheets_grc_list] ft 
    ON TRY_CAST(ft.country_id AS INT) = dc.CountryID
WHERE dc.CountryID NOT IN (0,250)

UNION 

SELECT -1 AS CountryID	
		,'Kosovo' AS Country
		,1 AS IsHighRiskCountry
		,1 AS RiskGroupID
		,NULL AS Designated_Regulation	
		,NULL AS 'aml_compliance'
	    ,NULL AS 'risk_list'
                ,GETDATE() AS UpdateDate

UNION 

SELECT -2 AS CountryID	
		,'Crimea' AS Country
		,1 AS IsHighRiskCountry
		,1 AS RiskGroupID
		,'NULL'  AS Designated_Regulation
	,'NULL' AS 'aml_compliance'
	    ,'NULL' AS 'risk_list'
,GETDATE() AS UpdateDate


UNION 

SELECT -3 AS CountryID	
		,'North Cyprus' AS Country
		,1 AS IsHighRiskCountry
		,1 AS RiskGroupID
		,'NULL'  AS Designated_Regulation
	,'NULL' AS 'aml_compliance'
	    ,'NULL' AS 'risk_list'
,GETDATE() AS UpdateDate


UNION 

SELECT -4 AS CountryID	
		,'Southern Rhodesia' AS Country
		,1 AS IsHighRiskCountry
		,1 AS RiskGroupID
		,'NULL'  AS Designated_Regulation
		,'NULL' AS 'aml_compliance'
	    ,'NULL' AS 'risk_list'
,GETDATE() AS UpdateDate