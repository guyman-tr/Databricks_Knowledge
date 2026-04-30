# Monitoring.GetStuckTravelRuleTransactions

> Returns the count of travel rule transactions that are stuck in PENDING status without ever reaching COMPLETED or CANCELLED, indicating transactions awaiting travel rule resolution.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of stuck pending travel rule transactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetStuckTravelRuleTransactions counts travel rule transactions that have a PENDING status (TravelRuleStatusId=0) but have never received a terminal status (COMPLETED=1 or CANCELLED=2). A high count indicates the travel rule resolution pipeline is backing up, potentially blocking customer withdrawals.

This is a companion to GetStuckTravelRuleTransactionsGraph which provides the same data in a per-transaction detail format for time-series visualization.

---

## 2. Business Logic

### 2.1 Pending Without Terminal Status

**What**: Counts transactions with PENDING but no COMPLETED/CANCELLED.

**Columns/Parameters Involved**: `TravelRuleStatusId`

**Rules**:
- EXISTS: has at least one status with TravelRuleStatusId = 0 (PENDING)
- NOT EXISTS: has no status with TravelRuleStatusId IN (1, 2) (COMPLETED, CANCELLED)
- Returns a single scalar count

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StuckTransactionCount | INT | NO | - | CODE-BACKED | Total number of travel rule transactions stuck in PENDING. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleInformation | FROM (read) | Travel rule transaction records |
| Query body | Wallet.TransactionTravelRuleStatuses | EXISTS/NOT EXISTS | Status checking |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetStuckTravelRuleTransactions (procedure)
  ├── Wallet.TransactionTravelRuleInformation (table)
  └── Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | FROM - TR records |
| Wallet.TransactionTravelRuleStatuses | Table | EXISTS - status checking |

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

### 8.1 Get current stuck count
```sql
EXEC Monitoring.GetStuckTravelRuleTransactions;
```

### 8.2 Compare with graph view for details
```sql
EXEC Monitoring.GetStuckTravelRuleTransactionsGraph;
```

### 8.3 Check stuck transactions by age
```sql
SELECT DATEDIFF(HOUR, ttri.Occurred, GETUTCDATE()) AS AgeHours, COUNT(*) AS Count
FROM Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK)
WHERE EXISTS (SELECT 1 FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK) WHERE TransactionTravelRuleInformationId = ttri.Id AND TravelRuleStatusId = 0)
  AND NOT EXISTS (SELECT 1 FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK) WHERE TransactionTravelRuleInformationId = ttri.Id AND TravelRuleStatusId IN (1, 2))
GROUP BY DATEDIFF(HOUR, ttri.Occurred, GETUTCDATE()) / 24
ORDER BY 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetStuckTravelRuleTransactions | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetStuckTravelRuleTransactions.sql*
