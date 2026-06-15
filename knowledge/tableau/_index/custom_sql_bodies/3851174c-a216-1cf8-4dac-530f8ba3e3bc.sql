SELECT nbr.Manager
      ,nbr.RealCID
	  ,SUM(CASE WHEN nbr.IsContacted = 1 THEN nbr.TotalDepositAmount ELSE 0 END) DepositWithContact
	  ,SUM(nbr.TotalCoAmount) TotalCashoutAmount
	  ,CASE WHEN SUM(nbr.TotalCoAmount) > SUM(CASE WHEN nbr.IsContacted = 1 THEN nbr.TotalDepositAmount ELSE 0 END) 
	  THEN SUM(CASE WHEN nbr.IsContacted = 1 THEN nbr.TotalDepositAmount ELSE 0 END) ELSE SUM(nbr.TotalCoAmount) END CalculatedCO
,CASE WHEN SUM(CASE WHEN nbr.IsContacted = 1 THEN nbr.TotalDepositAmount ELSE 0 END) - SUM(nbr.TotalCoAmount) <=0 THEN 0 
	  ELSE SUM(CASE WHEN nbr.IsContacted = 1 THEN nbr.TotalDepositAmount ELSE 0 END) - SUM(nbr.TotalCoAmount) END ResidualAmount
FROM BI_DB_dbo.BI_DB_NewBonusReport nbr WITH (NOLOCK)
INNER JOIN  [BI_DB_dbo].[External_BI_OUTPUT_Customer_Customer_Support_Agent_User] syn 
--inner join [BI_DB_dbo].[External_BI_OUTPUT_Customer_Customer_Support_Agent_User]
ON nbr.ManagerID = AccountManagerID
AND syn.ToDate='9999-12-31T00:00:00.000Z'
WHERE DateID < CONVERT(CHAR(8),DATEFROMPARTS(YEAR(<[Parameters].[Parameter 3]>),MONTH(<[Parameters].[Parameter 3]>),1),112)
AND nbr.Desk = 'Australia'
GROUP BY Manager
      ,RealCID