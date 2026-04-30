# BackOffice.GetAmlAndRiskComments

> Returns the AML (Anti-Money Laundering) and Risk free-text comment fields for a customer from the BackOffice customer record, used by compliance and risk management teams.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer identifier; returns one row with two comment fields |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAmlAndRiskComments` retrieves the two compliance-related free-text annotation fields stored on the BackOffice customer record: `AMLComment` and `RiskComment`. These are internal notes written by compliance and risk management staff - not visible to customers.

**AMLComment** captures Anti-Money Laundering observations: flags about suspicious deposit patterns, source-of-funds concerns, PEP (Politically Exposed Person) notes, or remediation actions taken. The `CustomerHistoryUpdate` trigger on `BackOffice.Customer` automatically prepends each update with a timestamp and manager login (format: `[YYYY-MM-DD HH:MM: Login] new comment text`), turning AMLComment into a running audit log of AML-related observations.

**RiskComment** is a parallel free-text field used by the risk team for risk classification notes, margin call history, unusual trading pattern observations, or other risk-relevant annotations. The same trigger applies the same timestamp prefix on update.

The procedure is minimal by design - it is called by back-office management services (BOManagementServiceUser) to populate the AML/Risk comment panel in the BackOffice agent UI, and the single-row result feeds directly into display fields without further transformation.

---

## 2. Business Logic

### 2.1 Direct Column Read - No Transformation

**What**: The procedure performs a direct SELECT of two columns with no filtering beyond CID, no JOINs, no aggregation.

**Columns/Parameters Involved**: `BackOffice.Customer.AMLComment`, `BackOffice.Customer.RiskComment`

**Rules**:
- Returns exactly one row if the CID exists in BackOffice.Customer; zero rows if not.
- Both columns are NVARCHAR(MAX) and nullable - NULL is returned if no comment has been written.
- NOLOCK hint is applied - reads may be slightly stale but this is acceptable for display-only use.

### 2.2 AMLComment Trigger-Prepended Format

**What**: AMLComment is not a single string but a timestamped log maintained by the `CustomerHistoryUpdate` trigger.

**Columns/Parameters Involved**: `AMLComment`

**Rules**:
- The `CustomerHistoryUpdate` AFTER UPDATE trigger on `BackOffice.Customer` fires on any update to the row.
- When AMLComment changes, the trigger prepends the format: `[YYYY-MM-DD HH:MM: ManagerLogin] {new text}` to the existing value.
- Result: AMLComment grows as a reverse-chronological log of AML annotations, newest entry at the top.
- This procedure returns the raw concatenated value - the calling application is responsible for parsing/displaying the log entries.
- RiskComment follows the same trigger pattern.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer Identifier. Used in WHERE clause to filter BackOffice.Customer to one customer row. |
| 2 | AMLComment | NVARCHAR(MAX) | YES | - | CODE-BACKED | Anti-Money Laundering free-text annotation maintained by compliance staff. Each update is prepended with `[YYYY-MM-DD HH:MM: ManagerLogin]` by the CustomerHistoryUpdate trigger, forming a reverse-chronological audit log. NULL if no AML notes have been recorded. |
| 3 | RiskComment | NVARCHAR(MAX) | YES | - | CODE-BACKED | Risk team free-text annotation for risk classification, unusual trading pattern notes, or margin observations. Same trigger-prepend format as AMLComment. NULL if no risk notes recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Primary source (WHERE filter) | Reads AMLComment and RiskComment for the given CID. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BOManagementServiceUser service account. No SQL procedure callers in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAmlAndRiskComments (procedure)
└── BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Only source - reads AMLComment and RiskComment filtered by CID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BOManagementServiceUser. No SQL procedure callers in repository. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. BackOffice.Customer has a clustered index on CID - the WHERE CID=@CID lookup is a single-row seek.

### 7.2 Constraints

NOLOCK on BackOffice.Customer. No SET NOCOUNT ON. Single-table read with no JOINs. AuditActionTypeID=225 corresponds to this procedure's invocation in the BackOffice audit trail.

---

## 8. Sample Queries

### 8.1 Get AML and Risk comments for a customer
```sql
EXEC BackOffice.GetAmlAndRiskComments @CID = 10848122;
```

### 8.2 Inline equivalent
```sql
SELECT AMLComment, RiskComment
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 10848122;
```

### 8.3 Parse the timestamped AMLComment log entries (pattern)
```sql
-- Each log entry follows: [YYYY-MM-DD HH:MM: Login] comment text
-- To extract the most recent entry, find the first ']' after the opening '['
SELECT SUBSTRING(AMLComment, 1, CHARINDEX(']', AMLComment))  AS LatestHeader,
       SUBSTRING(AMLComment, CHARINDEX(']', AMLComment) + 2,
           CHARINDEX('[', AMLComment, 2) - CHARINDEX(']', AMLComment) - 2) AS LatestText
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 10848122
  AND AMLComment IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| OPS0435 / Ticket 51005 | Jira | Procedure created April 2018 for compliance workflow integration. BOManagementServiceUser granted execute permission at creation. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAmlAndRiskComments | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAmlAndRiskComments.sql*
