# Column Lineage: main.bi_output.bi_output_vg_revenue

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_revenue` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_revenue.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_revenue.json` (rows: 52, mismatches: 3) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_VerificationLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_ouput_v_dim_instrumenttype.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Revenue_Generating_Actions.md` |
| `main.bi_output.bi_output_customer_ddr_revenue_metrics` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_customer_ddr_revenue_metrics.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.bi_output.bi_output_vg_date   (JOIN)
  + main.bi_output.bi_ouput_v_dim_instrumenttype   (JOIN)
  + main.bi_output.bi_output_customer_ddr_revenue_metrics   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
        │
        ▼
main.bi_output.bi_output_vg_revenue   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `main.bi_output.bi_output_vg_date` | `Date` | `join_enriched` | — | dd.Date |
| 2 | `DateID` | `main.bi_output.bi_output_vg_date` | `DateID` | `join_enriched` | — | dd.DateID |
| 3 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | — | dd.CalendarYearMonth |
| 4 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | — | dd.CalendarQuarter |
| 5 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | — | dd.CalendarYear |
| 6 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to STRING — CAST(rga.RealCID AS STRING) AS RealCID |
| 7 | `InstrumentTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `InstrumentTypeID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | rga.InstrumentTypeID |
| 8 | `InstrumentType` | `main.bi_output.bi_ouput_v_dim_instrumenttype` | `InstrumentType` | `join_enriched` | — | ins.InstrumentType |
| 9 | `IsSettled` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsSettled` | `passthrough` | (Tier 5 — Expert Review) | rga.IsSettled |
| 10 | `IsCopy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsCopy` | `passthrough` | (Tier 2 — Fact_CustomerAction.MirrorID logic via Function_Revenue_*) | rga.IsCopy |
| 11 | `Metric` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `Metric` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | rga.Metric |
| 12 | `CountAsActiveTrade` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `CountAsActiveTrade` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | rga.CountAsActiveTrade |
| 13 | `IncludedInTotalRevenue` | `main.bi_output.bi_output_customer_ddr_revenue_metrics` | `IncludedInTotalRevenue` | `join_enriched` | — | rmtr.IncludedInTotalRevenue |
| 14 | `RevenueMetricCategory` | `main.bi_output.bi_output_customer_ddr_revenue_metrics` | `RevenueMetricCategory` | `join_enriched` | — | rmtr.RevenueMetricCategory |
| 15 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerLevelID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerLevelID |
| 16 | `ClubTier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS ClubTier |
| 17 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegulationID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.RegulationID |
| 18 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr.Name AS Regulation |
| 19 | `VerificationLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `VerificationLevelID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.VerificationLevelID |
| 20 | `VerificationLevel` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | `Name` | `join_enriched` | (Tier 1 — upstream wiki, Dictionary.VerificationLevel) | dv.Name AS VerificationLevel |
| 21 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CountryID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.CountryID |
| 22 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 23 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName AS Region |
| 24 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountManagerID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountManagerID |
| 25 | `AccountManager` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `—` | `string_op` | — | CONCAT_WS(dm.FirstName, '', dm.LastName) AS AccountManager |
| 26 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `LanguageID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.LanguageID |
| 27 | `Language` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dl.Name AS Language |
| 28 | `CommunicationLanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CommunicationLanguageID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.CommunicationLanguageID |
| 29 | `CommunicationLanguage` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dcl.Name AS CommunicationLanguage |
| 30 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountTypeID |
| 31 | `AccountType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountType) | act.Name AS AccountType |
| 32 | `GuruStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GuruStatusID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.GuruStatusID |
| 33 | `GuruStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `GuruStatusName` | `join_enriched` | (Tier 1 — Dictionary.GuruStatus) | gs.GuruStatusName |
| 34 | `IsPI` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `case` | — | CASE WHEN fsc.GuruStatusID > 1 THEN 1 ELSE 0 END AS IsPI |
| 35 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountStatusID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountStatusID |
| 36 | `AccountStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `AccountStatusName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountStatus) | ast.AccountStatusName |
| 37 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerStatusID |
| 38 | `PlayerStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.Name AS PlayerStatusName |
| 39 | `CanOpenPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanOpenPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanOpenPosition |
| 40 | `CanClosePosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanClosePosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanClosePosition |
| 41 | `CanEditPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanEditPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanEditPosition |
| 42 | `CanBeCopied` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanBeCopied` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanBeCopied |
| 43 | `CanDeposit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanDeposit` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanDeposit |
| 44 | `CanRequestWithdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanRequestWithdraw` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanRequestWithdraw |
| 45 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusReasonID` | `join_enriched` | — | fsc.PlayerStatusReasonID |
| 46 | `PlayerStatusReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) | psr.Name AS PlayerStatusReasonName |
| 47 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusSubReasonID` | `join_enriched` | — | fsc.PlayerStatusSubReasonID |
| 48 | `PlayerStatusSubReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `PlayerStatusSubReasonName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) | pssr.PlayerStatusSubReasonName |
| 49 | `CitizenshipCountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CitizenshipCountryID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.CitizenshipCountryID |
| 50 | `CitizenshipCountry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dcz.Name AS CitizenshipCountry |
| 51 | `Amount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `—` | `aggregate` | — | SUM(rga.Amount) AS Amount |
| 52 | `AffiliateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AffiliateID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.AffiliateID |

## Cross-check vs system.access.column_lineage

- Total target columns: **52**
- OK: **49**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `AccountManager` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.firstname`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.lastname` | ERROR |
| `IsPI` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.gurustatusid` | ERROR |
| `Amount` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions.amount` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **45**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc1 ON rga.RealCID = dc1.RealCID
- `INNER INNER` — INNER JOIN main.bi_output.bi_output_vg_date AS dd ON rga.DateID = dd.DateID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_ouput_v_dim_Instrumenttype AS ins ON rga.InstrumentTypeID = ins.InstrumentTypeID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_output_customer_ddr_revenue_metrics AS rmtr ON rga.Metric = rmtr.Metric
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fsc.RealCID = rga.RealCID AND fsc.FromDateID <= rga.DateID AND fsc.ToDateID >= rga.DateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dcu ON fsc.RealCID = dcu.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager AS dm ON fsc.AccountManagerID = dm.ManagerID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr ON fsc.RegulationID = dr.ID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
