-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_spaceship_mimo
-- Captured: 2026-05-18T08:14:46Z
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

contact_mapping AS (
  SELECT DISTINCT account_id, user_id
  FROM main.spaceship.bronze_spaceship_metabase_contact
  WHERE account_id IS NOT NULL
    AND user_id IS NOT NULL
),

super_mimo AS (
  SELECT
    'Super'                                                   AS product,
    FALSE                                                     AS is_internal_transfer,
    CAST(st.paid_date AS DATE)                                AS date,
    COALESCE(ua.user_id, st.member_id)                        AS user_id,
    CASE
      WHEN st.type = 'Contributions'
        OR st.description = 'Contributions Tax'
      THEN CAST(st.aud_amount AS DOUBLE)
      ELSE 0
    END                                                       AS deposit_amount,
    CASE
      WHEN st.type IN ('Benefit Payment', 'Fees', 'Tax', 'Premium')
       AND COALESCE(st.description, '') <> 'Contributions Tax'
      THEN -CAST(st.aud_amount AS DOUBLE)
      ELSE 0
    END                                                       AS withdrawal_amount,
    CASE
      WHEN st.type = 'Contributions'
        OR st.description = 'Contributions Tax'
      THEN 1 ELSE 0
    END                                                       AS is_deposit,
    CASE
      WHEN st.type IN ('Benefit Payment', 'Fees', 'Tax', 'Premium')
       AND COALESCE(st.description, '') <> 'Contributions Tax'
      THEN 1 ELSE 0
    END                                                       AS is_withdrawal
  FROM main.spaceship.bronze_spaceship_metabase_super_transactions st
  LEFT JOIN user_accounts ua
    ON st.member_id = ua.member_id
  WHERE st.paid_date IS NOT NULL
    AND CAST(st.paid_date AS DATE) <> DATE '2024-05-18'
    AND st.type IN ('Contributions', 'Benefit Payment', 'Fees', 'Tax', 'Premium')
),

money_mimo AS (
  SELECT
    'Money'                                                   AS product,
    CASE
      WHEN mt.transaction_type IN (
        'USER_DEPOSIT', 'USER_WITHDRAWAL',
        'USER_DEPOSIT_REVERSAL', 'USER_WITHDRAWAL_REVERSAL',
        'NOVA_TAF_FEE', 'NOVA_REG_FEE', 'NOVA_MONTHLY_FEE',
        'NOVA_MERGER_ACQUISITIONS', 'NOVA_DIVIDEND'
      ) THEN FALSE
      ELSE TRUE
    END                                                       AS is_internal_transfer,
    CAST(FROM_UTC_TIMESTAMP(mt.completed_at, 'Australia/Sydney') AS DATE) AS date,
    cm.user_id,
    CASE
      WHEN mt.transaction_type IN (
        'USER_DEPOSIT', 'USER_DEPOSIT_REVERSAL',
        'NOVA_DIVIDEND', 'NOVA_MERGER_ACQUISITIONS', 'NOVA_SALE',
        'VOYAGER_SALE', 'VOYAGER_DISTRIBUTION',
        'VOYAGER_DISTRIBUTION_REVERSAL', 'VOYAGER_BONUS',
        'S8_DEPOSIT'
      ) THEN CAST(mt.aud_amount AS DOUBLE)
      ELSE 0
    END                                                       AS deposit_amount,
    CASE
      WHEN mt.transaction_type IN (
        'USER_WITHDRAWAL', 'USER_WITHDRAWAL_REVERSAL',
        'NOVA_TAF_FEE', 'NOVA_REG_FEE', 'NOVA_MONTHLY_FEE',
        'NOVA_PURCHASE',
        'VOYAGER_PURCHASE', 'VOYAGER_PURCHASE_REVERSAL', 'VOYAGER_BOOST'
      ) THEN ABS(CAST(mt.aud_amount AS DOUBLE))
      ELSE 0
    END                                                       AS withdrawal_amount,
    CASE
      WHEN mt.transaction_type IN (
        'USER_DEPOSIT', 'USER_DEPOSIT_REVERSAL',
        'NOVA_DIVIDEND', 'NOVA_MERGER_ACQUISITIONS', 'NOVA_SALE',
        'VOYAGER_SALE', 'VOYAGER_DISTRIBUTION',
        'VOYAGER_DISTRIBUTION_REVERSAL', 'VOYAGER_BONUS',
        'S8_DEPOSIT'
      ) THEN 1 ELSE 0
    END                                                       AS is_deposit,
    CASE
      WHEN mt.transaction_type IN (
        'USER_WITHDRAWAL', 'USER_WITHDRAWAL_REVERSAL',
        'NOVA_TAF_FEE', 'NOVA_REG_FEE', 'NOVA_MONTHLY_FEE',
        'NOVA_PURCHASE',
        'VOYAGER_PURCHASE', 'VOYAGER_PURCHASE_REVERSAL', 'VOYAGER_BOOST'
      ) THEN 1 ELSE 0
    END                                                       AS is_withdrawal
  FROM main.spaceship.bronze_spaceship_analytics_fct_money_transactions mt
  INNER JOIN contact_mapping cm
    ON mt.account_id = cm.account_id
  WHERE mt.status NOT IN ('CANCELLED', 'FAILED', 'REJECTED')
    AND mt.transaction_direction IN ('CREDIT', 'DEBIT')
    AND mt.transaction_type IN (
      'USER_DEPOSIT', 'USER_WITHDRAWAL',
      'USER_DEPOSIT_REVERSAL', 'USER_WITHDRAWAL_REVERSAL',
      'NOVA_TAF_FEE', 'NOVA_REG_FEE', 'NOVA_MONTHLY_FEE',
      'NOVA_MERGER_ACQUISITIONS', 'NOVA_DIVIDEND',
      'VOYAGER_PURCHASE', 'VOYAGER_SALE', 'VOYAGER_BOOST',
      'VOYAGER_DISTRIBUTION', 'VOYAGER_BONUS',
      'VOYAGER_DISTRIBUTION_REVERSAL', 'VOYAGER_PURCHASE_REVERSAL',
      'NOVA_PURCHASE', 'NOVA_SALE',
      'S8_DEPOSIT'
    )
),

