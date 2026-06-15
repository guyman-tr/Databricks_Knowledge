# Column Lineage: main.bi_output.bi_output_deltaapp_subscription_view

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_deltaapp_subscription_view` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_deltaapp_subscription_view.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_deltaapp_subscription_view.json` (rows: 21, mismatches: 21) |
| **Primary upstream** | `main.bi_db.bronze_deltaapp_bronze_subscriptions` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.bronze_deltaapp_bronze_subscriptions` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_deltaapp_bronze_subscriptions.md` |

## Lineage Chain

```
main.bi_db.bronze_deltaapp_bronze_subscriptions   ←── primary upstream
        │
        ▼
main.bi_output.bi_output_deltaapp_subscription_view   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `user_id` | `—` | `user_id` | `join_enriched` | — | data.user_id |
| 2 | `event_date` | `—` | `event_date` | `join_enriched` | — | data.event_date |
| 3 | `account_id` | `—` | `account_id` | `join_enriched` | — | data.account_id |
| 4 | `event_origin` | `—` | `event_origin` | `join_enriched` | — | data.event_origin |
| 5 | `event_id` | `—` | `event_id` | `join_enriched` | — | data.event_id |
| 6 | `event_type` | `—` | `event_type` | `join_enriched` | — | data.event_type |
| 7 | `event_status` | `—` | `event_status` | `join_enriched` | — | data.event_status |
| 8 | `customer_id` | `—` | `customer_id` | `join_enriched` | — | data.customer_id |
| 9 | `product_id` | `—` | `product_id` | `join_enriched` | — | data.product_id |
| 10 | `price_id` | `—` | `price_id` | `join_enriched` | — | data.price_id |
| 11 | `subscription_interval` | `—` | `subscription_interval` | `join_enriched` | — | data.subscription_interval |
| 12 | `subscription_type` | `—` | `subscription_type` | `join_enriched` | — | data.subscription_type |
| 13 | `subscription_plan_id` | `—` | `subscription_plan_id` | `join_enriched` | — | data.subscription_plan_id |
| 14 | `period_start_date` | `—` | `period_start_date` | `join_enriched` | — | data.period_start_date |
| 15 | `period_end_date` | `—` | `period_end_date` | `join_enriched` | — | data.period_end_date |
| 16 | `trial_active` | `—` | `trial_active` | `join_enriched` | — | data.trial_active |
| 17 | `payment_amount` | `—` | `payment_amount` | `join_enriched` | — | data.payment_amount |
| 18 | `payment_amount_received` | `—` | `payment_amount_received` | `join_enriched` | — | data.payment_amount_received |
| 19 | `payment_amount_refunded` | `—` | `payment_amount_refunded` | `join_enriched` | — | data.payment_amount_refunded |
| 20 | `payment_currency` | `—` | `payment_currency` | `join_enriched` | — | data.payment_currency |
| 21 | `payment_method` | `—` | `payment_method` | `join_enriched` | — | data.payment_method |

## Cross-check vs system.access.column_lineage

- Total target columns: **21**
- OK: **0**, WARN: **0**, ERROR: **21**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `user_id` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `event_date` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `account_id` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `event_origin` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `event_id` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `event_type` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `event_status` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `customer_id` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `product_id` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `price_id` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `subscription_interval` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `subscription_type` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `subscription_plan_id` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `period_start_date` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `period_end_date` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `trial_active` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `payment_amount` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `payment_amount_received` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `payment_amount_refunded` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `payment_currency` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |
| `payment_method` | — | `main.bi_db.bronze_deltaapp_bronze_subscriptions.json_text` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **21**
