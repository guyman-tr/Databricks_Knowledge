# Column Lineage: main.etoro_kpi.v_raf

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_raf` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\v_raf.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\v_raf.json` (rows: 31, mismatches: 5) |
| **Primary upstream** | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.bronze_etoro_customer_customermoney` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` |
| `main.bi_db.bronze_etoro_customer_customermoney` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` |
| `main.general.bronze_etoro_dictionary_country` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |
| `main.general.bronze_etoro_dictionary_country` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |
| `main.general.bronze_etoro_dictionary_regulation` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md` |
| `main.general.bronze_etoro_dictionary_regulation` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md` |
| `main.general.bronze_etoro_dictionary_gurustatus` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GuruStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md` |
| `main.general.bronze_etoro_dictionary_playerlevel` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerLevel.md` |
| `main.general.bronze_etoro_dictionary_playerlevel` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerLevel.md` |
| `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.experience.bronze_rafcompensations_customer_raftrackingprocessed   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.general.bronze_etoro_dictionary_playerlevel   (JOIN)
  + main.general.bronze_etoro_dictionary_gurustatus   (JOIN)
  + main.general.bronze_etoro_dictionary_country   (JOIN)
  + main.general.bronze_etoro_dictionary_regulation   (JOIN)
  + main.general.bronze_etoro_dictionary_playerlevel   (JOIN)
  + main.general.bronze_etoro_dictionary_country   (JOIN)
  + main.general.bronze_etoro_dictionary_regulation   (JOIN)
  + main.bi_db.bronze_etoro_customer_customermoney   (JOIN)
  + main.bi_db.bronze_etoro_customer_customermoney   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities   (JOIN)
        │
        ▼
main.etoro_kpi.v_raf   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `ReferringCID` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `ReferringCID` | `passthrough` | — | R.ReferringCID |
| 2 | `ReferredCID` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `ReferredCID` | `passthrough` | — | R.ReferredCID |
| 3 | `ReferringGCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `GCID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | C1.GCID AS ReferringGCID |
| 4 | `ReferredGCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `GCID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | C2.GCID AS ReferredGCID |
| 5 | `ReferringCompensationAmount` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `—` | `arithmetic` | — | R.ReferringCompensationAmount / 100.0 AS ReferringCompensationAmount |
| 6 | `ReferredCompensationAmount` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `—` | `arithmetic` | — | R.ReferredCompensationAmount / 100.0 AS ReferredCompensationAmount |
| 7 | `RafStatusID` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `RafStatusID` | `passthrough` | — | R.RafStatusID |
| 8 | `RafStatusName` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `RafStatusName` | `passthrough` | — | R.RafStatusName |
| 9 | `CompensationDate` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `CompensationDate` | `passthrough` | — | R.CompensationDate |
| 10 | `ProcessingDate` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `ProcessingDate` | `passthrough` | — | R.ProcessingDate |
| 11 | `FraudReason` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `FraudReason` | `passthrough` | — | R.FraudReason |
| 12 | `IsProcessed` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `IsProcessed` | `passthrough` | — | R.IsProcessed |
| 13 | `ReferringOrigPlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerLevelID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | C1.PlayerLevelID AS ReferringOrigPlayerLevelID |
| 14 | `ReferringCalcPlayerLevelID` | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | `CalcPlayerLevelID` | `rename` | — | R.CalcPlayerLevelID AS ReferringCalcPlayerLevelID |
| 15 | `ReferringPlayerLevelName` | `main.general.bronze_etoro_dictionary_playerlevel` | `Name` | `join_enriched` | — | P1.Name AS ReferringPlayerLevelName |
| 16 | `ReferredOrigPlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerLevelID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | C2.PlayerLevelID AS ReferredOrigPlayerLevelID |
| 17 | `ReferredPlayerLevelName` | `main.general.bronze_etoro_dictionary_playerlevel` | `Name` | `join_enriched` | — | P2.Name AS ReferredPlayerLevelName |
| 18 | `ReferringRegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegulationID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | C1.RegulationID AS ReferringRegulationID |
| 19 | `ReferredRegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegulationID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | C2.RegulationID AS ReferredRegulationID |
| 20 | `ReferringRegulationName` | `main.general.bronze_etoro_dictionary_regulation` | `Name` | `join_enriched` | — | DR1.Name AS ReferringRegulationName |
| 21 | `ReferredRegulationName` | `main.general.bronze_etoro_dictionary_regulation` | `Name` | `join_enriched` | — | DR2.Name AS ReferredRegulationName |
| 22 | `ReferringIsPI` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `case` | — | CASE WHEN C1.GuruStatusID > 1 THEN 1 ELSE 0 END AS ReferringIsPI |
| 23 | `ReferringGuruStatusName` | `main.general.bronze_etoro_dictionary_gurustatus` | `Name` | `join_enriched` | — | G1.Name AS ReferringGuruStatusName |
| 24 | `ReferringCountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CountryID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | C1.CountryID AS ReferringCountryID |
| 25 | `ReferringCountry` | `main.general.bronze_etoro_dictionary_country` | `Name` | `join_enriched` | — | DC1.Name AS ReferringCountry |
| 26 | `ReferredCountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CountryID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | C2.CountryID AS ReferredCountryID |
| 27 | `ReferredCountry` | `main.general.bronze_etoro_dictionary_country` | `Name` | `join_enriched` | — | DC2.Name AS ReferredCountry |
| 28 | `ReferringRealizedEquity` | `main.bi_db.bronze_etoro_customer_customermoney` | `RealizedEquity` | `join_enriched` | — | CM1.RealizedEquity AS ReferringRealizedEquity |
| 29 | `ReferredRealizedEquity` | `main.bi_db.bronze_etoro_customer_customermoney` | `RealizedEquity` | `join_enriched` | — | CM2.RealizedEquity AS ReferredRealizedEquity |
| 30 | `ReferringTotalInvestedAmount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` | `TotalPositionsAmount` | `join_enriched` | — | L1.TotalPositionsAmount AS ReferringTotalInvestedAmount |
| 31 | `ReferredTotalInvestedAmount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` | `TotalPositionsAmount` | `join_enriched` | — | L2.TotalPositionsAmount AS ReferredTotalInvestedAmount |

## Cross-check vs system.access.column_lineage

- Total target columns: **31**
- OK: **26**, WARN: **2**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `ReferringCompensationAmount` | — | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed.referringcompensationamount` | ERROR |
| `ReferredCompensationAmount` | — | `main.experience.bronze_rafcompensations_customer_raftrackingprocessed.referredcompensationamount` | ERROR |
| `ReferringIsPI` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.gurustatusid` | ERROR |
| `ReferringTotalInvestedAmount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities.totalpositionsamount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities.totalpositionsamount`, `main.etoro_kpi.ddr_aum_v.totalinvestedamount` | WARN |
| `ReferredTotalInvestedAmount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities.totalpositionsamount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities.totalpositionsamount`, `main.etoro_kpi.ddr_aum_v.totalinvestedamount` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **22**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS C1 ON R.ReferringCID = C1.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS C2 ON R.ReferredCID = C2.RealCID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_playerlevel AS P1 ON P1.PlayerLevelID = C1.PlayerLevelID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_gurustatus AS G1 ON G1.GuruStatusID = C1.GuruStatusID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_country AS DC1 ON DC1.CountryID = C1.CountryID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_regulation AS DR1 ON DR1.ID = C1.RegulationID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_playerlevel AS P2 ON P2.PlayerLevelID = C2.PlayerLevelID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_country AS DC2 ON DC2.CountryID = C2.CountryID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_regulation AS DR2 ON DR2.ID = C2.RegulationID
- `LEFT JOIN` — LEFT JOIN main.bi_db.bronze_etoro_customer_customermoney AS CM1 ON CM1.CID = R.ReferringCID
