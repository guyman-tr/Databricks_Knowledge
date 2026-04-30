# Dictionary.SeverityType

## 1. Business Meaning

**What it is**: A lookup table defining log severity levels for the platform's server-side error logging system. Classifies logged events from Fatal (most severe) to Verbose (least severe) following standard logging severity conventions.

**Why it exists**: eToro's trading platform generates error and diagnostic logs that are stored in `History.ErrorLog`. Each log entry has a severity level from this table, enabling monitoring systems to filter, alert, and prioritize issues. Fatal and Error entries trigger immediate alerts; Warning and below are informational.

**How it works**: When a server-side event is logged to `History.ErrorLog`, the `SeverityTypeID` is set from this table. The ErrorLog has an explicit FK constraint to this table. Monitoring dashboards and alerting rules filter on severity level — typically alerting on Fatal/Error and suppressing Verbose/Informatory noise.

---

## 2. Business Logic

### Severity Levels (descending criticality)
| ID | Name | Meaning |
|----|------|---------|
| 1 | Fatal | System-breaking error — service crash, data corruption risk. Requires immediate action. |
| 2 | Error | Operational failure — transaction failed, but service continues. Requires investigation. |
| 3 | Warning | Potential issue — unusual condition that may lead to errors. Monitor closely. |
| 4 | Informatory | Normal operational event — logged for audit trail. No action needed. |
| 5 | Verbose | Detailed diagnostic data — for debugging only. High volume, normally suppressed. |

---

## 3. Data Overview

| SeverityTypeID | Name | Business Meaning |
|---------------|------|------------------|
| 1 | Fatal | Critical system failure |
| 2 | Error | Operational failure |
| 3 | Warning | Potential issue |
| 4 | Informatory | Normal event |
| 5 | Verbose | Debug-level detail |

*5 rows — standard 5-level logging severity scale*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **SeverityTypeID** | int | NOT NULL | — | Primary key. Severity level: 1=Fatal, 2=Error, 3=Warning, 4=Informatory, 5=Verbose. Lower ID = higher severity. | `MCP` |
| **Name** | varchar(20) | NOT NULL | — | Unique severity label. Enforced unique by index `DSEV_NAME`. Follows standard logging conventions (note: "Informatory" not "Information"). | `MCP+DDL` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| History.ErrorLog | SeverityTypeID | FK_DSEV_HERR | Each logged error has a severity classification |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `History.ErrorLog` — server-side error log with explicit FK

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `SeverityTypeID` (clustered) |
| Indexes | `DSEV_NAME` — unique nonclustered on `Name` |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | DICTIONARY |
| Fill Factor | 90% |
| Row Count | 5 |

---

## 8. Sample Queries

```sql
-- Get all severity levels
SELECT  SeverityTypeID, Name
FROM    Dictionary.SeverityType WITH (NOLOCK)
ORDER BY SeverityTypeID;

-- Error count by severity (last 24 hours)
SELECT  ST.Name AS Severity, COUNT(*) AS ErrorCount
FROM    History.ErrorLog EL WITH (NOLOCK)
JOIN    Dictionary.SeverityType ST WITH (NOLOCK) ON ST.SeverityTypeID = EL.SeverityTypeID
WHERE   EL.Occurred >= DATEADD(HOUR, -24, GETDATE())
GROUP BY ST.Name, ST.SeverityTypeID
ORDER BY ST.SeverityTypeID;

-- Find recent Fatal errors
SELECT  TOP 10 EL.ErrorLogID, EM.ErrorText, EL.Parameters, EL.Occurred
FROM    History.ErrorLog EL WITH (NOLOCK)
JOIN    Dictionary.ErrorMessage EM WITH (NOLOCK) ON EM.ErrorMessageID = EL.ErrorMessageID
WHERE   EL.SeverityTypeID = 1
ORDER BY EL.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Severity levels follow standard software logging conventions.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (5 rows), codebase traced (1 FK consumer: History.ErrorLog), unique index documented*
