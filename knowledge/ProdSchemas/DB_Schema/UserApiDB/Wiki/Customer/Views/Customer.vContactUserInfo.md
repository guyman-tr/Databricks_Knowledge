# Customer.vContactUserInfo

> View providing read access to user contact information from the Real_Customer legacy table, exposing the same columns as Customer.ContactUserInfo.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID (from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.vContactUserInfo is a compatibility view that exposes contact information by reading from the `Real_Customer` table (a dbo synonym/legacy view). It returns the same columns as Customer.ContactUserInfo: email, phone, address, country, citizenship, region, and email verification status. The view uses WITH(NOLOCK) for non-blocking reads.

This view exists to provide a stable interface for stored procedures and application code that need contact data through the legacy Real_Customer path rather than the Customer.ContactUserInfo table directly. Several stored procedures (like GetContactUserInfo) read from this view.

---

## 2. Business Logic

No complex business logic. Simple passthrough SELECT from Real_Customer with NOLOCK hint.

---

## 3. Data Overview

N/A - view mirrors Customer.ContactUserInfo data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. From Real_Customer. |
| 2 | CountryID | int | NO | - | CODE-BACKED | Self-declared country of residence. See [Country](_glossary.md#country). |
| 3 | Email | varchar(50) | YES | - | CODE-BACKED | User's email address. |
| 4 | Address | nvarchar(100) | YES | - | CODE-BACKED | Street address. |
| 5 | City | nvarchar(50) | YES | - | CODE-BACKED | City name. |
| 6 | Zip | nvarchar(50) | YES | - | CODE-BACKED | Postal/ZIP code. |
| 7 | Phone | varchar(30) | YES | - | CODE-BACKED | Full phone number (legacy format). |
| 8 | PhonePrefix | nvarchar(6) | YES | - | CODE-BACKED | International dialing prefix. |
| 9 | PhoneBody | nvarchar(24) | YES | - | CODE-BACKED | Phone number without prefix. |
| 10 | Mobile | varchar(30) | YES | - | CODE-BACKED | Mobile phone number. |
| 11 | Fax | varchar(30) | YES | - | CODE-BACKED | Fax number (legacy). |
| 12 | StateID | int | NO | - | CODE-BACKED | State/province. See [State](_glossary.md#state). |
| 13 | CountryIDByIP | int | NO | - | CODE-BACKED | IP-detected country at registration. |
| 14 | LowerEmail | computed | - | - | CODE-BACKED | Lowercase email for case-insensitive lookups. |
| 15 | BuildingNumber | nvarchar(30) | YES | - | CODE-BACKED | Building/house number. |
| 16 | RegionID | int | YES | - | CODE-BACKED | User's region within country. |
| 17 | RegionByIP_ID | int | YES | - | CODE-BACKED | IP-detected region. |
| 18 | CitizenshipCountryID | int | YES | - | CODE-BACKED | Nationality for tax/sanctions. |
| 19 | POBCountryID | int | YES | - | CODE-BACKED | Place of birth country. |
| 20 | IsEmailVerified | bit | YES | - | CODE-BACKED | Whether email has been verified. |
| 21 | SubRegionID | int | YES | - | CODE-BACKED | Sub-region within the region. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Real_Customer (dbo) | FROM | Base data source |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.GetContactUserInfo | GCID | SP reads | Returns contact data via this view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.vContactUserInfo (view)
  +-- Real_Customer (dbo synonym/table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Real_Customer | dbo synonym/table | SELECT FROM |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetContactUserInfo | Stored Procedure | Reads from this view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (no SCHEMABINDING, no indexed view).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get contact info via view
```sql
SELECT GCID, CountryID, Email, City, Phone FROM Customer.vContactUserInfo WITH (NOLOCK) WHERE GCID = @GCID
```

### 8.2 Find user by email
```sql
SELECT GCID FROM Customer.vContactUserInfo WITH (NOLOCK) WHERE LowerEmail = LOWER(@Email)
```

### 8.3 Users by country
```sql
SELECT CountryID, COUNT(*) AS UserCount FROM Customer.vContactUserInfo WITH (NOLOCK) GROUP BY CountryID ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: Customer.vContactUserInfo | Type: View | Source: UserApiDB/UserApiDB/Customer/Views/Customer.vContactUserInfo.sql*
