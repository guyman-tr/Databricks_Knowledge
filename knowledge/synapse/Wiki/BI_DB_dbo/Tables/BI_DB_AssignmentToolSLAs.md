# BI_DB_dbo.BI_DB_AssignmentToolSLAs

**Schema**: BI_DB_dbo | **UC Target**: _Not_Migrated
**Row count**: ~4.97M total (2022-05-19 → 2026-04-13) | **Refresh**: daily (Hourly SP), Priority 0
**Distribution**: ROUND_ROBIN | **Structure**: HEAP

---

## 1. Business Meaning

Daily SLA compliance report for the **Assignment Tool** — eToro's internal task management system used by operations teams (KYC, compliance, customer service) to handle customer cases. One row = one task that was completed (had an outcome recorded) on a given day.

For each completed task, the table records the time elapsed from task creation to agent pickup (`TimeinHr`), whether that time was within the 24-hour SLA (`SLA`), the team and agent responsible, the customer's country, and escalation SLA details where applicable.

Covers 9 operations teams: Philippines (35%), Cyprus (16%), KYC (14%), Romania (12%), Ukraine (9%), Israel (6%), USA (4%), Singapore (3%), China (<1%). SLA compliance rate: ~91%.

The data originates from `External_Assignment_*` staging tables within BI_DB_dbo that receive feeds from the Assignment Tool production system.

---

## 2. Business Logic

### 2.1 ETL Pattern and Date Parameter
The SP runs daily (SP_H prefix = Hourly scheduler, runs daily in practice). `@StartDate` is the target date. The SP deletes all rows where `OutcomeDateID = @StartDateID` then inserts fresh. One day's data is replaced per run.

### 2.2 SLA Definition
`SLA = 1` when `TimeinHr ≤ 24` (task completed within 24 hours of creation). `SLA = 0` when the task exceeded 24 hours. `TimeinHr = DATEDIFF(hour, CreateDate, BeginTime)` — time from task creation to the agent beginning work (not to task completion).

### 2.3 Escalation SLA
Some tasks are escalated (OutcomeID=3). For these, the SP computes `TimeFromEscalation = DATEDIFF(HOUR, EscalationTime, OutcomeDate)` and `SLA_Escalation = 1` if the escalation was resolved within 24 hours of the escalation event. Both are NULL for non-escalated tasks.

### 2.4 Team Attribution via Manager
Team is derived by looking up the most recent team assignment for each manager: `ManagerID → #finalmanagers → TeamID → Teams.Name`. Two manager-team history tables are unioned to cover historical and current assignments.

### 2.5 Deduplication
The SP unions historical and current task views and deduplicates by (TaskID, OutcomeID) keeping the earliest BeginTime (`row_number() PARTITION BY TaskID, OutcomeID ORDER BY BeginTime ASC WHERE RN=1`). The `RN` column in the output table is always 1 — it is a dedup artifact from this process.

### 2.6 Dead Column: `Include`
The `Include` column exists in the DDL but is NOT in the SP INSERT statement. It is always NULL in production.

---

## 3. Query Advisory

### 3.1 `SLA` and `SLA_Escalation` Store Integers 0/1
Despite the SP using string literals ('1'/'0') in the CASE expression, the DDL type is int — Synapse implicitly converts. Filter with `SLA = 1` (integer), not `SLA = '1'` (string).

### 3.2 `Country` Is Full Name, Not ISO Code
`Country` = `Dim_Country.Name` — e.g., "France", "United States", "United Kingdom". It is NOT an ISO 3166 two-letter code. Use the name for display; join to Dim_Country on Name if an ISO code is needed.

### 3.3 `Include` Column Is Always NULL
Do not reference `Include` — it is never populated. Skip it in SELECT *.

### 3.4 `UpdateDate` Is Date Type (No Time)
`UpdateDate [date]` truncates the GETDATE() to a date. Do not use it to track exact execution time. The date reflects the day the SP ran, which is typically `@StartDate + 1`.

### 3.5 `UptadedByName` Typo
Column name is `UptadedByName` (not `UpdatedByName`). This is the production column name — use it exactly. Agent name is `NULL` when the ManagerID is not in `DWH_dbo.Dim_Manager`.

### 3.6 `RN` Is Always 1
The `RN` column reflects the post-dedup row number and is always 1. It has no analytical value.

