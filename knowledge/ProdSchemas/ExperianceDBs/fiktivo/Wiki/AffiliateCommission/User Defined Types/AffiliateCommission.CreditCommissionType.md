# AffiliateCommission.CreditCommissionType

> Table-valued parameter type used to pass credit commission records in bulk to stored procedures that save or insert credit-based affiliate commissions.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | CreditID + Tier (composite key in target table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CreditCommissionType is a table-valued parameter (TVP) that defines the shape of credit commission data passed to stored procedures. It models the commission earned by affiliates when a customer they referred makes a credit transaction (deposit, bonus, etc.). Each row represents one commission record for a specific credit event at a specific tier level.

This type exists because a single credit event can generate multiple commission rows - one per tier in a multi-tier affiliate structure. Rather than calling a procedure once per commission row, the TVP allows the application to batch all commission rows for a credit into a single procedure call, ensuring atomicity within a transaction.

The type is used primarily by SaveCreditCommission and InsertCredit. SaveCreditCommission receives the TVP, deletes any existing commission rows for the credit, updates the Credit record's processing state, and inserts the new commission rows - all within a single transaction.

---

## 2. Business Logic

### 2.1 Multi-Tier Commission Model

**What**: A single credit event can generate commissions for multiple affiliates at different tiers in the referral chain.

**Columns/Parameters Involved**: `AffiliateID`, `Tier`, `Commission`

**Rules**:
- Tier 1 is the direct referring affiliate; higher tiers represent upstream affiliates in the referral chain
- Each tier may earn a different commission amount for the same credit event
- The TVP carries all tiers for one credit event in a single batch

**Diagram**:
```
Customer deposits $100
       |
       v
  [Credit Event]
       |
       +-- Tier 1: Direct affiliate -> Commission $10
       +-- Tier 2: Master affiliate  -> Commission $2
```

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter type, not a persisted table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | Unique identifier of the credit transaction this commission applies to. Maps to AffiliateCommission.Credit.CreditID and AffiliateCommission.CreditCommission.CreditID. |
| 2 | AffiliateID | int | NO | - | CODE-BACKED | Identifier of the affiliate earning this commission. References the affiliate system (dbo.tblaff_Affiliates). |
| 3 | Commission | float | NO | - | CODE-BACKED | Dollar amount of commission earned by this affiliate for this credit event. Precision uses float for legacy compatibility with the commission calculation engine. |
| 4 | Tier | int | NO | - | CODE-BACKED | Level in the multi-tier affiliate referral chain. 1 = direct referrer, 2+ = upstream affiliates. Combined with CreditID, forms the natural key in the target CreditCommission table. |
| 5 | Paid | bit | NO | - | CODE-BACKED | Whether this commission has been paid out to the affiliate. 0 = unpaid/pending, 1 = paid. Newly inserted commissions are typically unpaid (0) and set to paid (1) during payment processing. |
| 6 | PaymentID | int | NO | - | CODE-BACKED | Identifier of the payment batch in which this commission was or will be paid. 0 when unpaid; populated with the payment batch ID when the commission is included in an affiliate payout. |
| 7 | AffiliateTypeID | int | YES | - | CODE-BACKED | Type classification of the affiliate earning this commission. NULL when the affiliate type is not relevant to commission calculation. Added as part of PART-2448 (CPA New Compensation Design). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditID | AffiliateCommission.Credit | Implicit | Links commission to the originating credit transaction |
| CreditID | AffiliateCommission.CreditCommission | Implicit | TVP rows are inserted into CreditCommission |
| AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning commission |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.SaveCreditCommission | @AffiliateCommission | Parameter Type | TVP parameter carrying credit commission rows to save |
| AffiliateCommission.InsertCredit | @AffiliateCommission | Parameter Type | TVP parameter carrying credit commission rows during credit insertion |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.SaveCreditCommission | Stored Procedure | READONLY parameter for bulk commission insert |
| AffiliateCommission.InsertCredit | Stored Procedure | READONLY parameter for commission insert during credit creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. Table types do not support constraints beyond NOT NULL.

---

## 8. Sample Queries

### 8.1 Declare and populate for testing
```sql
DECLARE @Commissions AffiliateCommission.CreditCommissionType;
INSERT INTO @Commissions (CreditID, AffiliateID, Commission, Tier, Paid, PaymentID, AffiliateTypeID)
VALUES
    (12345, 100, 15.50, 1, 0, 0, NULL),
    (12345, 200, 3.00, 2, 0, 0, NULL);
```

### 8.2 Pass to SaveCreditCommission
```sql
EXEC AffiliateCommission.SaveCreditCommission
    @CreditID = 12345,
    @CommissionSource = 'Deposit',
    @AffiliateCommission = @Commissions,
    @CreditDate = '2026-01-15';
```

### 8.3 Inspect TVP contents before saving
```sql
SELECT CreditID, AffiliateID, Commission, Tier, Paid, PaymentID, AffiliateTypeID
FROM @Commissions
ORDER BY Tier;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2448](https://etoro-jira.atlassian.net/browse/PART-2448) | Jira | CPA New Compensation Design - added AffiliateTypeID column to support affiliate type-specific commission rules (Dec 2023) |
| [PART-5458](https://etoro-jira.atlassian.net/browse/PART-5458) | Jira | ISA MoneyFarm integration - referenced in SaveCreditCommission header (Jan 2026) |
| [PART-1278](https://etoro-jira.atlassian.net/browse/PART-1278) | Jira | Added IsProcessed field update to SaveCreditCommission flow (Mar 2023) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/2*
*Sources: Atlassian: 0 Confluence + 3 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditCommissionType | Type: User Defined Type | Source: fiktivo/AffiliateCommission/User Defined Types/AffiliateCommission.CreditCommissionType.sql*
