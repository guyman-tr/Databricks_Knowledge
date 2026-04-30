# Trade.GetAdminPositionLogByRequestID

> Retrieves admin position log entries by request GUID and customer ID, linking all operations in a single admin batch request.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns admin position log columns filtered by AdminPositionRequestID + CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all admin position log records associated with a specific admin request (identified by a GUID) for a specific customer. Admin requests can create multiple position operations in a single batch (e.g., opening positions across multiple instruments for compensation), and this procedure retrieves all operations from that batch.

The procedure exists to support request-level tracking and auditing. When an admin submits a batch request and needs to verify all operations completed successfully, this procedure shows every position operation within that request for the specified customer.

Data flows from Trade.AdminPositionLog filtered by both AdminPositionRequestID (the batch GUID) and CID (customer filter), with NOLOCK for non-blocking reads.

---

## 2. Business Logic

### 2.1 Dual-Key Lookup

**What**: Uses both request GUID and CID for filtered retrieval.

**Columns/Parameters Involved**: `@RequestID`, `@CID`

**Rules**:
- AdminPositionRequestID groups all operations in a single admin batch request
- CID filter ensures results are scoped to a specific customer (a batch request could theoretically span customers, though this is uncommon)
- Both filters must match for a row to be returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to filter admin operations by. |
| 2 | @RequestID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Admin request GUID that groups all position operations from a single admin batch. |

**Output columns:** Same 27 columns as Trade.GetAdminPositionLogByAdminPositionID. See [Trade.GetAdminPositionLogByAdminPositionID](Trade.GetAdminPositionLogByAdminPositionID.md) Section 4 for full column descriptions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.AdminPositionLog | Direct Read | Reads admin position log entries by request GUID and CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAdminPositionLogByRequestID (procedure)
└── Trade.AdminPositionLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | SELECT with NOLOCK - filtered by AdminPositionRequestID + CID |

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

### 8.1 Look up admin operations by request

```sql
EXEC Trade.GetAdminPositionLogByRequestID
    @CID = 12345678,
    @RequestID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Find all request GUIDs for a customer's admin operations

```sql
SELECT DISTINCT
        AdminPositionRequestID,
        MIN(RequestOccurred) AS FirstOperation,
        COUNT(*) AS OperationCount
FROM    Trade.AdminPositionLog WITH (NOLOCK)
WHERE   CID = 12345678
GROUP BY AdminPositionRequestID
ORDER BY FirstOperation DESC;
```

### 8.3 Check failed operations in a request batch

```sql
SELECT  AdminPositionID,
        InstrumentID,
        State,
        FailReason,
        ErrorCode
FROM    Trade.AdminPositionLog WITH (NOLOCK)
WHERE   AdminPositionRequestID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
    AND CID = 12345678
    AND FailReason IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAdminPositionLogByRequestID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAdminPositionLogByRequestID.sql*
