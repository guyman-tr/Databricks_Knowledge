# BI_DB_dbo.External_Cmrdb_FxRate

> Daily cross-currency exchange rate matrix sourced from the external CMR-DB system. One row per (DomesticCurrency, ForeignCurrency, ExchangeDate) combination — for any of ~30 supported foreign currencies, the rate is expressed in 4 domestic-currency views (USD, EUR, GBP, AUD) so a fact table denominated in any of those bases can convert directly without a triangular join. Loaded daily; `IsOld` flags superseded rows.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (External-prefixed naming convention — sourced from the CMR-DB system upstream) |
| **Production Source** | CMR-DB FX rate service (external to eToro DWH) |
| **Refresh** | Daily — new rows appended per ExchangeDate; `IsOld` flag marks any superseded rate |
| **Grain** | One row per (DomesticCurrencyCode, ForeignCurrencyCode, ExchangeDate) |
| | |
| **Synapse Distribution** | (typically REPLICATE for FX dim — small) |
| **Synapse Index** | CLUSTERED on Id |
| | |
| **UC Target** | `finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (generic pipeline) |

---

## 1. Business Meaning

`External_Cmrdb_FxRate` is the canonical **daily FX rate dimension** used to convert customer-currency amounts into eToro reporting currencies (USD, EUR, GBP, AUD). It comes from the CMR-DB system (Compliance/Regulatory FX service) and is NOT the same as the legacy `Dim_Currency` rate snapshot — this table is structured for direct join from a dual-currency fact, providing a row for every (domestic, foreign, date) tuple.

Key access pattern:

```sql
fact.Amount_in_LocalCurr × fx.ExchangeRate ⇒ fact.Amount_in_USD
```

The 4 supported domestic currencies (USD, EUR, GBP, AUD) cover all eToro regulatory entities (US Apex, CySEC EUR, FCA GBP, ASIC AUD). Same-day all-pairs availability means a USD-denominated fact and a GBP-denominated fact can convert without a separate USD-GBP triangulation step.

`IsOld` indicates that a newer rate exists for the same (domestic, foreign, date) tuple — usually because of an intra-day correction. **For reporting, always filter `WHERE IsOld = FALSE`** to use the latest rate. Two-column PII-style audit trail (`AddedBy`, `UpdatedBy`) records who last touched the row.

`CrossExchangeRate` and `ExchangeQuantity` are denominator-control fields:
- `ExchangeQuantity` is typically 1 — meaning the rate is per-unit. For currencies with very small unit values it may be 100 or 1000.
- `CrossExchangeRate` is the cross-rate (foreign × foreign) computed indirectly through a base currency.

---

## 2. Query Advisory

### 2.1 Common Patterns

| Question | Approach |
|----------|----------|
| Convert customer EUR amount → USD on a given day | `JOIN ... ON fx.DomesticCurrencyCode = 'USD' AND fx.ForeignCurrencyCode = 'EUR' AND fx.ExchangeDate = fact.Day AND fx.IsOld = 0` |
| Latest rate available | `SELECT TOP 1 ... ORDER BY ExchangeDate DESC, IsOld ASC` |
| Daily rate matrix sanity check | Expect each (domestic, foreign) pair × 1 row per `ExchangeDate` (when `IsOld = 0`) |

### 2.2 Gotchas

- **Always filter `IsOld = 0`** unless you specifically want the audit trail.
- **Same-currency rows exist** (e.g., AUD→AUD, USD→USD with rate=1). Don't double-convert.
- **`ExchangeQuantity` matters** — the formula is `amount × ExchangeRate / ExchangeQuantity`. For currencies where it's 1, this drops out; for the few where it isn't, missing this gives a 100× error.
- **`CrossExchangeRate` vs `ExchangeRate`**: prefer `ExchangeRate` for direct domestic↔foreign conversion. `CrossExchangeRate` is for indirect / triangulated conversions.
- **Grain duplicates**: with `IsOld = 1` rows present, a naive `JOIN` will multiply rows. Always filter or use `MAX(Id)` per (domestic, foreign, date) tuple.

---

## 3. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 1 | DDL + UC sample (12 rows for 2026-05-07 verified) |
| ** | Tier 2 | Inferred from CMR-DB FX-service convention |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Surrogate primary key — append-only sequence assigned on insert. Use to order/dedupe within a (domestic, foreign, date) tuple. (Tier 1 — DDL) |
| 2 | DomesticCurrencyCode | nvarchar | YES | ISO-4217 code of the **destination** (reporting) currency: USD, EUR, GBP, or AUD. (Tier 1 — UC sample) |
| 3 | ForeignCurrencyCode | nvarchar | YES | ISO-4217 code of the **source** (customer/local) currency. ~30 codes covered (AED, AUD, CAD, USD, EUR, GBP, ...). (Tier 1 — UC sample) |
| 4 | ForeignCurrencyName | nvarchar | YES | Human-readable name of the foreign currency (e.g. `'Australian Dollar'`, `'Canadian Dollar'`). May equal the code itself if no display name was provided in CMR-DB. (Tier 1 — UC sample) |
| 5 | ForeignCurrencyName2 | nvarchar | YES | Secondary / alternate display name for the foreign currency, populated from CMR-DB when an alternate localization exists. Often NULL. (Tier 2 — convention) |
| 6 | ExchangeRate | numeric(38,16) | YES | Conversion rate: 1 unit of ForeignCurrency = ExchangeRate units of DomesticCurrency, divided by ExchangeQuantity. Apply as `amount_in_foreign × ExchangeRate / ExchangeQuantity`. (Tier 1 — UC sample) |
| 7 | ExchangeQuantity | numeric(38,16) | YES | Denominator for the rate; typically 1 (rate is per-unit). For low-unit currencies CMR-DB may publish per-100 or per-1000 rates — divide by ExchangeQuantity to get the per-unit factor. (Tier 1 — DDL + convention) |
| 8 | ExchangeDate | date | YES | The business date this rate applies to. One rate (post-`IsOld` filter) per (domestic, foreign, date) tuple. (Tier 1 — UC sample) |
| 9 | IsOld | bit | YES | TRUE if a newer rate has superseded this row for the same (domestic, foreign, date) tuple. Filter `IsOld = FALSE` for reporting; keep TRUE rows for audit. (Tier 1 — DDL + convention) |
| 10 | AddedDate | datetime2(7) | YES | Timestamp when the rate was first inserted into CMR-DB. (Tier 1 — DDL) |
| 11 | AddedBy | nvarchar | YES | User/system that inserted the row in CMR-DB. Often empty when system-driven. (Tier 1 — UC sample) |
| 12 | UpdatedDate | datetime2(7) | YES | Timestamp when the rate was last updated in CMR-DB. NULL when the row has never been edited post-insert. (Tier 1 — DDL) |
| 13 | UpdatedBy | nvarchar | YES | User/system that last edited the row in CMR-DB. Often empty. (Tier 1 — DDL) |
| 14 | CrossExchangeRate | numeric(38,16) | YES | Cross-currency rate computed indirectly through a base currency (e.g. EUR↔AUD via USD). For direct domestic↔foreign conversion, prefer `ExchangeRate`; use `CrossExchangeRate` only for triangulated/derived calculations. (Tier 2 — name-inferred + CMR-DB convention) |

---

## 4. Lineage

### 4.1 Production Source

```
CMR-DB FX rate service (external) → daily ETL → BI_DB_dbo.External_Cmrdb_FxRate
                                              ↓ Generic Pipeline (gold export)
                  main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate
