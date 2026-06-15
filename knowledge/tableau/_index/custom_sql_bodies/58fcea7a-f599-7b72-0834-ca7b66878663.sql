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
FROM BI_DB.dbo.BI_DB_InvestorsDetail i
INNER JOIN [BI_DB].[dbo].[Syn_gsheets.customer_managers] syn
ON i.[AccountManagerID] = syn.[manager_id]
and syn.[manager_type] = 'Investor AM'
WHERE AssetType = 'Investment'
)AS q0
UNPIVOT 
(
Amount FOR MI_MO in (MoneyIn,MoneyOut)
)AS up
WHERE Amount>0