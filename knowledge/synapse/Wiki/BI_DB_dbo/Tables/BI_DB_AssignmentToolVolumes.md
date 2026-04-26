# BI_DB_dbo.BI_DB_AssignmentToolVolumes

**Schema**: BI_DB_dbo | **UC Target**: _Not_Migrated
**Row count**: ~10.6M total (2019-11-01 → 2026-04-12) | **Refresh**: hourly (SP_H prefix), Priority 0
**Distribution**: ROUND_ROBIN | **Structure**: CLUSTERED INDEX (BeginTimeID ASC)

---

## 1. Business Meaning

Task-level outcome log for the **Assignment Tool** — eToro's internal task management system used by operations teams (KYC, compliance, customer service) to handle customer cases. One row = one task outcome event, recording which agent completed it, which team they belonged to, what outcome was recorded, and when it happened.

Unlike the sibling `BI_DB_AssignmentToolSLAs` table (which tracks SLA compliance), this table focuses on task *volumes* and *outcomes* — it answers "how many tasks did each team/agent complete, and what was the result?" rather than "did they do it within 24 hours?"

The data originates from `External_Assignment_*` staging tables within BI_DB_dbo that receive feeds from the Assignment Tool production system. Historical and current task views are unioned and deduplicated before insert.

---

## 2. Business Logic

### 2.1 ETL Pattern and Date Parameter
The SP runs hourly (SP_H prefix). `@date` is the target date. The SP deletes all rows where `BeginTimeID = @dateID` then inserts fresh from the UNION of historical and current task views filtered to that date.

### 2.2 Deduplication
The SP unions `External_Assignment_History_V_Tasks` and `External_Assignment_Assignment_V_Tasks`, then deduplicates by `(TaskID, Outcome)` keeping `RN=1 ORDER BY BeginTime ASC` — i.e., the earliest outcome event per task-outcome pair is retained.

### 2.3 BeginTimeID Derivation
`BeginTimeID = CONVERT(INT, CONVERT(VARCHAR(8), OutcomeDate, 112))` — a YYYYMMDD integer derived from the `OutcomeDate` field (when the task outcome was recorded). This is the primary partition/delete key, not derived from `BeginTime` despite the column name.

### 2.4 Team Attribution via Manager
`UpdatedByTeamFinal` is derived by looking up the most recent team assignment for each manager: `ManagerID → #finalmanagers → TeamID → Teams.Name`. Two manager-team history tables (current + historical) are unioned and deduplicated by `BeginTime DESC` to find the most recent team.

### 2.5 Agent Name Resolution
`UpdatedByTeamMemberFinal = FirstName + ' ' + LastName` (space separator present — no bug, unlike the related BO_Generated_Compensations table).

---

## 3. Query Advisory

### 3.1 `BeginTimeID` Is Derived from `OutcomeDate`, Not `BeginTime`
Despite the name, `BeginTimeID` is `CONVERT(INT, CONVERT(VARCHAR(8), OutcomeDate, 112))`. Use `BeginTimeID` for date-range filtering (integer range: `20260101`–`20261231`), but understand it reflects the *outcome* date, not the task start date.

### 3.2 `Occurred` Is the Outcome Datetime
`Occurred = OutcomeDate` — the datetime when the task outcome was recorded. `BeginTime` = when the agent began working. Both are present; `Occurred` is the canonical event time.

### 3.3 `UpdatedByTeamMemberFinal` Can Be NULL
If the ManagerID is not found in `External_Assignment_BackOffice_Manager`, the agent name is NULL. Filter `WHERE UpdatedByTeamMemberFinal IS NOT NULL` when aggregating by agent.

### 3.4 `UpdateDate` Is Date Type
`UpdateDate [date]` stores `GETDATE()` truncated to a date. Do not use it for sub-daily timing. It reflects the day the SP ran, typically = the `@date` target day.

### 3.5 `Country` Is Full Name
`Country = Dim_Country.Name` — e.g., "France", "Germany". Not an ISO 3166 code.

