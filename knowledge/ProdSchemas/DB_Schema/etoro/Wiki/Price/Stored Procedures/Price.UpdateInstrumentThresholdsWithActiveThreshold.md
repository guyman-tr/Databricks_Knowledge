# Price.UpdateInstrumentThresholdsWithActiveThreshold

> Atomically updates one or more OMPD threshold values and optionally switches the active threshold type for a specific instrument, combining the value-update and type-switch operations into a single validated transaction.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Price.OMPDThresholdValues (bulk from TVP) and optionally Price.OMPDActiveThreshold; returns JSON confirmation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.UpdateInstrumentThresholdsWithActiveThreshold is the comprehensive OMPD configuration update procedure. While `Price.UpdateInstrumentOMPDThresholdByInstrumentId` updates a single threshold value and `Price.UpdateActiveOMPDThresholdByInstrumentId` switches only the active type, this procedure combines both operations: it accepts a batch of threshold values via a table-valued parameter (TVP) and optionally changes the active threshold type in the same atomic transaction.

This is designed for UI-driven scenarios where an operator views an instrument's complete OMPD configuration (all threshold values + active type) and submits changes to multiple aspects at once. The TVP accepts one or two rows (one per threshold type), and @ActiveThresholdType controls which type should be active after the update. If @ActiveThresholdType is NULL, only the values are updated; the active type selector remains unchanged.

The procedure has five validation guards before DML begins, ensuring all inputs are consistent with the current database state. Any validation failure raises an error and no data is changed. All DML executes in a single BEGIN TRANSACTION/COMMIT with full ROLLBACK on any failure.

---

## 2. Business Logic

### 2.1 Five-Gate Validation Pipeline

**What**: Before any updates, five sequential checks validate the input against the current DB state.

**Columns/Parameters Involved**: `@InstrumentID`, `@ThresholdValues`, `@ActiveThresholdType`

**Rules**:
1. `Trade.InstrumentMetaData WHERE InstrumentID=@InstrumentID` - instrument must exist
2. `@ThresholdValues tv LEFT JOIN Dictionary.OMPDThresholdType dt ON tv.ThresholdType=dt.ThresholdTypeID WHERE dt.ThresholdTypeID IS NULL` - all ThresholdType values in TVP must be valid dictionary entries
3. `@ThresholdValues tv LEFT JOIN Price.OMPDThresholdValues pv WHERE pv.ThresholdType IS NULL` - each (InstrumentID, ThresholdType) pair in TVP must already exist in OMPDThresholdValues (no INSERT, only UPDATE)
4. (Only if @ActiveThresholdType IS NOT NULL): `@ThresholdValues WHERE ThresholdType=@ActiveThresholdType` - the active type must be present in the submitted TVP
5. (Only if @ActiveThresholdType IS NOT NULL): `Price.OMPDActiveThreshold WHERE InstrumentID=@InstrumentID` - an active threshold record must exist for this instrument

**Error messages**:
- Gate 1 fail: 'Invalid. InstrumentID must exist in the Trade.InstrumentMetaData table.'
- Gate 2 fail: 'Invalid. ThresholdType in ThresholdValues must exist in the Dictionary.OMPDThresholdType table.'
- Gate 3 fail: 'Invalid. All threshold types in ThresholdValues must exist in Price.OMPDThresholdValues for the specified InstrumentID.'
- Gate 4 fail: 'Invalid. ActiveThresholdType must exist in the provided ThresholdValues.'
- Gate 5 fail: 'Invalid. ThresholdType must exist in Price.OMPDActiveThreshold for the specified InstrumentID.' (when @ActiveThresholdType IS NOT NULL) or 'Not Found. No active threshold type found for the InstrumentID to update.' (when @ActiveThresholdType IS NULL but no OMPDActiveThreshold row)

### 2.2 Dual-Target Atomic Update

**What**: Within a transaction, updates threshold values and optionally switches active type.

**Columns/Parameters Involved**: `@ThresholdValues`, `@ActiveThresholdType`

**Rules**:
- UPDATE 1: Price.OMPDThresholdValues SET Value=srcTbl.Value WHERE InstrumentID=@InstrumentID AND ThresholdType matching TVP rows
- UPDATE 2 (only if @ActiveThresholdType IS NOT NULL): Price.OMPDActiveThreshold SET ThresholdType=@ActiveThresholdType WHERE InstrumentID=@InstrumentID
- Both updates in BEGIN TRANSACTION / COMMIT TRANSACTION
- CATCH block: ROLLBACK, re-raise error via RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)

**Diagram**:
```
INPUT: @InstrumentID=1, @ThresholdValues=[(Type=1, Value=55.00), (Type=2, Value=45.00)], @ActiveThresholdType=2

Step 1: 5 validation gates (all must pass)
Step 2: BEGIN TRANSACTION
  UPDATE OMPDThresholdValues: InstrumentID=1, ThresholdType=1 -> Value=55.00
  UPDATE OMPDThresholdValues: InstrumentID=1, ThresholdType=2 -> Value=45.00
  UPDATE OMPDActiveThreshold: InstrumentID=1, ThresholdType=2 (switch to Percentage)
Step 3: COMMIT TRANSACTION

OUTPUT (JSON via FOR JSON PATH):
  InstrumentID=1, ActiveThresholdType=2,
  ThresholdValues=[{"ThresholdType":1,"Value":55.00},{"ThresholdType":2,"Value":45.00}]
```

### 2.3 JSON Return Format

**What**: Returns a confirmation row with the submitted values in JSON format.

