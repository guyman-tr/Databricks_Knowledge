select Date
      ,RealCID
	  ,ParentUserName
	  ,InstrumentType
	  ,ActionType
	  ,AccountManagerID
          ,DaysContacted
	  ,MI_MO
	  ,Amount
FROM
(SELECT  Date
	   ,DateID
	   ,RealCID
	   ,InstrumentType
	   ,ParentUserName
	   ,ActionType
	   ,MoneyOut
	   ,MoneyIn
	   ,DaysContacted
	   ,AccountManagerID
FROM BI_DB_dbo.BI_DB_InvestorsDetail i
INNER JOIN [DWH_dbo].[Dim_Manager] dm
ON i.[AccountManagerID] = dm.[ManagerID]
AND dm.[IsActive]=1
AND dm.[SFManagerID] is not null
WHERE AssetType = 'Investment'
)AS q0
UNPIVOT 
(
Amount FOR MI_MO in (MoneyIn,MoneyOut)
)AS up
WHERE Amount>0