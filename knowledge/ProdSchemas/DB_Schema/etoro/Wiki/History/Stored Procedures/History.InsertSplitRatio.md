# History.InsertSplitRatio

> Validated writer for stock split events - closes the current active split ratio record for an instrument and inserts the new split, returning the new record ID and calculated price/amount ratios.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID + @MinDate - the instrument and effective date of the new split |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.InsertSplitRatio` is the sole writer for new stock split events in `History.SplitRatio`. When a publicly listed stock instrument undergoes a split (or reverse split), this procedure is called to advance the split ratio time-series: it closes the previously-active ratio record for the instrument (by setting its MaxDate to the new split's effective date) and inserts a new record representing the post-split adjustment ratios.

The procedure accepts the split in natural business terms (`@UnitsBefore` and `@UnitsAfter`) and derives the database-stored `PriceRatio` and `AmountRatio` automatically. For a standard 2:1 forward split (Apple-style), the caller passes `@UnitsBefore=1, @UnitsAfter=2`; the procedure computes `AmountRatio=2` (customers now hold 2x units) and `PriceRatio=0.5` (price halves). This separation enables a clean API for operations teams while maintaining the legacy ratio columns for downstream consumers.

The procedure was modified in 2021 (by Yaniv G.) to accept `UnitsBefore/UnitsAfter` as the primary input instead of the older `PriceRatio/AmountRatio` parameters (which are now commented out). The ratios are now computed internally for backward compatibility with the table's existing consumers.

---

## 2. Business Logic

### 2.1 Split Ratio Time-Series Advancement

**What**: The SplitRatio table maintains a chain of non-overlapping date ranges per instrument. Each split "closes" the current record and opens a new one.

**Columns/Parameters Involved**: `@InstrumentID`, `@MinDate`, `MaxDate`

**Rules**:
- Sentinel value '21000101' (year 2100) marks the currently-active split ratio for each instrument
- Step 1: UPDATE SplitRatio SET MaxDate = @MinDate WHERE MaxDate = '21000101' AND InstrumentID = @InstrumentID (close current record)
- Step 2: Validate exactly 1 row was updated (@@ROWCOUNT <> 1 -> RAISERROR: must find exactly one active record to close)
- Step 3: INSERT new row with MinDate = @MinDate and MaxDate = '21000101' (the new active record)
- If a future record already exists for the instrument (MinDate >= @MinDate): RAISERROR before any writes

### 2.2 Ratio Calculation

**What**: PriceRatio and AmountRatio are derived from the natural split description (UnitsBefore/UnitsAfter).

**Columns/Parameters Involved**: `@UnitsBefore`, `@UnitsAfter`, `@AmountRatio`, `@PriceRatio`

**Rules**:
- `@AmountRatio = @UnitsAfter / @UnitsBefore` - how much the unit count increases/decreases
  - 2:1 forward split: UnitsBefore=1, UnitsAfter=2 -> AmountRatio=2 (positions 2x more units)
  - 1:2 reverse split: UnitsBefore=2, UnitsAfter=1 -> AmountRatio=0.5 (positions halved)
- `@PriceRatio = @UnitsBefore / @UnitsAfter` - inverse: how much the price adjusts
  - 2:1 forward split: PriceRatio=0.5 (price halves)
  - 1:2 reverse split: PriceRatio=2 (price doubles)
- Comment: "-- for backwards compatibility" - PriceRatio/AmountRatio still stored despite being removed from parameters
- All four ratio columns (PriceRatio, AmountRatio, PriceRatioUnAdjusted, AmountRatioUnAdjusted, PriceRatioUnAdjustedFull, AmountRatioUnAdjustedFull) receive the same calculated values

### 2.3 Validation Gate

**What**: Four validation checks run before any writes, preventing invalid split records.

**Columns/Parameters Involved**: `@InstrumentID`, `@UnitsBefore`, `@UnitsAfter`, `@MinDate`

**Rules**:
- Overlap check: IF EXISTS (select * from SplitRatio where InstrumentID = @InstrumentID AND MinDate >= @MinDate) -> RAISERROR "already a record that covers the requested date"
- Null check: @InstrumentID, @UnitsBefore, @UnitsAfter, @MinDate must not be null
- Value check: @UnitsBefore > 0 AND @UnitsAfter > 0 (prevents zero-division and negative ratios)
- Active record check: must find exactly 1 row with MaxDate = '21000101' for the instrument

### 2.4 Conditional Transaction Management

**What**: Only starts a transaction if not already inside one.

**Columns/Parameters Involved**: `@MyTran`

**Rules**:
- IF @@TRANCOUNT = 0 -> SET @MyTran = 1, BEGIN TRAN (own transaction)
- ELSE -> SET @MyTran = 0 (already in a caller's transaction - participate without nesting)
- On error: ROLLBACK only if @MyTran = 1; THROW re-raises the error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | VERIFIED | The stock instrument for which the split is being recorded. Must be a stock (InstrumentID > 1000 per the CK_InstrumentIsStock check constraint on SplitRatio). Must have exactly one active record (MaxDate='21000101') in History.SplitRatio. |
| 2 | @MinDate | DATETIME | NO | - | VERIFIED | The effective date of the split event - when the new ratio takes effect. The current active record's MaxDate is set to this value. Must not be <= any existing MinDate for this instrument (overlap check). |
| 3 | @UnitsBefore | DECIMAL(19,12) | NO | - | VERIFIED | The number of units in the pre-split state. Must be > 0. For a 2:1 forward split: @UnitsBefore=1. Used to compute AmountRatio = @UnitsAfter/@UnitsBefore and PriceRatio = @UnitsBefore/@UnitsAfter. |
| 4 | @UnitsAfter | DECIMAL(19,12) | NO | - | VERIFIED | The number of units in the post-split state. Must be > 0. For a 2:1 forward split: @UnitsAfter=2. For a 1:4 reverse split: @UnitsAfter=1 with @UnitsBefore=4. |

**Output columns** (returned by SELECT):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SplitID | INT | NO | - | VERIFIED | The IDENTITY value of the newly inserted SplitRatio row (@@IDENTITY). Returned so the caller can reference the new record. |
| 2 | PriceRatio | DECIMAL(38,19) | NO | - | VERIFIED | Calculated price adjustment ratio: @UnitsBefore / @UnitsAfter. For a 2:1 split = 0.5 (price halves). Used by the split processing pipeline to adjust historical and current prices. |
| 3 | AmountRatio | DECIMAL(38,19) | NO | - | VERIFIED | Calculated unit/amount adjustment ratio: @UnitsAfter / @UnitsBefore. For a 2:1 split = 2 (customers receive twice as many units). Used to adjust open position unit counts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.SplitRatio | Reads + Writes | SELECT (exists check), UPDATE (close current record), INSERT (new split event) |

### 5.2 Referenced By (other objects point to this)

No callers found in the etoro SSDT repository. Called by the split processing pipeline or operations tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InsertSplitRatio (procedure)
└── History.SplitRatio (table - active primary split ratio store)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | SELECT (existence check) + UPDATE (close current record) + INSERT (new split event) |

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Change history**:
- 2015-05-04 (Adi, FB 25855): Deleted the check that @PriceRatio * @AmountRatio = 1; changed return code to return value of new record
- 2021-11-04 (Yaniv G.): Changed to support full split ratio via UnitsBefore/UnitsAfter inputs (removed @PriceRatio and @AmountRatio parameters, now computed internally)

---

## 8. Sample Queries

### 8.1 Record a 2:1 forward stock split effective 2024-06-01

```sql
EXEC History.InsertSplitRatio
    @InstrumentID = 1234,
    @MinDate = '2024-06-01',
    @UnitsBefore = 1,
    @UnitsAfter = 2
-- Returns: SplitID, PriceRatio=0.5, AmountRatio=2.0
```

### 8.2 Record a 1:4 reverse split (consolidation)

```sql
EXEC History.InsertSplitRatio
    @InstrumentID = 1234,
    @MinDate = '2024-09-15',
    @UnitsBefore = 4,
    @UnitsAfter = 1
-- Returns: SplitID, PriceRatio=4.0, AmountRatio=0.25
```

### 8.3 View the current active split ratio for an instrument

```sql
SELECT InstrumentID, PriceRatio, AmountRatio, UnitsBefore, UnitsAfter, MinDate, MaxDate
FROM History.SplitRatio WITH (NOLOCK)
WHERE InstrumentID = 1234
  AND MaxDate = '21000101'
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Split](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/11761189103/Split) | Confluence | Found via search (updated 2023-12-20) - likely contains documentation on stock split processing workflow |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 1 Confluence found (inaccessible content) + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.InsertSplitRatio | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.InsertSplitRatio.sql*
