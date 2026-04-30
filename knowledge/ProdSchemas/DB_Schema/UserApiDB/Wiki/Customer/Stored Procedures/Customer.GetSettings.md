# Customer.GetSettings

> Retrieves user settings (privacy, opt-out, display preferences, homepage) for a single customer from Customer schema normalized tables.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns settings for a single GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetSettings retrieves user display and privacy settings for a single customer from the normalized Customer schema tables. It joins CustomerIdentification (for CID), BasicUserInfo (for UserName), and UserSettings (for the actual preference values). This is the Customer schema replacement for the legacy GetManyUserSettings (which reads from dbo.Real_Customer + General_Settings).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-customer settings read from three normalized tables.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID (from BasicUserInfo). |
| 3 | CID (output) | int | NO | - | CODE-BACKED | Customer ID from CustomerIdentification. |
| 4 | UserName (output) | varchar | YES | - | CODE-BACKED | Account username from BasicUserInfo. |
| 5 | PrivacyPolicyID (output) | int | YES | - | CODE-BACKED | Privacy policy version from UserSettings. |
| 6 | OptOutReasonID (output) | int | YES | - | CODE-BACKED | Communication opt-out reason from UserSettings. |
| 7 | AllowDisplayFullName (output) | bit | YES | - | CODE-BACKED | Allow public full name display from UserSettings. |
| 8 | AllowShareFollow (output) | bit | YES | - | CODE-BACKED | Allow sharing/following from UserSettings. |
| 9 | HomepageId (output) | int | YES | - | CODE-BACKED | Homepage preference from UserSettings. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerIdentification | JOIN | CID resolution |
| GCID | Customer.BasicUserInfo | JOIN | Username |
| GCID | Customer.UserSettings | JOIN | Settings values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Settings retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetSettings (procedure)
+-- Customer.CustomerIdentification (table)
+-- Customer.BasicUserInfo (table)
+-- Customer.UserSettings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | JOIN - CID |
| Customer.BasicUserInfo | Table | JOIN - username |
| Customer.UserSettings | Table | JOIN - settings |

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
EXEC Customer.GetSettings @gcid = 12345
```

### 8.2 Direct query equivalent
```sql
SELECT bi.GCID, ci.CID, bi.UserName, us.PrivacyPolicyID, us.OptOutReasonID,
       us.AllowDisplayFullName, us.AllowShareFollow, us.HomepageId
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
JOIN Customer.BasicUserInfo bi WITH (NOLOCK) ON bi.GCID = ci.GCID
JOIN Customer.UserSettings us WITH (NOLOCK) ON us.GCID = ci.GCID
WHERE ci.GCID = @gcid
```

### 8.3 Compare with legacy
```sql
-- GetSettings: Customer.UserSettings (normalized)
-- GetManyUserSettings: dbo.Real_Customer + General_Settings (legacy, batch)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetSettings | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetSettings.sql*
