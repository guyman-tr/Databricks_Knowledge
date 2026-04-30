# Wallet.GetUnnotifiedRedeemRequests

> Identifies redemption requests that were sent to the executer but resulted in an error status and have not been notified/retried within a configurable timeout, used by the redeem scheduler for error recovery.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns unnotified failed redemption requests exceeding timeout |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds redemption requests that failed during execution and haven't been handled yet. Specifically, it looks for redemptions with status 2 (SentToExecuter) where no corresponding sent transaction exists (the blockchain send was never created) AND the request's latest status is 'Error', AND the error has been unresolved for longer than the configurable timeout.

The redeem scheduler service uses this to detect redemptions that need retry or escalation - cases where the request was submitted but the blockchain execution failed before creating a SentTransaction record. The CROSS APPLY with the `drs.Name = 'Error'` filter ensures only error-state requests are returned, not requests that are still in normal processing.

---

## 2. Business Logic

### 2.1 Failed Redemption Detection

**What**: Finds redemptions sent to the executer that failed without creating a blockchain transaction.

**Columns/Parameters Involved**: `RedemptionStatus`, `SentTransactions.Id`, `Dictionary.RequestStatuses.Name`

**Rules**:
- RedemptionStatus = 2 (SentToExecuter) - the redemption was forwarded to execution
- LEFT JOIN to SentTransactions WHERE st.Id IS NULL - no blockchain transaction was created
- CROSS APPLY to RequestStatuses with Dictionary.RequestStatuses.Name = 'Error' - latest request status is Error
- DATEDIFF(MINUTE, LastStatusOccurred, GETDATE()) > @ExecuterMaxProcessingTimeMinutes - error has been unresolved beyond timeout
- Returns billing-relevant fields (BillingRedeemId, BillingTransId) for notification

**Diagram**:
```
Redemption (status=2 SentToExecuter)
        |
        +-- No SentTransaction exists (LEFT JOIN IS NULL)
        |
        +-- Request latest status = 'Error'
        |
        +-- Error age > @ExecuterMaxProcessingTimeMinutes
        |
        v
  UNNOTIFIED FAILED REDEMPTION
  (needs retry or escalation)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecuterMaxProcessingTimeMinutes | int | NO | - | VERIFIED | Maximum time in minutes before a failed redemption is flagged as unnotified. |
| 2 | Id (output) | bigint | NO | - | CODE-BACKED | Redemption record ID. |
| 3 | BillingRedeemId (output) | bigint | YES | - | CODE-BACKED | Billing system's redemption ID for notification/reconciliation with the trading platform. |
| 4 | CryptoId (output) | int | NO | - | VERIFIED | Cryptocurrency being redeemed. FK to Wallet.CryptoTypes. |
| 5 | CorrelationId (output) | uniqueidentifier | YES | - | CODE-BACKED | Send request correlation ID (aliased from SendRequestCorrelationId). Links to Wallet.Requests. |
| 6 | BillingTransId (output) | bigint | YES | - | CODE-BACKED | Billing system's transaction ID. |
| 7 | Amount (output) | decimal | NO | - | CODE-BACKED | Requested redemption amount (aliased from RequestedAmount). |
| 8 | RedemptionPositionId (output) | bigint | YES | - | CODE-BACKED | Trading position ID being redeemed (aliased from PositionId). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedemptionStatus=2 | Wallet.Redemptions | Filter | SentToExecuter redemptions |
| SendRequestCorrelationId | Wallet.SentTransactions.CorrelationId | LEFT JOIN (IS NULL) | Confirms no blockchain tx exists |
| CorrelationId | Wallet.Requests.CorrelationId | JOIN | Links to request for status check |
| RequestStatusId | Wallet.RequestStatuses + Dictionary.RequestStatuses | CROSS APPLY | Latest error status with timeout check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemSchedulerUser | - | EXECUTE | Error recovery for failed redemptions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetUnnotifiedRedeemRequests (procedure)
+-- Wallet.Redemptions (table)
+-- Wallet.SentTransactions (table)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
+-- Dictionary.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | Source of SentToExecuter redemptions |
| Wallet.SentTransactions | Table | LEFT JOIN to detect missing blockchain tx |
| Wallet.Requests | Table | JOIN via CorrelationId for status access |
| Wallet.RequestStatuses | Table | CROSS APPLY for latest status timestamp |
| Dictionary.RequestStatuses | Table | JOIN for status name filter ('Error') |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemSchedulerUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find redemptions stuck in error for over 30 minutes
```sql
EXEC Wallet.GetUnnotifiedRedeemRequests @ExecuterMaxProcessingTimeMinutes = 30;
```

### 8.2 Compare with stuck redeems (sibling SP)
```sql
-- Failed without creating a SentTransaction (this SP):
EXEC Wallet.GetUnnotifiedRedeemRequests @ExecuterMaxProcessingTimeMinutes = 30;
-- Stuck after creating a SentTransaction:
EXEC Wallet.GetStuckRedeemRequests @ExecuterMaxProcessingTimeMinutes = 30;
```

### 8.3 Direct diagnostic query
```sql
SELECT re.Id, re.BillingRedeemId, re.CryptoId, re.SendRequestCorrelationId,
    re.RequestedAmount, re.PositionId
FROM Wallet.Redemptions re WITH (NOLOCK)
    LEFT JOIN Wallet.SentTransactions st WITH (NOLOCK) ON st.CorrelationId = re.SendRequestCorrelationId
    JOIN Wallet.Requests r WITH (NOLOCK) ON r.CorrelationId = re.SendRequestCorrelationId
    CROSS APPLY (
        SELECT TOP 1 rs.Timestamp, drs.Name
        FROM Wallet.RequestStatuses rs WITH (NOLOCK)
            JOIN Dictionary.RequestStatuses drs WITH (NOLOCK) ON drs.Id = rs.RequestStatusId AND drs.Name = 'Error'
        WHERE rs.RequestId = r.Id ORDER BY rs.Id DESC
    ) rs
WHERE re.RedemptionStatus = 2 AND st.Id IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetUnnotifiedRedeemRequests | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetUnnotifiedRedeemRequests.sql*
