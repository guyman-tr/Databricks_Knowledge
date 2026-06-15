-- Use CTEs for a cleaner, more performant translation in Databricks
WITH DateParams AS (
  SELECT CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), 'yyyyMMdd') AS INT) AS DateID
),

cids AS (
  Select *
  from
    main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations a
  WHERE
    a.Category in ('Special Promotion')
    and a.Amount > 0  -- =30
    and a.etr_ymd >= add_months(current_date(), -12)
),

dep AS (
  SELECT
    c.CID,
    SUM(ad.AmountUSD) AS TotalDeposits
  FROM
    (SELECT DISTINCT CID FROM cids) c
  JOIN
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ad ON ad.CID = c.CID
  WHERE
    ad.PaymentStatusID = 2 -- Approved
  GROUP BY
    c.CID
),

LIABILITIES AS (
  SELECT
    l.CID,
    (Liabilities + ActualNWA) AS TotalEquity,
    Credit AS Balance
  FROM
    (SELECT DISTINCT CID FROM cids) c
  JOIN
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities l ON c.CID = l.CID
  WHERE
    l.DateID = (SELECT DateID FROM DateParams)
),

co AS (
  SELECT DISTINCT
    c.CID,
    c.Time,
    w.ModificationDate
  FROM
    (SELECT DISTINCT CID, Time FROM cids) c
  LEFT JOIN
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw w ON w.CID = c.CID
  WHERE
    w.CashoutStatusID_Funding = 3
    AND w.ModificationDate BETWEEN c.Time AND DATE_ADD(c.Time, 10)
),

final AS (
  SELECT DISTINCT
    c.CID
  FROM
    (SELECT DISTINCT CID FROM co) c
  JOIN
    LIABILITIES l ON l.CID = c.CID AND l.TotalEquity <= 20
),

pos AS (
  SELECT
    p.CID,
    COUNT(p.PositionID) AS TotalPositions
  FROM
    cids c
  JOIN
    main.dwh.dim_position p ON p.CID = c.CID
  GROUP BY
    p.CID
)

SELECT
  c.CID,
  c.time as Occurred,
  c.Amount as Payment,
  c.Description,
  c.Manager,
  c.Category,
  c.Country_Reg_Form as Country,
  c.Regulation,
  dc.GCID,
  c.Player_level as PlayerLevel,
  d.TotalDeposits,
  CASE WHEN f.CID IS NULL THEN 'No Abuser' ELSE 'Abuser' END AS SpecialPromotion_CO_LowBalance_Filter,
  p.TotalPositions,
  a.AirdropStatusName,
  dc.AffiliateID
FROM
  cids c
LEFT JOIN
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = c.CID
LEFT JOIN
  dep d ON d.CID = c.CID
LEFT JOIN
  final f ON f.CID = c.CID
LEFT JOIN
  pos p ON p.CID = c.CID
LEFT JOIN
  (SELECT
    c.CID,
    REPLACE(REPLACE(REPLACE(CONCAT_WS(',', COLLECT_SET(a.AirdropStatusName)), '[', ''), ']', ''), '"', '') AS AirdropStatusName
  FROM
    main.bi_db.bronze_marketperformance_airdrop_customer c
  LEFT JOIN
    main.general.bronze_marketperformance_dictionary_airdropstatus a ON a.AirdropStatusID = c.AirdropStatusID
  GROUP BY
    c.CID) a on a.cid = c.CID