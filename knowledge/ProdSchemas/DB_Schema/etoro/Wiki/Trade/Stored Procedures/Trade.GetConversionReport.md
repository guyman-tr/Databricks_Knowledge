# Trade.GetConversionReport

> Retrieves the results of a settlement type conversion operation (IsSettled update) by operation GUID, showing which positions were successfully converted and any failures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns conversion operation results filtered by OperationGuid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the audit log for a batch settlement type conversion operation. When positions are converted from one settlement type to another (e.g., CFD to real stock or vice versa), the operation is tracked in History.IsSettledUpdateOperations with a unique GUID. This procedure lets operators review which positions were successfully updated and which failed, along with details and timestamps.

The "conversion" in the name refers to changing the IsSettled/SettlementTypeID value on positions - a significant business operation that affects how PnL is calculated, what fees apply, and whether the customer owns actual shares.

Data flow: An admin initiates a settlement conversion operation -> the system processes positions and logs results to History.IsSettledUpdateOperations -> this procedure retrieves the report by OperationGuid.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a report/audit reader. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationGuid | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Unique identifier for the batch conversion operation. Each settlement type update batch gets a GUID to group related position updates. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | - | - | CODE-BACKED | Position that was included in the conversion operation. |
| 2 | Sucseeded | BIT | - | - | CODE-BACKED | Whether the conversion succeeded for this position: 1=success, 0=failure. Note: column name contains a typo (Sucseeded vs Succeeded). |
| 3 | Occurred | DATETIME | - | - | CODE-BACKED | Timestamp when this position's conversion was attempted. |
| 4 | Details | VARCHAR | - | - | CODE-BACKED | Additional details about the conversion result - may contain error messages for failures or confirmation for successes. |
| 5 | Operator | VARCHAR | - | - | CODE-BACKED | Identity of the admin/operator who initiated the conversion operation. |
| 6 | OperationGuid | UNIQUEIDENTIFIER | - | - | CODE-BACKED | The batch operation GUID, echoed back for reference. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OperationGuid | History.IsSettledUpdateOperations | Read | Retrieves conversion audit records by operation GUID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Admin Tools | EXEC | Caller | Reviews conversion operation results |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetConversionReport (procedure)
└── History.IsSettledUpdateOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.IsSettledUpdateOperations | Table | Source of conversion audit records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Admin Tools | External | Conversion report retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON for performance

---

## 8. Sample Queries

### 8.1 Execute for a specific operation

```sql
EXEC Trade.GetConversionReport @OperationGuid = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Find recent conversion operations

```sql
SELECT DISTINCT OperationGuid, Operator, MIN(Occurred) AS StartTime, MAX(Occurred) AS EndTime,
       COUNT(*) AS TotalPositions,
       SUM(CAST(Sucseeded AS INT)) AS SuccessCount
FROM History.IsSettledUpdateOperations WITH (NOLOCK)
GROUP BY OperationGuid, Operator
ORDER BY MIN(Occurred) DESC;
```

### 8.3 Find failed conversions

```sql
SELECT PositionID, Details, Occurred, Operator
FROM History.IsSettledUpdateOperations WITH (NOLOCK)
WHERE Sucseeded = 0
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetConversionReport | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetConversionReport.sql*
