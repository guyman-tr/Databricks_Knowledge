# Scheduler.GetPlanByPaymentId

> Retrieves a recurring payment plan by its associated PaymentId, bridging the Scheduler and Recurring schemas for payment-level lookups.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns a single Plan row for the specified PaymentId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.GetPlanByPaymentId retrieves a recurring payment plan using the PaymentId - the cross-schema identifier that links a scheduler plan to the payment record in the Recurring schema. This is the reverse lookup from GetPlanById: instead of knowing the PlanId directly, the caller has a PaymentId and needs to find the corresponding scheduling plan.

This procedure supports workflows that originate from the payment side of the system. For example, when a user modifies their recurring payment (changes amount, payment method, etc.) through the Recurring schema, the system needs to find and potentially update the associated scheduler plan. Similarly, when displaying plan details in a customer-facing UI, the application often has the PaymentId from the user's context and needs to resolve the scheduling configuration.

The procedure returns a subset of plan columns - notably, it does NOT return EndDate or ChargingDay, unlike GetPlanById which returns all columns. This lighter result set suggests it is used in contexts where only the core scheduling parameters (frequency, start date) are needed, not the full plan lifecycle state.

---

## 2. Business Logic

### 2.1 Payment-to-Plan Lookup

**What**: Resolves a PaymentId to its corresponding scheduler plan record.

**Columns/Parameters Involved**: `@PaymentId`, `Scheduler.Plan.PaymentId`

**Rules**:
- Exact match on PaymentId
- The relationship between Payment and Plan is one-to-one (one plan per payment)
- Returns zero rows if no plan exists for the given PaymentId
- Does NOT use NOLOCK - reads with default isolation level
- Returns a reduced column set: PlanId, PaymentId, FrequencyId, StartDate, StartDateWithUserOffset
- Omits EndDate and ChargingDay from the result set (unlike GetPlanById)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | VERIFIED | Cross-schema identifier linking to the payment record in the Recurring schema. Used as the lookup key. |
| 2 | PlanId | int (OUT) | NO | - | CODE-BACKED | Primary key of the scheduler plan. The resolved identifier the caller needs. |
| 3 | PaymentId | int (OUT) | NO | - | CODE-BACKED | Echoes back the input PaymentId. Confirms the mapping. |
| 4 | FrequencyId | int (OUT) | NO | - | CODE-BACKED | Recurring cadence. See [Frequency](_glossary.md#frequency). 1=Weekly, 2=BiWeekly, 3=Monthly. |
| 5 | StartDate | datetime2 (OUT) | NO | - | CODE-BACKED | UTC date when the plan's scheduling begins. |
| 6 | StartDateWithUserOffset | nvarchar (OUT) | YES | - | CODE-BACKED | The plan's start date adjusted for the user's timezone offset. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentId | Scheduler.Plan | FK parameter | Looks up the plan by its PaymentId foreign key |
| (SELECT) | Scheduler.Plan | Direct Read | Reads the plan record |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker resolves PaymentId to PlanId for cross-schema operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.GetPlanByPaymentId (procedure)
└── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Plan | Table | READER - looks up plan by PaymentId |

### 6.2 Objects That Depend On This

No database dependents. Called by RecurringScheduler application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up a plan by its PaymentId
```sql
EXEC Scheduler.GetPlanByPaymentId @PaymentId = 500123;
```

### 8.2 Verify the plan-payment mapping exists
```sql
DECLARE @PayId INT = 500123;
EXEC Scheduler.GetPlanByPaymentId @PaymentId = @PayId;
```

### 8.3 Manually find a plan with full details including EndDate and ChargingDay
```sql
-- GetPlanByPaymentId omits EndDate and ChargingDay; use this for full details
SELECT p.PlanId, p.PaymentId, p.FrequencyId, p.StartDate, p.StartDateWithUserOffset, p.EndDate, p.ChargingDay
FROM Scheduler.[Plan] p
WHERE p.PaymentId = 500123;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.GetPlanByPaymentId | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.GetPlanByPaymentId.sql*
