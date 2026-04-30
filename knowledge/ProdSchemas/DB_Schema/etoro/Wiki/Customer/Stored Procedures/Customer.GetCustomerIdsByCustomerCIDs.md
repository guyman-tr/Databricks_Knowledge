# Customer.GetCustomerIdsByCustomerCIDs

> Batch-resolves CIDs to their system GUIDs (ID field) using a table-valued parameter; used by the User Sync API and business rule services to map integer CIDs to REST API identity GUIDs.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CustomerCIDs (TVP - batch of CIDs to resolve) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerIdsByCustomerCIDs converts a batch of integer CIDs to their corresponding system GUIDs (the `ID` uniqueidentifier column on CustomerStatic). The `ID` column is the primary identity field exposed by eToro's REST APIs and service layer, while CID is the internal integer key used throughout the database.

The procedure exists to bridge the two identity systems. Services that operate on CIDs internally but need to call APIs or services that identify customers by GUID use this procedure to do the conversion in a single efficient batch query, instead of looping or building dynamic IN lists.

It accepts a table-valued parameter of type Customer.CustomerCIDsTableType (a UDT with a single CID column), enabling callers to pass hundreds of CIDs in one round-trip. Used by SQL_UserSyncAPI (the user synchronization API service) and BusinessRuleUserForEtoro.

---

## 2. Business Logic

### 2.1 Batch CID-to-GUID Resolution

**What**: Efficient set-based conversion from integer CID to uniqueidentifier GUID.

**Columns/Parameters Involved**: `@CustomerCIDs`, `CID`, `ID`

**Rules**:
- INNER JOIN between CustomerStatic and the TVP: only CIDs present in both are returned
- CIDs in the input TVP that don't exist in CustomerStatic are silently excluded
- Output is NOT ordered; caller should order if needed
- The ID (uniqueidentifier) uses newsequentialid() as default in CustomerStatic for insert performance

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CustomerCIDs | Customer.CustomerCIDsTableType | NO | - | CODE-BACKED | Table-valued parameter (READONLY) containing the batch of CIDs to resolve. Type definition: single column `CID INT`. Pass with INSERT INTO TVP syntax or EXEC with table variable. CIDs not found in CustomerStatic are silently excluded from results. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| CID | Customer.CustomerStatic.CID | Internal integer customer identifier (database key). |
| ID | Customer.CustomerStatic.ID | System GUID (uniqueidentifier) - primary identity exposed by REST APIs and service layer. newsequentialid() default for insert-order performance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CustomerCIDs | Customer.CustomerCIDsTableType | TVP type definition | Input parameter type; batch of CIDs |
| cs.CID | Customer.CustomerStatic | Read (INNER JOIN) | Source of CID and ID columns |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_UserSyncAPI (SQL login) | EXECUTE | Permission | User sync API service resolves CID-to-GUID for REST identity |
| BusinessRuleUserForEtoro (SQL login) | EXECUTE | Permission | Business rules service maps CIDs to GUIDs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerIdsByCustomerCIDs (procedure)
├── Customer.CustomerCIDsTableType (user defined type)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerCIDsTableType | User Defined Type | TVP parameter type definition |
| Customer.CustomerStatic | Table | Source of CID + ID columns via INNER JOIN |

### 6.2 Objects That Depend On This

No stored procedure dependents found (called directly by external service accounts).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READONLY TVP | Parameter | @CustomerCIDs cannot be modified within the procedure |
| INNER JOIN | Implicit filter | CIDs missing from CustomerStatic are silently excluded |
| SET NOCOUNT ON | Performance | Suppresses row-count messages for caller efficiency |

---

## 8. Sample Queries

### 8.1 Resolve a batch of CIDs to GUIDs

```sql
DECLARE @CIDs Customer.CustomerCIDsTableType
INSERT INTO @CIDs (CID) VALUES (12345678), (23456789), (34567890)
EXEC Customer.GetCustomerIdsByCustomerCIDs @CustomerCIDs = @CIDs
```

### 8.2 Reproduce the procedure logic directly

```sql
SELECT cs.CID, cs.ID
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.CID IN (12345678, 23456789, 34567890)
```

### 8.3 Look up the CustomerCIDsTableType definition

```sql
SELECT name, system_type_id, max_length
FROM sys.columns WITH (NOLOCK)
WHERE object_id = TYPE_ID('Customer.CustomerCIDsTableType')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9/10, Logic: 6/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerIdsByCustomerCIDs | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomerIdsByCustomerCIDs.sql*
