SELECT bdomkv.RealCID,
		bdcd.GCID,
		bdomkv.RegisteredDate,
		bdcd.FirstDepositDate,
		bdomkv.VerificationMethod,
		bdomkv.VerificationSLA,
		bdcd.VerificationLevel1Date,
		bdcd.VerificationLevel2Date,
		bdcd.VerificationLevel3Date,
		bdcd.EmailVerifiedDate,
		bdcd.PhoneVerifiedDate,
		bdomkv.KYCFlow,
		bdcd.NewMarketingRegion [MarketingRegion],
		bdcd.Country,
		bdomkv.DaysToVerify,
		bdomkv.WorkingDaysToVerify,
		bdomkv.HoursToVerify,
		bdomkv.MinutesToVerify,
		bdomkv.UnderOneDay,
		bdomkv.OverOneDay,
		bdomkv.EvMatchStatus,
		bdomkv.[Uploaded 2 Docs (not EV)],
		bdcd.DocsOK,
		bdcd.Verified,
		bdomkv.VerificationDate,
		bdcd.Channel,
		bdcd.SubChannel
FROM BI_DB..BI_DB_Operations_Monthly_KPIs_Verifications bdomkv
LEFT JOIN DWH..Dim_PendingClosureStatus dpcs ON bdomkv.PendingClosureStatusID = dpcs.PendingClosureStatusID
LEFT JOIN BI_DB..BI_DB_CIDFirstDates bdcd ON bdcd.CID = bdomkv.RealCID