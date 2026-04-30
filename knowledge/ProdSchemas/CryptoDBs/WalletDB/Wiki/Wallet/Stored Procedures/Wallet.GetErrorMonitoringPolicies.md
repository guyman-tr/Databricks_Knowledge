# Wallet.GetErrorMonitoringPolicies

> Returns all error monitoring policies with their associated rules as embedded JSON, providing the complete error monitoring configuration for the transaction error alerting system.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Dictionary.ErrorMonitoringPolicies + rules JSON |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure loads the complete error monitoring configuration. Error monitoring policies define alerting rules for transaction failures - which transaction statuses trigger monitoring, at what intervals to check, and over what time windows. The embedded JSON PolicyRules contain the escalation tiers (e.g., check every 5 minutes for first hour, then every 15 minutes after).

Without this procedure, the error monitoring service could not load its alerting configuration, disabling automated detection of stuck or failing transactions.

---

## 2. Business Logic

### 2.1 Embedded Policy Rules as JSON

**What**: Each policy row includes its rules as a nested JSON array using FOR JSON AUTO.

**Columns/Parameters Involved**: ErrorMonitoringPolicies, ErrorMonitoringPolicyRules

**Rules**:
- Correlated subquery joins PolicyRules to Policies by ErrorMonitoringPolicyId
- Rules are ordered by Id and serialized as JSON
- Each rule defines PeriodUpperBoundMinutes (time window) and CheckIntervalMinutes (how often to check)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Policy ID. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Policy name (e.g., "SendTransactionMonitoring"). |
| 3 | TransactionStatusId | tinyint | NO | - | CODE-BACKED | Which transaction status this policy monitors. |
| 4 | PolicyRules | nvarchar(MAX) | YES | - | CODE-BACKED | JSON array of escalation rules: [{Id, ErrorMonitoringPolicyId, PeriodUpperBoundMinutes, CheckIntervalMinutes}]. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.ErrorMonitoringPolicies | Reader | Policy definitions |
| - | Dictionary.ErrorMonitoringPolicyRules | Reader | Escalation rules (via FOR JSON) |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetErrorMonitoringPolicies (procedure)
  ├── Dictionary.ErrorMonitoringPolicies (table)
  └── Dictionary.ErrorMonitoringPolicyRules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ErrorMonitoringPolicies | Table | SELECT source |
| Dictionary.ErrorMonitoringPolicyRules | Table | FOR JSON subquery |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hints, SET NOCOUNT ON
- FOR JSON AUTO for embedded rules serialization

---

## 8. Sample Queries

### 8.1 Load all policies
```sql
EXEC Wallet.GetErrorMonitoringPolicies
```

### 8.2 View policies flat
```sql
SELECT emp.Id, emp.Name, emp.TransactionStatusId
FROM Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK)
```

### 8.3 View rules for a specific policy
```sql
SELECT Id, PeriodUpperBoundMinutes, CheckIntervalMinutes
FROM Dictionary.ErrorMonitoringPolicyRules WITH (NOLOCK)
WHERE ErrorMonitoringPolicyId = 1
ORDER BY Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetErrorMonitoringPolicies | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetErrorMonitoringPolicies.sql*
