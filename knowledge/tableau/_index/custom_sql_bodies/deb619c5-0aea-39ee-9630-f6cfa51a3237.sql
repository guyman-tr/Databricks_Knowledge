SELECT DISTINCT cast(efc.EventTimeStamp AS date) AS Date,
client_Type,
beta.total_group AS invited_users,
COUNT(DISTINCT efa.Gcid) AS Card_Ordering,
COUNT( efc.GCID)    AS activated
FROM
(SELECT DISTINCT GCID,CASE WHEN mbu.Date_Inserted<='2021-11-25' THEN 'Old' ELSE 'New' END AS client_Type, COUNT(GCID) OVER (PARTITION BY CASE WHEN mbu.Date_Inserted<='2021-11-25' THEN 'Old' ELSE 'New' END) AS total_group   FROM eMoney_BetaUsers mbu WHERE mbu.Program='Card-UK') AS beta
left JOIN
ETL_FiatAccount efa
ON beta.GCID=efa.Gcid AND efa.DateID>='20211125'
left JOIN 
(SELECT * 
from (SELECT c.GCID,cardstatus.Name ,cs.EventTimeStamp ,row_number() over (partition by cs.CardId order by cs.EventTimeStamp desc) as RN
FROM [dbo].[ETL_FiatCardStatuses] cs
join [dbo].[ETL_DictionaryCardStatuses] cardstatus on cardstatus.Id=cs.[CardStatusId]
join [dbo].[ETL_FiatCards] cards on cards.Id=cs.CardId
join [dbo].[ETL_FiatAccount] account on account.Id=cards.[AccountId]
join DWH.dbo.Dim_Customer c on c.GCID=account.Gcid
WHERE cs.DateID>='20211125') efc WHERE efc.RN=1 AND efc.Name='Activated')efc
ON beta.GCID=efc.GCID  --AND efa.Date=CAST(efc.EventTimeStamp AS DATE)
GROUP BY cast(efc.EventTimeStamp AS date),client_Type,beta.total_group