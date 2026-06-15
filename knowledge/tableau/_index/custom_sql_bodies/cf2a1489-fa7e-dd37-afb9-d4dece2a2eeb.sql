SELECT
			DISTINCT f.[RealCID]
		   ,f.[RegisteredDate]
           ,[VerificationLevel1Date]
           ,[VerificationLevel2Date]
           ,[EvMatchStatusDate]
           ,[VerificationDate]
		   ,DateAdded
		   ,Occurred
           ,[EffectiveAddDate]
	   ,f.[FirstDepositDate]
		   ,FirstReviewed
		   ,FirstTouch
		   ,FirstTouchHour
		   ,FirstTouchMinute
		   ,[DaysToVerify]
		   ,MinutesToVerify
		   ,HoursToVerify
		   ,f.[VerificationLevelID]
           ,dc.[PlayerStatusID]
           ,dc.[PendingClosureStatusID]
           ,dc.[PlayerStatusReasonID]
           ,f.[EvMatchStatus]
           ,dc1.[Region]
           ,[Regulation]
           ,dc.IsDepositor
           ,dc1.[RiskGroupID]
           ,[VerificationMethod]
		   ,[KYCFlow],
dr.Name as DesignatedRegulation,
dc1.Name as Country
		FROM #finalRaw f
join DWH_dbo.Dim_Customer dc on dc.RealCID=f.RealCID
join DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
LEFT JOIN DWH_dbo.Dim_Regulation dr on dr.ID=dc.DesignatedRegulationID