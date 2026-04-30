# Customer.GetValidationExtendedUserFieldByCountriesId_GCID

> Retrieves extended user field values in batches of 1000 for validation purposes - supports filtering by countries+fields or GCIDs+fields with cursor-based pagination via @LastGCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 1000 extended field rows with pagination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetValidationExtendedUserFieldByCountriesId_GCID is a batch-oriented validation procedure for extended user fields. It retrieves extended field values with fast verification data, supporting two modes: by country list (for regulatory batch validation across all users in specific countries) or by GCID list (for targeted validation of specific users). Pagination is handled via @LastGCID cursor (returns records with GCID > @LastGCID, ordered ascending).

This procedure supports compliance teams running batch validation of tax IDs, national PINs, and other regulatory fields across entire country populations.

---

## 2. Business Logic

### 2.1 Dual Filter Mode

**What**: Two code paths based on whether @CountriesId has entries.

**Rules**:
- If @CountriesId has rows: filter by CountryId IN @CountriesId AND FieldId IN @FieldsId AND GCID > @LastGCID
- If @CountriesId is empty: filter by GCID IN @GCIDs AND FieldId IN @FieldsId AND GCID > @LastGCID
- Both paths: TOP 1000, ORDER BY GCID ASC (cursor-based pagination)
- Both paths include FastVerificationData via LEFT JOIN

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCIDs | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to filter (used when @CountriesId is empty). |
| 2 | @CountriesId | dbo.IdList (TVP) | NO | - | CODE-BACKED | Country IDs to filter. If non-empty, takes precedence over @GCIDs. |
| 3 | @FieldsId | dbo.IdList (TVP) | NO | - | CODE-BACKED | Extended field IDs to retrieve (e.g., 6=TaxId, 7=NationalPin). |
| 4 | @LastGCID | int | NO | - | CODE-BACKED | Pagination cursor: returns only GCID > this value. Pass 0 for first page. |
| 5 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 6 | FieldId (output) | int | NO | - | CODE-BACKED | Extended field type. |
| 7 | Value (output) | nvarchar(128) | YES | - | CODE-BACKED | Field value. |
| 8 | LastModified (output) | datetime | NO | - | CODE-BACKED | Last modification date. |
| 9 | ID (output) | int | NO | - | CODE-BACKED | ExtendedUserField row ID. |
| 10 | CountryId (output) | int | YES | - | CODE-BACKED | Country context. |
| 11 | TypeId (output) | int | YES | - | CODE-BACKED | Value subtype. |
| 12 | AdditionalDetails (output) | varchar(max) | YES | - | CODE-BACKED | Additional JSON data. |
| 13 | ExtendedUserValueTypeId (output) | int | YES | - | CODE-BACKED | Fast verification value type. |
| 14 | MedicareReference (output) | varchar | YES | - | CODE-BACKED | Medicare reference (Australia). |
| 15 | MedicareColor (output) | varchar | YES | - | CODE-BACKED | Medicare card color. |
| 16 | ExpirationDate (output) | date | YES | - | CODE-BACKED | Document expiration. |
| 17 | ProvinceId (output) | int | YES | - | CODE-BACKED | Province ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.ExtendedUserField | FROM | Field values |
| ID | Customer.FastVerificationData | LEFT JOIN | Verification metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch field validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetValidationExtendedUserFieldByCountriesId_GCID (procedure)
+-- Customer.ExtendedUserField (table)
+-- Customer.FastVerificationData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserField | Table | FROM - field values |
| Customer.FastVerificationData | Table | LEFT JOIN - verification data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Batch validation jobs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get tax IDs for Italy (first page)
```sql
DECLARE @GCIDs dbo.IdList, @Countries dbo.IdList, @Fields dbo.IdList
INSERT @Countries VALUES (106)
INSERT @Fields VALUES (6) -- TaxId
EXEC Customer.GetValidationExtendedUserFieldByCountriesId_GCID
    @GCIDs=@GCIDs, @CountriesId=@Countries, @FieldsId=@Fields, @LastGCID=0
```

### 8.2 Get national PINs for specific users
```sql
DECLARE @GCIDs dbo.IdList, @Countries dbo.IdList, @Fields dbo.IdList
INSERT @GCIDs VALUES (1001), (1002)
INSERT @Fields VALUES (7) -- NationalPin
EXEC Customer.GetValidationExtendedUserFieldByCountriesId_GCID
    @GCIDs=@GCIDs, @CountriesId=@Countries, @FieldsId=@Fields, @LastGCID=0
```

### 8.3 Pagination - next page after GCID 50000
```sql
EXEC Customer.GetValidationExtendedUserFieldByCountriesId_GCID
    @GCIDs=@GCIDs, @CountriesId=@Countries, @FieldsId=@Fields, @LastGCID=50000
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetValidationExtendedUserFieldByCountriesId_GCID | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetValidationExtendedUserFieldByCountriesId_GCID.sql*
