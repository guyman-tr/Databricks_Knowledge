-- 7A. Historical Disk Usage Trends (Latest timestamp per day per worker)
SELECT DISTINCT ON (DATE_TRUNC('day', hdu.record_timestamp), hdu.worker_id)
    hdu.worker_id,
    hdu.record_timestamp,
    DATE_TRUNC('day', hdu.record_timestamp) AS usage_date,
    ROUND(hdu.total_space_bytes / (1024.0 * 1024 * 1024), 2) AS total_space_gb,
    ROUND(hdu.used_space_bytes / (1024.0 * 1024 * 1024), 2) AS used_space_gb,
    ROUND((hdu.total_space_bytes - hdu.used_space_bytes) / (1024.0 * 1024 * 1024), 2) AS free_space_gb,
    ROUND(100.0 * hdu.used_space_bytes / NULLIF(hdu.total_space_bytes, 0), 2) AS used_percent
FROM public.historical_disk_usage hdu
WHERE hdu.record_timestamp >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY DATE_TRUNC('day', hdu.record_timestamp) DESC, hdu.worker_id, hdu.record_timestamp DESC