# EXW_dbo.EXW_SimplexMapping — Column Lineage

**Generated**: 2026-04-20  
**Object**: EXW_dbo.EXW_SimplexMapping  
**Type**: Table  
**Production Source**: Simplex external payment provider API (external feed — not in DB_Schema)  
**ETL Mechanism**: External pipeline (Fivetran or equivalent) — no SSDT-managed SP

---

## ETL Pipeline

```
Simplex Payment Provider API (external)
  |-- External pipeline (Fivetran / ADF) ---|
  v
EXW_dbo.EXW_SimplexMapping (103K rows, frozen 2022-09-19)
  |-- No UC Generic Pipeline mapping found ---|
  v
UC Target: _Not_Migrated (no mapping in bronze_opsdb_dbo_vw_unitycatalog_mapping_tables)
```

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|------------|-------------|---------------|-----------|------|
| 1 | partner | Simplex API | partner | Passthrough | Tier 4 |
| 2 | processed_at_utc | Simplex API | processed_at_utc | Passthrough (stored as nvarchar) | Tier 4 |
| 3 | country | Simplex API | country | Passthrough | Tier 4 |
| 4 | currency | Simplex API | currency | Passthrough (fiat currency code) | Tier 4 |
| 5 | total_amount_usd | Simplex API | total_amount_usd | Passthrough | Tier 4 |
| 6 | crypto_currency | Simplex API | crypto_currency | Passthrough | Tier 4 |
| 7 | total_amount | Simplex API | total_amount | Passthrough (amount in fiat currency) | Tier 4 |
| 8 | long_id | Simplex API | long_id | Passthrough (Simplex internal transaction GUID) | Tier 4 |
| 9 | uti | Simplex API | uti | Passthrough (Unique Transaction Identifier) | Tier 4 |
| 10 | status | Simplex API | status | Passthrough | Tier 4 |
| 11 | UpdateDate | ETL | — | ETL-managed load timestamp | Tier 2 |
| 12 | reason | Simplex API | reason | Passthrough (cancellation/decline reason) | Tier 4 |
| 13 | stage_drop | Simplex API | stage_drop | Passthrough (funnel stage where transaction ended) | Tier 4 |
| 14 | bank_further_reason | Simplex API | bank_further_reason | Passthrough (bank decline message) | Tier 4 |
| 15 | card_debit_or_credit | Simplex API | card_debit_or_credit | Passthrough (noisy — contains system messages) | Tier 4 |
| 16 | bin_country | Simplex API | bin_country | Passthrough (issuing bank country) | Tier 4 |
| 17 | bank_name | Simplex API | bank_name | Passthrough (issuing bank name) | Tier 4 |
| 18 | last_4_digits | Simplex API | last_4_digits | Passthrough (card last 4 digits, stored as nvarchar) | Tier 4 |

---

## Notes

- **No upstream DB_Schema wiki** — Simplex is a third-party payment provider not modeled in DB_Schema repos
- **Table appears frozen** — processed_at_utc max = 2022-09-19; UpdateDate max = 2024-04-09 (last ETL sync). Simplex as primary crypto buy provider was replaced/discontinued around late 2022
- **card_debit_or_credit data quality issue** — contains mixed values: proper types (DEBIT, CREDIT), system error messages (card bin is blacklisted!), and network names (VISA, MASTERCARD)
- All columns Tier 4 except UpdateDate (Tier 2 ETL timestamp)
