# Column Lineage: main.bi_output.bi_output_vg_cf_crm_contact

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_cf_crm_contact` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_cf_crm_contact.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_cf_crm_contact.json` (rows: 26, mismatches: 0) |
| **Primary upstream** | `main.bi_output_stg.` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_vg_crm_user` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_crm_user.md` |
| `main.bi_output.bi_output_vg_crm_user` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_crm_user.md` |
| `main.bi_output_stg.` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.bi_output_stg.   ←── primary upstream
  + main.bi_output.bi_output_vg_crm_user   (JOIN)
  + main.bi_output.bi_output_vg_crm_user   (JOIN)
        │
        ▼
main.bi_output.bi_output_vg_cf_crm_contact   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Id_Source` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `Id` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `CreatedDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `CreatedDateTime` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `Task_Id` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `CustEng_Id` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `Email_Id` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `Case_Id` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `Case_Number` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 10 | `CID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 11 | `Task_CreatedDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 12 | `Task_LastModifiedDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 13 | `CustEng_CreatedDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 14 | `CustEng_LastModifiedDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 15 | `Email_CreatedDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 16 | `Email_LastModifiedDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 17 | `Task_Subject` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 18 | `Task_Subtype` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 19 | `Task_Status` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 20 | `CustEng_CallSummary` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 21 | `CustEng_ZoomCall` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 22 | `OwnerId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 23 | `Owner` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 24 | `AccountManagerId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 25 | `AccountManager` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 26 | `CallDurationInSeconds` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 27 | `Vonage_CallDuration` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 28 | `Task_CallDuration` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 29 | `CustEng_CallDuration` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 30 | `ContactDirection` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 31 | `ContactType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 32 | `ContactType_Group` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 33 | `CF_Terminology` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 34 | `CreatedDateId` | `main.bi_output_stg.` | `—` | `unknown` | — | CAST(DATE_FORMAT(tfcrm.CreatedDate, 'yyyyMMdd') AS INT) AS CreatedDateId /* Derived date key */ |
| 35 | `AM_BO_User_ID` | `main.bi_output.bi_output_vg_crm_user` | `BO_User_ID` | `join_enriched` | — | amu.BO_User_ID AS AM_BO_User_ID /* AM enrichment */ |
| 36 | `AM_FullName` | `main.bi_output.bi_output_vg_crm_user` | `FullName` | `join_enriched` | — | amu.FullName AS AM_FullName |
| 37 | `AM_Department` | `main.bi_output.bi_output_vg_crm_user` | `Department` | `join_enriched` | — | amu.Department AS AM_Department |
| 38 | `AM_Title` | `main.bi_output.bi_output_vg_crm_user` | `Title` | `join_enriched` | — | amu.Title AS AM_Title |
| 39 | `AM_Position` | `main.bi_output.bi_output_vg_crm_user` | `Position` | `join_enriched` | — | amu.Position AS AM_Position |
| 40 | `AM_Desk` | `main.bi_output.bi_output_vg_crm_user` | `Desk` | `join_enriched` | — | amu.Desk AS AM_Desk |
| 41 | `AM_Team` | `main.bi_output.bi_output_vg_crm_user` | `Team` | `join_enriched` | — | amu.Team AS AM_Team |
| 42 | `AM_IsActive` | `main.bi_output.bi_output_vg_crm_user` | `IsActive` | `join_enriched` | — | amu.IsActive AS AM_IsActive |
| 43 | `AM_TimeZoneSidKeys` | `main.bi_output.bi_output_vg_crm_user` | `TimeZoneSidKeys` | `join_enriched` | — | amu.TimeZoneSidKeys AS AM_TimeZoneSidKeys |
| 44 | `Manager_FullName` | `main.bi_output.bi_output_vg_crm_user` | `Manager_FullName` | `join_enriched` | — | amu.Manager_FullName /* AM manager hierarchy */ |
| 45 | `Manager_Department` | `main.bi_output.bi_output_vg_crm_user` | `Manager_Department` | `join_enriched` | — | amu.Manager_Department |
| 46 | `Manager_Title` | `main.bi_output.bi_output_vg_crm_user` | `Manager_Title` | `join_enriched` | — | amu.Manager_Title |
| 47 | `Manager_Position` | `main.bi_output.bi_output_vg_crm_user` | `Manager_Position` | `join_enriched` | — | amu.Manager_Position |
| 48 | `Manager_Desk` | `main.bi_output.bi_output_vg_crm_user` | `Manager_Desk` | `join_enriched` | — | amu.Manager_Desk |
| 49 | `Manager_Team` | `main.bi_output.bi_output_vg_crm_user` | `Manager_Team` | `join_enriched` | — | amu.Manager_Team |
| 50 | `Owner_BO_User_ID` | `main.bi_output.bi_output_vg_crm_user` | `BO_User_ID` | `join_enriched` | — | owneru.BO_User_ID AS Owner_BO_User_ID /* Owner enrichment */ |
| 51 | `Owner_FullName` | `main.bi_output.bi_output_vg_crm_user` | `FullName` | `join_enriched` | — | owneru.FullName AS Owner_FullName |
| 52 | `Owner_Department` | `main.bi_output.bi_output_vg_crm_user` | `Department` | `join_enriched` | — | owneru.Department AS Owner_Department |
| 53 | `Owner_Title` | `main.bi_output.bi_output_vg_crm_user` | `Title` | `join_enriched` | — | owneru.Title AS Owner_Title |
| 54 | `Owner_Position` | `main.bi_output.bi_output_vg_crm_user` | `Position` | `join_enriched` | — | owneru.Position AS Owner_Position |
| 55 | `Owner_Desk` | `main.bi_output.bi_output_vg_crm_user` | `Desk` | `join_enriched` | — | owneru.Desk AS Owner_Desk |
| 56 | `Owner_Team` | `main.bi_output.bi_output_vg_crm_user` | `Team` | `join_enriched` | — | owneru.Team AS Owner_Team |
| 57 | `Owner_IsActive` | `main.bi_output.bi_output_vg_crm_user` | `IsActive` | `join_enriched` | — | owneru.IsActive AS Owner_IsActive |
| 58 | `Owner_TimeZoneSidKeys` | `main.bi_output.bi_output_vg_crm_user` | `TimeZoneSidKeys` | `join_enriched` | — | owneru.TimeZoneSidKeys AS Owner_TimeZoneSidKeys |

## Cross-check vs system.access.column_lineage

- Total target columns: **26**
- OK: **5**, WARN: **0**, ERROR: **0**, INFO: **21**  ✓

## Lost / added columns

- Computed/added columns vs primary: **24**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `INNER JOIN` — JOIN main.bi_output.bi_output_vg_crm_user AS amu ON tfcrm.AccountManagerId = amu.UserId
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_output_vg_crm_user AS owneru ON tfcrm.OwnerId = owneru.UserId
