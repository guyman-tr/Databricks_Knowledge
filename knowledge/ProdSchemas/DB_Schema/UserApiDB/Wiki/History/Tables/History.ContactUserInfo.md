# History.ContactUserInfo

> Audit history table storing temporal snapshots of Customer.ContactUserInfo changes (email, phone, address, country, citizenship).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CustomerVersionID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + NC on GCID,CustomerVersionID DESC) |

---

## 1. Business Meaning

History.ContactUserInfo stores temporal snapshots of contact data changes. Tracks: CountryID, CitizenshipCountryID, RegionID, SubRegionID, Email, Address, BuildingNumber, City, StateID, Zip, Phone, PhonePrefix, PhoneBody, Mobile, Fax, IsEmailVerified, EmailVerificationProviderID.

---

## 2. Business Logic

Same temporal snapshot pattern. ValidTo='3000-01-01' = current version. Populated by UPDATE trigger on Customer.ContactUserInfo.

---

## 3. Data Overview

N/A - large audit history table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerVersionID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Version identifier. |
| 2 | ValidFrom | datetime | NO | - | CODE-BACKED | Version start. |
| 3 | ValidTo | datetime | NO | - | CODE-BACKED | Version end. '3000-01-01' = current. |
| 4 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 5 | CountryID | int | NO | - | CODE-BACKED | Country of residence at this point. |
| 6 | CitizenshipCountryID | int | YES | - | CODE-BACKED | Citizenship country at this point. |
| 7 | RegionID | int | YES | - | CODE-BACKED | Region at this point. |
| 8 | SubRegionID | int | YES | - | CODE-BACKED | Sub-region at this point. |
| 9 | Email | varchar(50) | YES | - | CODE-BACKED | Email at this point. |
| 10 | Address | nvarchar(100) | YES | - | CODE-BACKED | Street address at this point. |
| 11 | BuildingNumber | nvarchar(30) | YES | - | CODE-BACKED | Building number at this point. |
| 12 | City | nvarchar(50) | YES | - | CODE-BACKED | City at this point. |
| 13 | StateID | int | NO | - | CODE-BACKED | State at this point. |
| 14 | Zip | nvarchar(50) | YES | - | CODE-BACKED | Postal code at this point. |
| 15 | Phone | varchar(30) | YES | - | CODE-BACKED | Phone at this point. |
| 16 | PhonePrefix | nvarchar(6) | YES | - | CODE-BACKED | Phone prefix at this point. |
| 17 | PhoneBody | nvarchar(24) | YES | - | CODE-BACKED | Phone body at this point. |
| 18 | Mobile | varchar(30) | YES | - | CODE-BACKED | Mobile at this point. |
| 19 | Fax | varchar(30) | YES | - | CODE-BACKED | Fax at this point. |
| 20 | IsEmailVerified | bit | YES | - | CODE-BACKED | Email verification status at this point. |
| 21 | EmailVerificationProviderID | int | YES | - | CODE-BACKED | How email was verified at this point. |
| 22 | Trace | nvarchar(max) | NO | JSON | CODE-BACKED | Connection audit context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK constraints.

### 5.2 Referenced By (other objects point to this)

Populated by triggers on Customer.ContactUserInfo.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Triggers on Customer.ContactUserInfo.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryContactUserInfo | CLUSTERED PK | CustomerVersionID | - | - | Active |
| Idx_HistoryContact_GCID_CustomerVersionID | NONCLUSTERED | GCID ASC, CustomerVersionID DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_HistoryContactUserInfo_Trace | DEFAULT | Connection context JSON |

---

## 8. Sample Queries

### 8.1 Email change history
```sql
SELECT ValidFrom, ValidTo, Email, CountryID FROM History.ContactUserInfo WITH (NOLOCK) WHERE GCID = @GCID ORDER BY CustomerVersionID DESC
```

### 8.2 Country change history
```sql
SELECT h.ValidFrom, c.Name AS Country FROM History.ContactUserInfo h WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON h.CountryID = c.CountryID WHERE h.GCID = @GCID ORDER BY h.ValidFrom
```

### 8.3 Address at a point in time
```sql
SELECT Address, City, Zip FROM History.ContactUserInfo WITH (NOLOCK)
WHERE GCID = @GCID AND ValidFrom <= @Date AND ValidTo > @Date
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.ContactUserInfo | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.ContactUserInfo.sql*
