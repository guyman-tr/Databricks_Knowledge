# Dictionary.ErrorMonitoringPolicyRules

> Configuration table defining the retry timing and check interval rules for each error monitoring policy, controlling how frequently and for how long the system monitors transaction errors.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + unique composite on PolicyId+Period) |

---

## 1. Business Meaning

This table defines the specific retry timing rules for each error monitoring policy defined in `Dictionary.ErrorMonitoringPolicies`. While the parent policy table classifies errors by severity (TemporaryHiccup, PermanentError, etc.), this table specifies exactly HOW the monitoring system checks for resolution: how frequently to check and for how long before escalating.

Each policy can have multiple rules representing different time windows. For example, a TemporaryHiccup (policy 1) might be checked every 5 minutes for the first 2 hours, then every 10 minutes for the first day, then every 60 minutes for a week. This tiered approach avoids over-monitoring while ensuring errors don't slip through.

The table is consumed by `Wallet.GetErrorMonitoringPolicyRules` and `Wallet.GetErrorMonitoringPolicies` stored procedures. The unique index on (ErrorMonitoringPolicyId, PeriodUpperBoundMinutes) ensures no duplicate time windows per policy.

---

## 2. Business Logic

### 2.1 Tiered Monitoring Windows

**What**: Each policy defines escalating time windows with progressively longer check intervals.

**Columns/Parameters Involved**: `ErrorMonitoringPolicyId`, `PeriodUpperBoundMinutes`, `CheckIntervalMinutes`

**Rules**:
- **TemporaryHiccup (policy 1)**: Check every 5 min up to 2 hours, every 10 min up to 1 day, every 60 min up to 1 week. Gradual de-escalation for transient errors.
- **PermanentErrorForOneDay (policy 2)**: Check every 5 min for 1 hour, every 60 min for 1 day. Aggressive early monitoring, then daily check.
- **PermanentErrorForOneWeek (policy 3)**: Check every 5 min for 1 hour, every 60 min for 1 week. Same as policy 2 but extends the monitoring window.
- **TentativeTimeoutError (policy 4)**: Check every 10 min for 30 min, every 10 min for 1 day, every 60 min for 1 week. Starts quick for timeout resolution.
- **ImmaditaeFailure (policy 5)**: PeriodUpperBound=0, CheckInterval=0. No retry - immediate failure with no monitoring window.
- **HalfHourRetry (policy 6)**: Check every 5 min for 30 min. Short monitoring window, then done.
- **TwoDays (policy 7)**: Check every 60 min for 2 days. Single long-interval window.

**Diagram**:
```
TemporaryHiccup (policy 1):
  [0-2h] check every 5m --> [2h-1d] check every 10m --> [1d-1w] check every 60m

PermanentErrorForOneDay (policy 2):
  [0-1h] check every 5m --> [1h-1d] check every 60m

ImmaditaeFailure (policy 5):
  [immediate] no retry (0/0)

HalfHourRetry (policy 6):
  [0-30m] check every 5m --> done
```

### 2.2 Policy-to-Rules Multiplicity

**What**: One policy maps to 1-3 rules representing escalating time windows.

**Columns/Parameters Involved**: `ErrorMonitoringPolicyId`, `Id`

**Rules**:
- Policies 1, 3, 4 have 3 rules each (three-tier monitoring)
- Policies 2 have 2 rules (two-tier monitoring)
- Policies 5, 6, 7 have 1 rule each (single-tier or immediate)
- Total: 13 rules across 7 policies

---

## 3. Data Overview

