SELECT RealCID,
	Convert(DATE, FirstDepositDate) AS FTD_Date,
	CASE WHEN NewUpload = 1 THEN 'UploadedOnlyOne' ELSE 'UploadedNone' END AS Problem,
	DATEDIFF(day, FirstDepositDate, getdate()) AS DaysFromFTD
FROM [BI_DB_dbo].[BI_DB_VerificationStatus30Days]
WHERE EvVerified = 0 
	AND CurrentVerificationLevel < 3 
	AND Closed = 0 AND ((NewUpload = 1 
	AND (SuggestedPOA + SuggestedPOI < 2 
			OR SuggestedPOA IS NULL 
			OR SuggestedPOI IS NULL))
	OR SuggestedPOA IS NULL 
	OR SuggestedPOI IS NULL)