# fiktivo.spafw_SetSalesAsPaid

> Marks sales commissions as paid for a specific affiliate within a date range by setting Paid=1 and recording the PaymentID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Rows affected (UPDATE) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

spafw_SetSalesAsPaid is part of the payment processing pipeline in the affiliate commission system. When a payment batch is finalized for an affiliate, this procedure is called to mark all eligible sales commissions within the specified date range as paid. This prevents the same commissions from being included in future payment runs.

The procedure targets the dbo.tblaff_Sales_Commissions table, updating records that meet all eligibility criteria: the commission must be unpaid (Paid=0), valid (Valid=1), and accepted (AffiliateSaleAccepted=1). The PaymentID is stamped on each updated record, providing a full audit trail linking commission records to their payment batch.

This is one of several "SetAsPaid" procedures in the affiliate schema, each handling a different commission type (sales, CPA, eCost, first positions, leads, registrations, etc.). They all follow the same pattern but target different commission tables.

---

## 2. Business Logic

### 2.1 Mark Sales Commissions as Paid

**What**: Updates unpaid, valid, accepted sales commissions for the specified affiliate and date range, setting them to paid status.

**Columns/Parameters Involved**: Paid, PaymentID, AffiliateID, ORDER_DATE, Valid, AffiliateSaleAccepted

**Rules**:
- UPDATE dbo.tblaff_Sales_Commissions SET Paid = 1, PaymentID = @PaymentID
- FROM dbo.tblaff_Sales INNER JOIN dbo.tblaff_Sales_Commissions ON SalesID
- WHERE AffiliateID = @AffiliateID
- AND ORDER_DATE >= @StartDate AND ORDER_DATE <= @EndDate (inclusive date range)
- AND Paid = 0 (only unpaid records)
- AND Valid = 1 (only valid records)
- AND AffiliateSaleAccepted = 1 (only accepted sales events)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate whose sales commissions should be marked as paid. |
| 2 | @StartDate | VARCHAR(12) (IN) | NO | - | CODE-BACKED | Start date of the payment period (inclusive). Compared against ORDER_DATE in tblaff_Sales. |
| 3 | @EndDate | VARCHAR(12) (IN) | NO | - | CODE-BACKED | End date of the payment period (inclusive). Compared against ORDER_DATE in tblaff_Sales. |
| 4 | @PaymentID | INT (IN) | NO | - | CODE-BACKED | The payment batch identifier to stamp on each commission record for audit trail purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_Sales | JOIN | Joins to access ORDER_DATE, Valid, and AffiliateSaleAccepted for filtering |
| - | dbo.tblaff_Sales_Commissions | UPDATE | Updates Paid and PaymentID on eligible commission records |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_SetSalesAsPaid (procedure)
├── dbo.tblaff_Sales (table, cross-schema)
└── dbo.tblaff_Sales_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

2 cross-schema dbo tables (tblaff_Sales, tblaff_Sales_Commissions).

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Mark sales commissions as paid for affiliate 100 in March 2026
```sql
EXEC fiktivo.spafw_SetSalesAsPaid
    @AffiliateID = 100,
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-31',
    @PaymentID = 5001
```

### 8.2 Preview which sales commissions would be marked as paid
```sql
SELECT
    sc.SalesCommissionID,
    sc.AffiliateID,
    sc.Commission,
    s.ORDER_DATE,
    sc.Paid,
    sc.PaymentID
FROM dbo.tblaff_Sales s WITH (NOLOCK)
INNER JOIN dbo.tblaff_Sales_Commissions sc WITH (NOLOCK)
    ON s.SalesID = sc.SalesID
WHERE sc.AffiliateID = 100
    AND s.ORDER_DATE >= '2026-03-01'
    AND s.ORDER_DATE <= '2026-03-31'
    AND sc.Paid = 0
    AND s.Valid = 1
    AND s.AffiliateSaleAccepted = 1
```

### 8.3 Verify payment batch was applied correctly
```sql
SELECT
    sc.AffiliateID,
    COUNT(*) AS PaidRecords,
    SUM(sc.Commission) AS TotalPaid
FROM dbo.tblaff_Sales_Commissions sc WITH (NOLOCK)
WHERE sc.PaymentID = 5001
    AND sc.Paid = 1
GROUP BY sc.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 7.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_SetSalesAsPaid | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_SetSalesAsPaid.sql*
