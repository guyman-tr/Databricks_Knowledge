# Customer.GetToaLeadDetails

> Retrieves Transfer of Account (TOA) lead details by TOA ID or MAMC ID - gets the pre-registration lead data for Chinese market account transfers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 1 lead details by ToaId or MamcId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetToaLeadDetails retrieves lead information for Transfer of Account (TOA) operations, primarily for the Chinese market. When a customer initiates an account transfer through a partner (MAMC - Multi-Account Management Company), lead details are captured before the customer completes registration. This procedure looks up those lead details by either the TOA identifier or the MAMC identifier.

The procedure automatically converts a ToaId to a MamcId using Customer.ConvertToaIdToMamcId when only a ToaId is provided. It returns TOP 1 ordered by InsertDate DESC (most recent lead for the identifier).

---

## 2. Business Logic

### 2.1 ToaId to MamcId Conversion

**What**: Automatic conversion when @mamcId is NULL but @toaId is provided.

**Rules**:
- If @mamcId IS NULL AND @toaId IS NOT NULL: calls Customer.ConvertToaIdToMamcId(@toaId) to derive the MAMC ID
- Search uses OR: WHERE ToaId = @toaId OR MamcId = @mamcId
- TOP 1 ORDER BY InsertDate DESC returns the most recent lead

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @toaId | nvarchar(150) | YES | NULL | CODE-BACKED | Transfer of Account identifier. |
| 2 | @mamcId | nvarchar(300) | YES | NULL | CODE-BACKED | Multi-Account Management Company ID. Auto-derived from @toaId if NULL. |
| 3 | ToaId (output) | nvarchar | YES | - | CODE-BACKED | TOA identifier. |
| 4 | FullName (output) | nvarchar | YES | - | CODE-BACKED | Lead's full name. |
| 5 | ToaPhone (output) | nvarchar | YES | - | CODE-BACKED | Lead's phone number. |
| 6 | IsToaPhoneVerified (output) | bit | YES | - | CODE-BACKED | Whether the TOA phone was verified. |
| 7 | ChineseIdNumber (output) | nvarchar | YES | - | CODE-BACKED | Chinese national ID number. |
| 8 | ChineseIdType (output) | nvarchar | YES | - | CODE-BACKED | Type of Chinese ID document. |
| 9 | AffiliateId (output) | int | YES | - | CODE-BACKED | Affiliate that referred this lead. |
| 10 | InsertDate (output) | datetime | YES | - | CODE-BACKED | When the lead was created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @toaId/@mamcId | Customer.ToaDetails_Lead | FROM | Lead details table |
| @toaId | Customer.ConvertToaIdToMamcId | Function call | TOA to MAMC ID conversion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | TOA lead lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetToaLeadDetails (procedure)
+-- Customer.ToaDetails_Lead (table)
+-- Customer.ConvertToaIdToMamcId (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ToaDetails_Lead | Table | FROM - lead data |
| Customer.ConvertToaIdToMamcId | Function | Called to convert ToaId to MamcId |

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

### 8.1 Get lead by TOA ID
```sql
EXEC Customer.GetToaLeadDetails @toaId = N'TOA-12345'
```

### 8.2 Get lead by MAMC ID
```sql
EXEC Customer.GetToaLeadDetails @mamcId = N'MAMC-67890'
```

### 8.3 Direct query
```sql
SELECT TOP 1 ToaId, FullName, ToaPhone, IsToaPhoneVerified,
       ChineseIdNumber, ChineseIdType, AffiliateId, InsertDate
FROM Customer.ToaDetails_Lead WITH (NOLOCK)
WHERE ToaId = @toaId OR MamcId = @mamcId
ORDER BY InsertDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetToaLeadDetails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetToaLeadDetails.sql*
