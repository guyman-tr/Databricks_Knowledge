# fiktivo.spafw_SetLeadsAsPaid

> Marks all unpaid lead commission records as paid for a specific affiliate within a date range, associating them with a payment ID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates: tblaff_Leads_Commissions.Paid, .PaymentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of the affiliate payment processing workflow. When a payment batch is being finalized for an affiliate, this procedure marks all qualifying lead commission records as paid by setting Paid=1 and stamping them with the PaymentID that covers them.

Lead commissions are earned when an affiliate generates a qualifying lead -- typically a prospective customer who completes a registration or initial engagement step. This procedure ensures those commissions are properly flagged once included in a payment.

It is one of nine "SetXxxAsPaid" procedures -- one for each commission type in the affiliate platform. Only commissions where the associated lead is Valid=1 and AffiliateSaleAccepted=1 are eligible for payment marking. Note that leads use the "AffiliateSaleAccepted" flag (shared naming with sales) rather than a dedicated "AffiliateLeadAccepted" flag. The procedure uses SET NOCOUNT ON/OFF and contains commented-out legacy cursor-based logic.

---

## 2. Business Logic

### 2.1 Payment Marking Update

**What**: Updates unpaid lead commission records to mark them as paid.

**Columns/Parameters Involved**: `@AffiliateID`, `@StartDate`, `@EndDate`, `@PaymentID`

**Rules**:
- Updates tblaff_Leads_Commissions via INNER JOIN with tblaff_Leads on LeadID
- Sets Paid = 1 and PaymentID = @PaymentID
- Date range filter: ORDER_DATE >= CONVERT(DATETIME, @StartDate, 101) AND ORDER_DATE < DATEADD(d, 1, CONVERT(DATETIME, @EndDate, 101))
- End date uses < DATEADD(d, 1, ...) pattern to include the full end date (inclusive end date)
- Filters: AffiliateID = @AffiliateID AND Paid = 0 AND Valid = 1 AND AffiliateSaleAccepted = 1
- Date parameters are varchar(12) converted with style 101 (mm/dd/yyyy)
- Uses SET NOCOUNT ON to suppress row count messages

### 2.2 Validation Filters

**What**: Only eligible commissions are marked as paid.

**Rules**:
- Paid = 0: Only unpaid records are updated (prevents double-payment)
- Valid = 1: The lead itself must be marked as valid
- AffiliateSaleAccepted = 1: The lead must be accepted (uses sale-accepted flag naming convention)
- All three conditions must be true for a record to be marked as paid

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate ID whose lead commissions are being marked as paid. |
| 2 | @StartDate (IN) | VARCHAR(12) | NO | - | CODE-BACKED | Start of the payment date range. Converted to DATETIME using style 101 (mm/dd/yyyy). |
| 3 | @EndDate (IN) | VARCHAR(12) | NO | - | CODE-BACKED | End of the payment date range (inclusive). Converted to DATETIME using style 101. |
| 4 | @PaymentID (IN) | INT | NO | - | CODE-BACKED | The payment batch identifier to stamp on commission records being marked as paid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE) | dbo.tblaff_Leads_Commissions | Table write | Target table - sets Paid=1 and PaymentID |
| (JOIN) | dbo.tblaff_Leads | Table read | Joined for ORDER_DATE, Valid, and AffiliateSaleAccepted filters |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_SetLeadsAsPaid (procedure)
    ├── dbo.tblaff_Leads (table)
    └── dbo.tblaff_Leads_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads | Table | INNER JOIN - provides ORDER_DATE, Valid, AffiliateSaleAccepted for filtering |
| dbo.tblaff_Leads_Commissions | Table | UPDATE target - Paid and PaymentID columns modified |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Legacy Code

The procedure contains commented-out cursor-based logic that iterated row-by-row over qualifying LeadIDs. This was replaced with the current set-based UPDATE...FROM...INNER JOIN approach, which is significantly more performant.

### 7.4 Naming Anomaly

The acceptance flag on tblaff_Leads is named `AffiliateSaleAccepted` rather than `AffiliateLeadAccepted`. This suggests the leads table may have been derived from the sales table schema, or that "sale" is used as a generic term for affiliate-attributed events in the leads context.

---

## 8. Sample Queries

### 8.1 Mark lead commissions as paid for a payment run
```sql
EXEC fiktivo.spafw_SetLeadsAsPaid
    @AffiliateID = 100,
    @StartDate = '01/01/2025',
    @EndDate = '01/31/2025',
    @PaymentID = 5001
```

### 8.2 Verify which lead commissions would be affected
```sql
SELECT lc.LeadID, lc.AffiliateID, lc.Commission, lc.Paid, l.ORDER_DATE
FROM dbo.tblaff_Leads_Commissions lc
    INNER JOIN dbo.tblaff_Leads l ON lc.LeadID = l.LeadID
WHERE l.ORDER_DATE >= '2025-01-01' AND l.ORDER_DATE < '2025-02-01'
    AND lc.AffiliateID = 100 AND lc.Paid = 0
    AND l.Valid = 1 AND l.AffiliateSaleAccepted = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_SetLeadsAsPaid | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_SetLeadsAsPaid.sql*
