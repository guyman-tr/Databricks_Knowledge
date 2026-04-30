# AffiliateCommission.GetOrganicAffiliates

> Returns the list of affiliate IDs classified as "organic" (group ID 126), used to identify non-paid affiliate registrations for attribution processing.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns AffiliateID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetOrganicAffiliates retrieves all affiliates belonging to the "organic" group (AffiliatesGroupsID = 126). Organic affiliates represent unpaid/natural registrations - customers who signed up without being referred by a paid affiliate partner. The commission system uses this list to distinguish between organic and paid-affiliate-driven registrations during attribution processing.

This procedure exists because the commission engine needs to identify organic registrations for special handling. When a registration event's NonOrganicUpdated flag changes (indicating the customer was initially organic but later re-attributed to a paid affiliate, or vice versa), the engine needs the organic affiliate list to process the change correctly.

---

## 2. Business Logic

### 2.1 Organic Group Identification

**What**: Retrieves affiliates in the hardcoded organic group (ID 126).

**Columns/Parameters Involved**: `AffiliatesGroupsID`

**Rules**:
- AffiliatesGroupsID = 126 is the organic affiliate group (hardcoded)
- Returns all AffiliateIDs in this group
- These IDs are used as a lookup to identify organic registrations in the commission pipeline
- The organic group designation is managed externally in the affiliate admin system

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | - | - | CODE-BACKED | Affiliate IDs belonging to the organic group (AffiliatesGroupsID = 126). Used to identify unpaid/natural registrations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_Affiliates | READ (SELECT) | Filters by AffiliatesGroupsID = 126 |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the attribution processing service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetOrganicAffiliates (procedure)
+-- dbo.tblaff_Affiliates (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table (external) | SELECT WHERE AffiliatesGroupsID = 126 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Attribution processing service) | External | Loads organic affiliate list for attribution decisions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all organic affiliates
```sql
EXEC [AffiliateCommission].[GetOrganicAffiliates]
```

### 8.2 Check if a specific affiliate is organic
```sql
SELECT AffiliateID, AffiliatesGroupsID
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
WHERE AffiliateID = 3
```

### 8.3 Count affiliates per group
```sql
SELECT AffiliatesGroupsID, COUNT(*) AS AffiliateCount
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
GROUP BY AffiliatesGroupsID
ORDER BY AffiliateCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetOrganicAffiliates | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetOrganicAffiliates.sql*
