# fiktivo.sp_UpdateSalesCommissions

> Inserts or updates a sales commission record in tblaff_Sales_Commissions, returning the record ID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RetVal OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_UpdateSalesCommissions is the writer procedure for sales commission records in the affiliate system. Unlike the other commission INSERT procedures which only create new records, this procedure supports both INSERT and UPDATE operations controlled by the @InsertNewRecord parameter. When the affiliate commission calculation engine determines that a sales event should generate or adjust a commission for an affiliate (or sub-affiliate), this procedure is called to persist the record into dbo.tblaff_Sales_Commissions.

This procedure is the most complex of the commission writer procedures due to its dual INSERT/UPDATE behavior and its handling of the UsedBonusCommission field. When inserting a new record, it behaves like the other commission INSERT procedures. When updating an existing record, it accumulates the Commission and UsedBonusCommission values onto the existing row rather than replacing them, enabling incremental commission adjustments.

Sales commissions are the primary revenue-share commission type, generated from customer trading activity (spreads, fees, P&L). They represent the bulk of affiliate commission payments and appear as the "Sales" type in payment aggregation reports. The UsedBonusCommission tracks the portion of commission attributable to bonus-funded trading, which may be subject to different payout rules.

---

## 2. Business Logic

### 2.1 Insert vs Update Logic

**What**: The @InsertNewRecord parameter determines whether a new commission row is created or an existing row is updated.

**Columns/Parameters Involved**: @InsertNewRecord, @SaleID, @AffiliateID, @Commission, @Tier, @Paid, @PaymentID, @SubAffiliateID, @UsedBonusCommission

**Rules**:
- **If @InsertNewRecord = 1 (INSERT)**:
  - INSERT INTO dbo.tblaff_Sales_Commissions (SaleID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID, UsedBonusCommission) VALUES (@SaleID, @AffiliateID, @Commission, @Tier, @Paid, @PaymentID, @SubAffiliateID, @UsedBonusCommission / 100)
  - SELECT @RetVal = SCOPE_IDENTITY()
- **If @InsertNewRecord = 0 (UPDATE)**:
  - UPDATE dbo.tblaff_Sales_Commissions SET Commission = Commission + @Commission, UsedBonusCommission = UsedBonusCommission + (@UsedBonusCommission / 100) WHERE SaleID = @SaleID AND AffiliateID = @AffiliateID AND Tier = @Tier
  - Accumulates values onto the existing record rather than replacing them

### 2.2 UsedBonusCommission Division

**What**: The @UsedBonusCommission value is divided by 100 before being stored.

**Columns/Parameters Involved**: @UsedBonusCommission

**Rules**:
- The input @UsedBonusCommission is in cents (or a scaled integer representation)
- Division by 100 converts it to dollar-equivalent units before storage
- This conversion applies in both INSERT and UPDATE paths

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SaleID | INT (IN) | NO | - | CODE-BACKED | Foreign key to the sales event in dbo.tblaff_Sales. Identifies which sale triggered this commission. Used as a match key in UPDATE mode. |
| 2 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate earning this commission. Used as a match key in UPDATE mode alongside SaleID and Tier. |
| 3 | @Commission | FLOAT (IN) | NO | - | CODE-BACKED | The commission amount. In INSERT mode, stored directly. In UPDATE mode, added to the existing Commission value. |
| 4 | @Tier | INT (IN) | NO | - | CODE-BACKED | Commission tier level. Tier 1 = direct affiliate, Tier 2+ = sub-affiliate tiers. Used as a match key in UPDATE mode. |
| 5 | @Paid | BIT (IN) | NO | - | CODE-BACKED | Payment status flag. 0 = unpaid, 1 = paid. Only used in INSERT mode. |
| 6 | @PaymentID | INT (IN) | NO | - | CODE-BACKED | Reference to the payment batch. Only used in INSERT mode. |
| 7 | @SubAffiliateID | INT (IN) | NO | - | CODE-BACKED | The sub-affiliate in the referral chain, if applicable. Only used in INSERT mode. |
| 8 | @InsertNewRecord | BIT (IN) | NO | - | CODE-BACKED | Controls operation mode. 1 = INSERT a new commission record, 0 = UPDATE an existing record by accumulating Commission and UsedBonusCommission. |
| 9 | @UsedBonusCommission | DECIMAL(18,6) (IN) | NO | - | CODE-BACKED | The bonus-funded portion of the commission, in cents. Divided by 100 before storage. In UPDATE mode, accumulated onto the existing value. |
| 10 | @RetVal | INT (OUTPUT) | NO | - | CODE-BACKED | In INSERT mode, returns the SCOPE_IDENTITY() value of the newly inserted record. In UPDATE mode, value is not set by the procedure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_Sales_Commissions | INSERT | Inserts new commission record (when @InsertNewRecord = 1) |
| - | dbo.tblaff_Sales_Commissions | UPDATE | Updates existing commission record by accumulating values (when @InsertNewRecord = 0) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateSalesCommissions (procedure)
└── dbo.tblaff_Sales_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

1 cross-schema dbo table (tblaff_Sales_Commissions).

### 6.2 Objects That Depend On This

Called by the affiliate commission calculation engine during sales commission processing.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

### 7.3 Notes

- Output parameter is named @RetVal (not @NewID as in most other commission INSERT procedures).
- @UsedBonusCommission is divided by 100 before storage (cents-to-dollars conversion).
- UPDATE mode matches on the composite key (SaleID, AffiliateID, Tier) and accumulates Commission and UsedBonusCommission via addition.

---

## 8. Sample Queries

### 8.1 Insert a new Tier 1 sales commission
```sql
DECLARE @RetVal INT
EXEC fiktivo.sp_UpdateSalesCommissions
    @SaleID = 90001,
    @AffiliateID = 100,
    @Commission = 45.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 0,
    @InsertNewRecord = 1,
    @UsedBonusCommission = 500.000000,
    @RetVal = @RetVal OUTPUT
SELECT @RetVal AS NewCommissionID
```

### 8.2 Update an existing sales commission (accumulate values)
```sql
DECLARE @RetVal INT
EXEC fiktivo.sp_UpdateSalesCommissions
    @SaleID = 90001,
    @AffiliateID = 100,
    @Commission = 12.50,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 0,
    @InsertNewRecord = 0,
    @UsedBonusCommission = 200.000000,
    @RetVal = @RetVal OUTPUT
-- Commission on the existing row is now increased by 12.50
-- UsedBonusCommission on the existing row is now increased by 2.00 (200/100)
```

### 8.3 Insert a Tier 2 sub-affiliate sales commission with no bonus component
```sql
DECLARE @RetVal INT
EXEC fiktivo.sp_UpdateSalesCommissions
    @SaleID = 90001,
    @AffiliateID = 200,
    @Commission = 9.00,
    @Tier = 2,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = 100,
    @InsertNewRecord = 1,
    @UsedBonusCommission = 0.000000,
    @RetVal = @RetVal OUTPUT
SELECT @RetVal AS NewCommissionID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateSalesCommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateSalesCommissions.sql*
