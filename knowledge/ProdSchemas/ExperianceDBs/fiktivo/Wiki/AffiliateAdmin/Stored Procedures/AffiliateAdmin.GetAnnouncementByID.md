# AffiliateAdmin.GetAnnouncementByID

> Retrieves a single announcement by ID along with its targeted affiliate type associations in two result sets.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Announcement details + targeted AffiliateTypeIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetAnnouncementByID retrieves a single announcement record and its associated affiliate type targeting. The first result set contains the full announcement details from `tblaff_Announcement`, and the second result set returns the list of AffiliateTypeIDs from `tblaff_Announcement_AffiliateType` that the announcement is targeted to.

**WHY:** Announcements in the affiliate platform can be targeted to specific affiliate types, meaning not all affiliates see the same announcements. When an administrator opens an announcement for viewing or editing, the system needs both the announcement content and its targeting configuration. Returning both in a single call supports efficient form population in the admin UI.

**HOW:** The procedure accepts an @ID parameter identifying the announcement, then executes two SELECT statements. The first retrieves announcement details (title, content, dates, active status) from `tblaff_Announcement` filtered by the given ID. The second retrieves all AffiliateTypeID values from `tblaff_Announcement_AffiliateType` for the same announcement, providing the targeting information.

---

## 2. Business Logic

### 2.1 Announcement Retrieval
The first result set fetches the complete announcement record by primary key lookup. This includes all announcement metadata such as title, body, creation date, active/inactive status, and display dates.

### 2.2 Affiliate Type Targeting
The second result set returns the AffiliateTypeIDs associated with the announcement. This represents the targeting configuration: only affiliates whose type matches one of the returned IDs should see this announcement. If no rows are returned in the second result set, the announcement may be untargeted (visible to all).

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | INT | No | - | CODE-BACKED | The unique identifier of the announcement to retrieve |

**Result Set 1:** All columns from `tblaff_Announcement` for the specified ID (CODE-BACKED)
**Result Set 2:** AffiliateTypeID (INT) from `tblaff_Announcement_AffiliateType` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Announcement` | Table | SELECT announcement details by ID |
| `dbo.tblaff_Announcement_AffiliateType` | Table | SELECT targeted affiliate types |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Announcement edit screen | Application | Loads announcement data for editing |
| Announcement detail view | Application | Displays announcement content and targeting |

---

## 6. Dependencies

### 6.0 Chain
`GetAnnouncementByID` -> `tblaff_Announcement`, `tblaff_Announcement_AffiliateType`

### 6.1 Depends On
- `dbo.tblaff_Announcement` - Source table for announcement content
- `dbo.tblaff_Announcement_AffiliateType` - Junction table for announcement-to-affiliate-type targeting

### 6.2 Depend On This
No known database dependencies. Called from application layer.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get announcement ID 42 with its targeting
EXEC AffiliateAdmin.GetAnnouncementByID @ID = 42;
```

```sql
-- 2. Load announcement for edit form population
EXEC AffiliateAdmin.GetAnnouncementByID @ID = 100;
-- First result set populates form fields
-- Second result set populates affiliate type checkboxes
```

```sql
-- 3. Verify announcement targeting after update
EXEC AffiliateAdmin.GetAnnouncementByID @ID = 42;
-- Check second result set to confirm affiliate type IDs
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4678.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAnnouncementByID | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAnnouncementByID.sql*
