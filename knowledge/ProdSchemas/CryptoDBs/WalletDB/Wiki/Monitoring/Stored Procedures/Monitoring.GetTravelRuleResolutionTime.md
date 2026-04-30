# Monitoring.GetTravelRuleResolutionTime

> Calculates the average time in hours from PENDING status to COMPLETED or CANCELLED status across all travel rule transactions, measuring how quickly the travel rule pipeline resolves transactions.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns average resolution time in hours |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetTravelRuleResolutionTime measures the average processing time of the travel rule compliance pipeline. It calculates the time difference between the first PENDING status (TravelRuleStatusId=0) and the first terminal status (COMPLETED=1 or CANCELLED=2). For transactions not yet resolved, it uses the current time as the end point.

A rising average indicates the travel rule pipeline is slowing down, which directly impacts customer experience on outgoing crypto transfers.

---

## 2. Business Logic

### 2.1 Resolution Time Calculation

**What**: Average hours from PENDING to terminal status.

**Columns/Parameters Involved**: `TravelRuleStatusId`, `Occurred`

**Rules**:
- PendingTime = MIN(Occurred) where TravelRuleStatusId = 0
- CompletedOrCancelledTime = MIN(Occurred) where TravelRuleStatusId IN (1, 2)
- If not yet resolved: ISNULL(CompletedOrCancelledTime, GETUTCDATE())
- Resolution hours = DATEDIFF(HOUR, PendingTime, CompletedOrCancelledTime)
- Returns the average across all transactions that have a PendingTime

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AvgHoursFromPendingToCompleteOrBB | DECIMAL(10,2) | YES | - | CODE-BACKED | Average hours from PENDING to resolution (COMPLETED or CANCELLED). Includes unresolved transactions using current time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleInformation | FROM (read) | TR transaction records |
| Query body | Wallet.TransactionTravelRuleStatuses | LEFT JOIN | Status timestamps |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external KPI tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetTravelRuleResolutionTime (procedure)
  ├── Wallet.TransactionTravelRuleInformation (table)
  └── Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | FROM - TR records |
| Wallet.TransactionTravelRuleStatuses | Table | LEFT JOIN - status timestamps |

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

### 8.1 Get average resolution time
```sql
EXEC Monitoring.GetTravelRuleResolutionTime;
```

### 8.2 Check resolution time distribution
```sql
SELECT DATEDIFF(HOUR, MIN(CASE WHEN ttrs.TravelRuleStatusId = 0 THEN ttrs.Occurred END),
  MIN(CASE WHEN ttrs.TravelRuleStatusId IN (1,2) THEN ttrs.Occurred END)) AS Hours, COUNT(*) AS Count
FROM Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK)
LEFT JOIN Wallet.TransactionTravelRuleStatuses ttrs WITH (NOLOCK) ON ttri.Id = ttrs.TransactionTravelRuleInformationId
GROUP BY ttri.Id
HAVING MIN(CASE WHEN ttrs.TravelRuleStatusId IN (1,2) THEN ttrs.Occurred END) IS NOT NULL;
```

### 8.3 View all TR KPIs together
```sql
EXEC Monitoring.GetTravelRuleSuccessRate;
EXEC Monitoring.GetTravelRuleBounceBackRate;
EXEC Monitoring.GetTravelRuleResolutionTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetTravelRuleResolutionTime | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetTravelRuleResolutionTime.sql*
