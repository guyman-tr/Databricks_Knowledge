---> 2063 unique apexid, 1647 unique gcid
 SELECT DISTINCT 
		ReportDate, 
		trading_dep.TradingFTDASum, trading_dep.TradingRedepositsSum,
		(trading_dep.TradingFTDASum+trading_dep.TradingRedepositsSum) AS TradingTotalDepositsSum,
		
		ISNULL(op_apex.daily_ops_ftda_sum,0) AS OptionsFTDASum,
		ISNULL(op_apex.daily_ops_redeposits_sum,0) AS OptionsRedepositsSum,
		ISNULL(op_apex.daily_ops_total_deposits_sum,0) AS OptionsTotalDepositsSum, 

		TradingFTDACount,
		TradingRedepositsCount,
		TradingTotalDepositsCount,

		ISNULL(daily_ops_ftda_ct,0) AS OptionsFTDACount,
		ISNULL(daily_ops_redeposits_ct, 0) AS OptionsRedepositsCount,
		ISNULL(daily_ops_total_deposits_ct,0) AS OptionsTotalDepositsCount,

		TradingFTDA_CIDCount,
		TradingRedeposits_CIDCount,
		TradingTotalDeposits_CIDCount,

		ISNULL(daily_ops_redepositors_ct,0) daily_ops_redepositors_ct,
		ISNULL(daily_ops_depositors_ct,0) daily_ops_depositors_ct
 FROM 
(
		SELECT 
			CAST(CONVERT(char(8), fca.DateID) as date) ReportDate, 
			
			Count(DISTINCT CASE WHEN fbd.IsFTD = 1 THEN fca.RealCID end) AS TradingFTDA_CIDCount,
			Count(DISTINCT CASE WHEN fbd.IsFTD = 0 THEN fca.RealCID end) AS TradingRedeposits_CIDCount,
			count(DISTINCT fca.RealCID) AS TradingTotalDeposits_CIDCount,

			Count(DISTINCT CASE WHEN fbd.IsFTD = 1 THEN fca.DepositID end) AS TradingFTDACount,
			Count(DISTINCT CASE WHEN fbd.IsFTD = 0 THEN fca.DepositID end) AS TradingRedepositsCount,
			count(DISTINCT fca.DepositID) AS TradingTotalDepositsCount,

			sum(CASE WHEN fbd.IsFTD = 1 THEN fca.Amount end) AS TradingFTDASum,
			sum(CASE WHEN fbd.IsFTD = 0 THEN fca.Amount end) AS TradingRedepositsSum,
			SUM(fca.Amount) AS TradingTotalDepositsSum

		FROM DWH_dbo.Fact_CustomerAction fca
			JOIN DWH_dbo.Dim_Customer dc1
				ON fca.RealCID = dc1.RealCID AND dc1.IsValidCustomer=1 --AND 
				AND dc1.RegulationID IN (6,7,8,14) AND dc1.DesignatedRegulationID IN (7,8,14)
			JOIN DWH_dbo.Dim_Country dc ON dc1.CountryID = dc.CountryID AND dc.MarketingRegionManualName='USA'
			JOIN DWH_dbo.Dim_FundingType dft 
				ON fca.FundingTypeID = dft.FundingTypeID
				AND dft.FundingTypeID!=42
			JOIN DWH_dbo.Fact_BillingDeposit fbd ON fca.DepositID=fbd.DepositID
		WHERE fca.ActionTypeID = 7
		  AND CAST(CONVERT(char(8), fca.DateID) as date) >= DATEADD(WEEK, -10, GETDATE())	
		  --AND fbd.IsFTD!=1
		GROUP BY CAST(CONVERT(char(8), fca.DateID) as date) 
) trading_dep

