# fiktivo.sp_UpdateLeadsCommissions

> Writes a new lead commission record for an affiliate into the leads commissions table and returns the new record's identity.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT (new commission record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a single affiliate lead commission record into `dbo.tblaff_Leads_Commissions`. A "lead" typically represents a customer who has registered but may not yet have deposited or traded. Lead commissions compensate affiliates for driving registrations and potential customer acquisitions.

Lead-based commissions are a top-of-funnel metric in the affiliate program. They incentivize affiliates to drive traffic and registrations, even before those registrations convert to depositing or trading customers. Without this procedure, affiliates would not receive credit for lead generation activities.

The procedure is called by the commission engine after a lead event is processed. It inserts the commission record with the lead identifier, affiliate details, and commission parameters, then returns SCOPE_IDENTITY().

---

## 2. Business Logic

### 2.1 Lead Commission Record Creation

**What**: Creates a commission record linking a lead (registration) event to an affiliate's earned commission.

**Columns/Parameters Involved**: `@LeadID`, `@AffiliateID`, `@Commission`, `@Tier`, `@Paid`, `@PaymentID`, `@SubAffiliateID`

**Rules**:
- One commission record per lead event per affiliate
- The LeadID links to the specific lead/registration record
- Tier reflects the affiliate's commission tier at the time of the event
- Standard paid/unpaid tracking via Paid flag and PaymentID
- SubAffiliateID tracks downstream sub-affiliate if applicable

**Diagram**:
```
Lead/Registration Event
    |
    v
sp_UpdateLeadsCommissions
    |
    +--> INSERT INTO tblaff_Leads_Commissions
    |        (LeadID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID)
    |
    +--> SCOPE_IDENTITY() --> @NewID OUTPUT
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LeadID (IN) | INT | NO | - | CODE-BACKED | The unique identifier of the lead event that triggered this commission. References the lead/registration record. |
| 2 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate who earned this lead commission. References dbo.tblaff_Affiliates. |
| 3 | @Commission (IN) | FLOAT | NO | - | CODE-BACKED | The monetary commission amount earned for this lead. Determined by the affiliate's lead commission rate. |
| 4 | @Tier (IN) | INT | NO | - | CODE-BACKED | The affiliate tier level at the time this commission was calculated. |
| 5 | @Paid (IN) | BIT | NO | - | CODE-BACKED | Payment status: 1 = commission has been paid, 0 = commission is pending payment. |
| 6 | @PaymentID (IN) | INT | NO | - | CODE-BACKED | The payment batch identifier. Links to dbo.tblaff_PaymentHistory when Paid=1. Zero when unpaid. |
| 7 | @SubAffiliateID (IN) | NVARCHAR(1024) | NO | '' | CODE-BACKED | The sub-affiliate tracking identifier. Empty string when no sub-affiliate involvement. |
| 8 | @NewID (OUT) | INT | YES | - | CODE-BACKED | The SCOPE_IDENTITY() value of the newly inserted commission record. Returned to confirm creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LeadID | dbo.tblaff_Leads | Implicit | Links the commission to the originating lead/registration event |
| @AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning the commission |
| @PaymentID | dbo.tblaff_PaymentHistory | Implicit | Links to the payment batch when commission is disbursed |
| INSERT target | dbo.tblaff_Leads_Commissions | Write | Inserts a new lead commission record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateLeadsCommissions (procedure)
└── dbo.tblaff_Leads_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads_Commissions | Table | INSERT target for lead commission records |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Insert a new lead commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateLeadsCommissions
    @LeadID = 30100,
    @AffiliateID = 100,
    @Commission = 10.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = '',
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Verify lead commissions for a specific lead
```sql
SELECT *
FROM dbo.tblaff_Leads_Commissions WITH (NOLOCK)
WHERE LeadID = 30100
ORDER BY ID DESC
```

### 8.3 Review unpaid lead commissions for an affiliate with details
```sql
SELECT lc.*, a.UserName
FROM dbo.tblaff_Leads_Commissions lc WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateID = lc.AffiliateID
WHERE lc.AffiliateID = 100 AND lc.Paid = 0
ORDER BY lc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateLeadsCommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateLeadsCommissions.sql*
