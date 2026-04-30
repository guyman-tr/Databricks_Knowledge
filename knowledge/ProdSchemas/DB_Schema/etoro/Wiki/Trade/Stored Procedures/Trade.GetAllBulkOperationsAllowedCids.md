# Trade.GetAllBulkOperationsAllowedCids

> Returns all customers authorized for bulk trading operations, grouped by permission group.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Full dump of Trade.BulkOperationsAllowedCids |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete list of customers (CIDs) that are authorized to perform bulk trading operations, along with their permission group assignment. Bulk operations allow certain authorized users to execute trades on behalf of multiple customers in a single batch.

The whitelist is maintained in `Trade.BulkOperationsAllowedCids`. Each entry maps a CID to a GroupID, which likely represents a permission tier or organizational grouping for bulk operation access control.

This is a simple full-table read with no parameters, typically used to cache or load the entire authorization list at application startup or refresh.

---

## 2. Business Logic

### 2.1 Full Table Read

**What**: Returns all rows from the bulk operations whitelist.

**Columns/Parameters Involved**: `Trade.BulkOperationsAllowedCids.CID`, `Trade.BulkOperationsAllowedCids.GroupID`

**Rules**:
- No filtering - returns all authorized CIDs
- Uses NOLOCK hint for non-blocking reads
- No ordering specified

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Output Columns

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CID | INT | CODE-BACKED | Customer ID authorized for bulk operations. |
| 2 | GroupID | INT | CODE-BACKED | Permission group the customer belongs to for bulk operations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.BulkOperationsAllowedCids | Direct Read | Authorization whitelist |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllBulkOperationsAllowedCids (procedure)
└── Trade.BulkOperationsAllowedCids (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BulkOperationsAllowedCids | Table | Full table read |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all authorized CIDs

```sql
EXEC Trade.GetAllBulkOperationsAllowedCids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllBulkOperationsAllowedCids | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllBulkOperationsAllowedCids.sql*
