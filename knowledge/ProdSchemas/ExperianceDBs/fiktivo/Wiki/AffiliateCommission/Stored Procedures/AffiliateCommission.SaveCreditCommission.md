# AffiliateCommission.SaveCreditCommission

> Replaces the commission records for a credit within a transaction (DELETE + INSERT), marks the credit as processed, and updates the commission date and source.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Credit + replaces CreditCommission |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

SaveCreditCommission is the commission finalization procedure for credits. After the commission engine calculates or recalculates commissions for a credit event, this procedure atomically replaces existing commission records with new ones. It follows the same DELETE + INSERT pattern as SaveClosedPositionCommission, and additionally sets CommissionSource to track which commission calculation path produced the result.

---

## 2. Business Logic

### 2.1 Atomic Commission Replacement with Source Tracking

**What**: DELETE + INSERT pattern to replace commission rows, plus sets IsProcessed and CommissionSource.

**Columns/Parameters Involved**: `@CreditID`, `@CreditDate`, `@CommissionSource`, `@AffiliateCommission` (TVP)

**Rules**:
- BEGIN TRAN
- DELETE CreditCommission WHERE CreditID = @CreditID
- UPDATE Credit SET CreditDate = @CreditDate, IsProcessed = 1, CommissionSource = @CommissionSource
- INSERT new CreditCommission from TVP (includes AffiliateTypeID column)
- COMMIT (or ROLLBACK on error)
- CommissionSource tracks which calculation path produced these commissions (e.g., CPA, CPAD, RevShare)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditID | bigint (IN) | NO | - | CODE-BACKED | The credit whose commissions are being replaced. |
| 2 | @CommissionSource | varchar(30) (IN) | NO | - | CODE-BACKED | Identifies which commission calculation path produced these results (e.g., CPA, CPAD, RevShare). |
| 3 | @AffiliateCommission | CreditCommissionType (IN, TVP) | NO | - | CODE-BACKED | New commission rows (CreditID, AffiliateID, Commission, Tier, Paid, PaymentID, AffiliateTypeID). |
| 4 | @CreditDate | datetime (IN) | NO | - | CODE-BACKED | When the commission was calculated. Set on Credit.CreditDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditCommission | DELETE + INSERT | Replaces commission rows |
| - | AffiliateCommission.Credit | UPDATE | Sets IsProcessed=1, CreditDate, CommissionSource |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission engine after credit recalculation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.SaveCreditCommission (procedure)
+-- AffiliateCommission.Credit (table)
+-- AffiliateCommission.CreditCommission (table)
+-- AffiliateCommission.CreditCommissionType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | UPDATE IsProcessed, CreditDate, CommissionSource |
| AffiliateCommission.CreditCommission | Table | DELETE + INSERT (full replacement) |
| AffiliateCommission.CreditCommissionType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission engine) | External | Saves recalculated credit commissions |

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

### 8.1 Save recalculated credit commissions
```sql
DECLARE @CommData AffiliateCommission.CreditCommissionType
INSERT @CommData (CreditID, AffiliateID, Commission, Tier, Paid, PaymentID, AffiliateTypeID)
VALUES (100, 3, 5.00, 1, 0, 0, 1)

EXEC [AffiliateCommission].[SaveCreditCommission]
    @CreditID = 100, @CommissionSource = 'CPA',
    @AffiliateCommission = @CommData, @CreditDate = '2026-04-12'
```

### 8.2 Verify credit is processed
```sql
SELECT CreditID, IsProcessed, CreditDate, CommissionSource
FROM [AffiliateCommission].[Credit] WITH (NOLOCK)
WHERE CreditID = 100
```

### 8.3 View commission breakdown
```sql
SELECT CreditID, AffiliateID, Commission, Tier, AffiliateTypeID
FROM [AffiliateCommission].[CreditCommission] WITH (NOLOCK)
WHERE CreditID = 100
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-5458: ISA MoneyFarm (2026-01-29)
- PART-2448: CPA New Compensation Design (2023-12-17)
- PART-1278: Add IsProcess field update (2023-03-22)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.SaveCreditCommission | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.SaveCreditCommission.sql*
