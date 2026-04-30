# Billing.GetPaymentsTotals

> Returns three aggregate payment metrics as OUTPUT parameters: total payment sum, total approved payment sum, and the percentage of approved payments - a simple KPI snapshot of the entire Billing.Payment table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Three OUTPUT parameters: @SumTotalAmount, @SumApprovedAmount, @PercentApproved |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPaymentsTotals` computes three summary KPIs across ALL records in `Billing.Payment`: the total sum of all payment amounts, the sum of approved payment amounts (PaymentStatusID=2), and the approval rate percentage. These metrics represent the lifetime payment volume and quality for the eToro platform.

The procedure exists as a quick dashboard/reporting query that bypasses the need to write raw aggregation SQL. Billing managers and BI analysts can call it to get a snapshot of total vs approved payment volume at any point.

Data flows: the procedure runs two `SELECT SUM(Amount)` queries against `Billing.Payment` (no time filter, no currency filter - all records ever), then computes percentage as integer division. Results are returned exclusively through OUTPUT parameters; no result set is returned.

---

## 2. Business Logic

### 2.1 Approval Rate Calculation (Integer Division)

**What**: @PercentApproved is calculated as `@SumApprovedAmount * 100 / @SumTotalAmount` using integer arithmetic.

**Columns/Parameters Involved**: `@SumApprovedAmount`, `@SumTotalAmount`, `@PercentApproved`

**Rules**:
- Integer division (BIGINT / BIGINT) - result is truncated, not rounded (e.g., 87.9% -> 87)
- If @SumTotalAmount is 0 (no payments ever), this causes a divide-by-zero error (no guard)
- The percentage is a full lifetime metric - no date range filtering
- Amounts are summed across all currencies and funding types without normalization (USD-equivalent is not computed)

### 2.2 No Filtering - Lifetime Aggregates

**What**: Both SUM queries have no WHERE clause beyond `PaymentStatusID = 2` for the approved filter.

**Rules**:
- @SumTotalAmount includes ALL payments: approved, declined, pending, refunded, etc.
- @SumApprovedAmount counts only `PaymentStatusID = 2` (Approved)
- No date range, no currency filter, no funding type filter

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SumTotalAmount | BIGINT OUTPUT | NO | - | CODE-BACKED | OUTPUT: Sum of `Billing.Payment.Amount` across ALL payments (all statuses, all time). Returned in the native amount unit (integer, assumed USD). |
| 2 | @SumApprovedAmount | BIGINT OUTPUT | NO | - | CODE-BACKED | OUTPUT: Sum of `Billing.Payment.Amount` for approved payments only (`PaymentStatusID = 2`). Subset of @SumTotalAmount. |
| 3 | @PercentApproved | INTEGER OUTPUT | NO | - | CODE-BACKED | OUTPUT: Integer approval rate: `@SumApprovedAmount * 100 / @SumTotalAmount`. Truncated (not rounded). Represents the percentage of total payment volume that was successfully approved. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source) | Billing.Payment | SELECT (two aggregations) | Aggregates Amount from all payments; second query filters to PaymentStatusID=2 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER | GRANT EXECUTE | Permission | Billing management role - KPI reporting |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin role - aggregate reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPaymentsTotals (procedure)
└── Billing.Payment (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | Two SUM(Amount) aggregations - one full table, one filtered to PaymentStatusID=2 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BILLING_MANAGER | DB Security Principal | EXECUTE permission |
| PROD_BIadmins | DB Security Principal | EXECUTE permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Notable**: No `WITH (NOLOCK)` hints on the two SELECT statements - this procedure takes shared locks on `Billing.Payment` (a very large table with ~7.7M rows). Consider adding NOLOCK if used in reporting contexts. The integer division for @PercentApproved truncates rather than rounds, and there is no divide-by-zero guard.

---

## 8. Sample Queries

### 8.1 Execute and read the OUTPUT parameters
```sql
DECLARE @Total BIGINT, @Approved BIGINT, @Pct INT
EXEC [Billing].[GetPaymentsTotals]
    @SumTotalAmount = @Total OUTPUT,
    @SumApprovedAmount = @Approved OUTPUT,
    @PercentApproved = @Pct OUTPUT

SELECT @Total AS TotalAmount, @Approved AS ApprovedAmount, @Pct AS ApprovalPct
```

### 8.2 Equivalent direct query with rounding
```sql
SELECT
    SUM(Amount) AS TotalAmount,
    SUM(CASE WHEN PaymentStatusID = 2 THEN Amount ELSE 0 END) AS ApprovedAmount,
    ROUND(
        100.0 * SUM(CASE WHEN PaymentStatusID = 2 THEN Amount ELSE 0 END)
        / NULLIF(SUM(Amount), 0),
        1
    ) AS ApprovalPctRounded
FROM Billing.Payment WITH (NOLOCK)
```

### 8.3 Breakdown by funding type for context
```sql
SELECT
    FundingTypeID,
    SUM(Amount) AS TotalAmount,
    SUM(CASE WHEN PaymentStatusID = 2 THEN Amount ELSE 0 END) AS ApprovedAmount,
    COUNT(*) AS PaymentCount
FROM Billing.Payment WITH (NOLOCK)
GROUP BY FundingTypeID
ORDER BY TotalAmount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPaymentsTotals | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPaymentsTotals.sql*
