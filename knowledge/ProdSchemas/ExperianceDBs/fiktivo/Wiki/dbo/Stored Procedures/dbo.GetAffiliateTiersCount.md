# dbo.GetAffiliateTiersCount

> Returns the count of sub-affiliate members at each tier level (2 through 5) for a given affiliate in a single row.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a quick summary count of how many sub-affiliates exist at each tier below a given affiliate. It is used by the Partners portal to display the affiliate's network size in a compact summary format (e.g., "Tier 2: 15, Tier 3: 42, ...") without returning the full member list. The counts are computed via sequential self-joins on tblaff_Tier2Members, one query per tier, which is straightforward but may be slow for large networks. Created by Ran Ovadia (April 2020).

---

## 2. Business Logic

- Four separate SELECT COUNT(*) queries populate scalar variables @tier2 through @tier5:
  - @tier2: Direct children (one join from root).
  - @tier3: Grandchildren (two joins from root).
  - @tier4: Great-grandchildren (three joins).
  - @tier5: Great-great-grandchildren (four joins).
- Each query uses NOLOCK on all joined instances.
- Final SELECT returns all four counts as named columns (Tier2, Tier3, Tier4, Tier5) in a single row.
- SET NOCOUNT ON suppresses extra result sets.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | IN | (required) | High | Affiliate whose sub-affiliate tier counts are summarized |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT COUNT (x4 queries) | dbo.tblaff_Tier2Members | Read | Self-joined up to 4 times to count members at each tier |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateTiersCount
  └── dbo.tblaff_Tier2Members   (READ, self-joined 1-4 times per query)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Tier2Members | Table | Self-joined in four separate queries to count members at Tier 2, 3, 4, and 5 |

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
-- Get tier counts for affiliate 1000
EXEC dbo.GetAffiliateTiersCount @AffiliateID = 1000;
-- Returns: Tier2, Tier3, Tier4, Tier5 as a single row

-- Use in a summary report
DECLARE @Counts TABLE (Tier2 INT, Tier3 INT, Tier4 INT, Tier5 INT);
INSERT INTO @Counts EXEC dbo.GetAffiliateTiersCount @AffiliateID = 1000;
SELECT Tier2 + Tier3 + Tier4 + Tier5 AS TotalNetwork FROM @Counts;

-- Compare network size between two affiliates
EXEC dbo.GetAffiliateTiersCount @AffiliateID = 5000;
EXEC dbo.GetAffiliateTiersCount @AffiliateID = 6000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.
*(Author note: Ran Ovadia, 14/04/2020 - Create.)*

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAffiliateTiersCount | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateTiersCount.sql*
