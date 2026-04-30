# fiktivo.spafw_SetBonusesAsPaid

> Marks all unpaid bonus commission records as paid for a specific affiliate within a date range, associating them with a payment ID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates: tblaff_Bonuses_Commissions.Paid, .PaymentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of the affiliate payment processing workflow. When a payment batch is being finalized for an affiliate, this procedure marks all qualifying bonus commission records as paid by setting Paid=1 and stamping them with the PaymentID that covers them.

It is one of nine "SetXxxAsPaid" procedures -- one for each commission type in the affiliate platform. Together they ensure that all commission records included in a payment are flagged so they are not double-paid in future payment runs.

Only commissions where the associated bonus is Valid=1 and AffiliateBonusAccepted=1 are eligible for payment marking. The procedure contains commented-out legacy cursor-based logic that was replaced with a more efficient set-based UPDATE with INNER JOIN.

---

## 2. Business Logic

### 2.1 Payment Marking Update

**What**: Updates unpaid bonus commission records to mark them as paid.

**Columns/Parameters Involved**: `@AffiliateID`, `@StartDate`, `@EndDate`, `@PaymentID`

**Rules**:
- Updates tblaff_Bonuses_Commissions via INNER JOIN with tblaff_Bonuses on BonusID
- Sets Paid = 1 and PaymentID = @PaymentID
- Date range filter: ORDER_DATE >= CONVERT(DATETIME, @StartDate, 101) AND ORDER_DATE < DATEADD(d, 1, CONVERT(DATETIME, @EndDate, 101))
- End date uses < DATEADD(d, 1, ...) pattern to include the full end date (inclusive end date)
- Filters: AffiliateID = @AffiliateID AND Paid = 0 AND Valid = 1 AND AffiliateBonusAccepted = 1
- Date parameters are varchar(12) converted with style 101 (mm/dd/yyyy)

### 2.2 Validation Filters

**What**: Only eligible commissions are marked as paid.

**Rules**:
- Paid = 0: Only unpaid records are updated (prevents double-payment)
- Valid = 1: The bonus itself must be marked as valid
- AffiliateBonusAccepted = 1: The bonus must be accepted by the affiliate system
- All three conditions must be true for a record to be marked as paid

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate ID whose bonus commissions are being marked as paid. |
| 2 | @StartDate (IN) | VARCHAR(12) | NO | - | CODE-BACKED | Start of the payment date range. Converted to DATETIME using style 101 (mm/dd/yyyy). |
| 3 | @EndDate (IN) | VARCHAR(12) | NO | - | CODE-BACKED | End of the payment date range (inclusive). Converted to DATETIME using style 101. |
| 4 | @PaymentID (IN) | INT | NO | - | CODE-BACKED | The payment batch identifier to stamp on commission records being marked as paid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE) | dbo.tblaff_Bonuses_Commissions | Table write | Target table - sets Paid=1 and PaymentID |
| (JOIN) | dbo.tblaff_Bonuses | Table read | Joined for ORDER_DATE, Valid, and AffiliateBonusAccepted filters |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_SetBonusesAsPaid (procedure)
    ├── dbo.tblaff_Bonuses (table)
    └── dbo.tblaff_Bonuses_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Bonuses | Table | INNER JOIN - provides ORDER_DATE, Valid, AffiliateBonusAccepted for filtering |
| dbo.tblaff_Bonuses_Commissions | Table | UPDATE target - Paid and PaymentID columns modified |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Legacy Code

The procedure contains commented-out cursor-based logic that iterated row-by-row over qualifying BonusIDs. This was replaced with the current set-based UPDATE...FROM...INNER JOIN approach, which is significantly more performant.

---

## 8. Sample Queries

### 8.1 Mark bonus commissions as paid for a payment run
```sql
EXEC fiktivo.spafw_SetBonusesAsPaid
    @AffiliateID = 100,
    @StartDate = '01/01/2025',
    @EndDate = '01/31/2025',
    @PaymentID = 5001
```

### 8.2 Verify which bonus commissions would be affected
```sql
SELECT bc.BonusID, bc.AffiliateID, bc.Commission, bc.Paid, b.ORDER_DATE
FROM dbo.tblaff_Bonuses_Commissions bc
    INNER JOIN dbo.tblaff_Bonuses b ON bc.BonusID = b.BonusID
WHERE b.ORDER_DATE >= '2025-01-01' AND b.ORDER_DATE < '2025-02-01'
    AND bc.AffiliateID = 100 AND bc.Paid = 0
    AND b.Valid = 1 AND b.AffiliateBonusAccepted = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_SetBonusesAsPaid | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_SetBonusesAsPaid.sql*
