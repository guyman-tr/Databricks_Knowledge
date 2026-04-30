# dbo.GetAnnouncementsAffiliateTypes

> Returns all rows from the announcement-to-affiliate-type mapping table, providing the full cross-reference of which announcements target which affiliate types.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

Announcements can be targeted to specific affiliate types. The tblaff_Announcement_AffiliateType table is the mapping table that records each announcement-to-affiliate-type pairing. This procedure returns the entire contents of that table, enabling the application layer to perform in-memory filtering or to build a complete picture of all announcement targeting rules.

This all-rows retrieval pattern is common for small reference or mapping tables that are loaded once and cached by the application. The calling layer can then determine, for any given affiliate type, which announcements apply to it without issuing additional per-type queries.

---

## 2. Business Logic

### 2.1 Full Table Scan of Mapping Table

**What**: Returns every announcement-to-affiliate-type relationship row with no filtering.

**Columns/Parameters Involved**: `ID`, `AnnouncementID`, `AffiliateTypeID`

**Rules**:
- No parameters; the procedure always returns all rows
- Each row represents one directed relationship: a specific announcement targets a specific affiliate type
- If an announcement has no rows in this table, it is considered untargeted (applies to all types by default, or is handled by the caller's business logic)
- The result set is used for bulk load and cache population; no pagination is implemented

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure accepts no parameters.

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| - | (none) | - | - | - | No parameters; returns all rows unconditionally. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Announcement_AffiliateType | SELECT | Full table scan; all mapping rows are returned |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| ID | tblaff_Announcement_AffiliateType | Primary key of the mapping row |
| AnnouncementID | tblaff_Announcement_AffiliateType | Foreign key to tblaff_Announcement |
| AffiliateTypeID | tblaff_Announcement_AffiliateType | Foreign key to the affiliate type that this announcement targets |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAnnouncementsAffiliateTypes (stored procedure)
+-- dbo.tblaff_Announcement_AffiliateType (table) [SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Announcement_AffiliateType | Table | Sole data source; all rows returned |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application announcement cache | Application | Loads this procedure once to build an in-memory announcement-type map |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- WITH (NOLOCK) hint applied; suitable for a small, low-churn mapping table
- No parameters and no WHERE clause; the entire table is always returned
- Consider using dbo.GetAnnouncementById for single-announcement targeting lookups

---

## 8. Sample Queries

### 8.1 Return all announcement-to-affiliate-type mappings

```sql
EXEC dbo.GetAnnouncementsAffiliateTypes;
```

### 8.2 Find all announcements targeting a specific affiliate type

```sql
SELECT AnnouncementID
FROM dbo.tblaff_Announcement_AffiliateType WITH (NOLOCK)
WHERE AffiliateTypeID = 2;
```

### 8.3 Count targeting rows per announcement

```sql
SELECT AnnouncementID, COUNT(*) AS TargetTypeCount
FROM dbo.tblaff_Announcement_AffiliateType WITH (NOLOCK)
GROUP BY AnnouncementID
ORDER BY AnnouncementID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetAnnouncementsAffiliateTypes | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAnnouncementsAffiliateTypes.sql*
