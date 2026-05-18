# Column Lineage: main.etoro_kpi_prep.v_spaceship_mimo

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_spaceship_mimo` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_spaceship_mimo.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_spaceship_mimo.json` (rows: 15, mismatches: 15) |
| **Primary upstream** | `main.spaceship.bronze_spaceship_metabase_contact` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.spaceship.bronze_spaceship_metabase_contact` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_user_beta` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_contact` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_nova_transactions` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_super_transactions` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.spaceship.spaceship_metabase_voyager_user_balances` | JOIN / referenced | ✗ `(no wiki found)` |

## Lineage Chain

```
main.spaceship.bronze_spaceship_metabase_contact   ←── primary upstream
  + main.spaceship.bronze_spaceship_metabase_super_transactions   (JOIN)
  + main.spaceship.bronze_spaceship_analytics_fct_money_transactions   (JOIN)
  + main.spaceship.spaceship_metabase_voyager_user_balances   (JOIN)
  + main.spaceship.bronze_spaceship_metabase_nova_transactions   (JOIN)
  + main.bi_db.bronze_sub_accounts_accounts   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit   (JOIN)
  + main.spaceship.bronze_spaceship_metabase_user_beta   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_spaceship_mimo   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `date` | `—` | `date` | `join_enriched` | — | m.date |
| 2 | `date_id` | `—` | `—` | `unknown` | — | CAST(DATE_FORMAT(m.date, 'yyyyMMdd') AS INT) AS date_id |
| 3 | `product` | `—` | `product` | `join_enriched` | — | m.product |
| 4 | `is_internal_transfer` | `—` | `is_internal_transfer` | `join_enriched` | — | m.is_internal_transfer |
| 5 | `user_id` | `—` | `user_id` | `join_enriched` | — | m.user_id |
| 6 | `gcid` | `—` | `gcid` | `join_enriched` | — | g.gcid |
| 7 | `total_deposits_aud` | `—` | `total_deposits` | `join_enriched` | — | m.total_deposits AS total_deposits_aud |
| 8 | `total_withdrawals_aud` | `—` | `total_withdrawals` | `join_enriched` | — | m.total_withdrawals AS total_withdrawals_aud |
| 9 | `net_flow_aud` | `—` | `net_flow` | `join_enriched` | — | m.net_flow AS net_flow_aud |
| 10 | `total_deposits_usd` | `—` | `—` | `arithmetic` | — | m.total_deposits * COALESCE(r.aud_to_usd_rate, 0) AS total_deposits_usd |
| 11 | `total_withdrawals_usd` | `—` | `—` | `arithmetic` | — | m.total_withdrawals * COALESCE(r.aud_to_usd_rate, 0) AS total_withdrawals_usd |
| 12 | `net_flow_usd` | `—` | `—` | `arithmetic` | — | m.net_flow * COALESCE(r.aud_to_usd_rate, 0) AS net_flow_usd |
| 13 | `count_deposits` | `—` | `count_deposits` | `join_enriched` | — | m.count_deposits |
| 14 | `count_withdrawals` | `—` | `count_withdrawals` | `join_enriched` | — | m.count_withdrawals |
| 15 | `is_ftd` | `—` | `—` | `case` | — | CASE WHEN m._is_orphan_ftd THEN TRUE WHEN m.date = f.first_deposit_date AND m.total_deposits > 0 THEN TRUE ELSE FALSE END AS is_ftd |

## Cross-check vs system.access.column_lineage

- Total target columns: **15**
- OK: **0**, WARN: **0**, ERROR: **15**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `date` | — | `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.completed_at`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_filled_at`, `main.spaceship.bronze_spaceship_metabase_super_transactions.paid_date`, `main.spaceship.bronze_spaceship_metabase_user_beta.nova_first_transaction_at`, `main.spaceship.bronze_spaceship_metabase_user_beta.super_first_became_financial_date`, `main.spaceship.bronze_spaceship_metabase_user_beta.voyager_first_became_financial_date`, `main.spaceship.spaceship_metabase_voyager_user_balances.effective_date` | ERROR |
| `date_id` | — | `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.completed_at`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_filled_at`, `main.spaceship.bronze_spaceship_metabase_super_transactions.paid_date`, `main.spaceship.bronze_spaceship_metabase_user_beta.nova_first_transaction_at`, `main.spaceship.bronze_spaceship_metabase_user_beta.super_first_became_financial_date`, `main.spaceship.bronze_spaceship_metabase_user_beta.voyager_first_became_financial_date`, `main.spaceship.spaceship_metabase_voyager_user_balances.effective_date` | ERROR |
| `product` | — | `main.spaceship.bronze_spaceship_metabase_user_beta.nova_first_transaction_at`, `main.spaceship.bronze_spaceship_metabase_user_beta.super_first_became_financial_date`, `main.spaceship.bronze_spaceship_metabase_user_beta.voyager_first_became_financial_date` | ERROR |
| `is_internal_transfer` | — | `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_user_beta.nova_first_transaction_at`, `main.spaceship.bronze_spaceship_metabase_user_beta.super_first_became_financial_date`, `main.spaceship.bronze_spaceship_metabase_user_beta.voyager_first_became_financial_date` | ERROR |
| `user_id` | — | `main.spaceship.bronze_spaceship_metabase_contact.user_id`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.user_id`, `main.spaceship.bronze_spaceship_metabase_super_transactions.member_id`, `main.spaceship.bronze_spaceship_metabase_user_beta.user_id`, `main.spaceship.spaceship_metabase_voyager_user_balances.user_id` | ERROR |
| `gcid` | — | `main.bi_db.bronze_sub_accounts_accounts.gcid` | ERROR |
| `total_deposits_aud` | — | `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.aud_amount`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_direction`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_direction`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_trade_aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.description`, `main.spaceship.bronze_spaceship_metabase_super_transactions.type`, `main.spaceship.spaceship_metabase_voyager_user_balances.inflow_aud_amount` | ERROR |
| `total_withdrawals_aud` | — | `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.aud_amount`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_direction`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_direction`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_trade_aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.description`, `main.spaceship.bronze_spaceship_metabase_super_transactions.type`, `main.spaceship.spaceship_metabase_voyager_user_balances.outflow_aud_amount` | ERROR |
| `net_flow_aud` | — | `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.aud_amount`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_direction`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_direction`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_trade_aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.description`, `main.spaceship.bronze_spaceship_metabase_super_transactions.type`, `main.spaceship.spaceship_metabase_voyager_user_balances.inflow_aud_amount`, `main.spaceship.spaceship_metabase_voyager_user_balances.outflow_aud_amount` | ERROR |
| `total_deposits_usd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.aud_amount`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_direction`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_direction`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_trade_aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.description`, `main.spaceship.bronze_spaceship_metabase_super_transactions.type`, `main.spaceship.spaceship_metabase_voyager_user_balances.inflow_aud_amount` | ERROR |
| `total_withdrawals_usd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.aud_amount`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_direction`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_direction`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_trade_aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.description`, `main.spaceship.bronze_spaceship_metabase_super_transactions.type`, `main.spaceship.spaceship_metabase_voyager_user_balances.outflow_aud_amount` | ERROR |
| `net_flow_usd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.aud_amount`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_direction`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_direction`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_trade_aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.description`, `main.spaceship.bronze_spaceship_metabase_super_transactions.type`, `main.spaceship.spaceship_metabase_voyager_user_balances.inflow_aud_amount`, `main.spaceship.spaceship_metabase_voyager_user_balances.outflow_aud_amount` | ERROR |
| `count_deposits` | — | `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_direction`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_direction`, `main.spaceship.bronze_spaceship_metabase_super_transactions.description`, `main.spaceship.bronze_spaceship_metabase_super_transactions.type`, `main.spaceship.spaceship_metabase_voyager_user_balances.inflow_count` | ERROR |
| `count_withdrawals` | — | `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_direction`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_direction`, `main.spaceship.bronze_spaceship_metabase_super_transactions.description`, `main.spaceship.bronze_spaceship_metabase_super_transactions.type`, `main.spaceship.spaceship_metabase_voyager_user_balances.outflow_count` | ERROR |
| `is_ftd` | — | `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.aud_amount`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.completed_at`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_direction`, `main.spaceship.bronze_spaceship_analytics_fct_money_transactions.transaction_type`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_direction`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_filled_at`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_trade_aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.aud_amount`, `main.spaceship.bronze_spaceship_metabase_super_transactions.description`, `main.spaceship.bronze_spaceship_metabase_super_transactions.paid_date`, `main.spaceship.bronze_spaceship_metabase_super_transactions.type`, `main.spaceship.bronze_spaceship_metabase_user_beta.nova_first_transaction_at`, `main.spaceship.bronze_spaceship_metabase_user_beta.super_first_became_financial_date`, `main.spaceship.bronze_spaceship_metabase_user_beta.voyager_first_became_financial_date`, `main.spaceship.spaceship_metabase_voyager_user_balances.effective_date`, `main.spaceship.spaceship_metabase_voyager_user_balances.inflow_aud_amount` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **14**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN user_gcid AS g ON m.user_id = g.user_id
- `LEFT JOIN` — LEFT JOIN first_deposit_dates AS f ON m.user_id = f.user_id
- `LEFT JOIN` — LEFT JOIN aud_usd_rates AS r ON m.date = r.rate_date
- `LEFT JOIN` — LEFT JOIN user_accounts AS ua ON st.member_id = ua.member_id
- `INNER INNER` — INNER JOIN contact_mapping AS cm ON mt.account_id = cm.account_id
- `INNER INNER` — INNER JOIN main.spaceship.bronze_spaceship_metabase_contact AS c ON sa.accountId = c.user_id
- `LEFT JOIN` — LEFT JOIN mimo_aggregated AS m ON f.user_id = m.user_id AND f.first_deposit_date = m.date
