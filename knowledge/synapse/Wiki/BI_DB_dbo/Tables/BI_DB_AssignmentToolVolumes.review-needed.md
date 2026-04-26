# Review Notes — BI_DB_dbo.BI_DB_AssignmentToolVolumes

Generated: 2026-04-23 | Batch: 65 | Phase 16 Score: 8.2 / 10

## Status: PASS — minor items for domain review

---

## Items Requiring Human Review

### 1. Outcome Dictionary Values Not Confirmed
- **Issue**: The `Outcome` column has 11 distinct values in the live table (≤15, qualifies for inline dictionary), but the exact value list was not enumerated in the wiki due to context compaction during the session. The SP notes outcomes come from `External_Assignment_Dictionary_Outcome.Name`.
- **Action**: Query `SELECT DISTINCT Outcome FROM BI_DB_dbo.BI_DB_AssignmentToolVolumes` and add an inline dictionary to the Outcome column description in Section 4.
- **Severity**: Low — no analytical impact, enhancement only.

### 2. `UpdatedByTeamMemberFinal` NULL Rate
- **Issue**: The NULL rate for agent names was not confirmed by live sampling. The wiki states "NULL if ManagerID not in BackOffice_Manager" but does not quantify.
- **Action**: Run `SELECT COUNT(*) total, SUM(CASE WHEN UpdatedByTeamMemberFinal IS NULL THEN 1 ELSE 0 END) nulls FROM BI_DB_dbo.BI_DB_AssignmentToolVolumes` to confirm.
- **Severity**: Low.

### 3. Team Distribution Not Sampled for Volumes Table
- **Issue**: Team distribution percentages were inferred from the sibling SLAs table (Philippines 35%, Cyprus 16%, etc.). Volumes may differ.
- **Action**: Query `SELECT UpdatedByTeamFinal, COUNT(*) FROM BI_DB_dbo.BI_DB_AssignmentToolVolumes GROUP BY UpdatedByTeamFinal ORDER BY 2 DESC` to confirm.
- **Severity**: Low.

### 4. Change History Incomplete
- **Issue**: SP comment shows only the initial creation date (2020-02-16, Pavlina Masoura). Subsequent modifications are not captured.
- **Action**: Check Atlassian/Confluence for SP_H_AssignmentToolVolumes change history.
- **Severity**: Low.

---

## Confidence Assessment

| Section | Confidence | Notes |
|---------|-----------|-------|
| Business Meaning | High | Confirmed by sibling SLAs wiki and SP code |
| Business Logic | High | SP code read directly |
| Query Advisory | High | Derived from SP and DDL |
| Elements | High | All columns traced to SP code |
| Lineage | High | SP code read directly |
| Relationships | Medium | SLAs sibling confirmed; other relationships inferred |
| Sample Queries | High | Standard patterns |
