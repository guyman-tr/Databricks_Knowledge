# Column Lineage: main.etoro_kpi_prep.v_moneyfarm_mimo

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_moneyfarm_mimo` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_moneyfarm_mimo.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_moneyfarm_mimo.json` (rows: 12, mismatches: 12) |
| **Primary upstream** | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |

## Lineage Chain

```
main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_moneyfarm_mimo   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `date` | `—` | `date` | `join_enriched` | — | m.date |
| 2 | `dateid` | `—` | `—` | `unknown` | — | CAST(DATE_FORMAT(m.date, 'yyyyMMdd') AS INT) AS dateid |
| 3 | `gcid` | `—` | `GCID` | `join_enriched` | — | m.GCID AS gcid |
| 4 | `total_deposits_gbp` | `—` | `total_deposits` | `join_enriched` | — | m.total_deposits AS total_deposits_gbp |
| 5 | `total_withdrawals_gbp` | `—` | `total_withdrawals` | `join_enriched` | — | m.total_withdrawals AS total_withdrawals_gbp |
| 6 | `net_flow_gbp` | `—` | `—` | `arithmetic` | — | m.total_deposits - m.total_withdrawals AS net_flow_gbp |
| 7 | `total_deposits_usd` | `—` | `—` | `arithmetic` | — | m.total_deposits * COALESCE(r.gbp_to_usd_rate, 0) AS total_deposits_usd |
| 8 | `total_withdrawals_usd` | `—` | `—` | `arithmetic` | — | m.total_withdrawals * COALESCE(r.gbp_to_usd_rate, 0) AS total_withdrawals_usd |
| 9 | `net_flow_usd` | `—` | `—` | `arithmetic` | — | (m.total_deposits - m.total_withdrawals) * COALESCE(r.gbp_to_usd_rate, 0) AS net_flow_usd |
| 10 | `count_deposits` | `—` | `count_deposits` | `join_enriched` | — | m.count_deposits |
| 11 | `count_withdrawals` | `—` | `count_withdrawals` | `join_enriched` | — | m.count_withdrawals |
| 12 | `is_ftd` | `—` | `—` | `case` | — | CASE WHEN m.date = f.first_deposit_date AND m.total_deposits > 0 THEN TRUE ELSE FALSE END AS is_ftd |

## Cross-check vs system.access.column_lineage

- Total target columns: **12**
- OK: **0**, WARN: **0**, ERROR: **12**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `date` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata` | ERROR |
| `dateid` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata` | ERROR |
| `gcid` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata` | ERROR |
| `total_deposits_gbp` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata` | ERROR |
| `total_withdrawals_gbp` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata` | ERROR |
| `net_flow_gbp` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata` | ERROR |
| `total_deposits_usd` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid` | ERROR |
| `total_withdrawals_usd` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid` | ERROR |
| `net_flow_usd` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid` | ERROR |
| `count_deposits` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata` | ERROR |
| `count_withdrawals` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata` | ERROR |
| `is_ftd` | — | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.eventpayloadrowdata` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **11**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN first_deposit_dates AS f ON m.GCID = f.GCID
- `LEFT JOIN` — LEFT JOIN gbp_usd_rates AS r ON m.date = r.rate_date
