# dbo.GetAffiliateTypeById

> Returns the complete commission plan configuration row from tblaff_AffiliateTypes for a given AffiliateTypeID, including all rate, slab, bonus, and display flag columns.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the canonical lookup for a full affiliate commission plan configuration. It returns all columns of the tblaff_AffiliateTypes table for a single plan, used by the admin and affiliate portal to display and edit plan settings. The table contains over 80 configuration fields covering every dimension of the commission structure: per-deposit, per-sale, per-lead, per-registration, per-click, per-copy-trader, per-first-position rates, slab thresholds and amounts, PNL settings, display flags, cookie behavior, bonus structures, country-specific settings, and plan metadata. It is a central configuration object in the affiliate management system.

---

## 2. Business Logic

- Simple single-table SELECT against dbo.tblaff_AffiliateTypes with NOLOCK.
- Returns all ~85 columns for the row where AffiliateTypeID = @Id.
- No joins, no conditional logic, no transforms.
- Set NoCount On suppresses row-count messages.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @Id | INT | IN | (required) | High | Primary key of the affiliate type/commission plan to retrieve |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_AffiliateTypes | Read | Returns all configuration columns for the matching plan row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateTypeById
  └── dbo.tblaff_AffiliateTypes   (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_AffiliateTypes | Table | Full commission plan configuration table |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Retrieve full plan configuration for AffiliateType 10
EXEC dbo.GetAffiliateTypeById @Id = 10;

-- Check deposit slab settings for a specific plan
EXEC dbo.GetAffiliateTypeById @Id = 42;
-- Inspect DepositSlab1To, DepositSlab2To, DepositSlab3To, DepositSlab1Amount...

-- Load plan 1 (default/base plan)
EXEC dbo.GetAffiliateTypeById @Id = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAffiliateTypeById | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateTypeById.sql*
