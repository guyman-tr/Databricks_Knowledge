---

SELECT 'FTF' AS Indicator
       ,'This Month' AS Period
 ,NULL AS Indicator_A
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL AS EOM_IsFundedNew
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE fd.FirstDepositDate IS NOT NULL
AND fd.FirstNewFundedDate IS NOT NULL
AND DATEDIFF(m, fd.FirstNewFundedDate, GETDATE()-1) = 0
GROUP BY fd.Region

UNION


SELECT 'FTF' AS Indicator
       ,'Last Month' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE fd.FirstDepositDate IS NOT NULL
AND fd.FirstNewFundedDate IS NOT NULL
AND DATEPART(m, fd.FirstNewFundedDate) = DATEPART(m, DATEADD(m, -1, getdate()-1))
AND DATEPART(yyyy, fd.FirstNewFundedDate) = DATEPART(yyyy, DATEADD(m, -1, getdate()-1))
GROUP BY fd.Region
UNION

SELECT 'FTF' AS Indicator
       ,'This Quarter' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE fd.FirstDepositDate IS NOT NULL
AND fd.FirstNewFundedDate IS NOT NULL
AND YEAR(fd.FirstNewFundedDate) = YEAR(GETDATE()-1)
AND  DATEPART(QUARTER,fd.FirstNewFundedDate) = DATEPART(QUARTER,GETDATE()-1)
GROUP BY fd.Region
UNION



SELECT 'FTF' AS Indicator
       ,'Last Quarter' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE fd.FirstDepositDate IS NOT NULL
AND fd.FirstNewFundedDate IS NOT NULL
AND DATEPART(q, fd.FirstNewFundedDate) = DATEPART(q, DATEADD(q, -1, getdate()-1))
AND DATEPART(yyyy, fd.FirstNewFundedDate) = DATEPART(yyyy, DATEADD(q, -1, getdate()-1))
GROUP BY fd.Region

UNION

SELECT 'FTF' AS Indicator
       ,'This Year' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE fd.FirstDepositDate IS NOT NULL
AND fd.FirstNewFundedDate IS NOT NULL
AND YEAR(fd.FirstNewFundedDate) = YEAR(GETDATE()-1)
GROUP BY fd.Region

UNION

SELECT 'FTF' AS Indicator
       ,'Same Time Last Year' AS Period
       ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE fd.FirstDepositDate IS NOT NULL
AND fd.FirstNewFundedDate IS NOT NULL
AND YEAR(fd.FirstNewFundedDate) = YEAR(dateadd(YEAR,-1,GETDATE()-1))
AND  MONTH(fd.FirstNewFundedDate) <= MONTH(dateadd(YEAR,-1,GETDATE()-1))
GROUP BY fd.Region
UNION
--Regs

SELECT 'Reg' AS Indicator
       ,'This Month' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE  DATEDIFF(m, fd.registered, GETDATE()-1) = 0
GROUP BY fd.Region
UNION

SELECT 'Reg' AS Indicator
       ,'Last Month' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE  DATEPART(m, fd.registered) = DATEPART(m, DATEADD(m, -1, getdate()-1))
AND DATEPART(yyyy, fd.registered) = DATEPART(yyyy, DATEADD(m, -1, getdate()-1))
GROUP BY fd.Region
UNION

SELECT 'Reg' AS Indicator

       ,'This Quarter' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE  YEAR(fd.registered) = YEAR(GETDATE()-1)
AND  DATEPART(QUARTER,fd.registered) = DATEPART(QUARTER,GETDATE()-1)
GROUP BY fd.Region
UNION

SELECT 'Reg' AS Indicator
       ,'Last Quarter' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE  DATEPART(q, fd.registered) = DATEPART(q, DATEADD(q, -1, getdate()-1))
AND DATEPART(yyyy, fd.registered) = DATEPART(yyyy, DATEADD(q, -1, getdate()-1))
GROUP BY fd.Region
UNION

SELECT 'Reg' AS Indicator
       ,'This Year' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE YEAR(fd.registered) = YEAR(GETDATE()-1)
