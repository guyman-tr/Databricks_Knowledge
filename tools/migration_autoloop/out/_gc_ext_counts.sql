SELECT 'ext_fgc' AS src, COUNT(*) AS rows, COUNT(DISTINCT CID) AS cids, MIN(DateID) AS min_d, MAX(DateID) AS max_d
FROM dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers
UNION ALL
SELECT 'lake_snap', COUNT(*), COUNT(DISTINCT CID), MIN(CAST(date_format(`TIMESTAMP`, 'yyyyMMdd') AS INT)), MAX(CAST(date_format(`TIMESTAMP`, 'yyyyMMdd') AS INT))
FROM dwh_daily_process.daily_snapshot.etoro_History_GuruCopiers
WHERE `TIMESTAMP` = CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
