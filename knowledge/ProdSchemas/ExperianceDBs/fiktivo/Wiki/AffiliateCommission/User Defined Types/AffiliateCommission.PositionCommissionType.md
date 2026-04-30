# AffiliateCommission.PositionCommissionType

> Table-valued parameter type used to pass closed position commission records in bulk to stored procedures that save affiliate commissions earned from trading activity.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | PositionID + Tier (composite key in target table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

PositionCommissionType is a table-valued parameter (TVP) that defines the shape of position-based commission data passed to stored procedures. It models the commission earned by affiliates when a position opened by a referred customer is closed. Each row represents one commission record for a specific closed position at a specific tier level.

This type exists because a single closed position can generate commissions for multiple affiliates in a multi-tier referral chain. The TVP allows the application to batch all tier commissions for one position into a single procedure call, ensuring transactional atomicity. Unlike CreditCommissionType, this type uses decimal(16,6) precision for Commission to match the financial precision requirements of trading-related amounts.

The type is consumed by SaveClosedPositionCommission and InsertClosedPosition. SaveClosedPositionCommission receives the TVP, deletes existing commissions for the position, updates the ClosedPosition record's processing state and commission date, and inserts the new commission rows - all within a single transaction. Note that PositionID in this TVP is NOT used by SaveClosedPositionCommission (which takes @ClosedPositionID as a separate scalar parameter); the PositionID column is used by InsertClosedPosition.

---

## 2. Business Logic

### 2.1 Multi-Tier Position Commission Model

**What**: A single closed position generates commissions for one or more affiliates in the referral hierarchy.

**Columns/Parameters Involved**: `PositionID`, `AffiliateID`, `Tier`, `Commission`

**Rules**:
- Tier 1 is the direct referring affiliate; higher tiers represent upstream affiliates
- Commission amount uses decimal(16,6) precision for trading-grade accuracy
- The TVP carries all tiers for one position, enabling atomic save within a transaction

**Diagram**:
```
Position closed (profit/loss)
       |
       v
  [Commission Calculation]
       |
       +-- Tier 1: Direct affiliate -> Commission $25.123456
       +-- Tier 2: Master affiliate  -> Commission $5.024688
```

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter type, not a persisted table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Unique identifier of the closed position this commission applies to. Maps to AffiliateCommission.ClosedPositionCommission.ClosedPositionID. Used by InsertClosedPosition; SaveClosedPositionCommission uses a separate scalar @ClosedPositionID parameter instead. |
| 2 | AffiliateID | int | NO | - | CODE-BACKED | Identifier of the affiliate earning this commission. References the affiliate system (dbo.tblaff_Affiliates). Inserted directly into ClosedPositionCommission.AffiliateID. |
| 3 | Commission | decimal(16,6) | NO | - | CODE-BACKED | Dollar amount of commission earned for this closed position. Uses decimal(16,6) for trading-grade precision (unlike CreditCommissionType which uses float). |
| 4 | Tier | int | NO | - | CODE-BACKED | Level in the multi-tier affiliate referral chain. 1 = direct referrer, 2+ = upstream affiliates. Combined with ClosedPositionID, forms the composite PK in the target ClosedPositionCommission table. |
| 5 | Paid | bit | NO | - | CODE-BACKED | Whether this commission has been paid out to the affiliate. 0 = unpaid/pending, 1 = paid. Newly inserted commissions are typically unpaid (0). |
| 6 | PaymentID | int | NO | - | CODE-BACKED | Identifier of the payment batch in which this commission was or will be paid. 0 when unpaid; populated with the payment batch ID during affiliate payout processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | AffiliateCommission.ClosedPosition | Implicit | Links commission to the originating closed position |
| PositionID | AffiliateCommission.ClosedPositionCommission | Implicit | TVP rows are inserted into ClosedPositionCommission |
| AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning commission |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.SaveClosedPositionCommission | @AffiliateCommission | Parameter Type | TVP parameter carrying position commission rows to save |
| AffiliateCommission.InsertClosedPosition | @AffiliateCommission | Parameter Type | TVP parameter carrying commission rows during position insertion |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.SaveClosedPositionCommission | Stored Procedure | READONLY parameter for bulk commission insert |
| AffiliateCommission.InsertClosedPosition | Stored Procedure | READONLY parameter for commission insert during position creation |

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
DECLARE @Commissions AffiliateCommission.PositionCommissionType;
INSERT INTO @Commissions (PositionID, AffiliateID, Commission, Tier, Paid, PaymentID)
VALUES
    (9876543, 100, 25.123456, 1, 0, 0),
    (9876543, 200, 5.024688, 2, 0, 0);
```

### 8.2 Pass to SaveClosedPositionCommission
```sql
EXEC AffiliateCommission.SaveClosedPositionCommission
    @ClosedPositionID = 9876543,
    @AffiliateCommission = @Commissions,
    @CommissionDate = '2026-01-15';
```

### 8.3 Verify commission amounts by tier
```sql
SELECT PositionID, AffiliateID, Tier, Commission,
       CASE Paid WHEN 1 THEN 'Paid' ELSE 'Pending' END AS PaymentStatus
FROM @Commissions
ORDER BY Tier;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2448](https://etoro-jira.atlassian.net/browse/PART-2448) | Jira | CPA New Compensation Design - context for multi-tier commission architecture (Dec 2023) |
| [PART-1278](https://etoro-jira.atlassian.net/browse/PART-1278) | Jira | Added IsProcessed field update to save flow (Mar 2023) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/2*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.PositionCommissionType | Type: User Defined Type | Source: fiktivo/AffiliateCommission/User Defined Types/AffiliateCommission.PositionCommissionType.sql*
