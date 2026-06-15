SELECT sc.RealCID CID
      ,[ApplicationDate]
	  ,[SelectedCriteria] NumberOfCriteriaSelected
	  ,dm.FirstName + '' + dm.LastName AM
	  ,'' Desk
	  ,dd.CalendarYearMonth
      ,dd.MonthName+' '+ CAST(dd.CalendarYear AS VARCHAR(30)) AS YearMonth
	  ,dpl.Name Tier
	  ,dc1.MarketingRegionManualName Region
FROM [BI_DB_dbo].[External_BI_OUTPUT_Customer_ProfessionalCustomers] sf 
JOIN DWH_dbo.Fact_SnapshotCustomer sc WITH (NOLOCK)
on sf.GCID = sc.GCID
INNER JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
on sc.DateRangeID = dr.DateRangeID
AND CONVERT(CHAR(8),GETDATE()-1,112) >= FromDateID
AND  CONVERT(CHAR(8),GETDATE()-1,112) <= ToDateID
LEFT JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
ON sc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN DWH_dbo.[Dim_Customer] dc WITH (NOLOCK)
ON sc.RealCID = dc.RealCID
INNER JOIN [DWH_dbo].[Dim_Manager] dm WITH (NOLOCK)
ON dc.AccountManagerID = dm.ManagerID
INNER JOIN DWH_dbo.[Dim_Date] dd WITH (NOLOCK)
ON CAST(sf.ApplicationDate AS DATE) = dd.FullDate
INNER JOIN [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON sc.CountryID = dc1.CountryID