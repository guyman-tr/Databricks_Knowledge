# Column Lineage — BI_DB_dbo.BI_DB_AssignmentToolVolumes

Generated: 2026-04-23 | Writer SP: SP_H_AssignmentToolVolumes | ETL Frequency: Hourly

## Production Source

| Property | Value |
|----------|-------|
| **Primary Source** | Assignment Tool production system (eToro internal KYC/ops task management) |
| **Source Layer** | External tables in BI_DB_dbo (External_Assignment_*) |
| **UC Target** | `_Not_Migrated` |
| **Upstream Wiki** | None — Assignment Tool is an internal system with no documented wiki |

## ETL Pipeline

```
Assignment Tool Production System (internal)
  |-- External staging: External_Assignment_* tables in BI_DB_dbo --|
  v
External_Assignment_Assignment_TaskAudit   (task outcomes, ManagerID, OutcomeDate)
External_Assignment_Assignment_V_Tasks     (current tasks: CID, CreateDate, BeginTime)
External_Assignment_History_V_Tasks        (historical tasks: CID, CreateDate, BeginTime)
External_Assignment_Assignment_ManagerTeam (current manager–team assignments)
External_Assignment_History_ManagerTeam    (historical manager–team assignments)
External_Assignment_Assignment_Teams       (team names)
External_Assignment_Dictionary_Outcome     (outcome name dictionary)
External_Assignment_BackOffice_Manager     (agent first/last names)
  |-- JOIN DWH_dbo.Dim_Customer, DWH_dbo.Dim_Country --|
  |-- SP_H_AssignmentToolVolumes @date (hourly, P0) --|
  |-- DELETE WHERE BeginTimeID=@dateID + INSERT --|
  v
BI_DB_dbo.BI_DB_AssignmentToolVolumes (10.6M rows, 2019-11-01 to 2026-04-12)
  |-- UC: _Not_Migrated --|
```

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|------------|---------------|---------------|-----------|------|
| 1 | CID | External_Assignment_History_V_Tasks / Assignment_V_Tasks | CID | Passthrough — customer whose case the task relates to | Tier 2 |
| 2 | TaskID | External_Assignment_Assignment_TaskAudit | TaskID | Passthrough — unique task identifier | Tier 2 |
| 3 | UpdatedByTeamMemberID | External_Assignment_Assignment_TaskAudit | ManagerID | Rename: ManagerID → UpdatedByTeamMemberID | Tier 2 |
| 4 | UpdatedByTeamMemberFinal | External_Assignment_BackOffice_Manager | FirstName, LastName | Concat: FirstName + ' ' + LastName (agent full name) | Tier 2 |
| 5 | UpdatedByTeamFinal | External_Assignment_Assignment_Teams | Name | Resolved via ManagerID → #finalmanagers (latest team) → Teams.Name | Tier 2 |
| 6 | Outcome | External_Assignment_Dictionary_Outcome | Name | Resolved via ta.OutcomeID → outcome.Name | Tier 2 |
| 7 | CreateDate | External_Assignment_History_V_Tasks / Assignment_V_Tasks | CreateDate | Passthrough — task creation datetime | Tier 2 |
| 8 | Occurred | External_Assignment_Assignment_TaskAudit | OutcomeDate | Rename: OutcomeDate → Occurred | Tier 2 |
| 9 | Country | DWH_dbo.Dim_Country | Name | Resolved via CID → Dim_Customer.CountryID → Dim_Country.Name | Tier 2 |
| 10 | BeginTime | External_Assignment_History_V_Tasks / Assignment_V_Tasks | BeginTime | Passthrough — time agent began working on task | Tier 2 |
| 11 | BeginTimeID | External_Assignment_Assignment_TaskAudit | OutcomeDate | Computed: CONVERT(VARCHAR(8), OutcomeDate, 112) AS INT (YYYYMMDD) | Tier 2 |
| 12 | UpdateDate | — | — | GETDATE() at INSERT time — ETL metadata | Propagation |

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No upstream wiki for Assignment Tool |
| Tier 2 | 11 | ETL-computed from Assignment Tool external tables and DWH lookups |
| Propagation | 1 | UpdateDate |
