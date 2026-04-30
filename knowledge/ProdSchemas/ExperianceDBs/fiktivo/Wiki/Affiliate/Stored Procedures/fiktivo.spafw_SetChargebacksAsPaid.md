# fiktivo.spafw_SetChargebacksAsPaid

> Marks chargeback commissions as paid for a specific affiliate within a date range by setting Paid=1 and recording the PaymentID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Rows affected (UPDATE) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

spafw_SetChargebacksAsPaid is part of the payment processing pipeline in the affiliate commission system. When a payment batch is finalized for an affiliate, this procedure is called to mark all eligible chargeback commissions within the specified date range as paid. This prevents the same commissions from being included in future payment runs.

The procedure targets the dbo.tblaff_Chargebacks_Commissions table, updating records that meet all eligibility criteria: the commission must be unpaid (Paid=0), valid (Valid=1), and accepted (AffiliateChargebackAccepted=1). The PaymentID is stamped on each updated record, providing a full audit trail linking commission records to their payment batch.

Chargeback commissions are typically negative adjustments -- when a customer initiates a chargeback, the affiliate's previously earned commission on that customer's activity may be clawed back. Marking these as paid ensures they are included in the net payment calculation for the affiliate.

---

## 2. Business Logic

### 2.1 Mark Chargeback Commissions as Paid

**What**: Updates unpaid, valid, accepted chargeback commissions for the specified affiliate and date range, setting them to paid status.

**Columns/Parameters Involved**: Paid, PaymentID, AffiliateID, ORDER_DATE, Valid, AffiliateChargebackAccepted

**Rules**:
- UPDATE dbo.tblaff_Chargebacks_Commissions SET Paid = 1, PaymentID = @PaymentID
- FROM dbo.tblaff_Chargebacks INNER JOIN dbo.tblaff_Chargebacks_Commissions ON ChargebackID
- WHERE AffiliateID = @AffiliateID
- AND ORDER_DATE >= @StartDate AND ORDER_DATE <= @EndDate (inclusive date range)
- AND Paid = 0 (only unpaid records)
- AND Valid = 1 (only valid records)
- AND AffiliateChargebackAccepted = 1 (only accepted chargeback events)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate whose chargeback commissions should be marked as paid. |
| 2 | @StartDate | VARCHAR(12) (IN) | NO | - | CODE-BACKED | Start date of the payment period (inclusive). Compared against ORDER_DATE in tblaff_Chargebacks. |
| 3 | @EndDate | VARCHAR(12) (IN) | NO | - | CODE-BACKED | End date of the payment period (inclusive). Compared against ORDER_DATE in tblaff_Chargebacks. |
| 4 | @PaymentID | INT (IN) | NO | - | CODE-BACKED | The payment batch identifier to stamp on each commission record for audit trail purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_Chargebacks | JOIN | Joins to access ORDER_DATE, Valid, and AffiliateChargebackAccepted for filtering |
| - | dbo.tblaff_Chargebacks_Commissions | UPDATE | Updates Paid and PaymentID on eligible commission records |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_SetChargebacksAsPaid (procedure)
├── dbo.tblaff_Chargebacks (table, cross-schema)
└── dbo.tblaff_Chargebacks_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

2 cross-schema dbo tables (tblaff_Chargebacks, tblaff_Chargebacks_Commissions).

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

### 8.1 Mark chargeback commissions as paid for affiliate 100 in March 2026
```sql
EXEC fiktivo.spafw_SetChargebacksAsPaid
    @AffiliateID = 100,
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-31',
    @PaymentID = 5002
```

### 8.2 Preview which chargeback commissions would be marked as paid
```sql
SELECT
    cc.ChargebackCommissionID,
    cc.AffiliateID,
    cc.Commission,
    c.ORDER_DATE,
    cc.Paid,
    cc.PaymentID
FROM dbo.tblaff_Chargebacks c WITH (NOLOCK)
INNER JOIN dbo.tblaff_Chargebacks_Commissions cc WITH (NOLOCK)
    ON c.ChargebackID = cc.ChargebackID
WHERE cc.AffiliateID = 100
    AND c.ORDER_DATE >= '2026-03-01'
    AND c.ORDER_DATE <= '2026-03-31'
    AND cc.Paid = 0
    AND c.Valid = 1
    AND c.AffiliateChargebackAccepted = 1
```

### 8.3 Verify payment batch was applied correctly
```sql
SELECT
    cc.AffiliateID,
    COUNT(*) AS PaidRecords,
    SUM(cc.Commission) AS TotalPaid
FROM dbo.tblaff_Chargebacks_Commissions cc WITH (NOLOCK)
WHERE cc.PaymentID = 5002
    AND cc.Paid = 1
GROUP BY cc.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 7.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_SetChargebacksAsPaid | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_SetChargebacksAsPaid.sql*
