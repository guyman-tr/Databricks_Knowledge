# Wallet.GetTransactionErrors

> Retrieves the complete transaction error code catalog from the Dictionary schema, providing error source, code, message, monitoring policy, and internal classification for all known blockchain transaction errors.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Dictionary.TransactionErrorCodes |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete catalog of known blockchain transaction error codes from `Dictionary.TransactionErrorCodes`. Each row defines an error that can occur during blockchain transaction execution, including the error source (which provider/system reported it), the error code and message, the monitoring policy (how the system should respond), and an optional internal error classification.

Two services consume this procedure: the executer service (which matches runtime errors against this catalog to determine retry/escalation behavior) and the monitor service (which uses the monitoring policy to decide alerting thresholds). The catalog is loaded into memory at service startup and refreshed periodically, acting as a configuration table for error handling behavior.

The error catalog captures errors from multiple sources including blockchain providers (BitGo, CUG), internal systems, and network-level errors. Each error is tagged with a monitoring policy that determines whether it triggers immediate alerts, is silently retried, or requires manual intervention.

---

## 2. Business Logic

### 2.1 Error Classification System

**What**: Each error code is classified by source, monitoring severity, and internal category.

**Columns/Parameters Involved**: `ErrorSourceId`, `ErrorCode`, `ErrorMessage`, `ErrorMonitoringPolicyId`, `InternalTransactionErrorCodeId`

**Rules**:
- ErrorSourceId identifies which system reported the error (FK to Dictionary.ErrorSources)
- ErrorCode is the raw error code from the source system (e.g., HTTP status codes like "400", "429")
- ErrorMessage is the human-readable description
- ErrorMonitoringPolicyId determines alerting behavior (FK to Dictionary.ErrorMonitoringPolicies)
- InternalTransactionErrorCodeId maps to a normalized internal classification (FK to Dictionary.InternalTransactionErrorCodes)
- The combination (ErrorSourceId, ErrorCode, ErrorMessage) is unique - same code from same source with different messages are distinct errors

---

## 3. Data Overview

N/A for stored procedure. Returns full catalog. Sample entries:

| Id | ErrorSourceId | ErrorCode | ErrorMessage | ErrorMonitoringPolicyId | Meaning |
|---|---|---|---|---|---|
| 1 | 1 | 429 | too many requests, slow down! | 1 | Rate limiting by blockchain provider. Monitoring policy 1: auto-retry with backoff. |
| 2 | 1 | 404 | wallet transaction not found | 3 | Transaction hash not found on blockchain. Policy 3: may indicate dropped transaction. |
| 4 | 1 | 400 | invalid wallet id | 2 | Provider rejected the wallet identifier. Policy 2: requires investigation. |
| 5 | 1 | 515 | possible man-in-the-middle-attack | 2 | Security alert from provider. Policy 2: immediate investigation required. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id (output) | smallint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing error code catalog ID. |
| 2 | ErrorSourceId (output) | tinyint | NO | - | VERIFIED | System that reports this error. FK to Dictionary.ErrorSources. Identifies whether the error comes from a blockchain provider, internal service, or network layer. |
| 3 | ErrorCode (output) | varchar(20) | YES | - | CODE-BACKED | Raw error code from the source system. Often HTTP status codes (400, 429, 404) but can be provider-specific codes. NULL for errors identified only by message. |
| 4 | ErrorMessage (output) | varchar(255) | YES | - | CODE-BACKED | Human-readable error description from the source system. Used for both matching (the unique index includes this) and display. |
| 5 | ErrorMonitoringPolicyId (output) | tinyint | NO | - | VERIFIED | Determines the system's response to this error. FK to Dictionary.ErrorMonitoringPolicies. Controls retry behavior, alerting thresholds, and escalation paths. |
| 6 | InternalTransactionErrorCodeId (output) | tinyint | YES | - | CODE-BACKED | Maps the provider-specific error to a normalized internal classification. FK to Dictionary.InternalTransactionErrorCodes. NULL when no internal mapping exists (unmapped provider errors). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ErrorSourceId | Dictionary.ErrorSources | FK | Identifies the error-reporting system |
| ErrorMonitoringPolicyId | Dictionary.ErrorMonitoringPolicies | FK | Determines alerting/retry behavior |
| InternalTransactionErrorCodeId | Dictionary.InternalTransactionErrorCodes | FK | Normalized internal error classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Loads error catalog for runtime error matching |
| MonitorUser | - | EXECUTE | Loads error catalog for monitoring policy evaluation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetTransactionErrors (procedure)
+-- Dictionary.TransactionErrorCodes (table)
      +-- Dictionary.ErrorSources (table)
      +-- Dictionary.ErrorMonitoringPolicies (table)
      +-- Dictionary.InternalTransactionErrorCodes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TransactionErrorCodes | Table | Full table scan - returns all rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |
| MonitorUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Load the full error catalog
```sql
EXEC Wallet.GetTransactionErrors;
```

### 8.2 Direct query with error source names
```sql
SELECT tec.Id, es.Name AS ErrorSource, tec.ErrorCode, tec.ErrorMessage,
       emp.Name AS MonitoringPolicy
FROM Dictionary.TransactionErrorCodes tec WITH (NOLOCK)
    JOIN Dictionary.ErrorSources es WITH (NOLOCK) ON es.Id = tec.ErrorSourceId
    JOIN Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK) ON emp.Id = tec.ErrorMonitoringPolicyId
ORDER BY tec.Id;
```

### 8.3 Find high-severity errors
```sql
SELECT tec.Id, tec.ErrorCode, tec.ErrorMessage, tec.ErrorMonitoringPolicyId
FROM Dictionary.TransactionErrorCodes tec WITH (NOLOCK)
WHERE tec.ErrorMonitoringPolicyId = 2  -- Investigation required
ORDER BY tec.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetTransactionErrors | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetTransactionErrors.sql*
