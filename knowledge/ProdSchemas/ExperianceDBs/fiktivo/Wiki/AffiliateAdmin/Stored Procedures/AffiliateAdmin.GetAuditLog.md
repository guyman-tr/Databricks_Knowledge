# AffiliateAdmin.GetAuditLog

> Returns a paginated, sortable audit log with date range filtering, enriched with user names and action descriptions.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Paginated audit log entries with total count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetAuditLog retrieves a paginated listing of audit trail records from the system. Each entry is enriched with the performing user's name (from `tblaff_User`) and the action description (from `Dictionary.Action`). It supports filtering by date range, audit section, and free-text search, with configurable sorting and pagination.

**WHY:** Audit logging is a critical compliance and operational requirement for the affiliate administration platform. Administrators need to review who performed what actions, when, and on which sections of the system. This procedure provides the backbone for the audit log viewer, enabling investigation of changes, troubleshooting, and regulatory compliance reviews.

**HOW:** The procedure joins `AuditLog` with `tblaff_User` (for UserName resolution) and `Dictionary.Action` (for human-readable action names such as Insert, Update, Delete). It applies filters for @FromDate, @ToDate, @SectionIndex, and @SearchExpression. Results are paginated via @PageID and @PageSize, with dynamic sorting controlled by @SortColumn and @SortType. Two result sets are returned: total count and paginated rows.

---

## 2. Business Logic

### 2.1 Date Range Filtering
The @FromDate and @ToDate parameters define the time window for audit log retrieval. Both are DATETIME parameters allowing precise time-based filtering for investigation scenarios.

### 2.2 Section Filtering
The @SectionIndex parameter filters audit entries by the section of the system where the change occurred. Section values correspond to entries in `Dictionary.ChangedSections`. See Changed Sections glossary for available section IDs.

### 2.3 Action Resolution
The procedure joins with `Dictionary.Action` to resolve numeric action codes to human-readable names. See Action glossary: 1=Insert, 2=Update, 3=Delete.

### 2.4 User Resolution
User names are resolved by joining with `tblaff_User`, providing the display name of the administrator who performed each audited action.

### 2.5 Pagination and Sorting
Server-side pagination uses @PageID (zero-based) and @PageSize. Dynamic sorting defaults to AuditID ascending, which provides chronological ordering. The first result set returns the total count for pagination controls.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | No | - | CODE-BACKED | Start of the date range filter for audit entries |
| 2 | @ToDate | DATETIME | No | - | CODE-BACKED | End of the date range filter for audit entries |
| 3 | @PageID | INT | No | 0 | CODE-BACKED | Zero-based page index for pagination |
| 4 | @PageSize | INT | No | 10 | CODE-BACKED | Number of rows per page |
| 5 | @SectionIndex | INT | No | - | CODE-BACKED | Filter by audit section (from Dictionary.ChangedSections) |
| 6 | @SearchExpression | NVARCHAR | Yes | NULL | CODE-BACKED | Free-text search filter across audit fields |
| 7 | @SortColumn | NVARCHAR | No | 'AuditID' | CODE-BACKED | Column name to sort results by |
| 8 | @SortType | NVARCHAR | No | 'ASC' | CODE-BACKED | Sort direction: ASC or DESC |

**Result Set 1:** Total count of matching audit records (INT) (CODE-BACKED)
**Result Set 2:** Paginated audit rows with AuditID, UserName, Action name, section, details, timestamp (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.AuditLog` | Table | Primary data source for audit entries |
| `dbo.tblaff_User` | Table | JOIN for user name resolution |
| `Dictionary.Action` | Table | JOIN for action name resolution |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Audit log viewer | Application | Main audit trail review screen |
| Compliance reporting | Application | Regulatory audit investigation |

---

## 6. Dependencies

### 6.0 Chain
`GetAuditLog` -> `AuditLog` + `tblaff_User` + `Dictionary.Action`

### 6.1 Depends On
- `dbo.AuditLog` - Primary audit data source
- `dbo.tblaff_User` - User name resolution
- `Dictionary.Action` - Action type descriptions. See Action glossary: 1=Insert, 2=Update, 3=Delete.

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
-- 1. Get first page of audit log for the last 7 days
EXEC AffiliateAdmin.GetAuditLog
    @FromDate = '2026-04-05',
    @ToDate = '2026-04-12',
    @PageID = 0,
    @PageSize = 25,
    @SectionIndex = 0,
    @SortColumn = 'AuditID',
    @SortType = 'DESC';
```

```sql
-- 2. Search audit log for specific user actions in a section
EXEC AffiliateAdmin.GetAuditLog
    @FromDate = '2026-01-01',
    @ToDate = '2026-04-12',
    @PageID = 0,
    @PageSize = 50,
    @SectionIndex = 3,
    @SearchExpression = N'admin@example.com',
    @SortColumn = 'AuditID',
    @SortType = 'DESC';
```

```sql
-- 3. Get second page of results sorted by date
EXEC AffiliateAdmin.GetAuditLog
    @FromDate = '2026-03-01',
    @ToDate = '2026-04-12',
    @PageID = 1,
    @PageSize = 20,
    @SectionIndex = 0,
    @SortColumn = 'AuditID',
    @SortType = 'ASC';
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4214.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAuditLog | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAuditLog.sql*
