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
	   ,CASE  WHEN DATEDIFF(day,ProcessorValueDate,ModificationDate)<=3 AND datepart(dw,ProcessorValueDate)=6 THEN 'In 24 Hours'
		WHEN DATEDIFF(day,ProcessorValueDate,ModificationDate)<=2 AND datepart(dw,ProcessorValueDate)=7 THEN 'In 24 Hours'
		WHEN DATEDIFF(day,ProcessorValueDate,ModificationDate)<=1 THEN 'In 24 Hours' 
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
	     ,CASE  WHEN DATEDIFF(day,ProcessorValueDate,ModificationDate)<=3 AND datepart(dw,ProcessorValueDate)=6 THEN 'In 24 Hours'
		WHEN DATEDIFF(day,ProcessorValueDate,ModificationDate)<=2 AND datepart(dw,ProcessorValueDate)=7 THEN 'In 24 Hours'
		WHEN DATEDIFF(day,ProcessorValueDate,ModificationDate)<=1 THEN 'In 24 Hours' 
	   	ELSE 'More then 24 Hours' END