LEFT JOIN 
(	
	SELECT DISTINCT daily_dep.ProcessDate, 
			daily_ops_depositors_ct,
			daily_ops_depositors_ct- Ops_FTDA_ct AS daily_ops_redepositors_ct,
			
			daily_ops_total_deposits_ct,
			Ops_FTDA_ct AS daily_ops_ftda_ct,
			daily_ops_total_deposits_ct - Ops_FTDA_ct AS daily_ops_redeposits_ct, 

			daily_ops_total_deposits_sum, 
			isnull(Ops_Total_FTDA_Adj,0) daily_ops_ftda_sum,
			daily_ops_total_deposits_sum - isnull(Ops_Total_FTDA_Adj,0) AS daily_ops_redeposits_sum
	FROM 
				/********************************* target daily deposit dates ********************************/
		(
			SELECT  ProcessDate, 
				count(DISTINCT AccountNumber) daily_ops_depositors_ct,
				sum(ABS(Amount)) daily_ops_total_deposits_sum, 
				count(DISTINCT ACATSControlNumber) daily_ops_total_deposits_ct
			FROM  [BI_DB_dbo].[External_Sodreconciliation_apex_EXT869_CashActivity]  -- where all deposits and redeposits source from
			WHERE PayTypeCode = 'C' AND (EnteredBy IN ('ACH','WRD'))
				AND OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('GAT','FO1')
				AND ProcessDate >= DATEADD(WEEK, -10, GETDATE())	
			GROUP BY ProcessDate
		) daily_dep
	LEFT JOIN 	
	(
		SELECT  --dep_his.*, options_first_deposit
				op_ftd.options_first_deposit, 
				count(distinct op_ftd.AccountNumber) Ops_FTDA_ct,
								
				sum(CASE WHEN FirstDayDepositsCt >1 then FirstDayDepositsTotal / FirstDayDepositsCt 
						WHEN FirstDayDepositsCt=1 THEN FirstDayDepositsTotal 
						END)	AS Ops_Total_FTDA_Adj,
								
				sum(CASE WHEN FirstDayDepositsCt >1 then FirstDayDepositsTotal / FirstDayDepositsCt 
						WHEN FirstDayDepositsCt=1 THEN FirstDayDepositsTotal 
						END) / count(distinct op_ftd.AccountNumber) Ops_AFTDA_Adj
		FROM  
		(
			SELECT AccountNumber, ProcessDate, count(DISTINCT ACATSControlNumber) FirstDayDepositsCt, sum(ABS(Amount)) FirstDayDepositsTotal
			FROM [BI_DB_dbo].[External_Sodreconciliation_apex_EXT869_CashActivity] 
			WHERE OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('GAT','FO1') AND PayTypeCode = 'C' AND (EnteredBy IN ('ACH','WRD'))
			GROUP BY AccountNumber, ProcessDate
		) dep_his -- where all deposits and redeposits source from
		JOIN (
			SELECT ca1.AccountNumber,  
					MIN(ca1.ProcessDate) AS options_first_deposit
			FROM [BI_DB_dbo].[External_Sodreconciliation_apex_EXT869_CashActivity] ca1
			WHERE OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('GAT','FO1') AND (EnteredBy IN ('ACH','WRD'))
				AND AccountNumber NOT IN ('4GS43999', '3ET00001', '3ET00100', '3ET00101', '3ET00002', '3ET05007', '4GS00103', '4GS00104', '4GS00101', '4GS00100')
				AND PayTypeCode = 'C'  -- For deposits --qa, AND AccountNumber='4GS06154'
			GROUP BY AccountNumber
		) op_ftd
		ON
			dep_his.AccountNumber = op_ftd.AccountNumber 
			AND dep_his.ProcessDate = op_ftd.options_first_deposit
		WHERE op_ftd.options_first_deposit >= DATEADD(WEEK, -10, GETDATE())	
		GROUP BY op_ftd.options_first_deposit
		--ORDER BY op_ftd.options_first_deposit

	)ops_ftda
		ON daily_dep.ProcessDate=ops_ftda.options_first_deposit

)op_apex
ON trading_dep.ReportDate = op_apex.ProcessDate