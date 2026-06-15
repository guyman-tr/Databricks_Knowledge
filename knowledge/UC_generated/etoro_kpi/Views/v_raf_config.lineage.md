# Column Lineage: main.etoro_kpi.v_raf_config

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_raf_config` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\v_raf_config.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\v_raf_config.json` (rows: 15, mismatches: 6) |
| **Primary upstream** | `main.experience.bronze_rafcompensations_config_viewconfig` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_dictionary_regulation` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md` |
| `main.experience.bronze_rafcompensations_config_viewconfig` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.experience.bronze_rafcompensations_config_viewconfig   ←── primary upstream
  + main.general.bronze_etoro_dictionary_regulation   (JOIN)
        │
        ▼
main.etoro_kpi.v_raf_config   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CountryName` | `main.experience.bronze_rafcompensations_config_viewconfig` | `CountryName` | `passthrough` | — | CountryName /* CountryID, */ |
| 2 | `RegulationName` | `main.general.bronze_etoro_dictionary_regulation` | `Name` | `join_enriched` | — | DR.Name AS RegulationName /* RegulationID, */ |
| 3 | `ReferringCompensationInDollar` | `main.experience.bronze_rafcompensations_config_viewconfig` | `—` | `arithmetic` | — | ReferringCompensationInCents / 100 AS ReferringCompensationInDollar |
| 4 | `ReferredCompensationInDollar` | `main.experience.bronze_rafcompensations_config_viewconfig` | `—` | `arithmetic` | — | ReferredCompensationInCents / 100 AS ReferredCompensationInDollar |
| 5 | `MaxNumberOfCompensations` | `main.experience.bronze_rafcompensations_config_viewconfig` | `MaxNumberOfCompensations` | `passthrough` | — | MaxNumberOfCompensations |
| 6 | `FraudScore` | `main.experience.bronze_rafcompensations_config_viewconfig` | `FraudScore` | `passthrough` | — | FraudScore |
| 7 | `LevelName` | `main.experience.bronze_rafcompensations_config_viewconfig` | `LevelName` | `passthrough` | — | LevelName |
| 8 | `ValidFrom` | `main.experience.bronze_rafcompensations_config_viewconfig` | `ValidFrom` | `passthrough` | — | ValidFrom /* RafModelTypeID, */ /* RafConfigurationID, */ |
| 9 | `ReferringMinDepositInDollar` | `main.experience.bronze_rafcompensations_config_viewconfig` | `—` | `arithmetic` | — | ReferringMinDepositInCents / 100 AS ReferringMinDepositInDollar |
| 10 | `ReferredMinDepositInDollar` | `main.experience.bronze_rafcompensations_config_viewconfig` | `—` | `arithmetic` | — | ReferredMinDepositInCents / 100 AS ReferredMinDepositInDollar |
| 11 | `RafProgramStartDate` | `main.experience.bronze_rafcompensations_config_viewconfig` | `RafProgramStartDate` | `passthrough` | — | RafProgramStartDate |
| 12 | `DaysToWaitFromFTD` | `main.experience.bronze_rafcompensations_config_viewconfig` | `DaysToWaitFromFTD` | `passthrough` | — | DaysToWaitFromFTD |
| 13 | `ReferringMinPositionsAmountInDollar` | `main.experience.bronze_rafcompensations_config_viewconfig` | `—` | `arithmetic` | — | ReferringMinPositionsAmountInCents / 100 AS ReferringMinPositionsAmountInDollar |
| 14 | `ReferredMinPositionsAmountInDollar` | `main.experience.bronze_rafcompensations_config_viewconfig` | `—` | `arithmetic` | — | ReferredMinPositionsAmountInCents / 100 AS ReferredMinPositionsAmountInDollar |
| 15 | `DaysToCheckMinPositionsAmountFromRegistration` | `main.experience.bronze_rafcompensations_config_viewconfig` | `DaysToCheckMinPositionsAmountFromRegistration` | `passthrough` | — | DaysToCheckMinPositionsAmountFromRegistration |

## Cross-check vs system.access.column_lineage

- Total target columns: **15**
- OK: **9**, WARN: **0**, ERROR: **6**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `ReferringCompensationInDollar` | — | `main.experience.bronze_rafcompensations_config_viewconfig.referringcompensationincents` | ERROR |
| `ReferredCompensationInDollar` | — | `main.experience.bronze_rafcompensations_config_viewconfig.referredcompensationincents` | ERROR |
| `ReferringMinDepositInDollar` | — | `main.experience.bronze_rafcompensations_config_viewconfig.referringmindepositincents` | ERROR |
| `ReferredMinDepositInDollar` | — | `main.experience.bronze_rafcompensations_config_viewconfig.referredmindepositincents` | ERROR |
| `ReferringMinPositionsAmountInDollar` | — | `main.experience.bronze_rafcompensations_config_viewconfig.referringminpositionsamountincents` | ERROR |
| `ReferredMinPositionsAmountInDollar` | — | `main.experience.bronze_rafcompensations_config_viewconfig.referredminpositionsamountincents` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **7**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_regulation AS DR ON RC.RegulationID = DR.ID
