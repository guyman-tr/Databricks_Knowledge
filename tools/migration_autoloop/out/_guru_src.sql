SELECT MIN(`TIMESTAMP`) AS min_ts, MAX(`TIMESTAMP`) AS max_ts, COUNT(*) AS rows
FROM dwh_daily_process.daily_snapshot.etoro_History_GuruCopiers
