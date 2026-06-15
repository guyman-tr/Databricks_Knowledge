SELECT [Rebates].[AM] AS [AM],
  [OptedIn].[CID] AS [CID (Custom SQL Query)],
  [Rebates].[CID] AS [CID],
  [Rebates].[CalendarYearMonth] AS [CalendarYearMonth],
  [Rebates].[Country] AS [Country],
  [Rebates].[Region] AS [Region],
  [Rebates].[Revenue]+[Rebates].[Crypto] AS [Revenue]
FROM (
  
				SELECT dd.CalendarYearMonth CalendarYearMonth
						,fca.RealCID CID
						,dm.FirstName +' '+dm. LastName AM
  						,dc1.MarketingRegionManualName Region
  						,dc1.Name Country
						,SUM(ISNULL(CASE WHEN fca.ActionTypeID=35 
                         AND fca.Description IN ('CloseTotalFees', 'OpenTotalFees') 
						THEN fca.Amount END,0) * -1) AS Crypto
						, SUM(fca.CommissionOnClose) AS Revenue
				FROM DWH_dbo.Fact_CustomerAction fca
				INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
				ON dd.DateKey=fca.DateID
				JOIN DWH_dbo.Dim_Customer dc
				ON fca.GCID = dc.GCID
				INNER JOIN DWH_dbo.Dim_Manager dm
				ON dc.AccountManagerID = dm.ManagerID
				INNER JOIN [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
				ON dc.CountryID = dc1.CountryID
				WHERE dc.IsValidCustomer=1
				AND dc.RegulationID = 9
				AND fca.DateID>=20250601
				GROUP BY dd.CalendarYearMonth
						 ,fca.RealCID
  						 ,dm.FirstName +' '+dm. LastName
  						,dc1.MarketingRegionManualName 
  						,dc1.Name
) [Rebates]
  LEFT JOIN (
  SELECT RealCID CID
  FROM [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
  WHERE GCID IN (
SELECT DISTINCT gcid from [BI_DB_dbo].[External_Fivetran_google_sheets_fsarebate]
WHERE gcid NOT IN ('xxxxx','%%GCID%%')
  )
) [OptedIn] ON ([Rebates].[CID] = [OptedIn].[CID])