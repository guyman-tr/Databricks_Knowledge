# Trade.UpdateFeeInPercentageConfigurations

> Updates FeeValue and DataUpdated for a batch of percentage-based fee configuration rows using a TVP; validates IDs exist and at least one scope key (InstrumentID, InstrumentTypeID, or GroupID) is set; stamps @AppLoginName in CONTEXT_INFO for temporal audit.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ConfigTable (TVP - Trade.FeeInPercentageConfigUpdateTbl) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateFeeInPercentageConfigurations is the controlled write path for updating percentage-based fee configurations in `Trade.FeeInPercentageConfigurations`. Operations or configuration teams use this when they need to adjust spread/commission percentages for instruments, instrument types, or fee groups - for example, changing the close-fee percentage for a stock from 4% to 3.5%, or updating a group-level fee rule.

The procedure enforces two pre-flight validations before any data is modified: (1) at least one scope dimension (InstrumentID, InstrumentTypeID, or GroupID) must be non-null in every TVP row, preventing unconstrained "update everything" rows; and (2) every DBRowID in the TVP must already exist in the target table, preventing silent no-ops on stale IDs.

The `@AppLoginName` parameter is stored in `CONTEXT_INFO` before the UPDATE, which causes the system-computed `AppLoginName` column in `Trade.FeeInPercentageConfigurations` to capture the caller's identity. Since the table is system-versioned (temporal), every FeeValue change is automatically audited in `History.FeeInPercentageConfigurations` with the before/after values and the timestamp.

---

## 2. Business Logic

### 2.1 Pre-Flight Validation 1 - Scope Key Required

**What**: Every row in the TVP must have at least one of InstrumentID, InstrumentTypeID, or GroupID set. A row with all three NULL would be an unconstrained wildcard update.

**Columns/Parameters Involved**: `@ConfigTable.InstrumentID`, `@ConfigTable.InstrumentTypeID`, `@ConfigTable.GroupID`

**Rules**:
- `IF EXISTS (SELECT TOP 1 1 FROM @ConfigTable WHERE InstrumentID IS NULL AND InstrumentTypeID IS NULL AND GroupID IS NULL)` -> RAISERROR: "InstrumentID and InstrumentTypeID and GroupID cannot be null"
- All three null simultaneously is invalid - the fee config table has a CHECK constraint enforcing exactly one scope key is non-null, so any update must respect the same constraint

### 2.2 Pre-Flight Validation 2 - ID Existence Check

**What**: All DBRowID values in the TVP must correspond to existing rows in Trade.FeeInPercentageConfigurations.

**Columns/Parameters Involved**: `@ConfigTable.DBRowID`, `Trade.FeeInPercentageConfigurations.ID`

**Rules**:
- `IF EXISTS (SELECT DBRowID FROM @ConfigTable src WHERE NOT EXISTS (SELECT 1 FROM Trade.FeeInPercentageConfigurations WHERE ID = src.DBRowID))` -> RAISERROR: "ID not Found in DB"
- Prevents silent no-ops when a caller passes a stale or wrong ID
- Checked before the UPDATE, so the entire batch is rejected if any ID is invalid (fail-fast)

### 2.3 Hierarchical Scope JOIN

**What**: The UPDATE joins the temp table to the target using a three-way exclusive scope match plus the ID safety check.

**Columns/Parameters Involved**: `dest.InstrumentID`, `dest.InstrumentTypeID`, `dest.GroupID`, `dest.ID`, `src.DBRowID`

**Rules**:
- Three mutually exclusive match branches (reflecting the CHECK constraint in Trade.FeeInPercentageConfigurations):
  - Branch 1: `dest.InstrumentID IS NOT NULL AND dest.InstrumentTypeID IS NULL AND src.InstrumentID = dest.InstrumentID`
  - Branch 2: `dest.InstrumentID IS NULL AND dest.InstrumentTypeID IS NOT NULL AND src.InstrumentTypeID = dest.InstrumentTypeID`
  - Branch 3: `dest.InstrumentID IS NULL AND dest.InstrumentTypeID IS NULL AND dest.GroupID IS NOT NULL AND src.GroupID = dest.GroupID`
- AND always: `dest.ID = src.DBRowID` (the ID constraint is the primary safety net; scope matching is the secondary discrimination)
- Sets: `dest.FeeValue = src.FeeValue`, `dest.DataUpdated = GETUTCDATE()`

### 2.4 CONTEXT_INFO Audit Trail

