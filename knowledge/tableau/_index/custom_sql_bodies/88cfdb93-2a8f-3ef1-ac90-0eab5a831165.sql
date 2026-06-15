SELECT  'Alert' AS Indicator
 ,FullDate
 ,bdia.FirstAction
 ,InstrumentID
 ,InstrumentDisplayName
 ,FirstInstrument
 ,Industry
 ,Exchange
 ,Actions
 ,avg7d_past
 ,avg14d_past
 ,avg30d_past
 ,NULL AS Region
 ,NULL AS Country
 ,NULL AS EOD_Price
 ,NULL AS OpenPositions
 ,NULL AS OpenedPositions
 ,NULL AS UsersOpen
 ,NULL AS UsersHold 
      ,bdia.Actions*1.0 / SUM(bdia.Actions) OVER (PARTITION BY bdia.FullDate) PercentFirstActionsFromTotal
		 ,bdia.avg7d_past*1.0 / SUM(bdia.avg7d_past) OVER (PARTITION BY bdia.FullDate) PercentFirstActionsFromTotal_Past7Days
		 ,ROW_NUMBER() OVER (PARTITION BY bdia.FullDate,bdia.FirstAction ORDER BY bdia.Actions DESC) RankFirstActions
		 --,ISNULL(CASE WHEN (Tier = 1 and Actions>= 25 and Actions/NULLIF(avg7d_past,0)>=2)
   --         OR           (Tier = 2 and Actions>= 15 and Actions/NULLIF(avg7d_past,0)>=2.5)
   --         OR           (Tier = 3 and Actions>= 5 and Actions/NULLIF(avg7d_past,0)>=3)
   --         OR           (Tier = 4 and Actions>=5 and Actions/NULLIF(avg7d_past,0)>=3.5)
   --     THEN 1 END,0) AS Alert
FROM BI_DB_dbo.BI_DB_InstrumentsAlerts bdia WITH (NOLOCK)
WHERE bdia.FullDate = CAST(GETDATE()-<[Parameters].[Parameter 6]> AS DATE)
--AND bdia.FirstAction IN ('Stocks/ETFs','Crypto')


UNION 

----------------
SELECT  'FirstActions' 
 ,Date
 ,FirstAction
 ,NULL
 ,NULL
 ,FirstInstrument
 ,NULL
 ,NULL
 ,FirstActions
 ,0
 ,0
 ,0
 ,Region
 ,Country
 ,NULL AS EOD_Price
 ,NULL AS OpenPositions
 ,NULL AS OpenedPositions
 ,NULL AS UsersOpen
 ,NULL AS UsersHold
,NULL
,NULL
,aa.Ranking
 FROM 
(
 SELECT  cast(fa.FirstActionDate as date) Date
        ,fa.Region
        ,fa.Country
       ,fa.FirstInstrument 
		 ,fa.FirstAction
		 ,ff.RN Ranking
        ,COUNT(*) FirstActions
FROM BI_DB_dbo.BI_DB_First5Actions fa
 INNER JOIN 
 (SELECT  bdia.FirstInstrument
       ,FirstAction
		 ,bdia.Actions FA 
		 ,ROW_NUMBER() OVER (PARTITION BY bdia.FullDate,bdia.FirstAction ORDER BY bdia.Actions DESC) RN
 FROM BI_DB_dbo.BI_DB_InstrumentsAlerts bdia WITH (NOLOCK)
 WHERE bdia.FullDate = CAST(GETDATE()-<[Parameters].[Parameter 6]> AS DATE)
--AND bdia.FirstAction IN ('Stocks/ETFs','Crypto')

) ff
ON fa.FirstInstrument = ff.FirstInstrument
WHERE CAST(fa.FirstActionDate AS DATE) >= DATEADD(DAY,-60,GETDATE()-<[Parameters].[Parameter 6]>)
AND ff.RN <= 10
GROUP BY cast(fa.FirstActionDate as date) 
        ,fa.Region
        ,fa.Country
        ,fa.FirstInstrument 
		  ,fa.FirstAction
		   ,ff.RN 
) aa


UNION

--------------------

SELECT  'TradeData' AS Indicator
 ,Date
 ,FirstAction
 ,NULL
 ,NULL
 ,bb.InstrumentName
 ,NULL
 ,NULL
 ,NULL
 ,0
 ,0
 ,0
 ,Region
 ,Country
 ,bb.EOD_Price
 ,bb.OpenPositions
 ,bb.OpenedPositions
 ,bb.UsersOpen
 ,bb.UsersHold
 		  ,NULL
		  ,NULL
	,bb.RN
 FROM 
(
 SELECT  fa.Date
          ,FirstAction
        ,fa.Region
        ,fa.Country
		  ,di.Name AS InstrumentName
		  ,fa.EOD_Price
		  ,fa.OpenPositions
		  ,fa.OpenedPositions
		  ,fa.UsersOpen
		  ,fa.UsersHold
		  ,aa.RN
FROM BI_DB_dbo.BI_DB_Daily_TradeData fa
JOIN DWH_dbo.Dim_Instrument di
ON fa.InstrumentID = di.InstrumentID
 JOIN 
(
SELECT  a.InstrumentID
       ,a.FirstInstrument
		 ,a.FirstAction
       ,ROW_NUMBER() OVER (PARTITION BY a.FullDate,a.FirstAction ORDER BY a.Actions DESC) RN
FROM BI_DB_dbo.BI_DB_InstrumentsAlerts a
WHERE a.FullDate >=  cast(GETDATE()-<[Parameters].[Parameter 6]> AS DATE)
--AND FirstAction IN ('Stocks/ETFs','Crypto')
) aa
on aa.InstrumentID = fa.InstrumentID

WHERE fa.Date >= DATEADD(DAY,-180,GETDATE()-<[Parameters].[Parameter 6]>)
--AND fa.InstrumentType IN ( 'Stocks','ETF','Crypto Currencies')
AND aa.RN <= 10
GROUP BY fa.Date
        ,fa.Region
        ,fa.Country
		  ,di.Name
		  ,fa.EOD_Price
		  ,fa.OpenPositions
		  ,fa.OpenedPositions
		  ,fa.UsersOpen
		  ,fa.UsersHold
		  ,FirstAction
		  ,FirstAction
		  ,aa.RN
) bb