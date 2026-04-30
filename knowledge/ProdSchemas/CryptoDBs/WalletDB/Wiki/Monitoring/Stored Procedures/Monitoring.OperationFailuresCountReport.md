# Monitoring.OperationFailuresCountReport

> Aggregates failure counts by error code for a specific operation type within a date range, excluding known benign errors via Monitoring.ExcludedErrors pattern matching.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns failure counts grouped by error code per operation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.OperationFailuresCountReport provides a breakdown of failures by error code for a specific wallet operation type. This helps the operations team identify which specific errors are causing the most failures and prioritize investigation. For example, if operation type "Send" has 100 failures, this procedure shows whether they are 90 "insufficient funds" + 10 "invalid address" or some other distribution.

Without this procedure, the team would only see total failure counts without understanding the error distribution, making it impossible to prioritize fixes or identify emerging error patterns.

The procedure uses a LEFT JOIN to Monitoring.ExcludedErrors to filter out known benign errors (WHERE ee.ErrorMessage IS NULL), and extracts error codes and messages from the JSON DetailsJson field using JSON_VALUE. It runs with EXECUTE AS OWNER for elevated permissions.

---

## 2. Business Logic

### 2.1 Error Code Extraction and Aggregation

**What**: Parses JSON error details and groups failures by code and message.

**Columns/Parameters Involved**: `DetailsJson`, `RequestStatusId`, `@OperationId`

**Rules**:
- Only the MOST RECENT status per request is checked (TOP 1 ORDER BY Id DESC)
- RequestStatusId = 2 identifies failed requests
- Error code extracted: JSON_VALUE(DetailsJson, '$.Code') or fallback to JSON_VALUE(DetailsJson, '$.ErrorCode')
- Error message extracted: JSON_VALUE(DetailsJson, '$.ResponseMessage') or fallback to JSON_VALUE(DetailsJson, '$.ErrorMessage')
- Known benign errors excluded via LEFT JOIN to Monitoring.ExcludedErrors using LIKE pattern matching
- Results grouped by operation type, error code, and error message

### 2.2 Benign Error Exclusion

**What**: Filters out errors already catalogued in Monitoring.ExcludedErrors.

**Columns/Parameters Involved**: `ExcludedErrors.ErrorMessage`, `RequestStatuses.DetailsJson`

**Rules**:
- LEFT JOIN on `rs.DetailsJson LIKE ee.ErrorMessage`
- WHERE ee.ErrorMessage IS NULL keeps only unmatched (real) errors
- See [Monitoring.ExcludedErrors](../Tables/Monitoring.ExcludedErrors.md) for the full list of 28 exclusion patterns

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationId | TINYINT | NO | - | CODE-BACKED | Operation type ID to report on. From Dictionary.RequestTypes. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of reporting period (inclusive). |
| 3 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of reporting period (inclusive). |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | TINYINT | NO | - | CODE-BACKED | Request type ID (same as @OperationId). |
| 2 | Name | NVARCHAR | NO | - | CODE-BACKED | Human-readable operation type name from Dictionary.RequestTypes. |
| 3 | Code | NVARCHAR | YES | - | CODE-BACKED | Error code extracted from JSON (e.g., "WL.0221"). |
| 4 | error | NVARCHAR | YES | - | CODE-BACKED | Error message extracted from JSON. |
| 5 | FailuresCount | INT | NO | - | CODE-BACKED | Number of failures with this specific error code/message combination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Source of request records |
| Query body | Wallet.RequestStatuses | JOIN | Status records with error details |
| Query body | Dictionary.RequestTypes | JOIN | Operation type names |
| Query body | Monitoring.ExcludedErrors | LEFT JOIN (LIKE) | Benign error exclusion |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring/reporting tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.OperationFailuresCountReport (procedure)
  ├── Wallet.Requests (table)
  ├── Wallet.RequestStatuses (table)
  ├── Dictionary.RequestTypes (table)
  └── Monitoring.ExcludedErrors (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - request records |
| Wallet.RequestStatuses | Table | JOIN - error details |
| Dictionary.RequestTypes | Table | JOIN - type names |
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
| EXECUTE AS OWNER | Security | Runs with schema owner permissions for cross-schema access |

---

## 8. Sample Queries

### 8.1 Check send operation failures for today
```sql
EXEC Monitoring.OperationFailuresCountReport @OperationId = 1, @FromDate = '2026-04-15', @ToDate = '2026-04-16';
```

### 8.2 Check wallet creation failures for last week
```sql
EXEC Monitoring.OperationFailuresCountReport @OperationId = 0,
  @FromDate = '2026-04-08', @ToDate = '2026-04-15';
```

### 8.3 View all request type IDs
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
*Object: Monitoring.OperationFailuresCountReport | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.OperationFailuresCountReport.sql*
