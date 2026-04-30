# Customer.InsertToaRegistrationDetails

> Inserts Transfer of Account (TOA) post-registration details linking the TOA/MAMC ID to the newly created GCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Customer.ToaDetails_Registration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertToaRegistrationDetails records the TOA registration data after a customer completes account creation. Unlike InsertToaLeadDetails (pre-registration), this procedure includes the GCID (assigned during registration) and links the TOA transfer to the actual customer account. It is called by InsertNewCustomer and InsertRealCustomer as part of the registration transaction.

InsertDate is auto-set to GETUTCDATE().

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple INSERT.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @toaId | nvarchar(150) | NO | - | CODE-BACKED | Transfer of Account identifier. |
| 2 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID (assigned during registration). |
| 3 | @fullName | nvarchar(50) | YES | NULL | CODE-BACKED | Customer's full name. |
| 4 | @toaPhone | nvarchar(50) | YES | NULL | CODE-BACKED | Phone number. |
| 5 | @isToaPhoneVerified | bit | YES | NULL | CODE-BACKED | Phone verified flag. |
| 6 | @chineseIdNumber | nvarchar(50) | YES | NULL | CODE-BACKED | Chinese ID number. |
| 7 | @chineseIdType | nvarchar(50) | YES | NULL | CODE-BACKED | Chinese ID type. |
| 8 | @affiliateId | int | YES | NULL | CODE-BACKED | Referring affiliate. |
| 9 | @MamcId | nvarchar(300) | YES | NULL | CODE-BACKED | MAMC identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Customer.ToaDetails_Registration | INSERT | Registration storage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.InsertNewCustomer | - | EXEC | Called during registration |
| Customer.InsertRealCustomer | - | EXEC | Called during registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertToaRegistrationDetails (procedure)
+-- Customer.ToaDetails_Registration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ToaDetails_Registration | Table | INSERT INTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.InsertNewCustomer | Procedure | EXEC |
| Customer.InsertRealCustomer | Procedure | EXEC |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert TOA registration
```sql
EXEC Customer.InsertToaRegistrationDetails @toaId=N'TOA-12345', @gcid=50001,
    @fullName=N'Zhang Wei', @toaPhone=N'+8613800138000', @isToaPhoneVerified=1
```

### 8.2 Read back registration
```sql
EXEC Customer.GetToaRegistrationDetails @toaId=N'TOA-12345'
```

### 8.3 Read by GCID
```sql
EXEC Customer.GetToaRegistrationDetailsByGcid @gcid=50001
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.InsertToaRegistrationDetails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.InsertToaRegistrationDetails.sql*
