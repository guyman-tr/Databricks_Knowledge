# Column Lineage — BI_DB_dbo.BI_DB_AssignmentToolTasks
<!-- batch 61 | 2026-04-23 -->

**Writer SP**: `BI_DB_dbo.SP_H_AssignmentToolTasks` (Priority 0 — Hourly SQL, no parameters)
**ETL Pattern**: TRUNCATE TABLE + INSERT (full reload every run — no date parameter)
**Population Filter**: Tasks with `CreateDate >= first day of previous calendar month` from `External_Assignment_Assignment_V_Tasks`. Rolling ~1-2 month window.

---

## Source Tables

| Source | Layer | Role |
|--------|-------|------|
| BI_DB_dbo.External_Assignment_Assignment_V_Tasks | BI_DB External/View | Current task snapshot — TaskID, TaskType, GCID, CID, AssigneeID, CreateDate, Priority, TeamID, OutcomeID, OutcomeReasonID, IsActive, BeginTime, EndTime, Escalation2CY, UpdatedByTeamId |
| BI_DB_dbo.External_Assignment_BackOffice_Manager | BI_DB External | Agent/manager name lookup — ManagerID → FirstName, LastName |
| BI_DB_dbo.External_Assignment_Dictionary_Outcome | BI_DB External | Outcome name lookup — OutcomeID → Name |
| BI_DB_dbo.External_Assignment_Dictionary_OutcomeReason | BI_DB External | Outcome reason name lookup — OutcomeReasonID → Name |
| BI_DB_dbo.External_Assignment_Assignment_ManagerTeam | BI_DB External | Current manager-team mapping |
| BI_DB_dbo.External_Assignment_History_ManagerTeam | BI_DB External | Historical manager-team mapping |
| BI_DB_dbo.External_Assignment_Assignment_Teams | BI_DB External | Team name lookup — TeamID → Name |
| DWH_dbo.Dim_Customer | DWH dimension | RegulationID and CountryID lookup via CID = RealCID |
| DWH_dbo.Dim_Regulation | DWH dimension | Regulation name via RegulationID |
| DWH_dbo.Dim_Country | DWH dimension | Country full name and RiskGroupID via CountryID |

---

## Column-Level Lineage

### A. System Key (1 column)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| ID | IDENTITY(1,1) | Auto-generated on each INSERT. Resets meaningfully on TRUNCATE+reload — IDs are NOT stable across SP runs. |

### B. Task Identity & Dates (6 columns)

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| TaskID | External_Assignment_Assignment_V_Tasks (v) | TaskID | Direct. Assignment tool task identifier |
| TaskType | External_Assignment_Assignment_V_Tasks (v) | TaskType | Direct. Integer type classification of the task |
| GCID | External_Assignment_Assignment_V_Tasks (v) | GCID | Direct. Secondary customer/group identifier from Assignment Tool |
| CID | External_Assignment_Assignment_V_Tasks (v) | CID | Direct. Customer ID (RealCID equivalent). Used for Dim_Customer join |
| CreateDate | External_Assignment_Assignment_V_Tasks (v) | CreateDate | Direct. Task creation date (date type, not datetime) |
| Priority | External_Assignment_Assignment_V_Tasks (v) | Priority | Direct. Task priority integer |

### C. Task Status & Dates (4 columns)

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| IsActive | External_Assignment_Assignment_V_Tasks (v) | IsActive | Direct. 1=task is currently open/active, 0=task completed/closed |
| BeginTime | External_Assignment_Assignment_V_Tasks (v) | BeginTime | Direct. Date when agent began working (date type). NULL if not yet started |
| EndTime | External_Assignment_Assignment_V_Tasks (v) | EndTime | Direct. Date when task was completed (date type). '9999-12-31' sentinel for active/open tasks |
| Escalation2CY | External_Assignment_Assignment_V_Tasks (v) | Escalation2CY | Direct. Date when task was escalated to CY. NULL if not escalated (date type) |

