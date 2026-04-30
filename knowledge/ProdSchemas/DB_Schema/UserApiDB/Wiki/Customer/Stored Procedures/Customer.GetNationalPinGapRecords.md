# Customer.GetNationalPinGapRecords

> Finds customers who made an approved deposit in the last 7 days but do NOT have a National PIN on file and are NOT from an excluded country list - used for compliance gap detection.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 150 customers with National PIN gaps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetNationalPinGapRecords identifies customers with a compliance gap: they have made an approved real-money deposit within the last 7 days but have not yet provided a National PIN (FieldId=7 in Customer.ExtendedUserField). This is a regulatory requirement in certain jurisdictions - once a customer deposits, they must provide their national identification number.

The procedure also excludes customers from a caller-provided list of countries where National PIN is not required. This allows the compliance team to focus on customers in jurisdictions where this field is mandatory.

The procedure returns TOP 150 records for batch processing, ordered implicitly by the query plan. It reads from Real_Customer, Deposit, and Customer.ExtendedUserField.

---

## 2. Business Logic

### 2.1 National PIN Gap Detection

**What**: Finds depositing customers who are missing their National PIN, excluding exempt countries.

**Columns/Parameters Involved**: `@CountryList`, `PaymentStatusID`, `FieldId`, `PaymentDate`

**Rules**:
- Customer's CountryID must NOT be in @CountryList (excluded countries where NatPIN is not required)
- Customer must have at least one Deposit with PaymentStatusID = 2 (Approved) in the last 7 days
- Customer must NOT have any ExtendedUserField record with FieldId = 7 (NationalPin)
- Returns TOP 150 records per call (batch processing limit)
- 7-day window is calculated as GETUTCDATE() - 7 (cast to date for index-friendly comparison)

**Diagram**:
```
Real_Customer
  WHERE CountryID NOT IN @CountryList (exempt countries excluded)
  AND EXISTS (
    Deposit WHERE PaymentStatusID = 2 AND PaymentDate > (UTC - 7 days)
  )
  AND NOT EXISTS (
    ExtendedUserField WHERE FieldId = 7 (NationalPin)
  )
  |
  v
TOP 150: CID, GCID, BirthDate, FirstName, LastName, CountryID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryList | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of country IDs to EXCLUDE from results (countries where National PIN is not required). |
| 2 | CID (output) | int | NO | - | CODE-BACKED | Customer ID. |
| 3 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 4 | BirthDate (output) | datetime | YES | - | CODE-BACKED | Date of birth. |
| 5 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | First name. |
| 6 | LastName (output) | nvarchar | YES | - | CODE-BACKED | Last name. |
| 7 | CountryID (output) | int | YES | - | CODE-BACKED | Registered country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | @CountryList | LEFT JOIN (IS NULL) | Excludes exempt countries |
| CID | dbo.Deposit | EXISTS | Checks for recent approved deposits |
| GCID | Customer.ExtendedUserField | NOT EXISTS | Checks NatPIN is missing |
| - | dbo.Real_Customer | FROM | Core customer data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Compliance gap batch processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetNationalPinGapRecords (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Deposit (table)
+-- Customer.ExtendedUserField (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - customer data |
| dbo.Deposit | Table | EXISTS - recent approved deposits |
| Customer.ExtendedUserField | Table | NOT EXISTS - NatPIN gap check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by compliance batch jobs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find National PIN gaps excluding US and UK
```sql
DECLARE @ExcludedCountries dbo.IdList
INSERT @ExcludedCountries VALUES (234), (231) -- US, UK
EXEC Customer.GetNationalPinGapRecords @CountryList = @ExcludedCountries
```

### 8.2 Direct query equivalent
```sql
DECLARE @CurrDate DATETIME = CAST(GETUTCDATE() - 7 AS Date)
SELECT TOP 150 CC.CID, CC.GCID, CC.BirthDate, CC.FirstName, CC.LastName, CC.CountryID
FROM dbo.Real_Customer CC WITH (NOLOCK)
LEFT JOIN @CountryList cl ON CC.CountryID = cl.Id
WHERE cl.Id IS NULL
    AND EXISTS (SELECT 1 FROM dbo.Deposit D WITH (NOLOCK)
                WHERE D.CID = CC.CID AND D.PaymentStatusID = 2 AND D.PaymentDate > @CurrDate)
    AND NOT EXISTS (SELECT 1 FROM Customer.ExtendedUserField EF WITH (NOLOCK)
                    WHERE EF.GCID = CC.GCID AND EF.FieldId = 7)
```

### 8.3 Count total gap records (without TOP limit)
```sql
DECLARE @CurrDate DATETIME = CAST(GETUTCDATE() - 7 AS Date)
SELECT COUNT(*)
FROM dbo.Real_Customer CC WITH (NOLOCK)
LEFT JOIN @CountryList cl ON CC.CountryID = cl.Id
WHERE cl.Id IS NULL
    AND EXISTS (SELECT 1 FROM dbo.Deposit D WITH (NOLOCK)
                WHERE D.CID = CC.CID AND D.PaymentStatusID = 2 AND D.PaymentDate > @CurrDate)
    AND NOT EXISTS (SELECT 1 FROM Customer.ExtendedUserField EF WITH (NOLOCK)
                    WHERE EF.GCID = CC.GCID AND EF.FieldId = 7)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetNationalPinGapRecords | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetNationalPinGapRecords.sql*
