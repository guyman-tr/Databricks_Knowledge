# Monitoring.GetNoTravelRuleActivity

> Counts travel rule transactions that have had no status activity within the specified time window and are still in a pending/active state, detecting stalled travel rule processing.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of inactive travel rule transactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetNoTravelRuleActivity detects travel rule transactions that appear to be stalled - they have a pending or active status but no recent status updates. Travel rule compliance requires timely processing; transactions that sit without activity may indicate a failed integration with the travel rule provider or a processing bottleneck.

Without this procedure, stalled travel rule transactions would accumulate silently, potentially blocking customer withdrawals that require travel rule clearance.

The procedure finds TransactionTravelRuleInformation records where the latest status is in a non-terminal state (0=Pending, 3=AwaitingCounterparty, 4=ActionRequired, 5=InProgress) AND no status update has occurred within the @HoursBack window.

---

## 2. Business Logic

### 2.1 Stalled Transaction Detection

**What**: Identifies travel rule transactions with no recent status activity in non-terminal states.

**Columns/Parameters Involved**: `TravelRuleStatusId`, `@HoursBack`

**Rules**:
- Terminal statuses (1=Completed, 2=Cancelled) are excluded - these are resolved
- Active statuses checked: 0=Pending, 3=AwaitingCounterparty, 4=ActionRequired, 5=InProgress
- "No activity" = no TransactionTravelRuleStatuses record with Occurred in the last @HoursBack hours
- Default window: 24 hours

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursBack | INT | NO | 24 | CODE-BACKED | Hours without activity to consider a transaction stalled. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TransactionCountInXHors | INT | NO | - | CODE-BACKED | Count of travel rule transactions with no activity in the window. |
| 2 | InHoursBack | INT | NO | - | CODE-BACKED | Echo of @HoursBack for alert context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleInformation | FROM (read) | Travel rule transaction records |
| Query body | Wallet.TransactionTravelRuleStatuses | OUTER APPLY / NOT EXISTS | Status activity detection |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetNoTravelRuleActivity (procedure)
  ├── Wallet.TransactionTravelRuleInformation (table)
  └── Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | FROM - travel rule transactions |
| Wallet.TransactionTravelRuleStatuses | Table | OUTER APPLY / NOT EXISTS - activity detection |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check for stalled transactions (default 24h)
```sql
EXEC Monitoring.GetNoTravelRuleActivity;
```

### 8.2 Tighter window for urgent checks
```sql
EXEC Monitoring.GetNoTravelRuleActivity @HoursBack = 4;
```

### 8.3 View stalled travel rule transactions in detail
```sql
SELECT ttri.Id, ttri.Occurred, ls.TravelRuleStatusId, ls.Occurred AS LastStatusUpdate
FROM Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK)
OUTER APPLY (
    SELECT TOP 1 TravelRuleStatusId, Occurred
    FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK)
    WHERE TransactionTravelRuleInformationId = ttri.Id
    ORDER BY Occurred DESC
) ls
WHERE ls.TravelRuleStatusId IN (0, 3, 4, 5)
  AND ls.Occurred < DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY ls.Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetNoTravelRuleActivity | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetNoTravelRuleActivity.sql*
