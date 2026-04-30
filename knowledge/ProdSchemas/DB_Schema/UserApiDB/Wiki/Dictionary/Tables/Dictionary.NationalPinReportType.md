# Dictionary.NationalPinReportType

> Lookup table defining reporting format types for national identification numbers in regulatory transaction filings.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | NationalPinReportTypeID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.NationalPinReportType defines the formats in which national personal identification numbers are reported to financial regulators. When eToro files transaction reports (e.g., MiFID II transaction reporting to national competent authorities), each client's national identifier must be formatted according to specific standards. This table defines those format standards.

This table exists because different types of national identifiers must be reported in different formats. A national ID number is reported as NIND, a passport concatenated with country code as CCCP, and a legal entity as LEI. The reporting system needs to know which format to use for each client's identifier type.

Report types are linked to ExtendedUserValueType (the specific kind of national identifier) through the junction table Dictionary.NationalPinValueTypeToReportType. When generating regulatory reports, the system looks up the appropriate report format for each user's identifier type.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| NationalPinReportTypeID | Name | Meaning |
|---|---|---|
| 1 | NIND | National Identifier - standard format for national ID numbers (SSN, national insurance, fiscal codes) |
| 2 | CCCP | Country Code + Client Passport - concatenated format: 2-letter country ISO + passport number |
| 3 | CONCAT | Concatenated Identifier - country code + national ID for composite reporting |
| 4 | LEI | Legal Entity Identifier - 20-character alphanumeric code for corporate/institutional clients |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NationalPinReportTypeID | int | NO | - | CODE-BACKED | Primary key. Report format: 1=NIND (national ID), 2=CCCP (country+passport), 3=CONCAT (country+ID), 4=LEI (legal entity). Referenced by NationalPinValueTypeToReportType junction table. See [National Pin Report Type](_glossary.md#national-pin-report-type). |
| 2 | Name | varchar(100) | NO | - | CODE-BACKED | Report format code used in regulatory filing systems. Matches ESMA/MiFID II identifier type codes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.NationalPinValueTypeToReportType | NationalPinReportTypeID | Explicit FK | Maps identifier subtypes to their regulatory reporting format |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.NationalPinValueTypeToReportType | Table | FK to NationalPinReportTypeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_NationalPinReportType | CLUSTERED PK | NationalPinReportTypeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all report types
```sql
SELECT NationalPinReportTypeID, Name
FROM Dictionary.NationalPinReportType WITH (NOLOCK)
ORDER BY NationalPinReportTypeID
```

### 8.2 Show value type to report type mapping
```sql
SELECT vt.Name AS ValueType, rt.Name AS ReportFormat
FROM Dictionary.NationalPinValueTypeToReportType m WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON m.ValueTypeID = vt.ValueTypeID
JOIN Dictionary.NationalPinReportType rt WITH (NOLOCK) ON m.NationalPinReportTypeID = rt.NationalPinReportTypeID
ORDER BY rt.Name, vt.Name
```

### 8.3 Find which identifier types use LEI format
```sql
SELECT vt.Name AS ValueType
FROM Dictionary.NationalPinValueTypeToReportType m WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON m.ValueTypeID = vt.ValueTypeID
WHERE m.NationalPinReportTypeID = 4 -- LEI
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.NationalPinReportType | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.NationalPinReportType.sql*
