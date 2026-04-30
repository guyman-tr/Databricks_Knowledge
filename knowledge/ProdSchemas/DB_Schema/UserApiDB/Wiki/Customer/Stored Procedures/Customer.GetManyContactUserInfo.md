# Customer.GetManyContactUserInfo

> Retrieves contact information for multiple customers via the vContactUserInfo view - the legacy contact data access pattern.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns contact info rows via view |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyContactUserInfo retrieves contact data for multiple customers by reading from the Customer.vContactUserInfo view rather than the Customer.ContactUserInfo table directly. The view provides an abstraction layer that may include data transformations or unions not present in the raw table.

This procedure returns the same contact fields as GetManyContactInfo (country, email, address, phone, etc.) but through the view interface.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Batch read via view.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve contact info for. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | CountryID (output) | int | YES | - | CODE-BACKED | Registered country. |
| 4 | Email (output) | nvarchar | YES | - | CODE-BACKED | Email address. |
| 5 | Address (output) | nvarchar | YES | - | CODE-BACKED | Street address. |
| 6 | City (output) | nvarchar | YES | - | CODE-BACKED | City. |
| 7 | Zip (output) | varchar | YES | - | CODE-BACKED | Postal/ZIP code. |
| 8 | Phone (output) | varchar | YES | - | CODE-BACKED | Phone number. |
| 9 | Mobile (output) | varchar | YES | - | CODE-BACKED | Mobile phone. |
| 10 | Fax (output) | varchar | YES | - | CODE-BACKED | Fax number. |
| 11 | StateID (output) | int | YES | - | CODE-BACKED | State/province. |
| 12 | CountryIDByIP (output) | int | YES | - | CODE-BACKED | Country detected from IP. |
| 13 | BuildingNumber (output) | nvarchar | YES | - | CODE-BACKED | Building number. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | Customer.vContactUserInfo | JOIN | Contact data view |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch contact info via view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyContactUserInfo (procedure)
+-- Customer.vContactUserInfo (view)
    +-- Customer.ContactUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.vContactUserInfo | View | FROM - contact data via view abstraction |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get contact user info via view
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002)
EXEC Customer.GetManyContactUserInfo @ids = @ids
```

### 8.2 Direct query equivalent
```sql
SELECT GCID, CountryID, Email, [Address], City, Zip, Phone, Mobile, Fax, StateID, CountryIDByIP, BuildingNumber
FROM Customer.vContactUserInfo cui WITH (NOLOCK)
JOIN @ids ids ON ids.Id = cui.GCID
```

### 8.3 Compare access patterns
```sql
-- GetManyContactUserInfo reads from vContactUserInfo (view)
-- GetManyContactInfo reads from ContactUserInfo (table)
-- Use the view version when the view's abstraction layer is needed
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyContactUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyContactUserInfo.sql*
