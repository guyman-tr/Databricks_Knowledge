SELECT          CAST(created_at as DATE) [Created_Date]
		,tf.id	
		,tf.person_id
		,tf.survey_type
		,tf.score
		,tf.comment
		,tf.permalink
		,dc.MarketingRegionManualName
		,dc.Region
		,tf.properties_country [Country]
		,tf.properties_locale [Locale]
		,tf.properties_feature [FeaturePage]
FROM [ThirdParty_Fivetran].[Fivetran].[delighted].[response] tf
LEFT JOIN DWH..Dim_Country dc ON tf.properties_country = dc.Name COLLATE Latin1_General_100_BIN
WHERE tf.created_at >= CAST('2021-01-01' AS DATE)