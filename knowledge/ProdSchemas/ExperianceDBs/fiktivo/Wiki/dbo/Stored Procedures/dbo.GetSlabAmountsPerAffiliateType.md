# dbo.GetSlabAmountsPerAffiliateType

> Returns the four deposit slab threshold amounts for a specific affiliate type from tblaff_AffiliateTypes.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Gonen Frim |
| **Created** | 2015-11-30 |

---

## 1. Business Meaning

The CPA commission model for affiliates uses deposit slabs: bands of deposit amounts that determine which CPA rate applies. Each affiliate type has up to four slab threshold amounts that define the upper boundary of each deposit band. This procedure retrieves those four amount thresholds for a given affiliate type, enabling commission calculation services to determine which slab a customer deposit falls into.

Together with dbo.GetSlabsPerAffiliateType (which returns the slab "to" boundaries rather than the amounts), these two procedures provide the complete slab configuration needed to process CPA commission assignments.

---

## 2. Business Logic

### 2.1 Slab Amount Lookup

**What**: Returns the four deposit slab amount thresholds for the specified affiliate type.

**Columns/Parameters Involved**: `@AffiliateTypeID`, `DepositSlab1Amount`, `DepositSlab2Amount`, `DepositSlab3Amount`, `DepositSlab4Amount`

**Rules**:
- WHERE AffiliateTypeID = @AffiliateTypeID: returns at most one row (AffiliateTypeID is the primary key)
- If no matching AffiliateTypeID exists, zero rows are returned
- The four slab amounts represent the amount thresholds (e.g., the minimum deposit value that qualifies for each slab tier)
- NULL slab amounts indicate that fewer than four slabs are configured for this affiliate type

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @AffiliateTypeID | IN | int | (required) | The affiliate type for which to retrieve the deposit slab amount thresholds. References dbo.tblaff_AffiliateTypes.AffiliateTypeID. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_AffiliateTypes | SELECT | Source of slab amount configuration for the affiliate type |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| DepositSlab1Amount | tblaff_AffiliateTypes | Amount threshold for deposit slab 1 |
| DepositSlab2Amount | tblaff_AffiliateTypes | Amount threshold for deposit slab 2 |
| DepositSlab3Amount | tblaff_AffiliateTypes | Amount threshold for deposit slab 3 |
| DepositSlab4Amount | tblaff_AffiliateTypes | Amount threshold for deposit slab 4 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetSlabAmountsPerAffiliateType (stored procedure)
+-- dbo.tblaff_AffiliateTypes (table) [SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table | Source of slab amount configuration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CPA commission calculation service | Application | Retrieves slab amounts to determine which deposit slab applies for a given deposit value |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- No SET NOCOUNT ON; callers receive rowcount messages
- WITH (NOLOCK) applied; consistent with read-only reference-table pattern
- Always returns at most one row (AffiliateTypeID is the primary key of tblaff_AffiliateTypes)
- Compare with dbo.GetSlabsPerAffiliateType, which returns DepositSlab1To / 2To / 3To boundaries

---

## 8. Sample Queries

### 8.1 Get slab amounts for affiliate type 3

```sql
EXEC dbo.GetSlabAmountsPerAffiliateType @AffiliateTypeID = 3;
```

### 8.2 View slab configuration for all affiliate types

```sql
SELECT AffiliateTypeID,
       DepositSlab1Amount, DepositSlab2Amount,
       DepositSlab3Amount, DepositSlab4Amount
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
ORDER BY AffiliateTypeID;
```

### 8.3 Determine which slab a deposit falls into

```sql
DECLARE @DepositAmount DECIMAL(18,2) = 500;
SELECT
    CASE
        WHEN @DepositAmount <= DepositSlab1Amount THEN 1
        WHEN @DepositAmount <= DepositSlab2Amount THEN 2
        WHEN @DepositAmount <= DepositSlab3Amount THEN 3
        ELSE 4
    END AS SlabTier
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE AffiliateTypeID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetSlabAmountsPerAffiliateType | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetSlabAmountsPerAffiliateType.sql*
