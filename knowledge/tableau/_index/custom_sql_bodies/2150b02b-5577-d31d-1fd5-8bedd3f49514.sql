SELECT tfdr.id
,tfdr.person_id
,tfdr.survey_type
,tfdr.score
,CASE WHEN tfdr.score <=5 THEN 'Detractors'
				WHEN tfdr.score BETWEEN 6 AND 8 THEN 'Passives'
				WHEN tfdr.score BETWEEN 9 AND 10 THEN 'Promoters'
			END [NPS_ScoreGroup]
,CAST(tfdr.created_at AS DATETIME) [CreateDate]
,tfdr.created_at [Created_atDateTime]
,tfdr.comment
,tfdr.permalink
,CAST(tfdr.updated_at AS DATETIME) [SurveyResponse_UpdatedDate]
,tfdr._fivetran_synced
,tfdr.properties_club
,tfdr.properties_device
,tfdr.properties_delighted_source
,tfdr.properties_country
,dc.Region
,dc.MarketingRegionManualName [MarketingRegion]
,tfdr.properties_user_name
,tfdr.properties_locale
,tfdr.properties_feature
,dpl.Name [Club_AtSurveySubmission]
,dpl.Sort [ClubSort]
FROM [ThirdParty_Fivetran].[Fivetran].[delighted].[response] tfdr
LEFT JOIN DWH..Dim_PlayerLevel_2022 dpl ON dpl.PlayerLevelID = tfdr.properties_club
LEFT JOIN DWH..Dim_Country_2022 dc ON dc.Name collate SQL_Latin1_General_CP1_CI_AS = tfdr.properties_country collate SQL_Latin1_General_CP1_CI_AS