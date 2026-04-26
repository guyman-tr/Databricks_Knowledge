# Review Needed: BI_DB_dbo.BI_DB_AssignmentToolBacklog

**Generated**: 2026-04-23 | **Batch**: 56 | **Reviewer**: Pending

## Tier 4 Items (Low Confidence — Needs Confirmation)

None — all columns are Tier 2 with direct SP code evidence or Propagation (IDENTITY/GETDATE()).

## Open Questions

1. **Priority integer semantics**: The SP passes `Priority` through from `Assignment.Assignment.V_Tasks` without documentation. Observed values range 0–13. Confirm whether these are ordinal priority scores, category IDs, or something else — and whether higher means higher urgency.

2. **TeamID vs Teams**: The table stores both `TeamID` (from the source task record, varchar(max)) and `Teams` (resolved team name via ManagerTeam history). Confirm the relationship: is TeamID the team the task was assigned to in the Assignment system, while Teams is derived from the assignee's current/latest team membership? These may diverge for reassigned tasks.

3. **KYCFlowTypeID 1, 2, 3 filter**: The SP limits KycFlow resolution to KYCFlowTypeID IN (1, 2, 3). Confirm what these three IDs represent (e.g., 1=Basic, 2=Enhanced, 3=EDD) and whether other KYCFlowTypeIDs exist that are intentionally excluded.

4. **IsActive=1 filter and historical data**: The SP only loads IsActive=1 tasks; there is no historical record of completed/closed tasks. Confirm whether the Assignment system or another table retains task-completion history, and whether BI_DB_AssignmentToolBacklog is the intended single source of truth for the backlog dashboard.

5. **ManagerTeam union logic**: The SP unions `Assignment.Assignment.ManagerTeam` (current) and `Assignment.History.ManagerTeam` (historical) to resolve the latest team per manager. Confirm whether this deduplication is correct when a manager has been on multiple teams — specifically whether the most recent `BeginTime` from the combined union always reflects the true current team assignment.

## Known Issues / Notes

- `IsActive` column will always be 1 — the filter is in the WHERE clause. Downstream consumers should not rely on this column for filtering (it adds no information within this table).
- `Teams` and `Country`/`DesignatedRegulation` are resolved at load time as denormalized strings. They will not update if Dim_Manager, Dim_Country, or Dim_Regulation changes until the table is refreshed.
- The SP comment references a specific Tableau report URL — this table is tightly coupled to that report's data model; schema changes require coordination with the Tableau developer.
- No upstream wiki exists for the Assignment or ComplianceStateDB databases; column semantics for GCID, TaskID, Priority, and KYCFlowTypeID are inferred from SP code only.

## Cross-Object Consistency Checks

| Column | Canonical Source | Check Status |
|--------|-----------------|-------------|
| CID | DWH_dbo.Dim_Customer | ✓ Standard FK pattern — consistent with other BI_DB tables |
| Country | DWH_dbo.Dim_Country.Name | ✓ Resolution pattern consistent with other BI_DB tables (via Dim_Customer) |
| DesignatedRegulation | DWH_dbo.Dim_Regulation.Name | ✓ Resolution pattern consistent with other BI_DB tables (via Dim_Customer) |
| RiskGroupID | DWH_dbo.Dim_Country.RiskGroupID | ✓ Sourced from Dim_Country — consistent with risk group usage in other tables |
