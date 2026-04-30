# Dictionary.TransactionErrorCodes

> Master catalog of all known transaction error codes across all provider sources, mapping each specific error to its source system, monitoring policy, and internal error classification.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (smallint IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + unique composite on Source+Code+Message) |

---

## 1. Business Meaning

This table is the central error code registry for the wallet platform's transaction processing system. Every known error that can occur during blockchain transactions is cataloged here with its source system (BitGo, SQL, General), the specific error code and message, the monitoring policy that governs retry/alerting behavior, and optionally an internal error classification.

When a transaction fails, the system looks up the error in this table to determine: (a) which monitoring policy to apply (how long to retry, how often to check), (b) whether the error maps to an internal error code (e.g., InsufficientFunds), and (c) which team should investigate based on the error source.

The table currently contains 31 error codes, primarily from BitGo (source 1) with some General (source 3) errors. It is consumed by `Wallet.GetTransactionErrors` stored procedure and references three other Dictionary tables via FK constraints.

---

## 2. Business Logic

### 2.1 Error Code Classification Matrix

**What**: Each error code is classified along three dimensions: source, monitoring policy, and internal code.

**Columns/Parameters Involved**: `ErrorSourceId`, `ErrorCode`, `ErrorMessage`, `ErrorMonitoringPolicyId`, `InternalTransactionErrorCodeId`

**Rules**:
- **Source + Code + Message is unique**: The composite unique index ensures no duplicate error registrations
- **ErrorSourceId** determines which team investigates: 1=Bitgo (crypto infra), 2=SQL (DB team), 3=General (app team)
- **ErrorMonitoringPolicyId** determines retry behavior: from TemporaryHiccup (retry aggressively) to ImmaditaeFailure (no retry)
- **InternalTransactionErrorCodeId** is nullable - only populated when the external error maps to a known internal condition (e.g., InsufficientFunds)

### 2.2 Common Error Patterns

**What**: Error codes cluster into recognizable patterns by source and severity.

**Rules**:
- **BitGo 429 (rate limit)**: TemporaryHiccup policy - just slow down and retry
- **BitGo 400 (invalid wallet/amount)**: PermanentError - configuration or data issue
- **BitGo 404 (not found)**: Varies - "wallet transaction not found" is PermanentErrorForOneWeek, "task canceled" is TentativeTimeout
- **BitGo 450 (invalid status)**: "failed" gets HalfHourRetry, "removed/rejected" gets TemporaryHiccup
- **BitGo 500 (server error)**: PermanentError - provider infrastructure issue
- **BitGo 515 (MITM)**: PermanentError - security issue
- **General (empty code)**: TemporaryHiccup for transient application errors

**Diagram**:
```
Transaction Error
    |
    +---> Look up in TransactionErrorCodes by (Source, Code, Message)
    |
    +---> Found? --> Apply ErrorMonitoringPolicy retry rules
    |                Map to InternalTransactionErrorCode if applicable
    |
    +---> Not found? --> Default handling (General/TemporaryHiccup)
```

---

## 3. Data Overview

| Id | ErrorSourceId | ErrorCode | ErrorMessage | ErrorMonitoringPolicyId | Meaning |
|---|---|---|---|---|---|
| 1 | 1 (Bitgo) | 429 | too many requests, slow down! | 1 (TemporaryHiccup) | BitGo API rate limit hit. Automatically resolved by reducing request frequency. Most common transient error. |
| 5 | 1 (Bitgo) | 515 | possible man-in-the-middle-attack | 2 (PermanentErrorForOneDay) | Security alert from BitGo. Requires urgent investigation - possible network compromise or certificate issue. |
| 11 | 1 (Bitgo) | 404 | transaction attempted to double spend | 1 (TemporaryHiccup) | Bitcoin double-spend attempt detected. Usually caused by transaction malleability or UTXO race condition. |
| 17 | 1 (Bitgo) | 500 | Coin or token type eurx not supported | 5 (ImmaditaeFailure) | Attempted operation on unsupported cryptocurrency. Permanent configuration error - no retry possible. |
| 18 | 1 (Bitgo) | 400 | fee too low | 5 (ImmaditaeFailure) | Transaction fee below blockchain minimum. The transaction must be reconstructed with a higher fee. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | smallint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing unique identifier. 31 error codes currently registered. Uses smallint (not tinyint) to accommodate growth - error codes are added as new failure modes are discovered. |
| 2 | ErrorSourceId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.ErrorSources. Identifies which system component generated the error. Values: 1=Bitgo (blockchain provider), 2=SQL (database), 3=General (application). Determines investigation routing. |
| 3 | ErrorCode | varchar(20) | YES | - | CODE-BACKED | Provider-specific error code (e.g., HTTP status codes "400", "404", "429", "500"). Nullable and may be empty string for General source errors that don't have specific codes. |
| 4 | ErrorMessage | varchar(255) | YES | - | CODE-BACKED | Human-readable error description from the provider. Combined with ErrorCode to uniquely identify the error scenario. Examples: "too many requests, slow down!", "wallet not found", "fee too low". |
| 5 | ErrorMonitoringPolicyId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.ErrorMonitoringPolicies. Determines how the monitoring system handles this error: retry frequency, monitoring window duration, and alerting behavior. Values: 1=TemporaryHiccup, 2=PermanentErrorForOneDay, 3=PermanentErrorForOneWeek, 4=TentativeTimeoutError, 5=ImmaditaeFailure, 6=HalfHourRetry. |
| 6 | InternalTransactionErrorCodeId | tinyint | YES | - | CODE-BACKED | FK to Dictionary.InternalTransactionErrorCodes. Nullable - only populated when the external error maps to a known internal condition. Currently only value is 1=InsufficientFunds. NULL for most errors that don't have an internal equivalent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ErrorSourceId | Dictionary.ErrorSources | FK | Source system that generated the error (Bitgo/SQL/General) |
| ErrorMonitoringPolicyId | Dictionary.ErrorMonitoringPolicies | FK | Retry and alerting policy applied to this error |
| InternalTransactionErrorCodeId | Dictionary.InternalTransactionErrorCodes | FK (nullable) | Internal error classification (e.g., InsufficientFunds) |