voyager_mimo AS (
  SELECT
    'Voyager'                                                 AS product,
    TRUE                                                      AS is_internal_transfer,
    vb.effective_date                                         AS date,
    vb.user_id,
    CAST(vb.inflow_aud_amount AS DOUBLE)                      AS deposit_amount,
    ABS(CAST(vb.outflow_aud_amount AS DOUBLE))                AS withdrawal_amount,
    CAST(vb.inflow_count AS INT)                              AS is_deposit,
    CAST(vb.outflow_count AS INT)                             AS is_withdrawal
  FROM main.spaceship.spaceship_metabase_voyager_user_balances vb
  WHERE CAST(vb.inflow_aud_amount AS DOUBLE) <> 0
     OR CAST(vb.outflow_aud_amount AS DOUBLE) <> 0
),

nova_mimo AS (
  SELECT
    'Nova'                                                    AS product,
    TRUE                                                      AS is_internal_transfer,
    CAST(FROM_UTC_TIMESTAMP(nt.order_filled_at, 'Australia/Sydney') AS DATE) AS date,
    nt.user_id,
    CASE WHEN nt.order_direction = 'BUY'
         THEN CAST(nt.order_trade_aud_amount AS DOUBLE)
         ELSE 0
    END                                                       AS deposit_amount,
    CASE WHEN nt.order_direction = 'SELL'
         THEN ABS(CAST(nt.order_trade_aud_amount AS DOUBLE))
         ELSE 0
    END                                                       AS withdrawal_amount,
    CASE WHEN nt.order_direction = 'BUY'  THEN 1 ELSE 0 END  AS is_deposit,
    CASE WHEN nt.order_direction = 'SELL' THEN 1 ELSE 0 END  AS is_withdrawal
  FROM main.spaceship.bronze_spaceship_metabase_nova_transactions nt
  WHERE nt.order_status IN ('FINALISED', 'EXECUTED', 'PAYMENT_INITIATED')
    AND nt.order_direction IN ('BUY', 'SELL')
),

mimo_aggregated AS (
  SELECT
    product,
    is_internal_transfer,
    date,
    user_id,
    SUM(deposit_amount)                                       AS total_deposits,
    SUM(withdrawal_amount)                                    AS total_withdrawals,
    SUM(deposit_amount) - SUM(withdrawal_amount)              AS net_flow,
    SUM(is_deposit)                                           AS count_deposits,
    SUM(is_withdrawal)                                        AS count_withdrawals
  FROM (
    SELECT product, is_internal_transfer, date, user_id, deposit_amount,
           withdrawal_amount, is_deposit, is_withdrawal FROM super_mimo
    UNION ALL
    SELECT product, is_internal_transfer, date, user_id, deposit_amount,
           withdrawal_amount, is_deposit, is_withdrawal FROM money_mimo
    UNION ALL
    SELECT product, is_internal_transfer, date, user_id, deposit_amount,
           withdrawal_amount, is_deposit, is_withdrawal FROM voyager_mimo
    UNION ALL
    SELECT product, is_internal_transfer, date, user_id, deposit_amount,
           withdrawal_amount, is_deposit, is_withdrawal FROM nova_mimo
  ) all_mimo
  GROUP BY product, is_internal_transfer, date, user_id
),

