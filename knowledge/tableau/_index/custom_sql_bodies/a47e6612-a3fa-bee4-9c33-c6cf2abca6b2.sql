SELECT cast(efc.EventTimeStamp AS date) AS Date,
--COUNT(DISTINCT efa.Gcid) AS Card_Ordering,
COUNT(DISTINCT efc.GCID) AS activated
FROM
(SELECT DISTINCT GCID FROM eMoney_BetaUsers mbu WHERE mbu.Program='Card-UK') AS beta
inner JOIN 
(SELECT * 
from (SELECT c.GCID,cardstatus.Name ,cs.EventTimeStamp ,row_number() over (partition by cs.CardId order by cs.EventTimeStamp desc) as RN
FROM [dbo].[ETL_FiatCardStatuses] cs
join [dbo].[ETL_DictionaryCardStatuses] cardstatus on cardstatus.Id=cs.[CardStatusId]
join [dbo].[ETL_FiatCards] cards on cards.Id=cs.CardId
join [dbo].[ETL_FiatAccount] account on account.Id=cards.[AccountId]
join DWH.dbo.Dim_Customer c on c.GCID=account.Gcid
WHERE cs.DateID>='20211125') efc WHERE efc.RN=1 AND efc.Name='Activated')efc
ON beta.GCID=efc.GCID  --AND efa.Date=CAST(efc.EventTimeStamp AS DATE)
GROUP BY cast(efc.EventTimeStamp AS date)