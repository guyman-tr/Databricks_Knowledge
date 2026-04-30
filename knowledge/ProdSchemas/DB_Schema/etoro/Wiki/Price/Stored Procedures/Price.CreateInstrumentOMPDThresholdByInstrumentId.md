# Price.CreateInstrumentOMPDThresholdByInstrumentId

> Validated INSERT procedure that creates a new OMPD threshold value row for an instrument-type combination in Price.OMPDThresholdValues - enforces three pre-conditions and is the required first step before activating an OMPD threshold.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID + @ThresholdType (composite identifies the new value row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.CreateInstrumentOMPDThresholdByInstrumentId creates the threshold value record for a specific instrument and threshold type in Price.OMPDThresholdValues. This is the first step in setting up OMPD (Order Management Price Deviation) for an instrument: before an active threshold can be designated (via Price.CreateActiveOMPDThresholdByInstrumentId), the value record must exist.

OMPD protects traders from price slippage between order submission and execution. Each instrument can have two threshold configurations - one in Pips (ThresholdType=1) and one in Percentage (ThresholdType=2). This procedure stores the actual numeric threshold value (e.g., 40 pips, or 50%) for one of those types. An instrument can call this procedure twice to pre-populate both types, then use Price.OMPDActiveThreshold to switch between them without data loss.

Called by pricing management admin tools when adding OMPD coverage for new instruments or adding a second threshold type to an existing instrument.

---

## 2. Business Logic

### 2.1 Three-Guard Validation Before Insert

**What**: Three sequential validation guards prevent invalid inserts. Any failure raises RAISERROR (severity 16) and returns without inserting.

**Columns/Parameters Involved**: `@InstrumentID`, `@ThresholdType`, `@Value`

**Rules**:

Guard 1 - ThresholdType must be valid:
- EXISTS check: Dictionary.OMPDThresholdType WHERE ThresholdTypeID = @ThresholdType
- Valid values: 1=Pips, 2=Percentage
- Error: "Invalid. ThresholdType must exist in the Dictionary.OMPDThresholdType table."

Guard 2 - Instrument must exist in Trade.InstrumentMetaData:
- EXISTS check: Trade.InstrumentMetaData WHERE InstrumentID = @InstrumentID
- Ensures only valid instruments can have threshold values
- Error: "Invalid. InstrumentID must exist in the Trade.InstrumentMetaData table."
- Note: uses InstrumentMetaData (not Trade.Instrument) - consistent with OMPD's metadata-level design

Guard 3 - Combination must not already exist:
- EXISTS check: OMPDThresholdValues WHERE InstrumentID = @InstrumentID AND ThresholdType = @ThresholdType
- Prevents duplicate (InstrumentID, ThresholdType) pairs (composite PK would also catch this, but the guard provides a descriptive error)
- Error: "Conflict, The combination of InstrumentID and ThresholdType already exists."
- To update an existing value: use Price.UpdateInstrumentOMPDThresholdByInstrumentId instead

**Setup sequence for a new instrument**:
```
1. Price.CreateInstrumentOMPDThresholdByInstrumentId(@InstrumentID, ThresholdType=1, Value=40)  [Pips]
2. Price.CreateInstrumentOMPDThresholdByInstrumentId(@InstrumentID, ThresholdType=2, Value=50)  [Percentage, optional]
3. Price.CreateActiveOMPDThresholdByInstrumentId(@InstrumentID, ThresholdType=1)                [Activate Pips]
```

### 2.2 Unqualified Table Reference

**What**: The INSERT target and SELECT check reference `OMPDThresholdValues` without a schema prefix.

**Columns/Parameters Involved**: INSERT target

**Rules**:
- `FROM OMPDThresholdValues` and `INSERT INTO OMPDThresholdValues` resolve to Price.OMPDThresholdValues in context (procedure is in the Price schema and default schema resolution applies)
- Functionally identical to `Price.OMPDThresholdValues` - this is a DDL style inconsistency, not a functional issue

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | IN | - | CODE-BACKED | The instrument to create an OMPD threshold value for. Must exist in Trade.InstrumentMetaData. Stored in Price.OMPDThresholdValues.InstrumentID as part of the composite PK. |
| 2 | @ThresholdType | INT | IN | - | CODE-BACKED | The OMPD threshold type for this value: 1=Pips (absolute pip deviation), 2=Percentage (percentage deviation). Must exist in Dictionary.OMPDThresholdType. Combined with @InstrumentID to form the composite PK - calling this procedure twice with different @ThresholdType values stores both types for the same instrument. |
| 3 | @Value | DECIMAL(20,2) | IN | - | CODE-BACKED | The threshold numeric value. For ThresholdType=1 (Pips): the maximum allowed pip deviation (e.g., 40.00). For ThresholdType=2 (Percentage): the maximum allowed percentage deviation (e.g., 50.00). Stored in Price.OMPDThresholdValues.Value. |

**Output result set (on success):**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 1 | InstrumentID | INT | NO | CODE-BACKED | Echo of @InstrumentID - confirms the instrument for which the threshold value was created. |
| 2 | ThresholdType | INT | NO | CODE-BACKED | Echo of @ThresholdType - confirms the type stored (1=Pips, 2=Percentage). |
| 3 | Value | DECIMAL(20,2) | NO | CODE-BACKED | Echo of @Value - confirms the threshold value that was stored. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ThresholdType | Dictionary.OMPDThresholdType | VALIDATION READ | Guard 1: validates threshold type exists |
| @InstrumentID | Trade.InstrumentMetaData | VALIDATION READ | Guard 2: validates instrument exists |
| @InstrumentID + @ThresholdType | Price.OMPDThresholdValues | VALIDATION READ + INSERT | Guard 3: checks uniqueness; then INSERTs new threshold value row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no SQL callers found within the Price schema (called by external pricing management API).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.CreateInstrumentOMPDThresholdByInstrumentId (procedure)
├── Dictionary.OMPDThresholdType (table) - validation
├── Trade.InstrumentMetaData (table) - validation
└── Price.OMPDThresholdValues (table) - INSERT target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OMPDThresholdType | Table | EXISTS check - Guard 1 threshold type validation |
| Trade.InstrumentMetaData | Table | EXISTS check - Guard 2 instrument existence validation |
| Price.OMPDThresholdValues | Table | EXISTS check (Guard 3) + INSERT target (unqualified reference resolves to Price schema) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found in Price schema | - | Called by external pricing management API; prerequisite for CreateActiveOMPDThresholdByInstrumentId |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Three IF NOT EXISTS/EXISTS guards with RAISERROR (severity 16, state 1) + RETURN on failure. No explicit transaction. Uses `SELECT top 1 1` existence pattern. The DDL file ends with `print 'Price.DeleteOMPDThresholdByInstrumentID.sql'` - this is a deployment script artifact, not part of the procedure logic.

---

## 8. Sample Queries

### 8.1 Create both threshold types for a new instrument

```sql
-- Create Pips threshold value
EXEC Price.CreateInstrumentOMPDThresholdByInstrumentId
    @InstrumentID = 100,
    @ThresholdType = 1,
    @Value = 40.00;

-- Create Percentage threshold value (optional - allows future type switching without data loss)
EXEC Price.CreateInstrumentOMPDThresholdByInstrumentId
    @InstrumentID = 100,
    @ThresholdType = 2,
    @Value = 50.00;
```

### 8.2 Verify both threshold values were created

```sql
SELECT InstrumentID, ThresholdType,
       CASE ThresholdType WHEN 1 THEN 'Pips' WHEN 2 THEN 'Percentage' END AS TypeLabel,
       Value
FROM Price.OMPDThresholdValues WITH (NOLOCK)
WHERE InstrumentID = 100
ORDER BY ThresholdType;
```

### 8.3 Find instruments with only one threshold type configured

```sql
SELECT InstrumentID, COUNT(*) AS TypeCount
FROM Price.OMPDThresholdValues WITH (NOLOCK)
GROUP BY InstrumentID
HAVING COUNT(*) = 1
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object specifically. See OMPD runbooks for operational context.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CreateInstrumentOMPDThresholdByInstrumentId | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.CreateInstrumentOMPDThresholdByInstrumentId.sql*
