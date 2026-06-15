-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.v_spaceship_aum
-- Captured: 2026-05-19T15:18:11Z
-- ==========================================================================

WITH member_canonical AS (
  SELECT member_id, user_id AS canonical_user_id
  FROM (
    SELECT member_id, user_id,
      ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY user_id) AS rn
    FROM main.spaceship.bronze_spaceship_metabase_user_beta
    WHERE member_id IS NOT NULL
  )
  WHERE rn = 1
),

user_id_map AS (
  SELECT DISTINCT
    ub.user_id,
    mc.canonical_user_id
  FROM main.spaceship.bronze_spaceship_metabase_user_beta ub
  INNER JOIN member_canonical mc ON ub.member_id = mc.member_id
  WHERE ub.member_id IS NOT NULL
),

-- Super: weekday-only source, fill forward last weekday to Sat + Sun
super_bal_raw AS (
  SELECT
    CAST(sb.date AS DATE)                                     AS date,
    COALESCE(mc.canonical_user_id, sb.member_id)              AS user_id,
    CAST(sb.super_closing_aud_balance AS DOUBLE)              AS balance_aud
  FROM main.spaceship.bronze_spaceship_metabase_super_user_balances sb
  LEFT JOIN member_canonical mc ON sb.member_id = mc.member_id
),

super_last_weekday AS (
  SELECT date, user_id, balance_aud,
    NEXT_DAY(date, 'SA')              AS fill_sat,
    DATE_ADD(NEXT_DAY(date, 'SA'), 1) AS fill_sun
  FROM (
    SELECT date, user_id, balance_aud,
      ROW_NUMBER() OVER (
        PARTITION BY user_id, DATE_TRUNC('week', date)
        ORDER BY date DESC
      ) AS rn
    FROM super_bal_raw
    WHERE DAYOFWEEK(date) BETWEEN 2 AND 6
  ) WHERE rn = 1
),

super_bal AS (
  SELECT date, user_id, balance_aud
  FROM (
    SELECT date, user_id, balance_aud, 1 AS priority FROM super_bal_raw
    UNION ALL
    SELECT fill_sat,  user_id, balance_aud, 2 FROM super_last_weekday
    UNION ALL
    SELECT fill_sun,  user_id, balance_aud, 2 FROM super_last_weekday
  )
  QUALIFY ROW_NUMBER() OVER (PARTITION BY date, user_id ORDER BY priority) = 1
),

-- Voyager: same weekday-only fill-forward pattern
voyager_bal_raw AS (
  SELECT
    vb.effective_date                                         AS date,
    COALESCE(um.canonical_user_id, vb.user_id)                AS user_id,
    CAST(vb.aud_balance AS DOUBLE)                            AS balance_aud
  FROM main.spaceship.spaceship_metabase_voyager_user_balances vb
  LEFT JOIN user_id_map um ON vb.user_id = um.user_id
),

voyager_last_weekday AS (
  SELECT date, user_id, balance_aud,
    NEXT_DAY(date, 'SA')              AS fill_sat,
    DATE_ADD(NEXT_DAY(date, 'SA'), 1) AS fill_sun
  FROM (
    SELECT date, user_id, balance_aud,
      ROW_NUMBER() OVER (
        PARTITION BY user_id, DATE_TRUNC('week', date)
        ORDER BY date DESC
      ) AS rn
    FROM voyager_bal_raw
    WHERE DAYOFWEEK(date) BETWEEN 2 AND 6
  ) WHERE rn = 1
),

voyager_bal AS (
  SELECT date, user_id, balance_aud
  FROM (
    SELECT date, user_id, balance_aud, 1 AS priority FROM voyager_bal_raw
    UNION ALL
    SELECT fill_sat,  user_id, balance_aud, 2 FROM voyager_last_weekday
    UNION ALL
    SELECT fill_sun,  user_id, balance_aud, 2 FROM voyager_last_weekday
  )
  QUALIFY ROW_NUMBER() OVER (PARTITION BY date, user_id ORDER BY priority) = 1
),

-- Nova: 7-day data, no fill needed
nova_bal AS (
  SELECT
    CAST(nb.date AS DATE)                                     AS date,
    COALESCE(um.canonical_user_id, nb.user_id)                AS user_id,
    CAST(nb.aud_balance AS DOUBLE)                            AS balance_aud
  FROM main.spaceship.bronze_spaceship_metabase_nova_user_balances nb
  LEFT JOIN user_id_map um ON nb.user_id = um.user_id
),

combined AS (
  SELECT date, user_id,
    SUM(CASE WHEN src = 'S' THEN balance_aud ELSE 0 END)     AS super_balance_aud,
    SUM(CASE WHEN src = 'V' THEN balance_aud ELSE 0 END)     AS voyager_balance_aud,
    SUM(CASE WHEN src = 'N' THEN balance_aud ELSE 0 END)     AS nova_balance_aud
  FROM (
    SELECT date, user_id, balance_aud, 'S' AS src FROM super_bal
    UNION ALL
    SELECT date, user_id, balance_aud, 'V' AS src FROM voyager_bal
    UNION ALL
    SELECT date, user_id, balance_aud, 'N' AS src FROM nova_bal
  ) all_bal
  GROUP BY date, user_id
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
  c.date,
  CAST(DATE_FORMAT(c.date, 'yyyyMMdd') AS INT)               AS date_id,
  c.user_id,
  g.gcid,
  c.super_balance_aud,
  c.voyager_balance_aud,
  c.nova_balance_aud,
  c.super_balance_aud + c.voyager_balance_aud
    + c.nova_balance_aud                                      AS total_balance_aud,
  c.super_balance_aud   * COALESCE(r.aud_to_usd_rate, 0)     AS super_balance_usd,
  c.voyager_balance_aud * COALESCE(r.aud_to_usd_rate, 0)     AS voyager_balance_usd,
  c.nova_balance_aud    * COALESCE(r.aud_to_usd_rate, 0)     AS nova_balance_usd,
  (c.super_balance_aud + c.voyager_balance_aud
    + c.nova_balance_aud) * COALESCE(r.aud_to_usd_rate, 0)   AS total_balance_usd,
  CASE
    WHEN (c.super_balance_aud + c.voyager_balance_aud
          + c.nova_balance_aud) > 0
    THEN TRUE ELSE FALSE
  END                                                         AS is_funded
FROM combined c
LEFT JOIN user_gcid g
  ON c.user_id = g.user_id
LEFT JOIN aud_usd_rates r
  ON c.date = r.rate_date
