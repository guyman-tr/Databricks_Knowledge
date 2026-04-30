# Customer.UpdateSettings

> Updates user settings in Customer.UserSettings (new-style) with session context and automatic OptOutReasonID derivation from PrivacyPolicyID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Customer.UserSettings with session context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateSettings updates user display and privacy preferences in the normalized Customer.UserSettings table. It includes smart OptOutReasonID derivation: if PrivacyPolicyID is 1 (or NULL), OptOutReasonID is set to 0 (not opted out); otherwise it uses the provided OptOutReasonID (defaulting to 1). Returns SELECT 1 for cache invalidation.

---

## 2. Business Logic

### 2.1 OptOutReason Derivation

**What**: Automatically determines opt-out status from privacy policy version.

**Rules**:
- CASE WHEN ISNULL(@privacyPolicyId, 1) = 1 THEN 0 ELSE ISNULL(@OptOutReasonID, 1) END
- PrivacyPolicyID=1 (or NULL) -> OptOutReasonID=0 (no opt-out)
- PrivacyPolicyID > 1 -> OptOutReasonID from param (default 1)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @privacyPolicyId | int | YES | NULL | CODE-BACKED | Privacy policy version. Drives OptOutReasonID logic. |
| 3 | @allowDisplayFullName | bit | YES | NULL | CODE-BACKED | Allow public full name display. |
| 4 | @allowShareFollow | bit | YES | NULL | CODE-BACKED | Allow sharing/following. |
| 5 | @homepageId | int | YES | NULL | CODE-BACKED | Homepage preference. |
| 6 | @OptOutReasonID | smallint | YES | NULL | CODE-BACKED | Communication opt-out reason. Derived if not provided. |
| 7 | @correlationId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail. |
| 8 | @clientRequestId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail. |
| 9 | @requestTime | datetime | YES | NULL | CODE-BACKED | Audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.UserSettings | UPDATE | Settings data (new schema) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Settings updates (new path) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateSettings (procedure)
+-- Customer.UserSettings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.UserSettings | Table | UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update settings
```sql
EXEC Customer.UpdateSettings @gcid=12345, @privacyPolicyId=2, @allowDisplayFullName=1
```

### 8.2 Compare with legacy
```sql
-- UpdateSettings: Customer.UserSettings (new, with session context + OptOut derivation)
-- UpdateUserSettings: dbo.Real_UpdateUserSettingsRemote + General_UpdateSettings (legacy)
```

### 8.3 Verify
```sql
SELECT * FROM Customer.UserSettings WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateSettings | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateSettings.sql*
