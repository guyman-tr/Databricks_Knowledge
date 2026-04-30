# Trade.UpdateIsSettled

> Batch settlement-type conversion procedure that migrates positions between CFD (IsSettled=0) and REAL stock (IsSettled=1) settlement, updating Trade.PositionTbl in chunks of @Delta, writing position change log entries to History.PositionChangeLog_Active_BIGINT, deriving PnLVersion from Feature 120, and recording all results to History.IsSettledUpdateOperations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionIDsTbl.PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

eToro positions can exist in one of two settlement modes: CFD (Contract for Difference, IsSettled=0, synthetic derivative) and REAL stock settlement (IsSettled=1, actual share ownership). When a customer transitions between these modes - typically as part of a corporate action, a regulatory requirement, or an internal operational fix - positions must be migrated from CFD to REAL (CFD2REAL) or back from REAL to CFD (REAL2CFD).

This procedure performs that migration in a chunked batch approach to avoid long-running transactions on the highly-partitioned Trade.PositionTbl. Each chunk (default 5000 positions) is processed in its own transaction. The procedure:

1. Captures the pre-change state of all target positions into a global temp table
2. Processes positions in chunks of @Delta rows
3. For each chunk: UPDATE PositionTbl (IsSettled, SettlementTypeID, PnLVersion) + INSERT position change log entries
4. Marks each chunk's outcome (Status = 1 = success, 0 = failure with error message)
5. Inserts all outcomes into History.IsSettledUpdateOperations for audit

The PnLVersion change is linked to Feature 120 (a feature flag): if Feature 120 is enabled AND the direction is CFD->REAL (@IsSettledToSet=1), PnLVersion is set to 1; otherwise it remains 0. This allows the trading engine to apply different P&L calculation formulas for real stock positions.

---

## 2. Business Logic

### 2.1 PnLVersion Derivation from Feature 120

**What**: The PnLVersion to assign depends on a feature flag and the direction of the settlement change.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID` (= 120), `@IsSettledToSet`, `@PnLVersionToSet`

**Rules**:
- `@EnableNewPnLFormula = CAST(Value AS bit) FROM Maintenance.Feature WHERE FeatureID = 120`
- `@PnLVersionToSet = CAST(@EnableNewPnLFormula AS TINYINT) * @IsSettledToSet`
- If Feature 120 ON and @IsSettledToSet=1 (CFD->REAL): PnLVersion = 1 (new formula)
- If Feature 120 OFF or @IsSettledToSet=0 (REAL->CFD): PnLVersion = 0 (standard formula)

### 2.2 Partitioned Position Lookup

**What**: Positions are loaded from the partitioned Trade.Position view using the partition key.

**Columns/Parameters Involved**: `PositionID % 50`, `PositionPartitionCol`

**Rules**:
- JOIN: `ids.PositionID % 50 = tp.PositionPartitionCol`
- This is the standard partition lookup pattern for Trade.Position/PositionTbl (50 partitions, modulo-based routing)
- Loads all relevant position fields into global temp table ##PCL_Data for batch processing

### 2.3 Chunked Batch Processing

**What**: Positions are updated in batches of @Delta rows to limit transaction scope on the partitioned table.

**Columns/Parameters Involved**: `@Delta` (default 5000), `@MinID`, `##PCL_Data.ID` (ROW_NUMBER)

**Rules**:
- WHILE EXISTS (Status IS NULL): process rows where ID BETWEEN @MinID AND @MinID+@Delta-1
- Each iteration: UPDATE PositionTbl + INSERT PCL in one transaction
- On success: UPDATE ##PCL_Data SET Status=1, advance @MinID
- On error: ROLLBACK, SET Status=0+ErrorMessage, advance @MinID (continues processing remaining chunks)
- WITH RECOMPILE: plan is regenerated on each execution to prevent plan reuse with stale cardinality estimates

### 2.4 PositionTbl Update

**What**: Sets IsSettled, SettlementTypeID, and PnLVersion for the chunk.

**Columns/Parameters Involved**: `IsSettled`, `SettlementTypeID`, `PnLVersion`

