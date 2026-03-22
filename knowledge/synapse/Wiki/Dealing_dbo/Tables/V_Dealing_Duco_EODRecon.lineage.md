# Lineage Map — Dealing_dbo.V_Dealing_Duco_EODRecon

**Generated**: 2026-03-21
**Type**: View — thin filter wrapper with DISTINCT dedup and column alias
**Pattern**: SELECT DISTINCT *, [Buy/Sell] AS BuyOrSell FROM base table WHERE Date >= '2023-01-01'

## ETL Chain

```
Dealing_dbo.Dealing_Duco_EODRecon (NOLOCK)
  WHERE Date >= '2023-01-01'
  + DISTINCT deduplication
  + [Buy/Sell] aliased as BuyOrSell (SQL-safe column name)
        └── Dealing_dbo.V_Dealing_Duco_EODRecon
```

## Column Lineage

All columns pass through unchanged from `Dealing_dbo.Dealing_Duco_EODRecon`, plus:

| View Column | Source | Transform |
|-------------|--------|-----------|
| All base columns | Dealing_Duco_EODRecon | Direct passthrough |
| `BuyOrSell` | `Dealing_Duco_EODRecon.[Buy/Sell]` | Alias — makes the bracketed column name SQL-safe without brackets |

See [Dealing_Duco_EODRecon.md](Dealing_Duco_EODRecon.md) for full column definitions.

## Governance

- **No ETL / No writer**: This is a view — data is always read live from the base table
- **Fixed cutoff**: Date >= '2023-01-01' — hardcoded static date, not rolling
- **DISTINCT**: Removes any duplicate rows from the base table (defensive dedup)
- **BuyOrSell alias**: The base table column `[Buy/Sell]` contains a forward-slash which requires bracket quoting; this view surfaces it as `BuyOrSell` for easier consumption
- **NOLOCK hint**: May return uncommitted data; suitable for read-heavy dashboards
- **No OpsDB entry**: Views are not tracked in Service Broker orchestration
