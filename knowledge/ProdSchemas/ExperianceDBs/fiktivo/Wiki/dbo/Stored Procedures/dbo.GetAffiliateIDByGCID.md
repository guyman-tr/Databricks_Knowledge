# dbo.GetAffiliateIDByGCID

> Returns the AffiliateID and GCID for an affiliate identified by their Global Customer ID (GCID).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | GCID (Global Customer ID lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves an affiliate's internal AffiliateID from their GCID (Global Customer ID), which is the cross-system customer identifier used in the eToro ecosystem. It is called when an external or upstream system has a GCID and needs to determine the corresponding AffiliateID to perform affiliate-specific operations or lookups. The GCID represents the affiliate's identity in the broader eToro platform (not just the affiliate management system).

---

## 2. Business Logic

- Simple single-table SELECT against dbo.tblaff_Affiliates with NOLOCK.
- Filters on the GCID column and returns AffiliateID and GCID.
- No joins, no conditional logic.
- SET NOCOUNT ON suppresses rowcount messages.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @GCID | INT | IN | (required) | High | Global Customer ID used to locate the affiliate |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_Affiliates | Read | Resolves AffiliateID from the GCID column |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateIDByGCID
  └── dbo.tblaff_Affiliates   (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Affiliates | Table | Source table for GCID-to-AffiliateID resolution |

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
-- Look up an affiliate's ID by GCID
EXEC dbo.GetAffiliateIDByGCID @GCID = 987654;

-- Use the result to fetch the full affiliate profile
DECLARE @AffID INT;
SELECT @AffID = AffiliateID FROM dbo.tblaff_Affiliates WHERE GCID = 987654;
EXEC dbo.GetAffiliateById @Id = @AffID;

-- Verify GCID mapping for a known affiliate
EXEC dbo.GetAffiliateIDByGCID @GCID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAffiliateIDByGCID | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateIDByGCID.sql*
