# BI_DB_dbo.BI_DB_AssignmentToolTasks

**Schema**: BI_DB_dbo | **UC Target**: _Not_Migrated
**Row count**: ~190K (rolling ~1-2 month snapshot) | **Refresh**: daily full reload (Hourly SP), Priority 0
**Distribution**: ROUND_ROBIN | **Structure**: HEAP

---

## 1. Business Meaning

Current-state rolling snapshot of tasks in the **Assignment Tool** — eToro's internal case management system used by operations teams to process customer KYC, compliance, and support cases. One row = one task created in the last ~2 months.

Unlike the companion table `BI_DB_AssignmentToolSLAs` (historical daily log), this table is a **full-replace snapshot**: every run truncates and reloads with the latest state of recent tasks. It captures both **open** (IsActive=1, ~8.4%) and **closed** (IsActive=0, ~91.6%) tasks, including current assignments, outcomes, and agent assignments.

The rolling window covers tasks created since the first day of the previous calendar month, so the table always reflects approximately 1-2 months of task history with current status.

Teams covered: Philippines (18%), Romania (6%), Cyprus (4.5%), USA (3.3%), Singapore (2.6%), Israel (1.6%); 65% of rows have NULL team (assignee not found in team mapping).

---

## 2. Business Logic

### 2.1 Full-Replace Pattern (No Date Parameter)
The SP `SP_H_AssignmentToolTasks` takes **no parameters**. Every execution runs `TRUNCATE TABLE` then reloads all tasks matching the rolling date filter. This means:
- All rows in the table share the same `UpdateDate` (one SP run = one batch)
- `ID IDENTITY(1,1)` auto-increments from 1 on each reload — IDs are **not stable** across runs
- The table shows current state, not history

### 2.2 Rolling Date Window
Population filter: `v.CreateDate >= DATEFROMPARTS(YEAR(DATEADD(MONTH,-1,GETDATE())), MONTH(DATEADD(MONTH,-1,GETDATE())), 1)` — this is the first day of the previous month. Older tasks fall out of the table when the month changes.

### 2.3 Active vs Closed Tasks
`IsActive=1` means the task is still open (agent is working on it). `EndTime = '9999-12-31'` is a sentinel value used by the Assignment Tool for tasks without a resolved end date.

### 2.4 Team Attribution
Team is derived via: `AssigneeID → #finalmanagers (most recent team per manager) → Assignment_Teams.Name`. If `AssigneeID IS NULL`, Team = 'Unassigned'. If AssigneeID is set but not found in the team mapping, Team = NULL. The opaque `TeamID` column stores the raw hash identifier from the source system.

### 2.5 Manager Attribution
`Manager = FirstName + ' ' + LastName` from `External_Assignment_BackOffice_Manager`, joined on `AssigneeID`. Note: this uses the `BackOffice_Manager` table, not `DWH_dbo.Dim_Manager` (which is used by the SLAs SP).

### 2.6 Regulation From Customer Snapshot
`Regulation` is derived from `DWH_dbo.Dim_Customer.RegulationID` — the customer's regulation **at the time of the SP run** (not at task creation). This could differ from the regulation at task creation if the customer changed regulation.

---

## 3. Query Advisory

### 3.1 `ID` Is Not a Stable Key
The IDENTITY column resets on each TRUNCATE+reload. Do not use `ID` for cross-run joins or as a stable reference. Use `TaskID` instead.

### 3.2 `EndTime = '9999-12-31'` for Open Tasks
Active tasks use `EndTime = date '9999-12-31'` as a sentinel. Filter `EndTime < '9999-01-01'` to get only completed tasks, or use `IsActive = 0`.

### 3.3 `TeamID` and `UpdatedByTeamId` Are Hash Codes
These columns store opaque system identifiers (e.g., "03rdcrjn0z3xt0g"), not human-readable names. Use `Team` for the readable team name.

### 3.4 65% of Rows Have NULL `Team`
Team is NULL when the AssigneeID is set but not found in the current manager-team mapping. `IsActive=1` tasks waiting for assignment show NULL team. This is expected behavior.

### 3.5 `Country` Is Full Name, Not ISO Code
`Country = Dim_Country.Name` — full country name (e.g., 'Australia', 'Italy'). NOT an ISO 3166 code.

