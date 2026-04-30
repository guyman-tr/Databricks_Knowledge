# BackOffice.PhoneVerificationReport_JunkNoga240325

> JUNK/deprecated procedure that generates an HTML-formatted report of duplicate phone verification events within a date range and emails it to a hardcoded recipient list via sp_send_dbmail.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CTE finds phones verified >1 time in date range; sends HTML via msdb.dbo.sp_send_dbmail to hardcoded recipients |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.PhoneVerificationReport_JunkNoga240325` is a legacy/deprecated stored procedure (indicated by the `_JunkNoga240325` suffix, meaning it was marked for deletion by a team member named Noga in March 2025). It generates a fraud/abuse detection report identifying phone numbers that were used to complete verification multiple times within a specified date window. This pattern can indicate account sharing, SIM hijacking, or automated fraud where the same phone is used to verify multiple accounts.

The procedure formats the results as an HTML table and delivers it via SQL Server Database Mail (`msdb.dbo.sp_send_dbmail`) to a hardcoded list of internal recipients. Because recipients and report logic are embedded in the procedure body, it was designed as a scheduled job artifact rather than an application-callable API.

The JUNK suffix means this procedure should be considered inactive/legacy and should not be relied upon. It may have been replaced by an application-layer report or a more modern alerting mechanism.

---

## 2. Business Logic

### 2.1 Duplicate Phone Detection CTE

**What**: Identifies phone numbers that appear in verification events more than once within the date range.

**Rules**:
- CTE aggregates Customer phone verification data grouped by phone number and date range.
- COUNT > 1 filter: only phones verified by more than one event (or account) are included.
- Date range: @StartDate to @EndDate parameters control the reporting window.
- Results include: phone number, count of verification events, and associated customer identifiers.

### 2.2 HTML Email Delivery

**What**: Formats findings as an HTML table and sends via Database Mail.

**Rules**:
- `msdb.dbo.sp_send_dbmail`: SQL Server Database Mail - requires Database Mail to be configured and enabled on the server.
- Recipients are hardcoded in the procedure body (internal BackOffice/fraud team email addresses).
- Subject line includes date range for identification.
- If no duplicate phones found, email is still sent (empty report or "no results" message - per typical sp_send_dbmail patterns).
- Procedure is fire-and-forget: no return value, no error propagation from mail delivery.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | NAME-INFERRED | Start of the date range to scan for duplicate phone verifications. Passed to the CTE filter on verification event date. |
| 2 | @EndDate | datetime | NO | - | NAME-INFERRED | End of the date range. Combined with @StartDate to define the reporting window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CTE source | Customer schema phone verification tables | Reader | Aggregates phone verification events to find duplicates |
| Email delivery | msdb.dbo.sp_send_dbmail | Callee | Sends the HTML report to hardcoded recipients via Database Mail |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Was likely called from a SQL Server Agent scheduled job (now deprecated/removed).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.PhoneVerificationReport_JunkNoga240325 (procedure) [JUNK - deprecated]
+-- Customer phone verification tables [SELECT - aggregation]
+-- msdb.dbo.sp_send_dbmail [EXEC - email delivery]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer phone verification tables | Table(s) | SELECT - aggregates phone verification events in date range |
| msdb.dbo.sp_send_dbmail | System Procedure | EXEC - delivers HTML report to hardcoded recipients via Database Mail |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| JUNK suffix | Deprecation marker | Marked for deletion by Noga in March 2025. Should not be called in new code. |
| Hardcoded recipients | Design constraint | Email recipients are embedded in procedure body - cannot be changed without modifying the SP. |
| Database Mail dependency | Infrastructure | Requires Database Mail to be enabled and configured on the SQL Server instance. |

---

## 8. Sample Queries

### 8.1 Run the report (deprecated - do not use in production)

```sql
-- DEPRECATED - use only for historical reference
EXEC BackOffice.PhoneVerificationReport_JunkNoga240325
    @StartDate = '2025-03-01',
    @EndDate = '2025-03-31';
```

### 8.2 Direct equivalent for duplicate phone detection (without email)

```sql
-- Find phones used for verification by more than one customer in a date window
SELECT PhoneNumber, COUNT(DISTINCT CustomerID) AS CustomerCount
FROM Customer.ContactVerificationPhoneGetMany -- or relevant verification table
WHERE VerificationDate BETWEEN '2025-03-01' AND '2025-03-31'
GROUP BY PhoneNumber
HAVING COUNT(DISTINCT CustomerID) > 1
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 6/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.PhoneVerificationReport_JunkNoga240325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.PhoneVerificationReport_JunkNoga240325.sql*
