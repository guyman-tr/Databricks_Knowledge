# fiktivo.spafw_SetFirstPositionsAsPaid

> Marks first position commissions as paid for a specific affiliate within a date range by setting Paid=1 and recording the PaymentID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Rows affected (UPDATE) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

spafw_SetFirstPositionsAsPaid is part of the payment processing pipeline in the affiliate commission system. When a payment batch is finalized for an affiliate, this procedure is called to mark all eligible first position commissions within the specified date range as paid. This prevents the same commissions from being included in future payment runs.

The procedure targets the dbo.tblaff_FirstPositions_Commissions table, updating records that meet all eligibility criteria: the commission must be unpaid (Paid=0), valid (Valid=1), and accepted (AffiliateFirstPositionAccepted=1). The PaymentID is stamped on each updated record, providing a full audit trail linking commission records to their payment batch.

This is one of several "SetAsPaid" procedures in the affiliate schema, each handling a different commission type (first positions, CPA, eCost, sales, leads, etc.). They all follow the same pattern but target different commission tables.

---

## 2. Business Logic

### 2.1 Mark First Position Commissions as Paid

**What**: Updates unpaid, valid, accepted first position commissions for the specified affiliate and date range, setting them to paid status.

**Columns/Parameters Involved**: Paid, PaymentID, AffiliateID, ORDER_DATE, Valid, AffiliateFirstPositionAccepted

**Rules**:
- UPDATE dbo.tblaff_FirstPositions_Commissions SET Paid = 1, PaymentID = @PaymentID
- FROM dbo.tblaff_FirstPositions INNER JOIN dbo.tblaff_FirstPositions_Commissions ON FirstPositionID
- WHERE AffiliateID = @AffiliateID
- AND ORDER_DATE >= @StartDate AND ORDER_DATE <= @EndDate (inclusive date range)
- AND Paid = 0 (only unpaid records)
- AND Valid = 1 (only valid records)
- AND AffiliateFirstPositionAccepted = 1 (only accepted first position events)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate whose first position commissions should be marked as paid. |
| 2 | @StartDate | VARCHAR(12) (IN) | NO | - | CODE-BACKED | Start date of the payment period (inclusive). Compared against ORDER_DATE in tblaff_FirstPositions. |
| 3 | @EndDate | VARCHAR(12) (IN) | NO | - | CODE-BACKED | End date of the payment period (inclusive). Compared against ORDER_DATE in tblaff_FirstPositions. |
| 4 | @PaymentID | INT (IN) | NO | - | CODE-BACKED | The payment batch identifier to stamp on each commission record for audit trail purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_FirstPositions | JOIN | Joins to access ORDER_DATE, Valid, and AffiliateFirstPositionAccepted for filtering |
| - | dbo.tblaff_FirstPositions_Commissions | UPDATE | Updates Paid and PaymentID on eligible commission records |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_SetFirstPositionsAsPaid (procedure)
├── dbo.tblaff_FirstPositions (table, cross-schema)
└── dbo.tblaff_FirstPositions_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

2 cross-schema dbo tables (tblaff_FirstPositions, tblaff_FirstPositions_Commissions).

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

### 8.1 Mark first position commissions as paid for affiliate 100 in March 2026
```sql
EXEC fiktivo.spafw_SetFirstPositionsAsPaid
    @AffiliateID = 100,
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-31',
    @PaymentID = 5001
```

### 8.2 Preview which first position commissions would be marked as paid
```sql
SELECT
    fpc.FirstPositionCommissionID,
    fpc.AffiliateID,
    fpc.Commission,
    fp.ORDER_DATE,
    fpc.Paid,
    fpc.PaymentID
FROM dbo.tblaff_FirstPositions fp WITH (NOLOCK)
INNER JOIN dbo.tblaff_FirstPositions_Commissions fpc WITH (NOLOCK)
    ON fp.FirstPositionID = fpc.FirstPositionID
WHERE fpc.AffiliateID = 100
    AND fp.ORDER_DATE >= '2026-03-01'
    AND fp.ORDER_DATE <= '2026-03-31'
    AND fpc.Paid = 0
    AND fp.Valid = 1
    AND fp.AffiliateFirstPositionAccepted = 1
```

### 8.3 Verify payment batch was applied correctly
```sql
SELECT
    fpc.AffiliateID,
    COUNT(*) AS PaidRecords,
    SUM(fpc.Commission) AS TotalPaid
FROM dbo.tblaff_FirstPositions_Commissions fpc WITH (NOLOCK)
WHERE fpc.PaymentID = 5001
    AND fpc.Paid = 1
GROUP BY fpc.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 7.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_SetFirstPositionsAsPaid | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_SetFirstPositionsAsPaid.sql*
