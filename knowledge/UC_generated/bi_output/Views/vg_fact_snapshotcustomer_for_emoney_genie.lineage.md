# Column Lineage: main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_fact_snapshotcustomer_for_emoney_genie.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_fact_snapshotcustomer_for_emoney_genie.json` (rows: 26, mismatches: 0) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
        │
        ▼
main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `FromDateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `FromDateID` | `join_enriched` | (Tier 2 - SP code: SP_Fact_SnapshotEquity) | b.FromDateID |
| 2 | `ToDateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `ToDateID` | `join_enriched` | (Tier 2 - SP code: SP_Fact_SnapshotEquity) | b.ToDateID |
| 3 | `GCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GCID` | `passthrough` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.GCID AS GCID /* Customer identifiers (valid in snapshot period) */ |
| 4 | `CID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RealCID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.RealCID AS CID |
| 5 | `CountryID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CountryID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.CountryID AS CountryID_FromDate_ToDate /* Geography & regulation (valid in snapshot period) */ |
| 6 | `RegionID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegionID` | `rename` | — | a.RegionID AS RegionID_FromDate_ToDate |
| 7 | `RegulationID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegulationID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.RegulationID AS RegulationID_FromDate_ToDate |
| 8 | `LanguageID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `LanguageID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.LanguageID AS LanguageID_FromDate_ToDate /* Language & communication (valid in snapshot period) */ |
| 9 | `CommunicationLanguageID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CommunicationLanguageID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.CommunicationLanguageID AS CommunicationLanguageID_FromDate_ToDate |
| 10 | `VerificationLevelID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `VerificationLevelID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.VerificationLevelID AS VerificationLevelID_FromDate_ToDate /* Customer status & risk (valid in snapshot period) */ |
| 11 | `PlayerStatusID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.PlayerStatusID AS PlayerStatusID_FromDate_ToDate |
| 12 | `RiskStatusID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RiskStatusID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.RiskStatusID AS RiskStatusID_FromDate_ToDate |
| 13 | `RiskClassificationID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RiskClassificationID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.RiskClassificationID AS RiskClassificationID_FromDate_ToDate |
| 14 | `AccountStatusID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountStatusID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.AccountStatusID AS AccountStatusID_FromDate_ToDate |
| 15 | `IsValidCustomer_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsValidCustomer` | `rename` | — | a.IsValidCustomer AS IsValidCustomer_FromDate_ToDate |
| 16 | `IsEmailVerified_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsEmailVerified` | `rename` | — | a.IsEmailVerified AS IsEmailVerified_FromDate_ToDate |
| 17 | `IsPhoneVerified_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsPhoneVerified` | `rename` | — | a.IsPhoneVerified AS IsPhoneVerified_FromDate_ToDate |
| 18 | `PlayerLevelID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerLevelID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.PlayerLevelID AS PlayerLevelID_FromDate_ToDate /* Commercial / segmentation (valid in snapshot period) */ |
| 19 | `Club_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | c.Name AS Club_FromDate_ToDate |
| 20 | `AccountTypeID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.AccountTypeID AS AccountTypeID_FromDate_ToDate |
| 21 | `IsDepositor_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsDepositor` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.IsDepositor AS IsDepositor_FromDate_ToDate |
| 22 | `GuruStatusID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GuruStatusID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.GuruStatusID AS GuruStatusID_FromDate_ToDate |
| 23 | `AccountManagerID_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountManagerID` | `rename` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | a.AccountManagerID AS AccountManagerID_FromDate_ToDate |
| 24 | `City_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `City` | `rename` | — | a.City AS City_FromDate_ToDate /* Location (valid in snapshot period) */ |
| 25 | `Address_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `Address` | `rename` | — | a.Address AS Address_FromDate_ToDate |
| 26 | `Country_FromDate_ToDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | d.Name AS Country_FromDate_ToDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **26**
- OK: **26**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **4**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS b ON a.DateRangeID = b.DateRangeID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS c ON a.PlayerLevelID = c.PlayerLevelID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS d ON a.CountryID = d.CountryID
