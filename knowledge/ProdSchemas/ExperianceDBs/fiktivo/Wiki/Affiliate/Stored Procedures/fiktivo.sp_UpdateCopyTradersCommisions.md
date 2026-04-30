# fiktivo.sp_UpdateCopyTradersCommisions

> Inserts a new copy trader commission record into tblaff_CopyTraders_Commissions, returning the new record ID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_UpdateCopyTradersCommisions (note: the stored procedure name contains a typo -- "Commisions" instead of "Commissions") is the writer procedure for copy trader commission records in the affiliate system. When the affiliate commission calculation engine determines that a copy trading event should generate a commission for an affiliate (or sub-affiliate), this procedure is called to persist the commission record into dbo.tblaff_CopyTraders_Commissions. The name "Update" is a legacy misnomer; the procedure exclusively performs INSERT operations.

This procedure is part of the commission recording layer that sits between the commission calculation engine and the commission tables. Each call records a single commission line for a specific copy trader event, affiliate, tier, and payment status. The returned @NewID allows the calling process to track which commission record was created.

Copy trader commissions arise from the social trading feature where customers copy the trades of other traders. When a referred customer participates in copy trading activity, the referring affiliate earns a commission. These commissions appear as the "Copys" type in payment aggregation reports.

---

## 2. Business Logic

### 2.1 Insert Commission Record

**What**: Inserts a single row into dbo.tblaff_CopyTraders_Commissions with the provided parameter values.

**Columns/Parameters Involved**: CopyTraderID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID

**Rules**:
- INSERT INTO dbo.tblaff_CopyTraders_Commissions (CopyTraderID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID) VALUES (@CopyTraderID, @AffiliateID, @Commission, @Tier, @Paid, @PaymentID, @SubAffiliateID)
- SELECT @NewID = SCOPE_IDENTITY() to capture the auto-generated identity value of the newly inserted row
- No validation or transformation is performed on the input values

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CopyTraderID | INT (IN) | NO | - | CODE-BACKED | Foreign key to the copy trader event in dbo.tblaff_CopyTraders. Identifies which copy trading activity triggered this commission. |
| 2 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate earning this commission. May be the direct affiliate or a parent in the sub-affiliate chain. |
| 3 | @Commission | FLOAT (IN) | NO | - | CODE-BACKED | The commission amount to record for this copy trader event. |
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
| - | dbo.tblaff_CopyTraders_Commissions | INSERT | Inserts new commission record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateCopyTradersCommisions (procedure)
└── dbo.tblaff_CopyTraders_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

1 cross-schema dbo table (tblaff_CopyTraders_Commissions).

### 6.2 Objects That Depend On This

Called by the affiliate commission calculation engine during copy trader commission processing.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

### 7.3 Notes

- **Author**: Guy, 01/12/2011
- The procedure name contains a known typo: "Commisions" (single 's') instead of "Commissions" (double 's'). This typo is preserved in the actual SQL Server object name and must be used exactly when calling the procedure.

---

## 8. Sample Queries

### 8.1 Insert a Tier 1 copy trader commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateCopyTradersCommisions
    @CopyTraderID = 8001,
    @AffiliateID = 100,
    @Commission = 18.75,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 0,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Insert a Tier 2 sub-affiliate copy trader commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateCopyTradersCommisions
    @CopyTraderID = 8001,
    @AffiliateID = 200,
    @Commission = 3.75,
    @Tier = 2,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 100,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.3 Insert a copy trader commission with payment reference
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateCopyTradersCommisions
    @CopyTraderID = 9500,
    @AffiliateID = 300,
    @Commission = 22.00,
    @Tier = 1,
    @Paid = 1,
    @PaymentID = 6001,
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
*Object: fiktivo.sp_UpdateCopyTradersCommisions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateCopyTradersCommisions.sql*
