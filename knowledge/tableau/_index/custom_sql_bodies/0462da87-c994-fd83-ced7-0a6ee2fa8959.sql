SELECT DISTINCT 
	--DATEPART(WEEKDAY, ddr.DateMinus1) AS Weekday,
	ddr.*,
        cash.MSBCashBalance,

	 CASE 
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=7 THEN lag(ISNULL(OptionsWithdrawals_CIDCount, 0)) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=1 THEN lag(ISNULL(OptionsWithdrawals_CIDCount, 0),2) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1) BETWEEN 2 AND 6 THEN ISNULL(OptionsWithdrawals_CIDCount, 0)
	END AS OptionsWithdrawals_CIDCount
	, CASE 
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=7 THEN lag(ISNULL(OptionsWithdrawalsCount, 0)) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=1 THEN lag(ISNULL(OptionsWithdrawalsCount, 0),2) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1) BETWEEN 2 AND 6 THEN ISNULL(OptionsWithdrawalsCount, 0)
	END AS OptionsWithdrawalsCount
	, CASE 
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=7 THEN lag(ISNULL(OptionsWithdrawalsSum, 0)) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=1 THEN lag(ISNULL(OptionsWithdrawalsSum, 0),2) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1) BETWEEN 2 AND 6 THEN ISNULL(OptionsWithdrawalsSum, 0)
	END AS OptionsWithdrawalsSum
	, ISNULL(EquitiesPFOF, 0) AS EquitiesPFOF
	, ISNULL(OptionsPFOF, 0) AS OptionsPFOF
	, ISNULL(UK_OptionsContractFee, 0) AS UK_OptionsContractFee,

/*	, CASE 
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=7 THEN lag(ISNULL(EquitiesPFOF, 0)) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=1 THEN lag(ISNULL(EquitiesPFOF, 0),2) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1) BETWEEN 2 AND 6 THEN ISNULL(EquitiesPFOF, 0)
	END AS EquitiesPFOF
	, CASE 
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=7 THEN lag(ISNULL(OptionsPFOF, 0)) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=1 THEN lag(ISNULL(OptionsPFOF, 0),2) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1) BETWEEN 2 AND 6 THEN ISNULL(OptionsPFOF, 0)
	END AS OptionsPFOF
	, CASE 
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=7 THEN lag(ISNULL(UK_OptionsContractFee, 0)) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1)=1 THEN lag(ISNULL(UK_OptionsContractFee, 0),2) OVER (ORDER BY ddr.DateMinus1)
		WHEN DATEPART(WEEKDAY, ddr.DateMinus1) BETWEEN 2 AND 6 THEN ISNULL(UK_OptionsContractFee, 0)
	END AS UK_OptionsContractFee,

    ISNULL(OptionsWithdrawals_CIDCount, 0) OptionsWithdrawals_CIDCount, 
    ISNULL(OptionsWithdrawalsCount, 0) OptionsWithdrawalsCount, 
    ISNULL(OptionsWithdrawalsSum, 0) OptionsWithdrawalsSum, 
    ISNULL(EquitiesPFOF, 0) EquitiesPFOF, 
    ISNULL(OptionsPFOF, 0) OptionsPFOF, 
    ISNULL(UK_OptionsContractFee, 0) UK_OptionsContractFee, 
*/
    --ISNULL(ClubMember_Count, 0) ClubMember_Count,
    ISNULL(OptionsEquity, 0) OptionsEquity,

    COALESCE(
        OptionsEquity,
        MAX(OptionsEquity) OVER (
            ORDER BY ddr.DateMinus1
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        )
    ) AS OptionsEquity_Adj,
	
    w_in.USD                AS USDCustomerMoneyInFromOutside,
    w_in.CountActions       AS CountActions_CustomerMoneyInFromOutside,
    w_in.CountUsers         AS CountUsers_CustomerMoneyInFromOutside,
    
    w_out.USD               AS USDCustomerMoneyOut,
    w_out.CountActions      AS CountActions_CustomerMoneyOut,
    w_out.CountUsers        AS CountUsers_CustomerMoneyOut,

    redeems.USDRedeem       AS USDRedeemIntoWallet,
    redeems.CountActions    AS CountActions_RedeemIntoWallet,
    redeems.CountUsers      AS CountUsers_RedeemIntoWallet, 
    
    -- Combined totals
    w_in.USD + redeems.USDRedeem AS USDTotalMoneyIn,
    w_in.CountActions + redeems.CountActions AS CountActions_TotalMoneyIn,
    
    -- Unique CID count for combined MoneyInFromOutside and RedeemIntoWallet
    ISNULL(uniques.TotalUniqueCID, 0) AS UniqueCID_TotalMoneyIn

