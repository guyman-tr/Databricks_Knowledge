select RealCID, 
		CONVERT(DATE, FirstDepositDate) FirstDepositDate,
		Country, 
		Region,
		CurrentVerificationLevel,
		DidCO,
		UploadDocs,
		SuggestedPOA,
		SuggestedPOI,
		PendingClosureStatusID,
		CurrentPlayerStatus,
		PlayerStatusReasonID,
		Closed,
		EvVerified,
                NewUpload,
		case when DATEADD(day, 15, convert(date, FirstDepositDate)) <= convert(date, getdate()) 
			and	CurrentVerificationLevel < 3
			and DidCO = 0
			and PendingClosureStatusID < 3
			then 1 else 0 end as Not_Closed_15_Plus,
		RegulationID,
		EvMatchStatus,
		FTD_Plus_14,
		[14_Days_RE],
        [14_Days_Deposits],
		[Priority],
		IsDepositor,
		--WorldCheckID, 
		IsWalletUser,
                dr.Name as Regulation
        FROM [BI_DB_dbo].[BI_DB_VerificationStatus30Days]
join DWH_dbo.Dim_Regulation dr on dr.ID=RegulationID