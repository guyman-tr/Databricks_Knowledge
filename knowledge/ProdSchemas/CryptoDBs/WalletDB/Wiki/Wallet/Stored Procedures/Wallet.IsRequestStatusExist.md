# Wallet.IsRequestStatusExist

> Checks whether a specific request status exists in the status history for a request identified by CorrelationId, returning 1/0 for the AML, redeem scheduler, and wallet middleware services.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1/0 for status existence check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks whether a request has ever reached a specific status. The AML, redeem scheduler, and wallet middleware services call this to verify request lifecycle progression - e.g., confirming that a request has been acknowledged (status exists) before taking further action.

Unlike checking only the latest status, this checks the full status history - a request that was once in status X but has since progressed still returns 1.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. EXISTS check on RequestStatuses JOIN Requests by CorrelationId and RequestStatusId. Returns 1 (exists) or 0 (not found).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID identifying the request. |
| 2 | @RequestStatusId | int | NO | - | VERIFIED | Status ID to check for. FK to Dictionary.RequestStatuses. |
| 3 | (result) | int | NO | - | CODE-BACKED | 1 = status exists in history, 0 = never reached this status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.Requests.CorrelationId | JOIN | Request identification |
| @RequestStatusId | Wallet.RequestStatuses.RequestStatusId | EXISTS | Status history check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | AML status verification |
| RedeemSchedulerUser | - | EXECUTE | Redemption status checks |
| WalletMiddlewareUser | - | EXECUTE | Middleware status verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.IsRequestStatusExist (procedure)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | CorrelationId lookup |
| Wallet.RequestStatuses | Table | Status existence check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser, RedeemSchedulerUser, WalletMiddlewareUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if request reached a specific status
```sql
EXEC Wallet.IsRequestStatusExist @CorrelationId = 'YOUR-GUID', @RequestStatusId = 5;
```

### 8.2 Direct equivalent
```sql
IF EXISTS (SELECT 1 FROM Wallet.RequestStatuses rs WITH (NOLOCK)
    JOIN Wallet.Requests r WITH (NOLOCK) ON rs.RequestId = r.Id
    WHERE r.CorrelationId = 'YOUR-GUID' AND rs.RequestStatusId = 5) SELECT 1 ELSE SELECT 0;
```

### 8.3 Check multiple statuses
```sql
-- Check if request was ever acknowledged (e.g., status 3)
EXEC Wallet.IsRequestStatusExist @CorrelationId = 'YOUR-GUID', @RequestStatusId = 3;
-- Check if request was ever in error (e.g., status 2)
EXEC Wallet.IsRequestStatusExist @CorrelationId = 'YOUR-GUID', @RequestStatusId = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.IsRequestStatusExist | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.IsRequestStatusExist.sql*
