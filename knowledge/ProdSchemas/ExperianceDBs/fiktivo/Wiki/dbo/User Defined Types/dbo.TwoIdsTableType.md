# dbo.TwoIdsTableType

> Table-valued parameter type for passing pairs of integer IDs, used for bulk update operations on banners (priority and archive status).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | ID1 + ID2 pair (both INT, nullable, no PK) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This table type enables stored procedures to accept pairs of integer identifiers for bulk operations. The primary known use case is banner management - passing (BannerID, new value) pairs for batch updates to banner priority ordering and archive status.

Both columns are nullable, providing maximum flexibility for different use cases where one of the pair values might be optional. No primary key or uniqueness constraint exists, allowing the same pair to appear multiple times if needed.

Known consumers: `AffiliateAdmin.UpdateBannersPriority` (ID1=BannerID, ID2=Priority), `AffiliateAdmin.UpdateBannersArchive` (ID1=BannerID, ID2=ArchiveFlag).

---

## 2. Business Logic

### 2.1 Banner Bulk Update Pattern

**What**: Pairs of (BannerID, NewValue) are sent to update multiple banners in a single database round-trip.

**Columns/Parameters Involved**: `ID1`, `ID2`

**Rules**:
- In UpdateBannersPriority: ID1 = BannerID, ID2 = new priority/display order value
- In UpdateBannersArchive: ID1 = BannerID, ID2 = archive flag (1=archive, 0=unarchive)
- The admin UI sends all changes in a single batch rather than one call per banner

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID1 | int | YES | - | VERIFIED | First integer in the pair. Typically the entity identifier (e.g., BannerID). Nullable to support optional-first-ID scenarios. |
| 2 | ID2 | int | YES | - | VERIFIED | Second integer in the pair. Typically the new value to apply (e.g., priority rank, archive flag). Nullable to support optional-value scenarios. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.UpdateBannersPriority | Parameter | Parameter | Passes (BannerID, Priority) pairs for bulk priority reordering |
| AffiliateAdmin.UpdateBannersArchive | Parameter | Parameter | Passes (BannerID, ArchiveFlag) pairs for bulk archive/unarchive |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.UpdateBannersPriority | Stored Procedure | Parameter type for bulk banner priority updates |
| AffiliateAdmin.UpdateBannersArchive | Stored Procedure | Parameter type for bulk banner archive operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for banner priority update
```sql
DECLARE @bannerUpdates dbo.TwoIdsTableType
INSERT INTO @bannerUpdates (ID1, ID2)
VALUES (101, 1), (102, 2), (103, 3)  -- BannerID, NewPriority
```

### 8.2 Declare and populate for banner archive
```sql
DECLARE @archiveUpdates dbo.TwoIdsTableType
INSERT INTO @archiveUpdates (ID1, ID2)
VALUES (101, 1), (102, 1), (103, 0)  -- BannerID, ArchiveFlag (1=archive)
```

### 8.3 Use with a banner update procedure
```sql
DECLARE @updates dbo.TwoIdsTableType
INSERT INTO @updates (ID1, ID2) VALUES (101, 5), (102, 10)
EXEC AffiliateAdmin.UpdateBannersPriority @BannerPriorities = @updates
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TwoIdsTableType | Type: User Defined Type | Source: fiktivo/dbo/User Defined Types/dbo.TwoIdsTableType.sql*