FROM 
(
	select 
		DATEADD(DAY,-1, ReportDate) DateMinus1,
     sum(
		ISNULL([OvernightFee],0) -
			ISNULL([DividendsPaid],0) -
			(-1 * ISNULL([SDRT],0)) -
			(-1 * ISNULL([TicketFees],0)) 
		) AS cal_rollover_fee,
 	SUM(	
		ISNULL([FullTotalCommission],0)+
		ISNULL([InterestFees],0)   +
		ISNULL([ConversionFees],0) +
		ISNULL([DormantFee],0)     +
		(-1*ISNULL(TradingFees,0) - (-1 * ISNULL(TicketFees,0)) )
		+
		(
			ISNULL([OvernightFee],0) -
			ISNULL([DividendsPaid],0) -
			(-1 * ISNULL([SDRT],0)) -
			(-1 * ISNULL([TicketFees],0))
		)+
		-1 * ISNULL([SDRT],0)+
		ISNULL([TransferCoinFees],0)+
		ISNULL([CashoutFee],0)+
		-1 * ISNULL([TicketFees],0)
	)
		AS DDRdailyRevenue
		 , SUM(isnull(Cashouts							,0)) as Cashouts							
		 , SUM(ISNULL(TransferCoins						,0)) as CoinRedeem
		 , SUM(isnull(CashoutsAdjusted					,0)) as CashoutsAdjusted									
		 , SUM(isnull(CryptoCommission					,0))  as CryptoCommission		
		 , sum(ISNULL(CopyCommission					,0)) AS CopyCommission
		 , SUM(isnull(InterestFees 						,0)) as InterestFees 
		 , SUM(isnull(ConversionFees 					,0)) as ConversionFees 
		 , SUM(isnull(DormantFee 						,0)) as DormantFee
		 , SUM(isnull(-1 * SDRT 						,0)) as SDRT
		 , SUM(ISNULL(-1 * TradingFees					,0)) AS TradingFees
		 , SUM(ISNULL(-1 * TicketFees					,0)) AS TicketFees
		 , SUM(isnull(CashoutFee						,0)) AS CashoutFee						
		 , SUM(isnull(TransferCoinFees					,0)) as CoinTransferFees
		 , sum(ISNULL(Equity							,0)) AS Equity
         , sum(ISNULL(CashoutsCount						,0)) AS CashoutsCount
		 , sum(ISNULL(CashedOut							,0)) AS Cashouts_CIDCount,

                    sum(InvestedInStocksManual) InvestedInStocksManual, 
                    sum(InvestedInCryptoManual) InvestedInCryptoManual, 
                    sum(InvestedInCopyIncludingCash) InvestedInCopyIncludingCash,
                    sum(InProcessCashout) InProcessCashout, 
                    sum(Credit) Credit

	from BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] 
	WHERE DATEADD(DAY,-1, ReportDate) >= DATEADD(WEEK, -10, GETDATE())	
	--AND Region='USA'
	and IsCreditReportValidCB=1
	AND IsValidCustomer=1
	AND Regulation in ('eToroUS','FinCEN','FinCEN+FINRA','NYDFS+FINRA')
	--AND Country='United States' 
	AND TimeRange = 'Yesterday'
	GROUP BY DATEADD(DAY,-1, ReportDate) 
) ddr 
left JOIN (
	SELECT ProcessDate, 
        count(distinct AccountNumber) OptionsWithdrawals_CIDCount,
        count(DISTINCT ACATSControlNumber) OptionsWithdrawalsCount, 
        sum(Amount) OptionsWithdrawalsSum
	FROM [BI_DB_dbo].[External_Sodreconciliation_apex_EXT869_CashActivity] 
	WHERE OfficeCode IN ('4GS','5GU')
		AND RegisteredRepCode IN ('GAT','FO1')
		AND (EnteredBy IN ('ACH','WRD'))
		AND AccountNumber NOT IN ('4GS43999', '3ET00001', '3ET00100', '3ET00101', '3ET00002', '3ET05007', '4GS00103', '4GS00104', '4GS00101', '4GS00100')
		AND PayTypeCode = 'D'  -- For withdraw
		AND ProcessDate >= DATEADD(WEEK, -10, GETDATE())	
		--qa, AND AccountNumber='4GS06154'
	GROUP BY ProcessDate
) op_wit 
	ON op_wit.ProcessDate=ddr.DateMinus1

