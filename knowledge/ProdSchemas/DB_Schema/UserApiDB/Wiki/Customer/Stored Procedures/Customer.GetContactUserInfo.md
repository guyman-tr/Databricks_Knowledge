# Customer.GetContactUserInfo

> Returns contact data for a user via the Customer.vContactUserInfo view (legacy Real_Customer path).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetContactUserInfo is the legacy-path equivalent of GetContactInfo. Reads from Customer.vContactUserInfo (which reads from Real_Customer) instead of Customer.ContactUserInfo directly. Returns similar contact fields but does not include EmailVerificationProviderID (older API contract).

---

## 2. Business Logic

No complex business logic. Single SELECT from the view by GCID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |

Output: GCID, CountryID, Email, Address, City, Zip, Phone, PhonePrefix, PhoneBody, Mobile, Fax, StateID, CountryIDByIP, BuildingNumber, RegionID, RegionByIP_ID, CitizenshipCountryID, POBCountryID, IsEmailVerified, SubRegionID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.vContactUserInfo | SELECT FROM | Legacy contact view |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetContactUserInfo (procedure)
  +-- Customer.vContactUserInfo (view) [done in this batch]
        +-- Real_Customer (dbo synonym/view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.vContactUserInfo | View | SELECT FROM |

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

### 8.1 Get contact user info (legacy path)
```sql
EXEC Customer.GetContactUserInfo @gcid = 12345
```

### 8.2 Compare with modern path
```sql
EXEC Customer.GetContactUserInfo @gcid = 12345  -- legacy (via view)
EXEC Customer.GetContactInfo @gcid = 12345       -- modern (direct table)
```

### 8.3 Direct view query
```sql
SELECT * FROM Customer.vContactUserInfo WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetContactUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetContactUserInfo.sql*
