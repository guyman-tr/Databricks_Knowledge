SELECT fd.CID
	  ,fd.Club
	  ,fd.Country
	  ,fd.Region
	  ,fd.Verified
	  ,fd.DocsOK
	  ,fd.registered
	  ,fd.Manager
	  ,fd.FirstDepositDate
	  ,fd.VerificationLevel1Date
	  ,fd.VerificationLevel2Date
	  ,fd.VerificationLevel3Date
	  ,fd.EvMatchStatusDate
	  ,fd.EvMatchStatus
	  ,fd.FirstPosOpenDate FirstAction
,dr.Name Regulation
FROM [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
LEFT JOIN DWH.dbo.Dim_Regulation dr WITH (NOLOCK)
ON fd.RegulationID=dr.ID
WHERE fd.registered >='2021-01-01 00:00:00.000'