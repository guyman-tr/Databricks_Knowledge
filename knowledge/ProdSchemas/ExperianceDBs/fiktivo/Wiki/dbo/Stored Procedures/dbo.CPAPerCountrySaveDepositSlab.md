# dbo.CPAPerCountrySaveDepositSlab

> Updates the deposit slab thresholds and CPA payout amounts for a specified affiliate type plan.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateTypeID (target plan) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure modifies the deposit slab configuration on an affiliate commission plan (AffiliateType). The deposit slab defines tiered CPA payout amounts based on how many deposits a customer makes within a given period. Three threshold columns (DepositSlab1To, DepositSlab2To, DepositSlab3To) mark the upper boundary of each band, and four amount columns (DepositSlab1Amount through DepositSlab4Amount) set the dollar payout for each band. It is called by the admin/partner portal whenever a plan manager adjusts the deposit-based CPA tiers for a specific plan.

---

## 2. Business Logic

- Single UPDATE against dbo.tblaff_AffiliateTypes filtered by AffiliateTypeID.
- All seven slab fields are unconditionally overwritten with the supplied values; there is no partial-update logic.
- No transaction wrapper is present; the single statement is atomic by default.
- No audit log entry is written by this procedure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @DepositSlab1To | INTEGER | IN | (required) | High | Upper boundary (number of deposits) for slab 1 |
| 2 | @DepositSlab2To | INTEGER | IN | (required) | High | Upper boundary for slab 2 |
| 3 | @DepositSlab3To | INTEGER | IN | (required) | High | Upper boundary for slab 3 |
| 4 | @DepositSlab1Amount | INTEGER | IN | (required) | High | CPA payout amount for deposits in slab 1 |
| 5 | @DepositSlab2Amount | INTEGER | IN | (required) | High | CPA payout amount for deposits in slab 2 |
| 6 | @DepositSlab3Amount | INTEGER | IN | (required) | High | CPA payout amount for deposits in slab 3 |
| 7 | @DepositSlab4Amount | INTEGER | IN | (required) | High | CPA payout amount for deposits above slab 3 |
| 8 | @AffiliateTypeID | INTEGER | IN | (required) | High | Primary key of the affiliate plan to update |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | dbo.tblaff_AffiliateTypes | Write | Updates deposit slab columns on the matching plan row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CPAPerCountrySaveDepositSlab
  └── dbo.tblaff_AffiliateTypes  (WRITE)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_AffiliateTypes | Table | Updated to store new slab thresholds and amounts |

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
-- Update deposit slabs for affiliate type 42
EXEC dbo.CPAPerCountrySaveDepositSlab
    @DepositSlab1To      = 1,
    @DepositSlab2To      = 3,
    @DepositSlab3To      = 9,
    @DepositSlab1Amount  = 200,
    @DepositSlab2Amount  = 300,
    @DepositSlab3Amount  = 400,
    @DepositSlab4Amount  = 500,
    @AffiliateTypeID     = 42;

-- Reset all slabs to flat rate for a basic plan
EXEC dbo.CPAPerCountrySaveDepositSlab
    @DepositSlab1To      = 0,
    @DepositSlab2To      = 0,
    @DepositSlab3To      = 0,
    @DepositSlab1Amount  = 150,
    @DepositSlab2Amount  = 150,
    @DepositSlab3Amount  = 150,
    @DepositSlab4Amount  = 150,
    @AffiliateTypeID     = 10;

-- Verify change after update
SELECT AffiliateTypeID, DepositSlab1To, DepositSlab2To, DepositSlab3To,
       DepositSlab1Amount, DepositSlab2Amount, DepositSlab3Amount, DepositSlab4Amount
FROM dbo.tblaff_AffiliateTypes
WHERE AffiliateTypeID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.CPAPerCountrySaveDepositSlab | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.CPAPerCountrySaveDepositSlab.sql*
