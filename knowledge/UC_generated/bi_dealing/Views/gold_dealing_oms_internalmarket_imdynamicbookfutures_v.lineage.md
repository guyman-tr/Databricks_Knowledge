# Column Lineage: main.bi_dealing.gold_dealing_oms_internalmarket_imdynamicbookfutures_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.gold_dealing_oms_internalmarket_imdynamicbookfutures_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\gold_dealing_oms_internalmarket_imdynamicbookfutures_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\gold_dealing_oms_internalmarket_imdynamicbookfutures_v.json` (rows: 0, mismatches: 0) |
| **Primary upstream** | `main.bi_dealing.gold_dealing_oms_internalmarket_parameters` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.bi_dealing.gold_dealing_oms_internalmarket_parameters` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_oms_internalmarket_parameters.md` |
| `main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates` | JOIN / referenced | ✗ `(no wiki found)` |

## Lineage Chain

```
main.bi_dealing.gold_dealing_oms_internalmarket_parameters   ←── primary upstream
  + main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
        │
        ▼
main.bi_dealing.gold_dealing_oms_internalmarket_imdynamicbookfutures_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `InstrumentID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `Model` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `ModelParameter` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `Value` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `UpdateTime` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `ModelVersion` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `URL` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `OmsParam` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `etr_ymd` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |

## Cross-check vs system.access.column_lineage

- Total target columns: **0**
- OK: **0**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**

## Joins (detected)

- `INNER JOIN` — JOIN valid_parameters AS bb USING (InstrumentID)
- `INNER JOIN` — JOIN valid_instruments AS la ON mp.LiquidityAccountID = la.LiquidityAccountID AND mp.InstrumentID = la.InstrumentID AND mp.receivedtime BETWEEN DATE_ADD(MINUTE, -la.window_size_minutes, CURRENT_TIMESTAMP()) AND CURRENT_TIMESTAMP()
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di USING (InstrumentID)
