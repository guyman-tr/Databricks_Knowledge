SELECT
 ed.FullDate AS LastDayOfMonth
,a.BalanceUSD
, a.Users
, a.wn 'Wallets inc tokens'
, a.[Zero Wallets]
, a.[Non Zero Wallets]
,b.SentOutUSD
,b.ExternalReceivedUSD
,b.ConversionUSD
,b.RedeemedUSD
,b.PaymentUSD
, b.EtoroFeeUSD
,ed.Regulation
, ed.Region
,ed.Country
,ed.ComplianceClosureEvent AS [Compliance Closure Event]
 -- INTO #temp
 FROM

 (SELECT DISTINCT
edu.Regulation
   , edu.Country
   , edu.ComplianceClosureEvent
   , edu.Region
   , edu.RegionID
   , dd.FullDate
   FROM EXW_dbo.EXW_DimUser edu 
   CROSS APPLY
   (SELECT dd.FullDate
   FROM DWH_dbo.Dim_Date dd
   WHERE  dd.FullDate BETWEEN  dateadd(m,-6,getdate())  AND GETDATE()
 AND   (dd.IsLastDayOfMonth='Y' OR dd.DateKey =CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT))  
 AND edu.IsTestAccount =0
 ) dd ) ed 
 
 LEFT JOIN 
 (
 SELECT
	dd.FullDate AS  LastDayOfMonth
  ,edu.Regulation
   , edu.Country
   , edu.Region
   , edu.ComplianceClosureEvent AS 'Compliance Closure Event'
   ,SUM(efb.BalanceUSD)BalanceUSD
	   , Count (DISTINCT efb.GCID) Users
	   , COUNT(efb.WalletID)wn
	   , COUNT (CASE WHEN  efb.GCID>0 AND  efb.Balance =0 THEN  REPLACE(REPLACE(efb.WalletID, '{', ''), '}', '')  ELSE NULL END) 'Zero Wallets'
	    , COUNT(CASE WHEN efb.Balance <>0 THEN REPLACE(REPLACE(efb.WalletID, '{', ''), '}', '')   ELSE NULL END) 'Non Zero Wallets'
		FROM EXW_dbo.EXW_FactBalance efb with (NOLOcK)
     JOIN EXW_dbo.EXW_DimUser edu ON efb.GCID=edu.GCID AND edu.IsTestAccount=0
		JOIN DWH_dbo.Dim_Date dd ON dd.DateKey=efb.FullDateID AND   (dd.IsLastDayOfMonth='Y' OR dd.DateKey =CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT))
		WHERE 1=1
		AND dd.FullDate  >=  dateadd(m,-6,getdate())  
	AND efb.GCID>0
	AND edu.IsTestAccount =0

	GROUP BY 
	dd.FullDate
   ,edu.Regulation
   , edu.Country
   , edu.Region
   , edu.ComplianceClosureEvent     


 	) a
	ON a.LastDayOfMonth = ed.FullDate
	AND a.Country = ed.Country
	AND a.Region= ed.Region
	AND a.Regulation= ed.Regulation
	AND a.[Compliance Closure Event] = ed.ComplianceClosureEvent
	LEFT JOIN
(SELECT
		CASE
			WHEN YEAR(EOMONTH(eft.TranDate)) = YEAR(GETDATE()) AND
				MONTH(EOMONTH(eft.TranDate)) = MONTH(GETDATE()) THEN CONVERT(DATE, GETDATE())
			ELSE EOMONTH(eft.TranDate)
		END AS LastDayOfMonth
   ,edu.Regulation
  ,  edu.Region
   , edu.Country
   , edu.ComplianceClosureEvent AS 'Compliance Closure Event'
	   ,SUM(CASE
			WHEN eft.ActionTypeID = 1 AND
				eft.GCID > 0 AND
				eft.IsConversion <> 1 AND
				eft.IsRedeem <> 1 AND
				eft.IsPayment <> 1 THEN eft.AmountUSD
			ELSE 0
		END) AS SentOutUSD
	   ,SUM(CASE
			WHEN eft.ActionTypeID = 2 AND
				eft.GCID > 0 AND
				eft.IsRedeem <> 1 AND
				eft.IsConversion <> 1 AND
				eft.IsPayment <> 1 THEN eft.AmountUSD
			ELSE 0
		END) AS ExternalReceivedUSD
	   ,SUM(CASE
			WHEN eft.GCID > 0
			AND eft.ActionTypeID = 2 AND
				IsConversion = 1 THEN eft.AmountUSD
			ELSE 0
		END) AS ConversionUSD
	   ,SUM(CASE 
			WHEN eft.GCID > 0 AND eft.ActionTypeID = 2 AND
				eft.IsRedeem = 1 THEN eft.AmountUSD
			ELSE 0
		END) AS RedeemedUSD
	   ,SUM(CASE
			WHEN eft.GCID > 0 AND eft.ActionTypeID = 2 AND
				eft.IsPayment = 1 THEN eft.AmountUSD
			ELSE 0
		END) AS PaymentUSD
	   ,SUM(CASE
			WHEN eft.ActionTypeID = 1 THEN eft.EtoroFeesUSD
			ELSE 0
		END) AS EtoroFeeUSD
	FROM EXW_dbo.EXW_FactTransactions eft with (NOLOcK)
		 JOIN EXW_dbo.EXW_DimUser edu ON eft.GCID=edu.GCID AND edu.IsTestAccount=0
		WHERE eft.TranStatus = 'Verified' 
		AND eft.TranDate>= dateadd(m,-6,getdate())  
	GROUP BY
	CASE
			WHEN YEAR(EOMONTH(eft.TranDate)) = YEAR(GETDATE()) AND
				MONTH(EOMONTH(eft.TranDate)) = MONTH(GETDATE()) THEN CONVERT(DATE, GETDATE())
			ELSE EOMONTH(eft.TranDate)
		END  
   ,edu.Regulation
   , edu.Region
   , edu.Country
   , edu.ComplianceClosureEvent
   )b 
      ON b.LastDayOfMonth = ed.FullDate
	AND b.Country = ed.Country
	AND b.Region= ed.Region
	AND b.Regulation= ed.Regulation
	AND b.[Compliance Closure Event] = ed.ComplianceClosureEvent