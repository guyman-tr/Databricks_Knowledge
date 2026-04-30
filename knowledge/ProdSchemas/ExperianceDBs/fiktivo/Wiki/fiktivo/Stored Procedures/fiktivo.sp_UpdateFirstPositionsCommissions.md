# fiktivo.sp_UpdateFirstPositionsCommissions

> Writes a new first-position commission record for an affiliate into the first positions commissions table and returns the new record's identity via @RetVal.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RetVal OUTPUT (new commission record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a single affiliate first-position commission record into `dbo.tblaff_FirstPositions_Commissions`. A "first position" is the first trade opened by a referred customer on the platform. This milestone event can trigger a commission for the affiliate who referred the customer.

First-position commissions are a key metric in affiliate programs, representing the moment a referred customer transitions from registration to active trading. This event is significant because it demonstrates customer quality -- the customer has not only registered and deposited but has also placed their first trade. Without this procedure, affiliates would not receive credit for this conversion milestone.

The procedure is called by the commission engine after a first-position event is validated. Unlike most other commission writers, this procedure uses `@RetVal` as its OUTPUT parameter name (instead of `@NewID`). It inserts the record and returns SCOPE_IDENTITY().

---

## 2. Business Logic

### 2.1 First Position Commission Record Creation

**What**: Creates a commission record linking a customer's first trade to an affiliate's earned commission.

**Columns/Parameters Involved**: `@FirstPositionID`, `@AffiliateID`, `@Commission`, `@Tier`, `@Paid`, `@PaymentID`, `@SubAffiliateID`

**Rules**:
- One commission record per first-position event per affiliate
- FirstPositionID links to the specific first-trade milestone in dbo.tblaff_FirstPositions
- Tier reflects the affiliate's commission tier at the time of the event
- Standard paid/unpaid tracking via Paid flag and PaymentID
- Return value uses @RetVal (not @NewID) as the OUTPUT parameter name

**Diagram**:
```
Customer Places First Trade
    |
    v
sp_UpdateFirstPositionsCommissions
    |
    +--> INSERT INTO tblaff_FirstPositions_Commissions
    |        (FirstPositionID, AffiliateID, Commission, Tier, Paid, PaymentID, SubAffiliateID)
    |
    +--> SCOPE_IDENTITY() --> @RetVal OUTPUT
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FirstPositionID (IN) | INT | NO | - | CODE-BACKED | The unique identifier of the first-position event (customer's first trade) that triggered this commission. References dbo.tblaff_FirstPositions. |
| 2 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate who earned this commission. References dbo.tblaff_Affiliates. |
| 3 | @Commission (IN) | FLOAT | NO | - | CODE-BACKED | The monetary commission amount earned by the affiliate for this first-position milestone. |
| 4 | @Tier (IN) | INT | NO | - | CODE-BACKED | The affiliate tier level at the time this commission was calculated. |
| 5 | @Paid (IN) | BIT | NO | - | CODE-BACKED | Payment status: 1 = commission has been paid, 0 = commission is pending payment. |
| 6 | @PaymentID (IN) | INT | NO | - | CODE-BACKED | The payment batch identifier. Links to dbo.tblaff_PaymentHistory when Paid=1. Zero when unpaid. |
| 7 | @SubAffiliateID (IN) | NVARCHAR(1024) | NO | '' | CODE-BACKED | The sub-affiliate tracking identifier. Empty string when no sub-affiliate involvement. |
| 8 | @RetVal (OUT) | INT | YES | - | CODE-BACKED | The SCOPE_IDENTITY() value of the newly inserted commission record. Named @RetVal instead of @NewID in this procedure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FirstPositionID | dbo.tblaff_FirstPositions | Implicit | Links the commission to the customer's first trade event |
| @AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning the commission |
| @PaymentID | dbo.tblaff_PaymentHistory | Implicit | Links to the payment batch when commission is disbursed |
| INSERT target | dbo.tblaff_FirstPositions_Commissions | Write | Inserts a new first-position commission record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateFirstPositionsCommissions (procedure)
└── dbo.tblaff_FirstPositions_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_FirstPositions_Commissions | Table | INSERT target for first-position commission records |

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

### 8.1 Insert a new first-position commission
```sql
DECLARE @RetVal INT
EXEC fiktivo.sp_UpdateFirstPositionsCommissions
    @FirstPositionID = 7700,
    @AffiliateID = 150,
    @Commission = 75.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = '',
    @RetVal = @RetVal OUTPUT
SELECT @RetVal AS NewCommissionID
```

### 8.2 Verify first-position commissions for a specific event
```sql
SELECT *
FROM dbo.tblaff_FirstPositions_Commissions WITH (NOLOCK)
WHERE FirstPositionID = 7700
ORDER BY ID DESC
```

### 8.3 Review first-position commissions with affiliate details
```sql
SELECT fpc.*, a.UserName
FROM dbo.tblaff_FirstPositions_Commissions fpc WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateID = fpc.AffiliateID
WHERE fpc.AffiliateID = 150
ORDER BY fpc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateFirstPositionsCommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateFirstPositionsCommissions.sql*
