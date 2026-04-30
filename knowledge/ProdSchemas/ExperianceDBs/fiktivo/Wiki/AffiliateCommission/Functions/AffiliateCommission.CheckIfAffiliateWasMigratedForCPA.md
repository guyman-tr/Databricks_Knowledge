# AffiliateCommission.CheckIfAffiliateWasMigratedForCPA

> Scalar function that checks whether a given affiliate has been migrated to the new commission system for CPA (Cost Per Acquisition) commissions.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIT (1=migrated, 0=not migrated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CheckIfAffiliateWasMigratedForCPA is a migration gate function that determines whether a specific affiliate's CPA (Cost Per Acquisition) commissions should be processed by the new AffiliateCommission system or the legacy tblaff system. It checks the MigratedAffiliates_CPA synonym (pointing to the production eToro database) for the presence of the given AffiliateID.

This function exists as part of the incremental migration strategy. Rather than migrating all affiliates at once, each affiliate is migrated individually. Calling code checks this function before routing CPA commission processing to the appropriate system.

---

## 2. Business Logic

### 2.1 Migration Gate Check

**What**: Simple existence check returning a boolean.

**Columns/Parameters Involved**: `@AffiliateID`, `MigratedAffiliates_CPA.AffiliateID`

**Rules**:
- IF EXISTS (SELECT 1 FROM MigratedAffiliates_CPA WHERE AffiliateID = @AffiliateID) -> RETURN 1
- ELSE -> RETURN 0
- Uses WITH (NOLOCK) for non-blocking reads

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int | NO | - | CODE-BACKED | Input: Affiliate ID to check migration status for. |
| 2 | RETURN | bit | NO | - | CODE-BACKED | Output: 1 = affiliate is migrated to new CPA system, 0 = still on legacy system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.MigratedAffiliates_CPA | SELECT | Synonym target for migration check |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used by commission routing logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CheckIfAffiliateWasMigratedForCPA (function)
└── AffiliateCommission.MigratedAffiliates_CPA (synonym)
      └── [AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_CPA] (external table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.MigratedAffiliates_CPA | Synonym | Existence check for AffiliateID |

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
SELECT AffiliateCommission.CheckIfAffiliateWasMigratedForCPA(12345) AS IsMigrated;
```

### 8.2 Filter affiliates by migration status
```sql
SELECT a.AffiliateID, a.Name,
       AffiliateCommission.CheckIfAffiliateWasMigratedForCPA(a.AffiliateID) AS CPAMigrated
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
WHERE a.AffiliateID IN (100, 200, 300);
```

### 8.3 Check all three migration domains
```sql
SELECT
    AffiliateCommission.CheckIfAffiliateWasMigratedForCPA(12345) AS CPA,
    AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration(12345) AS Registration,
    AffiliateCommission.CheckIfAffiliateWasMigratedForSales(12345) AS Sales;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CheckIfAffiliateWasMigratedForCPA | Type: Scalar Function | Source: fiktivo/AffiliateCommission/Functions/AffiliateCommission.CheckIfAffiliateWasMigratedForCPA.sql*
