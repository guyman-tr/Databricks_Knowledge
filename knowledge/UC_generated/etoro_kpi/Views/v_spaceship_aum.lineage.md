# Column Lineage: main.etoro_kpi.v_spaceship_aum

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_spaceship_aum` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\v_spaceship_aum.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\v_spaceship_aum.json` (rows: 13, mismatches: 13) |
| **Primary upstream** | `main.spaceship.bronze_spaceship_metabase_user_beta` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.spaceship.bronze_spaceship_metabase_user_beta` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_contact` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `main.spaceship.bronze_spaceship_metabase_nova_user_balances` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.spaceship.bronze_spaceship_metabase_super_user_balances` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.spaceship.bronze_spaceship_metabase_user_beta` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.spaceship.spaceship_metabase_voyager_user_balances` | JOIN / referenced | ✗ `(no wiki found)` |

## Lineage Chain

```
main.spaceship.bronze_spaceship_metabase_user_beta   ←── primary upstream
  + main.spaceship.bronze_spaceship_metabase_super_user_balances   (JOIN)
  + main.spaceship.spaceship_metabase_voyager_user_balances   (JOIN)
  + main.spaceship.bronze_spaceship_metabase_nova_user_balances   (JOIN)
  + main.bi_db.bronze_sub_accounts_accounts   (JOIN)
  + main.spaceship.bronze_spaceship_metabase_contact   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit   (JOIN)
        │
        ▼
main.etoro_kpi.v_spaceship_aum   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `date` | `main.spaceship.bronze_spaceship_metabase_contact` | `date` | `join_enriched` | — | c.date |
| 2 | `date_id` | `main.spaceship.bronze_spaceship_metabase_contact` | `—` | `unknown` | — | CAST(DATE_FORMAT(c.date, 'yyyyMMdd') AS INT) AS date_id |
| 3 | `user_id` | `main.spaceship.bronze_spaceship_metabase_contact` | `user_id` | `join_enriched` | — | c.user_id |
| 4 | `gcid` | `—` | `gcid` | `join_enriched` | — | g.gcid |
| 5 | `super_balance_aud` | `main.spaceship.bronze_spaceship_metabase_contact` | `super_balance_aud` | `join_enriched` | — | c.super_balance_aud |
| 6 | `voyager_balance_aud` | `main.spaceship.bronze_spaceship_metabase_contact` | `voyager_balance_aud` | `join_enriched` | — | c.voyager_balance_aud |
| 7 | `nova_balance_aud` | `main.spaceship.bronze_spaceship_metabase_contact` | `nova_balance_aud` | `join_enriched` | — | c.nova_balance_aud |
| 8 | `total_balance_aud` | `main.spaceship.bronze_spaceship_metabase_contact` | `—` | `arithmetic` | — | c.super_balance_aud + c.voyager_balance_aud + c.nova_balance_aud AS total_balance_aud |
| 9 | `super_balance_usd` | `main.spaceship.bronze_spaceship_metabase_contact` | `—` | `arithmetic` | — | c.super_balance_aud * COALESCE(r.aud_to_usd_rate, 0) AS super_balance_usd |
| 10 | `voyager_balance_usd` | `main.spaceship.bronze_spaceship_metabase_contact` | `—` | `arithmetic` | — | c.voyager_balance_aud * COALESCE(r.aud_to_usd_rate, 0) AS voyager_balance_usd |
| 11 | `nova_balance_usd` | `main.spaceship.bronze_spaceship_metabase_contact` | `—` | `arithmetic` | — | c.nova_balance_aud * COALESCE(r.aud_to_usd_rate, 0) AS nova_balance_usd |
| 12 | `total_balance_usd` | `main.spaceship.bronze_spaceship_metabase_contact` | `—` | `arithmetic` | — | (c.super_balance_aud + c.voyager_balance_aud + c.nova_balance_aud) * COALESCE(r.aud_to_usd_rate, 0) AS total_balance_usd |
| 13 | `is_funded` | `main.spaceship.bronze_spaceship_metabase_contact` | `—` | `case` | — | CASE WHEN (c.super_balance_aud + c.voyager_balance_aud + c.nova_balance_aud) > 0 THEN TRUE ELSE FALSE END AS is_funded |

## Cross-check vs system.access.column_lineage

