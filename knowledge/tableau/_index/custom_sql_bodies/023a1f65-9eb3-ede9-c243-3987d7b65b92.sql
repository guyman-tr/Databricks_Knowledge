WITH AdoptionDateRegulation AS (
  SELECT
    FromDateID,
    ToDateID,
    RegulationID,
    dr.Name AS Regulation,
    pe.*
  FROM main.ml.ml_output_models_joaquin_riskdivers_before_after_conversion_performance pe
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON pe.CID = fsc.RealCID
   AND fsc.IsValidCustomer = 1 
   AND fsc.IsDepositor = 1
   AND FromDateID <= CAST(DATE_FORMAT(etr_ymd_conversion, 'yyyyMMdd') AS INT)
   AND ToDateID >= CAST(DATE_FORMAT(etr_ymd_conversion, 'yyyyMMdd') AS INT)
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
    ON dr.DWHRegulationID = fsc.RegulationID
  WHERE pe.save_date = (
    SELECT MAX(save_date)
    FROM main.ml.ml_output_models_joaquin_riskdivers_before_after_conversion_performance
  )
),

-- CTE חדש לבדיקת פז"ם קופי של הלקוח
FirstCopyCheck AS (
    SELECT 
        CID, 
        MIN(OpenDateID) as FirstEverCopyDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
    GROUP BY CID
),

RankedData AS (
  SELECT
    ff.CID,
    ff.etr_ymd_conversion,
    ff.months,
    ff.after_cid_return,
    CASE WHEN ff.after_cid_volatility IS NULL THEN 0.0 ELSE ff.after_cid_volatility END AS after_cid_volatility,
    ff.after_cid_VaR95,
    ff.after_cid_drawdown,
    ff.after_parent_return,
    CASE WHEN ff.after_parent_volatility IS NULL THEN 0.0 ELSE ff.after_parent_volatility END AS after_parent_volatility,
    ff.after_parent_VaR95,
    ff.after_parent_drawdown,
    ff.save_timestamp,
    ff.save_date,
    ff.UserName,
    dpl.Name AS Club,
    ff.before_sim30_CIDS,
    ff.before_sim30_amounts,
    ff.before_sim30_return,
    ff.before_sim30_volatility,
    ff.before_sim30_VaR95,
    ff.before_sim30_drawdown,
    ff.after_sim30_CIDS,
    ff.after_sim30_amounts,
    ff.after_sim30_return,
    CASE WHEN ff.after_sim30_volatility IS NULL THEN 0.0 ELSE ff.after_sim30_volatility END AS after_sim30_volatility,
    ff.after_sim30_VaR95,
    ff.after_sim30_drawdown,
    rp.Regulation,
    ff.MaxRisk,
    ff.parent_max_risk_score,
    dr.Name AS DesignatedRegulation,
    array_distinct(ff.after_parent_CIDS) AS after_parent_CIDS,
    ff.after_parent_amounts,
    ff.sum_parent_amounts_after,
    COALESCE(vl.Liabilities, 0) + COALESCE(vl.ActualNWA, 0) AS Equity,
    fcc.FirstEverCopyDateID, -- הוספת שדה התאריך הראשון
    ROW_NUMBER() OVER (
      PARTITION BY ff.CID, ff.months
      ORDER BY ff.etr_ymd_conversion DESC, ff.save_date DESC, ff.save_timestamp DESC
    ) AS rn
  FROM main.ml.ml_output_models_joaquin_riskdivers_before_after_conversion_performance ff
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
    ON dc.RealCID = ff.CID 
   AND dc.IsValidCustomer = 1 
   AND dc.IsDepositor = 1
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl 
    ON dpl.PlayerLevelID = dc.PlayerLevelID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
    ON vl.CID = ff.CID
   AND vl.DateID = CAST(DATE_FORMAT(DATE_SUB(ff.etr_ymd_conversion, 0), 'yyyyMMdd') AS INT)
  LEFT JOIN AdoptionDateRegulation rp
    ON rp.CID = ff.CID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
    ON dr.DWHRegulationID = dc.DesignatedRegulationID
  LEFT JOIN FirstCopyCheck fcc -- חיבור ל-CTE החדש
    ON fcc.CID = ff.CID
  WHERE ff.save_date = (
    SELECT MAX(save_date)
    FROM main.ml.ml_output_models_joaquin_riskdivers_before_after_conversion_performance
  )
    AND ff.etr_ymd_conversion >= '2025-06-30'
  GROUP BY
    ff.CID, ff.etr_ymd_conversion, ff.months,
    ff.after_cid_return, ff.after_cid_volatility, ff.after_cid_VaR95, ff.after_cid_drawdown,
    ff.after_parent_return, ff.after_parent_volatility, ff.after_parent_VaR95, ff.after_parent_drawdown,
    ff.save_timestamp, ff.save_date,
    ff.after_parent_CIDS, ff.after_parent_amounts,
    vl.Liabilities, ff.sum_parent_amounts_before,
    ff.sum_parent_amounts_after, vl.ActualNWA,
    rp.Regulation, dr.Name, ff.UserName, ff.MaxRisk, dpl.Name,
    ff.before_sim30_CIDS,
    ff.before_sim30_amounts,
    ff.before_sim30_return,
    ff.before_sim30_volatility,
    ff.before_sim30_VaR95,
    ff.before_sim30_drawdown,
    ff.after_sim30_CIDS,
    ff.after_sim30_amounts,
    ff.after_sim30_return,
    ff.after_sim30_volatility,
    ff.after_sim30_VaR95,
    ff.after_sim30_drawdown,
    ff.parent_max_risk_score,
    fcc.FirstEverCopyDateID
),

