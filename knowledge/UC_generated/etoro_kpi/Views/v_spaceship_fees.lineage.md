# Column Lineage: main.etoro_kpi.v_spaceship_fees

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_spaceship_fees` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\v_spaceship_fees.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\v_spaceship_fees.json` (rows: 7, mismatches: 7) |
| **Primary upstream** | `main.spaceship.bronze_spaceship_metabase_super_transactions` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.spaceship.bronze_spaceship_metabase_user_beta` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_contact` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `main.spaceship.bronze_spaceship_metabase_voyager_management_fees` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_nova_fees` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_nova_transactions` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.spaceship.spaceship_metabase_voyager_product_balances` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.spaceship.bronze_spaceship_metabase_super_transactions` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_voyager_account_fees` | JOIN / referenced | ✗ `(no wiki found)` |

## Lineage Chain

```
main.spaceship.bronze_spaceship_metabase_super_transactions   ←── primary upstream
  + main.spaceship.bronze_spaceship_metabase_voyager_account_fees   (JOIN)
  + main.spaceship.bronze_spaceship_metabase_voyager_management_fees   (JOIN)
  + main.spaceship.spaceship_metabase_voyager_product_balances   (JOIN)
  + main.spaceship.bronze_spaceship_metabase_nova_fees   (JOIN)
  + main.spaceship.bronze_spaceship_metabase_nova_transactions   (JOIN)
  + main.bi_db.bronze_sub_accounts_accounts   (JOIN)
  + main.spaceship.bronze_spaceship_metabase_contact   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit   (JOIN)
  + main.spaceship.bronze_spaceship_metabase_user_beta   (JOIN)
        │
        ▼
main.etoro_kpi.v_spaceship_fees   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `date` | `—` | `date` | `join_enriched` | — | f.date |
| 2 | `date_id` | `—` | `—` | `unknown` | — | CAST(DATE_FORMAT(f.date, 'yyyyMMdd') AS INT) AS date_id |
| 3 | `product` | `—` | `product` | `join_enriched` | — | f.product |
| 4 | `user_id` | `—` | `user_id` | `join_enriched` | — | f.user_id |
| 5 | `gcid` | `—` | `gcid` | `join_enriched` | — | g.gcid |
| 6 | `total_fees_aud` | `—` | `—` | `unknown` | — | ABS(SUM(f.fee_amount)) AS total_fees_aud |
| 7 | `total_fees_usd` | `—` | `—` | `arithmetic` | — | ABS(SUM(f.fee_amount)) * COALESCE(r.aud_to_usd_rate, 0) AS total_fees_usd |

## Cross-check vs system.access.column_lineage

- Total target columns: **7**
- OK: **0**, WARN: **0**, ERROR: **7**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `date` | — | `main.etoro_kpi_prep.v_spaceship_fees.date`, `main.spaceship.bronze_spaceship_metabase_nova_fees.coverage_start_date`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_filled_at`, `main.spaceship.bronze_spaceship_metabase_super_transactions.paid_date`, `main.spaceship.bronze_spaceship_metabase_voyager_account_fees.account_fee_created_at_date`, `main.spaceship.bronze_spaceship_metabase_voyager_management_fees.effective_date` | ERROR |
| `date_id` | — | `main.etoro_kpi_prep.v_spaceship_fees.date_id`, `main.spaceship.bronze_spaceship_metabase_nova_fees.coverage_start_date`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_filled_at`, `main.spaceship.bronze_spaceship_metabase_super_transactions.paid_date`, `main.spaceship.bronze_spaceship_metabase_voyager_account_fees.account_fee_created_at_date`, `main.spaceship.bronze_spaceship_metabase_voyager_management_fees.effective_date` | ERROR |
| `product` | — | `main.etoro_kpi_prep.v_spaceship_fees.product` | ERROR |
| `user_id` | — | `main.etoro_kpi_prep.v_spaceship_fees.user_id`, `main.spaceship.bronze_spaceship_metabase_nova_fees.user_id`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.user_id`, `main.spaceship.bronze_spaceship_metabase_super_transactions.member_id`, `main.spaceship.bronze_spaceship_metabase_user_beta.user_id`, `main.spaceship.bronze_spaceship_metabase_voyager_account_fees.user_id`, `main.spaceship.spaceship_metabase_voyager_product_balances.user_id` | ERROR |
| `gcid` | — | `main.bi_db.bronze_sub_accounts_accounts.gcid`, `main.etoro_kpi_prep.v_spaceship_fees.gcid` | ERROR |
| `total_fees_aud` | — | `main.etoro_kpi_prep.v_spaceship_fees.total_fees_aud`, `main.spaceship.bronze_spaceship_metabase_nova_fees.aud_net_amount`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_fx_aud_fee`, `main.spaceship.bronze_spaceship_metabase_super_transactions.aud_amount`, `main.spaceship.bronze_spaceship_metabase_voyager_account_fees.aud_fee_amount`, `main.spaceship.bronze_spaceship_metabase_voyager_management_fees.aud_fee_total`, `main.spaceship.bronze_spaceship_metabase_voyager_management_fees.effective_date`, `main.spaceship.bronze_spaceship_metabase_voyager_management_fees.net_asset_value_pre_fee`, `main.spaceship.spaceship_metabase_voyager_product_balances.aud_balance`, `main.spaceship.spaceship_metabase_voyager_product_balances.portfolio` | ERROR |
| `total_fees_usd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid`, `main.etoro_kpi_prep.v_spaceship_fees.total_fees_usd`, `main.spaceship.bronze_spaceship_metabase_nova_fees.aud_net_amount`, `main.spaceship.bronze_spaceship_metabase_nova_transactions.order_fx_aud_fee`, `main.spaceship.bronze_spaceship_metabase_super_transactions.aud_amount`, `main.spaceship.bronze_spaceship_metabase_voyager_account_fees.aud_fee_amount`, `main.spaceship.bronze_spaceship_metabase_voyager_management_fees.aud_fee_total`, `main.spaceship.bronze_spaceship_metabase_voyager_management_fees.effective_date`, `main.spaceship.bronze_spaceship_metabase_voyager_management_fees.net_asset_value_pre_fee`, `main.spaceship.spaceship_metabase_voyager_product_balances.aud_balance`, `main.spaceship.spaceship_metabase_voyager_product_balances.portfolio` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **5**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN user_gcid AS g ON f.user_id = g.user_id
- `LEFT JOIN` — LEFT JOIN aud_usd_rates AS r ON f.date = r.rate_date
- `LEFT JOIN` — LEFT JOIN user_accounts AS ua ON st.member_id = ua.member_id
- `INNER INNER` — INNER JOIN main.spaceship.spaceship_metabase_voyager_product_balances AS pb ON mf.portfolio = pb.portfolio AND pb.effective_date = (CASE WHEN DAYOFWEEK(CAST(mf.effective_date AS DATE)) = 1 THEN DATE_ADD(CAST(mf.effective_date AS DATE), -2) 
- `INNER INNER` — INNER JOIN main.spaceship.bronze_spaceship_metabase_contact AS c ON sa.accountId = c.user_id
