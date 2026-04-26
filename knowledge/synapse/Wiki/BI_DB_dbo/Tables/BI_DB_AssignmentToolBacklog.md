# BI_DB_dbo.BI_DB_AssignmentToolBacklog

**Schema**: BI_DB_dbo | **Batch**: 56 | **Generated**: 2026-04-23

## Purpose

Point-in-time snapshot of active KYC documentation tasks in the Assignment Tool, designed to power the "Assignment tool – docs backlog analysis" Tableau report. Each row represents one active task assigned (or unassigned) to a back-office agent, enriched with customer risk classification, KYC flow type, depositor status, and regulatory regime. The table replaces a previously inline Tableau query.

## Shape

| Property | Value |
|----------|-------|
| Rows | ~27,060 |
| Columns | 17 |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Grain | One row per active assignment task (TaskID) |

## Load Pattern

**Daily full refresh** — `SP_AssignmentToolBacklog` truncates the table and re-inserts from `Assignment.Assignment.V_Tasks` filtered to `IsActive=1`. The result is always the current open-task backlog; closed or completed tasks are excluded and not retained historically. All rows share the same UpdateDate timestamp from a single run.

## Columns

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 1 | ID | int IDENTITY(1,1) | NOT NULL | Surrogate key auto-incremented by Synapse at INSERT; has no upstream business meaning | Propagation |
| 2 | AssigneeID | int | NULL | ID of the back-office agent the task is assigned to; NULL if unassigned | Tier 2 |
| 3 | CreateDate | date | NULL | Date the assignment task was created in the Assignment system | Tier 2 |
| 4 | GCID | int | NULL | Global customer ID from the Assignment system | Tier 2 |
| 5 | CID | int | NULL | Customer identifier — FK to DWH_dbo.Dim_Customer.RealCID | Tier 2 |
| 6 | Depositors | varchar(max) | NULL | Customer depositor classification: 'Depositors' if the customer has a first-time deposit (IsFTD=1 in BI_DB_AllDeposits), 'Non-depositors' otherwise | Tier 2 |
| 7 | DesignatedRegulation | varchar(max) | NULL | Customer's designated regulatory regime name, resolved via Dim_Customer → Dim_Regulation | Tier 2 |
| 8 | IsActive | int | NULL | Task active flag from the Assignment system; always 1 in this table (inactive tasks are excluded at load) | Tier 2 |
| 9 | Priority | int | NULL | Task priority score assigned by the Assignment system; higher values indicate higher urgency | Tier 2 |
| 10 | TeamID | varchar(max) | NULL | Team identifier from the Assignment system task record | Tier 2 |
| 11 | TaskID | bigint | NULL | Source task identifier from Assignment.Assignment.V_Tasks | Tier 2 |
| 12 | Country | varchar(max) | NULL | Customer's country of residence name, resolved via Dim_Customer → Dim_Country | Tier 2 |
| 13 | RiskGroupID | int | NULL | Customer country risk group ID from Dim_Country; 0 = standard, higher values indicate elevated risk | Tier 2 |
| 14 | Teams | varchar(max) | NULL | Team name resolved from AssigneeID via Assignment ManagerTeam history; 'Unassigned' when AssigneeID is NULL | Tier 2 |
| 15 | VerificationLevelID | int | NULL | Customer's KYC verification level ID from DWH_dbo.Dim_Customer | Tier 2 |
| 16 | kycFlow | varchar(max) | NULL | Customer's KYC flow classification: 'Rank 1 or 2' for high-risk-group customers (RiskGroupID 1–2), 'Normal' for customers with no active KYC flow type (1, 2, or 3), or the KYC flow type name from ComplianceStateDB.Dictionary.KYCFlowType | Tier 2 |
| 17 | UpdateDate | datetime | NULL | Timestamp when this row was inserted by the ETL pipeline (GETDATE() at INSERT time) | Propagation |

## Key Relationships

| Column | Joins To | Cardinality |
|--------|----------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Many-to-one |
| TaskID | Assignment.Assignment.V_Tasks.TaskID | One-to-one (source PK) |
| Country | DWH_dbo.Dim_Country (resolved at load, not a stored FK) | — |
| DesignatedRegulation | DWH_dbo.Dim_Regulation (resolved at load, not a stored FK) | — |

## Data Observations

- CreateDate spans 2025-12-10 to 2026-04-13; all rows loaded on 2026-04-13 (single UpdateDate timestamp confirms full refresh)
- IsActive is uniformly 1 — inactive tasks are excluded by the WHERE clause at load; the column value is always 1 in this table
- 8 distinct assignees; 4 distinct TeamIDs — small operational team
- kycFlow: predominantly 'Normal' (overwhelmingly most rows); minority classified as 'Rank 1 or 2', 'Verify Before Trade', 'Verify Before Deposit', or 'High-Risk Country'
- RiskGroupID is 0 for the vast majority of customers; small subsets in groups 2, 3, 4
- Depositors: roughly two-thirds non-depositors, one-third depositors
- Priority values range 0–13; no single canonical meaning documented in SP code

## Quality Notes

| Dimension | Assessment |
|-----------|-----------|
| Tier Distribution | 15 Tier 2, 2 Propagation |
| Completeness | All 17 columns documented |
| Tier 1 | 0 — no upstream wiki for Assignment or ComplianceStateDB |
| Known Gaps | Priority integer semantics not documented in SP; no upstream wiki for Assignment system |

**Quality Score**: 8.0/10