first_deposit_dates AS (
  SELECT
    user_id,
    first_deposit_date,
    CASE
      WHEN first_deposit_date = super_ftd  THEN 'Super'
      WHEN first_deposit_date = voyager_ftd THEN 'Voyager'
      WHEN first_deposit_date = nova_ftd   THEN 'Nova'
    END AS ftd_product
  FROM (
    SELECT
      user_id,
      COALESCE(CAST(super_first_became_financial_date AS DATE), DATE '9999-12-31')  AS super_ftd,
      COALESCE(CAST(voyager_first_became_financial_date AS DATE), DATE '9999-12-31') AS voyager_ftd,
      COALESCE(CAST(FROM_UTC_TIMESTAMP(nova_first_transaction_at, 'Australia/Sydney') AS DATE), DATE '9999-12-31') AS nova_ftd,
      LEAST(
        COALESCE(CAST(super_first_became_financial_date AS DATE), DATE '9999-12-31'),
        COALESCE(CAST(voyager_first_became_financial_date AS DATE), DATE '9999-12-31'),
        COALESCE(CAST(FROM_UTC_TIMESTAMP(nova_first_transaction_at, 'Australia/Sydney') AS DATE), DATE '9999-12-31')
      ) AS first_deposit_date
    FROM main.spaceship.bronze_spaceship_metabase_user_beta
    WHERE user_id IS NOT NULL
  )
  WHERE first_deposit_date < DATE '9999-12-31'
),

mimo_final AS (
  SELECT product, is_internal_transfer, date, user_id,
    total_deposits, total_withdrawals, net_flow,
    count_deposits, count_withdrawals,
    FALSE                                                     AS _is_orphan_ftd
  FROM mimo_aggregated

  UNION ALL

  SELECT
    f.ftd_product                                             AS product,
    CASE WHEN f.ftd_product = 'Super' THEN FALSE ELSE TRUE END AS is_internal_transfer,
    f.first_deposit_date                                      AS date,
    f.user_id,
    CAST(0 AS DOUBLE)                                         AS total_deposits,
    CAST(0 AS DOUBLE)                                         AS total_withdrawals,
    CAST(0 AS DOUBLE)                                         AS net_flow,
    0                                                         AS count_deposits,
    0                                                         AS count_withdrawals,
    TRUE                                                      AS _is_orphan_ftd
  FROM first_deposit_dates f
  LEFT JOIN mimo_aggregated m
    ON f.user_id = m.user_id AND f.first_deposit_date = m.date
  WHERE m.user_id IS NULL
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
  m.date,
  CAST(DATE_FORMAT(m.date, 'yyyyMMdd') AS INT)               AS date_id,
  m.product,
  m.is_internal_transfer,
  m.user_id,
  g.gcid,
  m.total_deposits                                            AS total_deposits_aud,
  m.total_withdrawals                                         AS total_withdrawals_aud,
  m.net_flow                                                  AS net_flow_aud,
  m.total_deposits    * COALESCE(r.aud_to_usd_rate, 0)       AS total_deposits_usd,
  m.total_withdrawals * COALESCE(r.aud_to_usd_rate, 0)       AS total_withdrawals_usd,
  m.net_flow          * COALESCE(r.aud_to_usd_rate, 0)       AS net_flow_usd,
  m.count_deposits,
  m.count_withdrawals,
  CASE
    WHEN m._is_orphan_ftd THEN TRUE
    WHEN m.date = f.first_deposit_date AND m.total_deposits > 0 THEN TRUE
    ELSE FALSE
  END                                                         AS is_ftd
FROM mimo_final m
LEFT JOIN user_gcid g
  ON m.user_id = g.user_id
LEFT JOIN first_deposit_dates f
  ON m.user_id = f.user_id
LEFT JOIN aud_usd_rates r
  ON m.date = r.rate_date
