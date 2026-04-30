# AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration

> Scalar function that checks whether a given affiliate has been migrated to the new commission system for registration commissions.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIT (1=migrated, 0=not migrated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CheckIfAffiliateWasMigratedForRegistration is a migration gate function that determines whether a specific affiliate's registration commissions should be processed by the new AffiliateCommission system or the legacy tblaff_Registrations system. It checks the MigratedAffiliates_Registration synonym (pointing to the production eToro database).

Same pattern as CheckIfAffiliateWasMigratedForCPA and CheckIfAffiliateWasMigratedForSales. Part of the incremental migration strategy for the affiliate commission system.

---

## 2. Business Logic

### 2.1 Migration Gate Check

**What**: Simple existence check against external table via synonym.

**Rules**:
- IF EXISTS in MigratedAffiliates_Registration -> RETURN 1
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
| 2 | RETURN | bit | NO | - | CODE-BACKED | Output: 1 = migrated, 0 = legacy system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.MigratedAffiliates_Registration | SELECT | Synonym target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration (function)
└── AffiliateCommission.MigratedAffiliates_Registration (synonym)
      └── [AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_Registration] (external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.MigratedAffiliates_Registration | Synonym | Existence check |

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
SELECT AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration(12345) AS IsMigrated;
```

### 8.2 Check all domains
```sql
SELECT
    AffiliateCommission.CheckIfAffiliateWasMigratedForCPA(12345) AS CPA,
    AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration(12345) AS Registration,
    AffiliateCommission.CheckIfAffiliateWasMigratedForSales(12345) AS Sales;
```

### 8.3 Filter to non-migrated affiliates
```sql
SELECT AffiliateID FROM dbo.tblaff_Affiliates WITH (NOLOCK)
WHERE AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration(AffiliateID) = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration | Type: Scalar Function | Source: fiktivo/AffiliateCommission/Functions/AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration.sql*
