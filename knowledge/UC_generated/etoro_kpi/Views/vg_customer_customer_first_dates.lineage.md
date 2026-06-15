# Column Lineage: main.etoro_kpi.vg_customer_customer_first_dates

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_customer_customer_first_dates` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\vg_customer_customer_first_dates.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\vg_customer_customer_first_dates.json` (rows: 23, mismatches: 3) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_ClubChangeLogProduct.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | JOIN / referenced | ✓ `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_First5Actions.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.bi_db.bronze_moneybusdb_dictionary_accounttypes   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions   (JOIN)
  + main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct   (JOIN)
        │
        ▼
main.etoro_kpi.vg_customer_customer_first_dates   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `CID` | `rename` | — | cfd.CID AS RealCID |
| 2 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `GCID` | `passthrough` | — | cfd.GCID |
| 3 | `RegistrationDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegisteredReal` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.RegisteredReal AS RegistrationDate |
| 4 | `FirstDepositDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `FirstDepositDate` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.FirstDepositDate |
| 5 | `FirstDepositAmount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `FirstDepositAmount` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.FirstDepositAmount |
| 6 | `FTDPlatformID` | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | `ID` | `join_enriched` | — | df.ID AS FTDPlatformID |
| 7 | `FTDPlatformName` | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | `—` | `case` | — | CASE WHEN df.Name = 'Trading' THEN 'TradingPlatform' WHEN df.Name = 'IBAN' THEN 'eMoney' ELSE df.Name END AS FTDPlatformName |
| 8 | `FirstPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstPosOpenDate` | `passthrough` | — | cfd.FirstPosOpenDate |
| 9 | `LastDepositDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastDepositDate` | `passthrough` | — | cfd.LastDepositDate |
| 10 | `LastDepositAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastDepositAmount` | `passthrough` | — | cfd.LastDepositAmount |
| 11 | `VerificationLevel1Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `VerificationLevel1Date` | `passthrough` | — | cfd.VerificationLevel1Date |
| 12 | `VerificationLevel2Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `VerificationLevel2Date` | `passthrough` | — | cfd.VerificationLevel2Date |
| 13 | `VerificationLevel3Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `VerificationLevel3Date` | `passthrough` | — | cfd.VerificationLevel3Date |
| 14 | `FirstFundedDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstNewFundedDate` | `rename` | — | cfd.FirstNewFundedDate AS FirstFundedDate |
| 15 | `LastNewFundedDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastNewFundedDate` | `passthrough` | — | cfd.LastNewFundedDate |
| 16 | `LastCashoutDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastCashoutDate` | `passthrough` | — | cfd.LastCashoutDate |
| 17 | `FirstAction` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | `FirstAction` | `join_enriched` | — | ffa.FirstAction |
| 18 | `FirstActionDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | `FirstActionDate` | `join_enriched` | — | ffa.FirstActionDate |
| 19 | `FirstInstrument` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | `FirstInstrument` | `join_enriched` | — | ffa.FirstInstrument |
| 20 | `FirstCross` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | `FirstCross` | `join_enriched` | — | ffa.FirstCross |
| 21 | `FirstCrossDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | `FirstCrossDate` | `join_enriched` | — | ffa.FirstCrossDate |
| 22 | `FirstClub` | `—` | `CurrentClub` | `join_enriched` | — | fc.CurrentClub AS FirstClub |
| 23 | `FirstClubDate` | `—` | `Date` | `join_enriched` | — | fc.Date AS FirstClubDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **23**
- OK: **20**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `FTDPlatformName` | — | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes.name` | ERROR |
| `FirstClub` | — | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct.currentclub` | ERROR |
| `FirstClubDate` | — | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct.date` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **12**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON cfd.CID = dc.RealCID
- `LEFT JOIN` — LEFT JOIN main.bi_db.bronze_moneybusdb_dictionary_accounttypes AS df ON dc.FTDPlatformID = df.ID
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions AS ffa ON cfd.CID = ffa.CID
- `LEFT JOIN` — LEFT JOIN (SELECT ccl.CID, ccl.Date, ccl.CurrentClub FROM main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct AS ccl WHERE ccl.IsFTC = 1) AS fc ON fc.CID = cfd.CID
