# Monitoring.OperationsReport

> Generates a summary report of success/failure counts and percentages for ALL wallet operation types within a date range, excluding known benign errors.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns success/failure metrics per operation type |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.OperationsReport is the top-level operational health dashboard query. It provides a single summary showing every wallet operation type with its success count, failure count, and success/failure percentages. This is the starting point for operational monitoring - when failures spike for any operation type, the team drills down using OperationFailuresCountReport and then OperationFailuresDetailsReport.

Without this procedure, the team would have no unified view of operational health across all wallet operation types. Each operation would need to be checked individually.

The procedure uses a RIGHT JOIN from the aggregated results back to Dictionary.RequestTypes to ensure ALL operation types appear in the output (even those with zero activity). Operation type 5 is excluded. It runs with EXECUTE AS OWNER.

---

## 2. Business Logic

### 2.1 Operations Health Summary

**What**: Calculates success/failure rates for every operation type.

**Columns/Parameters Involved**: `RequestStatusId`, `RequestTypeId`, `@FromDate`, `@ToDate`

**Rules**:
- RequestStatusId = 1 counted as Success
- RequestStatusId = 2 counted as Failure (after ExcludedErrors filtering)
- SuccessProc = Success * 100 / (Success + Failures) - success percentage
- FailuresProc = Failures * 100 / (Success + Failures) - failure percentage
- ISNULL wrappers handle operation types with zero activity
- RequestTypeId = 5 is excluded from the report
- Only the most recent status per request is considered

### 2.2 Reporting Hierarchy

**What**: This procedure is the top of a three-level reporting hierarchy.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `@OperationId`

**Rules**:
- Level 1: OperationsReport - overview of all operations
- Level 2: OperationFailuresCountReport - error breakdown for one operation
- Level 3: OperationFailuresDetailsReport / OperationFailuresReport - individual request details

**Diagram**:
```
OperationsReport (all operations, success/fail counts)
  |
  v  [pick operation with high failures]
OperationFailuresCountReport (error code breakdown)
  |
  v  [pick specific error code]
OperationFailuresDetailsReport (individual requests)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of reporting period. |
| 2 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of reporting period. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationId | TINYINT | NO | - | CODE-BACKED | Operation type ID from Dictionary.RequestTypes. |
| 2 | Name | NVARCHAR | NO | - | CODE-BACKED | Human-readable operation type name. |
| 3 | Success | INT | NO | - | CODE-BACKED | Count of successful requests (StatusId=1). 0 if no activity. |
| 4 | Failures | INT | NO | - | CODE-BACKED | Count of failed requests (StatusId=2) after benign error exclusion. 0 if no activity. |
| 5 | SuccessProc | INT | NO | - | CODE-BACKED | Success percentage: Success * 100 / (Success + Failures). 0 if no activity. |
| 6 | FailuresProc | INT | NO | - | CODE-BACKED | Failure percentage: Failures * 100 / (Success + Failures). 0 if no activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Dictionary.RequestTypes | RIGHT JOIN | Ensures all operation types appear even with zero activity |
| Query body | Wallet.Requests | JOIN | Request records |
| Query body | Wallet.RequestStatuses | JOIN | Success/failure status |
| Query body | Monitoring.ExcludedErrors | LEFT JOIN (LIKE) | Benign error exclusion |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring/reporting tools. Serves as the entry point into the operations failure reporting hierarchy.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.OperationsReport (procedure)
  ├── Dictionary.RequestTypes (table)
  ├── Wallet.Requests (table)
  ├── Wallet.RequestStatuses (table)
  └── Monitoring.ExcludedErrors (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RequestTypes | Table | RIGHT JOIN - all operation types |
| Wallet.Requests | Table | JOIN - request records |
| Wallet.RequestStatuses | Table | JOIN - success/failure status |
| Monitoring.ExcludedErrors | Table | LEFT JOIN - benign error filtering |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS OWNER | Security | Runs with schema owner permissions |

---

## 8. Sample Queries

### 8.1 Today's operations summary
```sql
EXEC Monitoring.OperationsReport @FromDate = '2026-04-15', @ToDate = '2026-04-16';
```

### 8.2 Last week's operations summary
```sql
EXEC Monitoring.OperationsReport @FromDate = '2026-04-08', @ToDate = '2026-04-15';
```

### 8.3 View all available operation types
```sql
SELECT Id, Name FROM Dictionary.RequestTypes WITH (NOLOCK) ORDER BY Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.OperationsReport | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.OperationsReport.sql*