ExplodedParents AS (
  SELECT
    r.*,
    parent_cid
  FROM RankedData r
  LATERAL VIEW explode(r.after_parent_CIDS) AS parent_cid
),

CopyStatus AS (
  SELECT
    e.CID,
    e.etr_ymd_conversion,
    e.months,
    COUNT(DISTINCT e.parent_cid) AS total_parents,
    SUM(
      CASE 
        WHEN dm.CID IS NOT NULL 
             AND dm.IsActive = 1 
             AND (dm.PauseCopy = 0 OR dm.PauseCopy IS NULL)
        THEN 1 ELSE 0 
      END
    ) AS still_copying_parents
  FROM ExplodedParents e
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror dm
    ON dm.CID = e.CID
   AND dm.ParentCID = e.parent_cid
  WHERE e.rn = 1
    AND e.months IN (1,3,6,9,12)
  GROUP BY
    e.CID,
    e.etr_ymd_conversion,
    e.months
)

SELECT
  r.CID,
  r.etr_ymd_conversion,
  r.months,
  r.after_cid_return,
  r.after_cid_volatility,
  r.after_cid_VaR95,
  r.after_cid_drawdown,
  r.after_parent_return,
  r.after_parent_volatility,
  r.after_parent_VaR95,
  r.after_parent_drawdown,
  r.save_timestamp,
  r.save_date,
  r.UserName,
  r.MaxRisk,
  r.parent_max_risk_score,
  r.before_sim30_CIDS,
  r.before_sim30_amounts,
  r.before_sim30_return,
  r.before_sim30_volatility,
  r.before_sim30_VaR95,
  r.before_sim30_drawdown,
  r.after_sim30_CIDS,
  r.after_sim30_amounts,
  r.after_sim30_return,
  r.after_sim30_volatility,
  r.after_sim30_VaR95,
  r.after_sim30_drawdown,
  r.after_parent_CIDS,
  r.after_parent_amounts,
  r.sum_parent_amounts_after,
  r.Equity,
  r.Club,
  (r.sum_parent_amounts_after / NULLIF(r.Equity, 0)) AS equity_pct,
  r.Regulation,
  r.DesignatedRegulation,
  cs.total_parents,
  cs.still_copying_parents,

  -- האינדיקציה החדשה: האם הקופי הראשון היה בתאריך ההמרה (או אחריו)?
  CASE 
    WHEN r.FirstEverCopyDateID >= CAST(DATE_FORMAT(r.etr_ymd_conversion, 'yyyyMMdd') AS INT) THEN 'Yes'
    ELSE 'No'
  END AS IsFirstCopyInProgram,

 CASE 
    WHEN cs.still_copying_parents = 0 THEN 'Copying 0 of 3'
    WHEN cs.still_copying_parents = 1 THEN 'Copying 1 of 3'
    WHEN cs.still_copying_parents = 2 THEN 'Copying 2 of 3'
    WHEN cs.still_copying_parents >= 3 THEN 'Copying all 3'
  END AS Copying_Group

FROM RankedData r
LEFT JOIN CopyStatus cs
  ON cs.CID = r.CID
 AND cs.etr_ymd_conversion = r.etr_ymd_conversion
 AND cs.months = r.months
WHERE r.rn = 1
  AND r.months IN (1,3,6,9,12)