# Monitoring.OperationFailuresReport

> Returns per-request failure details for a specific operation type within a date range, showing customer, wallet, and error information while excluding known benign errors.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns individual failed requests for an operation type |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.OperationFailuresReport is similar to OperationFailuresDetailsReport but without the error message filter - it returns ALL failures for a given operation type. This provides a complete view of all non-excluded failures regardless of error type, useful for broad investigation or when the specific error code is not yet known.

Without this procedure, viewing all failures for an operation would require building the complex query with JSON parsing, wallet joins, and exclusion filtering manually.

---

## 2. Business Logic

### 2.1 Comprehensive Failure Listing

**What**: Lists all non-excluded failures for an operation type.

**Columns/Parameters Involved**: `@OperationId`, `RequestStatusId`, `DetailsJson`

**Rules**:
- Same base logic as OperationFailuresCountReport and OperationFailuresDetailsReport
- Only most recent status per request (TOP 1 ORDER BY Id DESC)
- RequestStatusId = 2 (failed)
- Excludes benign errors via ExcludedErrors LEFT JOIN
- No error message filter - returns ALL non-excluded failures
- Joins to CustomerWalletsView for wallet/provider context
- Runs with EXECUTE AS OWNER

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationId | TINYINT | NO | - | CODE-BACKED | Operation type to report on. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of period. |
| 3 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of period. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationId | TINYINT | NO | - | CODE-BACKED | Request type ID. |
| 2 | Name | NVARCHAR | NO | - | CODE-BACKED | Operation type name. |
| 3 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Request correlation ID. |
| 4 | CryptoID | INT | NO | - | CODE-BACKED | Cryptocurrency involved. |
| 5 | Gcid | INT | NO | - | CODE-BACKED | Customer ID. |
| 6 | WalletId | BIGINT | NO | - | CODE-BACKED | Customer's wallet ID. |
| 7 | ProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Blockchain provider wallet ID. |
| 8 | DetailsJson | NVARCHAR | YES | - | CODE-BACKED | Full JSON error details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Request records |
| Query body | Wallet.RequestStatuses | JOIN | Error status details |
| Query body | Dictionary.RequestTypes | JOIN | Operation type names |
| Query body | Wallet.CustomerWalletsView | JOIN | Wallet context |
| Query body | Monitoring.ExcludedErrors | LEFT JOIN (LIKE) | Benign error exclusion |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring/reporting tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.OperationFailuresReport (procedure)
  ├── Wallet.Requests (table)
  ├── Wallet.RequestStatuses (table)
  ├── Dictionary.RequestTypes (table)
  ├── Wallet.CustomerWalletsView (view)
  └── Monitoring.ExcludedErrors (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - request records |
| Wallet.RequestStatuses | Table | JOIN - error details |
| Dictionary.RequestTypes | Table | JOIN - type names |
| Wallet.CustomerWalletsView | View | JOIN - wallet context |
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

### 8.1 View all send failures for today
```sql
EXEC Monitoring.OperationFailuresReport @OperationId = 1, @FromDate = '2026-04-15', @ToDate = '2026-04-16';
```

### 8.2 View all receive failures for last week
```sql
EXEC Monitoring.OperationFailuresReport @OperationId = 8, @FromDate = '2026-04-08', @ToDate = '2026-04-15';
```

### 8.3 Compare total vs excluded failures
```sql
-- Total failures (including excluded)
SELECT COUNT(*) AS TotalFailures
FROM Wallet.Requests r WITH (NOLOCK)
JOIN Wallet.RequestStatuses rs WITH (NOLOCK) ON r.Id = rs.RequestId AND rs.RequestStatusId = 2
WHERE r.RequestTypeId = 1 AND r.Timestamp >= DATEADD(DAY, -1, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.OperationFailuresReport | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.OperationFailuresReport.sql*
