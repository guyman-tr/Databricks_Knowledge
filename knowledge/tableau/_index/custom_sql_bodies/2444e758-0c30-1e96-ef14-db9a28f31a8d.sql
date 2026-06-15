---2025.08.08 note: this is for US Monthly KPI dashboard;
-------- this contains last month and previous month data only

/* topics include: 
- DDR snapshop (yesterday): funded accounts, equity in crypto/equities, 
- MSB Cash: cash from Cyprus Finance / FBO bank account
- DDR aggregates (monthly): crypto revenue (ddr), crypto (manual) / copy commission

- Apex PFOF: options & equities revenue
- Apex Equity: equity from options (non-FINRAONLY) and options-equities hybrid account (FINRAONLY)
*/

SELECT  ddr.*, 
	MSBCashBalance,
	EquitiesPFOF,
	OptionsPFOF,
	UK_OptionsContractFee,
        OptionsEquity
from 
(
select 
		--ReportDate,
		DATEADD(DAY,-1, ReportDate) DateMinus1,
		-----------------metric snapshot ------------------
		SUM(CASE WHEN TimeRange = 'Yesterday' THEN isnull(Funded_New_Def,0) end) as Funded_New_Def, 
		sum(ISNULL(Equity,0)) AS Equity,
        sum(CASE WHEN TimeRange = 'Yesterday' THEN InvestedInStocksManual end) InvestedInStocksManual, 
        sum(CASE WHEN TimeRange = 'Yesterday' THEN InvestedInCryptoManual end) InvestedInCryptoManual, 
        sum(CASE WHEN TimeRange = 'Yesterday' THEN InvestedInCopyIncludingCash end) InvestedInCopyIncludingCash,
        sum(CASE WHEN TimeRange = 'Yesterday' THEN InProcessCashout end) InProcessCashout,
		
        --sum(Credit) Credit

		-----------------metric additive through time ------------------
		sum(CASE WHEN TimeRange = 'ThisMonth' THEN 
			ISNULL([OvernightFee],0) - ISNULL([DividendsPaid],0) - (-1 * ISNULL([SDRT],0)) - (-1 * ISNULL([TicketFees],0)) end
			) AS cal_rollover_fee,
 		SUM(CASE WHEN TimeRange = 'ThisMonth' THEN 	
			ISNULL([FullTotalCommission],0)+
			ISNULL([InterestFees],0)   +
			ISNULL([ConversionFees],0) +
			ISNULL([DormantFee],0)     +
			(-1*ISNULL(TradingFees,0) - (-1 * ISNULL(TicketFees,0)) )
			+
			(--cal_rollover_fee
				ISNULL([OvernightFee],0) - ISNULL([DividendsPaid],0) - (-1 * ISNULL([SDRT],0)) - (-1 * ISNULL([TicketFees],0)) 
			)+
			-1 * ISNULL([SDRT],0)+
			ISNULL([TransferCoinFees],0)+
			ISNULL([CashoutFee],0)+
			-1 * ISNULL([TicketFees],0)
			END
			)
			AS DDRdailyRevenue							
			 --, SUM(ISNULL(TransferCoins						,0)) as CoinRedeem
			 , SUM(CASE WHEN TimeRange = 'ThisMonth' THEN isnull(CryptoCommission		,0) END) as CryptoCommission	
			 , SUM(CASE WHEN TimeRange = 'ThisMonth' THEN isnull(FullCryptoCommission	,0) END) as FullCryptoCommission	
			 , sum(CASE WHEN TimeRange = 'ThisMonth' THEN ISNULL(FullCopyCommission		,0) END) AS FullCopyCommission
	from BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] 
	WHERE Region='USA'
		and IsCreditReportValidCB=1
		AND IsValidCustomer=1
		AND Regulation in ('FinCEN', 'FinCEN+FINRA', 'eToroUS', 'FINRAONLY')
		AND Country IN ('United States','US Virgin Islands','Puerto Rico') 
	AND DateID IN (
			SELECT CONVERT(VARCHAR(8),EOMONTH(dd.FullDate), 112)  MonthEndDateID
			FROM DWH_dbo.Dim_Date dd 
			WHERE dd.DateKey BETWEEN CONVERT(VARCHAR(8), DATEADD(MONTH, -12, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)), 112) AND CONVERT(VARCHAR(8), eomonth(dateadd(MONTH,-1,GETDATE())), 112) 
			GROUP BY CONVERT(VARCHAR(8),EOMONTH(dd.FullDate), 112) 
			)
			
	GROUP BY DATEADD(DAY,-1, ReportDate)
)ddr

