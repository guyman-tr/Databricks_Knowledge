# fiktivo.sp_UpdateSalesCommissions

> Inserts a new sales commission record or updates an existing one for an affiliate, supporting both initial creation and subsequent modification of sales commission entries.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RetVal OUTPUT (new or existing commission record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure manages affiliate sales commission records in `dbo.tblaff_Sales_Commissions`. Unlike the other commission writer procedures which only INSERT, this procedure supports both INSERT and UPDATE operations, controlled by the `@InsertNewRecord` flag. Sales commissions are the most complex commission type because a single sale can be updated multiple times (e.g., as the revenue share accrues over time).

Sales commissions represent revenue-share-based compensation. As a referred customer trades and generates revenue, the affiliate earns a share. This procedure handles the initial creation of the commission record and subsequent updates (e.g., when the commission amount changes due to additional trading activity). It also tracks the `@UsedBonusCommission` which records how much of the commission was offset by bonus-related costs.

The procedure is called by the commission engine during sales commission processing. When `@InsertNewRecord = 1`, it inserts a new row and returns SCOPE_IDENTITY(). When `@InsertNewRecord = 0`, it updates the existing record's Commission value. This dual behavior makes it the most versatile of the commission writer procedures.

---

## 2. Business Logic

### 2.1 Insert vs. Update Decision

**What**: Determines whether to create a new commission record or update an existing one based on the @InsertNewRecord flag.

**Columns/Parameters Involved**: `@InsertNewRecord`, `@SalesID`, `@AffiliateID`, `@Commission`, `@RetVal`

**Rules**:
- When @InsertNewRecord = 1: INSERT a new row into tblaff_Sales_Commissions with all provided parameters, return SCOPE_IDENTITY() as @RetVal
- When @InsertNewRecord = 0: UPDATE the existing commission record (matched by SalesID and AffiliateID) with the new Commission value
- The UsedBonusCommission is only relevant on INSERT; it tracks the bonus offset applied at commission creation time

**Diagram**:
```
Commission Engine Call
    |
    v
@InsertNewRecord?
    |
    +-- 1 (Yes) --> INSERT INTO tblaff_Sales_Commissions
    |                   (SalesID, AffiliateID, Commission, Tier, Paid,
    |                    PaymentID, SubAffiliateID, UsedBonusCommission)
    |               SCOPE_IDENTITY() --> @RetVal
    |
    +-- 0 (No)  --> UPDATE tblaff_Sales_Commissions
                        SET Commission = @Commission
                        WHERE SalesID = @SalesID AND AffiliateID = @AffiliateID
```

### 2.2 Bonus Commission Offset

**What**: Tracks how much of the sale commission was offset by bonus costs.

**Columns/Parameters Involved**: `@UsedBonusCommission`, `@Commission`

**Rules**:
- UsedBonusCommission records the portion of the commission that accounts for bonus-related costs
- The net commission to the affiliate is effectively Commission minus the bonus offset consideration
- This allows the system to track gross vs. net commission economics

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SalesID (IN) | INT | NO | - | CODE-BACKED | The unique identifier of the sale event. References dbo.tblaff_Sales. Used as a match key on UPDATE operations. |
| 2 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate who earned this sales commission. References dbo.tblaff_Affiliates. Used as a match key on UPDATE operations. |
| 3 | @Commission (IN) | FLOAT | NO | - | CODE-BACKED | The monetary commission amount. On INSERT, this is the initial commission. On UPDATE, this replaces the existing commission value. |
| 4 | @Tier (IN) | INT | NO | - | CODE-BACKED | The affiliate tier level at the time this commission was calculated. Used on INSERT only. |
| 5 | @Paid (IN) | BIT | NO | - | CODE-BACKED | Payment status: 1 = commission has been paid, 0 = commission is pending. Used on INSERT only. |
| 6 | @PaymentID (IN) | INT | NO | - | CODE-BACKED | The payment batch identifier. Links to dbo.tblaff_PaymentHistory when Paid=1. Used on INSERT only. |
| 7 | @SubAffiliateID (IN) | NVARCHAR(1024) | NO | '' | CODE-BACKED | The sub-affiliate tracking identifier. Used on INSERT only. Empty string when no sub-affiliate. |
| 8 | @InsertNewRecord (IN) | BIT | NO | - | CODE-BACKED | Controls INSERT vs UPDATE behavior: 1 = insert a new commission record, 0 = update the existing record matching SalesID+AffiliateID. |
| 9 | @UsedBonusCommission (IN) | DECIMAL | NO | - | CODE-BACKED | The portion of the commission offset by bonus-related costs. Stored on INSERT to track gross vs. net commission economics. |
| 10 | @RetVal (OUT) | INT | YES | - | CODE-BACKED | On INSERT: the SCOPE_IDENTITY() of the new record. On UPDATE: not set (retains caller's value). Named @RetVal instead of @NewID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SalesID | dbo.tblaff_Sales | Implicit | Links the commission to the originating sale event |
| @AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning the commission |
| @PaymentID | dbo.tblaff_PaymentHistory | Implicit | Links to the payment batch when commission is disbursed |
| INSERT/UPDATE target | dbo.tblaff_Sales_Commissions | Write | Inserts or updates sales commission records |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateSalesCommissions (procedure)
└── dbo.tblaff_Sales_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales_Commissions | Table | INSERT and UPDATE target for sales commission records |

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

### 8.1 Insert a new sales commission
```sql
DECLARE @RetVal INT
EXEC fiktivo.sp_UpdateSalesCommissions
    @SalesID = 88001,
    @AffiliateID = 100,
    @Commission = 150.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = '',
    @InsertNewRecord = 1,
    @UsedBonusCommission = 10.00,
    @RetVal = @RetVal OUTPUT
SELECT @RetVal AS NewCommissionID
```

### 8.2 Update an existing sales commission amount
```sql
DECLARE @RetVal INT
EXEC fiktivo.sp_UpdateSalesCommissions
    @SalesID = 88001,
    @AffiliateID = 100,
    @Commission = 175.50,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = '',
    @InsertNewRecord = 0,
    @UsedBonusCommission = 10.00,
    @RetVal = @RetVal OUTPUT
```

### 8.3 Review sales commissions with bonus offset details
```sql
SELECT sc.*, a.UserName,
       sc.Commission - sc.UsedBonusCommission AS NetCommission
FROM dbo.tblaff_Sales_Commissions sc WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateID = sc.AffiliateID
WHERE sc.AffiliateID = 100
ORDER BY sc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateSalesCommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateSalesCommissions.sql*