left JOIN (
	SELECT TradeDate, 
		sum(CASE WHEN InstrumentType='Equity' THEN abs(CustomerPFOFPayback) END) AS EquitiesPFOF,
		sum(CASE WHEN InstrumentType='Option' THEN abs(CustomerPFOFPayback) END) AS OptionsPFOF
		--sum() PFOF --, sum(abs(TotalQuantity)) Shares, count(DISTINCT OrderID) TradeCount
	FROM [BI_DB_dbo].[Sodreconciliation_apex_EXT1047_RevenueReports]
	WHERE TradeDate  >= DATEADD(WEEK, -10, GETDATE()) 
	GROUP BY TradeDate
)pfof 
	on ddr.DateMinus1=pfof.TradeDate

left JOIN (
	SELECT tr.ProcessDate, sum(ABS(tr.Quantity)) *0.5 AS UK_OptionsContractFee
	FROM 
		[BI_DB_dbo].[External_Sodreconciliation_apex_EXT872_TradeActivity] tr 
	WHERE 
		tr.RegisteredRepCode='UK1'
		AND tr.MarketCode = '5' 
		AND tr.ProcessDate >= DATEADD(WEEK, -10, GETDATE())	
	GROUP BY tr.ProcessDate
)uk 
	on uk.ProcessDate=ddr.DateMinus1

left JOIN (
	SELECT  
		DATEADD(DAY,-1, ReportDate) DateMinus1,  
		SUM(CountUsers) ClubMember_Count   --equity is a accumalative value 
	 FROM BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level]
	 WHERE DATEADD(DAY,-1, ReportDate) >= DATEADD(WEEK, -10, GETDATE())	
	 AND Region = 'USA' AND IsCreditReportValidCB=1 AND IsValidCustomer =1 
	 AND TimeRange='Yesterday' AND PlayerLevel IN ('Diamond','Platinum Plus', 'Platinum', 'Gold', 'Silver')
	 AND Regulation IN ('FinCEN+FINRA', 'FinCEN', 'FINRAONLY','NYDFS+FINRA')
	 GROUP BY DATEADD(DAY,-1, ReportDate)
)club
on ddr.DateMinus1=club.DateMinus1
LEFT JOIN (
	SELECT ProcessDate, sum(TotalEquity) OptionsEquity
	FROM [BI_DB_dbo].[External_Sodreconciliation_apex_EXT981_BuyPowerSummary]
	WHERE OfficeCode IN ('4GS','5GU')
	AND AccountNumber NOT IN ('4GS43999', '3ET00001', '3ET00100', '3ET00101', '3ET00002', '3ET05007', '4GS00103', '4GS00104', '4GS00101', '4GS00100')
	AND ProcessDate >= DATEADD(WEEK, -10, GETDATE())	
	GROUP BY ProcessDate 
	--ORDER BY ProcessDate 
)ops_equity
ON ddr.DateMinus1=ops_equity.ProcessDate