```

### 4.2 Refresh

Daily. Each business day, CMR-DB publishes a new set of (domestic, foreign) rates dated for that day. Intraday corrections set `IsOld = 1` on the prior version and append a new row.

---

## 5. Relationships

### 5.1 References To

`DomesticCurrencyCode` and `ForeignCurrencyCode` reference `Dim_Currency.CurrencyCode` (no enforced FK — CMR-DB and DWH `Dim_Currency` are aligned by ISO code).

### 5.2 Referenced By

Used by any cross-currency revenue / amount rollup that needs to convert between customer currency and reporting currency. Common joins from Deposits, Withdrawals, MIMO, and Trade fact tables.

---

## 6. Sample Queries

### 6.1 Today's USD-base rate matrix

```sql
SELECT ForeignCurrencyCode, ForeignCurrencyName, ExchangeRate, ExchangeQuantity
FROM   main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate
WHERE  DomesticCurrencyCode = 'USD'
  AND  ExchangeDate = CURRENT_DATE
  AND  IsOld = FALSE
ORDER  BY ForeignCurrencyCode
```

### 6.2 Convert EUR amount on its day to USD

```sql
SELECT f.CID, f.Amount_EUR, f.Day, f.Amount_EUR * fx.ExchangeRate / fx.ExchangeQuantity AS Amount_USD
FROM   <fact_eur> f
JOIN   main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate fx
  ON   fx.DomesticCurrencyCode = 'USD'
  AND  fx.ForeignCurrencyCode  = 'EUR'
  AND  fx.ExchangeDate         = f.Day
  AND  fx.IsOld                = FALSE
```

---

*Generated: 2026-05-07 | Wave 2 systematic NO_WIKI fill-in*
*Source: DDL + UC sample 2026-05-07 (12 rows, 4 domestic × multiple foreign)*
*Object: BI_DB_dbo.External_Cmrdb_FxRate | Type: External-prefixed table | Production: CMR-DB FX service*
