# Customer.CustomerLatinName_Ver2

> Legacy version of Customer.CustomerLatinName containing only CID, FirstName, LastName, and ModifiedDate - an earlier schema before Address, City, and MiddleName fields were added. Currently empty with no active consumers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (clustered PK, fillfactor=95) |

---

## 1. Business Meaning

Customer.CustomerLatinName_Ver2 is an orphaned legacy table representing an earlier iteration of the Latin name storage schema. It contains only four columns (CID, FirstName, LastName, ModifiedDate), which matches the original structure before Address, City, and MiddleName were added to Customer.CustomerLatinName.

The "_Ver2" suffix is counterintuitive - this is the older, simpler version, not a newer one. It appears to have been created as a "Version 2" experiment or migration stepping-stone that was ultimately superseded by the fuller Customer.CustomerLatinName schema. No stored procedures, views, or functions reference this table anywhere in the SSDT codebase. Currently 0 rows.

This table is likely retained for safety (in case the data needs to be referenced) and can be considered a candidate for deprecation/cleanup.

---

## 2. Business Logic

No active business logic found. Table is not referenced by any stored procedures or application code in the codebase scan.

---

## 3. Data Overview

*Customer.CustomerLatinName_Ver2 is currently empty (0 rows). No active consumers.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - primary key. Matches CID semantics in Customer.CustomerLatinName. |
| 2 | FirstName | varchar(100) | YES | - | CODE-BACKED | Latin-script first name. Same semantics as in Customer.CustomerLatinName. |
| 3 | LastName | varchar(100) | YES | - | CODE-BACKED | Latin-script last name. |
| 4 | ModifiedDate | datetime | NO | getdate() | CODE-BACKED | Timestamp of last modification. Default = getdate(). NOT NULL (unlike CustomerLatinNameFromNonLatin where ModifiedDate is nullable). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No consumers found in SSDT codebase. This table is orphaned/legacy.

---

## 6. Dependencies

No dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerLatinName_Ver2 | CLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerLatinName_Ver2 | PRIMARY KEY | CID must be unique |
| DF_CustomerLatinName_ModifiedDate_Ver2 | DEFAULT | ModifiedDate = getdate() |

---

## 8. Sample Queries

### 8.1 Confirm empty state

```sql
SELECT COUNT(*) AS RowCount
FROM Customer.CustomerLatinName_Ver2 WITH (NOLOCK)
-- Returns 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 6.5/10 (Elements: 7/10, Logic: 4/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerLatinName_Ver2 | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CustomerLatinName_Ver2.sql*
