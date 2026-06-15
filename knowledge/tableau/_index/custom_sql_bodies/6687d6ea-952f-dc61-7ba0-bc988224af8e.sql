SELECT
	bdada.*
  , d.TotalDeposits
  , v.TotalEquity
  , v.EquityInPositions
  , drc.RiskClassificationName 
  , CAST (dc.FirstDepositDate AS DATE) AS FTDDate  
FROM BI_DB_AML_Daily_Alerts bdada WITH (nolock)
JOIN V_GermanBaFin vgbf
	ON bdada.CID = vgbf.CID AND vgbf.DateID = CAST(CONVERT(VARCHAR(8), bdada.AlertDate, 112) AS INT)
JOIN (
	SELECT
		bd.CID
	  , SUM (bd.Amount*bd.ExchangeRate) AS TotalDeposits 
	FROM DWH..Fact_BillingDeposit bd WITH (nolock)
	WHERE bd.PaymentStatusID IN (2,4) GROUP BY bd.CID
	) d
	ON bdada.CID = d.CID
JOIN (
	SELECT
		vl.CID
	  , vl.DateID
	  , SUM (ISNULL (vl.TotalPositionsAmount, 0)+
		ISNULL (vl.PositionPnL, 0)+
		ISNULL (vl.InProcessCashouts, 0)+
		ISNULL (vl.TotalCash, 0)+
		ISNULL (vl.TotalStockOrders, 0))
		AS TotalEquity
	  , SUM (ISNULL (vl.TotalPositionsAmount, 0)+
		ISNULL (vl.PositionPnL, 0))
		AS EquityInPositions
FROM DWH..V_Liabilities vl WITH (nolock)
GROUP BY vl.CID	,vl.DateID
	 ) v
	ON v.CID = bdada.CID AND v.DateID = CAST(CONVERT(VARCHAR(8), bdada.AlertDate, 112) AS INT)
JOIN DWH..Dim_Customer dc WITH (nolock)
	ON dc.RealCID = bdada.CID
JOIN DWH..Dim_RiskClassification drc
	ON dc.RiskClassificationID = drc.RiskClassificationID
WHERE Regulation IN ('CySEC','FCA')


-- select top 10 * from BI_DB_AML_Daily_Alerts_History
--SELECT * FROM BI_DB_AML_Daily_Alerts bdada