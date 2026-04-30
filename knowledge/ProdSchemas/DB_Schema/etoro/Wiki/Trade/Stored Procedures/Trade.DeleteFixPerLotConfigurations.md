# Trade.DeleteFixPerLotConfigurations

> Removes fixed-per-lot fee configuration rows matching by instrument, instrument type, or group hierarchy, with existence validation and audit trail via CONTEXT_INFO.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ConfigTable (TVP of fee configurations to delete by DB row ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteFixPerLotConfigurations removes specific fixed-per-lot fee configuration rules from Trade.FixPerLotConfigurations. Fixed-per-lot fees define a flat fee per lot traded (as opposed to percentage-based fees). This procedure mirrors Trade.DeleteFeeInPercentageConfigurations but for the fixed-per-lot fee model.

This procedure exists to provide validated deletion with audit trail for the fixed-per-lot fee model. The same validation and three-tier hierarchy matching pattern is used as in the percentage fee variant.

Data flow: Same structure as DeleteFeeInPercentageConfigurations - validates input, sets CONTEXT_INFO for audit, and deletes matching rows using 3-tier hierarchy matching.

---

## 2. Business Logic

### 2.1 Three-Tier Fee Hierarchy Matching

**What**: Fees can be configured at instrument, instrument-type, or group level.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentTypeID`, `GroupID`, `DBRowID`

**Rules**:
- Same hierarchy as DeleteFeeInPercentageConfigurations: instrument > type > group
- DELETE matches the correct tier using OR conditions
- fp.ID = dfp.DBRowID ensures exact row identification

### 2.2 Input Validation

**What**: Prevents invalid operations.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentTypeID`, `GroupID`, `DBRowID`

**Rules**:
- All three targeting columns NULL: RAISERROR
- DBRowID not found in Trade.FixPerLotConfigurations: RAISERROR

### 2.3 Audit Trail via CONTEXT_INFO

**What**: Records the operator identity for change tracking.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- Same CONTEXT_INFO pattern as DeleteFeeInPercentageConfigurations

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ConfigTable | Trade.FixPerLotInstrumentDataTbl (READONLY) | NO | - | CODE-BACKED | TVP containing fee configuration rows to delete. Each row has DBRowID, InstrumentID, InstrumentTypeID, and GroupID identifying the configuration level. |
| 2 | @AppLoginName | NVARCHAR(100) | YES | '' | CODE-BACKED | Operator login name for audit trail. Stored in CONTEXT_INFO. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE) | Trade.FixPerLotConfigurations | DELETER | Removes fixed-per-lot fee rows matching hierarchy and DB row ID |
| (@ConfigTable) | Trade.FixPerLotInstrumentDataTbl | Type Reference | TVP type for batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteFixPerLotConfigurations (procedure)
+-- Trade.FixPerLotConfigurations (table)
+-- Trade.FixPerLotInstrumentDataTbl (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FixPerLotConfigurations | Table | Validation SELECT + DELETE target |
| Trade.FixPerLotInstrumentDataTbl | User Defined Type | Input parameter type |

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

### 8.1 Delete a fixed-per-lot fee configuration

```sql
DECLARE @Config Trade.FixPerLotInstrumentDataTbl
INSERT INTO @Config (DBRowID, InstrumentID, InstrumentTypeID, GroupID) VALUES (201, 1001, NULL, NULL)
EXEC Trade.DeleteFixPerLotConfigurations @ConfigTable = @Config, @AppLoginName = 'admin@etoro.com'
```

### 8.2 Check existing configurations

```sql
SELECT  ID, InstrumentID, InstrumentTypeID, GroupID
FROM    Trade.FixPerLotConfigurations WITH (NOLOCK)
ORDER BY InstrumentID, InstrumentTypeID, GroupID
```

### 8.3 Compare percentage vs fixed-per-lot config counts

```sql
SELECT  'Percentage' AS FeeModel, COUNT(*) AS ConfigCount FROM Trade.FeeInPercentageConfigurations WITH (NOLOCK)
UNION ALL
SELECT  'FixPerLot', COUNT(*) FROM Trade.FixPerLotConfigurations WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteFixPerLotConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteFixPerLotConfigurations.sql*
