# Column Lineage: main.bi_output.bi_output_vg_copy_mimo

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_copy_mimo` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_copy_mimo.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_copy_mimo.json` (rows: 55, mismatches: 8) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_VerificationLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror   (JOIN)
  + main.bi_output.bi_output_vg_date   (JOIN)
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
        │
        ▼
main.bi_output.bi_output_vg_copy_mimo   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DateID` | `passthrough` | (Tier 2 — SP_Fact_CustomerAction) | fca.DateID |
| 2 | `WeekNumberYear` | `main.bi_output.bi_output_vg_date` | `WeekNumberYear` | `join_enriched` | (Tier 1 — DDL) | dd.WeekNumberYear |
| 3 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 4 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarQuarter |
| 5 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarYear |
| 6 | `ParentCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `ParentCID` | `join_enriched` | (Tier 1 — Trade.Mirror) | mr.ParentCID |
| 7 | `ParentUserName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `ParentUserName` | `join_enriched` | (Tier 1 — Trade.Mirror) | mr.ParentUserName |
| 8 | `MirrorTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `MirrorTypeID` | `join_enriched` | (Tier 1 — Trade.Mirror) | mr.MirrorTypeID |
| 9 | `OpenOccurred` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `OpenOccurred` | `join_enriched` | (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) | mr.OpenOccurred |
| 10 | `CloseOccurred` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `CloseOccurred` | `join_enriched` | (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) | mr.CloseOccurred |
| 11 | `RegisteredReal` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegisteredReal` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.RegisteredReal |
| 12 | `FirstDepositDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `FirstDepositDate` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dcu.FirstDepositDate |
| 13 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RealCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fca.RealCID |
| 14 | `MirrorID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `MirrorID` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.MirrorID |
| 15 | `PositionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `PositionID` | `passthrough` | — | fca.PositionID |
| 16 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerLevelID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerLevelID |
| 17 | `ClubTier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS ClubTier |
| 18 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegulationID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.RegulationID |
| 19 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr.Name AS Regulation |
| 20 | `VerificationLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `VerificationLevelID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.VerificationLevelID |
| 21 | `VerificationLevel` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | `Name` | `join_enriched` | (Tier 1 — upstream wiki, Dictionary.VerificationLevel) | dv.Name AS VerificationLevel |
| 22 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CountryID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.CountryID |
| 23 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 24 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName AS Region |
| 25 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountManagerID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.AccountManagerID |
| 26 | `AccountManager` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `—` | `string_op` | — | CONCAT_WS(dm.FirstName, '', dm.LastName) AS AccountManager |
| 27 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `LanguageID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.LanguageID |
| 28 | `Language` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dl.Name AS Language |
| 29 | `CommunicationLanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CommunicationLanguageID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.CommunicationLanguageID |
| 30 | `CommunicationLanguage` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dcl.Name AS CommunicationLanguage |
| 31 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountTypeID |
| 32 | `AccountType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountType) | act.Name AS AccountType |
| 33 | `GuruStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GuruStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.GuruStatusID |
| 34 | `GuruStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `GuruStatusName` | `join_enriched` | (Tier 1 — Dictionary.GuruStatus) | gs.GuruStatusName |
| 35 | `IsPI` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `case` | — | CASE WHEN fsc.GuruStatusID > 1 THEN 1 ELSE 0 END AS IsPI |
| 36 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountStatusID |
| 37 | `AccountStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `AccountStatusName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountStatus) | ast.AccountStatusName |
| 38 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerStatusID |
| 39 | `PlayerStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.Name AS PlayerStatusName |
| 40 | `CanOpenPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanOpenPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanOpenPosition |
| 41 | `CanClosePosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanClosePosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanClosePosition |
| 42 | `CanEditPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanEditPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanEditPosition |
| 43 | `CanBeCopied` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanBeCopied` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanBeCopied |
| 44 | `CanDeposit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanDeposit` | `join_enriched` | — | pst.CanDeposit |
| 45 | `CanRequestWithdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanRequestWithdraw` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanRequestWithdraw |
| 46 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusReasonID` | `join_enriched` | — | fsc.PlayerStatusReasonID |
| 47 | `PlayerStatusReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) | psr.Name AS PlayerStatusReasonName |
| 48 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusSubReasonID` | `join_enriched` | — | fsc.PlayerStatusSubReasonID |
| 49 | `PlayerStatusSubReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `PlayerStatusSubReasonName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) | pssr.PlayerStatusSubReasonName |
| 50 | `IsDetachMirror` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `case` | — | CASE WHEN fca.ActionTypeID = 19 THEN 1 ELSE 0 END AS IsDetachMirror |
| 51 | `MoneyInMirror` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN fca.ActionTypeID = 15 THEN ABS(fca.Amount) ELSE 0 END) AS MoneyInMirror |
| 52 | `MoneyOutMirror` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN fca.ActionTypeID = 16 THEN ABS(fca.Amount) ELSE 0 END) AS MoneyOutMirror |
| 53 | `CloseMirror` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN fca.ActionTypeID = 18 THEN ABS(fca.Amount) ELSE 0 END) AS CloseMirror |
| 54 | `NewMirror` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `aggregate` | — | SUM(CASE WHEN fca.ActionTypeID = 17 THEN ABS(fca.Amount) ELSE 0 END) AS NewMirror |
| 55 | `MirrorType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `case` | — | CASE WHEN fsc.AccountTypeID = 9 THEN 'Portfolio' WHEN fsc.GuruStatusID > 1 THEN 'PI' ELSE 'Copy' END AS MirrorType |

## Cross-check vs system.access.column_lineage

- Total target columns: **55**
- OK: **47**, WARN: **0**, ERROR: **8**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `AccountManager` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.firstname`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.lastname` | ERROR |
| `IsPI` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.gurustatusid` | ERROR |
| `IsDetachMirror` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid` | ERROR |
| `MoneyInMirror` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amount` | ERROR |
| `MoneyOutMirror` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amount` | ERROR |
| `CloseMirror` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amount` | ERROR |
| `NewMirror` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.amount` | ERROR |
| `MirrorType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.accounttypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.gurustatusid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **50**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror AS mr ON fca.MirrorID = mr.MirrorID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_output_vg_date AS dd ON fca.DateID = dd.DateID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fsc.RealCID = fca.RealCID AND fsc.FromDateID <= fca.DateID AND fsc.ToDateID >= fca.DateID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dcu ON fsc.RealCID = dcu.RealCID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager AS dm ON fsc.AccountManagerID = dm.ManagerID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr ON fsc.RegulationID = dr.ID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language AS dl ON fsc.LanguageID = dl.LanguageID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel AS dv ON fsc.VerificationLevelID = dv.ID
