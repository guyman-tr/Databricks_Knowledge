# Dictionary.ExtendedUserValueType

> Lookup table defining specific subtypes of extended user field values, primarily country-specific Tax ID and NationalPin classifications.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ValueTypeID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.ExtendedUserValueType provides country-specific subtypes for Tax ID and NationalPin extended user fields. While Dictionary.ExtendedUserField defines the broad field categories, this table specifies the exact document type within that category. For example, under "Tax ID" (FieldTypeID=3), there are 20+ country-specific subtypes: taxCPR (Denmark), taxUTR (UK), taxTFN (Australia), taxCPF (Brazil), etc.

This granularity is essential for regulatory reporting. When filing tax reports with different national authorities, the platform must know exactly what type of identifier a user provided. The NationalPinValueTypeToReportType junction table maps each value type to its regulatory reporting format (NIND, CCCP, CONCAT, LEI).

---

## 2. Business Logic

### 2.1 Value Type Categories

**What**: 43 value subtypes grouped by parent field type.

**Columns/Parameters Involved**: `ValueTypeID`, `Name`, `FieldTypeID`

**Rules**:
- NationalPin (FieldTypeID=4): LEI, CONCAT, NationalNumber, PassportNumber, TaxNumber, NationalInsuranceNumber, InvestorShare, FiscalCode, SocialSecurityNumberPIN, Medicare, DrivingLicense, NRIC (IDs 37-44, 69, 76-78)
- Tax ID (FieldTypeID=3): 20+ country-specific tax ID types (IDs 45-68, 71-75, 79)
- DedicatedEv (FieldTypeID=9): Nin (ID 70) - specific to dedicated electronic verification

---

## 3. Data Overview

| ValueTypeID | Name | FieldTypeID | Meaning |
|---|---|---|---|
| 37 | LEI | 4 (NationalPin) | Legal Entity Identifier - 20-char code for corporate clients |
| 46 | taxID | 3 (Tax ID) | Generic tax ID subtype |
| 53 | taxTFN | 3 (Tax ID) | Australian Tax File Number |
| 57 | taxPAN | 3 (Tax ID) | Indian Permanent Account Number |
| 69 | SocialSecurityNumberPIN | 4 (NationalPin) | Social Security Number used as national PIN |

*5 of 43 rows shown.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ValueTypeID | int | NO | - | CODE-BACKED | Primary key. Value subtype identifier (37-79). Referenced by NationalPinValueTypeToReportType for regulatory reporting format. See [Extended User Value Type](_glossary.md#extended-user-value-type). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Value subtype name. camelCase for tax IDs (taxCPR), PascalCase for national PINs (NationalNumber). |
| 3 | FieldTypeID | int | YES | - | CODE-BACKED | FK to Dictionary.ExtendedUserFieldType. Parent field type: 3=Tax ID, 4=NationalPin, 9=DedicatedEv. |
| 4 | ExtendedUserValueTypeShortName | nvarchar(50) | YES | - | CODE-BACKED | Shortened name for API responses. Typically matches Name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FieldTypeID | Dictionary.ExtendedUserFieldType | Explicit FK | Parent field type category |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.NationalPinValueTypeToReportType | ValueTypeID | Explicit FK | Maps value types to regulatory reporting formats |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.ExtendedUserValueType (table)
  +-- Dictionary.ExtendedUserFieldType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExtendedUserFieldType | Table | FK: FieldTypeID -> UserFieldTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.NationalPinValueTypeToReportType | Table | FK: ValueTypeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExtendedUserValueType | CLUSTERED PK | ValueTypeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_Dictionary_ExtendedUserValueType_FieldTypeID | FOREIGN KEY | FieldTypeID -> Dictionary.ExtendedUserFieldType(UserFieldTypeId) |

---

## 8. Sample Queries

### 8.1 List value types with parent field type
```sql
SELECT vt.ValueTypeID, vt.Name, ft.Name AS FieldType FROM Dictionary.ExtendedUserValueType vt WITH (NOLOCK)
JOIN Dictionary.ExtendedUserFieldType ft WITH (NOLOCK) ON vt.FieldTypeID = ft.UserFieldTypeId ORDER BY vt.ValueTypeID
```

### 8.2 All tax ID subtypes
```sql
SELECT ValueTypeID, Name, ExtendedUserValueTypeShortName FROM Dictionary.ExtendedUserValueType WITH (NOLOCK)
WHERE FieldTypeID = 3 ORDER BY Name
```

### 8.3 Value types with reporting format
```sql
SELECT vt.Name AS ValueType, rt.Name AS ReportFormat
FROM Dictionary.NationalPinValueTypeToReportType m WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON m.ValueTypeID = vt.ValueTypeID
JOIN Dictionary.NationalPinReportType rt WITH (NOLOCK) ON m.NationalPinReportTypeID = rt.NationalPinReportTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.ExtendedUserValueType | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.ExtendedUserValueType.sql*
