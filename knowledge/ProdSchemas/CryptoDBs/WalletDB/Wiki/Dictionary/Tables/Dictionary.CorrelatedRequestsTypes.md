# Dictionary.CorrelatedRequestsTypes

> Lookup table defining the types of correlated (idempotent) requests used to prevent duplicate processing of wallet operations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table classifies the types of correlated requests tracked by the wallet system's idempotency mechanism. When external systems call wallet APIs, they include a correlation ID to prevent the same operation from being processed twice (e.g., due to network retries or duplicate messages). Each correlation is typed to distinguish between different operation categories.

Idempotency is critical in financial systems - processing a withdrawal twice would result in double-spending. The `Wallet.CorrelatedRequests` table stores correlation records, and this dictionary provides the type classification.

Currently only one type (`Bounceback`) is defined, suggesting the correlated request mechanism was initially built for bounceback operations and may expand to cover other operation types.

---

## 2. Business Logic

### 2.1 Bounceback Correlation

**What**: Bounceback operations require idempotency tracking to prevent duplicate refund processing.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Bounceback` (1): A bounceback occurs when the platform returns received cryptocurrency to the sender because the deposit cannot be processed (e.g., unsupported token, compliance block, unregistered address). Bounceback correlation ensures the return transaction is not accidentally sent twice.

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Bounceback | Correlation type for bounceback (return-to-sender) operations. When the platform receives crypto that cannot be accepted, a bounceback sends it back. This correlation ensures the return is processed exactly once, preventing duplicate refunds that would result in financial loss. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the correlated request type. Currently: 1=Bounceback. Referenced by Wallet.CorrelatedRequests to classify each idempotency record. |
| 2 | Name | varchar(128) | NO | - | CODE-BACKED | Descriptive label for the request type. Used in operational monitoring to filter and analyze correlated request patterns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK references found. Consumed implicitly by `Wallet.CorrelatedRequests` via application logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in the Wallet schema SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CorrelatedRequestsTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all correlated request types
```sql
SELECT Id, Name FROM Dictionary.CorrelatedRequestsTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count correlated requests by type
```sql
SELECT crt.Name, COUNT(cr.Id) AS RequestCount
FROM Dictionary.CorrelatedRequestsTypes crt WITH (NOLOCK)
LEFT JOIN Wallet.CorrelatedRequests cr WITH (NOLOCK) ON cr.CorrelatedRequestTypeId = crt.Id
GROUP BY crt.Name
```

### 8.3 Recent bounceback correlation records
```sql
SELECT cr.CorrelationId, crt.Name AS RequestType, cr.Created
FROM Wallet.CorrelatedRequests cr WITH (NOLOCK)
JOIN Dictionary.CorrelatedRequestsTypes crt WITH (NOLOCK) ON cr.CorrelatedRequestTypeId = crt.Id
WHERE crt.Id = 1
ORDER BY cr.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CorrelatedRequestsTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.CorrelatedRequestsTypes.sql*
