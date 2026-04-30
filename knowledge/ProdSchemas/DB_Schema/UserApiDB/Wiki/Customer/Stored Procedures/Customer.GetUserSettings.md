# Customer.GetUserSettings

> Retrieves user settings (privacy, display, homepage, opt-out) for a single customer from legacy dbo tables - the single-customer version of GetManyUserSettings.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns settings for a single GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUserSettings retrieves display and privacy preferences for a single customer from the legacy dbo tables (Real_Customer + General_Settings). It returns the username, privacy policy version, display/sharing preferences, homepage, and opt-out reason. This is the legacy single-customer equivalent of GetManyUserSettings (batch) and GetSettings (Customer schema).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-customer settings read.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | CID (output) | int | NO | - | CODE-BACKED | Customer ID. |
| 4 | UserName (output) | varchar | YES | - | CODE-BACKED | Account username. |
| 5 | PrivacyPolicyID (output) | int | YES | - | CODE-BACKED | Privacy policy version. |
| 6 | AllowDisplayFullName (output) | bit | YES | - | CODE-BACKED | Allow public name display. |
| 7 | AllowShareFollow (output) | bit | YES | - | CODE-BACKED | Allow sharing/following. |
| 8 | HomepageId (output) | int | YES | - | CODE-BACKED | Homepage preference. |
| 9 | OptOutReasonID (output) | int | YES | - | CODE-BACKED | Communication opt-out reason. Added 2017 (case 49207). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | FROM | Customer data + username |
| CID | dbo.General_Settings | LEFT JOIN | Display preferences |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Settings retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUserSettings (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.General_Settings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - customer + username |
| dbo.General_Settings | Table | LEFT JOIN - preferences |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get settings
```sql
EXEC Customer.GetUserSettings @gcid = 12345
```

### 8.2 Compare settings SP variants
```sql
-- GetUserSettings: legacy dbo, single GCID, includes OptOutReasonID
-- GetManyUserSettings: legacy dbo, batch IdList, no OptOutReasonID
-- GetSettings: Customer schema, single GCID, includes OptOutReasonID
```

### 8.3 Direct query
```sql
SELECT rc.GCID, rc.CID, rc.UserName, rc.PrivacyPolicyID,
       s.AllowDisplayFullName, s.AllowShareFollow, s.HomepageId, rc.OptOutReasonID
FROM dbo.Real_Customer rc WITH (NOLOCK)
LEFT JOIN dbo.General_Settings s WITH (NOLOCK) ON s.CID = rc.CID
WHERE rc.GCID = @gcid
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetUserSettings | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetUserSettings.sql*
