# Customer.ToaDetails_Registration

> Stores registration-stage Transfer of Account (TOA) details linking migrated users to their eToro GCID after successful registration.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (PK + unique on ToaId + NC on MamcId) |

---

## 1. Business Meaning

Customer.ToaDetails_Registration is the companion table to ToaDetails_Lead. After a TOA lead successfully registers on eToro and receives a GCID, their partner platform identity data is recorded here, linking the external ToaId to the internal GCID. The unique constraint on ToaId ensures each partner account maps to exactly one eToro account.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ToaId | nvarchar(150) | NO | - | CODE-BACKED | External identifier from the partner platform. Uniquely indexed - one partner account per eToro account. |
| 2 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID of the registered eToro user. One TOA registration per GCID. |
| 3 | FullName | nvarchar(50) MASKED | YES | - | CODE-BACKED | User's full name from partner platform. Dynamic data masking applied. |
| 4 | ToaPhone | nvarchar(50) MASKED | YES | - | CODE-BACKED | Phone number from partner platform. Dynamic data masking applied. |
| 5 | IsToaPhoneVerified | bit | YES | - | CODE-BACKED | Whether phone was verified on partner platform. |
| 6 | ChineseIdNumber | nvarchar(50) MASKED | YES | - | CODE-BACKED | Chinese national ID number. Dynamic data masking applied. |
| 7 | ChineseIdType | nvarchar(50) | YES | - | CODE-BACKED | Type of Chinese identification document. |
| 8 | AffiliateId | int | YES | - | CODE-BACKED | Partner/affiliate that referred this user. |
| 9 | InsertDate | smalldatetime | NO | - | CODE-BACKED | When this registration record was created. |
| 10 | MamcId | nvarchar(100) | YES | - | CODE-BACKED | Internal MAMC identifier derived from ToaId. Indexed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.InsertToaRegistrationDetails | GCID | SP writes | Creates registration records |
| Customer.GetToaRegistrationDetails | ToaId | SP reads | Retrieves by ToaId |
| Customer.GetToaRegistrationDetailsByGcid | GCID | SP reads | Retrieves by GCID |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.InsertToaRegistrationDetails | Stored Procedure | Inserts rows |
| Customer.GetToaRegistrationDetails | Stored Procedure | Reads from |
| Customer.GetToaRegistrationDetailsByGcid | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerToaDetails_Registration | CLUSTERED PK | GCID | - | - | Active (PAGE compressed) |
| UNQ_CustomerToaDetails_Registration_ToaId | NC UNIQUE | ToaId | - | - | Active (PAGE compressed) |
| IDX_ToaDetails_Registration_MamcId | NONCLUSTERED | MamcId | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UNQ_CustomerToaDetails_Registration_ToaId | UNIQUE | One eToro account per partner ToaId |

---

## 8. Sample Queries

### 8.1 Find registration by ToaId
```sql
SELECT GCID, MamcId, InsertDate FROM Customer.ToaDetails_Registration WITH (NOLOCK) WHERE ToaId = @ToaId
```

### 8.2 Find registration by GCID
```sql
SELECT ToaId, MamcId, AffiliateId FROM Customer.ToaDetails_Registration WITH (NOLOCK) WHERE GCID = @GCID
```

### 8.3 Match leads to registrations
```sql
SELECT l.ToaId, l.InsertDate AS LeadDate, r.GCID, r.InsertDate AS RegDate
FROM Customer.ToaDetails_Lead l WITH (NOLOCK)
LEFT JOIN Customer.ToaDetails_Registration r WITH (NOLOCK) ON l.ToaId = r.ToaId
ORDER BY l.InsertDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.ToaDetails_Registration | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.ToaDetails_Registration.sql*
