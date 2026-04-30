# Monitoring.GetStuckTravelRuleTransactionsGraph

> Returns individual stuck travel rule transactions (PENDING without COMPLETED/CANCELLED) with their creation timestamps, ordered by most recent first, for time-series graphing.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns individual stuck TR transactions for graphing |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetStuckTravelRuleTransactionsGraph is the detail companion to GetStuckTravelRuleTransactions. While that procedure returns a single count, this one returns each stuck transaction individually with its Occurred timestamp. This enables time-series visualization showing when stuck transactions were created, revealing whether the backlog is growing, stable, or shrinking.

---

## 2. Business Logic

### 2.1 Stuck Transaction Detail for Graphing

**What**: Same logic as GetStuckTravelRuleTransactions but returns individual rows.

**Columns/Parameters Involved**: `TravelRuleStatusId`, `Occurred`

**Rules**:
- Same EXISTS/NOT EXISTS pattern as GetStuckTravelRuleTransactions
- Returns (Occurred, Id) per stuck transaction ordered by Occurred DESC
- Enables plotting stuck count over time by grouping by date/hour

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the travel rule transaction was created. Used as the X-axis in time-series graphs. |
| 2 | Id | BIGINT | NO | - | CODE-BACKED | TransactionTravelRuleInformation ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleInformation | FROM (read) | Travel rule transaction records |
| Query body | Wallet.TransactionTravelRuleStatuses | EXISTS/NOT EXISTS | Status checking |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring/graphing tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetStuckTravelRuleTransactionsGraph (procedure)
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

### 8.1 Get all stuck transactions for graphing
```sql
EXEC Monitoring.GetStuckTravelRuleTransactionsGraph;
```

### 8.2 Group by day for trend analysis
```sql
SELECT CAST(ttri.Occurred AS DATE) AS Day, COUNT(*) AS StuckCount
FROM Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK)
WHERE EXISTS (SELECT 1 FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK) WHERE TransactionTravelRuleInformationId = ttri.Id AND TravelRuleStatusId = 0)
  AND NOT EXISTS (SELECT 1 FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK) WHERE TransactionTravelRuleInformationId = ttri.Id AND TravelRuleStatusId IN (1, 2))
GROUP BY CAST(ttri.Occurred AS DATE) ORDER BY Day;
```

### 8.3 Get the oldest stuck transaction
```sql
-- Use the graph procedure and take the last row (oldest)
EXEC Monitoring.GetStuckTravelRuleTransactionsGraph;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetStuckTravelRuleTransactionsGraph | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetStuckTravelRuleTransactionsGraph.sql*
