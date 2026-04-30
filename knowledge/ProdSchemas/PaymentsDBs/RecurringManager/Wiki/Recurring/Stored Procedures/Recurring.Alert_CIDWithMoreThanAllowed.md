# Recurring.Alert_CIDWithMoreThanAllowed

> Monitoring alert that detects customers with more active recurring payment plans than the allowed threshold, returning violating CIDs with their plan counts.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set of (Cid, CidActivePlansCount) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This stored procedure is a monitoring alert that identifies customers who have more active recurring payment plans than a configurable threshold. By default, each customer should have at most 1 active plan (StatusId=1), so any customer with 2 or more active plans represents an anomaly that may indicate a duplicate creation bug or race condition in the CreatePayment logic.

The alert is used by operational monitoring systems. It queries Recurring.Payment, groups by Cid, and returns any customers exceeding the threshold. Returns 1 if violations found, 0 if clean.

---

## 2. Business Logic

### 2.1 Active Plan Count Violation Detection

**What**: Finds customers with more active payment plans than allowed.

**Columns/Parameters Involved**: `@AllowedPlansCountPerUser`, Payment.`Cid`, Payment.`StatusId`

**Rules**:
- Only counts payments with StatusId=1 (Active)
- Default threshold is 1 (one active plan per customer)
- RETURN 0 = no violations found (healthy)
- RETURN 1 = at least one customer exceeds the threshold (alert should fire)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AllowedPlansCountPerUser | int (IN) | NO | 1 | VERIFIED | Maximum number of active plans a customer is allowed. Customers with counts exceeding this value are returned. Default 1 matches the business rule enforced by CreatePayment. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Cid | int | NO | - | CODE-BACKED | Customer ID with excess active plans. |
| 2 | CidActivePlansCount | int | NO | - | CODE-BACKED | Number of active plans for this customer. Always > @AllowedPlansCountPerUser. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.Payment | READER | Queries active payments grouped by Cid |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.Alert_CIDWithMoreThanAllowed (procedure)
└── Recurring.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | SELECT with GROUP BY Cid WHERE StatusId=1 |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run the alert with default threshold
```sql
EXEC Recurring.Alert_CIDWithMoreThanAllowed
```

### 8.2 Check for customers with more than 2 active plans
```sql
EXEC Recurring.Alert_CIDWithMoreThanAllowed @AllowedPlansCountPerUser = 2
```

### 8.3 Equivalent ad-hoc query
```sql
SELECT p.Cid, COUNT(p.PaymentId) AS ActivePlanCount
FROM Recurring.Payment p WITH (NOLOCK)
WHERE p.StatusId = 1
GROUP BY p.Cid
HAVING COUNT(p.PaymentId) > 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.Alert_CIDWithMoreThanAllowed | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.Alert_CIDWithMoreThanAllowed.sql*
