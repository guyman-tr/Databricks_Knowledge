SELECT CAST( DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(review_created_utc_ AS DATE)), 0) AS DATE)  review_created
		, review_title 
		, reference_id 
		,club_level 
		,cid 
		,am 
		,role 
		,company_response 
FROM [BI_DB_dbo].[External_Fivetran_google_sheets_trustpilot_currentdate]
WHERE am<>'no match'
AND review_stars IN (4,5)

UNION ALL
 
SELECT  CAST (DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(review_created_utc_ AS DATE)), 0) AS DATE) review_created
		, review_title 
		, reference_id 
		,club_level 
		,cid 
		,am 
		,role 
		,company_response 
FROM [BI_DB_dbo].[External_Fivetran_google_sheets_trustpilot_history]
WHERE am NOT LIKE '#N/A%'
AND review_stars IN ('4','5')