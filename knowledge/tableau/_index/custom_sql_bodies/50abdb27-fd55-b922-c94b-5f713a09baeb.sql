SELECT [DDR Data].[CalendarYearMonth],
  [DDR Data].[DateID],
  [DDR Data].[FullDate],
  [DDR Data].[ReportingMonth],
  [DDR Data].[Region],
  [DDR Data].[JoinRegion],
  [DDR Data].[FirstDepositors],
  [DDR Data].[FirstDepositAmounts],
  [DDR Data].[Deposits],
  [DDR Data].[Cashouts],
  [DDR Data].[CO Ratio],
  [DDR Data].[NetDeposit],
  [DDR Data].[Revenue],
  [KPI Data].[Date],
  [KPI Data].[Desk],
  [KPI Data].[FTD],
  [KPI Data].[FTDA] AS [FTDATarget],
  [KPI Data].[GrossDeposit] AS [GrossDepositTarget],
  [KPI Data].[COAmount] AS [COAmountTarget],
  [KPI Data].[CORatio] AS [CORatioTarget],
  [KPI Data].[NetDeposit] AS [NetDepositTarget],
  [KPI Data].[Revenue] AS [RevenueTarget],
  [WorkingDays].[CalendarYearMonth] AS [WorkingDays.CalendarYearMonth],
  [WorkingDays].[DaysMTD],
  [WorkingDays].[DaysInMonth]
FROM (
  SELECT q0.CalendarYearMonth
  	  ,q0.DateID
  	  ,q0.FullDate
  	  ,q0.ReportingMonth
  	  ,q0.Region
  	  ,q0.Region AS JoinRegion
  	  ,q0.FirstDepositors
  	  ,q0.FirstDepositAmounts
  	  ,q0.Deposits
  	  ,q0.Cashouts
  	  ,q0.[CO Ratio]
  	  ,q0.NetDeposit
  	  ,q0.Revenue
  FROM(
SELECT CalendarYearMonth
	  ,DateID
	  ,FullDate
	  ,ReportingMonth
	  ,Region
	  ,FirstDepositors
	  ,FirstDepositAmounts
	  ,Deposits
	  ,Cashouts
	  ,[CO Ratio]
	  ,NetDeposit
	  ,Revenue
	  ,UpdateDate	 
FROM dbo.BI_DB_RM_KPI_Report)q0
) [DDR Data]
  INNER JOIN (
  SELECT [Date]
        ,[Desk]
        ,[FTD]
        ,[FTDA]
        ,[GrossDeposit]
        ,[COAmount]
        ,[CORatio]
        ,[NetDeposit]
        ,[Revenue]
FROM [dbo].[BI_DB_RM_KPI]
) [KPI Data] ON (([DDR Data].[ReportingMonth] = [KPI Data].[Date]) AND ([DDR Data].[JoinRegion] = [KPI Data].[Desk]))
  LEFT JOIN (
  SELECT dd.CalendarYearMonth
          ,COUNT(DISTINCT dd.DateKey) DaysMTD
          ,COUNT(DISTINCT dd1.DateKey) DaysInMonth
  FROM [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
  INNER JOIN [DWH].[dbo].[Dim_Date] dd1 WITH (NOLOCK)
  ON dd.CalendarYearMonth = dd1.CalendarYearMonth
  AND dd1.IsWeekday = 'Y'
  WHERE dd.IsWeekday = 'Y'
  AND dd.DateKey <=CONVERT(CHAR(8),GETDATE()-1,112)
  GROUP BY dd.CalendarYearMonth
) [WorkingDays] ON ([DDR Data].[CalendarYearMonth] = [WorkingDays].[CalendarYearMonth])

WHERE [DDR Data].Region IN ('Romania','Denmark','Czech Republic','Poland','Norway','Sweden','Finland','Other Europe')