### 5.2 Referenced By (other objects point to this)

No direct FK references from other tables. Consumed by the error handling system via application logic and SP lookups.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.TransactionErrorCodes (table)
  +-- Dictionary.ErrorMonitoringPolicies (table)
  |     +-- Dictionary.TransactionStatus (table)
  +-- Dictionary.ErrorSources (table)
  +-- Dictionary.InternalTransactionErrorCodes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ErrorMonitoringPolicies | Table | FK on ErrorMonitoringPolicyId |
| Dictionary.ErrorSources | Table | FK on ErrorSourceId |
| Dictionary.InternalTransactionErrorCodes | Table | FK on InternalTransactionErrorCodeId (nullable) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetTransactionErrors | Stored Procedure | Reads error codes with source and policy details |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TransactionErrorCodes | CLUSTERED | Id ASC | - | - | Active |
| IX_..._ErrorSourceId_ErrorCode_ErrorMessage | NONCLUSTERED UNIQUE | ErrorSourceId ASC, ErrorCode ASC, ErrorMessage ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_..._ErrorMonitoringPolicyId | FOREIGN KEY | -> Dictionary.ErrorMonitoringPolicies(Id) |
| FK_..._ErrorSourceId | FOREIGN KEY | -> Dictionary.ErrorSources(Id) |
| FK_..._InternalTransactionErrorCodeId | FOREIGN KEY | -> Dictionary.InternalTransactionErrorCodes(Id) (nullable) |
| IX (unique composite) | UNIQUE | No duplicate Source+Code+Message combinations |

---

## 8. Sample Queries

### 8.1 List all error codes with source and policy names
```sql
SELECT tec.Id, es.Name AS Source, tec.ErrorCode, tec.ErrorMessage,
       emp.Name AS MonitoringPolicy
FROM Dictionary.TransactionErrorCodes tec WITH (NOLOCK)
JOIN Dictionary.ErrorSources es WITH (NOLOCK) ON tec.ErrorSourceId = es.Id
JOIN Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK) ON tec.ErrorMonitoringPolicyId = emp.Id
ORDER BY es.Name, tec.ErrorCode
```

### 8.2 Find immediate-failure errors (no retry)
```sql
SELECT es.Name AS Source, tec.ErrorCode, tec.ErrorMessage
FROM Dictionary.TransactionErrorCodes tec WITH (NOLOCK)
JOIN Dictionary.ErrorSources es WITH (NOLOCK) ON tec.ErrorSourceId = es.Id
JOIN Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK) ON tec.ErrorMonitoringPolicyId = emp.Id
WHERE emp.Id = 5 -- ImmaditaeFailure
ORDER BY tec.ErrorCode
```

### 8.3 Error codes with internal classification
```sql
SELECT tec.Id, es.Name AS Source, tec.ErrorCode, tec.ErrorMessage,
       itec.Name AS InternalCode
FROM Dictionary.TransactionErrorCodes tec WITH (NOLOCK)
JOIN Dictionary.ErrorSources es WITH (NOLOCK) ON tec.ErrorSourceId = es.Id
LEFT JOIN Dictionary.InternalTransactionErrorCodes itec WITH (NOLOCK)
  ON tec.InternalTransactionErrorCodeId = itec.Id
WHERE tec.InternalTransactionErrorCodeId IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TransactionErrorCodes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.TransactionErrorCodes.sql*
