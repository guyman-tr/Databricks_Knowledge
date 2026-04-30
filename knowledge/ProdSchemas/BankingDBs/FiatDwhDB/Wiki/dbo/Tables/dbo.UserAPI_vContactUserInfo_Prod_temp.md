# dbo.UserAPI_vContactUserInfo_Prod_temp

> Temporary staging table holding raw customer contact information exported from the UserAPI vContactUserInfo view, used for data import and enrichment pipelines.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap table) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

UserAPI_vContactUserInfo_Prod_temp is a temporary staging table that holds raw customer contact information exported from the UserAPI's vContactUserInfo view. It contains PII-adjacent fields like email, address, phone numbers, and geographic identifiers. All columns are nvarchar(100), indicating this is a raw text dump designed for bulk import before data type conversion and validation.

This table exists as a landing zone for UserAPI data imports into the fiat DWH. The "_temp" suffix confirms its transient nature - data is loaded here, processed, and then consumed by downstream tables or reports. It may be truncated and repopulated with each import cycle.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a raw data landing table.

---

## 3. Data Overview

N/A - temporary staging table with PII data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | nvarchar(100) | YES | - | CODE-BACKED | Global Customer ID stored as string (raw import). Nullable for flexibility during bulk loads. |
| 2 | CountryID | nvarchar(100) | YES | - | NAME-INFERRED | Customer's country of residence identifier. |
| 3 | Email | nvarchar(100) | YES | - | NAME-INFERRED | Customer's email address. PII field. |
| 4 | Address | nvarchar(100) | YES | - | NAME-INFERRED | Customer's street address. PII field. |
| 5 | City | nvarchar(100) | YES | - | NAME-INFERRED | Customer's city of residence. |
| 6 | Zip | nvarchar(100) | YES | - | NAME-INFERRED | Customer's postal/zip code. |
| 7 | Phone | nvarchar(100) | YES | - | NAME-INFERRED | Customer's full phone number (prefix + body). PII field. |
| 8 | PhonePrefix | nvarchar(100) | YES | - | NAME-INFERRED | International dialing prefix for the customer's phone. |
| 9 | PhoneBody | nvarchar(100) | YES | - | NAME-INFERRED | Phone number without the international prefix. |
| 10 | Mobile | nvarchar(100) | YES | - | NAME-INFERRED | Customer's mobile phone number. PII field. |
| 11 | Fax | nvarchar(100) | YES | - | NAME-INFERRED | Customer's fax number. Legacy field, rarely populated. |
| 12 | StateID | nvarchar(100) | YES | - | NAME-INFERRED | State/province identifier for the customer's address. |
| 13 | CountryIDByIP | nvarchar(100) | YES | - | NAME-INFERRED | Country detected from the customer's IP address at registration. Used for fraud and compliance checks. |
| 14 | LowerEmail | nvarchar(100) | YES | - | NAME-INFERRED | Lowercased version of the email for case-insensitive matching. |
| 15 | BuildingNumber | nvarchar(100) | YES | - | NAME-INFERRED | Building/house number portion of the address. |
| 16 | RegionID | nvarchar(100) | YES | - | NAME-INFERRED | Geographic region identifier. |
| 17 | RegionByIP_ID | nvarchar(100) | YES | - | NAME-INFERRED | Region detected from IP address at registration. |
| 18 | CitizenshipCountryID | nvarchar(100) | YES | - | NAME-INFERRED | Customer's citizenship country identifier. |
| 19 | POBCountryID | nvarchar(100) | YES | - | NAME-INFERRED | Customer's place-of-birth country identifier. |
| 20 | IsEmailVerified | nvarchar(100) | YES | - | NAME-INFERRED | Whether the customer's email has been verified. Stored as string ("true"/"false" or "1"/"0"). |
| 21 | SubRegionID | nvarchar(100) | YES | - | NAME-INFERRED | Sub-region classification for more granular geographic targeting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No objects reference this temporary staging table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

No indexes (heap table).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check row count
```sql
SELECT COUNT(*) AS Rows FROM dbo.UserAPI_vContactUserInfo_Prod_temp WITH (NOLOCK);
```

### 8.2 Find customers by country
```sql
SELECT TOP 10 GCID, CountryID, Email, City
FROM dbo.UserAPI_vContactUserInfo_Prod_temp WITH (NOLOCK)
WHERE CountryID = '10' ORDER BY GCID;
```

### 8.3 Find IP vs declared country mismatches
```sql
SELECT GCID, CountryID, CountryIDByIP
FROM dbo.UserAPI_vContactUserInfo_Prod_temp WITH (NOLOCK)
WHERE CountryID <> CountryIDByIP AND CountryIDByIP IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 6.8/10 (Elements: 5.2/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 20 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.UserAPI_vContactUserInfo_Prod_temp | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.UserAPI_vContactUserInfo_Prod_temp.sql*
