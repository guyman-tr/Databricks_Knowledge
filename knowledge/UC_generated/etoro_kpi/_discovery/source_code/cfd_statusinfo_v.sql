-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.cfd_statusinfo_v
-- Captured: 2026-05-19T15:04:26Z
-- ==========================================================================

SELECT 
  sanm.RealCID, 
  sanm.GCID, 
  sanm.CFD_Status,
  sanm.ApproprietnessScore_Status,
  sanm.ReleaseReasonDesc,
  sanm.ReleaseDate,
  sanm.BlockDate,
  sanm.BlockReasonDesc
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market sanm
