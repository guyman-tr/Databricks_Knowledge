# fiktivo.sp_UpdateChargebacksCommissions

> Inserts a new chargeback commission record into tblaff_Chargebacks_Commissions, returning the new record ID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_UpdateChargebacksCommissions is the writer procedure for chargeback commission records in the affiliate system. When the affiliate commission calculation engine determines that a chargeback event should generate a commission adjustment for an affiliate (or sub-affiliate), this procedure is called to persist the record into dbo.tblaff_Chargebacks_Commissions. The name "Update" is a legacy misnomer; the procedure exclusively performs INSERT operations.

This procedure is part of the commission recording layer that sits between the commission calculation engine and the commission tables. Each call records a single commission line for a specific chargeback event, affiliate, tier, and payment status. The returned @NewID allows the calling process to track which commission record was created.

Chargeback commissions typically carry negative values, as they represent commission clawbacks when a customer's payment is reversed. In payment reports, chargeback commissions are aggregated under the "Sales" commission type alongside regular sales and bonus commissions, effectively reducing the total commission payable.

---

## 2. Business Logic

### 2.1 Insert Commission Record

**What**: Inserts a single row into dbo.tblaff_Chargebacks_Commissions with the provided parameter values.

**Columns/Parameters Involved**: ChargebackID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID

**Rules**:
- INSERT INTO dbo.tblaff_Chargebacks_Commissions (ChargebackID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID) VALUES (@ChargebackID, @AffiliateID, @Commission, @Tier, @Paid, @PaymentID, @SubAffiliateID)
- SELECT @NewID = SCOPE_IDENTITY() to capture the auto-generated identity value of the newly inserted row
- No validation or transformation is performed on the input values

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ChargebackID | INT (IN) | NO | - | CODE-BACKED | Foreign key to the chargeback event in dbo.tblaff_Chargebacks. Identifies which chargeback triggered this commission. |
| 2 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate whose commission is being adjusted. May be the direct affiliate or a parent in the sub-affiliate chain. |
| 3 | @Commission | FLOAT (IN) | NO | - | CODE-BACKED | The commission amount for this chargeback event. Typically negative, representing a clawback. |
| 4 | @Tier | INT (IN) | NO | - | CODE-BACKED | Commission tier level. Tier 1 = direct affiliate, Tier 2+ = sub-affiliate tiers in the referral chain. |
| 5 | @Paid | BIT (IN) | NO | - | CODE-BACKED | Payment status flag. 0 = unpaid, 1 = paid. Typically set to 0 on initial insert. |
| 6 | @PaymentID | INT (IN) | NO | - | CODE-BACKED | Reference to the payment batch. Set to 0 or NULL on initial insert, updated when payment is processed. |
| 7 | @SubAffiliateID | INT (IN) | NO | - | CODE-BACKED | The sub-affiliate in the referral chain, if applicable. 0 if this is a direct (Tier 1) commission. |
| 8 | @NewID | INT (OUTPUT) | NO | - | CODE-BACKED | Returns the SCOPE_IDENTITY() value of the newly inserted commission record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_Chargebacks_Commissions | INSERT | Inserts new commission record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateChargebacksCommissions (procedure)
└── dbo.tblaff_Chargebacks_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

1 cross-schema dbo table (tblaff_Chargebacks_Commissions).

### 6.2 Objects That Depend On This

Called by the affiliate commission calculation engine during chargeback commission processing.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Insert a Tier 1 chargeback commission (negative clawback)
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateChargebacksCommissions
    @ChargebackID = 5001,
    @AffiliateID = 100,
    @Commission = -30.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 0,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Insert a Tier 2 sub-affiliate chargeback commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateChargebacksCommissions
    @ChargebackID = 5001,
    @AffiliateID = 200,
    @Commission = -6.00,
    @Tier = 2,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 100,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.3 Insert a chargeback commission with payment reference
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateChargebacksCommissions
    @ChargebackID = 7890,
    @AffiliateID = 300,
    @Commission = -12.50,
    @Tier = 1,
    @Paid = 1,
    @PaymentID = 4001,
    @SubAffiliateID = 0,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 8.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateChargebacksCommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateChargebacksCommissions.sql*