left join (
	SELECT 
		cb.Date as EoM, 
		COALESCE(cb.AdjustedClosingBalance,0)-COALESCE(nb.AdjNegativeBalance,0)-COALESCE(cb.less_affiliate_clients,0)-COALESCE(cb.less_RealCryptoAdjusted,0) AS MSBCashBalance
	FROM (
		SELECT 
			DateID, 
			Date,
			SUM(COALESCE(ClosingBalance, 0)) AS ClosingBalance,
			SUM(CASE 
					WHEN Regulation = 'FinCEN+FINRA' 
					THEN COALESCE(ClosingBalance, 0) - COALESCE(RealStocksClosingBalance, 0)
					ELSE COALESCE(ClosingBalance, 0)
				END) AS AdjustedClosingBalance,
			SUM(COALESCE(CASE 
						WHEN AccountType IN ('Affiliate Corporate Account', 'Affiliate Private Account')  
							 AND PlayerStatus = 'Trade & MIMO Blocked'
						THEN 
							CASE 
								WHEN Regulation = 'FinCEN+FINRA' 
								THEN COALESCE(ClosingBalance, 0) - COALESCE(RealStocksClosingBalance, 0)
								ELSE COALESCE(ClosingBalance, 0)
							END
					END, 0)) AS less_affiliate_clients,
			SUM(COALESCE(TotalRealCrypto, 0) + COALESCE(PositionPNLCryptoReal, 0)) AS less_RealCryptoAdjusted
		FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New 
		WHERE DateID  IN (
				SELECT CONVERT(VARCHAR(8),EOMONTH(dd.FullDate), 112)  MonthEndDateID
				FROM DWH_dbo.Dim_Date dd 
				WHERE dd.DateKey BETWEEN CONVERT(VARCHAR(8), DATEADD(MONTH, -12, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)), 112) AND CONVERT(VARCHAR(8), eomonth(dateadd(MONTH,-1,GETDATE())), 112) 
				GROUP BY CONVERT(VARCHAR(8),EOMONTH(dd.FullDate), 112) 
				)	
		  AND Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')
		  AND IsCreditReportValidCB = 1
		GROUP BY DateID, Date
	)cb 
	LEFT JOIN (
		SELECT 
			DateID,
			sum(COALESCE(ClosingBalance,0)-COALESCE(RealCryptoClosingBalance,0)-COALESCE(RealStocksClosingBalance,0)-COALESCE(RealFuturesClosingBalance,0)+COALESCE(actualNWA,0)) AS AdjNegativeBalance
		FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New 
		WHERE DateID  IN (
				SELECT CONVERT(VARCHAR(8),EOMONTH(dd.FullDate), 112)  MonthEndDateID
				FROM DWH_dbo.Dim_Date dd 
				WHERE dd.DateKey BETWEEN CONVERT(VARCHAR(8), DATEADD(MONTH, -12, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)), 112) AND CONVERT(VARCHAR(8), eomonth(dateadd(MONTH,-1,GETDATE())), 112) 
				GROUP BY CONVERT(VARCHAR(8),EOMONTH(dd.FullDate), 112) 
				)
		  AND Regulation IN ('FinCEN','FinCEN+FINRA')
		  AND TransferDirection = 1
		  AND COALESCE(ClosingBalance,0)- COALESCE(RealCryptoClosingBalance,0)- COALESCE(RealStocksClosingBalance,0)- COALESCE(RealFuturesClosingBalance,0)+ COALESCE(actualNWA,0) < 0
		  AND IsCreditReportValidCB = 1
		GROUP BY DateID
	)nb 
		on cb.DateID = nb.DateID
)cash   
on ddr.DateMinus1 = cash.EoM
left join 
(
	SELECT 
		EOMONTH(TradeDate) EoM , 
		sum(CASE WHEN InstrumentType='Equity' THEN abs(CustomerPFOFPayback) END) AS EquitiesPFOF,
		sum(CASE WHEN InstrumentType='Option' THEN abs(CustomerPFOFPayback) END) AS OptionsPFOF
	FROM [BI_DB_dbo].[Sodreconciliation_apex_EXT1047_RevenueReports]
	WHERE TradeDate BETWEEN DATEADD(MONTH, -12, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AND eomonth(dateadd(MONTH,-1,GETDATE()))
	GROUP BY EOMONTH(TradeDate)
)pfof 
on ddr.DateMinus1 = pfof.EoM
left join 
(
	SELECT eomonth(tr.ProcessDate) EoM, 
			sum(ABS(tr.Quantity)) *0.5 AS UK_OptionsContractFee
	FROM 
		[BI_DB_dbo].[External_Sodreconciliation_apex_EXT872_TradeActivity] tr 
	WHERE 
		--tr.OfficeCode='4GS'
		 tr.RegisteredRepCode='UK1'
		AND tr.MarketCode = '5' 
		AND tr.ProcessDate BETWEEN DATEADD(MONTH, -12, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AND eomonth(dateadd(MONTH,-1,GETDATE()))
	GROUP BY eomonth(tr.ProcessDate) 
)uk 
	on uk.EoM=ddr.DateMinus1
left join 
(
	SELECT
		p.ProcessDate AS AdjEoM, 
		m.EOM AS TargetEoM, 
		SUM(p.TotalEquity) AS OptionsEquity
	FROM [BI_DB_dbo].[External_Sodreconciliation_apex_EXT981_BuyPowerSummary] AS p
	JOIN (   -- skip weekends/NYSE holidays: For each calendar month‐end, find MIN(ProcessDate) ≥ that EOM
			SELECT me.EOM,MIN(t.ProcessDate) AS FirstAvailProcessDate
			FROM (
					SELECT DISTINCT EOMONTH(dd.FullDate) AS EOM
					FROM DWH_dbo.Dim_Date AS dd
					WHERE dd.FullDate BETWEEN DATEADD(MONTH, -12, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AND EOMONTH(DATEADD(MONTH, -1, GETDATE()))
				) AS me
			JOIN [BI_DB_dbo].[External_Sodreconciliation_apex_EXT981_BuyPowerSummary] AS t
					ON t.ProcessDate >= me.EOM AND t.OfficeCode IN ('4GS','5GU')
			GROUP BY me.EOM
		 ) AS m
			ON p.ProcessDate = m.FirstAvailProcessDate
	WHERE p.OfficeCode IN ('4GS','5GU')
		AND p.AccountNumber NOT IN ('4GS43999','3ET00001','3ET00100','3ET00101','3ET00002','3ET05007','4GS00103','4GS00104','4GS00101','4GS00100')
	GROUP BY p.ProcessDate, m.EOM
)ops_e
    on ops_e.TargetEoM=ddr.DateMinus1