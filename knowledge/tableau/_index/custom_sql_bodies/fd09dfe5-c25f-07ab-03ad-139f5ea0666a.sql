--Drop Table If EXISTS #temp
SELECT f.*,
		MAX(CASE WHEN ca.Date>CAST(f.RequestDate AS DATE) AND  DATEDIFF(DAY,CAST(f.RequestDate AS DATE),ca.Date)<=30 THEN 1 ELSE 0 END) OpendTickets30Days
		--INTO #temp
from(SELECT DISTINCT
		c.WithdrawID
		,c.WithdrawPaymentID
		,c.CID
		,c.Country
		,c.Region
		,c.Desk
		,c.RequestDate
		,c.ModificationDate
		,c.ModificationDate_WithdrawToFunding
		,CAST(ModificationDate AS DATE)Date
		,c.FundingType_Withdraw
		,c.FundingType_Funding
		,c.CashoutStatus_Withdraw
		,c.SendToProviderDate
		,c.IsDirect
		,c.CashoutStatus_Funding
		,c.Amount_WithdrawToFunding Amount_Withdraw
		,DATEDIFF(HOUR,c.RequestDate,c.ModificationDate_WithdrawToFunding)ProcessTime_H
		,CASE WHEN DATEDIFF(HOUR,c.RequestDate,c.ModificationDate_WithdrawToFunding)<=24 THEN 'within 24H'
			  WHEN DATEDIFF(HOUR,c.RequestDate,c.ModificationDate_WithdrawToFunding)between 24.00001 and 48 THEN 'Above 24H upto 48H'
			  WHEN DATEDIFF(HOUR,c.RequestDate,c.ModificationDate_WithdrawToFunding)between 48.00001 and 72 THEN 'Above 48H upto 72H'
			  WHEN DATEDIFF(HOUR,c.RequestDate,c.ModificationDate_WithdrawToFunding)between 72.00001 and 168 THEN 'Above 72H upto 1W'
			  WHEN DATEDIFF(HOUR,c.RequestDate,c.ModificationDate_WithdrawToFunding)between 168.00001 and 336 THEN 'Above 1W upto 2W'
			  WHEN DATEDIFF(HOUR,c.RequestDate,c.ModificationDate_WithdrawToFunding)between 336.00001 and 672 THEN 'Above 2w upto 4W'
			  ELSE 'Above 4W' END TimeIntervals
		,(DATEDIFF(dd, c.RequestDate , c.ModificationDate_WithdrawToFunding ) + 1.00)
			-(DATEDIFF(wk, CAST(c.RequestDate AS DATE), CAST(c.ModificationDate_WithdrawToFunding AS DATE)) * 2.00)
			-(CASE WHEN DATEPART(dw, CAST(c.RequestDate AS DATE)) = 1 THEN 1.00 ELSE 0.00 END)
			-(CASE WHEN DATEPART(dw, CAST(c.ModificationDate_WithdrawToFunding AS DATE)) = 7 THEN 1.00 ELSE 0.00 END)  As No_Working_Days
       ,CAST((DATEDIFF(dd, c.RequestDate , c.SendToProviderDate ) + 1.00)
			-(DATEDIFF(wk, CAST(c.RequestDate AS DATE), CAST(c.SendToProviderDate AS DATE)) * 2.00)
			-(CASE WHEN DATEPART(dw, CAST(c.RequestDate AS DATE)) = 1 THEN 1.00 ELSE 0.00 END)
			-(CASE WHEN DATEPART(dw, CAST(c.SendToProviderDate AS DATE)) = 7 THEN 1.00 ELSE 0.00 END)AS INT)  As No_Working_Days_ToProvider
       ,Datediff(HH, c.RequestDate, c.SendToProviderDate)
		+ CASE WHEN Datepart(dw, c.RequestDate) = 7 THEN 24 ELSE 0 END
		- (Datediff(wk, c.RequestDate, c.SendToProviderDate) * 48 )
		- CASE WHEN Datepart(dw, c.RequestDate) = 1 THEN 24 ELSE 0 END +
		- CASE WHEN Datepart(dw, c.SendToProviderDate) = 1 THEN 24 ELSE 0
		END No_Working_Hours_ToProvider

from(SELECT fbw.CID 
      ,dc1.Name Country
	  ,dc1.Region
	  ,dc1.Desk
      ,fbw.WithdrawID
	  ,fbw.WithdrawPaymentID
	  --,fbw.RequestDate
	  ,CASE WHEN f_withdraw.Name = 'eToroCryptoWallet' THEN br.RequestDate else fbw.RequestDate END RequestDate
	  ,fbw.ModificationDate
	  ,fbw.ModificationDate_WithdrawToFunding
	  ,fbw.ProcessorValueDate
	  ,fbw.ResponseTimeAsString
	  ,CASE WHEN f_funding.Name IN ('ACH','PWMB','CreditCard','PayPal') THEN  pt.ModificationDate
	        WHEN f_funding.Name IN('WireTransfer', 'OnlineBanking') THEN pt2.ModificationDate
		    ELSE  pt1.ModificationDate END SendToProviderDate
      ,CASE WHEN f_funding.Name NOT IN ('ACH','PWMB','CreditCard','WireTransfer', 'OnlineBanking','PayPal')
				THEN 1 ELSE 0 END IsDirect
	  ,f_withdraw.Name FundingType_Withdraw
	  ,f_funding.Name FundingType_Funding
	  ,s_withdraw.Name CashoutStatus_Withdraw 
	  ,s_funding.Name CashoutStatus_Funding
	  ,ct.CashoutTypeName
	  ,fbw.FundingID
	  ,fbw.Amount_Withdraw
	  ,fbw.Amount_WithdrawToFunding
	  ,fbw.ClientWithdrawReasonID
FROM DWH..Fact_BillingWithdraw fbw
JOIN DWH..Dim_Customer dc
	ON dc.RealCID = fbw.CID
	AND dc.CountryID = 219
JOIN DWH..Dim_Country dc1
	ON dc.CountryID = dc1.CountryID
JOIN DWH..Dim_CashoutStatus s_withdraw
	ON fbw.CashoutStatusID_Withdraw = s_withdraw.CashoutStatusID
JOIN DWH..Dim_CashoutStatus s_funding
	ON fbw.CashoutStatusID_Funding = s_funding.CashoutStatusID
JOIN DWH..Dim_FundingType f_withdraw
	ON fbw.FundingTypeID_Withdraw = f_withdraw.FundingTypeID
JOIN DWH..Dim_FundingType f_funding
	ON fbw.FundingTypeID_Funding = f_funding.FundingTypeID
LEFT JOIN [AZR-W-REAL-DB-2-BIDBUser].etoro.Dictionary.CashoutType ct
	ON fbw.CashoutTypeID = ct.CashoutTypeID
left JOIN OPENQUERY([AZR-W-REAL-DB-2-BIDBUser],'select distinct WithdrawToFundingID,RequestDate
											from etoro.[Billing].[Redeem] br
											')br
	ON br.WithdrawToFundingID = fbw.WithdrawPaymentID 
LEFT JOIN OPENQUERY([AZR-W-REAL-DB-2-BIDBUser],'select BW2F_ID,min(ModificationDate) ModificationDate
												FROM etoro.[History].[vWithdrawToFundingAction] 
												where ModificationDate>=''20200101''
												AND CashoutStatusID =10 --ACH/PWMB
												group by  BW2F_ID
												')pt
	ON fbw.WithdrawPaymentID = pt.BW2F_ID
LEFT JOIN OPENQUERY([AZR-W-REAL-DB-2-BIDBUser],'select BW2F_ID,ModificationDate 
												FROM etoro.[History].[vWithdrawToFundingAction] 
												where ModificationDate>=''20200101''
												AND CashoutStatusID =12 --CreditCard
												')pt1
	ON fbw.WithdrawPaymentID = pt1.BW2F_ID
LEFT JOIN OPENQUERY([AZR-W-REAL-DB-2-BIDBUser],'select BW2F_ID,ModificationDate 
												FROM etoro.[History].[vWithdrawToFundingAction] 
												where ModificationDate>=''20200101''
												AND CashoutStatusID =6  --Wires
												')pt2
	ON fbw.WithdrawPaymentID = pt2.BW2F_ID
WHERE fbw.ModificationDateID>=20210101

)AS c
--WHERE c.RequestDate>='20210101'
--AND c.CashoutStatus_Withdraw IN ('InProcess','Partially Processed')
)f
LEFT JOIN BI_DB.dbo.BI_DB_SF_Cases ca
	ON ca.CID = f.CID
	and ca.ActionType = 'Withdrawal'
	AND ca.TicketStatus = 'created'
	AND ca.DateID>=20201231
GROUP BY f.WithdrawID
	    ,f.WithdrawPaymentID
		,f.CID
		,f.Country
		,f.Region
		,f.Desk
		,f.RequestDate
		,f.ModificationDate
		,f.ModificationDate_WithdrawToFunding
		,f.Date
		,f.FundingType_Withdraw
		,f.FundingType_Funding
		,f.CashoutStatus_Withdraw
		,f.SendToProviderDate
		,f.IsDirect
		,f.CashoutStatus_Funding
		,f.Amount_Withdraw
		,ProcessTime_H
		,TimeIntervals
		,No_Working_Days
       ,No_Working_Days_ToProvider
       ,No_Working_Hours_ToProvider