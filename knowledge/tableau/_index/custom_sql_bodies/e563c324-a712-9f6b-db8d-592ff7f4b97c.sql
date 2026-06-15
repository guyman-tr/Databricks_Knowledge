SELECT  DepositDate
       ,PaymentStatusID
	   ,PaymentStatus
	   ,IsFTD
	   ,DepositStatus
	   ,DepositMethod
	   ,DepositFundingType
	   ,Region
	   ,Country
	   ,Regulation
	   ,CASE  WHEN DATEDIFF(HOUR,PaymentDate,ModificationDate)<=72 AND datepart(dw,PaymentDate)=6 THEN 'In 24 Hours'
		WHEN DATEDIFF(HOUR,PaymentDate,ModificationDate)<=48 AND datepart(dw,PaymentDate)=7 THEN 'In 24 Hours'
		WHEN DATEDIFF(HOUR,PaymentDate,ModificationDate)<=24 THEN 'In 24 Hours' 
	   	ELSE 'More then 24 Hours' END AS 'SLA_ind'
	   ,SUM(FirstAttempt_Ind)AS  FirstAttempt_Ind
	   ,SUM(FA_Approve_Rate) AS FA_Approve_Rate 
	   ,Count( DepositID) AS Deposit_Attempt
	   ,SUM(AmountUSD) AS  AmountUSD
	   ,SUM(DATEDIFF(HOUR,PaymentDate,ModificationDate)) AS ProcessedDate
	   
FROM BI_DB.dbo.BI_DB_Money_In_New_Management_Dashboard

GROUP BY  DepositDate
         ,PaymentStatusID
	     ,PaymentStatus
	     ,IsFTD
	     ,DepositStatus
	     ,DepositMethod
	     ,DepositFundingType
	     ,Region
	     ,Country
	     ,Regulation
	     ,CASE  WHEN DATEDIFF(HOUR,PaymentDate,ModificationDate)<=72 AND datepart(dw,PaymentDate)=6 THEN 'In 24 Hours'
		  WHEN DATEDIFF(HOUR,PaymentDate,ModificationDate)<=48 AND datepart(dw,PaymentDate)=7 THEN 'In 24 Hours'
		  WHEN DATEDIFF(HOUR,PaymentDate,ModificationDate)<=24 THEN 'In 24 Hours' 
	   	  ELSE 'More then 24 Hours' END