GROUP BY fd.Region


UNION

SELECT 'Reg' AS Indicator
       ,'Same Time Last Year' AS Period
,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE   YEAR(fd.registered) = YEAR(dateadd(YEAR,-1,GETDATE()-1))
AND  MONTH(fd.registered) <= MONTH(dateadd(YEAR,-1,GETDATE()-1))
GROUP BY fd.Region
UNION

SELECT 'Reg' AS Indicator
       ,'Monthly' AS Period
 ,NULL
       ,DATEFROMPARTS(YEAR(fd.registered),MONTH(fd.registered),1) AS Date
       ,COUNT(*) CIDs
,NULL
  ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE   YEAR(fd.registered) >= 2015
GROUP BY  DATEFROMPARTS(YEAR(fd.registered),MONTH(fd.registered),1),fd.Region

UNION

---New Trades


SELECT  'NewTrades' AS Indicator
       ,'This Month' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE)
       ,COUNT(DISTINCT CASE WHEN mp.IsFunded_New = 1 THEN mp.CID END)
,COUNT(DISTINCT CASE WHEN mp.IsEOM_Funded_NEW = 1 THEN mp.CID END)
  ,fd.Region
,NULL AS TotalAge
,SUM(mp.NewTrades_Total) NewTrades_Total
,SUM(mp.NewTrades_Copy) NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
ON mp.CID = fd.CID  AND fd.FirstDepositDate IS NOT NULL
WHERE  DATEDIFF(m, mp.ActiveDate, GETDATE()-1) = 0
GROUP BY fd.Region
UNION

SELECT 'NewTrades' AS Indicator
       ,'Last Month' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(DISTINCT CASE WHEN mp.IsFunded_New = 1 THEN mp.CID END)
,COUNT(DISTINCT CASE WHEN mp.IsEOM_Funded_NEW = 1 THEN mp.CID END)
  ,fd.Region
,NULL AS TotalAge
,SUM(mp.NewTrades_Total) NewTrades_Total
,SUM(mp.NewTrades_Copy) NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
ON mp.CID = fd.CID AND fd.FirstDepositDate IS NOT NULL
WHERE  DATEPART(m, mp.ActiveDate) = DATEPART(m, DATEADD(m, -1, getdate()-1))
AND DATEPART(yyyy, mp.ActiveDate) = DATEPART(yyyy, DATEADD(m, -1, getdate()-1))
GROUP BY fd.Region
UNION

SELECT  'NewTrades' AS Indicator
       ,'This Quarter' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE)
       ,COUNT(DISTINCT CASE WHEN mp.IsFunded_New = 1 THEN mp.CID END)
,COUNT(DISTINCT CASE WHEN mp.IsEOM_Funded_NEW = 1 THEN mp.CID END)
  ,fd.Region
,NULL AS TotalAge
,SUM(mp.NewTrades_Total) NewTrades_Total
,SUM(mp.NewTrades_Copy) NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
ON mp.CID = fd.CID AND fd.FirstDepositDate IS NOT NULL
WHERE YEAR(mp.ActiveDate) = YEAR(GETDATE()-1)
AND  DATEPART(QUARTER,mp.ActiveDate) = DATEPART(QUARTER,GETDATE()-1)
GROUP BY fd.Region

UNION

SELECT 'NewTrades' AS Indicator
       ,'Last Quarter' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE) AS Date
       ,COUNT(DISTINCT CASE WHEN mp.IsFunded_New = 1 THEN mp.CID END)
,COUNT(DISTINCT CASE WHEN mp.IsEOM_Funded_NEW = 1 THEN mp.CID END)
  ,fd.Region
,NULL AS TotalAge
,SUM(mp.NewTrades_Total) NewTrades_Total
,SUM(mp.NewTrades_Copy) NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
ON mp.CID = fd.CID AND fd.FirstDepositDate IS NOT NULL
WHERE   DATEPART(q, mp.ActiveDate) = DATEPART(q, DATEADD(q, -1, getdate()-1))
AND DATEPART(yyyy, mp.ActiveDate) = DATEPART(yyyy, DATEADD(q, -1, getdate()-1))
GROUP BY fd.Region

