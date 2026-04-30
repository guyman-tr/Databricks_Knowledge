# Customer.GetToaRegistrationDetailsByGcid

> Retrieves Transfer of Account (TOA) registration details by GCID - a simpler variant of GetToaRegistrationDetails that looks up by customer's global ID without ToaId/MamcId conversion.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOA registration rows for a GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetToaRegistrationDetailsByGcid retrieves TOA registration data for a customer by their GCID, returning all matching records (a customer could have multiple TOA registrations). Unlike GetToaRegistrationDetails (which searches by ToaId or MamcId), this variant uses the GCID directly - useful when you already have the customer's identity and want to check if they came through a TOA transfer.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple read by GCID. No ToaId-to-MamcId conversion needed.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID to look up. |
| 2 | ToaId (output) | nvarchar | YES | - | CODE-BACKED | Transfer of Account identifier. |
| 3 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID (echoed). |
| 4 | FullName (output) | nvarchar | YES | - | CODE-BACKED | Customer full name from TOA registration. |
| 5 | ToaPhone (output) | nvarchar | YES | - | CODE-BACKED | Phone number from TOA. |
| 6 | IsToaPhoneVerified (output) | bit | YES | - | CODE-BACKED | Whether TOA phone was verified. |
| 7 | ChineseIdNumber (output) | nvarchar | YES | - | CODE-BACKED | Chinese national ID number. |
| 8 | ChineseIdType (output) | nvarchar | YES | - | CODE-BACKED | Type of Chinese ID document. |
| 9 | AffiliateId (output) | int | YES | - | CODE-BACKED | Referring affiliate. |
| 10 | InsertDate (output) | datetime | YES | - | CODE-BACKED | When registered. |
| 11 | MamcId (output) | nvarchar | YES | - | CODE-BACKED | Multi-Account Management Company ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.ToaDetails_Registration | FROM | TOA registration data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | TOA lookup by customer ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetToaRegistrationDetailsByGcid (procedure)
+-- Customer.ToaDetails_Registration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ToaDetails_Registration | Table | FROM - registration data |

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

### 8.1 Get TOA details by GCID
```sql
EXEC Customer.GetToaRegistrationDetailsByGcid @gcid = 12345
```

### 8.2 Direct query equivalent
```sql
SELECT ToaId, GCID, FullName, ToaPhone, IsToaPhoneVerified,
       ChineseIdNumber, ChineseIdType, AffiliateId, InsertDate, MamcId
FROM Customer.ToaDetails_Registration WITH (NOLOCK)
WHERE GCID = @gcid
```

### 8.3 Compare with other TOA getters
```sql
-- GetToaRegistrationDetailsByGcid: lookup by GCID (simplest)
-- GetToaRegistrationDetails: lookup by ToaId or MamcId (with conversion)
-- GetToaLeadDetails: pre-registration lead data (different table)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetToaRegistrationDetailsByGcid | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetToaRegistrationDetailsByGcid.sql*