---

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| TaskID | bigint | Assignment tool task identifier. Unique identifier for a work item in the Assignment Tool production system. | Tier 2 — SP code | Primary key of the assignment task |
| GCID | int | Secondary customer or group identifier from the Assignment Tool system. Related to CID but distinct — populated from External_Assignment task views. | Tier 2 — SP code | Meaning in the Assignment Tool system may differ from CID |
| CID | int | Customer ID (RealCID equivalent). Identifies the customer whose case this task relates to. Joined to DWH_dbo.Dim_Customer to derive Country. | Tier 2 — SP code | Platform-standard customer identifier |
| CreateDate | datetime | Datetime when the task was created in the Assignment Tool. Start anchor for TimeinHr calculation. | Tier 2 — SP code | |
| BeginTime | datetime | Datetime when the assigned agent began working on the task (outcome start time). End anchor for TimeinHr calculation. | Tier 2 — SP code | |
| Priority | int | Task priority value from the Assignment Tool. Higher values indicate higher urgency. | Tier 2 — SP code | Values observed: 11, 13 in sample |
| Team | varchar(50) | Operations team that handled the task. Derived via ManagerID → most recent team assignment. | Tier 2 — SP code | 9 teams: Philippines (35%), Cyprus (16%), KYC (14%), Romania (12%), Ukraine (9%), Israel (6%), USA (4%), Singapore (3%), China (<1%) |
| TimeinHr | int | Hours elapsed from task creation to agent begin: DATEDIFF(hour, CreateDate, BeginTime). The core SLA measurement. | Tier 2 — SP code | Used to compute SLA column |
| SLA | int | SLA compliance flag. 1 = task completed within 24 hours (TimeinHr ≤ 24), 0 = SLA breached. ~91% of rows are SLA=1. | Tier 2 — SP code | DDL type int; SP derives from varchar CASE literals via implicit conversion |
| Country | varchar(50) | Full country name of the customer (e.g., 'France', 'United States'). From Dim_Country.Name via CID → Dim_Customer.CountryID. | Tier 2 — SP code | Full name, NOT ISO code. See Query Advisory 3.2 |
| RiskGroupID | int | Country-level risk group classification. From Dim_Country.RiskGroupID via customer's country. | Tier 2 — SP code | |
| UptadedByName | varchar(50) | Full name of the agent/manager who handled the task (FirstName + ' ' + LastName from Dim_Manager). NULL if ManagerID not in Dim_Manager. | Tier 2 — SP code | Column name has typo: "Uptaded" (should be "Updated") — use exact spelling |
| Outcome | varchar(50) | Task outcome label from the Assignment Tool outcome dictionary. E.g., 'Docs verified'. NULL if OutcomeID not found. | Tier 2 — SP code | From External_Assignment_Dictionary_Outcome.Name |
| TimeFromEscalation | int | For escalated tasks: hours from escalation event to outcome. DATEDIFF(HOUR, EscalationTime, OutcomeDate). NULL for non-escalated tasks. | Tier 2 — SP code | Only populated when TaskIDEscalated='Yes' |
| SLA_Escalation | int | For escalated tasks: 1 if escalation resolved within 24 hours of escalation event, 0 otherwise. NULL for non-escalated tasks. | Tier 2 — SP code | Only populated when TaskIDEscalated='Yes' |
| TaskIDEscalated | varchar(50) | Whether this task was escalated. 'Yes' if task appears in escalation history (OutcomeID=3), 'No' otherwise. | Tier 2 — SP code | |
| Include | varchar(50) | Always NULL — column exists in DDL but is not populated by the writer SP. Dead column. | Tier 2 — SP code | Do not use |
| RN | int | Deduplication artifact. Always 1 in production output — the SP inserts only RN=1 rows after deduplicating by (TaskID, OutcomeID) within BeginTime order. | Tier 2 — SP code | No analytical value |
| UpdateDate | date | Date when this row was written by the SP (GETDATE() truncated to date). Typically @StartDate + 1 day. | Propagation — ETL metadata | date type, not datetime — time component is lost |
| OutcomeDateID | int | YYYYMMDD integer representation of OutcomeDate. Primary partition/delete key. | Tier 2 — SP code | |
| OutcomeDate | datetime | Datetime when the task outcome was recorded in the Assignment Tool. | Tier 2 — SP code | Also the basis for @StartDate filtering |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Layer | Role |
|--------|-------|------|
| BI_DB_dbo.External_Assignment_Assignment_TaskAudit | BI_DB External | Task audit — TaskID, OutcomeID, OutcomeDate, ManagerID (current) |
| BI_DB_dbo.External_Assignment_History_V_Tasks | BI_DB External | Historical task view — GCID, CID, timestamps, Priority |
| BI_DB_dbo.External_Assignment_Assignment_V_Tasks | BI_DB External | Current task view — same schema as History |
| BI_DB_dbo.External_Assignment_Assignment_Teams | BI_DB External | Team name lookup |
| BI_DB_dbo.External_Assignment_History_ManagerTeam | BI_DB External | Historical manager-team mapping |
| BI_DB_dbo.External_Assignment_Assignment_ManagerTeam | BI_DB External | Current manager-team mapping |
| BI_DB_dbo.External_Assignment_Dictionary_Outcome | BI_DB External | Outcome name dictionary |
| DWH_dbo.Dim_Customer | DWH dimension | CID → CountryID lookup |
| DWH_dbo.Dim_Country | DWH dimension | Country name and RiskGroupID |
| DWH_dbo.Dim_Manager | DWH dimension | Agent/manager full name |

