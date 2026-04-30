# Customer.GetBlockedOperationsForCID

> Returns all currently blocked operations for a specific customer, joining the customer's blocked operation records with the operation type descriptions from the Dictionary.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to query) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBlockedOperationsForCID retrieves the list of operations that have been administratively blocked for a specific customer. It joins Customer.BlockedCustomerOperations (the per-customer block records) with Dictionary.OperationTypesForBlocking (the lookup of blockable operation types) to return both the machine code (OperationTypeID) and the human-readable description (OperationDescription).

The procedure exists for compliance and customer service use cases. When a compliance officer or support agent needs to know what operations a customer cannot perform, this procedure provides the answer. The BlockedCustomerOperations table records which operations have been restricted, when the restriction was applied (Occurred), and what type of operation is blocked. The Dictionary lookup adds the description so consumers don't need to maintain a separate type map.

Created 2015-04-30 (Geri Reshef, per Ilana's request). The TRY/CATCH with THROW ensures query errors propagate cleanly to the caller without silent failures.

---

## 2. Business Logic

### 2.1 Blocked Operation Lookup

**What**: Returns all blocked operation records for the customer with operation type descriptions.

**Columns/Parameters Involved**: `@CID`, `Customer.BlockedCustomerOperations.OperationTypeID`, `Customer.BlockedCustomerOperations.Occurred`, `Dictionary.OperationTypesForBlocking.OperationDescription`

**Rules**:
- SELECT from Customer.BlockedCustomerOperations WHERE CID = @CID
- JOIN Dictionary.OperationTypesForBlocking ON OperationTypeID for description
- NOLOCK on both tables: read-only, non-blocking
- Returns all rows - no date filtering, no status filtering (all active blocks returned)
- Empty result set if customer has no blocked operations (no special handling)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to query. Returns all blocked operations WHERE CID = @CID. Empty result if customer has no blocks. |

**Result set:**

| Column | Type | Description |
|--------|------|-------------|
| CID | INT | Customer's CID (echoed from the block record) |
| OperationTypeID | INT | Blocked operation type ID. FK to Dictionary.OperationTypesForBlocking. |
| Occurred | DATETIME | When the block was applied. |
| OperationDescription | VARCHAR | Human-readable description of the blocked operation type from Dictionary.OperationTypesForBlocking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.BlockedCustomerOperations | Read | All blocked operation records for this customer |
| OperationTypeID | Dictionary.OperationTypesForBlocking | Read (JOIN) | Resolves OperationTypeID to human-readable OperationDescription |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No callers found in SSDT repo. | - | Called by compliance/customer service applications. | |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBlockedOperationsForCID (procedure)
|- Customer.BlockedCustomerOperations (table)
+-- Dictionary.OperationTypesForBlocking (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | Per-customer blocked operation records; filtered by CID |
| Dictionary.OperationTypesForBlocking | Table | Lookup table: OperationTypeID -> OperationDescription |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called by compliance/customer service tools. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH THROW | Error handling | Errors propagate cleanly to caller without silent swallowing |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| No date filter | Design | All active blocks returned, regardless of age |

---

## 8. Sample Queries

### 8.1 Get blocked operations for a customer

```sql
EXEC Customer.GetBlockedOperationsForCID @CID = 12345678
```

### 8.2 Check available operation types that can be blocked

```sql
SELECT OperationTypeID, OperationDescription
FROM Dictionary.OperationTypesForBlocking WITH (NOLOCK)
ORDER BY OperationTypeID
```

### 8.3 Find all customers with a specific operation blocked

```sql
SELECT CID, Occurred
FROM Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE OperationTypeID = 1  -- replace with target operation type
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetBlockedOperationsForCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetBlockedOperationsForCID.sql*
