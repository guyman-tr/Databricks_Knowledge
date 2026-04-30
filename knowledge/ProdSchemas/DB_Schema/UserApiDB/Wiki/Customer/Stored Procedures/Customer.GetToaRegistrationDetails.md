# Customer.GetToaRegistrationDetails

> Retrieves Transfer of Account (TOA) registration details by TOA ID or MAMC ID - gets post-registration data including the linked GCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns registration details with GCID by ToaId or MamcId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetToaRegistrationDetails retrieves Transfer of Account registration data - the record created after a TOA lead completes their account registration. Unlike GetToaLeadDetails (which returns pre-registration lead data), this procedure returns the post-registration record that includes the assigned GCID and MamcId, confirming the account was successfully created.

Same ToaId-to-MamcId conversion logic as GetToaLeadDetails using Customer.ConvertToaIdToMamcId. Does NOT use TOP 1 (returns all matching rows, unlike the lead version).

---

## 2. Business Logic

### 2.1 ToaId to MamcId Conversion

**What**: Same auto-conversion as GetToaLeadDetails.

**Rules**:
- If @mamcId IS NULL AND @toaId IS NOT NULL: calls Customer.ConvertToaIdToMamcId(@toaId)
- Search: WHERE ToaId = @toaId OR MamcId = @mamcId
- Returns ALL matching rows (no TOP 1)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @toaId | nvarchar(300) | YES | NULL | CODE-BACKED | Transfer of Account identifier. |
| 2 | @mamcId | nvarchar(300) | YES | NULL | CODE-BACKED | MAMC ID. Auto-derived from @toaId if NULL. |
| 3 | ToaId (output) | nvarchar | YES | - | CODE-BACKED | TOA identifier. |
| 4 | GCID (output) | int | YES | - | CODE-BACKED | Global Customer ID assigned after registration. |
| 5 | FullName (output) | nvarchar | YES | - | CODE-BACKED | Registered customer's full name. |
| 6 | ToaPhone (output) | nvarchar | YES | - | CODE-BACKED | Phone number. |
| 7 | IsToaPhoneVerified (output) | bit | YES | - | CODE-BACKED | Phone verified flag. |
| 8 | ChineseIdNumber (output) | nvarchar | YES | - | CODE-BACKED | Chinese national ID. |
| 9 | ChineseIdType (output) | nvarchar | YES | - | CODE-BACKED | Chinese ID type. |
| 10 | AffiliateId (output) | int | YES | - | CODE-BACKED | Referring affiliate. |
| 11 | InsertDate (output) | datetime | YES | - | CODE-BACKED | Registration date. |
| 12 | MamcId (output) | nvarchar | YES | - | CODE-BACKED | MAMC identifier (returned in output, unlike lead version). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @toaId/@mamcId | Customer.ToaDetails_Registration | FROM | Registration details table |
| @toaId | Customer.ConvertToaIdToMamcId | Function call | TOA to MAMC conversion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | TOA registration lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetToaRegistrationDetails (procedure)
+-- Customer.ToaDetails_Registration (table)
+-- Customer.ConvertToaIdToMamcId (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ToaDetails_Registration | Table | FROM - registration data |
| Customer.ConvertToaIdToMamcId | Function | Called to convert ToaId |

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

### 8.1 Get registration by TOA ID
```sql
EXEC Customer.GetToaRegistrationDetails @toaId = N'TOA-12345'
```

### 8.2 Get registration by MAMC ID
```sql
EXEC Customer.GetToaRegistrationDetails @mamcId = N'MAMC-67890'
```

### 8.3 Compare with lead version
```sql
-- GetToaLeadDetails: pre-registration data, TOP 1, no GCID
-- GetToaRegistrationDetails: post-registration data, all rows, includes GCID + MamcId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetToaRegistrationDetails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetToaRegistrationDetails.sql*
