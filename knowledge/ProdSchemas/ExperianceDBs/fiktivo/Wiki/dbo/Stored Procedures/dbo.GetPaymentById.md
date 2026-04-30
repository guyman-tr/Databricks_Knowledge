# dbo.GetPaymentById

> Retrieves a single payment history record with full tier breakdown and optional eCost history details by payment ID, joining tblaff_PaymentHistory to tblaff_eCostHistory.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

Payment records in the affiliate platform capture a full snapshot of a payment run: the total amount, approval workflow state, and a per-tier breakdown of every commission type (CPA, Sales, Registrations, Leads, Clicks, CopyTraders, FirstPositions, eCost) across up to five affiliate tiers. Finance, affiliate managers, and the payment approval workflow all need to retrieve a single payment record by its ID to inspect, approve, or export it.

This procedure is the canonical single-record read for the payment detail view. It joins to tblaff_eCostHistory via a LEFT JOIN to include any linked eCost cost history entry (TotalAmount and IsCommissionPlanAdjustment) without excluding payments that have no eCost history row.

---

## 2. Business Logic

### 2.1 Payment Record with eCost History Enrichment

**What**: Fetches all columns from tblaff_PaymentHistory for the given PaymentID, enriched with eCostHistory fields where available.

**Columns/Parameters Involved**: `@Id`, `PaymentHistory.PaymentID`, `eCostHistory.eCostHistoryID`

**Rules**:
- WHERE PaymentHistory.PaymentID = @Id; returns at most one row from tblaff_PaymentHistory
- LEFT JOIN to tblaff_eCostHistory on eCostHistoryID; if PaymentHistory.eCostHistoryID is NULL or has no match, TotalAmount and IsCommissionPlanAdjustment are NULL in the result
- No status filter applied; all payment statuses (pending, approved, rejected, archived) are returned

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @Id | IN | int | (required) | The PaymentID primary key of the payment record to retrieve. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_PaymentHistory | SELECT | Primary source of the payment record |
| dbo.tblaff_eCostHistory | SELECT (LEFT JOIN) | Optional eCost cost history details |

### 5.3 Result Set

The result set includes all columns from tblaff_PaymentHistory plus two columns from tblaff_eCostHistory. Key columns:

| Column | Source | Description |
|--------|--------|-------------|
| PaymentID | tblaff_PaymentHistory | Primary key |
| AffiliateID | tblaff_PaymentHistory | Affiliate receiving the payment |
| PaymentDate | tblaff_PaymentHistory | Date the payment was issued |
| PaymentAmount | tblaff_PaymentHistory | Total payment amount |
| PaymentAdjustment | tblaff_PaymentHistory | Manual adjustment applied to the payment |
| Tier1-5 CPA/Sales/Registrations/Leads/Clicks | tblaff_PaymentHistory | Count and commission for each commission type per tier (25 count columns, 25 commission columns) |
| Tier1-5 CopyTraders/FirstPositions | tblaff_PaymentHistory | Copy trader and first position counts and commissions per tier |
| PaymentRowStatusID | tblaff_PaymentHistory | Bitmask status of the payment row |
| ManagerApproved / Approved / VPMarketingApproved / FinanceApproved / FinanceManagerApproved | tblaff_PaymentHistory | Multi-stage approval flags |
| ApprovalDate / LastApprovalDate | tblaff_PaymentHistory | Timestamps of approval steps |
| PaymentPeriod | tblaff_PaymentHistory | The period this payment covers |
| PaymentGroupCode | tblaff_PaymentHistory | GUID grouping batch payments |
| CurrencyID | tblaff_PaymentHistory | Currency of the payment |
| ReferenceNumber | tblaff_PaymentHistory | External reference number |
| TotalAmount | tblaff_eCostHistory | Total eCost amount from the linked history row (NULL if no eCost history) |
| IsCommissionPlanAdjustment | tblaff_eCostHistory | Whether this payment is a commission plan adjustment (NULL if no eCost history) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetPaymentById (stored procedure)
+-- dbo.tblaff_PaymentHistory (table) [SELECT]
+-- dbo.tblaff_eCostHistory (table) [LEFT JOIN]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentHistory | Table | Primary source of payment data |
| dbo.tblaff_eCostHistory | Table | Optional eCost cost history enrichment |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment detail view (admin portal) | Application | Calls this procedure to display a specific payment record |
| Payment approval workflow | Application | Retrieves payment record before updating approval status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- WITH (NOLOCK) applied to both tables
- The result set is wide (70+ columns); all columns are explicitly listed rather than using SELECT *
- The LEFT JOIN ensures payments without eCost history are still returned; eCost columns will be NULL
- No status filter; use dbo.GetPayments or dbo.GetPaymentsForAffiliate for filtered/bulk retrieval

---

## 8. Sample Queries

### 8.1 Retrieve a payment by ID

```sql
EXEC dbo.GetPaymentById @Id = 5001;
```

### 8.2 Check payment approval status

```sql
SELECT PaymentID, PaymentAmount, PaymentRowStatusID,
       ManagerApproved, Approved, FinanceApproved
FROM dbo.tblaff_PaymentHistory WITH (NOLOCK)
WHERE PaymentID = 5001;
```

### 8.3 Find recent payments with eCost history

```sql
SELECT ph.PaymentID, ph.AffiliateID, ph.PaymentAmount, ec.TotalAmount
FROM dbo.tblaff_PaymentHistory ph WITH (NOLOCK)
LEFT JOIN dbo.tblaff_eCostHistory ec WITH (NOLOCK) ON ph.eCostHistoryID = ec.eCostHistoryID
WHERE ph.eCostHistoryID IS NOT NULL
ORDER BY ph.PaymentDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10*
*Object: dbo.GetPaymentById | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetPaymentById.sql*