### 5.2 ETL Pipeline

```
External_Assignment_History_ManagerTeam ─┐ most recent team per manager
External_Assignment_Assignment_ManagerTeam─┤ (UNION → dedup by BeginTime DESC)
                                          ↓
                                    #finalmanagers
External_Assignment_Assignment_TaskAudit ─┐ WHERE OutcomeDate=@StartDate
+ External_Assignment_History_V_Tasks    ─┤→ #history_all
+ #finalmanagers + Assignment_Teams      ─┘

External_Assignment_Assignment_TaskAudit ─┐ WHERE OutcomeDate=@StartDate
+ External_Assignment_Assignment_V_Tasks ─┤→ #current_all
+ #finalmanagers + Assignment_Teams      ─┘

#history_all UNION #current_all → #all
  → dedup (RN=1 per TaskID,OutcomeID, earliest BeginTime) → #history

#history WHERE OutcomeID=3 → #escalationsSLA → #SLAescfinal

#history
  + Dim_Customer + Dim_Country → Country, RiskGroupID
  + Dim_Manager → UptadedByName
  + Dictionary_Outcome → Outcome
  + #SLAescfinal → TimeFromEscalation, SLA_Escalation, TaskIDEscalated
  + SLA CASE computation
  → #final

DELETE WHERE OutcomeDateID=@StartDateID
INSERT INTO BI_DB_AssignmentToolSLAs ← #final
```

---

## 6. Relationships

| Related Table | Join | Notes |
|--------------|------|-------|
| BI_DB_dbo.BI_DB_AssignmentToolBacklog | OutcomeDateID or TaskID | Companion table tracking open/pending tasks; SLAs tracks completed |
| BI_DB_dbo.BI_DB_AssignmentToolTasks | TaskID | Detailed task-level data (separate table) |
| DWH_dbo.Dim_Customer | CID | Customer details |
| DWH_dbo.Dim_Country | Country (name match) | Country metadata if joining by name |

---

## 7. Sample Queries

**SLA compliance by team for a date range**
```sql
SELECT
    Team,
    SUM(1) total_tasks,
    SUM(SLA) within_sla,
    100.0 * SUM(SLA) / SUM(1) pct_within_sla,
    AVG(CAST(TimeinHr AS FLOAT)) avg_time_hr
FROM BI_DB_dbo.BI_DB_AssignmentToolSLAs
WHERE OutcomeDateID BETWEEN 20260401 AND 20260430
GROUP BY Team
ORDER BY total_tasks DESC
```

**Daily SLA trend**
```sql
SELECT
    OutcomeDate,
    SUM(1) tasks,
    SUM(SLA) within_sla,
    100.0 * SUM(SLA) / SUM(1) sla_pct
FROM BI_DB_dbo.BI_DB_AssignmentToolSLAs
WHERE OutcomeDateID >= 20260301
GROUP BY OutcomeDate
ORDER BY OutcomeDate
```

**Escalated tasks analysis**
```sql
SELECT
    Team,
    SUM(CASE WHEN TaskIDEscalated = 'Yes' THEN 1 ELSE 0 END) escalated,
    SUM(CASE WHEN TaskIDEscalated = 'Yes' THEN SLA_Escalation ELSE 0 END) esc_within_sla,
    SUM(1) total
FROM BI_DB_dbo.BI_DB_AssignmentToolSLAs
WHERE OutcomeDateID >= 20260101
GROUP BY Team
ORDER BY escalated DESC
```

---

## 8. Atlassian / Change History

| Reference | Date | Author | Change |
|-----------|------|--------|--------|
| Original | 2021-05-11 | Pavlina Masoura | Initial creation — Assignment Tool SLA per team/agent |
| — | 2021-05-18 | Pavlina Masoura | Added UpdateDate (table and SP) |
| — | 2021-07-20 | Pavlina Masoura | Case handling for null/empty UpdatedByTeamID |
| — | 2022-05-18 | Pavlina Masoura | New tables for teams and managers — External_Assignment_Assignment_* sources added |