---

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| CID | int | Customer ID. Identifies the customer whose case this task relates to. Used to derive Country via Dim_Customer. | Tier 2 — SP code | Platform-standard customer identifier |
| TaskID | bigint | Assignment tool task identifier. Unique identifier for a work item in the Assignment Tool production system. | Tier 2 — SP code | Deduplication key (with Outcome) |
| UpdatedByTeamMemberID | int | Internal ManagerID from the Assignment Tool. The agent who processed the task. | Tier 2 — SP code | Renamed from ManagerID |
| UpdatedByTeamMemberFinal | varchar(100) | Full name of the agent who handled the task (FirstName + ' ' + LastName). NULL if ManagerID not in BackOffice_Manager. | Tier 2 — SP code | Space separator present |
| UpdatedByTeamFinal | varchar(50) | Operations team that handled the task. Derived via ManagerID → most recent team assignment → Teams.Name. | Tier 2 — SP code | Based on most recent team at outcome time |
| Outcome | varchar(50) | Task outcome label from the Assignment Tool outcome dictionary. | Tier 2 — SP code | From External_Assignment_Dictionary_Outcome.Name |
| CreateDate | datetime | Datetime when the task was created in the Assignment Tool. | Tier 2 — SP code | Start anchor for elapsed-time analysis |
| Occurred | datetime | Datetime when the task outcome was recorded (= OutcomeDate from TaskAudit). | Tier 2 — SP code | Canonical event datetime |
| Country | varchar(50) | Full country name of the customer. From Dim_Country.Name via CID → Dim_Customer.CountryID. | Tier 2 — SP code | Full name, not ISO code |
| BeginTime | datetime | Datetime when the assigned agent began working on the task. | Tier 2 — SP code | End anchor for TimeinHr; distinct from Occurred |
| BeginTimeID | int | YYYYMMDD integer derived from OutcomeDate. Primary delete/partition key. | Tier 2 — SP code | CONVERT(INT, CONVERT(VARCHAR(8), OutcomeDate, 112)) — derived from Occurred, not BeginTime |
| UpdateDate | date | Date when this row was written by the SP (GETDATE() truncated to date). | Propagation — ETL metadata | date type, not datetime |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Layer | Role |
|--------|-------|------|
| BI_DB_dbo.External_Assignment_Assignment_TaskAudit | BI_DB External | Task audit — TaskID, OutcomeID, OutcomeDate, ManagerID (current) |
| BI_DB_dbo.External_Assignment_History_V_Tasks | BI_DB External | Historical task view — CID, CreateDate, BeginTime |
| BI_DB_dbo.External_Assignment_Assignment_V_Tasks | BI_DB External | Current task view — same schema as History |
| BI_DB_dbo.External_Assignment_Assignment_Teams | BI_DB External | Team name lookup |
| BI_DB_dbo.External_Assignment_History_ManagerTeam | BI_DB External | Historical manager-team mapping |
| BI_DB_dbo.External_Assignment_Assignment_ManagerTeam | BI_DB External | Current manager-team mapping |
| BI_DB_dbo.External_Assignment_Dictionary_Outcome | BI_DB External | Outcome name dictionary |
| BI_DB_dbo.External_Assignment_BackOffice_Manager | BI_DB External | Agent first/last name |
| DWH_dbo.Dim_Customer | DWH dimension | CID → CountryID lookup |
| DWH_dbo.Dim_Country | DWH dimension | Country full name |

### 5.2 ETL Pipeline

```
External_Assignment_History_ManagerTeam ─┐ most recent team per manager
External_Assignment_Assignment_ManagerTeam─┤ (UNION → dedup by BeginTime DESC)
                                          ↓
                                    #finalmanagers

External_Assignment_Assignment_TaskAudit ─┐ WHERE OutcomeDate=@date
+ External_Assignment_History_V_Tasks    ─┤→ #history_tasks
+ External_Assignment_Assignment_V_Tasks ─┘

#history_tasks UNION → dedup (RN=1 per TaskID,Outcome, earliest BeginTime)
  → #final

#final
  + #finalmanagers + Assignment_Teams   → UpdatedByTeamFinal
  + BackOffice_Manager                  → UpdatedByTeamMemberFinal
  + Dictionary_Outcome                  → Outcome
  + Dim_Customer + Dim_Country          → Country

DELETE WHERE BeginTimeID=@dateID
INSERT INTO BI_DB_AssignmentToolVolumes ← #final
```

---

## 6. Relationships

| Related Table | Join | Notes |
|--------------|------|-------|
| BI_DB_dbo.BI_DB_AssignmentToolSLAs | TaskID or OutcomeDateID | Sibling SLA compliance table — SLAs tracks time-to-complete, Volumes tracks outcome labels |
| BI_DB_dbo.BI_DB_AssignmentToolBacklog | TaskID | Backlog table tracks open/pending tasks; Volumes tracks completed outcomes |
| DWH_dbo.Dim_Customer | CID | Customer details |
| DWH_dbo.Dim_Country | Country (name match) | Country metadata if joining by name |

---

## 7. Sample Queries

**Task volumes by team and outcome for a date range**
```sql
SELECT
    UpdatedByTeamFinal,
    Outcome,
    COUNT(*) task_count
FROM BI_DB_dbo.BI_DB_AssignmentToolVolumes
WHERE BeginTimeID BETWEEN 20260401 AND 20260430
GROUP BY UpdatedByTeamFinal, Outcome
ORDER BY task_count DESC
```

**Daily volume trend by team**
```sql
SELECT
    BeginTimeID,
    UpdatedByTeamFinal,
    COUNT(*) tasks_completed
FROM BI_DB_dbo.BI_DB_AssignmentToolVolumes
WHERE BeginTimeID >= 20260301
GROUP BY BeginTimeID, UpdatedByTeamFinal
ORDER BY BeginTimeID, tasks_completed DESC
```

**Agent productivity for a specific date**
```sql
SELECT
    UpdatedByTeamFinal,
    UpdatedByTeamMemberFinal,
    COUNT(*) tasks,
    COUNT(DISTINCT CID) unique_customers
FROM BI_DB_dbo.BI_DB_AssignmentToolVolumes
WHERE BeginTimeID = 20260420
  AND UpdatedByTeamMemberFinal IS NOT NULL
GROUP BY UpdatedByTeamFinal, UpdatedByTeamMemberFinal
ORDER BY tasks DESC
```

---

## 8. Atlassian / Change History

| Reference | Date | Author | Change |
|-----------|------|--------|--------|
| Original | 2020-02-16 | Pavlina Masoura | Initial creation — Assignment Tool task volume tracking |
