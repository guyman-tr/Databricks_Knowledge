# Wallet.GetErrorMonitoringPolicyRules

> Returns the escalation rules for a specific error monitoring policy, defining the time windows and check intervals for transaction error alerting.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns rules for a specific PolicyId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the escalation rules for a single error monitoring policy. Each rule defines a time window (PeriodUpperBoundMinutes) and how frequently to check for errors within that window (CheckIntervalMinutes). Rules are tiered - shorter periods with frequent checks for fresh errors, longer periods with less frequent checks for older ones.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple filtered SELECT from Dictionary table.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PolicyId | tinyint | NO | - | CODE-BACKED | The error monitoring policy ID to retrieve rules for. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.ErrorMonitoringPolicyRules | Reader | Source of policy rules |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetErrorMonitoringPolicyRules (procedure)
  └── Dictionary.ErrorMonitoringPolicyRules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ErrorMonitoringPolicyRules | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON

---

## 8. Sample Queries

### 8.1 Get rules for policy 1
```sql
EXEC Wallet.GetErrorMonitoringPolicyRules @PolicyId = 1
```

### 8.2 View all rules
```sql
SELECT * FROM Dictionary.ErrorMonitoringPolicyRules WITH (NOLOCK) ORDER BY ErrorMonitoringPolicyId, Id
```

### 8.3 Rules with policy names
```sql
SELECT emp.Name, empr.PeriodUpperBoundMinutes, empr.CheckIntervalMinutes
FROM Dictionary.ErrorMonitoringPolicyRules empr WITH (NOLOCK)
JOIN Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK) ON emp.Id = empr.ErrorMonitoringPolicyId
ORDER BY emp.Id, empr.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetErrorMonitoringPolicyRules | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetErrorMonitoringPolicyRules.sql*
