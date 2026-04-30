# Customer.GetContactInfo

> Returns the full contact profile for a user directly from Customer.ContactUserInfo.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetContactInfo retrieves the complete contact record for a user directly from Customer.ContactUserInfo (not through the legacy Real_Customer path). Returns all contact fields: country (residence, IP, citizenship, POB), email, address, phone, region, sub-region, email verification status and provider.

---

## 2. Business Logic

No complex business logic. Single SELECT by GCID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |

Output: GCID, CountryID, Email, Address, City, Zip, Phone, PhonePrefix, PhoneBody, Mobile, Fax, StateID, CountryIDByIP, BuildingNumber, RegionID, RegionByIP_ID, CitizenshipCountryID, POBCountryID, IsEmailVerified, SubRegionID, EmailVerificationProviderID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.ContactUserInfo | SELECT FROM | Full contact record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetContactInfo (procedure)
  +-- Customer.ContactUserInfo (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ContactUserInfo | Table | SELECT FROM |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get contact info
```sql
EXEC Customer.GetContactInfo @gcid = 12345
```

### 8.2 With country names
```sql
DECLARE @R TABLE (GCID INT, CountryID INT, Email VARCHAR(50), Address NVARCHAR(100), City NVARCHAR(50), Zip NVARCHAR(50), Phone VARCHAR(30), PhonePrefix NVARCHAR(6), PhoneBody NVARCHAR(24), Mobile VARCHAR(30), Fax VARCHAR(30), StateID INT, CountryIDByIP INT, BuildingNumber NVARCHAR(30), RegionID INT, RegionByIP_ID INT, CitizenshipCountryID INT, POBCountryID INT, IsEmailVerified BIT, SubRegionID INT, EmailVerificationProviderID INT)
INSERT INTO @R EXEC Customer.GetContactInfo @gcid = 12345
SELECT r.Email, c.Name AS Country FROM @R r JOIN Dictionary.Country c WITH (NOLOCK) ON r.CountryID = c.CountryID
```

### 8.3 Direct query
```sql
SELECT * FROM Customer.ContactUserInfo WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetContactInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetContactInfo.sql*
