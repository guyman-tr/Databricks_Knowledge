# Customer.GetManyUserSettings

> Retrieves user settings (privacy policy, display preferences, homepage) for multiple customers from legacy dbo tables.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns settings rows for a GCID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyUserSettings is a batch reader for user display and privacy settings. It retrieves the username, privacy policy version, and General_Settings preferences (AllowDisplayFullName, AllowShareFollow, HomepageId) for multiple customers.

This procedure reads from the legacy dbo.Real_Customer and dbo.General_Settings tables. It serves callers that need user preferences in bulk - for example, when checking privacy settings across a group of users.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Batch read by GCID list.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve settings for. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | CID (output) | int | NO | - | CODE-BACKED | Customer ID from Real_Customer. |
| 4 | UserName (output) | varchar | YES | - | CODE-BACKED | Account username. |
| 5 | PrivacyPolicyID (output) | int | YES | - | CODE-BACKED | Privacy policy version accepted. |
| 6 | AllowDisplayFullName (output) | bit | YES | - | CODE-BACKED | Whether user allows full name public display. From General_Settings. |
| 7 | AllowShareFollow (output) | bit | YES | - | CODE-BACKED | Whether user allows sharing/following. From General_Settings. |
| 8 | HomepageId (output) | int | YES | - | CODE-BACKED | User homepage preference. From General_Settings. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Real_Customer | JOIN | Customer record |
| CID | dbo.General_Settings | LEFT JOIN | User preferences |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch settings retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyUserSettings (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.General_Settings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - customer + username |
| dbo.General_Settings | Table | LEFT JOIN - privacy/display settings |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get settings for multiple customers
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002)
EXEC Customer.GetManyUserSettings @ids = @ids
```

### 8.2 Direct query equivalent
```sql
SELECT rc.GCID, rc.CID, rc.UserName, rc.PrivacyPolicyID,
       s.AllowDisplayFullName, s.AllowShareFollow, s.HomepageId
FROM dbo.Real_Customer rc WITH (NOLOCK)
JOIN @ids ids ON ids.Id = rc.GCID
LEFT JOIN dbo.General_Settings s WITH (NOLOCK) ON s.CID = rc.CID
```

### 8.3 Find customers with public full name display
```sql
SELECT rc.GCID, rc.UserName
FROM dbo.Real_Customer rc WITH (NOLOCK)
JOIN @ids ids ON ids.Id = rc.GCID
JOIN dbo.General_Settings s WITH (NOLOCK) ON s.CID = rc.CID
WHERE s.AllowDisplayFullName = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyUserSettings | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyUserSettings.sql*
