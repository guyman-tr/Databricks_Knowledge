SELECT c.[WithdrawID]
      ,c.[CID]
	  ,c.[Amount]
	  ,c.ModificationDate
	  ,pl.[PlayerLevelID] AS ClubID
	  ,pl.Sort AS ClubSort
      ,c.[PlayeLevel] AS Club
      ,c.[DateID]
      ,c.[FundingTypeID]
	  ,f.[Name] AS FundingType
	  ,s.Segment AS ActivitySegment
	  ,co.Region
	  ,co.Name AS Country
  FROM [BI_DB].[dbo].[BI_DB_ConversionFees_WithdrawIDs] c
  left join [BI_DB].[dbo].[BI_DB_ActivitySegment_Snapshot] s
  on c.CID = s.RealCID
  and c.DateID <= s.ToDateID
  and c.DateID >= s.FromDateID
  left join [DWH].[dbo].[Fact_SnapshotCustomer] sc
  on sc.RealCID = c.CID
  left join [DWH].[dbo].[Dim_Range] r
  on sc.[DateRangeID] = r.[DateRangeID]
  left join [DWH].[dbo].[Dim_Country] co
  on sc.CountryID = co.CountryID
  left join [DWH].[dbo].[Dim_FundingType] f
  on f.[FundingTypeID] = c.[FundingTypeID]
  left join[DWH].[dbo].[Dim_PlayerLevel] pl
  on c.PlayeLevel = pl.Name
  where c.DateID >= 20190401
  and c.[DateID] >=r.[FromDateID]
  and c.[DateID] <=r.[ToDateID]
  and sc.IsValidCustomer = '1'