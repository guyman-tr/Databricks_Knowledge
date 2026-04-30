# Customer.Avatars

> Stores user profile avatar images across multiple sizes and versions, with CDN URLs for image delivery.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | AvatarId (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + NC on CID) |

---

## 1. Business Meaning

Customer.Avatars stores the metadata for user profile images (avatars) on the eToro social trading platform. Each avatar has multiple size variants (different Width x Height) and version numbers, allowing the platform to serve appropriately sized images for different contexts (thumbnail, profile page, social feed). Images are stored on CDN with URLs recorded here.

Avatars are important for eToro's social trading experience. User profile images appear in copy-trading search results, news feeds, portfolio pages, and PI profiles. Multiple versions allow users to update their photo while retaining history.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AvatarId | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing avatar record identifier. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID (legacy). Links to the user who owns this avatar. Indexed for fast lookup. |
| 3 | Width | int | NO | - | CODE-BACKED | Image width in pixels. Multiple sizes stored per avatar version (e.g., 50, 100, 200, 500). |
| 4 | Height | int | NO | - | CODE-BACKED | Image height in pixels. Typically matches Width for square avatars. |
| 5 | VersionNum | int | NO | - | CODE-BACKED | Version number for this avatar. Incremented when user uploads a new profile photo. Latest version is the active one. |
| 6 | ImageURL | varchar(500) | NO | - | CODE-BACKED | Full CDN URL for this avatar image variant. Used directly in UI rendering. |
| 7 | AvatarTypeId | int | NO | - | CODE-BACKED | Type of avatar image (e.g., profile photo, cover image). |
| 8 | Ocurred | datetime | YES | getutcdate() | CODE-BACKED | Timestamp when this avatar record was created. Default: current UTC time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.InsertAvatar | AvatarId | SP writes | Creates new avatar records |
| Customer.DeleteAvatarsByCid | CID | SP deletes | Removes all avatars for a user |
| Customer.GetCustomerAvatarsLatestVersionAllSizes | CID | SP reads | Returns latest avatar in all sizes |
| Customer.GetCustomerAvatarsAllVersionsAllSizes | CID | SP reads | Returns full avatar history |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.InsertAvatar | Stored Procedure | Inserts rows |
| Customer.DeleteAvatarsByCid | Stored Procedure | Deletes rows |
| Customer.GetCustomerAvatarsLatestVersionAllSizes | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Avatars | CLUSTERED PK | AvatarId | - | - | Active (PAGE compressed) |
| IX_CustomerAvatar_CID_20161219 | NONCLUSTERED | CID | AvatarId, Width, Height, ImageURL, AvatarTypeId, VersionNum | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | getutcdate() for Ocurred |

---

## 8. Sample Queries

### 8.1 Get latest avatar for a user (all sizes)
```sql
SELECT Width, Height, ImageURL FROM Customer.Avatars WITH (NOLOCK)
WHERE CID = @CID AND VersionNum = (SELECT MAX(VersionNum) FROM Customer.Avatars WITH (NOLOCK) WHERE CID = @CID)
ORDER BY Width
```

### 8.2 Count avatar versions per user
```sql
SELECT CID, COUNT(DISTINCT VersionNum) AS VersionCount FROM Customer.Avatars WITH (NOLOCK) GROUP BY CID HAVING COUNT(DISTINCT VersionNum) > 1
```

### 8.3 Find recent avatar uploads
```sql
SELECT TOP 100 CID, VersionNum, Width, Height, Ocurred FROM Customer.Avatars WITH (NOLOCK) ORDER BY Ocurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.Avatars | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.Avatars.sql*