### D. Outcome (2 columns)

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| Outcome | External_Assignment_Dictionary_Outcome (outcome) | Name | LEFT JOIN on OutcomeID. Task outcome label (e.g., 'Docs verified', 'Cancelled', 'Pending client response'). NULL if no outcome recorded or OutcomeID not found |
| OutcomeReason | External_Assignment_Dictionary_OutcomeReason (reason) | Name | LEFT JOIN on OutcomeReasonID. Sub-reason for the outcome (e.g., 'SP email sent'). NULL if no reason recorded |

### E. Team & Manager Assignment (4 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| TeamID | External_Assignment_Assignment_V_Tasks (v) | Direct. Raw hash/code team identifier from the Assignment Tool (e.g., "03rdcrjn0z3xt0g"). NOT the human-readable team name — use `Team` column for that |
| UpdatedByTeamId | External_Assignment_Assignment_V_Tasks (v) | Direct. Raw hash/code identifier for the team that last updated the task. Same format as TeamID |
| Manager | External_Assignment_BackOffice_Manager (dm) | FirstName + ' ' + LastName | Agent full name via AssigneeID LEFT JOIN. NULL if no assignee or name not found |
| Team | External_Assignment_Assignment_Teams (teams1) | Name | CASE WHEN AssigneeID IS NULL THEN 'Unassigned' ELSE teams1.Name END. Via AssigneeID → #finalmanagers (most recent team) → Teams.Name. NULL when AssigneeID assigned but not found in team mapping |

### F. Customer Context (3 columns)

| BI_DB Column | Source | Source Column | Transform |
|-------------|--------|---------------|-----------|
| Country | DWH_dbo.Dim_Country (dc1) | Name | Full country name (e.g., 'Italy', 'Australia'). Via CID → Dim_Customer.CountryID → Dim_Country. NOT ISO code. |
| RiskGroupID | DWH_dbo.Dim_Country (dc1) | RiskGroupID | Country-level risk group classification |
| Regulation | DWH_dbo.Dim_Regulation (dr) | Name | Customer's regulation at snapshot time. Via CID → Dim_Customer.RegulationID → Dim_Regulation.Name |

### G. Metadata (1 column)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| UpdateDate | computed | GETDATE() at SP execution. datetime type. All rows in a given load share the same UpdateDate (all or nothing reload) |

---

## ETL Flow Diagram

```
External_Assignment_Assignment_ManagerTeam ─┐ most recent team per manager
External_Assignment_History_ManagerTeam    ─┤ (UNION → dedup by BeginTime DESC)
                                            ↓
                                      #finalmanagers

External_Assignment_Assignment_V_Tasks ─┐ WHERE CreateDate >= first day of last month
External_Assignment_BackOffice_Manager ─┤ AssigneeID → FirstName, LastName
Dictionary_Outcome                     ─┤ Outcome name
Dictionary_OutcomeReason               ─┘ OutcomeReason name
                                            ↓
                                        #FINAL (base task data)
                                            ↓
DWH_dbo.Dim_Customer → RegulationID + CountryID
DWH_dbo.Dim_Regulation → Regulation name
DWH_dbo.Dim_Country → Country name + RiskGroupID
#finalmanagers + Assignment_Teams → Team name
                                            ↓
                                        #final1 (all columns)
                                            ↓
TRUNCATE TABLE BI_DB_AssignmentToolTasks
INSERT INTO BI_DB_AssignmentToolTasks ← #final1
```

---

## Notes

- **No `@StartDate` parameter** — SP always loads current state with a rolling date filter. All rows have the same UpdateDate (the SP execution timestamp).
- **IDENTITY ID is unstable** — IDs are regenerated on each full reload. Do not use `ID` as a stable task reference across runs; use `TaskID` instead.
- **TeamID / UpdatedByTeamId are hash codes** — These opaque identifiers come directly from the Assignment Tool. The human-readable team name is in the `Team` column.
- **EndTime = '9999-12-31'** — sentinel value indicating task is still open (no resolution date yet).
- **Complement to BI_DB_AssignmentToolSLAs** — Tasks is a rolling current-state snapshot; SLAs is a historical daily log with SLA calculations.
