# Dictionary.NationalPinValueTypeToReportType

> Junction table mapping ExtendedUserValueType national identifiers to their regulatory reporting format (NIND, CCCP, CONCAT, LEI).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ValueTypeID + NationalPinReportTypeID (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.NationalPinValueTypeToReportType is a junction table that maps each type of national identifier (from Dictionary.ExtendedUserValueType) to its appropriate regulatory reporting format (from Dictionary.NationalPinReportType). This mapping is essential for MiFID II transaction reporting, where each client's identifier must be formatted according to specific ESMA standards.

For example, a user with a National Number (ValueTypeID=39) is reported using NIND format, while a user with a Passport Number (ValueTypeID=40) uses CCCP format (Country Code + Passport), and corporate clients with LEI (ValueTypeID=37) use LEI format.

---

## 2. Business Logic

### 2.1 Identifier-to-Report Format Mapping

**What**: 9 mappings connecting identifier types to their regulatory reporting format.

**Columns/Parameters Involved**: `ValueTypeID`, `NationalPinReportTypeID`

**Rules**:
- LEI (37) -> LEI report (4) - corporate identifier
- CONCAT (38) -> CONCAT report (3) - concatenated format
- NationalNumber (39) -> NIND report (1) - standard national ID
- PassportNumber (40) -> CCCP report (2) - country code + passport
- TaxNumber (41), NationalInsuranceNumber (42), InvestorShare (43), FiscalCode (44), SocialSecurityNumberPIN (69) -> NIND report (1)

---

## 3. Data Overview

| ValueTypeID | NationalPinReportTypeID | Meaning |
|---|---|---|
| 37 | 4 (LEI) | Legal Entity Identifier reported as LEI |
| 38 | 3 (CONCAT) | Concatenated identifier uses CONCAT format |
| 39 | 1 (NIND) | National Number reported as NIND |
| 40 | 2 (CCCP) | Passport Number uses Country Code + Passport format |
| 41 | 1 (NIND) | Tax Number reported as NIND |

*5 of 9 rows shown.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ValueTypeID | int | NO | - | CODE-BACKED | Part of composite PK. FK to Dictionary.ExtendedUserValueType. The national identifier subtype. |
| 2 | NationalPinReportTypeID | int | NO | - | CODE-BACKED | Part of composite PK. FK to Dictionary.NationalPinReportType. The regulatory reporting format (1=NIND, 2=CCCP, 3=CONCAT, 4=LEI). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ValueTypeID | Dictionary.ExtendedUserValueType | Explicit FK | The identifier subtype being mapped |
| NationalPinReportTypeID | Dictionary.NationalPinReportType | Explicit FK | The reporting format to use |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.NationalPinValueTypeToReportType (table)
  +-- Dictionary.ExtendedUserValueType (table)
  |     +-- Dictionary.ExtendedUserFieldType (table)
  +-- Dictionary.NationalPinReportType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExtendedUserValueType | Table | FK: ValueTypeID |
| Dictionary.NationalPinReportType | Table | FK: NationalPinReportTypeID |

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_NationalPinValueTypeToReportType | CLUSTERED PK | ValueTypeID, NationalPinReportTypeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_..._NationalPinReportTypeID | FOREIGN KEY | NationalPinReportTypeID -> Dictionary.NationalPinReportType(NationalPinReportTypeID) |
| FK_..._ValueTypeID | FOREIGN KEY | ValueTypeID -> Dictionary.ExtendedUserValueType(ValueTypeID) |

---

## 8. Sample Queries

### 8.1 Full mapping with names
```sql
SELECT vt.Name AS ValueType, rt.Name AS ReportFormat
FROM Dictionary.NationalPinValueTypeToReportType m WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON m.ValueTypeID = vt.ValueTypeID
JOIN Dictionary.NationalPinReportType rt WITH (NOLOCK) ON m.NationalPinReportTypeID = rt.NationalPinReportTypeID
ORDER BY rt.Name, vt.Name
```

### 8.2 All identifier types using NIND format
```sql
SELECT vt.Name FROM Dictionary.NationalPinValueTypeToReportType m WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON m.ValueTypeID = vt.ValueTypeID
WHERE m.NationalPinReportTypeID = 1
```

### 8.3 Count identifiers per report format
```sql
SELECT rt.Name, COUNT(*) AS IdentifierCount FROM Dictionary.NationalPinValueTypeToReportType m WITH (NOLOCK)
JOIN Dictionary.NationalPinReportType rt WITH (NOLOCK) ON m.NationalPinReportTypeID = rt.NationalPinReportTypeID
GROUP BY rt.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.NationalPinValueTypeToReportType | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.NationalPinValueTypeToReportType.sql*
