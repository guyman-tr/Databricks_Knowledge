# Column Lineage: main.bi_output.bi_ouput_v_dim_instrumenttype

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_ouput_v_dim_instrumenttype` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_ouput_v_dim_instrumenttype.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_ouput_v_dim_instrumenttype.json` (rows: 2, mismatches: 1) |
| **Primary upstream** | `main.general.bronze_etoro_dictionary_currencytype` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_dictionary_currencytype` | Primary (FROM) | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CurrencyType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

## Lineage Chain

```
main.general.bronze_etoro_dictionary_currencytype   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
        │
        ▼
main.bi_output.bi_ouput_v_dim_instrumenttype   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `InstrumentTypeID` | `main.general.bronze_etoro_dictionary_currencytype` | `CurrencyTypeID` | `rename` | — | ct.CurrencyTypeID AS InstrumentTypeID |
| 2 | `InstrumentType` | `main.general.bronze_etoro_dictionary_currencytype` | `—` | `coalesce` | — | COALESCE(di.InstrumentType, ct.Name) AS InstrumentType |

## Cross-check vs system.access.column_lineage

- Total target columns: **2**
- OK: **1**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `InstrumentType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttype`, `main.general.bronze_etoro_dictionary_currencytype.name` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **0**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN (SELECT DISTINCT InstrumentTypeID, InstrumentType FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument) AS di ON ct.CurrencyTypeID = di.InstrumentTypeID
