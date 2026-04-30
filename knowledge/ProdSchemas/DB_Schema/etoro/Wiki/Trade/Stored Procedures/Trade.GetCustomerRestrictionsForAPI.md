# Trade.GetCustomerRestrictionsForAPI

> Retrieves all active operation restrictions (blocks) for a specific customer, showing which operations are blocked, when they were blocked, and the reason code.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns blocked operations for a CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer has trading restrictions (e.g., blocked from opening positions, blocked from withdrawals), those restrictions are stored in Customer.BlockedCustomerOperations. This procedure retrieves all active restrictions for a given customer, used by the API layer to determine what operations the customer is allowed to perform.

This procedure is also called internally by Trade.GetCustomerDataAndRestrictions as part of a composite customer data retrieval.

Data flow: API service or parent procedure provides a CID -> this procedure queries Customer.BlockedCustomerOperations -> returns all active restrictions with operation type, timestamp, and reason.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple customer restriction reader.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve restrictions for. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID (echoed back for reference). |
| 2 | OperationTypeID | INT | NO | - | CODE-BACKED | Type of operation that is blocked for this customer. References a dictionary of operation types (e.g., open position, close position, deposit, withdrawal). |
| 3 | Occurred | DATETIME | - | - | CODE-BACKED | Timestamp when the restriction was applied. |
| 4 | BlockReasonID | INT | - | - | CODE-BACKED | Reason code for the block. References Dictionary.BlockUnBlockReason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.BlockedCustomerOperations | Read | Retrieves all blocked operations for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCustomerDataAndRestrictions | EXEC | Caller | Called as part of composite customer data retrieval |
| API Services | EXEC | Caller | Direct restriction lookup for authorization checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomerRestrictionsForAPI (procedure)
└── Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | Source of customer operation restrictions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCustomerDataAndRestrictions | Procedure | Calls this to include restrictions in composite result |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON for performance

---

## 8. Sample Queries

### 8.1 Execute for a specific customer

```sql
EXEC Trade.GetCustomerRestrictionsForAPI @CID = 12345;
```

### 8.2 Query restrictions with reason names

```sql
SELECT bco.CID, bco.OperationTypeID, bco.Occurred, bco.BlockReasonID, br.Reason
FROM Customer.BlockedCustomerOperations bco WITH (NOLOCK)
LEFT JOIN Dictionary.BlockUnBlockReason br WITH (NOLOCK) ON br.ID = bco.BlockReasonID
WHERE bco.CID = 12345;
```

### 8.3 Find most restricted customers

```sql
SELECT CID, COUNT(*) AS RestrictionCount
FROM Customer.BlockedCustomerOperations WITH (NOLOCK)
GROUP BY CID
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomerRestrictionsForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomerRestrictionsForAPI.sql*
