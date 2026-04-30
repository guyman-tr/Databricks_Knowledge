# fiktivo.spafw_SeteCostAsPaid

> Marks eCost commissions as paid for a specific affiliate within a date range by setting Paid=1 and recording the PaymentID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Rows affected (UPDATE) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

spafw_SeteCostAsPaid is part of the payment processing pipeline in the affiliate commission system. When a payment batch is finalized for an affiliate, this procedure is called to mark all eligible eCost commissions within the specified date range as paid. This prevents the same commissions from being included in future payment runs.

The procedure targets the dbo.tblaff_eCost_Commissions table, updating records that meet all eligibility criteria: the commission must be unpaid (Paid=0), valid (Valid=1), and accepted (AffiliateeCostAccepted=1). The PaymentID is stamped on each updated record, providing a full audit trail linking commission records to their payment batch.

This is one of several "SetAsPaid" procedures in the affiliate schema, each handling a different commission type (eCost, CPA, first positions, sales, leads, etc.). They all follow the same pattern but target different commission tables.

---

## 2. Business Logic

### 2.1 Mark eCost Commissions as Paid

**What**: Updates unpaid, valid, accepted eCost commissions for the specified affiliate and date range, setting them to paid status.

**Columns/Parameters Involved**: Paid, PaymentID, AffiliateID, ORDER_DATE, Valid, AffiliateeCostAccepted

**Rules**:
- UPDATE dbo.tblaff_eCost_Commissions SET Paid = 1, PaymentID = @PaymentID
- FROM dbo.tblaff_eCost INNER JOIN dbo.tblaff_eCost_Commissions ON eCostID
- WHERE AffiliateID = @AffiliateID
- AND ORDER_DATE >= @StartDate AND ORDER_DATE <= @EndDate (inclusive date range)
- AND Paid = 0 (only unpaid records)
- AND Valid = 1 (only valid records)
- AND AffiliateeCostAccepted = 1 (only accepted eCost events)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate whose eCost commissions should be marked as paid. |
| 2 | @StartDate | VARCHAR(12) (IN) | NO | - | CODE-BACKED | Start date of the payment period (inclusive). Compared against ORDER_DATE in tblaff_eCost. |
| 3 | @EndDate | VARCHAR(12) (IN) | NO | - | CODE-BACKED | End date of the payment period (inclusive). Compared against ORDER_DATE in tblaff_eCost. |
| 4 | @PaymentID | INT (IN) | NO | - | CODE-BACKED | The payment batch identifier to stamp on each commission record for audit trail purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_eCost | JOIN | Joins to access ORDER_DATE, Valid, and AffiliateeCostAccepted for filtering |
| - | dbo.tblaff_eCost_Commissions | UPDATE | Updates Paid and PaymentID on eligible commission records |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_SeteCostAsPaid (procedure)
├── dbo.tblaff_eCost (table, cross-schema)
└── dbo.tblaff_eCost_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

2 cross-schema dbo tables (tblaff_eCost, tblaff_eCost_Commissions).

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

### 8.1 Mark eCost commissions as paid for affiliate 100 in March 2026
```sql
EXEC fiktivo.spafw_SeteCostAsPaid
    @AffiliateID = 100,
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-31',
    @PaymentID = 5001
```

### 8.2 Preview which eCost commissions would be marked as paid
```sql
SELECT
    ec.eCostCommissionID,
    ec.AffiliateID,
    ec.Commission,
    e.ORDER_DATE,
    ec.Paid,
    ec.PaymentID
FROM dbo.tblaff_eCost e WITH (NOLOCK)
INNER JOIN dbo.tblaff_eCost_Commissions ec WITH (NOLOCK)
    ON e.eCostID = ec.eCostID
WHERE ec.AffiliateID = 100
    AND e.ORDER_DATE >= '2026-03-01'
    AND e.ORDER_DATE <= '2026-03-31'
    AND ec.Paid = 0
    AND e.Valid = 1
    AND e.AffiliateeCostAccepted = 1
```

### 8.3 Verify payment batch was applied correctly
```sql
SELECT
    ec.AffiliateID,
    COUNT(*) AS PaidRecords,
    SUM(ec.Commission) AS TotalPaid
FROM dbo.tblaff_eCost_Commissions ec WITH (NOLOCK)
WHERE ec.PaymentID = 5001
    AND ec.Paid = 1
GROUP BY ec.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 7.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_SeteCostAsPaid | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_SeteCostAsPaid.sql*
