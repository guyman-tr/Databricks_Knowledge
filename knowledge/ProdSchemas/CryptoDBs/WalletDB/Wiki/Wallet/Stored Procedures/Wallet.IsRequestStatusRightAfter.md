# Wallet.IsRequestStatusRightAfter

> Checks whether a specific request status transition occurred in the correct order - verifying that @AfterRequestStatusId immediately follows @BeforeRequestStatusId in the status history for the AML service's validation logic.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1/0 for sequential status transition check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure validates that a specific status transition occurred in the correct sequence. The AML service uses this to verify that request status changes happened in the expected order - e.g., confirming that status 5 immediately followed status 3, without intervening statuses. This is important for compliance audit trail validation.

The check finds the most recent occurrence of @BeforeRequestStatusId, then verifies that @AfterRequestStatusId exists with a later timestamp AND with a sequential RequestStatusId (BeforeStatusId + 1).

---

## 2. Business Logic

### 2.1 Sequential Status Transition Validation

**What**: Verifies two statuses occurred in direct sequence.

**Columns/Parameters Involved**: `@BeforeRequestStatusId`, `@AfterRequestStatusId`

**Rules**:
- Finds TOP 1 of @BeforeRequestStatusId (latest occurrence) for the request
- Checks if @AfterRequestStatusId exists with: same RequestId, Timestamp > BeforeTimestamp, AND RequestStatusId = BeforeStatusId + 1
- Returns 1 if the transition was direct/sequential, 0 otherwise
- The +1 check ensures no status was skipped between them

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Request to check. |
| 2 | @BeforeRequestStatusId | int | NO | - | VERIFIED | The expected earlier status. |
| 3 | @AfterRequestStatusId | int | NO | - | VERIFIED | The expected later status (must be BeforeStatusId + 1). |
| 4 | (result) | int | NO | - | CODE-BACKED | 1 = transition was sequential, 0 = not found or not sequential. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.Requests | JOIN | Request identification |
| - | Wallet.RequestStatuses | Subquery + JOIN | Sequential status check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | Compliance status transition validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.IsRequestStatusRightAfter (procedure)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | CorrelationId lookup |
| Wallet.RequestStatuses | Table | Sequential status check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if status 5 immediately followed status 3
```sql
EXEC Wallet.IsRequestStatusRightAfter @CorrelationId='YOUR-GUID', @BeforeRequestStatusId=3, @AfterRequestStatusId=5;
```

### 8.2 Check sequential progression
```sql
-- Verify status 4 directly followed status 3
EXEC Wallet.IsRequestStatusRightAfter @CorrelationId='YOUR-GUID', @BeforeRequestStatusId=3, @AfterRequestStatusId=4;
```

### 8.3 Check full status history manually
```sql
SELECT rs.RequestStatusId, rs.Timestamp FROM Wallet.RequestStatuses rs WITH (NOLOCK)
    JOIN Wallet.Requests r WITH (NOLOCK) ON r.Id = rs.RequestId
WHERE r.CorrelationId = 'YOUR-GUID' ORDER BY rs.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.IsRequestStatusRightAfter | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.IsRequestStatusRightAfter.sql*
