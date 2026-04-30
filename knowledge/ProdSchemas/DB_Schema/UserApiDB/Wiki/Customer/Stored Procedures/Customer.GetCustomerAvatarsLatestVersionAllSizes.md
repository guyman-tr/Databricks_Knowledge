# Customer.GetCustomerAvatarsLatestVersionAllSizes

> Retrieves the latest avatar version for a customer in all sizes, with special handling for AvatarTypeId=4 which tracks its own version independently.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid (legacy CID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerAvatarsLatestVersionAllSizes retrieves the most recent avatar for a customer across all image sizes, with special version tracking for AvatarTypeId=4. This is the primary avatar retrieval procedure for profile display - it shows only the current avatar, not historical versions.

This procedure serves profile display, social feed user cards, and any UI that shows the user's current avatar. The special handling of type 4 avatars (which maintain their own version timeline) ensures both regular avatars and type-4 avatars are returned from their respective latest versions.

---

## 2. Business Logic

### 2.1 Dual Version Tracking (Regular vs Type 4)

**What**: AvatarTypeId=4 has independent version tracking from other avatar types.

**Columns/Parameters Involved**: `AvatarTypeId`, `VersionNum`

**Rules**:
- Regular avatars (type != 4): latest version = MAX(VersionNum) WHERE AvatarTypeId <> 4
- Type 4 avatars: latest version = MAX(VersionNum) WHERE AvatarTypeId = 4
- Both latest versions are determined independently
- Results are combined via UNION ALL
- For type 4, additionally deduplicates by MAX(AvatarId) per CID+VersionNum+Width+Height group

**Diagram**:
```
Step 1: @LatestVersionForOther = MAX(VersionNum) WHERE AvatarTypeId <> 4
Step 2: @LatestVersionForType4 = MAX(VersionNum) WHERE AvatarTypeId = 4
Step 3: UNION ALL
        - All rows WHERE type <> 4 AND version = @LatestVersionForOther
        - Deduplicated rows WHERE type = 4 AND version = @LatestVersionForType4
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int | NO | - | CODE-BACKED | Legacy Customer ID. Used to filter Customer.Avatars by CID. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | AvatarId | Customer.Avatars | CODE-BACKED | Unique avatar record ID. |
| 2 | CID | Customer.Avatars | CODE-BACKED | Customer ID. |
| 3 | VersionNum | Customer.Avatars | CODE-BACKED | Avatar version (latest for each type group). |
| 4 | Width | Customer.Avatars | CODE-BACKED | Image width in pixels. |
| 5 | Height | Customer.Avatars | CODE-BACKED | Image height in pixels. |
| 6 | ImageURL | Customer.Avatars | CODE-BACKED | URL to stored image. |
| 7 | AvatarTypeId | Customer.Avatars | CODE-BACKED | Avatar type. Type 4 has special version tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | Customer.Avatars | SELECT (READER) | Latest avatar records for customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by profile display services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerAvatarsLatestVersionAllSizes (procedure)
+-- Customer.Avatars (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Avatars | Table | SELECT - latest version avatars by CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get latest avatars for a customer
```sql
EXEC Customer.GetCustomerAvatarsLatestVersionAllSizes @cid = 12345
```

### 8.2 Check latest version numbers
```sql
SELECT MAX(VersionNum) AS LatestRegular FROM Customer.Avatars WITH (NOLOCK) WHERE CID = 12345 AND AvatarTypeId <> 4
SELECT MAX(VersionNum) AS LatestType4 FROM Customer.Avatars WITH (NOLOCK) WHERE CID = 12345 AND AvatarTypeId = 4
```

### 8.3 View avatar sizes for latest version
```sql
SELECT AvatarTypeId, Width, Height, ImageURL
FROM Customer.Avatars WITH (NOLOCK)
WHERE CID = 12345 AND VersionNum = (SELECT MAX(VersionNum) FROM Customer.Avatars WITH (NOLOCK) WHERE CID = 12345 AND AvatarTypeId <> 4)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerAvatarsLatestVersionAllSizes | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetCustomerAvatarsLatestVersionAllSizes.sql*