**Rules**:
- `SET IsSettled = @IsSettledToSet, SettlementTypeID = @IsSettledToSet, PnLVersion = @PnLVersionToSet`
- Note: Both IsSettled and SettlementTypeID are set to the same @IsSettledToSet value (bit: 0 or 1)
- JOIN uses partition key: `p.PositionID % 50 = t.PartitionCol`

### 2.5 Position Change Log (PCL) Entry

**What**: Every position in the chunk gets a PositionChangeLog entry recording the before/after state.

**Columns/Parameters Involved**: `History.PositionChangeLog_Active_BIGINT`, `ChangeTypeID` (= 13), `ClientRequestGuid` (= @OperationGuid)

**Rules**:
- ChangeTypeID = 13 (hard-coded: settlement type conversion)
- PreviousIsSettled from ##PCL_Data; IsSettled = @IsSettledToSet
- PreviousSettlementTypeID from ##PCL_Data; SettlementTypeID = @IsSettledToSet
- PreviousPnLVersion from ##PCL_Data; PnLVersion = @PnLVersionToSet
- Most "delta" fields (Amount, Rates) are recorded as same before/after (AmountChanged=0, same LimitRate, StopRate etc.)
- ClientRequestGuid = @OperationGuid for traceability

### 2.6 Audit in IsSettledUpdateOperations

**What**: After all chunks are processed, one row per position is inserted into History.IsSettledUpdateOperations recording the outcome.

**Columns/Parameters Involved**: `History.IsSettledUpdateOperations`, `Sucseeded`, `Details`, `OperationGuid`

**Rules**:
- Details: IIF(@IsSettledToSet=1, 'CFD2REAL', 'REAL2CFD') + ErrorMessage (if any)
- Sucseeded = 1 if chunk succeeded, 0 if error
- OperationGuid links all entries from this call

### 2.7 OperationGuid Regeneration Bug Note

**What**: There is a code defect in the OperationGuid logic.

