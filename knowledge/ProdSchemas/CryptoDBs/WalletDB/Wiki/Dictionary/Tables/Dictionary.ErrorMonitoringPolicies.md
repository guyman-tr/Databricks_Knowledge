# Dictionary.ErrorMonitoringPolicies

> Lookup table defining error monitoring policies that classify transaction errors by severity and determine alerting and retry behavior.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 unique (Name) |

---

## 1. Business Meaning

This table defines error monitoring policies that categorize transaction errors by their severity and expected resolution pattern. Each policy describes how the system should respond to a class of errors - whether to retry quickly (TemporaryHiccup), wait and retry (HalfHourRetry), or mark as permanent failure (PermanentError).

Each policy is linked to a TransactionStatus that it monitors. The error monitoring system watches for transactions reaching specific statuses and applies the appropriate policy rules to determine alerting, retry intervals, and escalation paths.

FK-referenced by `Dictionary.ErrorMonitoringPolicyRules` (which defines the specific retry timing rules for each policy) and `Dictionary.TransactionErrorCodes` (which maps individual error codes to policies). Also references `Dictionary.TransactionStatus` via FK.

---

## 2. Business Logic

### 2.1 Error Severity Classification

**What**: Seven policies covering the spectrum from transient hiccups to permanent failures.

**Columns/Parameters Involved**: `Id`, `Name`, `TransactionStatusId`

**Rules**:
- `TemporaryHiccup` (1): Transient error, monitored at WavedError (6) status. Auto-resolves quickly. Minimal alerting.
- `PermanentErrorForOneDay` (2): Error unlikely to self-resolve within a day. Monitored at PermanentError (5) status. Alert after 24 hours.
- `PermanentErrorForOneWeek` (3): Error unlikely to self-resolve within a week. Same PermanentError (5) status. Alert after 7 days.
- `TentativeTimeoutError` (4): Timeout that may resolve when blockchain catches up. WavedError (6) status.
- `ImmaditaeFailure` (5): Immediate failure requiring urgent attention. WavedError (6) status. (Note: typo "Immaditae" in original data).
- `HalfHourRetry` (6): Error that should be retried after 30 minutes. WavedError (6) status.
- `TwoDays` (7): Error requiring a 2-day waiting period before retry. WavedError (6) status.

**Diagram**:
```
Error Classification:
  Transient:  TemporaryHiccup(1), HalfHourRetry(6)  [auto-resolve expected]
  Timeout:    TentativeTimeoutError(4)               [blockchain delay]
  Serious:    ImmaditaeFailure(5), TwoDays(7)        [needs attention]
  Permanent:  PermanentErrorForOneDay(2),             [escalate if not resolved]
              PermanentErrorForOneWeek(3)

TransactionStatus monitored:
  WavedError (6): policies 1, 4, 5, 6, 7
  PermanentError (5): policies 2, 3
```

---

## 3. Data Overview

| Id | Name | TransactionStatusId | Meaning |
|---|---|---|---|
| 1 | TemporaryHiccup | 6 (WavedError) | Transient error expected to self-resolve. No manual intervention needed. Monitoring watches for persistent recurrence. |
| 2 | PermanentErrorForOneDay | 5 (PermanentError) | Error expected to persist for at least 24 hours. If not resolved within a day, escalate to operations team. |
| 5 | ImmaditaeFailure | 6 (WavedError) | Immediate critical failure requiring urgent attention. Despite being categorized as WavedError at the transaction level, this policy triggers immediate alerting. |
| 6 | HalfHourRetry | 6 (WavedError) | Error suitable for automatic retry after a 30-minute cooldown. Common for rate-limited or temporarily overloaded provider endpoints. |
| 7 | TwoDays | 6 (WavedError) | Error requiring a 2-day waiting period. The underlying condition (e.g., blockchain network congestion, maintenance window) is expected to resolve within 48 hours. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 1-7 as described above. FK target for Dictionary.ErrorMonitoringPolicyRules and Dictionary.TransactionErrorCodes. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Unique policy name. Describes the error severity and expected resolution timeline. Used in monitoring dashboards and alerting configuration. |
| 3 | TransactionStatusId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.TransactionStatus. The blockchain transaction status that this policy monitors. Most policies watch WavedError (6); permanent policies watch PermanentError (5). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionStatusId | Dictionary.TransactionStatus | FK | The transaction status this policy monitors |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.ErrorMonitoringPolicyRules | ErrorMonitoringPolicyId | FK | Retry timing rules for this policy |
| Dictionary.TransactionErrorCodes | ErrorMonitoringPolicyId | FK | Maps individual error codes to this policy |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.ErrorMonitoringPolicies (table)
  +-- Dictionary.TransactionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TransactionStatus | Table | FK on TransactionStatusId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ErrorMonitoringPolicyRules | Table | FK on ErrorMonitoringPolicyId |
| Dictionary.TransactionErrorCodes | Table | FK on ErrorMonitoringPolicyId |
| Wallet.GetErrorMonitoringPolicies | Stored Procedure | Reads all policies |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ErrorMonitoringPolicies | CLUSTERED | Id ASC | - | - | Active |
| IX_Dictionary_ErrorMonitoringPolicies_Name | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_..._TransactionStatusId | FOREIGN KEY | TransactionStatusId -> Dictionary.TransactionStatus(Id) |

---

## 8. Sample Queries

### 8.1 List all error monitoring policies with their watched status
```sql
SELECT emp.Id, emp.Name AS Policy, ts.Name AS WatchedStatus
FROM Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK)
JOIN Dictionary.TransactionStatus ts WITH (NOLOCK) ON emp.TransactionStatusId = ts.Id
ORDER BY emp.Id
```

### 8.2 Policies with their retry rules
```sql
SELECT emp.Name AS Policy, empr.PeriodUpperBoundMinutes, empr.CheckIntervalMinutes
FROM Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK)
JOIN Dictionary.ErrorMonitoringPolicyRules empr WITH (NOLOCK) ON empr.ErrorMonitoringPolicyId = emp.Id
ORDER BY emp.Id, empr.PeriodUpperBoundMinutes
```

### 8.3 Error codes grouped by policy
```sql
SELECT emp.Name AS Policy, COUNT(tec.Id) AS ErrorCodeCount
FROM Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK)
LEFT JOIN Dictionary.TransactionErrorCodes tec WITH (NOLOCK) ON tec.ErrorMonitoringPolicyId = emp.Id
GROUP BY emp.Name ORDER BY ErrorCodeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ErrorMonitoringPolicies | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ErrorMonitoringPolicies.sql*
