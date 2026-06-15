SELECT efa.Date,
COUNT(DISTINCT efa.Gcid) AS Card_Ordering
--COUNT(DISTINCT efc.GCID) AS activated
FROM
(SELECT DISTINCT GCID FROM eMoney_BetaUsers mbu WHERE mbu.Program='Card-UK') AS beta
left JOIN ETL_FiatAccount efa
ON beta.GCID=efa.Gcid AND efa.DateID>='20211125'
group by efa.Date