---2025.08.06 note: this is for US Monthly KPI dashboard;
-------- this contains last month and previous month data only

/* topics include: 
- ICT (instant cash transfer): between TP & options account (non-FINRAONLY)
- wallet in & out

*/

select 
    wallet.*,
    CountAccount_main_to_ops, 
	CountAccount_ops_to_main, 
	CountAction_main_to_ops, 
	CountAction_ops_to_main, 
	AbsAmount_main_to_ops, 
	AbsAmount_ops_to_main
from
(
    SELECT  
    EOMONTH(TranDate) AS EoM,

        SUM(CASE WHEN WalletActivity = 'CustomerMoneyOut' THEN AmountUSD_Daily ELSE 0 END)           AS USDCustomerMoneyOut,
        SUM(CASE WHEN WalletActivity = 'CustomerMoneyInFromOutside' THEN AmountUSD_Daily ELSE 0 END) AS USDCustomerMoneyInFromOutside,
        SUM(CASE WHEN WalletActivity = 'RedeemIntoWallet' THEN AmountUSD_Daily ELSE 0 END)           AS USDRedeemIntoWallet,
        
        SUM(CASE WHEN WalletActivity = 'CustomerMoneyOut' THEN CountActions_Daily ELSE 0 END)           AS CountActions_CustomerMoneyOut,
        SUM(CASE WHEN WalletActivity = 'CustomerMoneyInFromOutside' THEN CountActions_Daily ELSE 0 END) AS CountActions_CustomerMoneyInFromOutside,
        SUM(CASE WHEN WalletActivity = 'RedeemIntoWallet' THEN CountActions_Daily  ELSE 0 END)          AS CountActions_RedeemIntoWallet,

        -- Unique user counts
        COUNT(DISTINCT CASE WHEN WalletActivity = 'CustomerMoneyOut' THEN RealCID END)                  AS CountUsers_CustomerMoneyOut,
        COUNT(DISTINCT CASE WHEN WalletActivity = 'CustomerMoneyInFromOutside' THEN RealCID END)        AS CountUsers_CustomerMoneyInFromOutside,
        COUNT(DISTINCT CASE WHEN WalletActivity = 'RedeemIntoWallet' THEN RealCID END)                  AS CountUsers_RedeemIntoWallet,

        -- Unique CID count for combined MoneyInFromOutside and RedeemIntoWallet
        COUNT(distinct CASE WHEN WalletActivity in ('RedeemIntoWallet','CustomerMoneyInFromOutside') THEN RealCID END)  AS UniqueCID_TotalMoneyIn,
        
        -- Combined totals OF MONEY IN
        SUM(CASE WHEN WalletActivity in ('RedeemIntoWallet','CustomerMoneyInFromOutside') THEN AmountUSD_Daily END)     AS USDTotalMoneyIn,
        SUM(CASE WHEN WalletActivity in ('RedeemIntoWallet','CustomerMoneyInFromOutside') THEN CountActions_Daily END)  AS CountActions_TotalMoneyIn

    FROM 
    (
        SELECT 
            'CustomerMoneyOut' AS WalletActivity,
            eft.TranDate,
            edu.RealCID,
            COUNT(eft.TranID) AS CountActions_Daily,
            SUM(eft.AmountUSD) AS AmountUSD_Daily
        FROM EXW_dbo.EXW_FactTransactions eft 
        JOIN EXW_dbo.EXW_DimUser edu ON eft.GCID = edu.GCID 
        WHERE eft.ActionTypeID = 1
        AND eft.GCID > 0
        AND edu.IsTestAccount = 0
        AND eft.TranStatusID = 2
        AND eft.TransactionTypeID = 1
        AND eft.TranDate BETWEEN DATEADD(MONTH, -2, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AND eomonth(dateadd(MONTH,-1,GETDATE()))
        AND edu.CountryID = 219
        GROUP BY 
            eft.TranDate, edu.RealCID

        UNION ALL

        SELECT 
            'CustomerMoneyInFromOutside' AS WalletActivity,
            eft.TranDate,
            edu.RealCID,
            COUNT(eft.TranID) AS CountActions_Daily,
            SUM(eft.AmountUSD) AS AmountUSD_Daily
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
            AND eft.TranDate BETWEEN DATEADD(MONTH, -2, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AND eomonth(dateadd(MONTH,-1,GETDATE()))
            AND edu.CountryID = 219
        GROUP BY 
            eft.TranDate, edu.RealCID

        UNION ALL 

        SELECT 
            'RedeemIntoWallet' AS WalletActivity,
            CAST(err.[etoro - ModificationDate] AS DATE) AS TranDate,
            edu.RealCID,
            COUNT(err.RedeemID) AS CountActions_Daily,
            SUM(err.[etoro - Amount]) AS AmountUSD_Daily
        FROM EXW_dbo.EXW_RedeemReconciliation err 
        JOIN EXW_dbo.EXW_DimUser edu ON edu.GCID = err.[Wallet - RequestingGCID]
        WHERE CAST(err.[etoro - ModificationDate] AS DATE) BETWEEN DATEADD(MONTH, -2, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AND eomonth(dateadd(MONTH,-1,GETDATE()))
            AND err.EntryAppears = 'BothSidesEntry'
            AND err.[etoro - RedeemStatus] = 'TransactionDone'
            AND edu.IsTestAccount = 0
            AND edu.CountryID = 219
        GROUP BY 
            CAST(err.[etoro - ModificationDate] AS DATE),
            edu.RealCID
    ) w 
    GROUP BY 
        EOMONTH(TranDate)
) wallet

join 
(
    	SELECT eomonth(ProcessDate) EoM, 
    
		count(DISTINCT CASE WHEN PayTypeCode='C' THEN AccountNumber end)        AS CountAccount_main_to_ops, 
		count(DISTINCT CASE WHEN PayTypeCode='D' THEN AccountNumber end)        AS CountAccount_ops_to_main, 

		count(DISTINCT CASE WHEN PayTypeCode='C' THEN ACATSControlNumber end)   AS CountAction_main_to_ops, 
		count(DISTINCT CASE WHEN PayTypeCode='D' THEN ACATSControlNumber end)   AS CountAction_ops_to_main, 

		sum(CASE WHEN PayTypeCode='C' THEN abs(Amount) end)                     AS AbsAmount_main_to_ops, 
		sum(CASE WHEN PayTypeCode='D' THEN abs(Amount) end)                     AS AbsAmount_ops_to_main
	FROM [BI_DB_dbo].[External_Sodreconciliation_apex_EXT869_CashActivity]
	WHERE OfficeCode IN ('4GS','5GU')  
		AND RegisteredRepCode IN ('GAT', 'FO1')
		and (TerminalID = 'OMJNL')
		AND AccountNumber not in ('4GS43999','3ET00001','3ET00100','3ET00101','3ET00002','3ET05007','4GS00103','4GS00104','4GS00101','4GS00100')
		AND ProcessDate BETWEEN DATEADD(MONTH, -2, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AND eomonth(dateadd(MONTH,-1,GETDATE()))
	GROUP BY eomonth(ProcessDate)
)ict 

on  wallet.EoM = ict.EoM