LEFT JOIN (
    SELECT 
        'CustomerMoneyOut' AS WalletActivity,
        SUM(eft.AmountUSD) AS USD,
        COUNT(DISTINCT edu.RealCID) AS CountUsers,
        COUNT(eft.TranID) AS CountActions,
        eft.TranDate
    FROM EXW_dbo.EXW_FactTransactions eft 
    JOIN EXW_dbo.EXW_DimUser edu ON eft.GCID = edu.GCID 
    WHERE eft.ActionTypeID = 1
      AND eft.GCID > 0
      AND eft.TransactionTypeID = 1
      AND edu.IsTestAccount = 0
      AND eft.TranStatusID = 2
      AND eft.TranDate >= DATEADD(WEEK, -10, GETDATE())
      AND edu.CountryID = 219
    GROUP BY eft.TranDate
) w_out ON ddr.DateMinus1 = w_out.TranDate

LEFT JOIN (
    SELECT 
        'CustomerMoneyInFromOutside' AS WalletActivity,
        SUM(eft.AmountUSD) AS USD,
        COUNT(DISTINCT edu.RealCID) AS CountUsers,
        COUNT(eft.TranID) AS CountActions,
        eft.TranDate
    FROM EXW_dbo.EXW_FactTransactions eft 
    JOIN EXW_dbo.EXW_DimUser edu ON eft.GCID = edu.GCID 
    WHERE eft.ActionTypeID = 2
      AND eft.GCID > 0
      AND edu.IsTestAccount = 0
      AND eft.TranStatusID = 2
      AND eft.IsRedeem = 0 
      AND eft.IsConversion = 0 
      AND eft.IsPayment = 0 
      AND ISNULL(eft.ReceivedTransactionTypeID, 0) NOT IN (8, 3)
      AND eft.TranDate >= DATEADD(WEEK, -10, GETDATE())
      AND edu.CountryID = 219
    GROUP BY eft.TranDate
) w_in ON ddr.DateMinus1 = w_in.TranDate

LEFT JOIN (
    SELECT 
        'RedeemIntoWallet' AS WalletActivity,
        SUM(err.[etoro - Amount]) AS USDRedeem,
        COUNT(DISTINCT edu.RealCID) AS CountUsers,
        COUNT(err.RedeemID) AS CountActions,
        CAST(err.[etoro - ModificationDate] AS DATE) AS TranDate
    FROM EXW_dbo.EXW_RedeemReconciliation err 
    JOIN EXW_dbo.EXW_DimUser edu ON edu.GCID = err.[Wallet - RequestingGCID]
    WHERE CAST(err.[etoro - ModificationDate] AS DATE) >= DATEADD(WEEK, -10, GETDATE())
      AND err.EntryAppears = 'BothSidesEntry'
      AND err.[etoro - RedeemStatus] = 'TransactionDone'
      AND edu.IsTestAccount = 0
      AND edu.CountryID = 219
    GROUP BY CAST(err.[etoro - ModificationDate] AS DATE)
) redeems ON ddr.DateMinus1 = redeems.TranDate

