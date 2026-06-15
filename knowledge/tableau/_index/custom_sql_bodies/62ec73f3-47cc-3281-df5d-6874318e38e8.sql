SELECT pc.Date
        ,pc.RealCID
	,pc.Desk
        ,pc.AM
        ,pc.IsActive
	,dd.MonthName+' '+ CAST(dd.CalendarYear AS VARCHAR(30)) AS YearMonth
	,dc1.Name Country
	,dc1.MarketingRegionManualName Region
	,fm.Revenue_Total Revenue
  FROM [BI_DB_dbo].[BI_DB_ProfessionalCustomers] pc WITH (NOLOCK)
  INNER JOIN [DWH_dbo].[Dim_Date] dd WITH (NOLOCK)
  ON pc.DateID = dd.DateKey
  INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
  ON pc.RealCID = dc.RealCID
  INNER JOIN [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
  ON dc.CountryID = dc1.CountryID
  LEFT JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
  ON dc.RealCID = fm.CID
  AND pc.Date = fm.ActiveDate