# AffiliateCommission.CheckIfAffiliateWasMigratedForSales

> Scalar function that checks whether a given affiliate has been migrated to the new commission system for sales (closed position) commissions.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIT (1=migrated, 0=not migrated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CheckIfAffiliateWasMigratedForSales is a migration gate function that determines whether a specific affiliate's sales/closed-position commissions should be processed by the new AffiliateCommission system or the legacy tblaff_Sales system. Unlike the CPA and Registration variants (which use synonyms to external servers), this function checks the LOCAL MigratedAffiliates_Sales table.

Same pattern as the other two migration check functions but with a local table target. The local table is currently empty (0 rows), meaning no affiliates are flagged as migrated for sales commissions in this environment.

---

## 2. Business Logic

### 2.1 Migration Gate Check

**What**: Simple existence check against local table.

**Rules**:
- IF EXISTS in MigratedAffiliates_Sales -> RETURN 1
- ELSE -> RETURN 0
- Uses WITH (NOLOCK)

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int | NO | - | CODE-BACKED | Input: Affiliate ID to check. |
| 2 | RETURN | bit | NO | - | CODE-BACKED | Output: 1 = migrated, 0 = legacy system. Currently always returns 0 (empty table). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.MigratedAffiliates_Sales | SELECT | Local migration tracking table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CheckIfAffiliateWasMigratedForSales (function)
└── AffiliateCommission.MigratedAffiliates_Sales (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.MigratedAffiliates_Sales | Table | Existence check (local, currently empty) |

### 6.2 Objects That Depend On This

No dependents found in this schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check single affiliate
```sql
SELECT AffiliateCommission.CheckIfAffiliateWasMigratedForSales(12345) AS IsMigrated;
```

### 8.2 Check all three migration domains
```sql
SELECT
    AffiliateCommission.CheckIfAffiliateWasMigratedForCPA(12345) AS CPA,
    AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration(12345) AS Registration,
    AffiliateCommission.CheckIfAffiliateWasMigratedForSales(12345) AS Sales;
```

### 8.3 Verify all return 0 (empty table)
```sql
SELECT TOP 5 AffiliateID,
       AffiliateCommission.CheckIfAffiliateWasMigratedForSales(AffiliateID) AS SalesMigrated
FROM dbo.tblaff_Affiliates WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CheckIfAffiliateWasMigratedForSales | Type: Scalar Function | Source: fiktivo/AffiliateCommission/Functions/AffiliateCommission.CheckIfAffiliateWasMigratedForSales.sql*
