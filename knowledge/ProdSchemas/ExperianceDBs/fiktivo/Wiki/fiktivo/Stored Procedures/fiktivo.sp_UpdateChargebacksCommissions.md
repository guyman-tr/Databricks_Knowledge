# fiktivo.sp_UpdateChargebacksCommissions

> Writes a new chargeback commission record for an affiliate into the chargebacks commissions table and returns the new record's identity.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT (new commission record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a single affiliate chargeback commission record into `dbo.tblaff_Chargebacks_Commissions`. It records the commission adjustment (typically a deduction) applied to an affiliate when a chargeback event occurs against one of their referred customers.

Chargebacks represent a reversal of a customer payment, and the affiliate commission system must account for these by creating a corresponding commission record. This is typically a negative commission or a clawback entry. Without this procedure, chargeback-related commission adjustments would not be tracked in the affiliate compensation ledger.

The procedure is called by the commission engine when a chargeback is processed. It inserts the record with the chargeback reference, affiliate details, and commission parameters, then returns the SCOPE_IDENTITY() of the new row so the calling process can confirm and track the adjustment.

---

## 2. Business Logic

### 2.1 Chargeback Commission Record Creation

**What**: Creates a commission record linking a chargeback event to an affiliate's commission adjustment.

**Columns/Parameters Involved**: `@ChargebackID`, `@AffiliateID`, `@Commission`, `@Tier`, `@Paid`, `@PaymentID`, `@SubAffiliateID`

**Rules**:
- One commission record is created per chargeback per affiliate
- The Commission value is typically negative, representing a clawback of previously earned commission
- Tier reflects the affiliate's commission tier at the time of the chargeback
- Paid=0 means the adjustment is pending; Paid=1 means it has been applied in a payment batch
- SubAffiliateID tracks sub-affiliate involvement if applicable

**Diagram**:
```
Chargeback Event
    |
    v
sp_UpdateChargebacksCommissions
    |
    +--> INSERT INTO tblaff_Chargebacks_Commissions
    |        (ChargebackID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID)
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
| 1 | @ChargebackID (IN) | INT | NO | - | CODE-BACKED | The unique identifier of the chargeback event that triggered this commission adjustment. References the chargeback record in the platform. |
| 2 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate affected by this chargeback commission. References dbo.tblaff_Affiliates. |
| 3 | @Commission (IN) | FLOAT | NO | - | CODE-BACKED | The commission adjustment amount. Typically negative for chargebacks, representing a clawback of previously earned commission. |
| 4 | @Tier (IN) | INT | NO | - | CODE-BACKED | The affiliate tier level at the time this commission adjustment was calculated. |
| 5 | @Paid (IN) | BIT | NO | - | CODE-BACKED | Payment status: 1 = adjustment has been applied in a payment batch, 0 = adjustment is pending. |
| 6 | @PaymentID (IN) | INT | NO | - | CODE-BACKED | The payment batch identifier. Links to dbo.tblaff_PaymentHistory when Paid=1. Zero or default when unapplied. |
| 7 | @SubAffiliateID (IN) | NVARCHAR(1024) | NO | '' | CODE-BACKED | The sub-affiliate tracking identifier. Empty string when no sub-affiliate involvement. |
| 8 | @NewID (OUT) | INT | YES | - | CODE-BACKED | The SCOPE_IDENTITY() value of the newly inserted commission record. Returned to confirm creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ChargebackID | dbo.tblaff_Chargebacks | Implicit | Links the commission adjustment to the originating chargeback event |
| @AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate affected by the chargeback |
| @PaymentID | dbo.tblaff_PaymentHistory | Implicit | Links to the payment batch when the adjustment is applied |
| INSERT target | dbo.tblaff_Chargebacks_Commissions | Write | Inserts a new commission adjustment record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateChargebacksCommissions (procedure)
└── dbo.tblaff_Chargebacks_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Chargebacks_Commissions | Table | INSERT target for chargeback commission records |

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

### 8.1 Insert a new chargeback commission adjustment
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateChargebacksCommissions
    @ChargebackID = 5678,
    @AffiliateID = 100,
    @Commission = -15.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = '',
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Verify chargeback commissions for a specific chargeback
```sql
SELECT *
FROM dbo.tblaff_Chargebacks_Commissions WITH (NOLOCK)
WHERE ChargebackID = 5678
ORDER BY ID DESC
```

### 8.3 Review all chargeback commissions for an affiliate with affiliate name
```sql
SELECT cc.*, a.UserName
FROM dbo.tblaff_Chargebacks_Commissions cc WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateID = cc.AffiliateID
WHERE cc.AffiliateID = 100
ORDER BY cc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateChargebacksCommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateChargebacksCommissions.sql*
