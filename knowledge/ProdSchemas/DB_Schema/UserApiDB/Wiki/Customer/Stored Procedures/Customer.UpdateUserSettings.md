# Customer.UpdateUserSettings

> Legacy settings update - resolves GCID to CID, delegates to dbo.Real_UpdateUserSettingsRemote (privacy/opt-out) and dbo.General_UpdateSettings (display preferences).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | EXEC Real_UpdateUserSettingsRemote + General_UpdateSettings |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateUserSettings is the legacy version of UpdateSettings. It splits the update across two legacy procedures: Real_UpdateUserSettingsRemote (privacy policy + opt-out) and General_UpdateSettings (display preferences: full name, share/follow, homepage). Returns SELECT 1 for cache invalidation.

---

## 2. Business Logic

### 2.1 Split Update

**Rules**:
- Resolve GCID to CID via Real_Customer
- EXEC Real_UpdateUserSettingsRemote @gcid, @privacyPolicyId, @OptOutReasonID (privacy)
- EXEC General_UpdateSettings @cid, @allowDisplayFullName, @allowShareFollow, @homepageId (display)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @privacyPolicyId | int | YES | NULL | CODE-BACKED | Privacy policy version. |
| 3 | @allowDisplayFullName | bit | YES | NULL | CODE-BACKED | Public name display. |
| 4 | @allowShareFollow | bit | YES | NULL | CODE-BACKED | Sharing/following. |
| 5 | @homepageId | int | YES | NULL | CODE-BACKED | Homepage preference. |
| 6 | @OptOutReasonID | smallint | YES | NULL | CODE-BACKED | Communication opt-out reason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | SELECT | CID resolution |
| Privacy params | dbo.Real_UpdateUserSettingsRemote | EXEC | Privacy/opt-out |
| Display params | dbo.General_UpdateSettings | EXEC | Display preferences |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy settings updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateUserSettings (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Real_UpdateUserSettingsRemote (procedure)
+-- dbo.General_UpdateSettings (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | SELECT - CID |
| dbo.Real_UpdateUserSettingsRemote | Procedure | EXEC |
| dbo.General_UpdateSettings | Procedure | EXEC |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Legacy callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update settings (legacy)
```sql
EXEC Customer.UpdateUserSettings @gcid=12345, @privacyPolicyId=2,
    @allowDisplayFullName=1, @allowShareFollow=1
```

### 8.2 Prefer new version
```sql
-- Use Customer.UpdateSettings for new development
```

### 8.3 Verify
```sql
EXEC Customer.GetUserSettings @gcid=12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateUserSettings | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateUserSettings.sql*
