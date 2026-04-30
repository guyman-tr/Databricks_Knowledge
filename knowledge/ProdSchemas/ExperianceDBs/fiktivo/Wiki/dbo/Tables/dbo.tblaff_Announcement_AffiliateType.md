# dbo.tblaff_Announcement_AffiliateType

> Junction table targeting announcements to specific affiliate types, enabling selective communication to affiliates on particular commission plans.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 nonclustered covering AnnouncementID+AffiliateTypeID) |

---

## 1. Business Meaning

This table controls which affiliate types (commission plans) receive each announcement. By linking announcements to specific affiliate types, the platform can target communications - e.g., sending a "new CPA rate" announcement only to CPA affiliates, or a "platform update" to all types.

Without this table, all announcements would go to all affiliates regardless of their plan. Currently 26 mappings exist. Rows are cascade-deleted when the parent announcement is deleted (via tblaff_Announcement_DTrig trigger).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A - Junction table. See element descriptions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate key for the mapping row. |
| 2 | AnnouncementID | int | NO | - | CODE-BACKED | References [dbo.tblaff_Announcement](dbo.tblaff_Announcement.md).AnnouncementID. The announcement being targeted. Cascade-deleted via parent trigger. |
| 3 | AffiliateTypeID | int | NO | - | CODE-BACKED | References [dbo.tblaff_AffiliateTypes](dbo.tblaff_AffiliateTypes.md).AffiliateTypeID. The commission plan whose affiliates will see this announcement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AnnouncementID | [dbo.tblaff_Announcement](dbo.tblaff_Announcement.md) | Implicit FK | The parent announcement. |
| AffiliateTypeID | [dbo.tblaff_AffiliateTypes](dbo.tblaff_AffiliateTypes.md) | Implicit FK | Target affiliate type. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no hard dependencies (no explicit FK constraints in DDL).

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetAnnouncementsAffiliateTypes | Stored Procedure | READER |
| dbo.GetAnnouncementsByAffiliateType | Stored Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_Announcement_AffiliateType | CLUSTERED PK | ID | - | - | Active |
| Announcement_AffiliateTypeID_Covered | NC | AnnouncementID, AffiliateTypeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get announcements targeted to a specific affiliate type
```sql
SELECT a.AnnouncementID, a.AnnouncementHeadline, a.AnnouncementDate
FROM dbo.tblaff_Announcement_AffiliateType aat WITH (NOLOCK)
JOIN dbo.tblaff_Announcement a WITH (NOLOCK) ON aat.AnnouncementID = a.AnnouncementID
WHERE aat.AffiliateTypeID = 2
  AND GETDATE() BETWEEN a.AnnouncementDate AND a.AnnouncementExpirationDate
```

### 8.2 List all affiliate types targeted by an announcement
```sql
SELECT at.AffiliateTypeID, at.Description
FROM dbo.tblaff_Announcement_AffiliateType aat WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON aat.AffiliateTypeID = at.AffiliateTypeID
WHERE aat.AnnouncementID = 149
```

### 8.3 Find announcements without any type targeting (broadcast to all)
```sql
SELECT a.AnnouncementID, a.AnnouncementHeadline
FROM dbo.tblaff_Announcement a WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Announcement_AffiliateType aat WITH (NOLOCK) ON a.AnnouncementID = aat.AnnouncementID
WHERE aat.ID IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Announcement_AffiliateType | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Announcement_AffiliateType.sql*
