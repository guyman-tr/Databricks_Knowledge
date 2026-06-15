--DECLARE @date DATE = GETDATE() - 1
--DECLARE @dateINT INT = dbo.DateToDateID(@date)


SELECT da.TradingAccount_RealCID AS CID
      ,da.AffiliateID
		,da.AffiliatesGroupsName
		,da.Contact
		,da.Email
		,da.WebSiteURL
		,dc.VerificationLevelID
		,da.AccountActivated
		,dc.RegisteredReal
		,da.DateCreated
      ,ps.Name AS PlayerStatus
		,dat.Name AS AccountType
		,CASE WHEN dc.FirstDepositDate > '20000101' THEN 'Yes' ELSE 'No' END AS HasFTD
		,MAX(da.RegistrationLifeTime) AS RegistrationLifeTime
		,MAX(da.FTDLifeTime) AS FTDLifeTime
		,MAX(vl.RealizedEquity) AS RealizedEquity
		,MAX(vl.PositionPnL) AS PositionPnL
		,MAX(vl.Credit) AS Balance
FROM DWH_dbo.Dim_Affiliate da
JOIN DWH_dbo.Dim_Channel dc1
 ON da.SubChannelID = dc1.SubChannelID
JOIN DWH_dbo.Dim_Customer dc
 ON da.TradingAccount_RealCID = dc.RealCID
JOIN DWH_dbo.Dim_AccountType dat
ON dc.AccountTypeID = dat.AccountTypeID
JOIN DWH_dbo.Dim_PlayerStatus ps
ON ps.PlayerStatusID = dc.PlayerStatusID
LEFT JOIN DWH_dbo.V_Liabilities vl
ON vl.CID = dc.RealCID AND vl.DateID =  CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112)
WHERE dc1.Channel IN('Affiliate','Introducing Agents')
GROUP BY da.TradingAccount_RealCID 
      ,da.AffiliateID
		,da.AffiliatesGroupsName
		,da.Contact
		,da.Email
		,da.WebSiteURL
		,dc.VerificationLevelID
		,da.AccountActivated
		,dc.RegisteredReal
		,da.DateCreated
		,dat.Name
       ,ps.Name
		 ,CASE WHEN dc.FirstDepositDate > '20000101' THEN 'Yes' ELSE 'No' END