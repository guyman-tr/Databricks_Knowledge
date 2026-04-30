# Customer.GCIDs

> Table-Valued Parameter type for passing a batch of Global Customer IDs (GCIDs) to stored procedures that operate on sets of global identifiers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type |
| **Key Identifier** | GCID (int, clustered PK within the type) |
| **Partition** | N/A |
| **Indexes** | Clustered PK on GCID (within TVP scope) |

---

## 1. Business Meaning

Customer.GCIDs is a Table-Valued Parameter (TVP) type for passing a set of Global Customer IDs (GCIDs) to stored procedures. GCID is the global unique customer identifier used across eToro's federated trading systems, distinct from the schema-local CID. While CID identifies a customer within a specific context (e.g., within the etoro database), GCID spans across linked accounts and global identity contexts — it is the canonical identifier used in cross-system operations like referral programs, global reporting, and multi-account management.

The type enables batch input for procedures that need to process multiple customers by their GCID in a single call, avoiding repeated per-customer invocations or string-based ID lists.

Currently consumed by Customer.RafGetByReferedGCIDs, which accepts a set of GCIDs representing referred customers in the Refer-a-Friend (RAF) program to look up their referral status and eligibility data in a single batch operation.

---

## 2. Business Logic

### 2.1 Bulk GCID Input Pattern

**What**: Enables procedures to receive a set of Global Customer IDs as a typed table parameter for batch processing.

**Columns/Parameters Involved**: `GCID`

**Rules**:
- Passed as READONLY to all consuming procedures
- Clustered PK on GCID enforces uniqueness within the passed set
- Used when the caller has a collection of GCIDs (rather than CIDs) — applicable to RAF, global account operations, and cross-system lookups
- Mirrors Customer.CustomerCIDsTableType in structure but for global IDs (GCID) rather than local IDs (CID)

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID - the cross-system unique customer identifier. Primary key within the TVP, enforcing uniqueness in the input set. Used in RAF program lookups, global account operations, and cross-system identity resolution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RafGetByReferedGCIDs | @ReferredGCIDs | TVP Parameter | Accepts a batch of GCIDs of referred customers to look up their RAF status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RafGetByReferedGCIDs | Stored Procedure | READONLY TVP parameter - input set of GCIDs for batch RAF referral lookup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED | GCID ASC | - | - | Active (within TVP scope) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | Clustered | GCID must be unique within the TVP - prevents duplicate GCIDs in the input set |

---

## 8. Sample Queries

### 8.1 Declare and use the TVP for RAF lookups

```sql
DECLARE @ReferredGCIDs Customer.GCIDs
INSERT INTO @ReferredGCIDs (GCID) VALUES (500001), (500002), (500003)

EXEC Customer.RafGetByReferedGCIDs @ReferredGCIDs = @ReferredGCIDs
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
  AND t.name = 'GCIDs'
```

### 8.3 Compare CID-based vs GCID-based TVP types

```sql
-- CID-based type (local identifier)
SELECT 'CustomerCIDsTableType' AS TypeName, c.name AS ColumnName
FROM sys.table_types t WITH (NOLOCK)
INNER JOIN sys.columns c WITH (NOLOCK) ON c.object_id = t.type_table_object_id
WHERE t.schema_id = SCHEMA_ID('Customer') AND t.name = 'CustomerCIDsTableType'

UNION ALL

-- GCID-based type (global identifier)
SELECT 'GCIDs', c.name
FROM sys.table_types t WITH (NOLOCK)
INNER JOIN sys.columns c WITH (NOLOCK) ON c.object_id = t.type_table_object_id
WHERE t.schema_id = SCHEMA_ID('Customer') AND t.name = 'GCIDs'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GCIDs | Type: User Defined Type | Source: etoro/etoro/Customer/User Defined Types/Customer.GCIDs.sql*