| Id | ErrorMonitoringPolicyId | PeriodUpperBoundMinutes | CheckIntervalMinutes | Meaning |
|---|---|---|---|---|
| 1 | 1 (TemporaryHiccup) | 120 | 5 | First tier: check every 5 minutes for the first 2 hours. Catches quick-resolving transient issues like rate limiting or brief outages. |
| 7 | 1 (TemporaryHiccup) | 1440 | 10 | Second tier: check every 10 minutes from 2 hours to 1 day. Error persists longer than expected - reduce monitoring frequency. |
| 11 | 5 (ImmaditaeFailure) | 0 | 0 | No monitoring - immediate failure policy. Period=0 and Interval=0 means the system does not attempt retries. Error is permanent on first occurrence. |
| 6 | 4 (TentativeTimeout) | 30 | 10 | Quick initial check for timeouts: every 10 minutes for 30 minutes. Blockchain timeouts often resolve quickly when a block is mined. |
| 12 | 6 (HalfHourRetry) | 30 | 5 | Short retry window: check every 5 minutes for 30 minutes then stop. For errors where a brief wait typically resolves the issue. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing unique identifier. 13 rules across 7 policies. Non-sequential relative to policy order. |
| 2 | ErrorMonitoringPolicyId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.ErrorMonitoringPolicies. Links this timing rule to its parent policy. Values: 1-7 matching the 7 policies. Multiple rules can share the same policy (1:N relationship). |
| 3 | PeriodUpperBoundMinutes | int | NO | - | CODE-BACKED | Maximum duration (in minutes) for this monitoring window. The system checks at CheckIntervalMinutes frequency until this many minutes have elapsed since the error occurred. 0 = no monitoring (immediate failure). Common values: 30 (half hour), 120 (2 hours), 1440 (1 day), 2880 (2 days), 10080 (1 week). |
| 4 | CheckIntervalMinutes | int | NO | - | CODE-BACKED | How frequently (in minutes) the monitoring system checks whether the error has resolved during this time window. 0 = no checking. Common values: 5 (aggressive), 10 (moderate), 60 (hourly). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ErrorMonitoringPolicyId | Dictionary.ErrorMonitoringPolicies | FK | Parent policy that this rule belongs to |

### 5.2 Referenced By (other objects point to this)

No direct FK references. Consumed by monitoring system SPs.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.ErrorMonitoringPolicyRules (table)
  +-- Dictionary.ErrorMonitoringPolicies (table)
        +-- Dictionary.TransactionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ErrorMonitoringPolicies | Table | FK on ErrorMonitoringPolicyId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetErrorMonitoringPolicyRules | Stored Procedure | Reads all policy rules |
| Wallet.GetErrorMonitoringPolicies | Stored Procedure | JOINs policies with their rules |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ErrorMonitoringPolicyRules | CLUSTERED | Id ASC | - | - | Active |
| IX_..._ErrorMonitoringPolicyId_PeriodUpperBoundMinutes | NONCLUSTERED UNIQUE | ErrorMonitoringPolicyId ASC, PeriodUpperBoundMinutes ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_..._ErrorMonitoringPolicyId | FOREIGN KEY | ErrorMonitoringPolicyId -> Dictionary.ErrorMonitoringPolicies(Id) |
| IX (unique composite) | UNIQUE | No duplicate time windows per policy |

---

## 8. Sample Queries

### 8.1 List all policy rules with policy names
```sql
SELECT emp.Name AS Policy, empr.PeriodUpperBoundMinutes, empr.CheckIntervalMinutes
FROM Dictionary.ErrorMonitoringPolicyRules empr WITH (NOLOCK)
JOIN Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK) ON empr.ErrorMonitoringPolicyId = emp.Id
ORDER BY emp.Id, empr.PeriodUpperBoundMinutes
```

### 8.2 Find the most aggressive monitoring rules (shortest intervals)
```sql
SELECT emp.Name AS Policy, empr.CheckIntervalMinutes, empr.PeriodUpperBoundMinutes
FROM Dictionary.ErrorMonitoringPolicyRules empr WITH (NOLOCK)
JOIN Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK) ON empr.ErrorMonitoringPolicyId = emp.Id
WHERE empr.CheckIntervalMinutes > 0
ORDER BY empr.CheckIntervalMinutes, empr.PeriodUpperBoundMinutes
```

### 8.3 Monitoring duration per policy (total window)
```sql
SELECT emp.Name AS Policy, MAX(empr.PeriodUpperBoundMinutes) AS MaxMonitoringMinutes,
  MAX(empr.PeriodUpperBoundMinutes) / 60.0 AS MaxMonitoringHours
FROM Dictionary.ErrorMonitoringPolicyRules empr WITH (NOLOCK)
JOIN Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK) ON empr.ErrorMonitoringPolicyId = emp.Id
GROUP BY emp.Name
ORDER BY MaxMonitoringMinutes DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ErrorMonitoringPolicyRules | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ErrorMonitoringPolicyRules.sql*