**What**: @AppLoginName is written to the SQL Server session's CONTEXT_INFO slot, making it available to the computed `AppLoginName` column in the target table for temporal audit capture.

**Columns/Parameters Involved**: `@AppLoginName`, `Trade.FeeInPercentageConfigurations.AppLoginName`

**Rules**:
- `DECLARE @info VARBINARY(128) = CAST(@AppLoginName AS VARBINARY(128))`
- `SET CONTEXT_INFO @info`
- The computed column `AppLoginName = context_info()` in Trade.FeeInPercentageConfigurations reads this value and stores it with each updated row
- The system-versioned temporal table then captures this in History.FeeInPercentageConfigurations
- @AppLoginName defaults to '' (empty string) if not supplied

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ConfigTable | Trade.FeeInPercentageConfigUpdateTbl READONLY | NO | - | CODE-BACKED | TVP containing the batch of fee configurations to update. Each row: DBRowID (FK to Trade.FeeInPercentageConfigurations.ID, required), InstrumentID (nullable), InstrumentTypeID (nullable), GroupID (nullable - at least one must be non-null), FeeValue (decimal - new percentage value). The scope columns are used in the hierarchical JOIN; DBRowID is the primary safety key. |
| 2 | @AppLoginName | nvarchar(100) | YES | '' | CODE-BACKED | Identity of the application or user performing the update. Stored in SQL Server CONTEXT_INFO for the session, captured by the computed AppLoginName column in Trade.FeeInPercentageConfigurations and audited via temporal history. Defaults to empty string if not provided. Cast to varbinary(128) - values longer than 128 bytes are truncated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ConfigTable | Trade.FeeInPercentageConfigUpdateTbl | TVP | Input parameter type defining the batch structure |
| ID validation | Trade.FeeInPercentageConfigurations | Read | Checks all DBRowIDs exist before UPDATE |
| UPDATE target | Trade.FeeInPercentageConfigurations | Modifier | Updates FeeValue and DataUpdated for matched rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no callers found in SSDT. Invoked by fee configuration tooling or admin API.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateFeeInPercentageConfigurations (procedure)
+-- Trade.FeeInPercentageConfigUpdateTbl (TVP type)
+-- Trade.FeeInPercentageConfigurations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeInPercentageConfigUpdateTbl | User Defined Type (TVP) | Input parameter shape: DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue |
| Trade.FeeInPercentageConfigurations | Table | ID existence validation + UPDATE target for FeeValue and DataUpdated |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (fee configuration tooling / admin API) | - | Called by config management services when adjusting percentage fee rules |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. The TVP is materialized into `#ConfigTable` with a CLUSTERED INDEX on (DBRowID, InstrumentID, InstrumentTypeID) and a NONCLUSTERED INDEX on (InstrumentTypeID) to optimize the JOIN.

### 7.2 Constraints

N/A for stored procedure. No explicit transaction - the UPDATE is a single statement. No TRY/CATCH; errors propagate to the caller. RAISERROR severity 16 causes the batch to terminate before the UPDATE if validation fails.

---

## 8. Sample Queries

### 8.1 Update FeeValue for a batch of instrument-specific configs
```sql
DECLARE @Updates Trade.FeeInPercentageConfigUpdateTbl;

INSERT INTO @Updates (DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue)
VALUES
  (507, 3,    NULL, NULL, 3.00),   -- instrument-scoped: ID=507, InstrumentID=3
  (552, 4,    NULL, NULL, 3.50),   -- instrument-scoped: ID=552, InstrumentID=4
  (625, 1,    NULL, NULL, 0.75);   -- instrument-scoped: ID=625, InstrumentID=1

EXEC Trade.UpdateFeeInPercentageConfigurations
    @ConfigTable  = @Updates,
    @AppLoginName = 'ops.team@etoro.com';
```

### 8.2 Check current percentage fee configs
```sql
SELECT ID, InstrumentID, InstrumentTypeID, GroupID,
       IsSettled, FeeOperationTypeID, FeeValue, DataUpdated, AppLoginName
FROM   Trade.FeeInPercentageConfigurations WITH (NOLOCK)
WHERE  InstrumentID IN (1, 3, 4)
ORDER  BY InstrumentID, FeeOperationTypeID;
```

### 8.3 Review temporal history for recent changes
```sql
SELECT TOP 20 *
FROM   History.FeeInPercentageConfigurations WITH (NOLOCK)
ORDER  BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateFeeInPercentageConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateFeeInPercentageConfigurations.sql*
