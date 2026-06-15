-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.funded
-- Captured: 2026-05-19T14:53:10Z
-- ==========================================================================

SELECT year(ActiveDate) Year ,CID
FROM main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata bdcmpfd
WHERE IsFunded_New=1
AND ActiveDate>='2019-01-01'
AND ActiveDate<'2024-07-01'
GROUP BY year(ActiveDate) ,CID
