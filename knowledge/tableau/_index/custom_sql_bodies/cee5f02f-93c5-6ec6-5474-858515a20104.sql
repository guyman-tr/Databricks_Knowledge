SELECT  pcp.[Date],
CONVERT(CHAR(8),CASE WHEN MONTH(pcp.Date) = MONTH(GETDATE()) THEN DATEADD(DAY,-1,GETDATE()) ELSE EOMONTH(pcp.Date) END,112) EOMonth,
        pcp.[DateID],
        pcp.[RealCID],
        pcp.[ClubTier],
        pcp.[Desk],
        pcp.[AM],
        pcp.[Country],
        pcp.[DaysSinceApplication],
        pcp.[UpdateDate],
        dd.[DateKey],
        dd.[Date] AS [dd_Date],
        dd.[CalendarYearMonth] AS [CalendarYearMonth],
        dd.[YearMonth] AS [YearMonth],
		td.ACC_TotalDeposits,
		vl.Liabilities + vl.ActualNWA AS Equity,
		TradingKnowledge,
	    TradingExperience,
	    TotalCashLiquid,
	    AnnualIncome,
		dc1.MarketingRegionManualName Region,
		pcap.SelectedCriteria SelectedCriteria,
td.ACC_Revenue_Total,
dr.Name Regulation 
FROM BI_DB_dbo.[BI_DB_ProfessionalCustomersPending] pcp
INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
ON pcp.RealCID = dc.RealCID
INNER JOIN [DWH_dbo].[Dim_Regulation] dr  WITH (NOLOCK)
ON dc.RegulationID = dr.ID
LEFT JOIN [BI_DB_dbo].[External_BI_OUTPUT_Customer_ProfessionalCustomers] pcap
ON dc.GCID = pcap.GCID
INNER JOIN [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
  INNER JOIN (
  SELECT dd.DateKey
        ,dd.FullDate Date
        ,dd.CalendarYearMonth
        ,dd.MonthName+' '+ CAST(dd.CalendarYear AS VARCHAR(30)) AS YearMonth
  FROM [DWH_dbo].[Dim_Date] dd WITH (NOLOCK)
) dd 
ON pcp.[DateID] = dd.[DateKey]
--ORDER BY pcp.RealCID
LEFT JOIN  (
SELECT CID 
       ,Active_Month
	   ,ACC_TotalDeposits
	   ,ACC_Revenue_Total
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData
) 
td
ON pcp.RealCID = td.CID
AND left(pcp.DateID,6) = td.Active_Month
LEFT JOIN DWH_dbo.V_Liabilities vl
ON pcp.RealCID = vl.CID
AND CONVERT(CHAR(8),CASE WHEN MONTH(pcp.Date) = MONTH(GETDATE()) THEN DATEADD(DAY,-1,GETDATE()) ELSE EOMONTH(pcp.Date) END,112) = vl.DateID
LEFT JOIN (
SELECT RealCID
      ,CASE WHEN KYC.Q3_Is_Professional_Knowledge = 0 THEN 'No' ELSE 'Yes' END TradingKnowledge
	  ,KYC.Q2_AnswerText TradingExperience
	  ,KYC.Q11_AnswerText TotalCashLiquid 
	  ,KYC.Q10_AnswerText AnnualIncome
FROM BI_DB_dbo.BI_DB_KYC_Panel KYC
)kyc
ON pcp.RealCID = kyc.RealCID
WHERE dc.PlayerStatusID = 1