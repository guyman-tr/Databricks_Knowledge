# Customer.GetCustomerAvatarsAllVersionsAllSizes

> Retrieves all avatar records (all versions, all sizes, all types) for a customer from Customer.Avatars by CID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid (legacy CID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerAvatarsAllVersionsAllSizes retrieves the complete avatar history for a customer - every version, every size, and every type. This includes profile photos, cover images, and system-generated avatars across all historical uploads.

This procedure serves avatar management features: displaying avatar history, cleanup operations (Customer.CustomerAvatarsGetCIDsToDelete), and admin tools that need to see all avatar data for a user. Unlike GetCustomerAvatarsLatestVersionAllSizes which returns only the latest, this returns the full history.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple full-table read filtered by CID.

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
| 1 | AvatarId | Customer.Avatars | CODE-BACKED | Unique avatar record identifier (PK). |
| 2 | CID | Customer.Avatars | CODE-BACKED | Customer ID owning this avatar. |
| 3 | VersionNum | Customer.Avatars | CODE-BACKED | Avatar version number - increments with each new upload. |
| 4 | Width | Customer.Avatars | CODE-BACKED | Image width in pixels. |
| 5 | Height | Customer.Avatars | CODE-BACKED | Image height in pixels. |
| 6 | ImageURL | Customer.Avatars | CODE-BACKED | URL to the stored avatar image. |
| 7 | AvatarTypeId | Customer.Avatars | CODE-BACKED | Avatar type: distinguishes profile photos, cover images, etc. Type 4 has special handling in latest-version queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | Customer.Avatars | SELECT (READER) | All avatar records for this customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by avatar management services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerAvatarsAllVersionsAllSizes (procedure)
+-- Customer.Avatars (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Avatars | Table | SELECT - all avatar records by CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Get all avatars for a customer
```sql
EXEC Customer.GetCustomerAvatarsAllVersionsAllSizes @cid = 12345
```

### 8.2 Count avatar versions
```sql
SELECT CID, COUNT(*) AS TotalAvatars, MAX(VersionNum) AS LatestVersion
FROM Customer.Avatars WITH (NOLOCK)
WHERE CID = 12345
GROUP BY CID
```

### 8.3 View avatar types for a customer
```sql
SELECT AvatarTypeId, COUNT(*) AS Count, MAX(VersionNum) AS LatestVersion
FROM Customer.Avatars WITH (NOLOCK)
WHERE CID = 12345
GROUP BY AvatarTypeId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerAvatarsAllVersionsAllSizes | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetCustomerAvatarsAllVersionsAllSizes.sql*
