# fiktivo.sp_UpdateCopyTradersCommisions

> Writes a new CopyTrader commission record for an affiliate into the CopyTraders commissions table and returns the new record's identity.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT (new commission record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a single affiliate CopyTrader commission record into `dbo.tblaff_CopyTraders_Commissions`. It records the commission earned by an affiliate when a referred customer initiates a CopyTrader relationship (copying the trades of another user on the platform).

CopyTrader is a social trading feature where users can automatically replicate the trades of experienced traders. When a referred customer starts copy-trading, the responsible affiliate earns a commission. This procedure creates the commission entry. Without it, CopyTrader-related affiliate commissions would not be recorded.

The procedure is called by the commission engine after a CopyTrader event is processed. It inserts the commission record with the CopyTrader identifier, affiliate details, and commission parameters, then returns SCOPE_IDENTITY().

---

## 2. Business Logic

### 2.1 CopyTrader Commission Record Creation

**What**: Creates a commission record linking a CopyTrader event to an affiliate's earned commission.

**Columns/Parameters Involved**: `@CopyTraderID`, `@AffiliateID`, `@Commission`, `@Tier`, `@Paid`, `@PaymentID`, `@SubAffiliateID`

**Rules**:
- One commission record is created per CopyTrader event per affiliate
- The CopyTraderID links to the specific copy-trading initiation event
- Tier reflects the affiliate's commission tier at the time of the event
- Standard paid/unpaid tracking via Paid flag and PaymentID
- SubAffiliateID tracks downstream sub-affiliate if applicable

**Diagram**:
```
CopyTrader Event (customer starts copying)
    |
    v
sp_UpdateCopyTradersCommisions
    |
    +--> INSERT INTO tblaff_CopyTraders_Commissions
    |        (CopyTraderID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID)
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
| 1 | @CopyTraderID (IN) | INT | NO | - | CODE-BACKED | The unique identifier of the CopyTrader event that triggered this commission. References the CopyTrader record in dbo.tblaff_CopyTraders. |
| 2 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate who earned this commission. References dbo.tblaff_Affiliates. |
| 3 | @Commission (IN) | FLOAT | NO | - | CODE-BACKED | The monetary commission amount earned by the affiliate for this CopyTrader event. |
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
| @CopyTraderID | dbo.tblaff_CopyTraders | Implicit | Links the commission to the originating CopyTrader event |
| @AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning the commission |
| @PaymentID | dbo.tblaff_PaymentHistory | Implicit | Links to the payment batch when commission is disbursed |
| INSERT target | dbo.tblaff_CopyTraders_Commissions | Write | Inserts a new commission record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateCopyTradersCommisions (procedure)
└── dbo.tblaff_CopyTraders_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CopyTraders_Commissions | Table | INSERT target for CopyTrader commission records |

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

### 8.1 Insert a new CopyTrader commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateCopyTradersCommisions
    @CopyTraderID = 4500,
    @AffiliateID = 200,
    @Commission = 50.00,
    @Tier = 2,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = '',
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Verify CopyTrader commissions for a specific event
```sql
SELECT *
FROM dbo.tblaff_CopyTraders_Commissions WITH (NOLOCK)
WHERE CopyTraderID = 4500
ORDER BY ID DESC
```

### 8.3 Review CopyTrader commissions with affiliate details
```sql
SELECT ctc.*, a.UserName
FROM dbo.tblaff_CopyTraders_Commissions ctc WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateID = ctc.AffiliateID
WHERE ctc.AffiliateID = 200
ORDER BY ctc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateCopyTradersCommisions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateCopyTradersCommisions.sql*