### 3.6 This Is a Current Snapshot, Not History
For historical SLA analysis, use `BI_DB_AssignmentToolSLAs` instead. This table only covers the rolling 1-2 month window and overwrites on each run.

---

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| ID | int IDENTITY | Auto-generated row ID. Resets on each full reload — not a stable identifier across SP runs. | Tier 2 — SP code | Use TaskID as stable key |
| TaskID | bigint | Assignment tool task identifier. Unique identifier for a work item in the Assignment Tool system. | Tier 2 — SP code | Stable across reloads (unlike ID) |
| TaskType | int | Integer type classification for the task. Distinguishes different categories of assignment tool work items. | Tier 2 — SP code | |
| GCID | int | Secondary customer or group identifier from the Assignment Tool system. Related to but distinct from CID. | Tier 2 — SP code | |
| CID | int | Customer ID (RealCID equivalent). Customer whose case this task relates to. Used for DWH dimension joins. | Tier 2 — SP code | |
| CreateDate | date | Date when the task was created in the Assignment Tool. | Tier 2 — SP code | date type, not datetime — no time component |
| Priority | int | Task priority from the Assignment Tool. Higher values indicate higher urgency. | Tier 2 — SP code | |
| TeamID | varchar(max) | Raw hash/code team identifier from the Assignment Tool source system (e.g., "03rdcrjn0z3xt0g"). Opaque — use `Team` for human-readable name. | Tier 2 — SP code | NOT the team name |
| Outcome | varchar(max) | Task outcome label. From External_Assignment_Dictionary_Outcome. E.g., 'Docs verified', 'Cancelled', 'Pending client response'. NULL if no outcome. | Tier 2 — SP code | |
| OutcomeReason | varchar(max) | Sub-reason for the task outcome. From External_Assignment_Dictionary_OutcomeReason. E.g., 'SP email sent'. NULL if no reason. | Tier 2 — SP code | |
| IsActive | int | Task status flag. 1 = task is currently open/active, 0 = task completed or closed. ~8.4% of rows are active. | Tier 2 — SP code | |
| BeginTime | date | Date when the assigned agent began working on the task. NULL if not yet started. | Tier 2 — SP code | date type — day granularity only |
| EndTime | date | Date when the task was completed. '9999-12-31' sentinel for active/open tasks. | Tier 2 — SP code | See Query Advisory 3.2 |
| Escalation2CY | date | Date when the task was escalated to CY (Cyprus team). NULL if not escalated. | Tier 2 — SP code | |
| UpdatedByTeamId | varchar(max) | Raw hash/code identifier for the team that last updated the task. Same opaque format as TeamID. | Tier 2 — SP code | Opaque identifier |
| Country | varchar(max) | Full country name of the customer (e.g., 'Australia', 'United Kingdom'). From Dim_Country.Name via CID → Dim_Customer.CountryID. | Tier 2 — SP code | Full name, NOT ISO code. See Query Advisory 3.5 |
| RiskGroupID | int | Country-level risk group classification from Dim_Country.RiskGroupID. | Tier 2 — SP code | |
| Manager | varchar(max) | Full name of the assigned agent (FirstName + ' ' + LastName from External_Assignment_BackOffice_Manager). NULL if not assigned or name not found. | Tier 2 — SP code | Different source than SLAs table (BackOffice_Manager vs Dim_Manager) |
| Team | varchar(max) | Human-readable operations team name. 'Unassigned' if no AssigneeID. NULL if AssigneeID assigned but not found in team mapping. | Tier 2 — SP code | 65% NULL; Philippines (18%), Romania (6%), Cyprus (4.5%), USA (3.3%), Singapore (2.6%), Israel (1.6%) |
| Regulation | varchar(max) | Customer's current regulation (as of SP run time). From Dim_Regulation.Name via Dim_Customer.RegulationID. | Tier 1 — DWH_dbo.Dim_Regulation wiki | Short code for the regulation. Values match production Dictionary.Regulation.Name. May differ from regulation at task creation. |
| UpdateDate | datetime | SP execution timestamp (GETDATE()). All rows in a given load share the same value — useful to identify the last reload time. | Propagation — ETL metadata | datetime type (unlike SLAs table which uses date) |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Layer | Role |
|--------|-------|------|
| BI_DB_dbo.External_Assignment_Assignment_V_Tasks | BI_DB External | Primary task snapshot — all task fields, current state |
| BI_DB_dbo.External_Assignment_BackOffice_Manager | BI_DB External | Agent name lookup (AssigneeID → FirstName, LastName) |
| BI_DB_dbo.External_Assignment_Dictionary_Outcome | BI_DB External | Outcome name dictionary |
| BI_DB_dbo.External_Assignment_Dictionary_OutcomeReason | BI_DB External | Outcome reason dictionary |
| BI_DB_dbo.External_Assignment_Assignment_ManagerTeam | BI_DB External | Current manager-team mapping |
| BI_DB_dbo.External_Assignment_History_ManagerTeam | BI_DB External | Historical manager-team mapping |
| BI_DB_dbo.External_Assignment_Assignment_Teams | BI_DB External | Team name lookup |
| DWH_dbo.Dim_Customer | DWH dimension | CID → RegulationID + CountryID |
| DWH_dbo.Dim_Regulation | DWH dimension | Regulation name |
| DWH_dbo.Dim_Country | DWH dimension | Country full name + RiskGroupID |

