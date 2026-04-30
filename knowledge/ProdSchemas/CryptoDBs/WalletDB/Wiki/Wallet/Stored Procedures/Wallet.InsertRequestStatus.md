# Wallet.InsertRequestStatus

> Appends a status change event to a wallet request's lifecycle by CorrelationId, returning the number of affected rows, used by 9 service consumers for request state progression.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.RequestStatuses by CorrelationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a status change for a wallet request. Nine service accounts call this as requests progress through their lifecycle (e.g., Pending -> ExecuterEnqueued -> ReadByExecuter -> ExecuterCompleted or Error). The request is identified by CorrelationId. Empty DetailsJson is converted to NULL. Returns @@rowcount (1 on success, 0 if no matching request found).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Resolves RequestId from Requests.CorrelationId, INSERTs into RequestStatuses with GETDATE() timestamp.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID to identify the request. |
| 2 | @RequestStatusId | int | NO | - | VERIFIED | New status. FK to Dictionary.RequestStatuses. |
| 3 | @DetailsJson | varchar(max) | YES | - | CODE-BACKED | Optional JSON details. Empty string treated as NULL. |
| 4 | (return value) | int | NO | - | CODE-BACKED | @@rowcount - 1 if request found and status inserted, 0 if no matching request. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.Requests.CorrelationId | Lookup | Resolves RequestId |
| - | Wallet.RequestStatuses | INSERT | Appends status event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser, BackApiUser, ConversionUser, ExecuterUser, MonitorUser, RedeemSchedulerUser, ScheduledJobsUser, StakingUser, WalletMiddlewareUser | - | EXECUTE | Request lifecycle tracking (9 consumers) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertRequestStatus (procedure)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | CorrelationId lookup |
| Wallet.RequestStatuses | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser, BackApiUser, ConversionUser, ExecuterUser, MonitorUser, RedeemSchedulerUser, ScheduledJobsUser, StakingUser, WalletMiddlewareUser | Service Accounts | EXECUTE grants (9 consumers) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update request status
```sql
EXEC Wallet.InsertRequestStatus @CorrelationId = 'YOUR-GUID', @RequestStatusId = 5, @DetailsJson = NULL;
```

### 8.2 Update with details
```sql
EXEC Wallet.InsertRequestStatus @CorrelationId = 'YOUR-GUID', @RequestStatusId = 2, @DetailsJson = '{"Code":"WL.0102","Message":"Wallet creation rejected"}';
```

### 8.3 Check request status history
```sql
SELECT rs.*, drs.Name FROM Wallet.RequestStatuses rs WITH (NOLOCK) JOIN Dictionary.RequestStatuses drs WITH (NOLOCK) ON drs.Id = rs.RequestStatusId JOIN Wallet.Requests r WITH (NOLOCK) ON r.Id = rs.RequestId WHERE r.CorrelationId = 'YOUR-GUID' ORDER BY rs.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertRequestStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertRequestStatus.sql*
