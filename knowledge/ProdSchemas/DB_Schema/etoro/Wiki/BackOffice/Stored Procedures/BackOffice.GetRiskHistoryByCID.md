# BackOffice.GetRiskHistoryByCID

> Returns the full risk status change history for a single customer within a date range - combining both the audit history log and the current live risk record, used by Back Office risk review screens.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (required); returns History.CustomerRisk UNION BackOffice.CustomerRisk rows within date range |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetRiskHistoryByCID` retrieves the complete timeline of risk status changes for a specific customer. It is used by BO risk review agents to audit how a customer's risk classification evolved over time - which risk statuses were assigned, which events triggered those changes, and which manager made each change.

The procedure returns a UNION of two sources: `History.CustomerRisk` (the audit log of past risk state changes) and `BackOffice.CustomerRisk` (the current live risk record). The UNION allows the result to include the customer's present risk state alongside the historical trail, giving a complete picture in a single result set without needing separate queries.

Both UNION branches apply the same date range filter on `ModifiedDate`, so the current record only appears if it was modified within the requested window.

---

## 2. Business Logic

### 2.1 UNION of History and Current State

**What**: Combines the historical risk change audit log with the current live risk record into a single chronological result.

**Columns/Parameters Involved**: `History.CustomerRisk`, `BackOffice.CustomerRisk`, `@DateFrom`, `@DateTo`

**Rules**:
- Branch 1: `History.CustomerRisk` WHERE GCID = @CID's GCID AND ModifiedDate BETWEEN @DateFrom AND @DateTo
- Branch 2: `BackOffice.CustomerRisk` WHERE GCID = @CID's GCID AND ModifiedDate BETWEEN @DateFrom AND @DateTo
- Both branches are resolved via `Customer.Customer.GCID` JOIN (not direct CID lookup) - the GCID is the global customer identifier linking CID to risk records
- Result is ordered by ModifiedDate DESC (most recent change first)
- `Customer.Customer.Comments` is included in both branches - this is the customer-level comment field, NOT per-risk-event comments

### 2.2 Risk Status and Event Status

**What**: Translates numeric risk identifiers into human-readable names.

**Columns/Parameters Involved**: `Dictionary.RiskStatus`, `Dictionary.RiskEventStatus`, `RiskStatusID`, `RiskEventStatusID`

**Rules**:
- `RiskStatusID` -> `Dictionary.RiskStatus.Name` as `[Risk Status]` - the risk classification label (e.g., High Risk, Blocked, Monitored)
- `RiskEventStatusID` -> `Dictionary.RiskEventStatus.Name` as `[Risk Event Status]` - the event that triggered the status change
- Both are LEFT JOINs - NULL values appear if the risk record lacks an associated status or event

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID to retrieve risk history for. Used to find the GCID via Customer.Customer JOIN, then filter both risk history branches on GCID. Required - no default. |
| 2 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of date range. Filters History.CustomerRisk.ModifiedDate >= @DateFrom (BETWEEN inclusive). Required. |
| 3 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of date range. Filters History.CustomerRisk.ModifiedDate <= @DateTo (BETWEEN inclusive). Required. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Last Modification Date | DATETIME | YES | - | VERIFIED | Timestamp of this risk status change (History.CustomerRisk.ModifiedDate or BackOffice.CustomerRisk.ModifiedDate). Renamed from [Timestamp] in MIMOPS-2399. Ordered DESC in result. |
| 2 | Risk Status | NVARCHAR | YES | - | CODE-BACKED | Human-readable risk classification name (Dictionary.RiskStatus.Name). NULL if no RiskStatusID assigned on this record. Examples: HighRisk, Monitored, PEP, Blocked. |
| 3 | Risk Event Status | NVARCHAR | YES | - | CODE-BACKED | Name of the event type that triggered this status change (Dictionary.RiskEventStatus.Name via RiskEventStatusID). NULL if no event classification recorded. |
| 4 | Modified By | NVARCHAR | YES | - | CODE-BACKED | Login/username of the BackOffice manager who made this change (BackOffice.Manager.Login). NULL if the change was automated or manager record not found. |
| 5 | Comments | NVARCHAR | YES | - | CODE-BACKED | Customer-level comments field (Customer.Customer.Comments). This is the account-wide comment, not a per-risk-event note - same value repeats across all rows for the same customer. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CCST.CID = @CID | Customer.Customer | Read (WHERE filter) | Customer GCID lookup - drives both UNION branches |
| CCST.GCID | History.CustomerRisk | LEFT JOIN | Historical risk audit records |
| CCST.GCID | BackOffice.CustomerRisk | LEFT JOIN | Current live risk record |
| HRST.ManagerID | BackOffice.Manager | LEFT JOIN (x2) | Manager login name |
| HRST.RiskStatusID | Dictionary.RiskStatus | LEFT JOIN (x2) | Risk status name |
| HRST.RiskEventStatusID | Dictionary.RiskEventStatus | LEFT JOIN (x2) | Risk event status name |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO Risk screen) | @CID | Application | Called by Back Office customer risk history/audit screens |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetRiskHistoryByCID (procedure)
├── Customer.Customer (table) - CID -> GCID bridge
├── History.CustomerRisk (table) - historical audit log
├── BackOffice.CustomerRisk (table) - current live risk record
├── BackOffice.Manager (table) - manager login
├── Dictionary.RiskStatus (table) - risk classification names
└── Dictionary.RiskEventStatus (table) - event type names
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | JOIN on CID to retrieve GCID - drives both UNION branches |
| History.CustomerRisk | Table | Branch 1 of UNION - historical risk state changes |
| BackOffice.CustomerRisk | Table | Branch 2 of UNION - current live risk state |
| BackOffice.Manager | Table | LEFT JOIN for manager login name |
| Dictionary.RiskStatus | Table | LEFT JOIN for risk status name translation |
| Dictionary.RiskEventStatus | Table | LEFT JOIN for risk event status name translation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO application layer for risk history display. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| GCID-based join | Implementation | Both UNION branches join to Customer.Customer on GCID (not CID directly). The WHERE clause uses CCST.CID = @CID but risk records are keyed on GCID. |
| UNION (not UNION ALL) | Implementation | Duplicate elimination is applied - if a row appears in both History and BackOffice risk tables with identical values, it appears once. In practice this is rare as the tables have different data. |
| No static SQL | Implementation | This procedure uses direct SELECT (not dynamic SQL), unlike several other BackOffice report procedures. |

---

## 8. Sample Queries

### 8.1 Get full risk history for a customer in the last year
```sql
EXEC [BackOffice].[GetRiskHistoryByCID]
    @CID = 123456,
    @DateFrom = '20240101',
    @DateTo = '20251231'
