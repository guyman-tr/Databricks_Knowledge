# Trade.UpdateFixPerLotConfigurations

> Updates FeeValue and DataUpdated for a batch of fixed-per-lot fee configuration rows using a TVP; validates IDs exist and at least one scope key (InstrumentID, InstrumentTypeID, or GroupID) is set; stamps @AppLoginName in CONTEXT_INFO for temporal audit.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ConfigTable (TVP - Trade.FixPerLotConfigUpdateTbl) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateFixPerLotConfigurations is the controlled write path for updating fixed-per-lot fee configurations in `Trade.FixPerLotConfigurations`. While `Trade.UpdateFeeInPercentageConfigurations` handles percentage-based fees, this procedure handles the fixed-amount variant - where an instrument charges a flat dollar amount per lot (e.g., $1.50 per lot for US equities) rather than a percentage of trade value.

The procedure is structurally identical to Trade.UpdateFeeInPercentageConfigurations: same validation pattern, same hierarchical scope JOIN, same CONTEXT_INFO audit mechanism. The only differences are the TVP type (`Trade.FixPerLotConfigUpdateTbl`) and the target table (`Trade.FixPerLotConfigurations`).

Operations or configuration teams use this when recalibrating per-lot fees for instruments or groups - for example, adjusting the close-phase fixed fee for a batch of equity instruments following a broker fee renegotiation.

---

## 2. Business Logic

### 2.1 Pre-Flight Validation 1 - Scope Key Required

**What**: Every row in the TVP must have at least one of InstrumentID, InstrumentTypeID, or GroupID set.

**Columns/Parameters Involved**: `@ConfigTable.InstrumentID`, `@ConfigTable.InstrumentTypeID`, `@ConfigTable.GroupID`

**Rules**:
- `IF EXISTS (SELECT TOP 1 1 FROM @ConfigTable WHERE InstrumentID IS NULL AND InstrumentTypeID IS NULL AND GroupID IS NULL)` -> RAISERROR: "InstrumentID and InstrumentTypeID and GroupID cannot be null"
- Mirrors the CHECK constraint in Trade.FixPerLotConfigurations that requires exactly one scope key per row

### 2.2 Pre-Flight Validation 2 - ID Existence Check

**What**: All DBRowID values in the TVP must correspond to existing rows in Trade.FixPerLotConfigurations.

**Columns/Parameters Involved**: `@ConfigTable.DBRowID`, `Trade.FixPerLotConfigurations.ID`

**Rules**:
- `IF EXISTS (SELECT DBRowID FROM @ConfigTable src WHERE NOT EXISTS (SELECT 1 FROM Trade.FixPerLotConfigurations WHERE ID = src.DBRowID))` -> RAISERROR: "ID not Found in DB"
- Entire batch is rejected if any single ID is invalid (fail-fast before any UPDATE)

### 2.3 Hierarchical Scope JOIN

**What**: The UPDATE matches source to target using a three-way exclusive scope plus the ID safety check.

**Columns/Parameters Involved**: `dest.InstrumentID`, `dest.InstrumentTypeID`, `dest.GroupID`, `dest.ID`, `src.DBRowID`

**Rules**:
- Three mutually exclusive match branches:
  - Branch 1: `dest.InstrumentID IS NOT NULL AND dest.InstrumentTypeID IS NULL AND src.InstrumentID = dest.InstrumentID`
  - Branch 2: `dest.InstrumentID IS NULL AND dest.InstrumentTypeID IS NOT NULL AND src.InstrumentTypeID = dest.InstrumentTypeID`
  - Branch 3: `dest.InstrumentID IS NULL AND dest.InstrumentTypeID IS NULL AND dest.GroupID IS NOT NULL AND src.GroupID = dest.GroupID`
- AND always: `dest.ID = src.DBRowID`
- Sets: `dest.FeeValue = src.FeeValue`, `dest.DataUpdated = GETUTCDATE()`

### 2.4 CONTEXT_INFO Audit Trail