**Rules**:
- SELECT InstrumentID=@InstrumentID, ActiveThresholdType=CASE WHEN @ActiveThresholdType IS NULL THEN 0 ELSE @ActiveThresholdType END, ThresholdValues=(SELECT ThresholdType, Value FROM @ThresholdValues FOR JSON PATH)
- Note: returns 0 for ActiveThresholdType when @ActiveThresholdType was NULL (not the actual active type)
- ThresholdValues is a JSON array of the submitted TVP rows, not a re-read from DB

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The instrument whose OMPD thresholds are being updated. Validated against Trade.InstrumentMetaData before any DML. |
| 2 | @ThresholdValues | Price.ThresholdsTypeValue READONLY | NOT NULL | - | CODE-BACKED | Table-valued parameter (TVP) containing the threshold updates. Uses the Price.ThresholdsTypeValue UDT which has columns (ThresholdType INT, Value DECIMAL). Each row updates the matching (InstrumentID, ThresholdType) in OMPDThresholdValues. |
| 3 | @ActiveThresholdType | INT | YES | NULL | CODE-BACKED | Optional. If provided, switches Price.OMPDActiveThreshold.ThresholdType to this value after updating the values. If NULL, the active type is left unchanged. Must be a ThresholdType value present in @ThresholdValues (gate 4 validates this). |

**Return columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| R1 | InstrumentID | INT | CODE-BACKED | The instrument that was updated. |
| R2 | ActiveThresholdType | INT | CODE-BACKED | The @ActiveThresholdType value submitted (or 0 if NULL was passed - not the actual current active type). |
| R3 | ThresholdValues | NVARCHAR (JSON) | CODE-BACKED | JSON array of the submitted threshold values: [{"ThresholdType":N,"Value":N.NN},...] |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentMetaData | Lookup (validation) | Gate 1: instrument must exist |
| @ThresholdValues.ThresholdType | Dictionary.OMPDThresholdType | Lookup (validation) | Gate 2: each threshold type must be a valid dictionary entry |
| (@InstrumentID, @ThresholdValues.ThresholdType) | Price.OMPDThresholdValues | MODIFIER | Updates Value; also used in gate 3 existence check |
| @InstrumentID | Price.OMPDActiveThreshold | MODIFIER (conditional) | Updates ThresholdType if @ActiveThresholdType is not NULL; used in gate 5 existence check |

### 5.2 Referenced By (other objects point to this)

No SQL callers found in the etoro SSDT repo. Called externally by the OMPD configuration API.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.UpdateInstrumentThresholdsWithActiveThreshold (procedure)
├── Trade.InstrumentMetaData (table - validation: instrument must exist)
├── Dictionary.OMPDThresholdType (table - validation: threshold types must be valid)
├── Price.OMPDThresholdValues (table - UPDATE target for threshold values)
└── Price.OMPDActiveThreshold (table - conditional UPDATE target for active type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | Gate 1 validation - InstrumentID must exist |
| Dictionary.OMPDThresholdType | Table | Gate 2 validation - ThresholdType values must be valid |
| Price.OMPDThresholdValues | Table | Gate 3 validation + UPDATE target (threshold values) |
| Price.OMPDActiveThreshold | Table | Gate 4/5 validation + conditional UPDATE target (active type switch) |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 5-gate validation | Pre-DML | All 5 guards must pass; any failure raises RAISERROR severity 16 and exits |
| Full transaction | Atomicity | BEGIN TRANSACTION / COMMIT; CATCH -> ROLLBACK; re-raises original error |
| TVP type | Parameter | @ThresholdValues uses Price.ThresholdsTypeValue UDT - caller must create a typed variable matching this UDT |
| JSON return | Note | ThresholdValues in result is the submitted input as JSON, not a re-read from the DB |

---

## 8. Sample Queries

### 8.1 Update both threshold values and switch active type to Percentage

```sql
DECLARE @TV Price.ThresholdsTypeValue;
INSERT INTO @TV VALUES (1, 55.00), (2, 45.00);  -- Pips=55, Percentage=45

EXEC Price.UpdateInstrumentThresholdsWithActiveThreshold
    @InstrumentID = 1,
    @ThresholdValues = @TV,
    @ActiveThresholdType = 2;  -- Switch to Percentage
```

### 8.2 Update only the Pips value without changing the active type

```sql
DECLARE @TV Price.ThresholdsTypeValue;
INSERT INTO @TV VALUES (1, 40.00);  -- Update Pips threshold only

EXEC Price.UpdateInstrumentThresholdsWithActiveThreshold
    @InstrumentID = 1,
    @ThresholdValues = @TV,
    @ActiveThresholdType = NULL;  -- Keep current active type unchanged
```

### 8.3 Verify the updated state after the call

```sql
SELECT
    AT.InstrumentID,
    AT.ThresholdType AS ActiveType,
    OTT.Name AS ActiveTypeName,
    TV1.Value AS PipsValue,
    TV2.Value AS PercentageValue
FROM Price.OMPDActiveThreshold AT WITH (NOLOCK)
JOIN Dictionary.OMPDThresholdType OTT WITH (NOLOCK) ON OTT.ThresholdTypeID = AT.ThresholdType
LEFT JOIN Price.OMPDThresholdValues TV1 WITH (NOLOCK) ON TV1.InstrumentID = AT.InstrumentID AND TV1.ThresholdType = 1
LEFT JOIN Price.OMPDThresholdValues TV2 WITH (NOLOCK) ON TV2.InstrumentID = AT.InstrumentID AND TV2.ThresholdType = 2
WHERE AT.InstrumentID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Price.UpdateInstrumentThresholdsWithActiveThreshold | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.UpdateInstrumentThresholdsWithActiveThreshold.sql*
