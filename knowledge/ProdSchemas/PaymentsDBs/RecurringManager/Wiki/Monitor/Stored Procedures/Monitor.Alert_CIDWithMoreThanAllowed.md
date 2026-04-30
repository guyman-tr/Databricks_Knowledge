# Monitor.Alert_CIDWithMoreThanAllowed

> Datadog monitoring alert that detects customers with more than one active recurring payment, returning a scalar 0/1 flag suitable for automated health checks.

| Property | Value |
|----------|-------|
| **Schema** | Monitor |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar: 0 = no violations, 1 = at least one customer exceeds limit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitor.Alert_CIDWithMoreThanAllowed is a monitoring alert procedure designed specifically for Datadog integration. It checks whether any customer (CID) in the system has more than one active recurring payment (StatusId = 1). The procedure returns a simple scalar value (0 or 1) that Datadog can consume as a custom check metric to trigger alerts when the business invariant is violated.

This procedure exists because the recurring payments system enforces a constraint that each customer should have at most one active recurring payment plan at any given time. Violations of this rule could indicate a race condition in plan creation, a bug in plan cancellation logic, or an edge case in the payment lifecycle. Detecting these violations early via monitoring prevents double-charging customers.

The procedure is called by Datadog on a schedule (via the `datadog` SQL user which has EXECUTE permission). It queries Recurring.Payment for active plans (StatusId = 1), groups by customer (CID), and checks if any customer has more than one. A companion procedure exists in the Recurring schema (`Recurring.Alert_CIDWithMoreThanAllowed`) that provides richer output (actual CID list and counts) and a configurable threshold parameter - used by the application services (prod pod identities) and Splunk. The Monitor version is a simplified, hardcoded variant optimized for Datadog's scalar-check pattern.

---

## 2. Business Logic

### 2.1 Active Plan Limit Enforcement

**What**: Detects customers who violate the one-active-recurring-payment-per-customer business rule.

**Columns/Parameters Involved**: `Recurring.Payment.StatusId`, `Recurring.Payment.Cid`, `Recurring.Payment.PaymentId`

**Rules**:
- Filters to only Active payments (StatusId = 1). See [Plan Status](../../_glossary.md#plan-status): 1=Active, 2=Cancelled, 3=Stopped, 4=Invalid, 5=Paused
- Groups by CID (customer identifier) and counts active PaymentIds per customer
- Threshold is hardcoded at > 1 (the Recurring schema version accepts a configurable `@AllowedPlansCountPerUser` parameter, defaulting to 1)
- Returns 1 (alert) if ANY customer exceeds the limit; 0 (clear) if all customers are within limits
- Does not identify WHICH customers are in violation - that detail is available from the Recurring schema version

**Diagram**:
```
Datadog Scheduler
       |
       v
  EXEC Monitor.Alert_CIDWithMoreThanAllowed
       |
       v
  SELECT TOP 1 @Result = 1
  FROM Recurring.Payment
  WHERE StatusId = 1          -- Active plans only
  GROUP BY Cid
  HAVING COUNT(PaymentId) > 1 -- More than 1 active plan
       |
       +-- @Result = 0 -> All clear, no alert
       +-- @Result = 1 -> Violation detected -> Datadog triggers alert
```

### 2.2 Monitor vs Recurring Schema Variants

**What**: Two versions of the same alert exist for different consumers.

**Columns/Parameters Involved**: N/A (architectural pattern)

**Rules**:
- `Monitor.Alert_CIDWithMoreThanAllowed` (this procedure): No parameters, returns scalar 0/1 via `SELECT @Result AS [Value]`. Granted only to `datadog` user. Created 2023-03-21.
- `Recurring.Alert_CIDWithMoreThanAllowed`: Accepts `@AllowedPlansCountPerUser` (default 1), returns result set of violating CIDs with counts, plus RETURN code 0/1. Granted to `datadog`, `SplunkUser`, and production pod identities. Created 2021-07-29.
- The Monitor version was created ~20 months after the Recurring version, likely to provide a cleaner interface for Datadog's custom check format which expects a simple scalar value

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters and one output column.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Value (output column) | int | NO | - | CODE-BACKED | Scalar alert flag: 0 = no customer has more than one active recurring payment (system is healthy), 1 = at least one customer has multiple active payments (violation detected, Datadog should fire alert). Derived from a TOP 1 existence check against Recurring.Payment grouped by CID where StatusId = 1 (Active). |

**Internal Variables:**
| Variable | Type | Purpose |
|----------|------|---------|
| @Result | int | Initialized to 0 (clear). Set to 1 if the grouped query finds any customer with COUNT(PaymentId) > 1 among active payments. Returned as the `Value` output column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM clause) | Recurring.Payment | READER | Reads active recurring payments (StatusId = 1) to detect customers with multiple active plans. Uses Payment.Cid for grouping and Payment.PaymentId for counting. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| datadog (SQL user) | EXECUTE permission | External Consumer | Datadog monitoring agent calls this procedure on a schedule to check for active plan limit violations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitor.Alert_CIDWithMoreThanAllowed (procedure)
└── Recurring.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | SELECT FROM - reads StatusId, Cid, PaymentId to detect customers with multiple active plans |

### 6.2 Objects That Depend On This

No database objects depend on this procedure. It is called externally by Datadog monitoring.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Relevant indexes on Recurring.Payment used by this query:**
- `IX_RecurringPayment_StatusId` on (StatusId ASC) - supports the WHERE StatusId = 1 filter
- `IX_RecurringPayment_CID` on (Cid ASC) - supports the GROUP BY Cid

### 7.2 Constraints

None.

**Procedure characteristics:**
- SET NOCOUNT ON (suppresses row count messages)
- No explicit transaction handling (single SELECT, no writes)
- No error handling (simple read-only check)
- Author: Ran Ovadia (comment in DDL, dated 21/3/23)

---

## 8. Sample Queries

### 8.1 Execute the alert check
```sql
EXEC Monitor.Alert_CIDWithMoreThanAllowed
-- Returns: Value = 0 (clear) or Value = 1 (violation detected)
```

### 8.2 Manually investigate which customers have multiple active plans
```sql
SELECT p.Cid, COUNT(p.PaymentId) AS ActivePlanCount
FROM Recurring.Payment p WITH (NOLOCK)
WHERE p.StatusId = 1  -- Active
GROUP BY p.Cid
HAVING COUNT(p.PaymentId) > 1
ORDER BY ActivePlanCount DESC
```

### 8.3 Compare with the Recurring schema version (includes configurable threshold)
```sql
EXEC Recurring.Alert_CIDWithMoreThanAllowed @AllowedPlansCountPerUser = 1
-- Returns: Result set of violating CIDs + counts, plus RETURN code 0/1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Recurring variant) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitor.Alert_CIDWithMoreThanAllowed | Type: Stored Procedure | Source: RecurringManager/Monitor/Stored Procedures/Monitor.Alert_CIDWithMoreThanAllowed.sql*
