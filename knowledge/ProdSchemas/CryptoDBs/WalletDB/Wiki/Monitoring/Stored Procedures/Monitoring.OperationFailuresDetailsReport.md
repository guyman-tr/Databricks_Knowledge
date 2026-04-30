# Monitoring.OperationFailuresDetailsReport

> Returns detailed per-request failure information for a specific operation type and error message, enabling drill-down from the count report to individual affected customers and wallets.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns individual failed requests filtered by operation and error message |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.OperationFailuresDetailsReport is the drill-down companion to OperationFailuresCountReport. While the count report shows aggregated failure counts by error code, this procedure shows individual failed requests for a specific error message, including customer, wallet, and provider details. This enables investigation of specific error patterns.

Without this procedure, investigating a specific error pattern would require manual SQL queries across multiple tables. This procedure provides a ready-made investigation tool.

The procedure filters by both @OperationId and @ErrorMessage (matching against both ResponseMessage and ErrorMessage JSON fields), joins to CustomerWalletsView for wallet/provider details, and excludes benign errors via ExcludedErrors.

---

## 2. Business Logic

### 2.1 Error-Specific Detail Lookup

**What**: Retrieves individual requests matching a specific error message pattern.

**Columns/Parameters Involved**: `@OperationId`, `@ErrorMessage`, `DetailsJson`

**Rules**:
- Matches on JSON_VALUE(DetailsJson, '$.ResponseMessage') = @ErrorMessage OR JSON_VALUE(DetailsJson, '$.ErrorMessage') = @ErrorMessage
- Only most recent status per request (TOP 1 ORDER BY Id DESC)
- RequestStatusId = 2 (failed)
- Excludes benign errors via ExcludedErrors LEFT JOIN
- Joins to CustomerWalletsView on Gcid + CryptoID for wallet context
- Runs with EXECUTE AS OWNER

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationId | TINYINT | NO | - | CODE-BACKED | Operation type to filter by. |
| 2 | @ErrorMessage | NVARCHAR(500) | NO | - | CODE-BACKED | Exact error message to match (from count report). |
| 3 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of period. |
| 4 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of period. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationId | TINYINT | NO | - | CODE-BACKED | Request type ID. |
| 2 | Name | NVARCHAR | NO | - | CODE-BACKED | Operation type name. |
| 3 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Request correlation ID for tracing. |
| 4 | CryptoID | INT | NO | - | CODE-BACKED | Cryptocurrency involved. |
| 5 | Gcid | INT | NO | - | CODE-BACKED | Customer ID. |
| 6 | WalletId | BIGINT | NO | - | CODE-BACKED | Customer's wallet ID. |
| 7 | ProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Blockchain provider wallet ID from CustomerWalletsView. |
| 8 | DetailsJson | NVARCHAR | YES | - | CODE-BACKED | Full JSON error details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Request records |
| Query body | Wallet.RequestStatuses | JOIN | Error status details |
| Query body | Dictionary.RequestTypes | JOIN | Operation type names |
| Query body | Wallet.CustomerWalletsView | JOIN | Wallet and provider details |
| Query body | Monitoring.ExcludedErrors | LEFT JOIN (LIKE) | Benign error exclusion |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring/reporting tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.OperationFailuresDetailsReport (procedure)
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

### 8.1 Drill into specific error
```sql
EXEC Monitoring.OperationFailuresDetailsReport
  @OperationId = 1,
  @ErrorMessage = 'insufficient balance',
  @FromDate = '2026-04-15',
  @ToDate = '2026-04-16';
```

### 8.2 Check wallet creation permission errors
```sql
EXEC Monitoring.OperationFailuresDetailsReport
  @OperationId = 0,
  @ErrorMessage = 'User has no permission to create a wallet',
  @FromDate = '2026-04-08',
  @ToDate = '2026-04-15';
```

### 8.3 Find unique error messages for an operation
```sql
SELECT DISTINCT
  CASE WHEN JSON_VALUE(rs.DetailsJson, '$.ResponseMessage') IS NOT NULL
    THEN JSON_VALUE(rs.DetailsJson, '$.ResponseMessage')
    ELSE JSON_VALUE(rs.DetailsJson, '$.ErrorMessage') END AS ErrorMsg
FROM Wallet.Requests r WITH (NOLOCK)
JOIN Wallet.RequestStatuses rs WITH (NOLOCK) ON r.Id = rs.RequestId
WHERE r.RequestTypeId = 1 AND rs.RequestStatusId = 2
  AND r.Timestamp >= DATEADD(DAY, -7, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.OperationFailuresDetailsReport | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.OperationFailuresDetailsReport.sql*
