SELECT distinct ag.CID
	 , ag.Date
	 , ag.DateID
	 , ag.DailyCBGap
	 , ag.PreviousCBGap
	 , ag.CashoutRequested
	 , ag.CashoutProcessed
	 , ag.ClosingBalance
	 , ag.CycleCalculation
     , ag.[Cycle Gap]
	 , ag.CashoutGap
	 , ag.OutlierTransition
	 , ag.OutlierCycleCalculation
	 , ag.PreviousPlayerStatus
	 , ag.CurrentPlayerStatus
	 , ag.RefundAsChargeback_CB
	 , ag.RefundAsChargeback_Prod
	 , ag.TotalGap
	 , ag.Liabilities
	 , ag.Regulation
	 , ag.IsCreditReportValidCB
	 , ag.IsGermanBaFin
	 , ag.UpdateDate
	 , ag.DateID_b
	 , REPLACE(ag.OtherDateClosing, '_', ' ') AS OtherDateClosing
	 , REPLACE(CASE WHEN DailyCBGap <> 0 AND RefundAsChargeback_CB-RefundAsChargeback_Prod <> 0 AND TotalGap = 0 THEN 'RefundAsChargeback_Gap_Explained'
			WHEN DailyCBGap <> 0 AND RefundAsChargeback_CB-RefundAsChargeback_Prod <> 0 AND TotalGap <> 0 AND Liabilities < 0 THEN 'RefundAsChargeback_Gap_Explained_NegativeLiability'
			WHEN TotalGap = 0 AND DailyCBGap <> 0 AND PreviousCBGap <> 0 AND CashoutGap <> 0 AND ABS(ag.CashoutGap) = ABS(ag.[Cycle Gap]) AND ag.CashoutRequested <> ag.CashoutProcessed THEN 'Cashout_Gap_Closed'
			WHEN TotalGap = 0 AND DailyCBGap <> 0 AND PreviousCBGap <> 0 THEN 'Other_Previous_Gap_Closed'
			WHEN TotalGap <> 0 AND OutlierCycleCalculation <> 0 THEN 'Outlier_Gap_Explained_' + replace(OutlierTransition,' ','_')
			WHEN TotalGap <> 0 AND CashoutGap <> 0 AND ABS(ag.[Cycle Gap]) = ABS(ag.CashoutGap) AND ag.CashoutRequested <> ag.CashoutProcessed THEN 'Cashout_Gap_Explained'
			WHEN ag.DailyCBGap <> 0 AND ag.TotalGap <> 0 AND ag.OtherDateClosing IS NOT NULL THEN 'Gap_Unexplained_But_Self_Closes'
		ELSE 'Gap_Unexplained'
		END, '_', ' ') AS GapCategorized
FROM 
(
SELECT a.CID
	 , a.Date
	 , a.DateID
	 , a.DailyCBGap
	 , a.PreviousCBGap
	 , a.CashoutRequested
	 , a.CashoutProcessed
	 , a.ClosingBalance
	 , a.CycleCalculation
	 , a.CashoutGap -- this is a patch. the root cause is earlier processes show gap wrongly as "cashoutgap"
     , CASE WHEN a.OutlierCycleCalculation <> 0 THEN a.OutlierCycleCalculation else a.ClosingBalance-a.CycleCalculation END as [Cycle Gap]
	 , a.OutlierTransition
	 , a.OutlierCycleCalculation
	 , a.PreviousPlayerStatus
	 , a.CurrentPlayerStatus
	 , a.RefundAsChargeback_CB
	 , a.RefundAsChargeback_Prod
	 , a.TotalGap
	 , a.Liabilities
	 , a.Regulation
	 , a.IsCreditReportValidCB
	 , a.IsGermanBaFin
	 , a.UpdateDate
	 , a.DidRegulationTransfer, b.DateID AS DateID_b
	, CASE WHEN b.DateID > a.DateID THEN 'Gap_Will_Close_On_' + CAST(b.DateID AS varchar(10))
			WHEN b.DateID < a.DateID THEN 'Closes_Gap_From_' + CAST(b.DateID AS varchar(10))
	END AS OtherDateClosing
FROM BI_DB_dbo.BI_DB_CB_CycleGap_Categorization a
LEFT JOIN BI_DB_dbo.BI_DB_CB_CycleGap_Categorization b
	ON a.CID = b.CID AND a.DailyCBGap = -b.DailyCBGap
) ag
where ag.CID = <[Parameters].[Parameter 3]>