**Rules**:
- IF @OperationGuid IS NOT NULL -> `SET @OperationGuid = NEWID()` (overwrites the caller-provided value with a new one)
- This is likely a bug (should be `IF @OperationGuid IS NULL`); it means callers cannot provide a stable GUID for correlation
- Effective behavior: OperationGuid is always a fresh NEWID() regardless of what the caller passes

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionIDsTbl | Trade.PositionIDsTbl (TVP, READONLY) | NO | - | CODE-BACKED | Batch of PositionIDs (bigint) to migrate. Each PositionID is processed in chunk order. Positions not found in Trade.Position are silently skipped in the UPDATE (no error at chunk level). |
| 2 | @IsSettledToSet | bit | NO | - | CODE-BACKED | Target settlement state: 1 = convert to REAL stock (CFD2REAL), 0 = convert to CFD (REAL2CFD). Applied to both IsSettled and SettlementTypeID columns in Trade.PositionTbl. |
| 3 | @OperatorIdentifier | varchar(30) | YES | NULL | CODE-BACKED | Operator name or service identifier written to History.IsSettledUpdateOperations.Operator for audit. |
| 4 | @OperationGuid | uniqueidentifier | YES | NULL | CODE-BACKED | Correlation GUID for the operation. Written to PositionChangeLog.ClientRequestGuid and IsSettledUpdateOperations.OperationGuid. Note: due to a code issue (NULL check inverted), a caller-provided value is overwritten with NEWID(). |
| 5 | @Delta | int | YES | 5000 | CODE-BACKED | Chunk size: number of positions processed per transaction. Default 5000. Lower values reduce transaction duration but increase iteration count. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID + PartitionCol | Trade.PositionTbl | UPDATE | Sets IsSettled, SettlementTypeID, PnLVersion in chunks |
| PositionID + PartitionCol | Trade.Position | SELECT (read) | Reads current position state into ##PCL_Data before update |
| FeatureID = 120 | Maintenance.Feature | SELECT (read) | Feature flag controlling whether PnLVersion is updated on CFD->REAL |
| Batch outcome | History.PositionChangeLog_Active_BIGINT | INSERT | Change log entries (ChangeTypeID=13) for every position in each chunk |
| Operation audit | History.IsSettledUpdateOperations | INSERT | One row per position with success/failure status and direction (CFD2REAL/REAL2CFD) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External operational tooling | Application call | Caller | No internal SP callers found; invoked from ops tooling for settlement conversion workflows (typically preceded by UpdateIsSettledValidation) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateIsSettled (procedure)
|- Maintenance.Feature (table) [READ - FeatureID=120 for PnLVersion derivation]
|- Trade.Position (view) [READ - current position state into ##PCL_Data]
|- Trade.PositionTbl (table) [UPDATE - IsSettled, SettlementTypeID, PnLVersion in @Delta chunks]
|- History.PositionChangeLog_Active_BIGINT (table) [INSERT - ChangeTypeID=13 PCL entries]
+-- History.IsSettledUpdateOperations (table) [INSERT - one row per position, success/failure audit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | READ: FeatureID=120 value determines PnLVersion to set |
| Trade.Position | View | READ: Current position state (all relevant fields) loaded into ##PCL_Data |
| Trade.PositionTbl | Table | UPDATEd: IsSettled, SettlementTypeID, PnLVersion set per chunk |
| History.PositionChangeLog_Active_BIGINT | Table | INSERTed: ChangeTypeID=13 PCL entries per position per chunk |
| History.IsSettledUpdateOperations | Table | INSERTed: Operation audit - one row per position with status and direction |
| Trade.PositionIDsTbl | User Defined Type | TVP type for @PositionIDsTbl |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External settlement management tooling | Application | Calls this after UpdateIsSettledValidation pre-screens positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Hint | Query plan regenerated on each execution; prevents stale plan reuse for variable-size batches |
| Chunk-tolerant errors | Design | Failure in one chunk sets Status=0 + ErrorMessage but processing continues to next chunk |
| OperationGuid bug | Code issue | IF @OperationGuid IS NOT NULL -> assigns NEWID() (should be IS NULL); caller-provided GUID is overwritten |
| Global temp table | Design | ##PCL_Data is a global temp table (double ##) - visible across sessions; cleaned up by DROP TABLE IF EXISTS at start |
| Partition join | Pattern | PositionID % 50 = PartitionCol - standard partition routing for Trade.PositionTbl |
| ChangeTypeID=13 | Hard-coded | Settlement type conversion change type; recorded in PositionChangeLog |

---

## 8. Sample Queries

### 8.1 Convert positions from CFD to REAL stock

```sql
DECLARE @Positions [Trade].[PositionIDsTbl]
INSERT INTO @Positions (PositionID)
VALUES (100001), (100002), (100003)

DECLARE @OpGuid UNIQUEIDENTIFIER = NEWID()
EXEC Trade.UpdateIsSettled
    @PositionIDsTbl = @Positions,
    @IsSettledToSet = 1,    -- CFD to REAL
    @OperatorIdentifier = 'ops_admin',
    @OperationGuid = @OpGuid,
    @Delta = 5000
```

### 8.2 Convert positions back from REAL to CFD

```sql
DECLARE @Positions [Trade].[PositionIDsTbl]
INSERT INTO @Positions (PositionID)
VALUES (100001), (100002)

EXEC Trade.UpdateIsSettled
    @PositionIDsTbl = @Positions,
    @IsSettledToSet = 0,    -- REAL to CFD
    @OperatorIdentifier = 'ops_admin',
    @OperationGuid = NULL,
    @Delta = 1000   -- Smaller chunks for safety
```

### 8.3 Check operation audit results

```sql
SELECT
    op.PositionID,
    op.Sucseeded,
    op.Occurred,
    op.Details,
    op.Operator,
    op.OperationGuid
FROM History.IsSettledUpdateOperations op WITH (NOLOCK)
WHERE op.OperationGuid = @OpGuid
ORDER BY op.PositionID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateIsSettled | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateIsSettled.sql*
