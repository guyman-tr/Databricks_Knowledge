# History.LogErrorGeneral

> Error logging table capturing stored procedure execution errors with full error context (number, message, severity, state, line).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

History.LogErrorGeneral captures errors from stored procedure execution. When a procedure encounters an error, it can log details here via the dbo.InsertLogErrorGeneral synonym. Records the procedure name, input parameters (as XML), and full error context. Used for operational monitoring and debugging.

---

## 2. Business Logic

No complex business logic. Append-only error log.

---

## 3. Data Overview

N/A - error log table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Error log entry ID. |
| 2 | DateAt | datetime | NO | getdate() | CODE-BACKED | When the error occurred. Default: current datetime. |
| 3 | NameSP | varchar(50) | YES | - | CODE-BACKED | Name of the stored procedure that failed. |
| 4 | Param_XML | xml | YES | - | CODE-BACKED | Input parameters to the procedure as XML. |
| 5 | ErrorNumber | int | YES | - | CODE-BACKED | SQL Server error number (ERROR_NUMBER()). |
| 6 | ErrorMessage | varchar(max) | YES | - | CODE-BACKED | Error message text (ERROR_MESSAGE()). |
| 7 | ErrorSeverity | int | YES | - | CODE-BACKED | Error severity level (ERROR_SEVERITY()). |
| 8 | ErrorState | int | YES | - | CODE-BACKED | Error state (ERROR_STATE()). |
| 9 | ErrorProcedure | varchar(100) | YES | - | CODE-BACKED | Procedure where error occurred (ERROR_PROCEDURE()). |
| 10 | ErrorLine | int | YES | - | CODE-BACKED | Line number of error (ERROR_LINE()). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.InsertLogErrorGeneral | - | Synonym | Points to insert procedure for this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Written to via dbo.InsertLogErrorGeneral synonym.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_LogErrorGeneral_DateAt | DEFAULT | getdate() |

---

## 8. Sample Queries

### 8.1 Recent errors
```sql
SELECT TOP 50 DateAt, NameSP, ErrorNumber, ErrorMessage FROM History.LogErrorGeneral WITH (NOLOCK) ORDER BY DateAt DESC
```

### 8.2 Errors by procedure
```sql
SELECT NameSP, COUNT(*) AS ErrorCount FROM History.LogErrorGeneral WITH (NOLOCK) GROUP BY NameSP ORDER BY ErrorCount DESC
```

### 8.3 Specific error details
```sql
SELECT * FROM History.LogErrorGeneral WITH (NOLOCK) WHERE NameSP = @ProcName ORDER BY DateAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.LogErrorGeneral | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.LogErrorGeneral.sql*
