SELECT dd.FullDate
, b.Date 
, b.SentOutUSD 'Sent Out USD'
, b.SentOutTransactions 'Sent Out Tx'
, b.UsersSentOut 'Sent Out Users'
--
, b.ExternalReceivedUSD 'External Received USD' 
, b.ExternalReceivedTX 'External Received  Tx'
, b.ExternalReceivedUsers 'External Received Users'
--
, b.ConversionUSD 'Conversion USD'
, b.ConversionTX  'Conversion Tx'
, b.ConversionUsers  'Conversion Users'

, b.RedeemedUSD 'Coin Transfer USD' 
, b.RedeemedTX 'Coin Transfer Tx' 
, b.RedeemedUsers 'Coin Transfer Users' 
, b.PaymentUSD 'Fiat to Crypto USD'
, b.PaymentTX 'Fiat to Crypto Tx'
, b.PaymentUsers 'Fiat to Crypto Users'
  FROM DWH.dbo.Dim_Date dd
 LEFT JOIN
(	SELECT CASE
			WHEN DATEADD(DAY, 7 - DATEPART(WEEKDAY, eft.TranDate), eft.TranDate) >= CAST(GETDATE()AS DATE) 
then CAST(GETDATE() -1 AS DATE)
			ELSE DATEADD(DAY, 7 - DATEPART(WEEKDAY, eft.TranDate), eft.TranDate )
		END AS Date
		
  -- ,edu.Regulation
  --,  edu.Region
  -- , edu.Country
  -- , edu.ComplianceClosureEvent AS 'Compliance Closure Event'
, Count(Distinct eft.GCID)Users
			 ,SUM(CASE
			WHEN eft.ActionTypeID = 1 AND
				eft.GCID > 0 AND
				 eft.TransactionTypeID =1
				THEN eft.AmountUSD
			ELSE 0
		END) AS SentOutUSD
		,Sum(CASE
			WHEN eft.ActionTypeID = 1 AND
				eft.GCID > 0 AND
				 eft.TransactionTypeID =1 
				THEN 1
			ELSE 0
		END) AS SentOutTransactions 
		 ,Count(DISTINCT CASE
			WHEN eft.ActionTypeID = 1 AND
				eft.GCID > 0 AND
				 eft.TransactionTypeID =1
				THEN eft.GCID
		END) AS UsersSentOut 
		--------------------
	   ,SUM(CASE
			WHEN eft.ActionTypeID = 2 AND
				eft.GCID > 0 AND
				eft.IsRedeem <> 1 AND
				eft.IsConversion <> 1 AND
				eft.IsPayment <> 1 THEN eft.AmountUSD
			ELSE 0
		END) AS ExternalReceivedUSD
		  ,SUM(CASE
			WHEN eft.ActionTypeID = 2 AND
				eft.GCID > 0 AND
				eft.IsRedeem <> 1 AND
				eft.IsConversion <> 1 AND
				eft.IsPayment <> 1 THEN 1
			ELSE 0
		END) AS ExternalReceivedTX
		  ,COUNT (DISTINCT CASE
			WHEN eft.ActionTypeID = 2 AND
				eft.GCID > 0 AND
				eft.IsRedeem <> 1 AND
				eft.IsConversion <> 1 AND
				eft.IsPayment <> 1 THEN eft.GCID
		END) AS ExternalReceivedUsers
		---------------------------
	   ,SUM(CASE
			WHEN eft.GCID > 0
			AND eft.ActionTypeID = 2 AND
				IsConversion = 1 THEN eft.AmountUSD
			ELSE 0
		END) AS ConversionUSD

   ,SUM(CASE
			WHEN eft.GCID > 0
			AND eft.ActionTypeID = 2 AND
				IsConversion = 1 THEN 1
			ELSE 0
		END) AS ConversionTX
		   ,Count( DISTINCT CASE
			WHEN eft.GCID > 0
			AND eft.ActionTypeID = 2 AND
				IsConversion = 1 THEN eft.GCID
					END) AS ConversionUsers 
		------------------------------------------------
	   ,SUM(CASE 
			WHEN eft.GCID > 0 AND eft.ActionTypeID = 2 AND
				eft.IsRedeem = 1 THEN eft.AmountUSD
			ELSE 0
		END) AS RedeemedUSD
		   ,SUM(CASE 
			WHEN eft.GCID > 0 AND eft.ActionTypeID = 2 AND
				eft.IsRedeem = 1 THEN 1
			ELSE 0
		END) AS RedeemedTX
		   ,COUNT( DISTINCT CASE 
			WHEN eft.GCID > 0 AND eft.ActionTypeID = 2 AND
				eft.IsRedeem = 1 THEN eft.GCID
				END) AS RedeemedUsers
		-------------------------------------------------------
	   ,SUM(CASE
			WHEN eft.GCID > 0 AND eft.ActionTypeID = 2 AND
				eft.IsPayment = 1 THEN eft.AmountUSD
			ELSE 0
		END) AS PaymentUSD
		   ,SUM(CASE
			WHEN eft.GCID > 0 AND eft.ActionTypeID = 2 AND
				eft.IsPayment = 1 THEN 1
			ELSE 0
		END) AS PaymentTX
		   ,COUNT (DISTINCT CASE
			WHEN eft.GCID > 0 AND eft.ActionTypeID = 2 AND
				eft.IsPayment = 1 THEN eft.GCID
		
		END) AS PaymentUsers
		----------------------
	
	FROM EXW.dbo.EXW_FactTransactions eft with (NOLOcK)
		 JOIN EXW.dbo.EXW_DimUser edu ON eft.GCID=edu.GCID AND edu.IsTestAccount=0
		WHERE eft.TranStatus = 'Verified' 
AND eft.TranDateID >=CAST(CONVERT (VARCHAR(8) , DATEADD(week, -5,CAST(DATEADD(week, DATEDIFF(week, -1, GETDATE()), -1) AS DATE))  , 112 ) AS INT)  --5 closed weeks befor current
    AND eft.TranDateID<    CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT)

GROUP BY 	 
	CASE
			WHEN DATEADD(DAY, 7 - DATEPART(WEEKDAY, eft.TranDate), eft.TranDate) >= CAST(GETDATE()AS DATE) then CAST(GETDATE() -1 AS DATE)
			ELSE DATEADD(DAY, 7 - DATEPART(WEEKDAY, eft.TranDate), eft.TranDate )		END
	
	--select CAST(CONVERT(VARCHAR(8), DATEADD(week, -5,  DATEADD(DD,-(DATEPART(DW,CAST(GETDATE()AS DATE))-7),CAST(GETDATE()AS DATE))  ) , 112) AS INT)   
   --,edu.Regulation
   --, edu.Region
   --, edu.Country
   --, edu.ComplianceClosureEvent
   )b 
      ON b.Date = dd.FullDate
 WHERE  1=1 
 AND dd.DateKey  >=CAST(CONVERT (VARCHAR(8) , DATEADD(week, -5,CAST(DATEADD(week, DATEDIFF(week, -1, GETDATE()), -1) AS DATE))  , 112 ) AS INT)  --5 closed weeks befor current
 AND dd.DateKey<    CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT)
	AND    dd. FullDate=DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), FullDate)  --TO TAKE ONLY weekend