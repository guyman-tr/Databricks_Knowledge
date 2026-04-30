# History.IsSettledUpdateOperations

> Audit log of position settlement type conversion operations, recording each attempt to convert positions between CFD and real stock ownership (IsSettled flag changes), with success/failure status and error details.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PK: (OperationGuid, PositionID) - CLUSTERED, composite |
| **Partition** | No (stored on MAIN filegroup) |
| **Indexes** | 1 active (clustered PK, DATA_COMPRESSION PAGE, FILLFACTOR 95) |

---

## 1. Business Meaning

History.IsSettledUpdateOperations records every attempt to change a position's settlement status - converting it between CFD (IsSettled=0, contract-for-difference with no real stock ownership) and REAL (IsSettled=1, customer owns actual shares). This conversion happens as part of eToro's stock settlement process where positions originally opened as CFDs can be converted to real equity ownership. Each row records one position's conversion attempt within a batch operation, with a success/failure flag and error details.

This table serves as the operational audit trail for settlement migration runs. When a batch conversion job encounters failures (Sucseeded=0), this table provides the diagnostics: which positions failed, what error occurred, and which operator ran the job. The OperationGuid groups all positions processed in the same batch run, enabling investigation of a specific migration event.

The table is currently empty, indicating either the conversion process has not run recently in this environment or rows are periodically cleaned up. The stored procedure `Trade.UpdateIsSettled` is the sole writer - it performs the conversion then immediately INSERTs the outcome here.

---

## 2. Business Logic

### 2.1 CFD to Real Stock Conversion Audit

**What**: Settlement type conversion is a critical operation that changes how a position is legally held and how fees and dividends are processed.

**Columns/Parameters Involved**: `PositionID`, `Sucseeded`, `Details`, `Operator`, `OperationGuid`

**Rules**:
- Details column contains direction prefix: "CFD2REAL" (IsSettled 0->1) or "REAL2CFD" (IsSettled 1->0), followed by error message if failed
- Sucseeded (note: intentional typo in the original DDL) = 1 if the conversion succeeded, 0 if it failed for this position
- OperationGuid groups all positions in the same batch operation, enabling batch-level analysis
- The Operator field identifies who initiated the conversion (from @OperatorIdentifier parameter in Trade.UpdateIsSettled)
- Multiple positions with the same OperationGuid represent a bulk conversion batch run

**Diagram**:
```
Trade.UpdateIsSettled(@IsSettledToSet=1, @OperationGuid=X, @Operator='admin')
  |
  For each position in batch:
    BEGIN TRY
      UPDATE Trade positions: IsSettled=1, SettlementTypeID=1
    END CATCH -> capture ErrorMessage
    |
    INSERT History.IsSettledUpdateOperations:
      PositionID=<posID>, Sucseeded=<0/1>,
      Details='CFD2REAL' + ErrorMessage,
      Operator='admin', OperationGuid=X
```

---

## 3. Data Overview

No rows found in History.IsSettledUpdateOperations (table is empty in this environment).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | The position that was subject to the settlement type conversion. Part of composite PK with OperationGuid. References Trade position tables. |
| 2 | Sucseeded | bit | NO | - | CODE-BACKED | Whether the conversion operation succeeded for this position: 1 = success (IsSettled updated), 0 = failure (error occurred during conversion). Note: column name has a typo ("Sucseeded" instead of "Succeeded") - preserved as-is from DDL. |
| 3 | Occurred | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when this operation record was written. Defaults to current UTC time. Set in the INSERT from Trade.UpdateIsSettled using GETUTCDATE(). |
| 4 | Details | varchar(8000) | YES | - | CODE-BACKED | Operation detail string. Starts with "CFD2REAL" (converting to real stock) or "REAL2CFD" (reverting to CFD), followed by a space and the error message if the operation failed (Sucseeded=0). NULL or just the direction prefix when successful. |
| 5 | Operator | varchar(30) | YES | - | CODE-BACKED | Identifier of the operator or system that initiated the conversion batch. Maps to the @OperatorIdentifier parameter of Trade.UpdateIsSettled. Nullable for automated runs without an explicit operator identity. |
| 6 | OperationGuid | uniqueidentifier | NO | - | CODE-BACKED | GUID that groups all positions processed in the same batch conversion run. Combined with PositionID as composite PK. Used to query all results from a specific conversion job execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade position tables | Implicit | The position being converted. No explicit FK in DDL. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateIsSettled | IsSettledUpdateOperations | Writer | The sole writer - INSERTs one row per position after each conversion attempt |
| Trade.GetConversionReport | IsSettledUpdateOperations | Reader | Reads this table to generate reports on conversion operation outcomes |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateIsSettled | Stored Procedure | Writer - inserts audit records for each position conversion attempt |
| Trade.GetConversionReport | Stored Procedure | Reader - reads results to generate conversion operation reports |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_IsSettledUpdateOperations | CLUSTERED (PK) | OperationGuid ASC, PositionID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_IsSettledUpdateOperations | PRIMARY KEY | (OperationGuid, PositionID) - ensures one audit record per position per conversion run |

---

## 8. Sample Queries

### 8.1 Find all positions from a specific conversion batch
```sql
DECLARE @OperationGuid uniqueidentifier = 'your-guid-here'
SELECT
    PositionID,
    Sucseeded,
    Details,
    Operator,
    Occurred
FROM History.IsSettledUpdateOperations WITH (NOLOCK)
WHERE OperationGuid = @OperationGuid
ORDER BY PositionID
```

### 8.2 Find failed conversions in recent batches
```sql
SELECT
    OperationGuid,
    PositionID,
    Details,
    Operator,
    Occurred
FROM History.IsSettledUpdateOperations WITH (NOLOCK)
WHERE Sucseeded = 0
  AND Occurred > DATEADD(month, -3, GETUTCDATE())
ORDER BY Occurred DESC
```

### 8.3 Summarize conversion batch results
```sql
SELECT
    OperationGuid,
    Operator,
    MIN(Occurred) AS BatchStarted,
    COUNT(*) AS TotalPositions,
    SUM(CAST(Sucseeded AS INT)) AS Succeeded,
    SUM(CASE WHEN Sucseeded = 0 THEN 1 ELSE 0 END) AS Failed,
    LEFT(MAX(Details), 8) AS Direction
FROM History.IsSettledUpdateOperations WITH (NOLOCK)
GROUP BY OperationGuid, Operator
ORDER BY BatchStarted DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.IsSettledUpdateOperations | Type: Table | Source: etoro/etoro/History/Tables/History.IsSettledUpdateOperations.sql*
