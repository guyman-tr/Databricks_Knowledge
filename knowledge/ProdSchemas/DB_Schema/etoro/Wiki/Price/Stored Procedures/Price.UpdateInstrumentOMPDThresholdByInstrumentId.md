# Price.UpdateInstrumentOMPDThresholdByInstrumentId

> Updates the numeric OMPD threshold value for a specific instrument and threshold type in Price.OMPDThresholdValues, with dictionary and existence validation before the update.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Price.OMPDThresholdValues WHERE (InstrumentID, ThresholdType); returns scalar confirmation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.UpdateInstrumentOMPDThresholdByInstrumentId changes the numeric tolerance value for a specific OMPD threshold type on an instrument. OMPD (Order Management Price Deviation) protects orders by rejecting those where the market has moved too far from the order-creation price. The tolerance is stored as a numeric value in `Price.OMPDThresholdValues` - for example, "40 Pips" or "50%".

This procedure updates that numeric value for a given (InstrumentID, ThresholdType) pair. Before updating, it validates two conditions: (1) the ThresholdType is a valid dictionary entry in `Dictionary.OMPDThresholdType`, and (2) the (InstrumentID, ThresholdType) row already exists in OMPDThresholdValues (this procedure does not create new rows - use `Price.CreateInstrumentOMPDThresholdByInstrumentId` for that). If either validation fails, an error is raised and no changes are made.

This is the numeric-value companion to `Price.UpdateActiveOMPDThresholdByInstrumentId` (which switches the active type selector). Use this procedure to tighten or loosen the threshold value without changing which type is active.

---

## 2. Business Logic

### 2.1 Validated Threshold Value Update

**What**: Updates the Value field for an existing (InstrumentID, ThresholdType) row in OMPDThresholdValues after two validations pass.

**Columns/Parameters Involved**: `@InstrumentID`, `@ThresholdType`, `@Value`

**Rules**:
- Validation 1: ThresholdType must exist in Dictionary.OMPDThresholdType (ThresholdTypeID match). Fails with: 'Invalid. ThresholdType must exist in the Dictionary.OMPDThresholdType table.'
- Validation 2: (InstrumentID, ThresholdType) must exist in OMPDThresholdValues. Fails with: 'Not Found. No record found with the specified InstrumentID and ThresholdType.'
- UPDATE Price.OMPDThresholdValues SET Value = @Value WHERE InstrumentID = @InstrumentID AND ThresholdType = @ThresholdType
- Returns scalar confirmation: SELECT @InstrumentID AS InstrumentId, @ThresholdType AS ThresholdType, @Value AS Value
- The update is tracked by temporal versioning (System Versioning on OMPDThresholdValues) - all previous values are preserved in History.OMPDThresholdValues

**Threshold type values** (from Dictionary.OMPDThresholdType, inherited from OMPDThresholdValues doc):
- 1 = Pips: Value is an absolute pip count (e.g., 40.00 = 40 pips)
- 2 = Percentage: Value is a percentage (e.g., 50.00 = 50%)

**Diagram**:
```
OMPDThresholdValues (before):
  InstrumentID=1, ThresholdType=1, Value=40.00 (Pips)

UpdateInstrumentOMPDThresholdByInstrumentId(@InstrumentID=1, @ThresholdType=1, @Value=55.00)
  -> Validation 1: Dictionary.OMPDThresholdType WHERE ThresholdTypeID=1 -> OK
  -> Validation 2: OMPDThresholdValues WHERE (1,1) EXISTS -> OK
  -> UPDATE SET Value=55.00 WHERE (InstrumentID=1, ThresholdType=1)

OMPDThresholdValues (after):
  InstrumentID=1, ThresholdType=1, Value=55.00 (Pips) [tightened tolerance]
  History: old Value=40.00 row preserved in History.OMPDThresholdValues
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The instrument whose threshold value is being updated. Must have an existing row in OMPDThresholdValues for the given @ThresholdType; raises 'Not Found' error otherwise. |
| 2 | @ThresholdType | INT | NOT NULL | - | CODE-BACKED | The threshold type to update: 1=Pips, 2=Percentage. Validated against Dictionary.OMPDThresholdType before update. This identifies which of the two value rows for this instrument to modify. |
| 3 | @Value | DECIMAL(20,2) | NOT NULL | - | CODE-BACKED | The new numeric threshold value. For Pips (type=1): number of pips (e.g., 40.00). For Percentage (type=2): percentage points (e.g., 50.00 = 50%). DECIMAL(20,2) supports very large values for instruments with high absolute prices. |

**Return columns (scalar SELECT, not a result set):**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| R1 | InstrumentId | INT | CODE-BACKED | Echo of @InstrumentID - confirms which instrument was updated. |
| R2 | ThresholdType | INT | CODE-BACKED | Echo of @ThresholdType - confirms which type was updated. |
| R3 | Value | DECIMAL(20,2) | CODE-BACKED | Echo of @Value - confirms the new value that was applied. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ThresholdType | Dictionary.OMPDThresholdType | Lookup (validation) | ThresholdType must be a valid dictionary entry before update proceeds |
| (@InstrumentID, @ThresholdType) | Price.OMPDThresholdValues | MODIFIER | Updates Value for the matched composite PK row |

### 5.2 Referenced By (other objects point to this)

No SQL callers found in the etoro SSDT repo. Called externally by the OMPD configuration API.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.UpdateInstrumentOMPDThresholdByInstrumentId (procedure)
├── Dictionary.OMPDThresholdType (table - validation lookup)
└── Price.OMPDThresholdValues (table - UPDATE target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OMPDThresholdType | Table | Validation - confirms @ThresholdType is a valid threshold type ID |
| Price.OMPDThresholdValues | Table | UPDATE target - sets Value for (InstrumentID, ThresholdType); also existence-checked |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ThresholdType validation | Guard | IF NOT EXISTS (Dictionary.OMPDThresholdType WHERE ThresholdTypeID=@ThresholdType) -> RAISERROR 'Invalid' |
| Record existence check | Guard | IF NOT EXISTS (OMPDThresholdValues WHERE InstrumentID=@InstrumentID AND ThresholdType=@ThresholdType) -> RAISERROR 'Not Found' |
| Print artifact | Note | DDL contains `print 'Price.UpdateInstrumentThresholdsWithActiveThreshold.sql'` - copy-paste artifact, no runtime effect |
| Temporal audit | Note | OMPDThresholdValues has SYSTEM_VERSIONING - all previous values auto-archived to History.OMPDThresholdValues on UPDATE |

---

## 8. Sample Queries

### 8.1 Update the Pips threshold value for an instrument

```sql
EXEC Price.UpdateInstrumentOMPDThresholdByInstrumentId
    @InstrumentID = 1,
    @ThresholdType = 1,  -- 1 = Pips
    @Value = 55.00;
-- Returns: InstrumentId=1, ThresholdType=1, Value=55.00
```

### 8.2 Update the Percentage threshold value

```sql
EXEC Price.UpdateInstrumentOMPDThresholdByInstrumentId
    @InstrumentID = 1,
    @ThresholdType = 2,  -- 2 = Percentage
    @Value = 45.00;
```

### 8.3 View the threshold value change history for an instrument

```sql
SELECT
    InstrumentID,
    ThresholdType,
    Value,
    UserName,
    SysStartTime,
    SysEndTime
FROM Price.OMPDThresholdValues
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1
  AND ThresholdType = 1
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Price.UpdateInstrumentOMPDThresholdByInstrumentId | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.UpdateInstrumentOMPDThresholdByInstrumentId.sql*
