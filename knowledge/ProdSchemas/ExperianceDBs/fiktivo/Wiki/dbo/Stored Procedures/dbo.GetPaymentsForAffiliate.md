# dbo.GetPaymentsForAffiliate

> Returns payment history records for a specific affiliate with optional filtering by payment period, payment date range, and status bitmask, joining to eCostHistory for cost data enrichment.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

Affiliates viewing their own payment history on the portal, and affiliate managers reviewing the payment record of a specific affiliate, need a filtered view of payment records scoped to one affiliate. This procedure provides that view, supporting optional date range filters at both the payment-date level and the payment-period level, as well as a bitmask status filter.

Unlike dbo.GetPayments, which uses dynamic SQL for multi-affiliate admin queries, this procedure uses a static query with standard AND/OR NULL-coalescing patterns for its optional filters. This makes it simpler and predictable for single-affiliate reads.

The default @Status = 31 (binary 11111 -- all five lower status bits set) returns payments in any of the five standard active statuses.

---

## 2. Business Logic

### 2.1 Affiliate Scope

**What**: Restricts results to a single affiliate.

**Columns/Parameters Involved**: `@AffiliateId`, `PaymentHistory.AffiliateID`

**Rules**:
- WHERE PaymentHistory.AffiliateID = @AffiliateId is always applied; @AffiliateId is required

### 2.2 Status Bitmask Filter

**What**: Filters payments by their status using a bitmask.

**Columns/Parameters Involved**: `@Status`, `PaymentHistory.PaymentRowStatusID`

**Rules**:
- (@Status & PaymentRowStatusID = PaymentRowStatusID): returns rows where all bits in PaymentRowStatusID are set in @Status
- Default is 31 (binary 11111), matching all rows with status bits 1-5
- PaymentRowStatusID = 0 rows are excluded when @Status > 0, since (0 & @Status = 0) = 0 = @Status only when @Status = 0

### 2.3 Optional Date Filters

**What**: Payment date and period filters are independently optional.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `@FromPeriod`, `@ToPeriod`, `PaymentHistory.PaymentDate`, `PaymentHistory.PaymentPeriod`

**Rules**:
- (PaymentDate >= @FromDate OR @FromDate IS NULL): NULL means no lower bound on PaymentDate
- (PaymentDate <= @ToDate OR @ToDate IS NULL): NULL means no upper bound on PaymentDate
- Same NULL-coalescing pattern applied independently to PaymentPeriod via @FromPeriod / @ToPeriod
- All four date parameters are independently optional

### 2.4 eCostHistory Enrichment

**What**: Joins tblaff_eCostHistory to include cost history details when available.

**Rules**:
- LEFT JOIN on eCostHistoryID; payments without eCost history rows still appear with NULL eCost columns

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @AffiliateId | IN | int | (required) | The AffiliateID for which to retrieve payment records. |
| 2 | @FromPeriod | IN | datetime | NULL | Lower bound on PaymentPeriod. NULL means no lower bound. |
| 3 | @ToPeriod | IN | datetime | NULL | Upper bound on PaymentPeriod. NULL means no upper bound. |
| 4 | @FromDate | IN | datetime | NULL | Lower bound on PaymentDate. NULL means no lower bound. |
| 5 | @ToDate | IN | datetime | NULL | Upper bound on PaymentDate. NULL means no upper bound. |
| 6 | @Status | IN | int | 31 | Bitmask status filter. Returns rows where (PaymentRowStatusID & @Status) = PaymentRowStatusID. Default 31 returns all standard active statuses. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_PaymentHistory | SELECT | Primary source of payment records for the affiliate |
| dbo.tblaff_eCostHistory | SELECT (LEFT JOIN) | Optional eCost cost history enrichment |

### 5.3 Result Set

The result set is the same wide structure as dbo.GetPaymentById: all columns from tblaff_PaymentHistory plus TotalAmount and IsCommissionPlanAdjustment from tblaff_eCostHistory. Multiple rows are returned (one per qualifying payment).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetPaymentsForAffiliate (stored procedure)
+-- dbo.tblaff_PaymentHistory (table) [SELECT]
+-- dbo.tblaff_eCostHistory (table) [LEFT JOIN]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentHistory | Table | Primary payment data source |
| dbo.tblaff_eCostHistory | Table | eCost enrichment data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate payment history page | Application | Calls this procedure to display an affiliate's own payment records |
| Affiliate manager payment review | Application | Calls this procedure scoped to a specific affiliate under management |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON (via Set NoCount On) suppresses rowcount messages
- WITH (NOLOCK) applied to both tables
- The NULL-coalescing OR pattern for optional filters may prevent optimal index seeks on large datasets; for high-volume affiliates dbo.GetPayments (dynamic SQL) may be more efficient
- Default @Status = 31 returns payments in statuses 1, 2, 4, 8, 16 (all bits of the lower 5 set); adjust to filter specific statuses
- Both date dimensions (PaymentDate and PaymentPeriod) can be filtered independently; callers typically use one or the other

---

## 8. Sample Queries

### 8.1 Return all active payments for an affiliate

```sql
EXEC dbo.GetPaymentsForAffiliate @AffiliateId = 1001;
```

### 8.2 Filter by payment period

```sql
EXEC dbo.GetPaymentsForAffiliate
    @AffiliateId = 1001,
    @FromPeriod  = '2025-01-01',
    @ToPeriod    = '2025-03-31';
```

### 8.3 Filter by payment date and status

```sql
EXEC dbo.GetPaymentsForAffiliate
    @AffiliateId = 1001,
    @FromDate    = '2025-01-01',
    @ToDate      = '2025-03-31',
    @Status      = 4;
```

### 8.4 Return all payments regardless of status

```sql
EXEC dbo.GetPaymentsForAffiliate
    @AffiliateId = 1001,
    @Status      = 255; -- all bits set
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10*
*Object: dbo.GetPaymentsForAffiliate | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetPaymentsForAffiliate.sql*