-- Full outer join of unique CIDs across `MoneyInFromOutside` and `RedeemIntoWallet`
LEFT JOIN (
    SELECT 
        COALESCE(in_from_outside.TranDate, redeem_in.TranDate) AS TranDate,
        COUNT(DISTINCT COALESCE(in_from_outside.RealCID, redeem_in.RealCID)) AS TotalUniqueCID
    FROM 
        (SELECT DISTINCT edu.RealCID, eft.TranDate
         FROM EXW_dbo.EXW_FactTransactions eft
         JOIN EXW_dbo.EXW_DimUser edu ON eft.GCID = edu.GCID
         WHERE eft.ActionTypeID = 2
           AND eft.TranDate >= DATEADD(WEEK, -10, GETDATE())
           AND edu.IsTestAccount = 0
           AND edu.CountryID = 219
        ) in_from_outside
    FULL OUTER JOIN 
        (SELECT DISTINCT edu.RealCID, CAST(err.[etoro - ModificationDate] AS DATE) AS TranDate
         FROM EXW_dbo.EXW_RedeemReconciliation err
         JOIN EXW_dbo.EXW_DimUser edu ON edu.GCID = err.[Wallet - RequestingGCID]
         WHERE CAST(err.[etoro - ModificationDate] AS DATE) >= DATEADD(WEEK, -10, GETDATE())
           AND err.EntryAppears = 'BothSidesEntry'
           AND err.[etoro - RedeemStatus] = 'TransactionDone'
           AND edu.IsTestAccount = 0
           AND edu.CountryID = 219
        ) redeem_in ON in_from_outside.TranDate = redeem_in.TranDate
    GROUP BY COALESCE(in_from_outside.TranDate, redeem_in.TranDate)
) uniques ON ddr.DateMinus1 = uniques.TranDate
LEFT JOIN (
SELECT 
    --cb.DateID, 
    cb.Date, 
    COALESCE(cb.AdjustedClosingBalance,0)
    - COALESCE(nb.AdjNegativeBalance,0)
    - COALESCE(cb.less_affiliate_clients,0)
    - COALESCE(cb.less_RealCryptoAdjusted,0) AS MSBCashBalance
FROM (
    SELECT 
        DateID, 
        Date,
        SUM(COALESCE(ClosingBalance, 0)) AS ClosingBalance,
        SUM(CASE 
                WHEN Regulation in ('FinCEN+FINRA','NYDFS+FINRA')
                THEN COALESCE(ClosingBalance, 0) - COALESCE(RealStocksClosingBalance, 0)
                ELSE COALESCE(ClosingBalance, 0)
            END) AS AdjustedClosingBalance,
        SUM(COALESCE(
                CASE 
                    WHEN AccountType IN ('Affiliate Corporate Account', 'Affiliate Private Account')  
                         AND PlayerStatus = 'Trade & MIMO Blocked'
                    THEN 
                        CASE 
                            WHEN Regulation in ('FinCEN+FINRA','NYDFS+FINRA')
                            THEN COALESCE(ClosingBalance, 0) - COALESCE(RealStocksClosingBalance, 0)
                            ELSE COALESCE(ClosingBalance, 0)
                        END
                END, 0)) AS less_affiliate_clients,
        SUM(COALESCE(TotalRealCrypto, 0) + COALESCE(PositionPNLCryptoReal, 0)) AS less_RealCryptoAdjusted
    FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New 
    WHERE DateID >= CONVERT(nvarchar(8), DATEADD(WEEK, -10, GETDATE()), 112)	
      AND Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA','NYDFS+FINRA')
      AND IsCreditReportValidCB = 1
    GROUP BY DateID, Date
)cb 
LEFT JOIN (
    SELECT 
        DateID,
        SUM(COALESCE(ClosingBalance,0) 
        - COALESCE(RealCryptoClosingBalance,0) 
        - COALESCE(RealStocksClosingBalance,0) 
        - COALESCE(RealFuturesClosingBalance,0) 
        + COALESCE(actualNWA,0)) AS AdjNegativeBalance
    FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New 
    WHERE DateID >=  CONVERT(nvarchar(8), DATEADD(WEEK, -10, GETDATE()), 112)	
      AND Regulation IN ('FinCEN','FinCEN+FINRA','NYDFS+FINRA')
      AND TransferDirection = 1
      AND (COALESCE(ClosingBalance,0) 
           - COALESCE(RealCryptoClosingBalance,0) 
           - COALESCE(RealStocksClosingBalance,0) 
           - COALESCE(RealFuturesClosingBalance,0) 
           + COALESCE(actualNWA,0)) < 0
      AND IsCreditReportValidCB = 1
    GROUP BY DateID
)nb 
	on cb.DateID = nb.DateID
)cash
on cash.Date=ddr.DateMinus1