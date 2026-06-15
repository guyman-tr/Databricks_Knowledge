SELECT   d.[DateID]
        ,d.[DayOfInterest]
        ,d.[CID]
		,d.[CountryID]
		,d.[PlayerLevelID]
        ,d.[AccountTypeID]
        ,d.[RegulationID]
		,d.[Credit]
		,d.[Bonus]
		,d.[FundsForInterest]
		,d.[DailyInterest]
		,d.[YearlyInterestPercentage]
		,d.[Interest]
		,dr.Name  AS Regulation
		,dpl.Name AS PlayerLevel
		,dc1.Name AS Country
		,dat.Name AS AccountType
		,fsc.IsValidCustomer
  FROM [BI_DB_dbo].[BI_DB_InterestDaily] d
  LEFT JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON d.CID=fsc.RealCID
  LEFT JOIN DWH_dbo.Dim_Range dr1 ON fsc.DateRangeID = dr1.DateRangeID AND d.DateID BETWEEN dr1.FromDateID AND dr1.ToDateID
LEFT JOIN DWH_dbo.Dim_AccountType dat ON d.AccountTypeID = dat.AccountTypeID
LEFT JOIN DWH_dbo.Dim_Country dc1 ON d.CountryID = dc1.StatusID
LEFT JOIN DWH_dbo.Dim_PlayerLevel dpl ON d.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN DWH_dbo.Dim_Regulation dr ON d.RegulationID=dr.DWHRegulationID