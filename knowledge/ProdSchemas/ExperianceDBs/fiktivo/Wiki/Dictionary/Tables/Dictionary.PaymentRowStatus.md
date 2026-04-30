# Dictionary.PaymentRowStatus

> Lookup table defining the processing states of individual commission payment rows, using bitmask-style IDs (powers of 2) for potential bitwise combination.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PaymentRowStatusID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.PaymentRowStatus defines the five processing states of individual payment rows in the affiliate commission payout pipeline. Each payment row represents a line item in a commission payout batch. The bitmask-style IDs (1, 2, 4, 8, 16 - powers of 2) suggest the system may support bitwise combination of statuses for complex payment state queries.

Without this table, the payment processing system could not track where each payment row stands in the approval and execution pipeline. Finance teams use these statuses to manage payment approval workflows and track payout completion.

This is static reference data referenced by dbo.tblaff_PaymentHistory. Multiple payment-related procedures use PaymentRowStatusID for filtering, approval gating, and reporting.

---

## 2. Business Logic

### 2.1 Payment Processing Workflow

**What**: Five states in a linear approval and execution pipeline with a rejection branch.

**Columns/Parameters Involved**: `PaymentRowStatusID`, `StatusName`

**Rules**:
- ID=1 (Pending): Initial state - payment created but not yet reviewed
- ID=2 (Partially Approved): Some line items approved, others still under review - only possible in multi-item payments
- ID=4 (Approved): Fully approved and queued for processing
- ID=8 (Processed): Payment executed and funds transferred - terminal success state
- ID=16 (Rejected): Payment denied - terminal failure state
- Bitmask IDs (powers of 2) allow bitwise OR queries: e.g., WHERE StatusID & 12 > 0 matches both Approved (4) and Processed (8)

**Diagram**:
```
[Pending (1)] --> [Partially Approved (2)] --> [Approved (4)] --> [Processed (8)]
      |                                            |
      +-------------------------------------------> [Rejected (16)]
```

---

## 3. Data Overview

| PaymentRowStatusID | StatusName | Meaning |
|---|---|---|
| 1 | Pending | Payment row created but not yet reviewed or approved by the finance team. Initial state for all new payment rows |
| 2 | Partially Approved | Some line items in the payment batch are approved while others remain under review. Transitional state for complex multi-item payouts |
| 4 | Approved | Payment fully approved by finance and queued for execution. No further manual approval needed |
| 8 | Processed | Payment has been executed and funds transferred to the affiliate. Terminal success state - the affiliate has been paid |
| 16 | Rejected | Payment denied by finance - will not be processed. Terminal failure state. Affiliate may need to resolve issues before a new payment is created |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentRowStatusID | int | NO | - | VERIFIED | Primary key identifying the payment processing state. Values use bitmask pattern (powers of 2): 1=Pending, 2=Partially Approved, 4=Approved, 8=Processed, 16=Rejected. See [Payment Row Status](../../_glossary.md#payment-row-status) for full definitions. Bitmask IDs enable bitwise queries across multiple statuses. |
| 2 | StatusName | nvarchar(50) | NO | - | VERIFIED | Human-readable label for the payment status. Used in payment admin screens and finance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_PaymentHistory | PaymentRowStatusID | Implicit FK | Tracks payment status for each payment history row |
| dbo.GetPayments | WHERE | Filter | Filters payment list by status |
| dbo.GetPaymentById | JOIN | Lookup | Returns payment with status name |
| dbo.PaymentHistory_Insert | Parameter | Lookup | Sets initial status when creating payment rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentHistory | Table | Stores PaymentRowStatusID for each payment |
| dbo.GetPayments | Stored Procedure | READER - filters by status |
| dbo.GetPaymentById | Stored Procedure | READER - returns payment with status |
| dbo.PaymentHistory_Insert | Stored Procedure | WRITER - sets initial status |
| dbo.GetPaymentsForAffiliate | Stored Procedure | READER - affiliate-specific payments |
| dbo.ReadECostHistoryRecords | Stored Procedure | READER - eCost history with status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | PaymentRowStatusID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all payment statuses
```sql
SELECT PaymentRowStatusID, StatusName
FROM Dictionary.PaymentRowStatus WITH (NOLOCK)
ORDER BY PaymentRowStatusID
```

### 8.2 Find pending payments awaiting approval
```sql
SELECT ph.*
FROM dbo.tblaff_PaymentHistory ph WITH (NOLOCK)
WHERE ph.PaymentRowStatusID = 1
ORDER BY ph.PaymentHistoryID DESC
```

### 8.3 Count payments by status using bitmask query
```sql
SELECT prs.PaymentRowStatusID, prs.StatusName, COUNT(*) AS PaymentCount
FROM dbo.tblaff_PaymentHistory ph WITH (NOLOCK)
JOIN Dictionary.PaymentRowStatus prs WITH (NOLOCK) ON ph.PaymentRowStatusID = prs.PaymentRowStatusID
GROUP BY prs.PaymentRowStatusID, prs.StatusName
ORDER BY prs.PaymentRowStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentRowStatus | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.PaymentRowStatus.sql*
