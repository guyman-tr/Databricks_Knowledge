# History.tblaff_CPACountriesToAffiliateTypeID

> SQL Server temporal history table storing all historical versions of the CPA country-to-affiliate-type mapping, which controls country-specific CPA eligibility for each affiliate plan.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateTypeID + CountryID (composite) - identifies the mapping across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.tblaff_CPACountriesToAffiliateTypeID is the system-versioned temporal history table for dbo.tblaff_CPACountriesToAffiliateTypeID. It captures historical versions of the mapping between affiliate types and countries eligible for CPA (Cost Per Acquisition) commission. This mapping determines which countries qualify for CPA payouts under each affiliate plan.

This table supports auditing of CPA eligibility changes. When an affiliate disputes why a customer from a specific country did or did not generate a CPA commission, temporal queries reveal whether that country was mapped to the affiliate's type at the time of the event.

Currently contains 0 rows, indicating either no CPA country mappings have been modified since temporal versioning was enabled, or the feature is not actively used in this environment.

---

## 2. Business Logic

### 2.1 Country-Level CPA Eligibility

**What**: Controls which countries are eligible for CPA commission under each affiliate type.

**Columns/Parameters Involved**: `AffiliateTypeID`, `CountryID`

**Rules**:
- Each row represents one country eligible for CPA under one affiliate type
- If a country is NOT in this mapping for an affiliate type, customers from that country do not generate CPA commission for affiliates on that plan
- When a country is removed from CPA eligibility, the row moves to this history table
- AffiliateTypeID references dbo.tblaff_AffiliateTypes

---

## 3. Data Overview

Table is currently empty (0 rows). No CPA country mappings have been modified since temporal versioning was enabled.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateTypeID | int | NO | - | CODE-BACKED | The affiliate type this CPA country mapping applies to. References dbo.tblaff_AffiliateTypes.AffiliateTypeID. |
| 2 | CountryID | int | NO | - | CODE-BACKED | The country eligible for CPA commission under this affiliate type. |
| 3 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this mapping became active. Set by SQL Server temporal mechanism. |
| 4 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this mapping was superseded or removed. Set by SQL Server temporal mechanism. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | dbo.tblaff_CPACountriesToAffiliateTypeID | Temporal History | Stores historical versions of the base table |
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit FK | The affiliate type plan this CPA country mapping belongs to |

### 5.2 Referenced By (other objects point to this)

This table is accessed implicitly via temporal queries on dbo.tblaff_CPACountriesToAffiliateTypeID.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.tblaff_CPACountriesToAffiliateTypeID (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CPACountriesToAffiliateTypeID | Table | SYSTEM_VERSIONING - superseded versions stored here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_tblaff_CPACountriesToAffiliateTypeID | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View CPA country mapping history for an affiliate type
```sql
SELECT AffiliateTypeID, CountryID, ValidFrom, ValidTo
FROM dbo.tblaff_CPACountriesToAffiliateTypeID FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateTypeID = 741
ORDER BY ValidFrom
```

### 8.2 Check CPA-eligible countries at a point in time
```sql
SELECT cpa.AffiliateTypeID, at.Description, cpa.CountryID
FROM dbo.tblaff_CPACountriesToAffiliateTypeID FOR SYSTEM_TIME AS OF '2025-06-01' cpa WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON cpa.AffiliateTypeID = at.AffiliateTypeID
ORDER BY cpa.AffiliateTypeID, cpa.CountryID
```

### 8.3 Check if history table has any records
```sql
SELECT COUNT(*) AS HistoryRows
FROM History.tblaff_CPACountriesToAffiliateTypeID WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.1/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.tblaff_CPACountriesToAffiliateTypeID | Type: Table | Source: fiktivo/History/Tables/History.tblaff_CPACountriesToAffiliateTypeID.sql*
