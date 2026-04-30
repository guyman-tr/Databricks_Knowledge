# Wallet.DoesRequestContainStatus

> Stored procedure that checks whether a request identified by CorrelationId has ever had a specific status (by numeric StatusId), returning a BIT flag.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns BIT (1=status exists, 0=not found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.DoesRequestContainStatus checks whether a wallet request (identified by its CorrelationId) has ever transitioned through a specific status in its lifecycle history. Unlike the scalar function `Wallet.DoesRequestStatusExist` which accepts a status name, this procedure accepts a numeric StatusId and looks up the request via CorrelationId rather than RequestId.

This procedure serves as a quick boolean check for application code that needs to determine request lifecycle state - for example, checking whether a request has been acknowledged, processed, or errored before taking further action.

The procedure joins `Wallet.Requests` to `Wallet.RequestStatuses` to search for a matching status entry, returning a single-row single-column result set with 1 (true) or 0 (false).

---

## 2. Business Logic

### 2.1 Status Existence Check by CorrelationId

**What**: Determines if any status history entry exists for a request matching both the CorrelationId and StatusId.

**Columns/Parameters Involved**: `@CorrelationId`, `@StatusId`

**Rules**:
- Finds the request by `Wallet.Requests.CorrelationId = @CorrelationId`
- LEFT JOINs to `Wallet.RequestStatuses` filtered to `RequestStatusId = @StatusId`
- Uses EXISTS pattern with CASE to return BIT: 1 if any matching status row found, 0 otherwise
- Checks "has ever been" not "currently is" - once a status is recorded, this returns 1 permanently
- Uses NOLOCK hints on both tables

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Cross-system correlation ID that identifies the request. Used to find the request in Wallet.Requests (matched on r.CorrelationId). |
| 2 | @StatusId | int | NO | - | CODE-BACKED | Numeric status ID to search for in the request's status history (FK to Dictionary.RequestStatuses.Id). Unlike DoesRequestStatusExist which takes a name, this takes the raw ID. |
| 3 | Result (BIT) | bit | NO | - | CODE-BACKED | Single-column result set: CAST(1 AS BIT) if the status exists in the request's history, CAST(0 AS BIT) otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.Requests | FROM | Finds the request record by CorrelationId |
| @StatusId | Wallet.RequestStatuses | LEFT JOIN | Searches for status entries matching the given StatusId |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Called from application code for status lifecycle checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.DoesRequestContainStatus (procedure)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - finds request by CorrelationId |
| Wallet.RequestStatuses | Table | LEFT JOIN - searches for matching status |

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

### 8.1 Check if a request has reached status 5 (Done)
```sql
EXEC Wallet.DoesRequestContainStatus @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890', @StatusId = 5
```

### 8.2 Check if a request has encountered an error (status 3)
```sql
EXEC Wallet.DoesRequestContainStatus @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890', @StatusId = 3
```

### 8.3 Use in conditional logic
```sql
DECLARE @HasDone BIT
SELECT @HasDone = (SELECT TOP 1 1 FROM Wallet.Requests r WITH (NOLOCK)
    LEFT JOIN Wallet.RequestStatuses rs WITH (NOLOCK) ON rs.RequestId = r.Id
    WHERE rs.RequestStatusId = 5 AND r.CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.DoesRequestContainStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.DoesRequestContainStatus.sql*
