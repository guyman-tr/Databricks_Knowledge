SELECT q.DateID     
      ,q.ReportDate EOD
      --, 'EOW'
      ,EOMONTH(q.ReportDate) EOM
      ,q.CID
      ,q.IsValidCustomer
      ,q.IsCreditReportValidCB
      ,q.Country
      ,q.Region
      ,q.Regulation
      ,q.IsDepositor
      ,CAST(q.FirstDepositors AS INT) AS IsFirstDeposit
      ,CAST(q.Deposited AS INT) AS IsDeposit
      ,CASE WHEN  q.IsDepositor = 1 AND q.Deposited = 1 AND q.FirstDepositors = 0 THEN 1 ELSE 0 END IsReDeposit 
      ,CAST(q.DepositsCount AS INT) AS DepositsCount
      ,q.Deposits AS DepositsAmount
      ,q.FirstDepositAmounts
      ,q.FirstDepositDate 
      ,CAST(q.CashedOut AS INT) AS IsCashedOut
      ,CAST(q.Redeemed AS INT) AS IsRedeemed
      ,CAST(q.CashoutsCount AS INT)    CashoutsCount
      ,q.Cashouts AS CashoutsAmount
      ,q.TransferCoins RedeemAmount
      ,q.CashoutsIncludingRedeem AS CashoutsAmountIncludingRedeem    
      ,q.Deposits - q.Cashouts AS NetMoneyIn
      ,q.Deposits - q.CashoutsIncludingRedeem AS NetMoenyInIncludingRedeem
      ,q.[Label]
      ,q.AccountType
      ,q.PlayerStatus
      ,q.PlayerLevel
	  ,COUNT(CASE WHEN q.Deposits >0 OR q.Cashouts >0 THEN CID END) NMI_Actions
	  ,COUNT(DISTINCT CASE WHEN q.Deposits >0 OR q.Cashouts >0 THEN CID END) NMI_User 
--INTO BI_DB_DDR_Product_MIMO
FROM BI_DB_dbo.BI_DB_DDR_CID_Level q
INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
ON dd.DateKey = q.DateID
WHERE q.PlayerLevel != 'Internal'
AND DateID >= CAST(CONVERT(CHAR(8),getdate()-58,112) AS INT)
AND dd.DayNumberOfWeek_Sun_Start = DATEPART ( dw, getdate()-1 )  
GROUP BY q.DateID     
      ,q.ReportDate 
      --, 'EOW'
      ,EOMONTH(q.ReportDate) 
      ,q.CID
      ,q.IsValidCustomer
      ,q.IsCreditReportValidCB
      ,q.Country
      ,q.Region
      ,q.Regulation
      ,q.IsDepositor
      ,CAST(q.FirstDepositors AS INT)
      ,CAST(q.Deposited AS INT) 
      ,CASE WHEN  q.IsDepositor = 1 AND q.Deposited = 1 AND q.FirstDepositors = 0 THEN 1 ELSE 0 END 
      ,CAST(q.DepositsCount AS INT) 
      ,q.Deposits
      ,q.FirstDepositAmounts
      ,q.FirstDepositDate 
      ,CAST(q.CashedOut AS INT) 
      ,CAST(q.Redeemed AS INT) 
      ,CAST(q.CashoutsCount AS INT)   
      ,q.Cashouts
      ,q.TransferCoins 
      ,q.CashoutsIncludingRedeem 
      ,q.Deposits - q.Cashouts  
      ,q.Deposits - q.CashoutsIncludingRedeem 
      ,q.[Label]
      ,q.AccountType
      ,q.PlayerStatus
      ,q.PlayerLevel