```

### 8.2 Check recent risk changes in the last 30 days
```sql
EXEC [BackOffice].[GetRiskHistoryByCID]
    @CID = 123456,
    @DateFrom = DATEADD(DAY, -30, GETUTCDATE()),
    @DateTo = GETUTCDATE()
```

### 8.3 Direct query for recent risk status changes
```sql
SELECT HRST.ModifiedDate, DRST.Name AS RiskStatus, DRES.Name AS EventStatus,
       BMNG.Login AS ModifiedBy
FROM Customer.Customer CCST WITH (NOLOCK)
LEFT JOIN History.CustomerRisk HRST WITH (NOLOCK) ON CCST.GCID = HRST.GCID
LEFT JOIN BackOffice.Manager BMNG WITH (NOLOCK) ON BMNG.ManagerID = HRST.ManagerID
LEFT JOIN Dictionary.RiskStatus DRST WITH (NOLOCK) ON HRST.RiskStatusID = DRST.RiskStatusID
LEFT JOIN Dictionary.RiskEventStatus DRES WITH (NOLOCK) ON DRES.RiskEventStatusID = HRST.RiskEventStatusID
WHERE CCST.CID = 123456
  AND HRST.ModifiedDate BETWEEN DATEADD(DAY, -30, GETUTCDATE()) AND GETUTCDATE()
ORDER BY HRST.ModifiedDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-2399 | Jira | Renamed output column from [Timestamp] to [Last Modification Date] (Oct 2020, Shay O.) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira (MIMOPS-2399 from DDL comment) | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetRiskHistoryByCID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetRiskHistoryByCID.sql*
