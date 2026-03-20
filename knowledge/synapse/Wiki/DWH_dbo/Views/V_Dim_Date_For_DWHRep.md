# DWH_dbo.V_Dim_Date_For_DWHRep

> Simplified date dimension view for DWH replication — exposes the base Dim_Date columns plus PartitionID, UpdateDate, and IsFirstDayOfMonth without any dynamic temporal computations.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Table** | DWH_dbo.Dim_Date |
| **Purpose** | DWH replication/import interface (ImportFromSynapse pipeline) |

---

## 1. Business Meaning

`V_Dim_Date_For_DWHRep` is a streamlined version of the date dimension used specifically by the DWH replication pipeline that copies tables from Synapse back to the legacy DWH-01 SQL Server (see Confluence: "Import Tables From Synapse To DWH"). Unlike `V_Dim_Date` which adds ~20 dynamic CASE expressions, this view passes through the raw Dim_Date columns with no computed logic — making it cheaper to replicate and ensuring deterministic results across servers.

The view includes three columns that `V_Dim_Date` excludes:
- **PartitionID** — needed for partition-aligned replication
- **UpdateDate** — tracks when Dim_Date rows were last modified
- **IsFirstDayOfMonth** — a static Dim_Date flag (not dynamically computed)

---

## 2. Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1-42 | *(All standard Dim_Date columns)* | *(inherited)* | DateKey, FullDate, calendar/fiscal hierarchies, day/month/week names, format variants, holiday/weekend flags. Identical to V_Dim_Date base columns. (Tier 2 — view DDL) |
| 43 | PartitionID | int | Dim_Date partition identifier — included here but excluded from V_Dim_Date. (Tier 2 — view DDL) |
| 44 | UpdateDate | datetime | Timestamp when the Dim_Date row was last updated. (Tier 2 — view DDL) |
| 45 | IsFirstDayOfMonth | bit/varchar | Flag indicating whether the date is the first day of its month. Static column from Dim_Date. (Tier 2 — view DDL) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Date | Base table (1:1) | Source | Inbound |

---

## 4. ETL & Data Pipeline

No ETL — pass-through view. Used as the source for the ImportFromSynapse pipeline that copies date dimension data from Synapse to the legacy DWH-01 server.

---

## 5. Referenced By

| Object | Usage |
|--------|-------|
| ImportFromSynapse pipeline | Copies Dim_Date from Synapse to legacy DWH-01 |

---

## 6. Business Logic & Patterns

This is a pure pass-through view with no computed columns. Its existence is architectural — it provides a stable interface for the replication pipeline, decoupled from the dynamic temporal logic in V_Dim_Date.

---

## 7. Query Advisory

Straightforward SELECT — no performance concerns. The view returns the same number of rows as Dim_Date.

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [Import Tables From Synapse To DWH](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11895309220) | Documents the replication pipeline that uses this view |
| [DWH Dim_Date, Dim_Range and View V_M2M_Date_DateRange](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12952666154) | Date dimension family documentation |
| [System Transfer Data From Synapse to DWHRep](https://etoro-jira.atlassian.net/wiki/spaces/DBAC/pages/12604604544) | Daily Synapse → DWHRep transfer design (ETL on azr-we-bi-01 / ETL DB) |
| [DataWareHouseChecker: ValidateDWHreadiness](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12952633410) | Mentions Dim_Date date-window checks alongside DWH replication task validation |

---

*Generated: 2026-03-19 | Quality: 7.5/10 (★★★★☆) | Phases: 7/14*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/10, Logic: 7/10, Relationships: 6/10, Sources: 8/10*
*Object: DWH_dbo.V_Dim_Date_For_DWHRep | Type: View | Base Table: DWH_dbo.Dim_Date*
