SELECT  *
FROM BI_DB..BI_DB_DailyCommisionReport dcr
WHERE dcr.Region IN ('China','Other Asia')
AND dcr.DateID>=20200101