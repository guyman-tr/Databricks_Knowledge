# fiktivo.sp_UpdateBonusesCommissions

> Writes a new bonus commission record for an affiliate into the bonus commissions table and returns the new record's identity.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT (new commission record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a single affiliate bonus commission record into `dbo.tblaff_Bonuses_Commissions`. It records the commission earned by an affiliate (or sub-affiliate) for a specific bonus event, including the commission amount, tier level, and payment status.

Bonus commissions are part of the affiliate compensation model. When the platform awards a bonus to a referred customer, this procedure is called to create the corresponding commission entry for the responsible affiliate. Without it, affiliates would not receive credit for bonus-related compensation events.

The procedure is called by the affiliate commission engine after a bonus event is processed. It receives the bonus identifier, affiliate details, and commission parameters, inserts the record, and returns the newly generated identity via SCOPE_IDENTITY() so the calling process can track the created commission.

---

## 2. Business Logic

### 2.1 Commission Record Creation

**What**: Creates a single commission record linking a bonus event to an affiliate's earned commission.

**Columns/Parameters Involved**: `@BonusID`, `@AffiliateID`, `@Commission`, `@Tier`, `@Paid`, `@PaymentID`, `@SubAffiliateID`

**Rules**:
- One commission record is created per bonus event per affiliate
- The Tier value determines the affiliate's commission tier level at the time of the event
- Paid=0 means the commission is pending; Paid=1 means it has been disbursed
- PaymentID links to the payment batch when paid; 0 or NULL when unpaid
- SubAffiliateID tracks the downstream sub-affiliate if applicable (empty string if none)

**Diagram**:
```
Bonus Event
    |
    v
sp_UpdateBonusesCommissions
    |
    +--> INSERT INTO tblaff_Bonuses_Commissions
    |        (BonusID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID)
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
| 1 | @BonusID (IN) | INT | NO | - | CODE-BACKED | The unique identifier of the bonus event that triggered this commission. References the bonus record in the platform. |
| 2 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate who earned this commission. References dbo.tblaff_Affiliates. |
| 3 | @Commission (IN) | FLOAT | NO | - | CODE-BACKED | The monetary commission amount earned by the affiliate for this bonus event. Currency determined by affiliate agreement. |
| 4 | @Tier (IN) | INT | NO | - | CODE-BACKED | The affiliate tier level at the time this commission was calculated. Tier determines the commission rate applied. |
| 5 | @Paid (IN) | BIT | NO | - | CODE-BACKED | Payment status: 1 = commission has been paid to the affiliate, 0 = commission is pending payment. |
| 6 | @PaymentID (IN) | INT | NO | - | CODE-BACKED | The payment batch identifier. Links to dbo.tblaff_PaymentHistory when Paid=1. Zero or default when unpaid. |
| 7 | @SubAffiliateID (IN) | NVARCHAR(1024) | NO | '' | CODE-BACKED | The sub-affiliate tracking identifier. Empty string when the commission is earned directly (no sub-affiliate involvement). |
| 8 | @NewID (OUT) | INT | YES | - | CODE-BACKED | The SCOPE_IDENTITY() value of the newly inserted commission record. Returned to the caller to confirm successful creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BonusID | dbo.tblaff_Bonuses | Implicit | Links the commission to the originating bonus event |
| @AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning the commission |
| @PaymentID | dbo.tblaff_PaymentHistory | Implicit | Links to the payment batch when the commission is disbursed |
| INSERT target | dbo.tblaff_Bonuses_Commissions | Write | Inserts a new commission record into the bonuses commission table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateBonusesCommissions (procedure)
└── dbo.tblaff_Bonuses_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Bonuses_Commissions | Table | INSERT target for commission records |

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

### 8.1 Insert a new bonus commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateBonusesCommissions
    @BonusID = 12345,
    @AffiliateID = 100,
    @Commission = 25.50,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = '',
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Verify the inserted record
```sql
SELECT TOP 1 *
FROM dbo.tblaff_Bonuses_Commissions WITH (NOLOCK)
WHERE BonusID = 12345 AND AffiliateID = 100
ORDER BY ID DESC
```

### 8.3 Review all bonus commissions for an affiliate
```sql
SELECT bc.*, a.UserName
FROM dbo.tblaff_Bonuses_Commissions bc WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateID = bc.AffiliateID
WHERE bc.AffiliateID = 100
ORDER BY bc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateBonusesCommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateBonusesCommissions.sql*
