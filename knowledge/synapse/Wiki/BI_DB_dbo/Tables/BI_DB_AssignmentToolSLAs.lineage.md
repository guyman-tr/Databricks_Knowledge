# Column Lineage — BI_DB_dbo.BI_DB_AssignmentToolSLAs
<!-- batch 61 | 2026-04-23 -->

**Writer SP**: `BI_DB_dbo.SP_H_AssignmentToolSLAs` (Priority 0 — Hourly SQL)
**ETL Pattern**: DELETE-INSERT by OutcomeDateID (daily, per processing date)
**Population Filter**: Tasks whose `OutcomeDate = @StartDate` from External_Assignment tables. All operations teams.

---

## Source Tables

| Source | Layer | Role |
|--------|-------|------|
| BI_DB_dbo.External_Assignment_Assignment_TaskAudit | BI_DB External | Task audit log — TaskID, OutcomeID, OutcomeDate, ManagerID |
| BI_DB_dbo.External_Assignment_History_V_Tasks | BI_DB External/View | Historical task details — GCID, CID, CreateDate, BeginTime, EndTime, Priority, OutcomeReasonID |
| BI_DB_dbo.External_Assignment_Assignment_V_Tasks | BI_DB External/View | Current task details — same schema as History_V_Tasks |
| BI_DB_dbo.External_Assignment_Assignment_Teams | BI_DB External | Team name lookup — TeamID → Name |
| BI_DB_dbo.External_Assignment_History_ManagerTeam | BI_DB External | Historical manager-team mapping — ManagerID → TeamID |
| BI_DB_dbo.External_Assignment_Assignment_ManagerTeam | BI_DB External | Current manager-team mapping — ManagerID → TeamID |
| BI_DB_dbo.External_Assignment_Dictionary_Outcome | BI_DB External | Outcome name lookup — OutcomeID → Name |
| DWH_dbo.Dim_Customer | DWH dimension | CountryID lookup via CID = RealCID |
| DWH_dbo.Dim_Country | DWH dimension | Country name and RiskGroupID via CountryID |
| DWH_dbo.Dim_Manager | DWH dimension | Agent full name via ManagerID |

---

## Column-Level Lineage

### A. Task Identity (3 columns)

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| TaskID | External_Assignment_Assignment_TaskAudit | TaskID | Direct. Assignment tool task identifier (bigint) |
| GCID | External_Assignment V_Tasks (h1) | GCID | Direct. Secondary customer/group identifier from the Assignment Tool system |
| CID | External_Assignment V_Tasks (h1) | CID | Direct. Standard customer ID (RealCID). Joined to Dim_Customer for country lookup |

### B. Timestamps (3 columns)

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| CreateDate | External_Assignment V_Tasks (h1) | CreateDate | Direct. Task creation datetime |
| BeginTime | External_Assignment V_Tasks (h1) | BeginTime | Direct. Datetime when the agent began working on the task (outcome start time) |
| OutcomeDate | External_Assignment_Assignment_TaskAudit (ta) | OutcomeDate | Direct. Datetime when the task outcome was recorded |

### C. SLA Calculation (4 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| TimeinHr | computed (CreateDate, BeginTime) | DATEDIFF(hour, CreateDate, BeginTime) — hours elapsed from task creation to agent begin. DDL type int. |
| SLA | computed (TimeinHr) | CASE WHEN DATEDIFF(HOUR, CreateDate, BeginTime) ≤ 24 THEN '1' ELSE '0' END — implicit convert to int. '1'=within SLA, '0'=breach |
| TimeFromEscalation | computed (#escalationsSLA, OutcomeDate) | DATEDIFF(HOUR, EscalationTime, OutcomeDate) for tasks with OutcomeID=3 escalation. NULL if not escalated |
| SLA_Escalation | computed (EscalationTime, BeginTime) | CASE WHEN DATEDIFF(HOUR, EscalationTime, BeginTime) ≤ 24 THEN '1' ELSE '0' END. NULL if not escalated |

### D. Team & Assignment Context (5 columns)

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| Priority | External_Assignment V_Tasks (h1) | Priority | Direct. Task priority integer |
| Team | External_Assignment_Assignment_Teams (teams1) | Name | Via ManagerID → #finalmanagers (most recent team per manager) → TeamID → Teams.Name |
| UptadedByName | DWH_dbo.Dim_Manager (dm) | FirstName + LastName | dm.FirstName + ' ' + dm.LastName. LEFT JOIN — NULL if manager not in Dim_Manager. Column name has typo ("Uptaded" = "Updated") |
| Outcome | External_Assignment_Dictionary_Outcome (outcome) | Name | LEFT JOIN on OutcomeID. Task outcome label (e.g., 'Docs verified') |
| TaskIDEscalated | computed (#SLAescfinal) | TaskID existence | CASE WHEN slae.TaskID IS NOT NULL THEN 'Yes' ELSE 'No' END |

### E. Customer Geography (2 columns)

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| Country | DWH_dbo.Dim_Country (dc1) | Name | Full country name (e.g., 'France', 'United States'). NOT ISO abbreviation. Via CID → Dim_Customer.CountryID → Dim_Country |
| RiskGroupID | DWH_dbo.Dim_Country (dc1) | RiskGroupID | Direct. Country-level risk group classification integer |

### F. Dead / Metadata Columns (4 columns)

| BI_DB Column | DDL Type | Status | Notes |
|-------------|----------|--------|-------|
| Include | varchar(50) | Always NULL — not in SP INSERT list | Column exists in DDL but SP never populates it. Always NULL in production |
| RN | int | Dedup artifact — always 1 | row_number() over (PARTITION BY TaskID, OutcomeID ORDER BY BeginTime ASC). SP deduplicates before inserting; output is always RN=1 |
| OutcomeDateID | int | SP computed | CAST(CONVERT(VARCHAR(8), OutcomeDate, 112) AS INT) — YYYYMMDD integer. Used as DELETE filter |
| UpdateDate | date | ETL timestamp | GETDATE() at SP execution, stored as date type (time component truncated) |

---

## ETL Flow Diagram

```
External_Assignment_History_ManagerTeam ─┐
External_Assignment_Assignment_ManagerTeam─┤ most recent team per manager
                                          ↓
                                    #finalmanagers (ManagerID → TeamID)
                                          ↓ (JOINed in both branches)
External_Assignment_Assignment_TaskAudit ─┐
External_Assignment_History_V_Tasks      ─┤ → #history_all (WHERE OutcomeDate = @StartDate)
External_Assignment_Assignment_Teams     ─┘

External_Assignment_Assignment_TaskAudit ─┐
External_Assignment_Assignment_V_Tasks   ─┤ → #current_all (WHERE OutcomeDate = @StartDate)
External_Assignment_Assignment_Teams     ─┘
                   ↓ (UNION)
              #all → dedup → #history (RN=1 per TaskID, OutcomeID)
                   ↓
              #escalationsSLA (OutcomeID=3 tasks → EscalationTime)
              #SLAescfinal (TimeFromEscalation, SLA_Escalation)
                   ↓
DWH_dbo.Dim_Customer + Dim_Country → Country, RiskGroupID
DWH_dbo.Dim_Manager → UptadedByName
External_Assignment_Dictionary_Outcome → Outcome name
                   ↓
              #final (all columns assembled + SLA calculation)
                   ↓
DELETE WHERE OutcomeDateID = @StartDateID
INSERT INTO BI_DB_AssignmentToolSLAs ← #final
```
