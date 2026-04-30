# Wallet.TryAddCorrelatedRequest

> Attempts to link a child request to a parent request via CorrelatedRequests, inserting only if no record exists for the same type+parent combination, returning the existing or new record.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert-like INSERT into CorrelatedRequests |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a correlation link between a parent and child request. When a wallet operation spawns a sub-operation (e.g., a redemption spawning a send transaction), the redeem persistor service calls this to record the parent-child relationship. Idempotent: if a record already exists for the same type+parent, it returns the existing record instead of inserting a duplicate.

---

## 2. Business Logic

### 2.1 Idempotent Upsert Pattern

**What**: Inserts only if no record exists for the type+parent combination.

**Rules**:
- SELECT existing Id WHERE CorrelatedRequestsTypeId + ParentRequestCorrelationId match
- IF NULL: INSERT new record, capture SCOPE_IDENTITY
- Always returns the full record (existing or new) via final SELECT

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelatedRequestsTypeId | tinyint | NO | - | VERIFIED | Type of correlation. FK to Dictionary.CorrelatedRequestsTypes. |
| 2 | @ParentRequestCorrelationId | uniqueidentifier | NO | - | VERIFIED | Parent request's CorrelationId. |
| 3 | @ChildRequestCorrelationId | uniqueidentifier | NO | - | VERIFIED | Child request's CorrelationId. |
| 4 | (output row) | - | NO | - | CODE-BACKED | Returns Id, CorrelatedRequestsTypeId, ParentRequestCorrelationId, ChildRequestCorrelationId, Created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CorrelatedRequests | INSERT/SELECT | Correlation record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemPersistorUser | - | EXECUTE | Request correlation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TryAddCorrelatedRequest (procedure)
+-- Wallet.CorrelatedRequests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CorrelatedRequests | Table | Upsert target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemPersistorUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Link a child request to a parent
```sql
EXEC Wallet.TryAddCorrelatedRequest @CorrelatedRequestsTypeId=1, @ParentRequestCorrelationId='PARENT-GUID', @ChildRequestCorrelationId='CHILD-GUID';
```

### 8.2 Check correlations
```sql
SELECT * FROM Wallet.CorrelatedRequests WITH (NOLOCK) WHERE ParentRequestCorrelationId = 'PARENT-GUID';
```

### 8.3 Idempotent - second call returns existing
```sql
-- Both calls return the same record:
EXEC Wallet.TryAddCorrelatedRequest @CorrelatedRequestsTypeId=1, @ParentRequestCorrelationId='PARENT-GUID', @ChildRequestCorrelationId='CHILD-GUID';
EXEC Wallet.TryAddCorrelatedRequest @CorrelatedRequestsTypeId=1, @ParentRequestCorrelationId='PARENT-GUID', @ChildRequestCorrelationId='DIFFERENT-CHILD';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TryAddCorrelatedRequest | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.TryAddCorrelatedRequest.sql*
