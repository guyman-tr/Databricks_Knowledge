SELECT  CAST(CONVERT(nvarchar(8), DateID) as date) AS Date_EoM, Regulation, Country,
	sum(Registrations) as Registrations, 
	sum(FirstDepositors) AS FTD, 
	--CAST(sum(FirstDepositors) AS INT)/CAST(sum(Registrations) AS INT) *1.0000 AS CVR_RegToFTD,
	sum(FirstDepositAmounts) AS Total_FTDA, 
	ISNULL(sum(FirstDepositAmounts)/NULLIF(sum(FirstDepositors),0),0) AS Avg_FTDA,
	sum(NewTrades) as NewTrades,
	SUM(ActiveOpen) AS ActiveOpen,
	SUM(TotalInvestmentAmountInNewTrades) Volume,
	SUM(ISNULL(Revenue, 0)-ISNULL(DividendsPaid, 0)+ISNULL(InterestFees, 0)+ISNULL(ConversionFees, 0) +ISNULL(DormantFee, 0)) as [Revenue (excl. Dividend)],
	ISNULL(SUM(ISNULL(Revenue, 0)-ISNULL(DividendsPaid, 0)+ISNULL(InterestFees, 0)+ISNULL(ConversionFees, 0) +ISNULL(DormantFee, 0))/NULLIF(sum(NewTrades),0), 0) AS Avg_Rev_per_NewTrade
FROM [BI_DB_dbo].[BI_DB_DDR_TimeRange_Aggregated_Country_Level]
WHERE  --Region = 'USA' 
IsCreditReportValidCB=1 AND IsValidCustomer =1 
AND Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA','FINRAONLY')
AND TimeRange='ThisMonth' 
AND 
	(DateID IN (
				sELECT DISTINCT CONVERT(nvarchar(8), EoMONTH(CAST(CONVERT(char(8), FromDateID) as date)), 112) MonthEnd_DateID
				FROM [DWH_dbo].[Dim_Range] where FromDateID between 20220101 and CONVERT(nvarchar(8), GETDATE(), 112)
		) 
	or DateID =   CONVERT(nvarchar(8), DATEADD(DAY,-1,GETDATE()), 112)
	)
GROUP BY  CAST(CONVERT(nvarchar(8), DateID) as date), Regulation, Country
--ORDER BY  CAST(CONVERT(nvarchar(8), DateID) as date), Regulation, Country


--SELECT TOP 10 * FROM [BI_DB_dbo].[BI_DB_DDR_TimeRange_Aggregated_Country_Level]