# dbo.tblaff_AffiliateTypeCategories

> Junction table mapping which banner/media categories are available to affiliates on each commission plan (affiliate type).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | CategoryID + AffiliateTypeID (no explicit PK - heap with indexes) |
| **Partition** | No |
| **Indexes** | 2 active (nonclustered on AffiliateTypeID, nonclustered on CategoryID) |

---

## 1. Business Meaning

This table controls which banner categories affiliates can access based on their assigned commission plan. It implements a many-to-many relationship between [tblaff_AffiliateTypes](dbo.tblaff_AffiliateTypes.md) and [tblaff_Categories](dbo.tblaff_Categories.md), enabling fine-grained control over which marketing materials are visible to which affiliate tiers.

Without this table, all affiliates would see all banner categories regardless of their plan. This is important because premium affiliates may have access to exclusive creative assets, while basic affiliates see only standard materials. Currently 31,299 mappings exist.

Referential integrity is enforced by triggers (not FK constraints): insert/update triggers validate that both the CategoryID and AffiliateTypeID exist in their parent tables, raising error 60090 on violation.

---

## 2. Business Logic

### 2.1 Trigger-Enforced Referential Integrity

**What**: INSERT and UPDATE triggers enforce FK-like constraints without actual FK constraints.

**Columns/Parameters Involved**: `CategoryID`, `AffiliateTypeID`

**Rules**:
- INSERT trigger (tblaff_AffiliateTypeCate_ITrig): validates CategoryID exists in [tblaff_Categories](dbo.tblaff_Categories.md) AND AffiliateTypeID exists in [tblaff_AffiliateTypes](dbo.tblaff_AffiliateTypes.md)
- UPDATE trigger (tblaff_AffiliateTypeCate_UTrig): same validation on updates
- Failure raises RAISERROR 60090 and rolls back the transaction
- CASCADE DELETE is handled by tblaff_Categories_DTrig (deleting a category cascade-deletes its mappings here)

---

## 3. Data Overview

N/A - Junction table. See element descriptions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CategoryID | int | YES | 0 | CODE-BACKED | References [dbo.tblaff_Categories](dbo.tblaff_Categories.md).CategoryID. The banner category being granted to the affiliate type. Trigger-enforced FK. |
| 2 | AffiliateTypeID | int | YES | 0 | CODE-BACKED | References [dbo.tblaff_AffiliateTypes](dbo.tblaff_AffiliateTypes.md).AffiliateTypeID. The commission plan whose affiliates can see this category. Trigger-enforced FK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CategoryID | [dbo.tblaff_Categories](dbo.tblaff_Categories.md) | Trigger-FK | Banner category being granted. |
| AffiliateTypeID | [dbo.tblaff_AffiliateTypes](dbo.tblaff_AffiliateTypes.md) | Trigger-FK | Commission plan receiving access. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no hard dependencies (trigger-enforced, not DDL FK).

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| AffiliateTypeID | NC | AffiliateTypeID | - | - | Active |
| CategoryID | NC | CategoryID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_AffiliateTypeCategories_CategoryID | DEFAULT | 0 |
| DF_tblaff_AffiliateTypeCategories_AffiliateTypeID | DEFAULT | 0 |
| tblaff_AffiliateTypeCate_ITrig | TRIGGER (INSERT) | Validates both FKs exist |
| tblaff_AffiliateTypeCate_UTrig | TRIGGER (UPDATE) | Validates both FKs on update |

---

## 8. Sample Queries

### 8.1 List categories available to a specific affiliate type
```sql
SELECT c.CategoryID, c.CategoryName
FROM dbo.tblaff_AffiliateTypeCategories atc WITH (NOLOCK)
JOIN dbo.tblaff_Categories c WITH (NOLOCK) ON atc.CategoryID = c.CategoryID
WHERE atc.AffiliateTypeID = 2
ORDER BY c.CategoryName
```

### 8.2 Find affiliate types that have access to a specific category
```sql
SELECT at.AffiliateTypeID, at.Description
FROM dbo.tblaff_AffiliateTypeCategories atc WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON atc.AffiliateTypeID = at.AffiliateTypeID
WHERE atc.CategoryID = 11
ORDER BY at.Description
```

### 8.3 Count categories per affiliate type
```sql
SELECT at.AffiliateTypeID, at.Description, COUNT(atc.CategoryID) AS CategoryCount
FROM dbo.tblaff_AffiliateTypes at WITH (NOLOCK)
LEFT JOIN dbo.tblaff_AffiliateTypeCategories atc WITH (NOLOCK) ON at.AffiliateTypeID = atc.AffiliateTypeID
WHERE at.IsActive = 1
GROUP BY at.AffiliateTypeID, at.Description
ORDER BY CategoryCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_AffiliateTypeCategories | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_AffiliateTypeCategories.sql*
