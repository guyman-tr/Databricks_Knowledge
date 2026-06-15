SELECT TOP 20 SymbolFull
			 ,InstrumentDisplayName
	   	     ,CAST ( MoneyIn AS Decimal (12,2)) AS  MoneyIn
			 ,CAST (MoneyOut AS Decimal (12,2)) MoneyOut
			 ,CAST ((MoneyIn + MoneyOut) AS Decimal (12,2)) AS NetMoneyIn
FROM
(
SELECT imd.InstrumentDisplayName
	  ,imd.SymbolFull
	  ,SUM(CASE WHEN hm.CreditTypeID=3 THEN hm.Payment*-1 ELSE 0 END) AS  MoneyIn
	  ,SUM(CASE WHEN hm.CreditTypeID=4 THEN hm.Payment*-1 ELSE 0 END) AS MoneyOut
FROM [AZR-W-REAL-DB-2-BIDBUser].etoro.History.Credit hm  with (NOLOCK) 
JOIN (
select PositionID,InstrumentID
from [AZR-W-REAL-DB-2-BIDBUser].etoro.History.Position hp
where  (hp.OpenOccurred >=  dateadd(DAY, datediff(DAY, 0, getdate()),0)
	 OR hp.CloseOccurred >=  dateadd(DAY, datediff(DAY, 0, getdate()),0))
union 
select PositionID,InstrumentID
from [AZR-W-REAL-DB-2-BIDBUser].etoro.Trade.Position tp
where tp.Occurred >=  dateadd(DAY, datediff(DAY, 0, getdate()),0)) P0
ON hm.PositionID = P0.PositionID
JOIN [AZR-W-REAL-DB-2-BIDBUser].etoro.Trade.InstrumentMetaData imd with (NOLOCK) 
ON P0.InstrumentID=imd.InstrumentID
WHERE hm.CreditTypeID IN(3,4)
AND hm.MirrorID=0 
AND hm.Occurred >=  dateadd(DAY, datediff(DAY, 0, getdate()-1),0)
--AND (hp.OpenOccurred >=  dateadd(DAY, datediff(DAY, 0, getdate()),0)
--OR hp.CloseOccurred >=  dateadd(DAY, datediff(DAY, 0, getdate()),0))
AND imd.InstrumentTypeID IN (5,6)
GROUP BY imd.InstrumentDisplayName
	    ,imd.SymbolFull) Q0
ORDER BY NetMoneyIn