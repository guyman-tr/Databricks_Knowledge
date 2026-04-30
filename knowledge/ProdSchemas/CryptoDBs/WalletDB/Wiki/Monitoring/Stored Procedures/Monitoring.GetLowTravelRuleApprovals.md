# Monitoring.GetLowTravelRuleApprovals

> Counts travel rule approval (completed) transactions within a time window, alerting when the count drops below expected minimum thresholds indicating potential system issues.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of travel rule approvals in time window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetLowTravelRuleApprovals is the counterpart to GetHighTravelRuleBounceBacks. While that procedure detects too many rejections, this one detects too few approvals. A sudden drop in travel rule approvals suggests the verification pipeline may be stalled - transactions are being submitted but not getting processed.

Without this procedure, a silent failure in the travel rule approval pipeline could go undetected for hours, blocking all outgoing crypto transfers that require travel rule compliance.

---

## 2. Business Logic

### 2.1 Approval Volume Alert

**What**: Counts travel rule approvals for low-threshold alerting.

**Columns/Parameters Involved**: `TravelRuleStatusId`, `@HoursBack`, `@MinApprovals`

**Rules**:
- TravelRuleStatusId = 1 identifies COMPLETED/APPROVED status
- Count is within the @HoursBack window
- @MinApprovals parameter provides the expected minimum (default 1) for external comparison
- If the count is below @MinApprovals, external tooling triggers an alert

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursBack | INT | NO | 24 | CODE-BACKED | Lookback window in hours. |
| 2 | @MinApprovals | INT | NO | 1 | CODE-BACKED | Expected minimum number of approvals. Passed through to output for threshold comparison by external tooling. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApprovalCountLastXHours | INT | NO | - | CODE-BACKED | Total count of travel rule approvals within the window. |
| 2 | InHoursBack | INT | NO | - | CODE-BACKED | Echo of @HoursBack for context in alert messages. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleStatuses | FROM (read) | Source of travel rule status events |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetLowTravelRuleApprovals (procedure)
  └── Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleStatuses | Table | FROM - travel rule status events |

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

### 8.1 Check last 24 hours (default)
```sql
EXEC Monitoring.GetLowTravelRuleApprovals;
```

### 8.2 Check last 4 hours with higher threshold
```sql
EXEC Monitoring.GetLowTravelRuleApprovals @HoursBack = 4, @MinApprovals = 10;
```

### 8.3 Hourly travel rule approval trend
```sql
SELECT DATEPART(HOUR, ttrs.Occurred) AS HourOfDay, COUNT(*) AS Approvals
FROM Wallet.TransactionTravelRuleStatuses ttrs WITH (NOLOCK)
WHERE ttrs.TravelRuleStatusId = 1
  AND ttrs.Occurred >= DATEADD(DAY, -1, GETUTCDATE())
GROUP BY DATEPART(HOUR, ttrs.Occurred)
ORDER BY HourOfDay;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetLowTravelRuleApprovals | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetLowTravelRuleApprovals.sql*
