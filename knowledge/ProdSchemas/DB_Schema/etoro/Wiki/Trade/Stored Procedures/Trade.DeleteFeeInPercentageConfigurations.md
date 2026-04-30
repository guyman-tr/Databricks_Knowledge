# Trade.DeleteFeeInPercentageConfigurations

> Removes percentage-based fee configuration rows matching by instrument, instrument type, or group hierarchy, with existence validation and audit trail via CONTEXT_INFO.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ConfigTable (TVP of fee configurations to delete by DB row ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteFeeInPercentageConfigurations removes specific percentage-based fee configuration rules from Trade.FeeInPercentageConfigurations. Fee configurations define what percentage fee applies to trading operations for specific instruments, instrument types, or groups. This procedure is used by the Trading Operations (TRDOPS) admin tool when fee rules need to be updated or removed.

This procedure exists to provide validated deletion with audit trail. It ensures: (1) at least one targeting dimension (InstrumentID, InstrumentTypeID, or GroupID) is non-null, preventing accidental deletion of all configurations; (2) the DB row IDs in the input actually exist; and (3) the operation is traceable via CONTEXT_INFO.

Data flow: The caller provides a TVP containing rows with DBRowID (the existing config ID), InstrumentID, InstrumentTypeID, and GroupID. After validation, rows are matched using a 3-tier hierarchy pattern (instrument-level > type-level > group-level), ensuring each delete targets the correct hierarchy level.

---

## 2. Business Logic

### 2.1 Three-Tier Fee Hierarchy Matching

**What**: Fees can be configured at instrument, instrument-type, or group level. Delete matching respects this hierarchy.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentTypeID`, `GroupID`, `DBRowID`

**Rules**:
- Instrument-level: InstrumentID IS NOT NULL, InstrumentTypeID IS NULL, GroupID IS NULL
- Type-level: InstrumentID IS NULL, InstrumentTypeID IS NOT NULL, GroupID IS NULL
- Group-level: InstrumentID IS NULL, InstrumentTypeID IS NULL, GroupID IS NOT NULL
- DELETE uses OR to match the correct tier, AND fp.ID = dfp.DBRowID for exact row identification

### 2.2 Input Validation

**What**: Prevents invalid operations.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentTypeID`, `GroupID`, `DBRowID`

**Rules**:
- If any row has all three (InstrumentID, InstrumentTypeID, GroupID) as NULL: RAISERROR "cannot be null"
- If any DBRowID does not exist in Trade.FeeInPercentageConfigurations: RAISERROR "ID not Found in DB"

### 2.3 Audit Trail via CONTEXT_INFO

**What**: Records the operator identity for change tracking.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- Cast to VARBINARY(128) and set as CONTEXT_INFO before the DELETE
- Available to temporal table or trigger-based audit

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ConfigTable | Trade.FeeInPercentageInstrumentDataTbl (READONLY) | NO | - | CODE-BACKED | TVP containing fee configuration rows to delete. Each row has DBRowID (existing config ID), InstrumentID, InstrumentTypeID, and GroupID identifying the configuration level. |
| 2 | @AppLoginName | NVARCHAR(100) | YES | '' | CODE-BACKED | Operator login name for audit trail. Stored in CONTEXT_INFO. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE) | Trade.FeeInPercentageConfigurations | DELETER | Removes fee configuration rows matching the hierarchy level and DB row ID |
| (@ConfigTable) | Trade.FeeInPercentageInstrumentDataTbl | Type Reference | TVP type for batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteFeeInPercentageConfigurations (procedure)
+-- Trade.FeeInPercentageConfigurations (table)
+-- Trade.FeeInPercentageInstrumentDataTbl (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeInPercentageConfigurations | Table | Validation SELECT + DELETE target |
| Trade.FeeInPercentageInstrumentDataTbl | User Defined Type | Input parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Delete a fee configuration by row ID

```sql
DECLARE @Config Trade.FeeInPercentageInstrumentDataTbl
INSERT INTO @Config (DBRowID, InstrumentID, InstrumentTypeID, GroupID) VALUES (101, 1001, NULL, NULL)
EXEC Trade.DeleteFeeInPercentageConfigurations @ConfigTable = @Config, @AppLoginName = 'admin@etoro.com'
```

### 8.2 Check existing fee configurations

```sql
SELECT  ID, InstrumentID, InstrumentTypeID, GroupID, FeePercentage
FROM    Trade.FeeInPercentageConfigurations WITH (NOLOCK)
ORDER BY InstrumentID, InstrumentTypeID, GroupID
```

### 8.3 Verify deletion

```sql
SELECT  COUNT(*) AS RemainingConfigs
FROM    Trade.FeeInPercentageConfigurations WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteFeeInPercentageConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteFeeInPercentageConfigurations.sql*
