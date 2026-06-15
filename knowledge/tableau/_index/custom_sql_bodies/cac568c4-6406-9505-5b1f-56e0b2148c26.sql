SELECT 'Alert' AS Indicator
 ,a.FullDate
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
-- ,NULL AS Channel
 ,NULL AS EOD_Price
 ,NULL AS OpenPositions
 ,NULL AS OpenedPositions
 ,NULL AS UsersOpen
 ,NULL AS UsersHold

,ISNULL(CASE WHEN
    (Tier = 1
and Actions>= 25
and Actions/NULLIF(avg7d_past,0)>2.8
--and Actions/NULLIF(avg14d_past,0)>3.3
)
or
(Tier = 2
and Actions>= 15
and Actions/NULLIF(avg7d_past,0)>3
and Actions/NULLIF(avg14d_past,0)>3.5
)

or
( Tier = 3
and Actions>= 5
and Actions/NULLIF(avg7d_past,0)>3.5
and Actions/NULLIF(avg14d_past,0)>4
)

or
(Tier = 4
and Actions>=5
and Actions/NULLIF(avg7d_past,0)>5
and Actions/NULLIF(avg14d_past,0)>5.5
)

then 1 END,0) AS Alert

FROM BI_DB_dbo.BI_DB_InstrumentsAlerts a

WHERE a.FullDate >= cast(GETDATE()-2 as date)
AND FirstAction IN ('Stocks/ETFs','Crypto')
AND ISNULL(CASE WHEN
    (Tier = 1
and Actions>= 25
and Actions/NULLIF(avg7d_past,0)>2.8
--and Actions/NULLIF(avg14d_past,0)>3.3
)

or
(Tier = 2
and Actions>= 15
and Actions/NULLIF(avg7d_past,0)>3
--and Actions/NULLIF(avg14d_past,0)>3.5
)

or
( Tier = 3
and Actions>= 5
and Actions/NULLIF(avg7d_past,0)>3.5
--and Actions/NULLIF(avg14d_past,0)>4
)

or
(Tier = 4
and Actions>=5
and Actions/NULLIF(avg7d_past,0)>5
--and Actions/NULLIF(avg14d_past,0)>5.5
)

then 1 END,0) = 1

UNION 

----------------
SELECT  'FirstActions' AS Indicator
 ,Date
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
-- ,Channel
 ,NULL AS EOD_Price
 ,NULL AS OpenPositions
 ,NULL AS OpenedPositions
 ,NULL AS UsersOpen
 ,NULL AS UsersHold
 ,Alert
 FROM 
(
 SELECT  cast(fa.FirstActionDate as date) Date
        ,fa.Region
        ,fa.Country
     --   ,fa.SubChannel as Channel
       ,fa.FirstInstrument 
		 ,case when aa.FirstInstrument is not null then 1 else 0 end AS Alert
        ,COUNT(*) FirstActions
FROM BI_DB_dbo.BI_DB_First5Actions fa
left join 
(SELECT a.FirstInstrument
FROM BI_DB_dbo.BI_DB_InstrumentsAlerts a
WHERE a.FullDate >=  cast(GETDATE()-2 as date)
AND FirstAction IN ('Stocks/ETFs','Crypto')
AND ISNULL(CASE WHEN
    (Tier = 1
and Actions>= 25
and Actions/NULLIF(avg7d_past,0)>2.8
--and Actions/NULLIF(avg14d_past,0)>3.3
)

or
(Tier = 2
and Actions>= 15
and Actions/NULLIF(avg7d_past,0)>3
--and Actions/NULLIF(avg14d_past,0)>3.5
)

or
( Tier = 3
and Actions>= 5
and Actions/NULLIF(avg7d_past,0)>3.5
--and Actions/NULLIF(avg14d_past,0)>4
)

or
(Tier = 4
and Actions>=5
and Actions/NULLIF(avg7d_past,0)>5
and Actions/NULLIF(avg14d_past,0)>5.5
)

then 1 END,0) = 1
) aa
on aa.FirstInstrument = fa.FirstInstrument
WHERE fa.FirstActionDate >= DATEADD(DAY,-60,GETDATE()-2)
AND fa.FirstAction IN ('Stocks/ETFs','Crypto')
GROUP BY cast(fa.FirstActionDate as date)
        ,fa.Region
        ,fa.Country
      --  ,fa.SubChannel
		  ,fa.FirstInstrument
		  ,case when aa.FirstInstrument is not null then 1 else 0 end 
) bb




UNION
--------------------

SELECT  'TradeData' AS Indicator
 ,Date
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
 --,NULL
 ,bb.EOD_Price
 ,bb.OpenPositions
 ,bb.OpenedPositions
 ,bb.UsersOpen
 ,bb.UsersHold
 ,Alert
 FROM 
(
 SELECT  fa.Date
        ,fa.Region
        ,fa.Country
		  ,di.Name AS InstrumentName
		  ,fa.EOD_Price
		  ,fa.OpenPositions
		  ,fa.OpenedPositions
		  ,fa.UsersOpen
		  ,fa.UsersHold
		  ,CASE WHEN aa.InstrumentID IS NOT NULL THEN 1 ELSE 0 END AS Alert
FROM BI_DB_dbo.BI_DB_Daily_TradeData fa
JOIN DWH_dbo.Dim_Instrument di
ON fa.InstrumentID = di.InstrumentID
LEFT JOIN 
(
SELECT a.InstrumentID
FROM BI_DB_dbo.BI_DB_InstrumentsAlerts a
WHERE a.FullDate >=  cast(GETDATE()-2 as date)
AND FirstAction IN ('Stocks/ETFs','Crypto')
AND ISNULL(CASE WHEN
    (Tier = 1
and Actions>= 25
and Actions/NULLIF(avg7d_past,0)>2.8
--and Actions/NULLIF(avg14d_past,0)>3.3
)

or
(Tier = 2
and Actions>= 15
and Actions/NULLIF(avg7d_past,0)>3
--and Actions/NULLIF(avg14d_past,0)>3.5
)

or
( Tier = 3
and Actions>= 5
and Actions/NULLIF(avg7d_past,0)>3.5
--and Actions/NULLIF(avg14d_past,0)>4
)

or
(Tier = 4
and Actions>=5
and Actions/NULLIF(avg7d_past,0)>5
--and Actions/NULLIF(avg14d_past,0)>5.5
)

then 1 END,0) = 1
) aa
on aa.InstrumentID = fa.InstrumentID
WHERE fa.Date >= DATEADD(DAY,-180,GETDATE()-2)
AND fa.InstrumentType IN ('Stocks/ETFs','Crypto')

) bb