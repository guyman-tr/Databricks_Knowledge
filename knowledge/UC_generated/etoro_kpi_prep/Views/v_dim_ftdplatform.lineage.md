# Column Lineage: main.etoro_kpi_prep.v_dim_ftdplatform

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_dim_ftdplatform` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_dim_ftdplatform.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_dim_ftdplatform.json` (rows: 2, mismatches: 1) |
| **Primary upstream** | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | Primary (FROM) | ✓ `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md` |

## Lineage Chain

```
main.bi_db.bronze_moneybusdb_dictionary_accounttypes   ←── primary upstream
        │
        ▼
main.etoro_kpi_prep.v_dim_ftdplatform   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `FTDPlatformID` | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | `ID` | `rename` | — | ID AS FTDPlatformID |
| 2 | `Name` | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | `—` | `case` | — | CASE WHEN FTDPlatformID = 1 THEN 'TradingPlatform' WHEN FTDPlatformID = 2 THEN 'Options' WHEN FTDPlatformID = 3 THEN 'eMoney' WHEN FTDPlatfo |

## Cross-check vs system.access.column_lineage

- Total target columns: **2**
- OK: **1**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `Name` | — | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes.id`, `main.bi_db.bronze_moneybusdb_dictionary_accounttypes.name` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **1**
