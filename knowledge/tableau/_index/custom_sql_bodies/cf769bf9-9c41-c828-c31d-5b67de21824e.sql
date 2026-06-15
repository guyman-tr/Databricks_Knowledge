SELECT DISTINCT
pl.Name AS Club,
bdadh.CID, bdadh.DepositID, 
CASE WHEN  bdadh.Category='FTD' THEN 'Initial Deposit' 
	WHEN 	bdadh.Category='REDEPOSIT' THEN 'Redeposit'
	ELSE 'Others' END AS Category,
bdadh.FundingType, bdadh.[Amount In Orig Curr], bdadh.Currency, bdadh.[Amount in $], bdadh.ModificationDate, bdadh.[Deposit Time], bdadh.FirstDepositDate,
bdadh.PaymentStatus, bdadh.Provider, bdadh.CardType, bdadh.CardSubType, bdadh.[Country By Reg IP], bdadh.[Deposit Risk Status], bdadh.RiskStatus,
bdadh.[Account Manager], bdadh.[Bank name by Bincode], bdadh.AccountBalanceAsDecimal, bdadh.CurrentBalanceAsDecimal,   bdadh.PayerStatus, bdadh.AccountTypeAsString,
bdadh.Region, bdadh.Regulation, bdadh.DesignatedRegulation ,bdadh.[Country (customer)]
FROM BI_DB_dbo.BI_DB_AllDeposits bdadh
JOIN DWH_dbo.Dim_Customer c ON c.RealCID=bdadh.CID
JOIN DWH_dbo.Dim_PlayerLevel pl ON pl.PlayerLevelID=c.PlayerLevelID
WHERE bdadh.ModificationDateID >= 20220101 
--bdadh.ModificationDate>=DATEADD(Month, DATEDIFF(Month, 0, DATEADD(m, -12, CURRENT_TIMESTAMP)), 0)
AND bdadh.Region = 'USA' AND bdadh.DesignatedRegulation IN ('FinCEN', 'FinCEN+FINRA','eToroUS') 
AND c.IsValidCustomer=1 AND c.IsCreditReportValidCB=1
--ORDER BY CID, bdadh.ModificationDate