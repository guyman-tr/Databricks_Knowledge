# Customer.CustomerCIDsTableType

> Table-Valued Parameter type for passing a batch of customer CIDs (Customer IDs) to stored procedures in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID (int, clustered PK within the type) |
| **Partition** | N/A |
| **Indexes** | Clustered PK on CID (within TVP scope) |

---

## 1. Business Meaning

Customer.CustomerCIDsTableType is a Table-Valued Parameter (TVP) type that enables stored procedures to accept a set of Customer IDs (CIDs) as a single strongly-typed table parameter rather than a delimited string or a series of individual calls. It defines a single-column table structure — `CID INT` with a clustered primary key — matching the integer customer identifier used throughout the Customer schema.

Without this type, bulk customer lookups would require string splitting, temporary tables, or repeated single-row calls. The TVP pattern reduces round-trips and enables SQL Server to optimize batch operations against the full CID set at once.

Used as the parameter type for Customer.GetCustomerIdsByCustomerCIDs, which maps a set of customer-specific CIDs to global CIDs (GCIDs). The caller populates the TVP with a list of CIDs and passes it as READONLY to the procedure.

---

## 2. Business Logic

### 2.1 Bulk CID Input Pattern

**What**: Enables procedures to receive a set of customer IDs in a single typed parameter, avoiding string-splitting or repeated single-row calls.

**Columns/Parameters Involved**: `CID`

**Rules**:
- Passed as READONLY to all consuming procedures — data cannot be modified inside the procedure
- Clustered PK on CID enforces uniqueness within the passed set and enables efficient lookups
- Used by callers that have a batch of CIDs (e.g., from an application-side collection) that need to be resolved in bulk

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - matches the CID primary key used in Customer.CustomerStatic and throughout the Customer schema. Passed as a set; clustered PK enforces uniqueness within the TVP. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.GetCustomerIdsByCustomerCIDs | @CustomerCIDs | TVP Parameter | Accepts a batch of CIDs to bulk-resolve customer identifiers |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetCustomerIdsByCustomerCIDs | Stored Procedure | READONLY TVP parameter - input set of CIDs for bulk lookup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED | CID ASC | - | - | Active (within TVP scope) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | Clustered | CID must be unique within the TVP - prevents duplicate CIDs in the input set |

---

## 8. Sample Queries

### 8.1 Declare and use the TVP in a procedure call

```sql
DECLARE @CIDs Customer.CustomerCIDsTableType
INSERT INTO @CIDs (CID) VALUES (1001), (1002), (1003)

EXEC Customer.GetCustomerIdsByCustomerCIDs @CustomerCIDs = @CIDs
```

### 8.2 Inspect the type definition

```sql
SELECT
    t.name AS TypeName,
    c.name AS ColumnName,
    tp.name AS DataType,
    c.is_nullable
FROM sys.table_types t WITH (NOLOCK)
INNER JOIN sys.columns c WITH (NOLOCK) ON c.object_id = t.type_table_object_id
INNER JOIN sys.types tp WITH (NOLOCK) ON tp.user_type_id = c.user_type_id
WHERE t.schema_id = SCHEMA_ID('Customer')
  AND t.name = 'CustomerCIDsTableType'
```

### 8.3 List all procedures that use this TVP

```sql
SELECT DISTINCT
    SCHEMA_NAME(p.schema_id) AS SchemaName,
    p.name AS ProcedureName
FROM sys.procedures p WITH (NOLOCK)
INNER JOIN sys.parameters par WITH (NOLOCK) ON par.object_id = p.object_id
INNER JOIN sys.table_types tt WITH (NOLOCK) ON tt.user_type_id = par.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Customer')
  AND tt.name = 'CustomerCIDsTableType'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerCIDsTableType | Type: User Defined Type | Source: etoro/etoro/Customer/User Defined Types/Customer.CustomerCIDsTableType.sql*
