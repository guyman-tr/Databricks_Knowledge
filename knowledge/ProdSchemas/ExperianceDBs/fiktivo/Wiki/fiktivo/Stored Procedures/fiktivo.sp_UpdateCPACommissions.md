# fiktivo.sp_UpdateCPACommissions

> Writes a new CPA (Cost Per Acquisition) commission record for an affiliate into the CPA commissions table and returns the new record's identity.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT (new commission record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a single affiliate CPA commission record into `dbo.tblaff_CPA_Commissions`. CPA commissions are one-time payments awarded to an affiliate when a referred customer completes a qualifying deposit. The procedure also accepts an `@AffiliateTypeID` parameter that identifies the affiliate type agreement governing the CPA rate.

CPA (Cost Per Acquisition) is a fundamental affiliate compensation model where the affiliate receives a flat fee per qualifying customer action (typically a first deposit). This procedure records that earned commission. Without it, deposit-based acquisition commissions would not be tracked.

The procedure is called by the commission engine after a qualifying deposit event. It inserts the commission record with the deposit reference, affiliate type, and commission details, then returns the SCOPE_IDENTITY() value.

---

## 2. Business Logic

### 2.1 CPA Commission Record Creation

**What**: Creates a commission record linking a qualifying deposit to an affiliate's CPA commission.

**Columns/Parameters Involved**: `@DepositID`, `@AffiliateID`, `@AffiliateTypeID`, `@Commission`, `@Tier`, `@Paid`, `@PaymentID`, `@SubAffiliateID`

**Rules**:
- One CPA commission record is created per qualifying deposit per affiliate
- AffiliateTypeID determines which CPA agreement rate was used to calculate the commission
- The DepositID links the commission back to the specific deposit that triggered it
- Tier reflects the affiliate's commission tier at the time of the deposit
- Standard paid/unpaid tracking via Paid flag and PaymentID

**Diagram**:
```
Qualifying Deposit Event
    |
    v
sp_UpdateCPACommissions
    |
    +--> INSERT INTO tblaff_CPA_Commissions
    |        (DepositID, AffiliateID, AffiliateTypeID, Commission, Tier, Paid, PaymentID, SubAffiliateID)
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
| 1 | @DepositID (IN) | INT | NO | - | CODE-BACKED | The unique identifier of the qualifying deposit that triggered this CPA commission. References the deposit record in the platform. |
| 2 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate who earned this CPA commission. References dbo.tblaff_Affiliates. |
| 3 | @AffiliateTypeID (IN) | INT | NO | - | CODE-BACKED | The affiliate type agreement that governs the CPA rate applied. References dbo.tblaff_AffiliateTypes. Determines which CPA rate schedule was used to calculate the commission amount. |
| 4 | @Commission (IN) | FLOAT | NO | - | CODE-BACKED | The CPA commission amount earned by the affiliate. Typically a flat fee per qualifying deposit, determined by the affiliate type agreement. |
| 5 | @Tier (IN) | INT | NO | - | CODE-BACKED | The affiliate tier level at the time this CPA commission was calculated. |
| 6 | @Paid (IN) | BIT | NO | - | CODE-BACKED | Payment status: 1 = commission has been paid to the affiliate, 0 = commission is pending payment. |
| 7 | @PaymentID (IN) | INT | NO | - | CODE-BACKED | The payment batch identifier. Links to dbo.tblaff_PaymentHistory when Paid=1. Zero or default when unpaid. |
| 8 | @SubAffiliateID (IN) | NVARCHAR(1024) | NO | '' | CODE-BACKED | The sub-affiliate tracking identifier. Empty string when no sub-affiliate involvement. |
| 9 | @NewID (OUT) | INT | YES | - | CODE-BACKED | The SCOPE_IDENTITY() value of the newly inserted commission record. Returned to confirm creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | dbo.tblaff_Deposits | Implicit | Links the commission to the qualifying deposit event |
| @AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning the CPA commission |
| @AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit | Identifies the affiliate type agreement governing the CPA rate |
| @PaymentID | dbo.tblaff_PaymentHistory | Implicit | Links to the payment batch when commission is disbursed |
| INSERT target | dbo.tblaff_CPA_Commissions | Write | Inserts a new CPA commission record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateCPACommissions (procedure)
└── dbo.tblaff_CPA_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CPA_Commissions | Table | INSERT target for CPA commission records |

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

### 8.1 Insert a new CPA commission
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateCPACommissions
    @DepositID = 99001,
    @AffiliateID = 100,
    @AffiliateTypeID = 3,
    @Commission = 200.00,
    @Tier = 1,
    @Paid = 0,
    @PaymentID = 0,
    @SubAffiliateID = '',
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewCommissionID
```

### 8.2 Verify CPA commissions for a specific deposit
```sql
SELECT *
FROM dbo.tblaff_CPA_Commissions WITH (NOLOCK)
WHERE DepositID = 99001
ORDER BY ID DESC
```

### 8.3 Review CPA commissions by affiliate type agreement
```sql
SELECT cc.*, a.UserName, at.AffiliateTypeName
FROM dbo.tblaff_CPA_Commissions cc WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateID = cc.AffiliateID
INNER JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON at.AffiliateTypeID = cc.AffiliateTypeID
WHERE cc.AffiliateID = 100
ORDER BY cc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateCPACommissions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateCPACommissions.sql*
