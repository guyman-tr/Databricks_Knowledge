/* =========================================================================
   Securities-Transfer Compensation Report
   Converted from T-SQL (Synapse) to Databricks SQL
   Single CTE-based query – Tableau Custom SQL compatible
   ========================================================================= */

WITH

/* -- Compensations: driving set ------------------------------------------ */
comp AS (
  SELECT
    s.RealCID AS CID,
    SUM(s.Amount) AS TotalCompensation
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction AS s
  WHERE s.ActionTypeID = 36
    AND s.CompensationReasonID = 120
  GROUP BY s.RealCID
),

/* -- Alerts: Lifetime Deposits ------------------------------------------- */
ld_alerts AS (
  SELECT
    t.CID,
    'Yes' AS LifetimeDeposits_AlertTriggered,
    ARRAY_JOIN(COLLECT_SET(t.SubReason), ', ') AS LifetimeDeposits_SubType
  FROM (
    SELECT DISTINCT
      ra.CID,
      ra.SubReason
    FROM main.bi_output_stg.bi_output_operations_risk_alert_management_tool AS ra
    WHERE ra.AlertTypeDescription = 'Lifetime Deposits'
      AND ra.RN1 = 1
  ) AS t
  GROUP BY t.CID
),

/* -- Alerts: Unjustified Source of Income -------------------------------- */
usoi_alerts AS (
  SELECT
    t.CID,
    'Yes' AS UnjustifiedSOI_AlertTriggered,
    ARRAY_JOIN(COLLECT_SET(t.SubReason), ', ') AS Unjustified_SubType
  FROM (
    SELECT DISTINCT
      ra.CID,
      ra.SubReason
    FROM main.bi_output_stg.bi_output_operations_risk_alert_management_tool AS ra
    WHERE ra.AlertTypeDescription = 'Unjustified Source of Income'
      AND ra.RN1 = 1
  ) AS t
  GROUP BY t.CID
),

/* -- Customer slice: only CIDs with compensations ------------------------ */
cids AS (
  SELECT
    dc.RealCID,
    r.Name AS Regulation,
    rc.RiskClassificationName,
    COALESCE(ld.LifetimeDeposits_AlertTriggered, 'No') AS LifetimeDeposits_Alert_triggered,
    COALESCE(usoi.UnjustifiedSOI_AlertTriggered, 'No') AS Unjustified_SOI_Alert_triggered,
    usoi.Unjustified_SubType,
    ld.LifetimeDeposits_SubType
  FROM comp AS c
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc
    ON dc.RealCID = c.CID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS r
    ON r.ID = dc.RegulationID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification AS rc
    ON rc.RiskClassificationID = dc.RiskClassificationID
  LEFT JOIN ld_alerts AS ld ON ld.CID = dc.RealCID
  LEFT JOIN usoi_alerts AS usoi ON usoi.CID = dc.RealCID
),

/* -- Liabilities (yesterday snapshot) ------------------------------------ */
liabilities AS (
  SELECT
    l.CID,
    (l.Liabilities + l.ActualNWA) AS TotalEquity,
    l.Credit AS Balance
  FROM cids AS c
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities AS l
    ON l.CID = c.RealCID
  WHERE l.DateID = CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), 'yyyyMMdd') AS INT)
),

/* -- Deposits ------------------------------------------------------------ */
dep AS (
  SELECT
    c.RealCID,
    SUM(ad.AmountUSD) AS TotalDepositsAmount
  FROM cids AS c
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit AS ad
    ON ad.CID = c.RealCID
  WHERE ad.PaymentStatusID = 2
  GROUP BY c.RealCID
),

/* -- Cashouts ------------------------------------------------------------ */
co AS (
  SELECT
    bw.CID,
    SUM(bw.Amount_WithdrawToFunding) AS TotalCO_Sent
  FROM cids AS c
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw AS bw
    ON bw.CID = c.RealCID
  WHERE bw.CashoutStatusID_Funding = 3
  GROUP BY bw.CID
),

/* -- Last compensation date (securities transfer) ------------------------ */
compdate AS (
  SELECT
    s.RealCID,
    MAX(s.Occurred) AS LastCompDate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction AS s
WHERE s.ActionTypeID = 36 and s.CompensationReasonID = 120
  GROUP BY s.RealCID
),

/* -- Final aggregation --------------------------------------------------- */
final AS (
  SELECT
    c.RealCID,
    c.Regulation,
    c.RiskClassificationName,
    c.LifetimeDeposits_Alert_triggered,
    c.Unjustified_SOI_Alert_triggered,
    c.Unjustified_SubType,
    c.LifetimeDeposits_SubType,
    da.LastCompDate,
    COALESCE(l.TotalEquity, 0)              AS TradingEquity,
    COALESCE(d.TotalDepositsAmount, 0)      AS TotalDepositsAmount,
    COALESCE(co.TotalCO_Sent, 0)            AS TotalCashoutsAmount,
    COALESCE(comp.TotalCompensation, 0)     AS TotalCompensation,
    COALESCE(d.TotalDepositsAmount, 0) + COALESCE(comp.TotalCompensation, 0)
                                            AS `Total Deposits + Securities Transfer`,
    CASE
      WHEN COALESCE(d.TotalDepositsAmount, 0) + COALESCE(comp.TotalCompensation, 0) >= 3000000 THEN 'I: Above $3M'
      WHEN COALESCE(d.TotalDepositsAmount, 0) + COALESCE(comp.TotalCompensation, 0) >= 2000000 THEN 'H: Reached $2M'
      WHEN COALESCE(d.TotalDepositsAmount, 0) + COALESCE(comp.TotalCompensation, 0) >= 1500000 THEN 'G: Reached $1.5M'
      WHEN COALESCE(d.TotalDepositsAmount, 0) + COALESCE(comp.TotalCompensation, 0) >= 1000000 THEN 'F: Reached $1M'
      WHEN COALESCE(d.TotalDepositsAmount, 0) + COALESCE(comp.TotalCompensation, 0) >=  500000 THEN 'E: Reached $500K'
      WHEN COALESCE(d.TotalDepositsAmount, 0) + COALESCE(comp.TotalCompensation, 0) >=  250000 THEN 'D: Reached $250K'
      WHEN COALESCE(d.TotalDepositsAmount, 0) + COALESCE(comp.TotalCompensation, 0) >=  100000 THEN 'C: Reached $100K'
      WHEN COALESCE(d.TotalDepositsAmount, 0) + COALESCE(comp.TotalCompensation, 0) >=   50000 THEN 'B: Reached $50K'
      ELSE 'A: Below $50K'
    END AS AggregateAmountThreshold
  FROM cids AS c
  LEFT JOIN liabilities AS l ON l.CID = c.RealCID
  LEFT JOIN dep AS d ON d.RealCID = c.RealCID
  LEFT JOIN co ON co.CID = c.RealCID
  LEFT JOIN comp ON comp.CID = c.RealCID
  LEFT JOIN compdate AS da ON da.RealCID = c.RealCID
)

/* -- Output filter ------------------------------------------------------- */
SELECT *
FROM final
WHERE AggregateAmountThreshold IN (
      'I: Above $3M',
      'H: Reached $2M',
      'G: Reached $1.5M',
      'F: Reached $1M',
      'E: Reached $500K',
      'D: Reached $250K'
  )
  OR (AggregateAmountThreshold IN ('C: Reached $100K', 'B: Reached $50K')
      AND RiskClassificationName = 'High')