UNION

SELECT  'NewTrades' AS Indicator
       ,'This Year' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE)
       ,COUNT(DISTINCT CASE WHEN mp.IsFunded_New = 1 THEN mp.CID END)
,COUNT(DISTINCT CASE WHEN mp.IsEOM_Funded_NEW = 1 THEN mp.CID END)
  ,fd.Region
,NULL AS TotalAge
,SUM(mp.NewTrades_Total) NewTrades_Total
,SUM(mp.NewTrades_Copy) NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
ON fd.CID = mp.CID AND fd.FirstDepositDate IS NOT NULL

WHERE YEAR(mp.ActiveDate) = YEAR(GETDATE()-1)
GROUP BY fd.Region

UNION

SELECT  'NewTrades' AS Indicator
       ,'Same Time Last Year' AS Period
 ,NULL
       ,CAST(GETDATE()-1 AS DATE)
       ,COUNT(DISTINCT CASE WHEN mp.IsFunded_New = 1 THEN mp.CID END)
,COUNT(DISTINCT CASE WHEN mp.IsEOM_Funded_NEW = 1 THEN mp.CID END)
  ,fd.Region
,NULL AS TotalAge
,SUM(mp.NewTrades_Total) NewTrades_Total
,SUM(mp.NewTrades_Copy) NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
ON mp.CID = fd.CID AND fd.FirstDepositDate IS NOT NULL

WHERE   YEAR(mp.ActiveDate) = YEAR(dateadd(YEAR,-1,GETDATE()-1))
AND  MONTH(mp.ActiveDate) <= MONTH(dateadd(YEAR,-1,GETDATE()-1))
GROUP BY fd.Region
UNION

SELECT  'NewTrades' AS Indicator
       ,'Monthly' AS Period
,NULL
       ,mp.ActiveDate
       ,COUNT(DISTINCT CASE WHEN mp.IsFunded_New = 1 THEN mp.CID END)
,COUNT(DISTINCT CASE WHEN mp.IsEOM_Funded_NEW = 1 THEN mp.CID END)
  ,fd.Region
,NULL AS TotalAge
,SUM(mp.NewTrades_Total) NewTrades_Total
,SUM(mp.NewTrades_Copy) NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
ON mp.CID = fd.CID AND fd.FirstDepositDate IS NOT NULL

WHERE   mp.Active_Month >= 2015
GROUP BY mp.ActiveDate,fd.Region

UNION

SELECT  'Revenue' AS Indicator
        ,'Monthly'
 ,NULL
       ,mp.ActiveDate AS Date
       ,COUNT(DISTINCT CASE WHEN  mp.IsFunded_New = 1 THEN mp.CID END) CIDs
,COUNT(DISTINCT CASE WHEN mp.IsEOM_Funded_NEW = 1 THEN mp.CID END)
   ,fd.Region
,NULL AS TotalAge
,SUM(mp.NewTrades_Total)
,SUM(mp.NewTrades_Copy) NewTrades_Copy
,SUM(mp.A_Revenue_Currencies) AS A_Revenue_Currencies
,SUM(mp.A_Revenue_Commodities) AS A_Revenue_Commodities
,SUM(mp.A_Revenue_Crypto) AS A_Revenue_Crypto
,SUM(mp.A_Revenue_Equities) AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
ON mp.CID = fd.CID AND fd.FirstDepositDate IS NOT NULL
GROUP BY  mp.ActiveDate,fd.Region

UNION




SELECT  'Revenue' AS Indicator
 ,'Quarterly'
 ,YEAR(mp.ActiveDate)*100 + DATEPART(QUARTER,mp.ActiveDate)
       ,MIN(mp.ActiveDate) AS Date
       ,COUNT(DISTINCT CASE WHEN  mp.IsFunded_New = 1 THEN mp.CID END) CIDs