### 5.2 ETL Pipeline

```
External_Assignment_Assignment_ManagerTeam ─┐ most recent team per manager
External_Assignment_History_ManagerTeam    ─┤ (UNION → dedup)
                                            ↓
                                      #finalmanagers

External_Assignment_Assignment_V_Tasks ─┐ WHERE CreateDate >= first of prev month
+ BackOffice_Manager (AssigneeID)       ─┤ → FirstName, LastName
+ Dictionary_Outcome (OutcomeID)        ─┤ → Outcome name
+ Dictionary_OutcomeReason              ─┘ → OutcomeReason name
                                            ↓
                                        #FINAL

#FINAL
+ DWH_dbo.Dim_Customer (INNER JOIN on CID) → RegulationID, CountryID
+ DWH_dbo.Dim_Regulation → Regulation
+ DWH_dbo.Dim_Country → Country, RiskGroupID
+ #finalmanagers + Assignment_Teams → Team name
                                            ↓
                                        #final1

TRUNCATE TABLE BI_DB_AssignmentToolTasks
INSERT INTO BI_DB_AssignmentToolTasks ← #final1
```

---

## 6. Relationships

| Related Table | Join | Notes |
|--------------|------|-------|
| BI_DB_dbo.BI_DB_AssignmentToolSLAs | TaskID | Companion SLA table — historical daily completed tasks with SLA metrics |
| BI_DB_dbo.BI_DB_AssignmentToolBacklog | TaskID / CID | Backlog status tracking |
| DWH_dbo.Dim_Customer | CID | Customer details |
| DWH_dbo.Dim_Regulation | Regulation (name match) | Regulation metadata |

---

## 7. Sample Queries

**Open tasks by team (current snapshot)**
```sql
SELECT
    Team,
    Regulation,
    Priority,
    SUM(1) open_tasks
FROM BI_DB_dbo.BI_DB_AssignmentToolTasks
WHERE IsActive = 1
GROUP BY Team, Regulation, Priority
ORDER BY open_tasks DESC
```

**Tasks by outcome for recent month**
```sql
SELECT
    Outcome,
    OutcomeReason,
    Team,
    SUM(1) cnt
FROM BI_DB_dbo.BI_DB_AssignmentToolTasks
WHERE IsActive = 0
  AND EndTime < '9999-01-01'
GROUP BY Outcome, OutcomeReason, Team
ORDER BY cnt DESC
```

**Agent workload (last snapshot)**
```sql
SELECT
    Manager,
    Team,
    SUM(IsActive) active_tasks,
    SUM(CASE WHEN IsActive=0 THEN 1 ELSE 0 END) closed_tasks
FROM BI_DB_dbo.BI_DB_AssignmentToolTasks
WHERE Manager IS NOT NULL
GROUP BY Manager, Team
ORDER BY active_tasks DESC
```

---

## 8. Atlassian / Change History

| Reference | Date | Author | Change |
|-----------|------|--------|--------|
| Original | 2022-05-21 | Pavlina Masoura | Created to replace custom query in Tableau report (reports.etorocorp.com/#/workbooks/4402/views) |
