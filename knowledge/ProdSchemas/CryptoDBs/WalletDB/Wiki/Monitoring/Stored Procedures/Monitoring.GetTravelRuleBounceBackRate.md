# Monitoring.GetTravelRuleBounceBackRate

> Calculates the percentage of travel rule transactions that resulted in a bounceback (TravelRuleStatusId=2/CANCELLED), providing a KPI for travel rule rejection rates.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns bounceback percentage of all travel rule transactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetTravelRuleBounceBackRate calculates the overall rate at which travel rule transactions are bounced back (cancelled/rejected). This is a key compliance KPI - a rising bounceback rate may indicate issues with counterparty verification, address validation, or travel rule provider connectivity.

The default @DaysBack of 10000 effectively calculates the all-time rate. Adjusting to shorter windows enables trend analysis.

---

## 2. Business Logic

### 2.1 Bounceback Rate Calculation

**What**: Percentage of TR transactions with at least one status 2 (CANCELLED).

**Columns/Parameters Involved**: `TravelRuleStatusId`, `@DaysBack`

**Rules**:
- Each TransactionTravelRuleInformation record is checked for the presence of TravelRuleStatusId=2
- Rate = 100 * COUNT(with status 2) / COUNT(all) as DECIMAL(5,2)
- Default window: 10000 days (effectively all-time)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DaysBack | INT | NO | 10000 | CODE-BACKED | Lookback window in days. Default 10000 (all-time). |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PercentWithStatus2 | DECIMAL(5,2) | NO | - | CODE-BACKED | Percentage of travel rule transactions that were bounced back. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleInformation | FROM (read) | TR transaction records |
| Query body | Wallet.TransactionTravelRuleStatuses | LEFT JOIN | Bounceback status detection |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external KPI/monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetTravelRuleBounceBackRate (procedure)
  ├── Wallet.TransactionTravelRuleInformation (table)
  └── Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | FROM - TR records |
| Wallet.TransactionTravelRuleStatuses | Table | LEFT JOIN - status 2 detection |

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

### 8.1 All-time bounceback rate (default)
```sql
EXEC Monitoring.GetTravelRuleBounceBackRate;
```

### 8.2 Last 30 days
```sql
EXEC Monitoring.GetTravelRuleBounceBackRate @DaysBack = 30;
```

### 8.3 Compare with success rate
```sql
EXEC Monitoring.GetTravelRuleBounceBackRate;
EXEC Monitoring.GetTravelRuleSuccessRate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetTravelRuleBounceBackRate | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetTravelRuleBounceBackRate.sql*
