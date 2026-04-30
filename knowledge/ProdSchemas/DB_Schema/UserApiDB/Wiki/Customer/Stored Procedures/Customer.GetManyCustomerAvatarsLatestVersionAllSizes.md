# Customer.GetManyCustomerAvatarsLatestVersionAllSizes

> Retrieves the latest avatar versions in all sizes for multiple customers - supports both user-uploaded and system-generated avatars with separate versioning logic.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns avatar rows (latest versions, all sizes) for a CID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyCustomerAvatarsLatestVersionAllSizes is a batch avatar retrieval procedure that returns the latest version of all avatar sizes for multiple customers. It supports two avatar types: user-uploaded avatars (AvatarTypeId <> 4) and system-generated avatars (AvatarTypeId = 4), with separate versioning for each.

This procedure is used when the application needs to display avatars for multiple users at once - for example, in copy trading leader lists, social feeds, or search results.

The procedure uses a temp table to find the maximum version per customer per avatar type (User vs System), then retrieves all size variants for those versions. User avatars and system avatars are combined via UNION ALL.

---

## 2. Business Logic

### 2.1 Dual Avatar Type Versioning

**What**: User avatars and system avatars are versioned independently, with different selection logic.

**Columns/Parameters Involved**: `AvatarTypeId`, `VersionNum`, `CID`

**Rules**:
- User avatars (AvatarTypeId <> 4): grouped as 'User', MAX(VersionNum) per CID
- System avatars (AvatarTypeId = 4): grouped as 'System', uses MAX(AvatarId) to find the latest within the max version
- Both types are returned in a single UNION ALL result set
- Each result includes all size variants (Width, Height, ImageURL) for the latest version
- OPTION (RECOMPILE) hint for parameter-sensitive query optimization

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of CIDs (not GCIDs) to retrieve avatars for. |
| 2 | AvatarId (output) | int | NO | - | CODE-BACKED | Unique avatar record identifier. |
| 3 | CID (output) | int | NO | - | CODE-BACKED | Customer ID. |
| 4 | VersionNum (output) | int | NO | - | CODE-BACKED | Avatar version number. Higher = newer. |
| 5 | Width (output) | int | YES | - | CODE-BACKED | Image width in pixels. |
| 6 | Height (output) | int | YES | - | CODE-BACKED | Image height in pixels. |
| 7 | ImageURL (output) | varchar | YES | - | CODE-BACKED | URL to the avatar image file. |
| 8 | AvatarTypeId (output) | int | YES | - | CODE-BACKED | Avatar type: 4 = System-generated, others = User-uploaded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | Customer.Avatars | JOIN | Avatar storage table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch avatar retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyCustomerAvatarsLatestVersionAllSizes (procedure)
+-- Customer.Avatars (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Avatars | Table | FROM - avatar data with version/size filtering |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | Forces recompilation for parameter-sensitive optimization |

---

## 8. Sample Queries

### 8.1 Get avatars for multiple customers
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (100001), (100002)
EXEC Customer.GetManyCustomerAvatarsLatestVersionAllSizes @ids = @ids
```

### 8.2 Get latest user avatar for a single customer
```sql
SELECT a.AvatarId, a.CID, a.VersionNum, a.Width, a.Height, a.ImageURL, a.AvatarTypeId
FROM Customer.Avatars a WITH (NOLOCK)
WHERE a.CID = @CID AND a.AvatarTypeId <> 4
    AND a.VersionNum = (SELECT MAX(VersionNum) FROM Customer.Avatars WITH (NOLOCK)
                        WHERE CID = @CID AND AvatarTypeId <> 4)
```

### 8.3 Count avatar types per customer
```sql
SELECT CID, IIF(AvatarTypeId <> 4, 'User', 'System') AS AvatarType, COUNT(*) AS SizeCount
FROM Customer.Avatars WITH (NOLOCK)
WHERE CID IN (SELECT Id FROM @ids)
GROUP BY CID, IIF(AvatarTypeId <> 4, 'User', 'System')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyCustomerAvatarsLatestVersionAllSizes | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyCustomerAvatarsLatestVersionAllSizes.sql*
