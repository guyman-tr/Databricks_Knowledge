-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.v_spaceship_fees
-- Captured: 2026-05-19T15:18:19Z
-- ==========================================================================

WITH
user_accounts AS (
  SELECT member_id, user_id
  FROM (
    SELECT
      member_id,
      user_id,
      ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY user_id) AS rn
    FROM main.spaceship.bronze_spaceship_metabase_user_beta
    WHERE member_id IS NOT NULL
  )
  WHERE rn = 1
),

super_fees AS (
  SELECT
    'Super'                                                   AS product,
    CAST(st.paid_date AS DATE)                                AS date,
    COALESCE(ua.user_id, st.member_id)                        AS user_id,
    CAST(st.aud_amount AS DOUBLE)                             AS fee_amount
  FROM main.spaceship.bronze_spaceship_metabase_super_transactions st
  LEFT JOIN user_accounts ua
    ON st.member_id = ua.member_id
  WHERE st.type = 'Fees'
    AND st.paid_date IS NOT NULL
    AND CAST(st.paid_date AS DATE) <> DATE '2024-05-18'
),

voyager_fees AS (
  SELECT
    'Voyager (account)'                                       AS product,
    CAST(vaf.account_fee_created_at_date AS DATE)             AS date,
    vaf.user_id,
    CAST(vaf.aud_fee_amount AS DOUBLE)                        AS fee_amount
  FROM main.spaceship.bronze_spaceship_metabase_voyager_account_fees vaf
  WHERE vaf.aud_fee_amount IS NOT NULL
),

-- Voyager management fees: pro-rated to users by balance share of portfolio NAV.
-- Balance table is weekday-only, so weekend fees fill-forward to Friday balances.
-- CRITICAL: window partitions by fee date (mf.effective_date), NOT balance date.
voyager_mgmt_fees AS (
  SELECT
    'Voyager (mgmt)'                                          AS product,
    CAST(mf.effective_date AS DATE)                           AS date,
    pb.user_id,
    CAST(mf.aud_fee_total AS DOUBLE)
      * (CAST(pb.aud_balance AS DOUBLE)
         / NULLIF(
             CASE
               WHEN CAST(mf.net_asset_value_pre_fee AS DOUBLE) > 0
               THEN CAST(mf.net_asset_value_pre_fee AS DOUBLE)
               ELSE SUM(CAST(pb.aud_balance AS DOUBLE))
                      OVER (PARTITION BY pb.portfolio, CAST(mf.effective_date AS DATE))
             END, 0))                                         AS fee_amount
  FROM main.spaceship.bronze_spaceship_metabase_voyager_management_fees mf
  INNER JOIN main.spaceship.spaceship_metabase_voyager_product_balances pb
    ON mf.portfolio = pb.portfolio
    AND pb.effective_date = (
      CASE
        WHEN DAYOFWEEK(CAST(mf.effective_date AS DATE)) = 1
          THEN DATE_ADD(CAST(mf.effective_date AS DATE), -2)  -- Sunday -> Friday
        WHEN DAYOFWEEK(CAST(mf.effective_date AS DATE)) = 7
          THEN DATE_ADD(CAST(mf.effective_date AS DATE), -1)  -- Saturday -> Friday
        ELSE CAST(mf.effective_date AS DATE)
      END
    )
  WHERE mf.aud_fee_total IS NOT NULL
    AND mf.aud_fee_total <> 0
    AND pb.aud_balance > 0
),

nova_fees AS (
  SELECT
    'Nova (platform)'                                         AS product,
    CAST(nf.coverage_start_date AS DATE)                      AS date,
    nf.user_id,
    CAST(nf.aud_net_amount AS DOUBLE)                         AS fee_amount
  FROM main.spaceship.bronze_spaceship_metabase_nova_fees nf
  WHERE nf.aud_net_amount IS NOT NULL
    AND nf.aud_net_amount <> 0
),

-- Nova FX: order_filled_at is UTC, must convert to Sydney before date extraction
nova_fx_fees AS (
  SELECT
    'Nova (FX)'                                               AS product,
    CAST(FROM_UTC_TIMESTAMP(nt.order_filled_at, 'Australia/Sydney') AS DATE) AS date,
    nt.user_id,
    CAST(nt.order_fx_aud_fee AS DOUBLE)                       AS fee_amount
  FROM main.spaceship.bronze_spaceship_metabase_nova_transactions nt
  WHERE nt.order_status = 'FINALISED'
    AND nt.order_fx_aud_fee IS NOT NULL
    AND nt.order_fx_aud_fee <> 0
),

user_gcid AS (
  SELECT DISTINCT
    c.user_id,
    sa.gcid
  FROM main.bi_db.bronze_sub_accounts_accounts sa
  INNER JOIN main.spaceship.bronze_spaceship_metabase_contact c
    ON sa.accountId = c.user_id
  WHERE sa.providerName = 'Spaceship'
    AND sa.gcid IS NOT NULL
),

aud_usd_rates AS (
  SELECT
    CAST(OccurredDate AS DATE)                                AS rate_date,
    (Ask + Bid) / 2                                           AS aud_to_usd_rate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  WHERE InstrumentID = 7
)

SELECT
  f.date,
  CAST(DATE_FORMAT(f.date, 'yyyyMMdd') AS INT)               AS date_id,
  f.product,
  f.user_id,
  g.gcid,
  ABS(SUM(f.fee_amount))                                      AS total_fees_aud,
  ABS(SUM(f.fee_amount)) * COALESCE(r.aud_to_usd_rate, 0)    AS total_fees_usd
FROM (
  SELECT product, date, user_id, fee_amount FROM super_fees
  UNION ALL
  SELECT product, date, user_id, fee_amount FROM voyager_fees
  UNION ALL
  SELECT product, date, user_id, fee_amount FROM voyager_mgmt_fees
  UNION ALL
  SELECT product, date, user_id, fee_amount FROM nova_fees
  UNION ALL
  SELECT product, date, user_id, fee_amount FROM nova_fx_fees
) f
LEFT JOIN user_gcid g
  ON f.user_id = g.user_id
LEFT JOIN aud_usd_rates r
  ON f.date = r.rate_date
GROUP BY f.date, f.product, f.user_id, g.gcid, r.aud_to_usd_rate
