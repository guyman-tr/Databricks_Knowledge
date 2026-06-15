# Column Lineage: main.bi_output.negative_nmi

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.negative_nmi` |
| **Object Type** | `MATERIALIZED_VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\negative_nmi.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\negative_nmi.json` (rows: 5, mismatches: 5) |
| **Primary upstream** | `main.general.bronze_etoro_history_credit` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_history_credit` | Primary (FROM) | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md` |
| `main.trading.bronze_etoro_history_position_datafactory` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Position_DataFactory.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.trading.silver_etoro_trade_position` | JOIN / referenced | ✗ `(no wiki found)` |

## Lineage Chain

```
main.general.bronze_etoro_history_credit   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.trading.bronze_etoro_history_position_datafactory   (JOIN)
  + main.trading.silver_etoro_trade_position   (JOIN)
        │
        ▼
main.bi_output.negative_nmi   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `SymbolFull` | `main.general.bronze_etoro_history_credit` | `SymbolFull` | `passthrough` | — | SymbolFull |
| 2 | `InstrumentDisplayName` | `main.general.bronze_etoro_history_credit` | `InstrumentDisplayName` | `passthrough` | — | InstrumentDisplayName |
| 3 | `MoneyIn` | `main.general.bronze_etoro_history_credit` | `MoneyIn` | `cast` | — | cast to DECIMAL(12, 2) — CAST(MoneyIn AS DECIMAL(12, 2)) AS MoneyIn |
| 4 | `MoneyOut` | `main.general.bronze_etoro_history_credit` | `MoneyOut` | `cast` | — | cast to DECIMAL(12, 2) — CAST(MoneyOut AS DECIMAL(12, 2)) AS MoneyOut |
| 5 | `NetMoneyIn` | `main.general.bronze_etoro_history_credit` | `—` | `unknown` | — | CAST((MoneyIn + MoneyOut) AS DECIMAL(12, 2)) AS NetMoneyIn |

## Cross-check vs system.access.column_lineage

- Total target columns: **5**
- OK: **0**, WARN: **4**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `SymbolFull` | `main.general.bronze_etoro_history_credit.symbolfull` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.symbolfull` | WARN |
| `InstrumentDisplayName` | `main.general.bronze_etoro_history_credit.instrumentdisplayname` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumentdisplayname` | WARN |
| `MoneyIn` | `main.general.bronze_etoro_history_credit.moneyin` | `main.general.bronze_etoro_history_credit.credittypeid`, `main.general.bronze_etoro_history_credit.payment` | WARN |
| `MoneyOut` | `main.general.bronze_etoro_history_credit.moneyout` | `main.general.bronze_etoro_history_credit.credittypeid`, `main.general.bronze_etoro_history_credit.payment` | WARN |
| `NetMoneyIn` | — | `main.general.bronze_etoro_history_credit.credittypeid`, `main.general.bronze_etoro_history_credit.payment` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `INNER JOIN` — JOIN (SELECT PositionID, InstrumentID FROM main.trading.bronze_etoro_history_position_datafactory AS hp WHERE etr_ymd >= CURRENT_DATE UNION ALL SELECT PositionID, InstrumentID FROM main.trading.silver_etoro_trade_position AS tp WHERE tp.Occ
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS imd ON P0.InstrumentID = imd.InstrumentID
