-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_dim_dataplatform_uuid
-- Captured: 2026-05-18T08:04:49Z
-- ==========================================================================

WITH
-- All eToro persons: one row per GCID
etoro AS (
  SELECT
    GCID,
    MIN(RealCID)                AS primary_cid,
    COUNT(DISTINCT RealCID)     AS cid_count
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
  WHERE GCID NOT IN (1, 2, 3)   -- test GCIDs, multi-CID, never deposited
  GROUP BY GCID
),

-- SPS user_ids that are cross-onboarded (have a GCID via sub_accounts)
sps_cross AS (
  SELECT DISTINCT accountId AS sps_user_id, gcid
  FROM main.bi_db.bronze_sub_accounts_accounts
  WHERE providerName = 'Spaceship'
    AND gcid IS NOT NULL
),

-- All distinct SPS user_ids
sps_all AS (
  SELECT DISTINCT user_id AS sps_user_id
  FROM main.etoro_kpi.v_spaceship_aum
),

-- SPS-only: not mapped to any GCID
sps_only AS (
  SELECT sps_user_id
  FROM sps_all
  WHERE sps_user_id NOT IN (SELECT sps_user_id FROM sps_cross)
)

-- eToro users (tagged 'both_gcid' if also in SPS)
SELECT
  CAST(e.GCID AS STRING)                                                        AS dp_uuid,
  CASE WHEN sc.sps_user_id IS NOT NULL THEN 'both_gcid' ELSE 'etoro_gcid' END   AS source_platform,
  e.GCID                                                                        AS gcid,
  e.primary_cid                                                                 AS cid,
  e.cid_count                                                                   AS etoro_cid_count,
  sc.sps_user_id
FROM etoro e
LEFT JOIN sps_cross sc ON e.GCID = sc.gcid

UNION ALL

-- SPS-only users (no GCID)
SELECT
  sps_user_id                       AS dp_uuid,
  'spaceship_userid'                AS source_platform,
  NULL                              AS gcid,
  NULL                              AS cid,
  NULL                              AS etoro_cid_count,
  sps_user_id
FROM sps_only
