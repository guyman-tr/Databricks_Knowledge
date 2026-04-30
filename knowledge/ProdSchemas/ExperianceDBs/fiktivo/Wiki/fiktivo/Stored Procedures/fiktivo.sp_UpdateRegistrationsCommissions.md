# fiktivo.sp_UpdateRegistrationsCommissions

> Writes a new registration commission record for an affiliate into the registrations commissions table and returns the new record's identity.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT (new commission record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a single affiliate registration commission record into `dbo.tblaff_Registrations_Commissions`. It records the commission earned by an affiliate when a referred customer completes a registration on the platform.

Registration commissions are a top-of-funnel compensation mechanism. They reward affiliates for driving new user sign-ups, regardless of whether those users later deposit or trade. This is common in affiliate programs that use a hybrid model combining registration fees with revenue share or CPA. Without this procedure, registration-based affiliate compensation would not be tracked.

The procedure is called by the commission engine after a registration event is processed. It inserts the commission record with the registration identifier, affiliate details, and commission parameters, then returns SCOPE_IDENTITY().

---

## 2. Business Logic

### 2.1 Registration Commission Record Creation

**What**: Creates a commission record linking a customer registration to an affiliate's earned commission.

**Columns/Parameters Involved**: `@RegistrationID`, `@AffiliateID`, `@Commission`, `@Tier`, `@Paid`, `@PaymentID`, `@SubAffiliateID`

**Rules**:
- One commission record per registration event per affiliate
- RegistrationID links to the specific customer registration record
- Tier reflects the affiliate's commission tier at the time of the event
- Standard paid/unpaid tracking via Paid flag and PaymentID
- SubAffiliateID tracks downstream sub-affiliate if applicable

**Diagram**:
```
Customer Registration Event
    |
    v
sp_UpdateRegistrationsCommissions
    |
    +--> INSERT INTO tblaff_Registrations_Commissions
    |        (RegistrationID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID)
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
| 1 | @RegistrationID (IN) | INT | NO | - | CODE-BACKED | The unique identifier of the registration event that triggered this commission. References the customer registration record. |
| 2 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate who earned this registration commission. References dbo.tblaff_Affiliates. |
| 3 | @Commission (IN) | FLOAT | NO | - | CODE-BACKED | The monetary commission amount earned for this registration event. |
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
| @RegistrationID | dbo.tblaff_Registrations | Implicit | Links the commission to the originating registration event |
| @AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning the commission |
| @PaymentID | dbo.tblaff_PaymentHistory | Implicit | Links to the payment batch when commission is disbursed |
| INSERT target | dbo.tblaff_Registrations_Commissions | Write | Inserts a new registration commission record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateRegistrationsCommissions (procedure)
└── dbo.tblaff_Registrations_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Registrations_Commissions | Table | INSERT target for registration commission records |

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

### 8.1 Insert a new registration commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateRegistrationsCommissions
    @RegistrationID = 55000,
    @AffiliateID = 300,
    @Commission = 5.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = '',
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Verify registration commissions for a specific registration
```sql
SELECT *
FROM dbo.tblaff_Registrations_Commissions WITH (NOLOCK)
WHERE RegistrationID = 55000
ORDER BY ID DESC
```

### 8.3 Review registration commissions with affiliate details
```sql
SELECT rc.*, a.UserName
FROM dbo.tblaff_Registrations_Commissions rc WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateID = rc.AffiliateID
WHERE rc.AffiliateID = 300
ORDER BY rc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateRegistrationsCommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateRegistrationsCommissions.sql*
