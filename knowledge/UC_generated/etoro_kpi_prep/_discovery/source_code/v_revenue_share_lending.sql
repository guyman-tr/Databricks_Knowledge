-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_share_lending
-- Captured: 2026-05-19T12:23:28Z
-- ==========================================================================

SELECT
    fca.RealCID,
    fsc.GCID,
    fca.DateID,
    fca.Occurred,
    fca.Amount  AS ShareLendingFeeEtoroShare,
    fca.Amount  AS ShareLendingFeeUserShare,
    fca.Amount / 0.4 - 2 * fca.Amount AS ShareLendingFeeBrokerShare,
    fca.Amount / 0.4                  AS ShareLendingGrossAmount,
    fsc.IsValidCustomer
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON fca.RealCID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
WHERE fca.ActionTypeID = 36
    AND fca.CompensationReasonID = 119
