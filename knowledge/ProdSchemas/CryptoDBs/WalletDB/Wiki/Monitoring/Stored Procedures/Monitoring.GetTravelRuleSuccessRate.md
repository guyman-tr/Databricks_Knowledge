# Monitoring.GetTravelRuleSuccessRate

> Calculates the percentage of travel rule transactions that successfully completed (TravelRuleStatusId=1), providing the overall success rate KPI.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns success percentage of all travel rule transactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetTravelRuleSuccessRate is the primary success KPI for the travel rule compliance pipeline. It calculates what percentage of all travel rule transactions reached COMPLETED status. This is the complement to GetTravelRuleBounceBackRate - together they account for most terminal states.

A declining success rate requires investigation as it means fewer customer transfers are completing the compliance flow successfully.

---

## 2. Business Logic

### 2.1 Success Rate Calculation

**What**: Percentage of TR transactions with at least one COMPLETED status.

**Columns/Parameters Involved**: `TravelRuleStatusId`

**Rules**:
- Each TransactionTravelRuleInformation record is checked for the presence of TravelRuleStatusId=1 (COMPLETED)
- Rate = 100 * COUNT(with status 1) / COUNT(all) as DECIMAL(5,2)
- All-time calculation (no time window parameter)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PercentWithStatus1 | DECIMAL(5,2) | NO | - | CODE-BACKED | Percentage of travel rule transactions that completed successfully. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleInformation | FROM (read) | TR transaction records |
| Query body | Wallet.TransactionTravelRuleStatuses | LEFT JOIN | Success status detection |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external KPI tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetTravelRuleSuccessRate (procedure)
  ├── Wallet.TransactionTravelRuleInformation (table)
  └── Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | FROM - TR records |
| Wallet.TransactionTravelRuleStatuses | Table | LEFT JOIN - status detection |

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

### 8.1 Get all-time success rate
```sql
EXEC Monitoring.GetTravelRuleSuccessRate;
```

### 8.2 View all TR KPIs together
```sql
EXEC Monitoring.GetTravelRuleSuccessRate;
EXEC Monitoring.GetTravelRuleBounceBackRate;
EXEC Monitoring.GetTravelRuleResolutionTime;
EXEC Monitoring.GetStuckTravelRuleTransactions;
```

### 8.3 Monthly success rate trend
```sql
SELECT DATEPART(YEAR, ttri.Occurred) AS Y, DATEPART(MONTH, ttri.Occurred) AS M,
  CAST(100.0 * SUM(CASE WHEN s.HasStatus1 = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS SuccessRate
FROM Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK)
LEFT JOIN (SELECT DISTINCT TransactionTravelRuleInformationId, 1 AS HasStatus1
  FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK) WHERE TravelRuleStatusId = 1) s
  ON ttri.Id = s.TransactionTravelRuleInformationId
GROUP BY DATEPART(YEAR, ttri.Occurred), DATEPART(MONTH, ttri.Occurred) ORDER BY Y, M;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetTravelRuleSuccessRate | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetTravelRuleSuccessRate.sql*
