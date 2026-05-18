# Column Lineage: main.etoro_kpi_prep.v_options_aum

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_options_aum` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_options_aum.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_options_aum.json` (rows: 8, mismatches: 7) |
| **Primary upstream** | `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary` | Primary (FROM) | ✓ `knowledge\ProdSchemas\DB_Schema\Sodreconciliation\Wiki\apex\Tables\apex.EXT981_BuyPowerSummary.md` |
| `main.general.bronze_usabroker_apex_options` | JOIN / referenced | ✓ `knowledge\ProdSchemas\ComplianceDBs\USABroker\Wiki\apex\Tables\apex.Options.md` |

## Lineage Chain

```
main.general.bronze_sodreconciliation_apex_ext981_buypowersummary   ←── primary upstream
  + main.general.bronze_usabroker_apex_options   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_options_aum   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `GCID` | `main.general.bronze_usabroker_apex_options` | `GCID` | `join_enriched` | — | op.GCID |
| 2 | `DateID` | `—` | `—` | `unknown` | — | CAST(DATE_FORMAT(bp.Date, 'yyyyMMdd') AS INT) AS DateID |
| 3 | `Date` | `—` | `Date` | `join_enriched` | — | bp.Date |
| 4 | `OptionsTotalEquity` | `—` | `TotalEquity` | `cast` | — | cast to DECIMAL(18, 2) — CAST(bp.TotalEquity AS DECIMAL(18, 2)) AS OptionsTotalEquity |
| 5 | `OptionsCashEquity` | `—` | `CashEquity` | `cast` | — | cast to DECIMAL(18, 2) — CAST(bp.CashEquity AS DECIMAL(18, 2)) AS OptionsCashEquity |
| 6 | `OptionsPositionMarketValue` | `—` | `PositionMarketValue` | `cast` | — | cast to DECIMAL(18, 2) — CAST(bp.PositionMarketValue AS DECIMAL(18, 2)) AS OptionsPositionMarketValue |
| 7 | `FirstOptionsAUMDateID` | `—` | `—` | `unknown` | — | CAST(DATE_FORMAT(CAST(ff.FirstFundingDate AS DATE), 'yyyyMMdd') AS INT) AS FirstOptionsAUMDateID |
| 8 | `FirstOptionsAUMDate` | `—` | `FirstFundingDate` | `cast` | — | cast to DATE — CAST(ff.FirstFundingDate AS DATE) AS FirstOptionsAUMDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **1**, WARN: **0**, ERROR: **7**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | — | `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.processdate` | ERROR |
| `Date` | — | `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.processdate` | ERROR |
| `OptionsTotalEquity` | — | `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.totalequity` | ERROR |
| `OptionsCashEquity` | — | `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.cashequity` | ERROR |
| `OptionsPositionMarketValue` | — | `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.positionmarketvalue` | ERROR |
| `FirstOptionsAUMDateID` | — | `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.processdate` | ERROR |
| `FirstOptionsAUMDate` | — | `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.processdate` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.general.bronze_usabroker_apex_options AS op ON bp.AccountNumber = op.OptionsApexID
- `LEFT JOIN` — LEFT JOIN first_funding AS ff ON bp.AccountNumber = ff.AccountNumber
