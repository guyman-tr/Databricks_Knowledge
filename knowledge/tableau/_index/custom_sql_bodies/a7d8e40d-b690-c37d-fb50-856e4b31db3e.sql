-- 7B. Storage by Content Type
SELECT 
    'Workbooks' AS content_type,
    COUNT(*) AS item_count,
    ROUND(SUM(w.size) / (1024.0 * 1024 * 1024), 2) AS total_size_gb
FROM public.workbooks w
UNION ALL
SELECT 
    'Datasources' AS content_type,
    COUNT(*) AS item_count,
    ROUND(SUM(ds.size) / (1024.0 * 1024 * 1024), 2) AS total_size_gb
FROM 
 (select * 
  from public.datasources
-- Datasources that their creds are not embedded hold no size
  WHERE embedded != ''
) ds
UNION ALL
SELECT 
    'Extracts' AS content_type,
    COUNT(*) AS item_count,
    ROUND(SUM(e.size) / (1024.0 * 1024 * 1024), 2) AS total_size_gb
FROM public.extracts e