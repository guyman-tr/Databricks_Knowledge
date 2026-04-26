# Review Sidecar — BI_DB_dbo.BI_DB_AssignmentToolSLAs
<!-- batch 61 | 2026-04-23 -->

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 21 columns in DDL, 21 in wiki |
| All columns have tier suffix | ✅ | All 21 descriptions end with (Tier N — source) |
| Writer SP confirmed | ✅ | SP_H_AssignmentToolSLAs, P0, daily |
| Sample data reviewed | ✅ | 5 rows sampled; Teams: Philippines/Singapore/USA; Outcome='Docs verified'; SLA=1 for short tasks |
| Distribution query | ✅ | 9 teams; 91% SLA=1; 4.97M total rows (2022-05-19 → 2026-04-13) |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | `Include` dead column | High | Column exists in DDL but SP never inserts it (always NULL). Confirm if it was intentional (reserved for future use) or should be removed from DDL. |
| 2 | `GCID` meaning | Medium | `GCID` from External_Assignment V_Tasks — value differs from `CID` in sample (e.g., GCID=8326415, CID=8040538). Confirm what GCID represents in the Assignment Tool context (Group ID? Global customer ID? Agent ID?). |
| 3 | `SLA` int from varchar CASE | Medium | SP uses `THEN '1' ELSE '0'` (string literals) but DDL type is int. Relies on implicit Synapse conversion. Confirm this is stable and intentional. |
| 4 | `Country` full name vs ISO | Low | `Country` stores full name ('France', 'United States'), not ISO code. Confirm all downstream reports expect full names. |
| 5 | `UptadedByName` typo | Low | Column name has typo: "Uptaded" instead of "Updated". Baked into DDL, SP, and all downstream consumers. Confirm this is accepted as-is (legacy). |
| 6 | `UpdateDate` date precision | Low | `UpdateDate [date]` truncates to day, losing time. Confirm no downstream use case requires intra-day SP execution time. |
| 7 | External_Assignment sources | Medium | Primary data comes from `External_Assignment_*` staging tables within BI_DB_dbo. These are not documented in this wiki. Confirm their source system (Assignment Tool production DB) and refresh frequency so lineage is complete. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 20 | TaskID, GCID, CID, CreateDate, BeginTime, Priority, Team, TimeinHr, SLA, Country, RiskGroupID, UptadedByName, Outcome, TimeFromEscalation, SLA_Escalation, TaskIDEscalated, Include, RN, OutcomeDateID, OutcomeDate |
| Propagation | 1 | UpdateDate |
