# Column Lineage: main.bi_output.vg_emoney_potentialclients_attributes

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_potentialclients_attributes` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_emoney_potentialclients_attributes.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_emoney_potentialclients_attributes.json` (rows: 9, mismatches: 0) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
        │
        ▼
main.bi_output.vg_emoney_potentialclients_attributes   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `—` | `CID` | `join_enriched` | — | e.CID |
| 2 | `CountryName` | `—` | `CountryName` | `join_enriched` | — | e.CountryName |
| 3 | `Club` | `—` | `Club` | `join_enriched` | — | e.Club |
| 4 | `PlayerStatusID` | `—` | `PlayerStatusID` | `join_enriched` | — | e.PlayerStatusID |
| 5 | `VerificationLevelID` | `—` | `VerificationLevelID` | `join_enriched` | — | e.VerificationLevelID |
| 6 | `IsEligible` | `—` | `IsEligible_AU` | `join_enriched` | — | e.IsEligible_AU AS IsEligible |
| 7 | `HasETMAccount` | `—` | `—` | `coalesce` | — | COALESCE(a.HasETMAccount, 0) AS HasETMAccount |
| 8 | `AccountSubProgramID` | `—` | `AccountSubProgramID` | `join_enriched` | — | a.AccountSubProgramID |
| 9 | `AccountCreateDateID` | `—` | `AccountCreateDateID` | `join_enriched` | — | a.AccountCreateDateID |

## Cross-check vs system.access.column_lineage

- Total target columns: **9**
- OK: **9**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **8**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN etm_accounts AS a ON e.CID = a.CID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS co ON dc.CountryID = co.CountryID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON mda.CID = fsc.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON dr.DateRangeID = fsc.DateRangeID AND mda.AccountCreateDateID BETWEEN dr.FromDateID AND dr.ToDateID
