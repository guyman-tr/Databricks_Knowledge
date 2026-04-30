# fiktivo.sp_UpdateCPACommissions

> Inserts a new CPA commission record into tblaff_CPA_Commissions, returning the new record ID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_UpdateCPACommissions is the writer procedure for CPA (Cost Per Acquisition) commission records in the affiliate system. When the affiliate commission calculation engine determines that a qualifying deposit event should generate a CPA commission for an affiliate (or sub-affiliate), this procedure is called to persist the commission record into dbo.tblaff_CPA_Commissions. The name "Update" is a legacy misnomer; the procedure exclusively performs INSERT operations.

This procedure is part of the commission recording layer that sits between the commission calculation engine and the commission tables. Each call records a single commission line for a specific deposit event, affiliate, tier, affiliate type, and payment status. The returned @NewID allows the calling process to track which commission record was created.

CPA commissions are triggered by a customer's first deposit and represent a one-time acquisition payment to the affiliate. Unlike revenue-share models that pay ongoing commissions on trading activity, CPA pays a fixed amount per qualifying deposit. The @AffiliateTypeID parameter allows differentiation between CPA sub-types or affiliate program tiers.

---

## 2. Business Logic

### 2.1 Insert Commission Record

**What**: Inserts a single row into dbo.tblaff_CPA_Commissions with the provided parameter values, including the optional AffiliateTypeID.

**Columns/Parameters Involved**: DepositID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID, AffiliateTypeID

**Rules**:
- INSERT INTO dbo.tblaff_CPA_Commissions (DepositID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID, AffiliateTypeID) VALUES (@DepositID, @AffiliateID, @Commission, @Tier, @Paid, @PaymentID, @SubAffiliateID, @AffiliateTypeID)
- SELECT @NewID = SCOPE_IDENTITY() to capture the auto-generated identity value of the newly inserted row
- @AffiliateTypeID defaults to NULL if not provided
- No additional validation or transformation is performed on the input values

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT (IN) | NO | - | CODE-BACKED | Foreign key to the deposit/CPA event in dbo.tblaff_CPA. Identifies which deposit triggered this CPA commission. |
| 2 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate earning this commission. May be the direct affiliate or a parent in the sub-affiliate chain. |
| 3 | @Commission | FLOAT (IN) | NO | - | CODE-BACKED | The CPA commission amount to record for this deposit event. Typically a fixed amount per acquisition. |
| 4 | @Tier | INT (IN) | NO | - | CODE-BACKED | Commission tier level. Tier 1 = direct affiliate, Tier 2+ = sub-affiliate tiers in the referral chain. |
| 5 | @Paid | BIT (IN) | NO | - | CODE-BACKED | Payment status flag. 0 = unpaid, 1 = paid. Typically set to 0 on initial insert. |
| 6 | @PaymentID | INT (IN) | NO | - | CODE-BACKED | Reference to the payment batch. Set to 0 or NULL on initial insert, updated when payment is processed. |
| 7 | @SubAffiliateID | INT (IN) | NO | - | CODE-BACKED | The sub-affiliate in the referral chain, if applicable. 0 if this is a direct (Tier 1) commission. |
| 8 | @AffiliateTypeID | INT (IN) | YES | NULL | CODE-BACKED | Optional affiliate type identifier. Allows differentiation between CPA program types or affiliate tiers. NULL if not applicable. |
| 9 | @NewID | INT (OUTPUT) | NO | - | CODE-BACKED | Returns the SCOPE_IDENTITY() value of the newly inserted commission record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_CPA_Commissions | INSERT | Inserts new commission record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateCPACommissions (procedure)
└── dbo.tblaff_CPA_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

1 cross-schema dbo table (tblaff_CPA_Commissions).

### 6.2 Objects That Depend On This

Called by the affiliate commission calculation engine during CPA commission processing.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Insert a Tier 1 CPA commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateCPACommissions
    @DepositID = 45001,
    @AffiliateID = 100,
    @Commission = 200.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 0,
    @AffiliateTypeID = NULL,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Insert a CPA commission with affiliate type
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateCPACommissions
    @DepositID = 45001,
    @AffiliateID = 100,
    @Commission = 350.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 0,
    @AffiliateTypeID = 3,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.3 Insert a Tier 2 sub-affiliate CPA commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateCPACommissions
    @DepositID = 45001,
    @AffiliateID = 200,
    @Commission = 50.00,
    @Tier = 2,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 100,
    @AffiliateTypeID = NULL,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 8.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateCPACommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateCPACommissions.sql*
