SELECT ir.DateID, mr.PositionID, mr.ModificationDateID, mr.WithdrawToFundingID, mr.AmountMimo, ir.AmountTrade, dp.CloseDateID
FROM (
		SELECT fbw.ModificationDateID, fbr.PositionID, fbr.WithdrawToFundingID, fbw.Amount_WithdrawToFunding AS AmountMimo
		FROM BI_DB_dbo.External_etoro_Billing_Redeem fbr
			JOIN DWH_dbo.Fact_BillingWithdraw fbw
				ON fbr.WithdrawToFundingID = fbw.WithdrawPaymentID
		WHERE 1 = 1
		AND CAST(CONVERT(VARCHAR(8), fbr.LastModificationDate, 112) AS INT) 
			BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
		AND fbr.RedeemStatusID = 8
	) mr
	LEFT JOIN
	(
		SELECT bdidp.DateID, bdidp.PositionID, dp.Amount + dp.NetProfit AS AmountTrade
		FROM BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions bdidp
			JOIN DWH_dbo.Dim_Position dp
				ON bdidp.PositionID = dp.PositionID
		WHERE 1 = 1
		AND bdidp.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT) 
		AND bdidp.IsRedeem = 'Redeem'
		AND bdidp.PositionTiming IN ('Opened_And_Closed_In_Period','Opened_Before_Period_Closed_InPeriod')
	) ir
		ON mr.PositionID = ir.PositionID
	JOIN DWH_dbo.Dim_Position dp
		ON mr.PositionID = dp.PositionID
WHERE ir.PositionID IS NULL