# Column Lineage: main.bi_output.bi_output_vg_crm_user

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_crm_user` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_crm_user.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_crm_user.json` (rows: 21, mismatches: 5) |
| **Primary upstream** | `main.crm.silver_crm_user` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.crm.silver_crm_user` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.crm.silver_crm_user` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.crm.silver_crm_user` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.crm.silver_crm_user   ←── primary upstream
        │
        ▼
main.bi_output.bi_output_vg_crm_user   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `UserId` | `main.crm.silver_crm_user` | `Id` | `rename` | — | u.Id AS UserId |
| 2 | `BO_User_ID` | `main.crm.silver_crm_user` | `BO_User_ID__c` | `rename` | — | u.BO_User_ID__c AS BO_User_ID |
| 3 | `FullName` | `main.crm.silver_crm_user` | `—` | `string_op` | — | CONCAT(u.FirstName, ' ', u.LastName) AS FullName |
| 4 | `Department` | `main.crm.silver_crm_user` | `Department` | `passthrough` | — | u.Department AS Department |
| 5 | `Title` | `main.crm.silver_crm_user` | `Title` | `passthrough` | — | u.Title AS Title |
| 6 | `Position` | `main.crm.silver_crm_user` | `Position__c` | `rename` | — | u.Position__c AS Position |
| 7 | `Desk` | `main.crm.silver_crm_user` | `Desk__c` | `rename` | — | u.Desk__c AS Desk |
| 8 | `Team` | `main.crm.silver_crm_user` | `Team__c` | `rename` | — | u.Team__c AS Team |
| 9 | `IsActive` | `main.crm.silver_crm_user` | `IsActive` | `passthrough` | — | u.IsActive AS IsActive |
| 10 | `ManagerId` | `main.crm.silver_crm_user` | `ManagerId` | `passthrough` | — | u.ManagerId AS ManagerId |
| 11 | `TimeZoneSidKeys` | `main.crm.silver_crm_user` | `—` | `case` | — | CASE WHEN u.ManagerId IN ('0050800000EE0zOAAT', '0050800000GyOLrAAN', '0050800000DArh6AAD') THEN 'Australia/Sydney' ELSE u.TimeZoneSidKey EN |
| 12 | `Manager_BO_User_ID` | `main.crm.silver_crm_user` | `BO_User_ID__c` | `join_enriched` | — | m.BO_User_ID__c AS Manager_BO_User_ID /* Direct manager details (level 1) */ |
| 13 | `Manager_FullName` | `main.crm.silver_crm_user` | `—` | `string_op` | — | CONCAT(m.FirstName, ' ', m.LastName) AS Manager_FullName |
| 14 | `Manager_Department` | `main.crm.silver_crm_user` | `Department` | `join_enriched` | — | m.Department AS Manager_Department |
| 15 | `Manager_Title` | `main.crm.silver_crm_user` | `Title` | `join_enriched` | — | m.Title AS Manager_Title |
| 16 | `Manager_Position` | `main.crm.silver_crm_user` | `Position__c` | `join_enriched` | — | m.Position__c AS Manager_Position |
| 17 | `Manager_Desk` | `main.crm.silver_crm_user` | `Desk__c` | `join_enriched` | — | m.Desk__c AS Manager_Desk |
| 18 | `Manager_Team` | `main.crm.silver_crm_user` | `Team__c` | `join_enriched` | — | m.Team__c AS Manager_Team |
| 19 | `Manager_IsActive` | `main.crm.silver_crm_user` | `IsActive` | `join_enriched` | — | m.IsActive AS Manager_IsActive |
| 20 | `RM_UserId` | `—` | `RM_UserId` | `join_enriched` | — | rc.RM_UserId AS RM_UserId /* Resolved Regional Manager (RM) from the hierarchy */ |
| 21 | `RM_FullName` | `—` | `RM_FullName` | `join_enriched` | — | rc.RM_FullName AS RM_FullName |

## Cross-check vs system.access.column_lineage

- Total target columns: **21**
- OK: **16**, WARN: **0**, ERROR: **5**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `FullName` | — | `main.crm.silver_crm_user.firstname`, `main.crm.silver_crm_user.lastname` | ERROR |
| `TimeZoneSidKeys` | — | `main.crm.silver_crm_user.managerid`, `main.crm.silver_crm_user.timezonesidkey` | ERROR |
| `Manager_FullName` | — | `main.crm.silver_crm_user.firstname`, `main.crm.silver_crm_user.lastname` | ERROR |
| `RM_UserId` | — | `main.crm.silver_crm_user.id` | ERROR |
| `RM_FullName` | — | `main.crm.silver_crm_user.firstname`, `main.crm.silver_crm_user.lastname` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **10**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.crm.silver_crm_user AS m ON u.ManagerId = m.Id
- `LEFT JOIN` — LEFT JOIN rm_choice AS rc ON u.Id = rc.UserId AND rc.rn = 1
- `INNER JOIN` — JOIN main.crm.silver_crm_user AS rm ON h.CurrentId = rm.Id
- `INNER JOIN` — JOIN main.crm.silver_crm_user AS m ON h.NextManagerId = m.Id
