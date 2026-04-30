# fiktivo.sp_UpdateBonusesCommissions

> Inserts a new bonus commission record into tblaff_Bonuses_Commissions, returning the new record ID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_UpdateBonusesCommissions is the writer procedure for bonus commission records in the affiliate system. When the affiliate commission calculation engine determines that a bonus event should generate a commission for an affiliate (or sub-affiliate), this procedure is called to persist the commission record into dbo.tblaff_Bonuses_Commissions. The name "Update" is a legacy misnomer; the procedure exclusively performs INSERT operations.

This procedure is part of the commission recording layer that sits between the commission calculation engine and the commission tables. Each call records a single commission line for a specific bonus event, affiliate, tier, and payment status. The returned @NewID allows the calling process to track which commission record was created.

Bonus commissions arise when a customer receives a bonus credit, and the affiliate who referred that customer earns a commission on the bonus amount. These are typically aggregated under the "Sales" commission type in payment reports, alongside regular sales and chargeback commissions.

---

## 2. Business Logic

### 2.1 Insert Commission Record

**What**: Inserts a single row into dbo.tblaff_Bonuses_Commissions with the provided parameter values.

**Columns/Parameters Involved**: BonusID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID

**Rules**:
- INSERT INTO dbo.tblaff_Bonuses_Commissions (BonusID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID) VALUES (@BonusID, @AffiliateID, @Commission, @Tier, @Paid, @PaymentID, @SubAffiliateID)
- SELECT @NewID = SCOPE_IDENTITY() to capture the auto-generated identity value of the newly inserted row
- No validation or transformation is performed on the input values

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BonusID | INT (IN) | NO | - | CODE-BACKED | Foreign key to the bonus event in dbo.tblaff_Bonuses. Identifies which bonus triggered this commission. |
| 2 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate earning this commission. May be the direct affiliate or a parent in the sub-affiliate chain. |
| 3 | @Commission | FLOAT (IN) | NO | - | CODE-BACKED | The commission amount to record for this bonus event. |
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
| - | dbo.tblaff_Bonuses_Commissions | INSERT | Inserts new commission record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateBonusesCommissions (procedure)
└── dbo.tblaff_Bonuses_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

1 cross-schema dbo table (tblaff_Bonuses_Commissions).

### 6.2 Objects That Depend On This

Called by the affiliate commission calculation engine during bonus commission processing.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Insert a new Tier 1 bonus commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateBonusesCommissions
    @BonusID = 12345,
    @AffiliateID = 100,
    @Commission = 25.50,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 0,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Insert a Tier 2 sub-affiliate bonus commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateBonusesCommissions
    @BonusID = 12345,
    @AffiliateID = 200,
    @Commission = 5.10,
    @Tier = 2,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 100,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.3 Insert a pre-paid bonus commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateBonusesCommissions
    @BonusID = 67890,
    @AffiliateID = 300,
    @Commission = 15.00,
    @Tier = 1,
    @Paid = 1,
    @PaymentID = 5001,
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
*Object: fiktivo.sp_UpdateBonusesCommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateBonusesCommissions.sql*
