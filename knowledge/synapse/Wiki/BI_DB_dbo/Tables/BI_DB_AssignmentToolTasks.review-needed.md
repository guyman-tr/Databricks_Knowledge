# Review Sidecar — BI_DB_dbo.BI_DB_AssignmentToolTasks
<!-- batch 61 | 2026-04-23 -->

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 21 columns in DDL, 21 in wiki |
| All columns have tier suffix | ✅ | All 21 descriptions end with (Tier N — source) |
| Writer SP confirmed | ✅ | SP_H_AssignmentToolTasks, P0, TRUNCATE+INSERT, no date param |
| Sample data reviewed | ✅ | 5 rows sampled; EndTime='9999-12-31' confirmed; TeamID hash format confirmed |
| Distribution query | ✅ | IsActive: 0=174,562 (91.6%), 1=16,108 (8.4%); 7 teams + 65% NULL |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | `ID` IDENTITY instability | High | ID auto-increments from 1 on each TRUNCATE+reload. Confirm no downstream consumers join on `ID` across runs — if so, they'll break silently after each reload. Use `TaskID` as the stable key. |
| 2 | 65% NULL `Team` | Medium | Most rows have NULL Team despite having an AssigneeID. This occurs when AssigneeID is not found in the current manager-team mapping. Confirm this is expected operational data quality. |
| 3 | `Regulation` at SP run time | Medium | `Regulation` reflects the customer's regulation AT THE TIME OF THE SP RUN (from Dim_Customer), not at task creation. If a customer changed regulation between task creation and today, the stored value differs from the true regulation at task creation. Confirm this is acceptable for downstream uses. |
| 4 | Rolling window scope | Medium | Window = tasks created since first day of last month. Tasks older than ~2 months disappear from the table. Confirm all downstream Tableau reports (workbook 4402) and dashboards handle this rolling window correctly. |
| 5 | `TeamID` vs `Team` confusion | Medium | `TeamID` is an opaque hash code from the source system (e.g., "03rdcrjn0z3xt0g"), not the team name. Confirm downstream consumers use `Team` for filtering, not `TeamID`. |
| 6 | `EndTime = '9999-12-31'` sentinel | Low | Active tasks use '9999-12-31' as a sentinel for "no end date". Confirm all reporting tools handle this date correctly (some BI tools convert date columns to timestamps and may have issues with year 9999). |
| 7 | Manager source mismatch vs SLAs | Low | SLAs table uses `DWH_dbo.Dim_Manager`; this table uses `External_Assignment_BackOffice_Manager`. Same person may have different names in the two tables. Confirm joining by manager name across these tables is acceptable. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 1 | Regulation |
| Tier 2 | 19 | ID, TaskID, TaskType, GCID, CID, CreateDate, Priority, TeamID, Outcome, OutcomeReason, IsActive, BeginTime, EndTime, Escalation2CY, UpdatedByTeamId, Country, RiskGroupID, Manager, Team |
| Propagation | 1 | UpdateDate |