**What**: @AppLoginName is written to CONTEXT_INFO, captured by the computed AppLoginName column in Trade.FixPerLotConfigurations, and audited via the temporal table (History.FixPerLotConfigurations).

**Rules**:
- `DECLARE @info VARBINARY(128) = CAST(@AppLoginName AS VARBINARY(128))`
- `SET CONTEXT_INFO @info`
- Computed column `AppLoginName = context_info()` in the target table captures the caller identity per row
- Defaults to '' if @AppLoginName not supplied

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ConfigTable | Trade.FixPerLotConfigUpdateTbl READONLY | NO | - | CODE-BACKED | TVP containing the batch of fixed per-lot fee configurations to update. Each row: DBRowID (FK to Trade.FixPerLotConfigurations.ID), InstrumentID (nullable), InstrumentTypeID (nullable), GroupID (nullable - at least one must be non-null), FeeValue (decimal - new fixed per-lot fee amount in dollars). |
| 2 | @AppLoginName | nvarchar(100) | YES | '' | CODE-BACKED | Identity of the application or user performing the update. Stored in CONTEXT_INFO, captured by the computed AppLoginName column in Trade.FixPerLotConfigurations, and audited in History.FixPerLotConfigurations. Defaults to empty string. Truncated to 128 bytes after CAST to varbinary. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ConfigTable | Trade.FixPerLotConfigUpdateTbl | TVP | Input parameter type defining the batch structure |
| ID validation | Trade.FixPerLotConfigurations | Read | Checks all DBRowIDs exist before UPDATE |
| UPDATE target | Trade.FixPerLotConfigurations | Modifier | Updates FeeValue and DataUpdated for matched rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no callers found in SSDT. Invoked by fee configuration tooling or admin API.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateFixPerLotConfigurations (procedure)
+-- Trade.FixPerLotConfigUpdateTbl (TVP type)
+-- Trade.FixPerLotConfigurations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FixPerLotConfigUpdateTbl | User Defined Type (TVP) | Input parameter shape: DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue |
| Trade.FixPerLotConfigurations | Table | ID existence validation + UPDATE target for FeeValue and DataUpdated |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (fee configuration tooling / admin API) | - | Called by config management services when adjusting fixed per-lot fee rules |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. The TVP is materialized into `#ConfigTable` with a CLUSTERED INDEX on (DBRowID, InstrumentID, InstrumentTypeID) and a NONCLUSTERED INDEX on (InstrumentTypeID) to optimize the hierarchical scope JOIN.

### 7.2 Constraints

N/A for stored procedure. No explicit transaction wrapping. No TRY/CATCH. RAISERROR severity 16 aborts the batch before any UPDATE when validation fails.

---

## 8. Sample Queries

### 8.1 Update FeeValue for a batch of instrument-scoped per-lot configs
```sql
DECLARE @Updates Trade.FixPerLotConfigUpdateTbl;

INSERT INTO @Updates (DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue)
VALUES
  (35,  1001, NULL, NULL, 1.75),   -- instrument-scoped
  (93,  1003, NULL, NULL, 1.80),   -- instrument-scoped
  (100, 1111, NULL, NULL, 1.45);   -- instrument-scoped

EXEC Trade.UpdateFixPerLotConfigurations
    @ConfigTable  = @Updates,
    @AppLoginName = 'ops.team@etoro.com';
```

### 8.2 Check current per-lot fee configs
```sql
SELECT ID, InstrumentID, InstrumentTypeID, GroupID,
       IsSettled, FeeOperationTypeID, FeeValue, DataUpdated, AppLoginName
FROM   Trade.FixPerLotConfigurations WITH (NOLOCK)
WHERE  InstrumentID IN (1001, 1003, 1111)
ORDER  BY InstrumentID, FeeOperationTypeID;
```

### 8.3 Review temporal history for recent per-lot fee changes
```sql
SELECT TOP 20 *
FROM   History.FixPerLotConfigurations WITH (NOLOCK)
ORDER  BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateFixPerLotConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateFixPerLotConfigurations.sql*