,COUNT(DISTINCT CASE WHEN mp.IsEOM_Funded_NEW = 1 THEN mp.CID END)
   ,fd.Region
,NULL AS TotalAge
,SUM(mp.NewTrades_Total)
,SUM(mp.NewTrades_Copy) NewTrades_Copy
,SUM(mp.A_Revenue_Currencies) AS A_Revenue_Currencies
,SUM(mp.A_Revenue_Commodities) AS A_Revenue_Commodities
,SUM(mp.A_Revenue_Crypto) AS A_Revenue_Crypto
,SUM(mp.A_Revenue_Equities) AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd
ON mp.CID = fd.CID AND fd.FirstDepositDate IS NOT NULL
GROUP BY YEAR(mp.ActiveDate)*100 + DATEPART(QUARTER,mp.ActiveDate) ,fd.Region


UNION
SELECT  'Avg Age' AS Indicator
       ,mp.EOM_Club
 ,NULL
       ,mp.ActiveDate AS Date
,COUNT(DISTINCT CASE WHEN  mp.IsFunded_New = 1 THEN mp.CID END) CIDs
,COUNT(DISTINCT CASE WHEN mp.EOM_IsFunded = 1 THEN mp.CID END)
,fd.Region
       ,SUM(DATEDIFF(DAY, fd.BirthDate, GetDate()) / 365.25) AS TotalAge
,0
,0
,0
,0
,0
,0
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
LEFT JOIN dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
ON mp.CID = fd.CID AND fd.FirstDepositDate IS NOT NULL
WHERE IsFunded_New = 1
GROUP BY  mp.ActiveDate ,mp.EOM_Club,fd.Region

UNION
SELECT  'LT Regs' AS Indicator
       ,NULL
 ,NULL
       ,NULL AS Date
,COUNT(*) CIDs
,NULL
,fd.Region
       ,NULL
,0
,0
,0
,0
,0
,0
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM  dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
GROUP BY fd.Region



UNION
SELECT  'LT FTF' AS Indicator
       ,NULL
 ,NULL
       ,NULL AS Date
,COUNT(*) CIDs
,NULL
,fd.Region
       ,NULL
,0
,0
,0
,0
,0
,0
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM  dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE fd.FirstNewFundedDate IS NOT NULL
GROUP BY fd.Region

UNION

SELECT 'FTF' AS Indicator
       ,'Monthly' AS Period
 ,NULL
       ,DATEFROMPARTS(YEAR(fd.FirstNewFundedDate),MONTH(fd.FirstNewFundedDate),1) AS Date
       ,COUNT(*) CIDs
,NULL
   ,fd.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,0 AS EOM_Equity
,0 AS TotalDeposits
,0 AS TotalCashouts
,0 AS TotalPnL
FROM dbo.BI_DB_CIDFirstDates fd WITH(NOLOCK)
WHERE   YEAR(fd.registered) >= 2015
GROUP BY  DATEFROMPARTS(YEAR(fd.FirstNewFundedDate),MONTH(fd.FirstNewFundedDate),1),fd.Region

/**********************************************************************************************************************/

UNION

SELECT 'AUA' AS Indicator
       ,'Monthly' AS Period   --Comment: Jan
 ,NULL
       ,mp.ActiveDate
,COUNT(*) CIDs
,NULL
,mp.Region
,NULL AS TotalAge
,0 NewTrades_Total
,0 NewTrades_Copy
,0 AS A_Revenue_Currencies
,0 AS A_Revenue_Commodities
,0 AS A_Revenue_Crypto
,0 AS A_Revenue_Equities
,SUM(EOM_Equity) EOM_Equity
,SUM(mp.TotalDeposits) TotalDeposits
,SUM(mp.TotalCashouts) TotalCashouts
,SUM(mp.PnL_Total)  PnL_Total
FROM dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH(NOLOCK)
WHERE   mp.Active_Month >= 201501
GROUP BY   mp.ActiveDate
            ,mp.Region