# dbo.GetAffiliatePullInformationByAffiliateID

> Returns the commission plan description for a given affiliate by joining the affiliate record to its affiliate type.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the "pull" information for an affiliate, specifically the commission plan description (aliased as commissionPlan). It is used by external or consumer systems that need to know which commission plan an affiliate is assigned to, without loading the full affiliate profile. The naming convention "Pull" reflects the data direction: the application pulls plan information from the database. Created by Gonen Frim (Nov 2015), added to production by Geri Reshef (Jan 2016, ticket 32340).

---

## 2. Business Logic

- Simple two-table JOIN: tblaff_Affiliates (INNER JOIN) tblaff_AffiliateTypes on AffiliateTypeID.
- Returns only the Description column from tblaff_AffiliateTypes, aliased as commissionPlan.
- Uses NOLOCK hints on both tables.
- No NOCOUNT, no transaction, no error handling - minimal read-only SP.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | IN | (required) | High | Affiliate whose commission plan description is being fetched |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | dbo.tblaff_Affiliates | Read | Provides the AffiliateTypeID link |
| JOIN | dbo.tblaff_AffiliateTypes | Read | Source of the Description (commission plan name) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliatePullInformationByAffiliateID
  ├── dbo.tblaff_Affiliates       (READ)
  └── dbo.tblaff_AffiliateTypes   (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Affiliates | Table | Provides the AffiliateTypeID for the given affiliate |
| dbo.tblaff_AffiliateTypes | Table | Source of the commission plan description |

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
-- Get commission plan for affiliate 12345
EXEC dbo.GetAffiliatePullInformationByAffiliateID @AffiliateID = 12345;

-- Check plan assignment for a bulk verification
EXEC dbo.GetAffiliatePullInformationByAffiliateID @AffiliateID = 1001;

-- Use in a broader lookup context
DECLARE @Plan VARCHAR(200);
SELECT @Plan = AT.Description
FROM dbo.tblaff_Affiliates A WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes AT WITH (NOLOCK) ON A.AffiliateTypeID = AT.AffiliateTypeID
WHERE A.AffiliateID = 12345;
PRINT @Plan;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.
*(Author notes: Gonen Frim, 30/11/2015; Geri Reshef, 24/01/2016, ticket 32340.)*

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAffiliatePullInformationByAffiliateID | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliatePullInformationByAffiliateID.sql*
