# Customer.P_GetNotificationUserInfo

> Retrieves user profile data optimized for notification rendering - includes name, contact info, avatar (smallest size preferred), language culture code, and demo CID. Lookup by GCID list.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns notification-ready user profiles by GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.P_GetNotificationUserInfo retrieves the specific subset of user data needed for rendering notifications (push, email, in-app). It includes the user's name, email, phone, external ID, language culture code (for localization), avatar URL (preferring the smallest 50x50 size), and demo CID. The procedure is optimized for notification services that need to personalize messages for multiple users at once.

It uses temp tables and clustered indexes for performance, fetches latest avatar versions (both user-uploaded and system type 4), and resolves language to culture code via Dictionary_Language.

---

## 2. Business Logic

### 2.1 Avatar Size Preference

**What**: Returns one avatar per customer, preferring the smallest (50x50) for notification thumbnails.

**Rules**:
- Fetches latest version avatars (user + system type 4)
- Uses computed column CompCol = IIF(Height=50 AND Width=50, 0, 1) for sorting
- OUTER APPLY TOP 1 ORDER BY CompCol ASC picks 50x50 first if available
- Falls back to any other size if 50x50 doesn't exist

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | CID (output) | int | NO | - | CODE-BACKED | Customer ID. |
| 4 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | First name for notification personalization. |
| 5 | LastName (output) | nvarchar | YES | - | CODE-BACKED | Last name. |
| 6 | UserName (output) | varchar | YES | - | CODE-BACKED | Username. |
| 7 | ExternalID (output) | decimal | YES | - | CODE-BACKED | External system ID. |
| 8 | Phone (output) | varchar | YES | - | CODE-BACKED | Phone number for SMS notifications. |
| 9 | Email (output) | nvarchar | YES | - | CODE-BACKED | Email for email notifications. |
| 10 | CultureCode (output) | varchar | YES | - | CODE-BACKED | Language culture code (e.g., 'en-US') for localized notifications. From Dictionary_Language. |
| 11 | CountryID (output) | int | YES | - | CODE-BACKED | Country for regional notification rules. |
| 12 | AvatarId (output) | int | YES | - | CODE-BACKED | Avatar record ID (smallest size preferred). |
| 13 | VersionNum (output) | int | YES | - | CODE-BACKED | Avatar version. |
| 14 | Width (output) | int | YES | - | CODE-BACKED | Avatar width. |
| 15 | Height (output) | int | YES | - | CODE-BACKED | Avatar height. |
| 16 | ImageURL (output) | varchar | YES | - | CODE-BACKED | Avatar image URL. |
| 17 | AvatarTypeId (output) | int | YES | - | CODE-BACKED | Avatar type (4=system). |
| 18 | DemoCID (output) | int | YES | - | CODE-BACKED | Demo account CID from CustomerIdentification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Real_Customer | JOIN | Core customer data |
| LanguageID | dbo.Dictionary_Language | JOIN | Culture code resolution |
| CID | Customer.Avatars | CTE + OUTER APPLY | Avatar with size preference |
| GCID | Customer.CustomerIdentification | OUTER APPLY | Demo CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Notification service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.P_GetNotificationUserInfo (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Dictionary_Language (table)
+-- Customer.Avatars (table)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | JOIN - core data |
| dbo.Dictionary_Language | Table | JOIN - culture code |
| Customer.Avatars | Table | CTE - avatars |
| Customer.CustomerIdentification | Table | OUTER APPLY - demo CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Notification service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table indexes | Performance | Clustered index on #GetCustomerAvatarsLatestVersionAllSizes(CID, CompCol) |

---

## 8. Sample Queries

### 8.1 Get notification data
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002)
EXEC Customer.P_GetNotificationUserInfo @ids = @ids
```

### 8.2 Compare with CID version
```sql
-- P_GetNotificationUserInfo: lookup by GCID
-- P_GetNotificationUserInfoByCID: lookup by CID
-- Both return identical output columns
```

### 8.3 Direct avatar query (50x50 preferred)
```sql
SELECT TOP 1 AvatarId, ImageURL
FROM Customer.Avatars WITH (NOLOCK)
WHERE CID = @CID
ORDER BY IIF(Height=50 AND Width=50, 0, 1) ASC, VersionNum DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.P_GetNotificationUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.P_GetNotificationUserInfo.sql*
