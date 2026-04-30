# fiktivo.spafw_SetRegistrationsAsPaid

> Marks all unpaid registration commission records as paid for a specific affiliate within a date range, associating them with a payment ID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates: tblaff_Registrations_Commissions.Paid, .PaymentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of the affiliate payment processing workflow. When a payment batch is being finalized for an affiliate, this procedure marks all qualifying registration commission records as paid by setting Paid=1 and stamping them with the PaymentID that covers them.

Registration commissions are earned when an affiliate's referred user completes account registration on the platform. This is typically the earliest event in the customer lifecycle that generates a commission -- preceding first deposits (CPA), first positions, and sales.

It is one of nine "SetXxxAsPaid" procedures -- one for each commission type in the affiliate platform. Only commissions where the associated registration is Valid=1 and AffiliateRegistrationAccepted=1 are eligible for payment marking. The procedure uses SET NOCOUNT ON/OFF and contains commented-out legacy cursor-based logic.

---

## 2. Business Logic

### 2.1 Payment Marking Update

**What**: Updates unpaid registration commission records to mark them as paid.

**Columns/Parameters Involved**: `@AffiliateID`, `@StartDate`, `@EndDate`, `@PaymentID`

**Rules**:
- Updates tblaff_Registrations_Commissions via INNER JOIN with tblaff_Registrations on RegistrationID
- Sets Paid = 1 and PaymentID = @PaymentID
- Date range filter: ORDER_DATE >= CONVERT(DATETIME, @StartDate, 101) AND ORDER_DATE < DATEADD(d, 1, CONVERT(DATETIME, @EndDate, 101))
- End date uses < DATEADD(d, 1, ...) pattern to include the full end date (inclusive end date)
- Filters: AffiliateID = @AffiliateID AND Paid = 0 AND Valid = 1 AND AffiliateRegistrationAccepted = 1
- Date parameters are varchar(12) converted with style 101 (mm/dd/yyyy)
- Uses SET NOCOUNT ON to suppress row count messages

### 2.2 Validation Filters

**What**: Only eligible commissions are marked as paid.

**Rules**:
- Paid = 0: Only unpaid records are updated (prevents double-payment)
- Valid = 1: The registration itself must be marked as valid
- AffiliateRegistrationAccepted = 1: The registration must be accepted by the affiliate system
- All three conditions must be true for a record to be marked as paid

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate ID whose registration commissions are being marked as paid. |
| 2 | @StartDate (IN) | VARCHAR(12) | NO | - | CODE-BACKED | Start of the payment date range. Converted to DATETIME using style 101 (mm/dd/yyyy). |
| 3 | @EndDate (IN) | VARCHAR(12) | NO | - | CODE-BACKED | End of the payment date range (inclusive). Converted to DATETIME using style 101. |
| 4 | @PaymentID (IN) | INT | NO | - | CODE-BACKED | The payment batch identifier to stamp on commission records being marked as paid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE) | dbo.tblaff_Registrations_Commissions | Table write | Target table - sets Paid=1 and PaymentID |
| (JOIN) | dbo.tblaff_Registrations | Table read | Joined for ORDER_DATE, Valid, and AffiliateRegistrationAccepted filters |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_SetRegistrationsAsPaid (procedure)
    ├── dbo.tblaff_Registrations (table)
    └── dbo.tblaff_Registrations_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Registrations | Table | INNER JOIN - provides ORDER_DATE, Valid, AffiliateRegistrationAccepted for filtering |
| dbo.tblaff_Registrations_Commissions | Table | UPDATE target - Paid and PaymentID columns modified |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Legacy Code

The procedure contains commented-out cursor-based logic that iterated row-by-row over qualifying RegistrationIDs. This was replaced with the current set-based UPDATE...FROM...INNER JOIN approach, which is significantly more performant.

---

## 8. Sample Queries

### 8.1 Mark registration commissions as paid for a payment run
```sql
EXEC fiktivo.spafw_SetRegistrationsAsPaid
    @AffiliateID = 100,
    @StartDate = '01/01/2025',
    @EndDate = '01/31/2025',
    @PaymentID = 5001
```

### 8.2 Verify which registration commissions would be affected
```sql
SELECT rc.RegistrationID, rc.AffiliateID, rc.Commission, rc.Paid, r.ORDER_DATE
FROM dbo.tblaff_Registrations_Commissions rc
    INNER JOIN dbo.tblaff_Registrations r ON rc.RegistrationID = r.RegistrationID
WHERE r.ORDER_DATE >= '2025-01-01' AND r.ORDER_DATE < '2025-02-01'
    AND rc.AffiliateID = 100 AND rc.Paid = 0
    AND r.Valid = 1 AND r.AffiliateRegistrationAccepted = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_SetRegistrationsAsPaid | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_SetRegistrationsAsPaid.sql*
