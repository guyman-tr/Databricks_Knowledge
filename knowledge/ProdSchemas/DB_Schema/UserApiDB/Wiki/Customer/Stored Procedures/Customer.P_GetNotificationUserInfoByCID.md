# Customer.P_GetNotificationUserInfoByCID

> CID-based variant of P_GetNotificationUserInfo - retrieves notification-ready user profiles by CID list instead of GCID list.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns notification-ready user profiles by CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.P_GetNotificationUserInfoByCID is identical to P_GetNotificationUserInfo except it accepts CIDs instead of GCIDs. It returns the same notification data (name, email, phone, culture code, avatar, demo CID) with the same avatar size-preference logic. Created (Dec 2016, case 42550) for callers that have CIDs rather than GCIDs.

The JOIN to Real_Customer uses `ids.Id = rc.CID` instead of `ids.Id = rc.GCID`.

---

## 2. Business Logic

### 2.1 Avatar Size Preference

**What**: Same as P_GetNotificationUserInfo - prefers 50x50 avatar via computed column sorting.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of CIDs (not GCIDs) to retrieve. |
| 2-18 | (Same as P_GetNotificationUserInfo) | - | - | - | CODE-BACKED | Identical output: GCID, CID, names, ExternalID, Phone, Email, CultureCode, CountryID, avatar fields, DemoCID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Real_Customer | JOIN on CID | Customer data |
| LanguageID | dbo.Dictionary_Language | JOIN | Culture code |
| CID | Customer.Avatars | CTE | Avatars |
| GCID | Customer.CustomerIdentification | OUTER APPLY | Demo CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Notification service (CID-based) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.P_GetNotificationUserInfoByCID (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Dictionary_Language (table)
+-- Customer.Avatars (table)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | JOIN on CID |
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
| SET NOCOUNT ON | Performance | Reduces network chatter |

---

## 8. Sample Queries

### 8.1 Get notification data by CID
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (100001), (100002)
EXEC Customer.P_GetNotificationUserInfoByCID @ids = @ids
```

### 8.2 Compare with GCID version
```sql
-- P_GetNotificationUserInfo: @ids contains GCIDs
-- P_GetNotificationUserInfoByCID: @ids contains CIDs
```

### 8.3 Direct query
```sql
SELECT rc.GCID, rc.CID, rc.FirstName, rc.LastName, rc.Email, lc.CultureCode
FROM dbo.Real_Customer rc WITH (NOLOCK)
JOIN dbo.Dictionary_Language lc ON rc.LanguageID = lc.LanguageID
WHERE rc.CID IN (100001, 100002)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.P_GetNotificationUserInfoByCID | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.P_GetNotificationUserInfoByCID.sql*
