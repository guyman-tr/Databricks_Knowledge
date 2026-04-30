# Trade.GetCustomersRestrictionsByTypesForAPI

> Returns active customer operation blocks (copy block, trade block, etc.) for a list of customers, optionally filtered by specific operation types.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDs (TVP) + @OperationTypeIDs (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCustomersRestrictionsByTypesForAPI queries the Customer.BlockedCustomerOperations table to retrieve active operation blocks for a set of customers. Each block represents a restriction preventing the customer from performing a specific operation type (e.g., copy trading, opening positions, withdrawing funds). The caller can optionally filter to specific operation types or retrieve all blocks.

This procedure is a core building block for API responses that need to communicate customer restrictions. It is called by Trade.GetCustomersDataWithCopyRestirctions and Trade.GetCustomersDataWithRestirctions (with OperationTypeID=2 for copy blocks), and potentially by other API-facing procedures.

Data flows from Customer.BlockedCustomerOperations, joined to the @CIDs TVP to filter by customer and optionally joined to @OperationTypeIDs to filter by block type. If @OperationTypeIDs is empty, all block types are returned for the specified customers.

---

## 2. Business Logic

### 2.1 Optional Operation Type Filtering

**What**: Returns all blocks or only specific block types depending on whether @OperationTypeIDs has rows.

**Columns/Parameters Involved**: `@OperationTypeIDs`, `OperationTypeID`

**Rules**:
- IF EXISTS (SELECT 1 FROM @OperationTypeIDs): filter blocks to only the requested types
- ELSE: return all block types for the requested customers
- Common values: OperationTypeID=2 is "copy block" (used by GetCustomersDataWithCopyRestirctions)
- This branching avoids an unnecessary JOIN when no filter is needed

**Diagram**:
```
@CIDs (customer list)
  |
  +-- @OperationTypeIDs has rows?
  |     YES --> JOIN BlockedCustomerOperations + @OperationTypeIDs
  |     NO  --> JOIN BlockedCustomerOperations (all types)
  |
  Output: CID, OperationTypeID, Occurred, BlockReasonID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | Trade.CidList (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing Customer IDs to check for blocks. |
| 2 | @OperationTypeIDs | Trade.BlockedCustomerOperationTypeIDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter with operation types to filter. If empty, all types returned. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID with an active block. |
| 2 | OperationTypeID | int | NO | - | CODE-BACKED | Type of operation blocked. FK to Dictionary.BlockedCustomerOperationType (e.g., 2=copy block). |
| 3 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the block was applied. |
| 4 | BlockReasonID | int | YES | - | CODE-BACKED | Reason for the block. FK to a block reason lookup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.BlockedCustomerOperations | JOIN | Active operation blocks per customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCustomersDataWithCopyRestirctions | EXEC | EXEC | Called with OperationTypeID=2 for copy blocks |
| Trade.GetCustomersDataWithRestirctions | EXEC | EXEC | Called with OperationTypeID=2 for copy blocks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomersRestrictionsByTypesForAPI (procedure)
+-- Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | JOIN - source of customer operation blocks |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCustomersDataWithCopyRestirctions | Stored Procedure | EXEC caller with OperationTypeID=2 |
| Trade.GetCustomersDataWithRestirctions | Stored Procedure | EXEC caller with OperationTypeID=2 |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all restrictions for a customer

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @OpTypes Trade.BlockedCustomerOperationTypeIDs;
INSERT INTO @CIDs (CID) VALUES (12345);
EXEC Trade.GetCustomersRestrictionsByTypesForAPI @CIDs, @OpTypes;
```

### 8.2 Get only copy-trade blocks

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @OpTypes Trade.BlockedCustomerOperationTypeIDs;
INSERT INTO @CIDs (CID) VALUES (12345), (67890);
INSERT INTO @OpTypes (BlockedCustomerOperationTypeID) VALUES (2);
EXEC Trade.GetCustomersRestrictionsByTypesForAPI @CIDs, @OpTypes;
```

### 8.3 Direct query equivalent

```sql
SELECT  B.CID, B.OperationTypeID, B.Occurred, B.BlockReasonID
FROM    Customer.BlockedCustomerOperations B WITH (NOLOCK)
WHERE   B.CID = 12345
        AND B.OperationTypeID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomersRestrictionsByTypesForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomersRestrictionsByTypesForAPI.sql*
