# Customer.InsertToaLeadDetails

> Inserts Transfer of Account (TOA) lead details with automatic ToaId-to-MamcId conversion - records pre-registration lead data for Chinese market transfers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Customer.ToaDetails_Lead |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertToaLeadDetails records pre-registration lead data for Transfer of Account operations. When a potential customer comes through a TOA partner (MAMC), their contact details are captured as a lead before they complete registration. The procedure automatically converts ToaId to MamcId using Customer.ConvertToaIdToMamcId if only the ToaId is provided. InsertDate is set to GETUTCDATE().

---

## 2. Business Logic

### 2.1 ToaId to MamcId Auto-Conversion

**Rules**:
- If @mamcId IS NULL AND @toaId IS NOT NULL: derives MamcId via Customer.ConvertToaIdToMamcId(@toaId)
- InsertDate is auto-set to GETUTCDATE() (not caller-provided)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @toaId | nvarchar(150) | NO | - | CODE-BACKED | Transfer of Account identifier. |
| 2 | @fullName | nvarchar(50) | YES | NULL | CODE-BACKED | Lead's full name. |
| 3 | @toaPhone | nvarchar(50) | YES | NULL | CODE-BACKED | Lead's phone number. |
| 4 | @isToaPhoneVerified | bit | YES | NULL | CODE-BACKED | Whether phone was verified. |
| 5 | @chineseIdNumber | nvarchar(50) | YES | NULL | CODE-BACKED | Chinese national ID. |
| 6 | @chineseIdType | nvarchar(50) | YES | NULL | CODE-BACKED | Chinese ID type. |
| 7 | @affiliateId | int | YES | NULL | CODE-BACKED | Referring affiliate. |
| 8 | @mamcId | nvarchar(300) | YES | NULL | CODE-BACKED | MAMC ID. Auto-derived if NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Customer.ToaDetails_Lead | INSERT | Lead storage |
| @toaId | Customer.ConvertToaIdToMamcId | Function call | MamcId derivation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | TOA lead capture |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertToaLeadDetails (procedure)
+-- Customer.ToaDetails_Lead (table)
+-- Customer.ConvertToaIdToMamcId (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ToaDetails_Lead | Table | INSERT INTO |
| Customer.ConvertToaIdToMamcId | Function | ToaId to MamcId conversion |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | TOA lead capture |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert a TOA lead
```sql
EXEC Customer.InsertToaLeadDetails @toaId=N'TOA-12345', @fullName=N'Zhang Wei',
    @toaPhone=N'+8613800138000', @isToaPhoneVerified=1,
    @chineseIdNumber=N'110101199001011234', @chineseIdType=N'ID Card'
```

### 8.2 Read back the lead
```sql
EXEC Customer.GetToaLeadDetails @toaId=N'TOA-12345'
```

### 8.3 Check lead count
```sql
SELECT COUNT(*) FROM Customer.ToaDetails_Lead WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.InsertToaLeadDetails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.InsertToaLeadDetails.sql*
