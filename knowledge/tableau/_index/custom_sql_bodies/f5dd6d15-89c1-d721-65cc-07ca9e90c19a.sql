SELECT
	bdomkv.*
   ,dc1.Name AS Country,
    DesReg.Name as DesignatedRegulation,
row_number() over (partition by bdomkv.RealCID order by bdomkv.UpdateDate desc ) as RN,
	CASE WHEN bdomkv.VerificationDate IS NOT NULL AND bdomkv.VerificationDate>bdomkv.EffectiveAddDate
THEN DATEDIFF(DAY,bdomkv.EffectiveAddDate,bdomkv.VerificationDate) ELSE bdomkv.DaysToVerify
END AS DaysToVerification,
CASE WHEN bdomkv.VerificationDate IS NOT NULL AND bdomkv.VerificationDate>bdomkv.EffectiveAddDate
THEN DATEDIFF(minute,bdomkv.EffectiveAddDate,bdomkv.VerificationDate) ELSE bdomkv.DaysToVerify*24*60
END AS MinutesToVerification,
CASE WHEN bdomkv.VerificationDate IS NOT NULL AND bdomkv.VerificationDate>bdomkv.EffectiveAddDate
THEN DATEDIFF(hour,bdomkv.EffectiveAddDate,bdomkv.VerificationDate) ELSE bdomkv.DaysToVerify*24
END AS HoursToVerification,

CASE 
WHEN bdomkv.VerificationMethod IN ('EV') THEN 0
WHEN bdomkv.FirstReviewed IS NOT NULL AND bdomkv.FirstReviewed>=bdomkv.EffectiveAddDate
THEN DATEDIFF(DAY,bdomkv.EffectiveAddDate,bdomkv.FirstReviewed) ELSE bdomkv.FirstTouch
END AS DaysToFirstReview,

CASE 
WHEN bdomkv.VerificationMethod IN ('EV') THEN 0
WHEN bdomkv.FirstReviewed IS NOT NULL AND bdomkv.FirstReviewed>=bdomkv.EffectiveAddDate
THEN DATEDIFF(minute,bdomkv.EffectiveAddDate,bdomkv.FirstReviewed) ELSE bdomkv.FirstTouchMinute
END AS MinutesTosToFirstReview,
CASE 
WHEN bdomkv.VerificationMethod IN ('EV') THEN 0
WHEN bdomkv.FirstReviewed IS NOT NULL AND bdomkv.FirstReviewed>=bdomkv.EffectiveAddDate
THEN DATEDIFF(hour,bdomkv.EffectiveAddDate,bdomkv.FirstReviewed) ELSE bdomkv.FirstTouchMinute
END AS HoursTosToFirstReview,
CASE WHEN bdomkv.FirstReviewed='3000-01-01' THEN 'exclude' ELSE 'include' END AS [excludeOrInclude],
CASE WHEN dc.HasWallet = 1 then 'Yes' else 'No' end as HasWallet


FROM
BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications bdomkv
        JOIN DWH_dbo.Dim_Customer dc
            ON bdomkv.RealCID = dc.RealCID
        JOIN DWH_dbo.Dim_Regulation DesReg 
            ON DesReg.ID=dc.DesignatedRegulationID
	JOIN DWH_dbo.Dim_Country dc1
            ON dc.CountryID = dc1.CountryID