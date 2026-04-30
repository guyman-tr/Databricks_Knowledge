# Customer.CustomerLatinNameType

> Table-Valued Parameter type for passing a batch of customer Latin-character name and address records to bulk-upsert stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID (int, clustered PK within the type) |
| **Partition** | N/A |
| **Indexes** | Clustered PK on CID (within TVP scope) |

---

## 1. Business Meaning

Customer.CustomerLatinNameType is a Table-Valued Parameter (TVP) type for bulk-passing customer personal data — first name, last name, middle name, address, and city — stored in Latin-script transliterations. All varchar columns use the `Latin1_General_BIN` binary collation, which enables precise binary-level sorting and comparison for Latin-character strings. This is important when matching transliterated names submitted from external verification providers or document scanners that require exact byte-level matching.

Without this TVP, bulk updates to the Customer.CustomerLatinName table would require individual per-customer calls or delimited string manipulation. The type enables Customer.SetCustomerLatinName to accept a batch of name records in a single MERGE operation.

The latin name concept in eToro exists because many customers register with non-Latin names (Arabic, Chinese, Hebrew, Cyrillic) and the platform maintains a separate transliterated "Latin name" record for identity verification, KYC submissions, and financial instrument integration — contexts where only ASCII-compatible scripts are accepted.

---

## 2. Business Logic

### 2.1 Latin Transliteration Batch Input

**What**: Enables bulk setting of Latin-script name transliterations for multiple customers in a single stored procedure call.

**Columns/Parameters Involved**: `CID`, `FirstName`, `LastName`, `MiddleName`, `Address`, `City`

**Rules**:
- Passed as READONLY to Customer.SetCustomerLatinName which performs a MERGE (upsert) against Customer.CustomerLatinName
- All string columns use Latin1_General_BIN collation — binary collation for deterministic byte-level comparison
- NULL is allowed for FirstName, LastName, MiddleName, Address, City — allows partial record updates; the MERGE target table decides how to handle NULLs
- CID is the primary key, ensuring one record per customer in the batch

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - primary key within the TVP. Identifies which customer's Latin name records are being set. Maps to CID in Customer.CustomerLatinName. |
| 2 | FirstName | varchar(100) | YES | - | CODE-BACKED | Customer's first name in Latin-script transliteration. Latin1_General_BIN collation for binary comparison. NULL indicates not provided in this batch. |
| 3 | LastName | varchar(100) | YES | - | CODE-BACKED | Customer's last name (surname) in Latin-script transliteration. Latin1_General_BIN collation. NULL indicates not provided in this batch. |
| 4 | MiddleName | varchar(100) | YES | - | CODE-BACKED | Customer's middle name in Latin-script transliteration. Latin1_General_BIN collation. NULL indicates no middle name or not provided. |
| 5 | Address | varchar(200) | YES | - | CODE-BACKED | Customer's residential address in Latin-script transliteration. Latin1_General_BIN collation. NULL indicates not provided. |
| 6 | City | varchar(100) | YES | - | CODE-BACKED | Customer's city of residence in Latin-script transliteration. Latin1_General_BIN collation. NULL indicates not provided. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetCustomerLatinName | @CustomerLatinNameType | TVP Parameter | Accepts a batch of CID + Latin name records to bulk-upsert into Customer.CustomerLatinName |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetCustomerLatinName | Stored Procedure | READONLY TVP parameter - input set of CID + name records for MERGE upsert |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED | CID ASC | - | - | Active (within TVP scope) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | Clustered | CID must be unique within the TVP - one Latin name record per customer per batch |

---

## 8. Sample Queries

### 8.1 Declare and use the TVP to set Latin names for a batch of customers

```sql
DECLARE @LatinNames Customer.CustomerLatinNameType
INSERT INTO @LatinNames (CID, FirstName, LastName, MiddleName, Address, City)
VALUES
    (1001, 'John', 'Smith', NULL, '123 Main St', 'New York'),
    (1002, 'Jane', 'Doe', 'Marie', '456 Oak Ave', 'London')

EXEC Customer.SetCustomerLatinName @CustomerLatinNameType = @LatinNames
```

### 8.2 Inspect the type definition and collation settings

```sql
SELECT
    t.name AS TypeName,
    c.name AS ColumnName,
    tp.name AS DataType,
    c.max_length,
    col.name AS CollationName,
    c.is_nullable
FROM sys.table_types t WITH (NOLOCK)
INNER JOIN sys.columns c WITH (NOLOCK) ON c.object_id = t.type_table_object_id
INNER JOIN sys.types tp WITH (NOLOCK) ON tp.user_type_id = c.user_type_id
LEFT JOIN sys.columns col WITH (NOLOCK) ON col.object_id = c.object_id AND col.column_id = c.column_id
WHERE t.schema_id = SCHEMA_ID('Customer')
  AND t.name = 'CustomerLatinNameType'
```

### 8.3 Check which customers have Latin names set

```sql
SELECT
    cln.CID,
    cln.FirstName,
    cln.LastName,
    cln.MiddleName,
    cln.City
FROM Customer.CustomerLatinName cln WITH (NOLOCK)
WHERE cln.CID IN (1001, 1002)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerLatinNameType | Type: User Defined Type | Source: etoro/etoro/Customer/User Defined Types/Customer.CustomerLatinNameType.sql*
