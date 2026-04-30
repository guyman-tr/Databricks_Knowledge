# AffiliateCommission.SaveClosedPositionCommission

> Replaces the commission records for a closed position within a transaction (DELETE + INSERT), marks the position as processed, and updates the commission date.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates ClosedPosition + replaces ClosedPositionCommission |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

SaveClosedPositionCommission is the commission finalization procedure for closed positions. After the commission engine calculates (or recalculates) commissions for a position, this procedure atomically replaces the existing commission records with the new ones. It performs a DELETE + INSERT pattern (not MERGE) to ensure a clean replacement, and simultaneously marks the position as IsProcessed = 1 with an updated CommissionDate.

This procedure exists because commission calculations can be revised. When attribution changes (re-attribution, organic-to-paid), the commission engine recalculates and calls this procedure to replace the old commission rows with the new ones. The transactional guarantee ensures the position is never in a state where old commissions are deleted but new ones haven't been inserted yet.

---

## 2. Business Logic

### 2.1 Atomic Commission Replacement

**What**: DELETE + INSERT pattern to replace commission rows within a transaction.

**Columns/Parameters Involved**: `@ClosedPositionID`, `@CommissionDate`, `@AffiliateCommission` (TVP)

**Rules**:
- BEGIN TRAN
- DELETE all ClosedPositionCommission WHERE ClosedPositionID = @ClosedPositionID
- UPDATE ClosedPosition SET CommissionDate = @CommissionDate, IsProcessed = 1
- INSERT new ClosedPositionCommission from TVP
- COMMIT (or ROLLBACK on error)
- This is a full replacement - all old commission rows are removed, not merged

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ClosedPositionID | bigint (IN) | NO | - | CODE-BACKED | The position whose commissions are being replaced. |
| 2 | @AffiliateCommission | PositionCommissionType (IN, TVP) | NO | - | CODE-BACKED | New commission rows (AffiliateID, Commission, Tier, Paid, PaymentID). |
| 3 | @CommissionDate | datetime (IN) | NO | - | CODE-BACKED | When the commission was calculated. Set on ClosedPosition.CommissionDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPositionCommission | DELETE + INSERT | Replaces commission rows |
| - | AffiliateCommission.ClosedPosition | UPDATE | Sets IsProcessed=1, CommissionDate |
| @AffiliateCommission | AffiliateCommission.PositionCommissionType | TVP | Source of new commission rows |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission engine after recalculation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.SaveClosedPositionCommission (procedure)
+-- AffiliateCommission.ClosedPosition (table)
+-- AffiliateCommission.ClosedPositionCommission (table)
+-- AffiliateCommission.PositionCommissionType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | UPDATE IsProcessed, CommissionDate |
| AffiliateCommission.ClosedPositionCommission | Table | DELETE + INSERT (full replacement) |
| AffiliateCommission.PositionCommissionType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission engine) | External | Saves recalculated commissions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | TRAN | Atomic DELETE + UPDATE + INSERT |

---

## 8. Sample Queries

### 8.1 Save recalculated commissions
```sql
DECLARE @CommData AffiliateCommission.PositionCommissionType
INSERT @CommData (AffiliateID, Commission, Tier, Paid, PaymentID)
VALUES (3, 2.50, 1, 0, 0)

EXEC [AffiliateCommission].[SaveClosedPositionCommission]
    @ClosedPositionID = 500000,
    @AffiliateCommission = @CommData,
    @CommissionDate = '2026-04-12'
```

### 8.2 Verify position is marked as processed
```sql
SELECT ClosedPositionID, IsProcessed, CommissionDate
FROM [AffiliateCommission].[ClosedPosition] WITH (NOLOCK)
WHERE ClosedPositionID = 500000
```

### 8.3 View current commission breakdown
```sql
SELECT ClosedPositionID, AffiliateID, Commission, Tier, Paid, PaymentID
FROM [AffiliateCommission].[ClosedPositionCommission] WITH (NOLOCK)
WHERE ClosedPositionID = 500000
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-2448: CPA New Compensation Design (2023-12-17)
- PART-1278: Add update of IsProcess field (2023-03-22)
- Unlabeled: Adding @NewTrackingDate for one-day aggregation (2022-03-13)
- Unlabeled: Remove old tblaff tables (2023-07-19)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.SaveClosedPositionCommission | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.SaveClosedPositionCommission.sql*
