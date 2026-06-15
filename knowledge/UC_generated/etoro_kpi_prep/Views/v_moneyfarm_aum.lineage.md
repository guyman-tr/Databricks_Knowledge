# Column Lineage: main.etoro_kpi_prep.v_moneyfarm_aum

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_moneyfarm_aum` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_moneyfarm_aum.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_moneyfarm_aum.json` (rows: 7, mismatches: 7) |
| **Primary upstream** | `main.money_farm.silver_moneyfarm_etoro_mf_aum` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `main.money_farm.silver_moneyfarm_etoro_mf_aum` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.money_farm.silver_moneyfarm_etoro_mf_aum   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_moneyfarm_aum   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `date` | `—` | `date` | `join_enriched` | — | a.date |
| 2 | `dateid` | `—` | `—` | `unknown` | — | CAST(DATE_FORMAT(a.date, 'yyyyMMdd') AS INT) AS dateid |
| 3 | `gcid` | `—` | `GCID` | `join_enriched` | — | a.GCID AS gcid |
| 4 | `total_balance_gbp` | `—` | `total_balance_gbp` | `join_enriched` | — | a.total_balance_gbp |
| 5 | `total_balance_usd` | `—` | `—` | `arithmetic` | — | a.total_balance_gbp * COALESCE(r.gbp_to_usd_rate, 0) AS total_balance_usd |
| 6 | `is_funded` | `—` | `—` | `case` | — | CASE WHEN a.total_balance_gbp > 0 THEN TRUE ELSE FALSE END AS is_funded |
| 7 | `portfolio_count` | `—` | `portfolio_count` | `join_enriched` | — | a.portfolio_count |

## Cross-check vs system.access.column_lineage

- Total target columns: **7**
- OK: **0**, WARN: **0**, ERROR: **7**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `date` | — | `main.money_farm.silver_moneyfarm_etoro_mf_aum.etr_ymd` | ERROR |
| `dateid` | — | `main.money_farm.silver_moneyfarm_etoro_mf_aum.etr_ymd` | ERROR |
| `gcid` | — | `main.money_farm.silver_moneyfarm_etoro_mf_aum.gcid` | ERROR |
| `total_balance_gbp` | — | `main.money_farm.silver_moneyfarm_etoro_mf_aum.market_value` | ERROR |
| `total_balance_usd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid`, `main.money_farm.silver_moneyfarm_etoro_mf_aum.market_value` | ERROR |
| `is_funded` | — | `main.money_farm.silver_moneyfarm_etoro_mf_aum.market_value` | ERROR |
| `portfolio_count` | — | `main.money_farm.silver_moneyfarm_etoro_mf_aum.portfolio_id` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **6**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN gbp_usd_rates AS r ON a.date = r.rate_date
