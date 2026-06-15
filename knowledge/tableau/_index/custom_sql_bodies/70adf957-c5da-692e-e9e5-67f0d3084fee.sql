SELECT *,
CONVERT (datetime,convert(char(8),DateID))as Date
FROM BI_DB..BI_DB_DDR_Daily_Aggregated
WHERE DateID>=20200101