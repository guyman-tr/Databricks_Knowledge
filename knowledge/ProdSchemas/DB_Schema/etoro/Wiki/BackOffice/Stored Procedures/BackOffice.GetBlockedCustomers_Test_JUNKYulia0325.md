# BackOffice.GetBlockedCustomers_Test_JUNKYulia0325

> DEPRECATED/JUNK: Exact copy of BackOffice.GetBlockedCustomers - returns blocked customer report. Marked for removal by Yulia, March 2025. Use BackOffice.GetBlockedCustomers for all production queries.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IDs (player status filter TVP) + @StartDate/@EndDate; returns one row per customer with latest status change in window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

> **DEPRECATED**: This procedure is tagged JUNK (suffix `_JUNKYulia0325`) indicating it was marked for decommissioning by Yulia in March 2025. It should not be used in new code. Use `BackOffice.GetBlockedCustomers` instead - the production procedure with identical logic.

`BackOffice.GetBlockedCustomers_Test_JUNKYulia0325` is a verbatim copy of `BackOffice.GetBlockedCustomers`. The SQL code is line-for-line identical. Both procedures accept the same five parameters (three TVPs + two datetime), build the same CTE, apply the same filters, and return the same 30 columns.

The "_Test" in the name suggests it was originally created as a test/development version, with the intent of replacing or validating the production version. It was never removed after the work was completed, and was formally tagged JUNK in March 2025.

For full business logic, business rules, column descriptions, and sample queries, see: [BackOffice.GetBlockedCustomers](BackOffice.GetBlockedCustomers.md).

---

## 2. Business Logic

All logic is identical to `BackOffice.GetBlockedCustomers`. See that procedure's documentation for:
- TVP empty-means-all pattern (@IDs, @PlayerStatusReasonIDs, @PlayerStatusSubReasonIDs)
- Active account filter (AccountStatusID IS NULL OR =1)
- RANK()-based status change date window
- POI Approved / POA Approved correlated EXISTS checks
- New uploaded files unclassified count
- SubReason IIF logic (SubReasonID=0 -> free-text comment)
- OUTER APPLY BackOffice.GetUserRisksByCID_V2 for risk status

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

Same as `BackOffice.GetBlockedCustomers` - identical output schema (30 columns: Select.., CID, User Name, First Name, Last Name, Customer Status, Reason, SubReason, Days From FTD, Number of Open Positions, Balance, Pending Closure Status, Risk Status, Regulation, Document Status, Country By Reg. Form, Customer Level, Date Changed, Comment, Total Deposits, Manager, PlayerStatusID, POI Approved, POA Approved, Number of New Uploaded Files). See [BackOffice.GetBlockedCustomers](BackOffice.GetBlockedCustomers.md) for full element table.

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as BackOffice.GetBlockedCustomers. See that procedure's dependency chain.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. JUNK-tagged - not expected to have active callers.

---

## 6. Dependencies

### 6.0 Dependency Chain

Identical to BackOffice.GetBlockedCustomers. See [BackOffice.GetBlockedCustomers](BackOffice.GetBlockedCustomers.md) Section 6.

### 6.1 Objects This Depends On

Same 19 objects as BackOffice.GetBlockedCustomers. See that procedure.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | JUNK-tagged - not expected to be actively called. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Same as BackOffice.GetBlockedCustomers. No SET NOCOUNT ON. NOLOCK on all tables.

---

## 8. Sample Queries

### 8.1 Use production version instead (recommended)
```sql
-- DEPRECATED: Use GetBlockedCustomers for production queries
-- Identical results with same parameters:
DECLARE @IDs BackOffice.IDs;
DECLARE @Reasons BackOffice.IDs;
DECLARE @SubReasons BackOffice.IDs;
EXEC BackOffice.GetBlockedCustomers
    @IDs = @IDs,
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-01',
    @PlayerStatusReasonIDs = @Reasons,
    @PlayerStatusSubReasonIDs = @SubReasons;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetBlockedCustomers_Test_JUNKYulia0325 | Type: Stored Procedure (DEPRECATED/JUNK) | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetBlockedCustomers_Test_JUNKYulia0325.sql*
