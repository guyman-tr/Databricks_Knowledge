# dbo.GetSlabsPerAffiliateType

> Returns the three deposit slab upper-boundary values for a specific affiliate type from tblaff_AffiliateTypes.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Gonen Frim |
| **Created** | 2015-11-30 |

---

## 1. Business Meaning

The CPA commission model uses deposit slabs to tier commission rates. Each slab has an upper boundary value (the "to" amount) that defines the top of that deposit band. This procedure retrieves the three upper-boundary values (DepositSlab1To, DepositSlab2To, DepositSlab3To) for a given affiliate type.

These boundaries work in conjunction with the slab amounts from dbo.GetSlabAmountsPerAffiliateType: the "To" values define the upper limit of each band, while the "Amount" values define the corresponding commission rates. Together they provide the complete slab mapping needed to classify a customer deposit and assign the correct CPA commission.

---

## 2. Business Logic

### 2.1 Slab Boundary Lookup

**What**: Returns the three slab upper-boundary values for the specified affiliate type.

**Columns/Parameters Involved**: `@AffiliateTypeID`, `DepositSlab1To`, `DepositSlab2To`, `DepositSlab3To`

**Rules**:
- WHERE AffiliateTypeID = @AffiliateTypeID: returns at most one row
- If no matching AffiliateTypeID exists, zero rows are returned
- Three boundary values are returned; a fourth slab (the catch-all for deposits above DepositSlab3To) uses the amount from DepositSlab4Amount in dbo.GetSlabAmountsPerAffiliateType
- NULL boundary values indicate that fewer than three explicit slab thresholds are configured

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @AffiliateTypeID | IN | int | (required) | The affiliate type for which to retrieve the deposit slab upper-boundary values. References dbo.tblaff_AffiliateTypes.AffiliateTypeID. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_AffiliateTypes | SELECT | Source of slab upper-boundary configuration |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| DepositSlab1To | tblaff_AffiliateTypes | Upper boundary of deposit slab 1 (deposits at or below this value fall in slab 1) |
| DepositSlab2To | tblaff_AffiliateTypes | Upper boundary of deposit slab 2 |
| DepositSlab3To | tblaff_AffiliateTypes | Upper boundary of deposit slab 3 (deposits above this fall in slab 4) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetSlabsPerAffiliateType (stored procedure)
+-- dbo.tblaff_AffiliateTypes (table) [SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table | Source of slab boundary configuration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CPA commission calculation service | Application | Retrieves slab boundaries to classify deposits into commission tiers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- No SET NOCOUNT ON; callers receive rowcount messages
- WITH (NOLOCK) applied; suitable for a stable reference table
- Returns three slab "To" boundaries; the fourth slab (catch-all) has no upper boundary
- Compare with dbo.GetSlabAmountsPerAffiliateType, which returns the four commission amounts (DepositSlab1Amount through DepositSlab4Amount)
- Note: three "To" boundaries but four "Amount" values reflects the slab design: deposits above DepositSlab3To fall into slab 4, which has an amount but no upper boundary

---

## 8. Sample Queries

### 8.1 Get slab boundaries for affiliate type 3

```sql
EXEC dbo.GetSlabsPerAffiliateType @AffiliateTypeID = 3;
```

### 8.2 View both slab boundaries and amounts together

```sql
SELECT AffiliateTypeID,
       DepositSlab1To, DepositSlab1Amount,
       DepositSlab2To, DepositSlab2Amount,
       DepositSlab3To, DepositSlab3Amount,
       DepositSlab4Amount
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE AffiliateTypeID = 3;
```

### 8.3 Classify a deposit using slab boundaries

```sql
DECLARE @DepositAmount DECIMAL(18,2) = 750;
SELECT
    CASE
        WHEN @DepositAmount <= DepositSlab1To THEN DepositSlab1Amount
        WHEN @DepositAmount <= DepositSlab2To THEN DepositSlab2Amount
        WHEN @DepositAmount <= DepositSlab3To THEN DepositSlab3Amount
        ELSE DepositSlab4Amount
    END AS CPACommission
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE AffiliateTypeID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetSlabsPerAffiliateType | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetSlabsPerAffiliateType.sql*
