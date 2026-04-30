# Customer.CustomerLatinNameTemp

> Staging twin of Customer.CustomerLatinName - identical DDL structure used as a transient work table during bulk Latin name load operations. Not deployed in the current database environment.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (clustered PK, fillfactor=95) |

---

## 1. Business Meaning

Customer.CustomerLatinNameTemp is the staging counterpart to Customer.CustomerLatinName. It has an identical column structure (CID, FirstName, LastName, MiddleName, Address, City, ModifiedDate) and is used as a transient load buffer during bulk Latin name operations - data is loaded here first, validated, then promoted to the live Customer.CustomerLatinName table.

**This table is defined in SSDT but NOT deployed in the current database environment.** Any query against it will fail with "Invalid object name." This matches the pattern seen in Customer.CreditExtended_TEMP - these _TEMP tables exist as deployment-ready staging structures but are only instantiated when a bulk operation requires them.

No stored procedure consumers are found in the SSDT codebase for this table, suggesting it is populated by application-layer code or direct SQL scripts during data migration/load events.

---

## 2. Business Logic

### 2.1 Staging Pattern

**What**: Load-validate-promote pattern using a staging table with identical structure to the live table.

**Rules**:
- Structure is identical to Customer.CustomerLatinName except:
  - PK constraint name: `PK_CustomerLatinNameTemp` (vs `PK_CustomerLatinName`)
  - DEFAULT constraint name: `DF_CustomerLatinNameTemp_ModifiedDate` (vs `DF_CustomerLatinName_ModifiedDate`)
  - Both use DEFAULT (getdate()) for ModifiedDate
- Typical usage pattern: TRUNCATE CustomerLatinNameTemp -> bulk INSERT -> validate -> MERGE into CustomerLatinName

---

## 3. Data Overview

*Not deployed in current database environment. Table exists in SSDT DDL only.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - primary key. Matches CID in Customer.CustomerLatinName. |
| 2 | FirstName | varchar(100) | YES | - | CODE-BACKED | Latin-script first name staging value. |
| 3 | LastName | varchar(100) | YES | - | CODE-BACKED | Latin-script last name staging value. |
| 4 | ModifiedDate | datetime | NO | getdate() | CODE-BACKED | Timestamp of staging row creation. Default = getdate(). |
| 5 | Address | varchar(200) | YES | - | CODE-BACKED | Latin-script address staging value. |
| 6 | City | varchar(100) | YES | - | CODE-BACKED | Latin-script city staging value. |
| 7 | MiddleName | varchar(100) | YES | - | CODE-BACKED | Latin-script middle name staging value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No stored procedure consumers identified. Application-layer or script usage only.

---

## 6. Dependencies

No dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerLatinNameTemp | CLUSTERED | CID ASC | - | - | Active (when deployed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerLatinNameTemp | PRIMARY KEY | CID must be unique |
| DF_CustomerLatinNameTemp_ModifiedDate | DEFAULT | ModifiedDate = getdate() |

---

## 8. Sample Queries

### 8.1 Verify deployment status

```sql
SELECT OBJECT_ID('Customer.CustomerLatinNameTemp') AS ObjectID
-- NULL = not deployed; non-NULL = deployed
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerLatinNameTemp | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CustomerLatinNameTemp.sql*