- Total target columns: **13**
- OK: **0**, WARN: **5**, ERROR: **8**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `date` | `main.spaceship.bronze_spaceship_metabase_contact.date` | `main.etoro_kpi_prep.v_spaceship_aum.date`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.date`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.date`, `main.spaceship.spaceship_metabase_voyager_user_balances.effective_date` | WARN |
| `date_id` | — | `main.etoro_kpi_prep.v_spaceship_aum.date_id`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.date`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.date`, `main.spaceship.spaceship_metabase_voyager_user_balances.effective_date` | ERROR |
| `user_id` | `main.spaceship.bronze_spaceship_metabase_contact.user_id` | `main.etoro_kpi_prep.v_spaceship_aum.user_id`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.user_id`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.member_id`, `main.spaceship.bronze_spaceship_metabase_user_beta.user_id`, `main.spaceship.spaceship_metabase_voyager_user_balances.user_id` | WARN |
| `gcid` | — | `main.bi_db.bronze_sub_accounts_accounts.gcid`, `main.etoro_kpi_prep.v_spaceship_aum.gcid` | ERROR |
| `super_balance_aud` | `main.spaceship.bronze_spaceship_metabase_contact.super_balance_aud` | `main.etoro_kpi_prep.v_spaceship_aum.super_balance_aud`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.aud_balance`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`, `main.spaceship.spaceship_metabase_voyager_user_balances.aud_balance` | WARN |
| `voyager_balance_aud` | `main.spaceship.bronze_spaceship_metabase_contact.voyager_balance_aud` | `main.etoro_kpi_prep.v_spaceship_aum.voyager_balance_aud`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.aud_balance`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`, `main.spaceship.spaceship_metabase_voyager_user_balances.aud_balance` | WARN |
| `nova_balance_aud` | `main.spaceship.bronze_spaceship_metabase_contact.nova_balance_aud` | `main.etoro_kpi_prep.v_spaceship_aum.nova_balance_aud`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.aud_balance`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`, `main.spaceship.spaceship_metabase_voyager_user_balances.aud_balance` | WARN |
| `total_balance_aud` | — | `main.etoro_kpi_prep.v_spaceship_aum.total_balance_aud`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.aud_balance`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`, `main.spaceship.spaceship_metabase_voyager_user_balances.aud_balance` | ERROR |
| `super_balance_usd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid`, `main.etoro_kpi_prep.v_spaceship_aum.super_balance_usd`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.aud_balance`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`, `main.spaceship.spaceship_metabase_voyager_user_balances.aud_balance` | ERROR |
| `voyager_balance_usd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid`, `main.etoro_kpi_prep.v_spaceship_aum.voyager_balance_usd`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.aud_balance`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`, `main.spaceship.spaceship_metabase_voyager_user_balances.aud_balance` | ERROR |
| `nova_balance_usd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid`, `main.etoro_kpi_prep.v_spaceship_aum.nova_balance_usd`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.aud_balance`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`, `main.spaceship.spaceship_metabase_voyager_user_balances.aud_balance` | ERROR |
| `total_balance_usd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid`, `main.etoro_kpi_prep.v_spaceship_aum.total_balance_usd`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.aud_balance`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`, `main.spaceship.spaceship_metabase_voyager_user_balances.aud_balance` | ERROR |
| `is_funded` | — | `main.etoro_kpi_prep.v_spaceship_aum.is_funded`, `main.spaceship.bronze_spaceship_metabase_nova_user_balances.aud_balance`, `main.spaceship.bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`, `main.spaceship.spaceship_metabase_voyager_user_balances.aud_balance` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **12**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN user_gcid AS g ON c.user_id = g.user_id
- `LEFT JOIN` — LEFT JOIN aud_usd_rates AS r ON c.date = r.rate_date
- `INNER INNER` — INNER JOIN member_canonical AS mc ON ub.member_id = mc.member_id
- `LEFT JOIN` — LEFT JOIN member_canonical AS mc ON sb.member_id = mc.member_id
- `LEFT JOIN` — LEFT JOIN user_id_map AS um ON vb.user_id = um.user_id
- `LEFT JOIN` — LEFT JOIN user_id_map AS um ON nb.user_id = um.user_id
- `INNER INNER` — INNER JOIN main.spaceship.bronze_spaceship_metabase_contact AS c ON sa.accountId = c.user_id
