SELECT  mirror.ParentCID
,CopyType
  ,cc.UserName
  ,dm.Name AS Region
  ,CAST ( MoneyIn AS Decimal (12,2)) MoneyIn
 ,CAST (MoneyOut AS Decimal (12,2)) MoneyOut
 ,CAST ((MoneyIn + MoneyOut) AS Decimal (12,2)) NetMoneyIn
FROM
(
SELECT ParentCID
,case when AccountTypeID = 9 then 'Portfolio' else 'PI' END AS CopyType
  ,SUM (CASE WHEN ((MirrorOperationID=1) OR (MirrorOperationID = 3  AND Amount>0)) THEN Amount ELSE 0  END) MoneyIn
  ,SUM (CASE WHEN MirrorOperationID=2 THEN Amount*-1
 WHEN  (MirrorOperationID = 3  AND Amount<0) THEN Amount ELSE 0 END) MoneyOut
FROM [AZR-W-REAL-DB-2-BIDBUser].etoro.History.Mirror hm  with (NOLOCK) 
join [AZR-W-REAL-DB-2-BIDBUser].etoro.BackOffice.Customer bc  with (NOLOCK) 
on hm.ParentCID = bc.CID
and (AccountTypeID = 9 or GuruStatusID >= 2)
WHERE MirrorOperationID in (1,2,3) -- open/close/add or remove funds
AND ModificationDate >=  dateadd(DAY, datediff(DAY, 0, getdate()),0)
GROUP BY ParentCID,case when AccountTypeID = 9 then 'Portfolio' else 'PI' END-- , DATEPART(HOUR, ModificationDate)
) mirror
Inner join [AZR-W-REAL-DB-2-BIDBUser].etoro.Customer.Customer cc  with (NOLOCK) 
ON mirror.ParentCID = cc.CID
Inner join [AZR-W-REAL-DB-2-BIDBUser].etoro.Dictionary.Country dc  with (NOLOCK) 
ON dc.CountryID = cc.CountryID
Inner JOIN [AZR-W-REAL-DB-2-BIDBUser].etoro.Dictionary.MarketingRegion dm with (NOLOCK) 
ON dc.MarketingRegionID = dm.MarketingRegionID
Inner JOIN [AZR-W-REAL-DB-2-BIDBUser].etoro.BackOffice.Customer bc with (NOLOCK) 
ON bc.CID = cc.CID
Inner JOIN [AZR-W-REAL-DB-2-BIDBUser].etoro.BackOffice.Manager bm with (NOLOCK) 
ON bc.ManagerID = bm.ManagerID
WHERE ((cc.PlayerLevelID <> 4 and bc.GuruStatusID >= 2) or AccountTypeID = 9)