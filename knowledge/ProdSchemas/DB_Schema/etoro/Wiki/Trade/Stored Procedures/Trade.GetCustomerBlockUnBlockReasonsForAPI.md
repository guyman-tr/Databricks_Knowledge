# Trade.GetCustomerBlockUnBlockReasonsForAPI

> Returns all block/unblock reason codes from the Dictionary.BlockUnBlockReason lookup table, providing the reference data for customer blocking operations via the API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Dictionary.BlockUnBlockReason |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer's trading operations are blocked or unblocked (e.g., due to compliance issues, AML flags, or identity verification failures), a reason must be recorded. This procedure provides the complete list of valid block/unblock reasons that the API and admin interface use to populate selection lists.

Data flow: API/Admin service calls this procedure -> receives all block/unblock reasons -> presents them in the UI for operator selection when blocking or unblocking a customer.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple lookup table reader.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | - | CODE-BACKED | Unique identifier for the block/unblock reason. PK of Dictionary.BlockUnBlockReason. |
| 2 | Reason | VARCHAR | NO | - | CODE-BACKED | Human-readable description of the block/unblock reason (e.g., "AML Review", "Identity Verification Failed", "Compliance Hold"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Dictionary.BlockUnBlockReason | Read | Reads all block/unblock reason records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| API/Admin Services | EXEC | Caller | Reason list for block/unblock operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomerBlockUnBlockReasonsForAPI (procedure)
└── Dictionary.BlockUnBlockReason (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.BlockUnBlockReason | Table | Source of all block/unblock reasons |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| API/Admin Services | External | Reason selection for customer blocking |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Trade.GetCustomerBlockUnBlockReasonsForAPI;
```

### 8.2 Query reasons directly

```sql
SELECT ID, Reason FROM Dictionary.BlockUnBlockReason WITH (NOLOCK) ORDER BY ID;
```

### 8.3 Find which reasons are most commonly used

```sql
SELECT br.ID, br.Reason, COUNT(*) AS UsageCount
FROM Dictionary.BlockUnBlockReason br WITH (NOLOCK)
INNER JOIN Customer.BlockedCustomerOperations bco WITH (NOLOCK) ON bco.BlockReasonID = br.ID
GROUP BY br.ID, br.Reason
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomerBlockUnBlockReasonsForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomerBlockUnBlockReasonsForAPI.sql*
