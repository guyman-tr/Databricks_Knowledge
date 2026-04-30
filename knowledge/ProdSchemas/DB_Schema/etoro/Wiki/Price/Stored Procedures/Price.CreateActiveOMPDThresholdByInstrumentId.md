# Price.CreateActiveOMPDThresholdByInstrumentId

> Validated INSERT procedure that creates a new active OMPD threshold type designation for an instrument in Price.OMPDActiveThreshold - enforces three pre-conditions before inserting.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID (new active threshold record) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.CreateActiveOMPDThresholdByInstrumentId sets up the active OMPD (Order Management Price Deviation) threshold type for a new instrument. OMPD is a price protection mechanism that rejects orders when the market price has deviated beyond a configured threshold from the price at order creation. This procedure designates which threshold type (Pips=1 or Percentage=2) is the active enforcement mode for the given instrument.

The procedure targets Price.OMPDActiveThreshold, which is the selector table - it declares that "instrument X should use threshold type Y as its OMPD enforcement mode." The actual numeric threshold value (how many pips or what percentage) is stored separately in Price.OMPDThresholdValues. This procedure requires the threshold value record to already exist before creating the active designation, ensuring a new active threshold always has a backing value row.

Called when onboarding a new instrument into the OMPD protection system or when re-enabling OMPD for an instrument that had its active threshold deleted.

---

## 2. Business Logic

### 2.1 Three-Guard Validation Before Insert

**What**: The procedure enforces three sequential validation checks before allowing the INSERT. Any failure raises a RAISERROR and returns without inserting.

**Columns/Parameters Involved**: `@InstrumentID`, `@ThresholdType`

**Rules**:

Guard 1 - ThresholdType must be valid:
- EXISTS check: Dictionary.OMPDThresholdType WHERE ThresholdTypeID = @ThresholdType
- Ensures caller passes a known threshold type (1=Pips, 2=Percentage)
- Error: "Invalid. ThresholdType must exist in the Dictionary.OMPDThresholdType table."

Guard 2 - Threshold value must already exist for this instrument+type:
- EXISTS check: Price.OMPDThresholdValues WHERE InstrumentID = @InstrumentID AND ThresholdType = @ThresholdType
- Ensures the active designation has a backing value row in OMPDThresholdValues
- Error: "Invalid. The combination of InstrumentID and ThresholdType does not exist in the Price.OMPDThresholdValues table."
- **Dependency**: Price.CreateInstrumentOMPDThresholdByInstrumentId must be called first to create the value row

Guard 3 - Instrument must not already have an active threshold:
- EXISTS check: Price.OMPDActiveThreshold WHERE InstrumentID = @InstrumentID
- Prevents duplicate active threshold designations (PK on InstrumentID would also catch this, but the guard provides a descriptive error)
- Error: "Invalid. The InstrumentID already has an active threshold type."
- To change an existing active type: use Price.UpdateActiveOMPDThresholdByInstrumentId instead

**Setup order**:
```
1. Price.CreateInstrumentOMPDThresholdByInstrumentId  (creates value row in OMPDThresholdValues)
2. Price.CreateActiveOMPDThresholdByInstrumentId       (creates active selector in OMPDActiveThreshold)
```

### 2.2 Success Response

**What**: On successful INSERT, the procedure returns the inserted values as a confirmation result set.

**Columns/Parameters Involved**: `@InstrumentID`, `@ThresholdType`

**Rules**:
- Returns SELECT @InstrumentID AS InstrumentId, @ThresholdType AS ThresholdType
- Single-row confirmation result set - allows callers to verify the inserted values
- No OUTPUT parameters; result delivered as a result set

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | IN | - | CODE-BACKED | The instrument to create an active threshold designation for. Must have a matching row in Price.OMPDThresholdValues for the given @ThresholdType. Must NOT already exist in Price.OMPDActiveThreshold (use UpdateActiveOMPDThresholdByInstrumentId to change existing). |
| 2 | @ThresholdType | INT | IN | - | CODE-BACKED | The OMPD threshold type to designate as active: 1=Pips (absolute deviation in pips), 2=Percentage (percentage deviation). Must exist in Dictionary.OMPDThresholdType. The combination (@InstrumentID, @ThresholdType) must already exist in Price.OMPDThresholdValues. |

**Output result set (on success):**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 1 | InstrumentId | INT | NO | CODE-BACKED | Echo of @InstrumentID - confirms the instrument for which the active threshold was created. |
| 2 | ThresholdType | INT | NO | CODE-BACKED | Echo of @ThresholdType - confirms the threshold type that was activated (1=Pips, 2=Percentage). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ThresholdType | Dictionary.OMPDThresholdType | VALIDATION READ | Guard 1: validates ThresholdType exists |
| @InstrumentID + @ThresholdType | Price.OMPDThresholdValues | VALIDATION READ | Guard 2: validates value row exists before creating active designation |
| @InstrumentID | Price.OMPDActiveThreshold | VALIDATION READ + INSERT | Guard 3: checks no existing active threshold; then INSERTs new row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no SQL callers found within the Price schema (called by external pricing management API).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.CreateActiveOMPDThresholdByInstrumentId (procedure)
├── Dictionary.OMPDThresholdType (table) - validation
├── Price.OMPDThresholdValues (table) - prerequisite check
└── Price.OMPDActiveThreshold (table) - INSERT target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OMPDThresholdType | Table | EXISTS check - Guard 1 ThresholdType validation |
| Price.OMPDThresholdValues | Table | EXISTS check - Guard 2 prerequisite value existence |
| Price.OMPDActiveThreshold | Table | EXISTS check (Guard 3) + INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found in Price schema | - | Called by external pricing management API |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Uses three IF NOT EXISTS / IF EXISTS guards with RAISERROR (severity 16, state 1) and RETURN on failure. No explicit transaction wrapping the INSERT. Guards use `SELECT top 1 1` - efficient existence pattern. Note: CREATE procedure uses `CREATE PROCEDURE` with schema prefix, consistent with Price schema conventions.

---

## 8. Sample Queries

### 8.1 Full setup sequence: create value then create active designation

```sql
-- Step 1: Create the threshold value record (Pips type, value=40)
EXEC Price.CreateInstrumentOMPDThresholdByInstrumentId
    @InstrumentID = 1,
    @ThresholdType = 1,
    @Value = 40.00;

-- Step 2: Activate the Pips threshold type for this instrument
EXEC Price.CreateActiveOMPDThresholdByInstrumentId
    @InstrumentID = 1,
    @ThresholdType = 1;
```

### 8.2 Verify active threshold was created

```sql
SELECT AT.InstrumentID, AT.ThresholdType,
       OTV.Value AS ThresholdValue,
       CASE AT.ThresholdType WHEN 1 THEN 'Pips' WHEN 2 THEN 'Percentage' END AS TypeLabel
FROM Price.OMPDActiveThreshold AT WITH (NOLOCK)
JOIN Price.OMPDThresholdValues OTV WITH (NOLOCK)
    ON OTV.InstrumentID = AT.InstrumentID AND OTV.ThresholdType = AT.ThresholdType
WHERE AT.InstrumentID = 1;
```

### 8.3 Find instruments with no active OMPD threshold

```sql
SELECT TI.InstrumentID
FROM Trade.Instrument TI WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Price.OMPDActiveThreshold WITH (NOLOCK)
    WHERE InstrumentID = TI.InstrumentID
)
ORDER BY TI.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object specifically. See OMPD runbooks for operational context.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CreateActiveOMPDThresholdByInstrumentId | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.CreateActiveOMPDThresholdByInstrumentId.sql*
