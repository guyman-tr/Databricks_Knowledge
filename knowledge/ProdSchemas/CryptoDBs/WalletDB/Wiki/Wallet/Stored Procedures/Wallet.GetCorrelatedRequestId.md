# Wallet.GetCorrelatedRequestId

> Stored procedure that looks up a correlated request record by its type and parent/child correlation IDs.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CorrelatedRequests.Id |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetCorrelatedRequestId resolves a correlated request record by matching on the correlation type, parent request correlation ID, and child request correlation ID. Correlated requests represent parent-child relationships between wallet requests - for example, a conversion request may spawn child send/receive requests that are tracked as correlated.

This procedure is used by application services to check whether a correlation record already exists before creating a new one (idempotency), or to retrieve the correlation ID for further processing.

---

## 2. Business Logic

No complex business logic. Simple exact-match SELECT on three columns against Wallet.CorrelatedRequests.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelatedRequestsTypeId | tinyint | NO | - | CODE-BACKED | Type of correlation between the parent and child requests. Defines the semantic relationship. |
| 2 | @ParentRequestCorrelationId | uniqueidentifier | NO | - | CODE-BACKED | The CorrelationId of the parent (initiating) request. |
| 3 | @ChildRequestCorrelationId | uniqueidentifier | NO | - | CODE-BACKED | The CorrelationId of the child (spawned) request. |
| 4 | Id (result) | bigint | YES | - | CODE-BACKED | The CorrelatedRequests record ID if found, or empty result set if no match exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Wallet.CorrelatedRequests | FROM | Exact-match lookup with NOLOCK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Correlation record lookup and idempotency |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetCorrelatedRequestId (procedure)
+-- Wallet.CorrelatedRequests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CorrelatedRequests | Table | FROM with NOLOCK |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up a correlation record
```sql
EXEC Wallet.GetCorrelatedRequestId
    @CorrelatedRequestsTypeId = 1,
    @ParentRequestCorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @ChildRequestCorrelationId = 'B2C3D4E5-F6A7-8901-BCDE-F12345678901'
```

### 8.2 See all correlations for a parent request
```sql
SELECT * FROM Wallet.CorrelatedRequests WITH (NOLOCK)
WHERE ParentRequestCorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
```

### 8.3 Count correlations by type
```sql
SELECT CorrelatedRequestsTypeId, COUNT(*) AS Count
FROM Wallet.CorrelatedRequests WITH (NOLOCK)
GROUP BY CorrelatedRequestsTypeId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetCorrelatedRequestId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetCorrelatedRequestId.sql*
