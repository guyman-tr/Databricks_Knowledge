SELECT COALESCE(D.WeekStart,C.WeekStart) WeekStart
	  ,COALESCE(D.Depot,C.Depot)Depot
	  ,ISNULL(D.TotalDepositAmount,0)TotalDepositAmount
	  ,ISNULL(C.TotalCashoutAmount,0)TotalCashoutAmount
FROM(
		SELECT CAST(fbd.ModificationDate AS DATE)  [WeekStart],
			   dbd.Name Depot,
			   sum(fbd.AmountUSD) TotalDepositAmount
	   FROM DWH..Fact_BillingDeposit fbd
	   JOIN DWH..Dim_Customer dc
	   	ON dc.RealCID = fbd.CID
	   JOIN DWH..Dim_BillingDepot dbd
	   	ON fbd.DepotID = dbd.DepotID
	   WHERE fbd.ModificationDateID >= CAST(CONVERT(VARCHAR(8),DATEADD(day,-8,GETDATE()),112) AS INT)
	   AND fbd.PaymentStatusID = 2
	   AND dc.RegulationID = 2
	   AND dc.IsCreditReportValidCB =1
	   GROUP BY fbd.ModificationDate ,
					dbd.Name 

 )AS D
FULL OUTER JOIN (
				SELECT dd.FullDate [WeekStart],
					dbd.Name Depot,
					SUM(fbw.Amount_WithdrawToFunding) TotalCashoutAmount
			   FROM DWH..Fact_BillingWithdraw fbw	
			   JOIN DWH..Dim_Customer dc
			   	ON dc.RealCID = fbw.CID
			   JOIN DWH..Dim_CashoutStatus s_withdraw
			   	ON fbw.CashoutStatusID_Withdraw = s_withdraw.CashoutStatusID
			   JOIN DWH..Dim_CashoutStatus s_funding
			   	ON fbw.CashoutStatusID_Funding = s_funding.CashoutStatusID
			   JOIN DWH..Dim_BillingDepot dbd
			   	ON fbw.DepotID = dbd.DepotID
			   JOIN DWH..Dim_Date dd
			   	ON dd.FullDate = CAST(fbw.ModificationDate_WithdrawToFunding AS DATE)
			   WHERE dd.DateKey >= CAST(CONVERT(VARCHAR(8),DATEADD(day,-8,CAST(GETDATE() AS DATE)),112) AS int)
			   AND dc.IsCreditReportValidCB = 1
			   AND dc.RegulationID = 2
			   AND s_funding.Name = 'Processed' 
			   AND s_withdraw.Name = 'Processed'
			   GROUP BY dd.FullDate,
			   			dbd.Name  
		)AS C
ON D.WeekStart = C.WeekStart
AND D.Depot = C.Depot