# Trade.BlockedCustomerOperationTypeIDs

> A table-valued parameter type for passing sets of blocked operation type IDs when querying customer restriction data. Enables the eToro platform to block specific operations (open, close, edit) per customer for compliance or risk.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | BlockedCustomerOperationTypeID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.BlockedCustomerOperationTypeIDs is a table-valued parameter type for passing which operation types to consider as "blocked" when querying customer restriction data. Operation types include open position, close position, edit order, and similar trading actions. The platform can block specific operation types per customer for compliance, risk, or regulatory reasons.

This type enables batch restriction queries filtered by operation type. Callers pass the set of operation type IDs they care about - e.g., only open and close - and the procedures return customers with those types blocked. Used by GetCustomersRestrictionsByTypesForAPI, GetCustomersDataWithCopyRestirctions, and GetCustomersDataWithRestirctions.

Data flow: API clients or internal tools specify which operation types to filter (e.g., 1=Open, 2=Close, 3=Edit), populate the TVP, and call the restriction procedures along with a CID list. The procedure returns customer data annotated with which of the specified operation types are blocked for each customer.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type for operation type filtering in restriction queries.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BlockedCustomerOperationTypeID | int | NO | - | CODE-BACKED | Operation type ID from the platform's operation type dictionary. Identifies which trading actions (e.g., open, close, edit) to include when querying customer restrictions. Each ID corresponds to one operation type that may be blocked per customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BlockedCustomerOperationTypeID | Dictionary.OperationType (or similar) | Lookup | Operation type classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCustomersRestrictionsByTypesForAPI | @BlockedTypes (or similar) | Parameter (TVP) | Filters restriction data by operation types for API |
| Trade.GetCustomersDataWithCopyRestirctions | @BlockedTypes (or similar) | Parameter (TVP) | Filters customer data with copy restrictions |
| Trade.GetCustomersDataWithRestirctions | @BlockedTypes (or similar) | Parameter (TVP) | Filters customer data with restrictions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCustomersRestrictionsByTypesForAPI | Stored Procedure | READONLY parameter for API restriction queries |
| Trade.GetCustomersDataWithCopyRestirctions | Stored Procedure | READONLY parameter for copy restriction data |
| Trade.GetCustomersDataWithRestirctions | Stored Procedure | READONLY parameter for restriction data |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query restrictions for open and close operations only

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @BlockedTypes Trade.BlockedCustomerOperationTypeIDs;
INSERT INTO @CIDs (CID) VALUES (12345), (67890);
INSERT INTO @BlockedTypes (BlockedCustomerOperationTypeID) VALUES (1), (2);  -- 1=Open, 2=Close

EXEC Trade.GetCustomersRestrictionsByTypesForAPI @CIDs = @CIDs, @BlockedTypes = @BlockedTypes;
```

### 8.2 Get customer data with copy restrictions for all operation types

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @BlockedTypes Trade.BlockedCustomerOperationTypeIDs;
INSERT INTO @CIDs (CID) SELECT CID FROM Customer.CustomerTbl WITH (NOLOCK) WHERE RegionID = 1;
INSERT INTO @BlockedTypes (BlockedCustomerOperationTypeID)
SELECT OperationTypeID FROM Dictionary.OperationTypeTbl WITH (NOLOCK);

EXEC Trade.GetCustomersDataWithCopyRestirctions @CIDs = @CIDs, @BlockedTypes = @BlockedTypes;
```

### 8.3 Single operation type for edit-only restriction check

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @BlockedTypes Trade.BlockedCustomerOperationTypeIDs;
INSERT INTO @CIDs (CID) VALUES (55555);
INSERT INTO @BlockedTypes (BlockedCustomerOperationTypeID) VALUES (3);  -- Edit

EXEC Trade.GetCustomersDataWithRestirctions @CIDs = @CIDs, @BlockedTypes = @BlockedTypes;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BlockedCustomerOperationTypeIDs | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.BlockedCustomerOperationTypeIDs.sql*
