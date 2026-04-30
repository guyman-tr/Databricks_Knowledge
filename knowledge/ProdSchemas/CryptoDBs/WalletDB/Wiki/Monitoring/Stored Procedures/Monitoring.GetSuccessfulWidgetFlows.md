# Monitoring.GetSuccessfulWidgetFlows

> Counts the total number of successful travel rule widget flows and the number of unique users who completed them, providing a KPI metric for the travel rule UI.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns successful widget flow count and unique user count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetSuccessfulWidgetFlows measures the success of the travel rule widget - the UI component where customers provide required sender/receiver information for compliant crypto transfers. A successful flow means the travel rule information was submitted and reached COMPLETED status (TravelRuleStatusId=1).

This is a business KPI rather than an alert - it measures adoption and success rate of the travel rule compliance feature.

---

## 2. Business Logic

### 2.1 Success Counting

**What**: Counts distinct successful travel rule flows and unique customers.

**Columns/Parameters Involved**: `TravelRuleStatusId`, `RequestId`, `Gcid`

**Rules**:
- TravelRuleStatusId = 1 (COMPLETED/SUCCESS) indicates a successful flow
- COUNT(DISTINCT ttri.RequestId) gives unique successful flows
- COUNT(DISTINCT r.Gcid) gives unique users who had at least one success
- All-time metric (no time window parameter)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SuccessfulWidgetFlows | INT | NO | - | CODE-BACKED | Total distinct request IDs with a successful travel rule completion. |
| 2 | UniqueUsers | INT | NO | - | CODE-BACKED | Total distinct customers (Gcid) who completed at least one successful widget flow. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleInformation | FROM (read) | Travel rule records linked to requests |
| Query body | Wallet.TransactionTravelRuleStatuses | EXISTS | Success status check (StatusId=1) |
| Query body | Wallet.Requests | JOIN | Maps to Gcid for unique user counting |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring/KPI tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetSuccessfulWidgetFlows (procedure)
  ├── Wallet.TransactionTravelRuleInformation (table)
  ├── Wallet.TransactionTravelRuleStatuses (table)
  └── Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | FROM - TR records |
| Wallet.TransactionTravelRuleStatuses | Table | EXISTS - success check |
| Wallet.Requests | Table | JOIN - user mapping |

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

### 8.1 Get current KPI
```sql
EXEC Monitoring.GetSuccessfulWidgetFlows;
```

### 8.2 Check monthly trend manually
```sql
SELECT DATEPART(MONTH, ttri.Occurred) AS Month, COUNT(DISTINCT ttri.RequestId) AS Flows
FROM Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK)
WHERE EXISTS (SELECT 1 FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK) WHERE TransactionTravelRuleInformationId = ttri.Id AND TravelRuleStatusId = 1)
GROUP BY DATEPART(MONTH, ttri.Occurred) ORDER BY Month;
```

### 8.3 Compare success vs total
```sql
SELECT COUNT(*) AS TotalFlows,
  SUM(CASE WHEN EXISTS (SELECT 1 FROM Wallet.TransactionTravelRuleStatuses ttrs WITH (NOLOCK) WHERE ttrs.TransactionTravelRuleInformationId = ttri.Id AND ttrs.TravelRuleStatusId = 1) THEN 1 ELSE 0 END) AS Successful
FROM Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetSuccessfulWidgetFlows | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetSuccessfulWidgetFlows.sql*
