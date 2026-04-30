# History.SplitClosePositions

> Stock split adjustment processor for closed positions - reads split parameters (PriceRatio, AmountRatio) from History.SplitRatio and retroactively adjusts 10 rate/unit columns in History.Position for all unprocessed positions in the split instrument, recording each completed adjustment in History.PositionSplit via OUTPUT clause for idempotency.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID - identifies which stock split event to process |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.SplitClosePositions` is the stock split retroactive adjustment processor for closed positions. When a publicly traded company performs a stock split (e.g., 2-for-1 or 4-for-1), every closed position in `History.Position` for that instrument must be updated so historical position data remains economically accurate: rates (InitForexRate, LimitRate, StopRate, EndForexRate, etc.) are multiplied by PriceRatio (typically < 1 for splits), and unit counts (AmountInUnitsDecimal, LotCountDecimal) are multiplied by AmountRatio (typically > 1 for splits).

The procedure reads the split parameters from `History.SplitRatio` and processes all eligible closed positions in batches of 2000. Eligibility requires:
- The position's instrument matches the split instrument
- The instrument is a stock (InstrumentTypeID=5)
- The position was opened before the split date (@MinDate)
- The position has NOT already been adjusted for this split (not in History.PositionSplit for this SplitID)

Each UPDATE to History.Position simultaneously inserts an audit record into `History.PositionSplit` via the OUTPUT clause (atomic idempotency marker). After all positions are processed, `History.SplitRatio.IsCompletedClosePositions` is set to 1 to prevent re-running.

History note: Modified 2015-01-07 (FB 24690) to change stock position detection method; rounding added 2015-03-01; LotCountDecimal rounding precision changed 2015-12-14; PositionID to BIGINT 2021-11-17.

---

## 2. Business Logic

### 2.1 Split Eligibility Filter

**What**: Only unprocessed, pre-split, stock positions for the target instrument are included.

**Columns/Parameters Involved**: `History.Position.InstrumentID`, `Trade.GetInstrument.InstrumentTypeID`, `History.PositionSplit`, `History.SplitRatio.MinDate`

**Rules**:
- InstrumentID = @InstrumentID (from SplitRatio for this SplitID)
- InstrumentTypeID = 5 (Stocks - from Trade.GetInstrument JOIN)
- InitDateTime < @MinDate (position opened before the split date)
- LEFT JOIN History.PositionSplit WHERE SplitID=@SplitID AND PositionID IS NULL (not already processed)
- OPTION(RECOMPILE) on the eligibility SELECT to prevent parameter sniffing

### 2.2 Rate and Unit Adjustments

**What**: 10 columns in History.Position are updated with split-ratio multiplied values.

**Columns/Parameters Involved**: `AmountInUnitsDecimal`, `LotCountDecimal`, 8 rate columns

**Rules**:
- Unit adjustments (AmountRatio, e.g., 2.0 for 2:1 split = doubles units):
  - AmountInUnitsDecimal = MAX(AmountInUnitsDecimal * AmountRatio, 0.000001) - minimum 0.000001 prevents zero
  - LotCountDecimal = MAX(AmountInUnitsDecimal * AmountRatio, 0.000001) - NOTE: uses AmountInUnitsDecimal (not LotCountDecimal) as base; both fields set to same value
- Rate adjustments (PriceRatio, e.g., 0.5 for 2:1 split = halves prices), all ROUND to @Precision:
  - InitForexRate = ROUND(InitForexRate * PriceRatio, @Precision)
  - LimitRate = ROUND(LimitRate * PriceRatio, @Precision)
  - StopRate = ROUND(StopRate * PriceRatio, @Precision)
  - SpreadedPipBid = ROUND(SpreadedPipBid * PriceRatio, @Precision)
  - SpreadedPipAsk = ROUND(SpreadedPipAsk * PriceRatio, @Precision)
  - OrderPriceRate = ROUND(OrderPriceRate * PriceRatio, @Precision)
  - MarketPriceRate = ROUND(MarketPriceRate * PriceRatio, @Precision)
  - LastOpPriceRate = ROUND(LastOpPriceRate * PriceRatio, @Precision)
  - EndForexRate = ROUND(EndForexRate * PriceRatio, @Precision)
- @Precision: from Trade.ProviderToInstrument.Precision for the instrument (controls decimal places)

**Example (2:1 stock split)**:
```
Before:  Amount=10000 units, InitForexRate=200.00
After:   Amount=20000 units, InitForexRate=100.00
PriceRatio=0.5, AmountRatio=2.0, Precision=2
```

### 2.3 Batch Processing Pattern (2000-row chunks)

**What**: Processes eligible positions in chunks of 2000 to avoid long-running transactions.

**Rules**:
- WHILE loop: continues while any Status=0 rows remain in #Positions
- UPDATE TOP(2000) #Positions SET Status=1 (mark current batch)
- UPDATE TOP(2000) History.Position with OUTPUT -> History.PositionSplit
- DELETE #Positions WHERE Status=1 (remove processed rows)
- Each iteration handles exactly 2000 rows

### 2.4 Atomic Idempotency via OUTPUT Clause

**What**: History.PositionSplit is populated atomically in the same statement as the History.Position UPDATE.

**Rules**:
- `OUTPUT DELETED.PositionID, @SplitID, GETUTCDATE() INTO History.PositionSplit (PositionID, SplitID, SplitDate)`
- This guarantees: if the UPDATE succeeds, the audit record is inserted; if UPDATE fails, no audit record
- Prevents double-processing on restart: eligibility filter excludes PositionIDs already in PositionSplit for this SplitID
- IsCompletedClosePositions=1 on SplitRatio provides a high-level guard (checked at the start)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | INT | NO | - | CODE-BACKED | ID of the stock split event in History.SplitRatio. Identifies which split to process: loads InstrumentID, PriceRatioUnAdjusted, AmountRatioUnAdjusted, MinDate, and IsCompletedClosePositions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SplitID | History.SplitRatio | READ + UPDATE | Reads split parameters (InstrumentID, ratios, MinDate) and marks IsCompletedClosePositions=1 when done |
| InstrumentID, InitDateTime | History.Position | UPDATE (batch) | Updates 10 rate/unit columns for all eligible closed positions |
| PositionID, SplitID | History.PositionSplit | INSERT (via OUTPUT) | Atomically records processed positions as idempotency markers |
| InstrumentID | Trade.GetInstrument | INNER JOIN | Reads InstrumentTypeID to filter to stocks only (InstrumentTypeID=5) |
| InstrumentID | Trade.ProviderToInstrument | READ | Reads Precision for rate rounding |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called by DBA/ops tooling for split event processing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SplitClosePositions (procedure)
+-- History.SplitRatio (table)
+-- History.Position (table - UPDATE target)
+-- History.PositionSplit (table - OUTPUT target)
+-- Trade.GetInstrument (table/view, cross-schema)
+-- Trade.ProviderToInstrument (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | Source of split parameters (InstrumentID, PriceRatioUnAdjusted, AmountRatioUnAdjusted, MinDate, IsCompletedClosePositions); marked complete after processing |
| History.Position | Table | UPDATE target for split-adjusted rate and unit columns |
| History.PositionSplit | Table | INSERT target for processed-position audit records via OUTPUT clause |
| Trade.GetInstrument | Table/View (cross-schema) | INNER JOIN to filter to stock positions (InstrumentTypeID=5) |
| Trade.ProviderToInstrument | Table (cross-schema) | SELECT Precision for rate rounding |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsCompletedClosePositions guard | Idempotency | RAISERROR if SplitRatio.IsCompletedClosePositions=1 - prevents double-processing |
| History.PositionSplit NULL check | Idempotency | Per-position guard via LEFT JOIN + IS NULL - prevents single positions from being adjusted twice |
| InstrumentTypeID=5 filter | Business rule | Only stocks require split adjustment; other instrument types are excluded |
| InitDateTime < @MinDate | Business rule | Only positions opened before the split date are adjusted |
| AmountInUnitsDecimal minimum 0.000001 | Safety | Prevents zero/negative unit counts after multiplication |
| LotCountDecimal = AmountInUnitsDecimal * AmountRatio | Implementation note | LotCountDecimal is derived from AmountInUnitsDecimal (not its own prior value) - both fields hold the same post-split value |
| OUTPUT -> PositionSplit | Atomicity | Idempotency record is inserted in the same statement as the position update |
| Batch size 2000 | Performance | Limits transaction size; reduces lock contention on large split events |
| OPTION(RECOMPILE) | Performance | On the eligibility SELECT to prevent parameter sniffing for different SplitIDs |
| THROW on error | Error handling | Exceptions re-raise to caller; RETURN(-1) after THROW is unreachable |

---

## 8. Sample Queries

### 8.1 Check split parameters before running

```sql
SELECT ID, InstrumentID, PriceRatioUnAdjusted, AmountRatioUnAdjusted,
       MinDate, IsCompletedClosePositions
FROM History.SplitRatio WITH (NOLOCK)
WHERE ID = 37  -- example SplitID
```

### 8.2 Count eligible positions before processing

```sql
DECLARE @SplitID INT = 37
DECLARE @InstrumentID INT = (SELECT InstrumentID FROM History.SplitRatio WHERE ID = @SplitID)
DECLARE @MinDate DATETIME = (SELECT MinDate FROM History.SplitRatio WHERE ID = @SplitID)

SELECT COUNT(*) AS EligiblePositions
FROM History.Position HPOS WITH (NOLOCK)
LEFT JOIN History.PositionSplit HPS ON HPOS.PositionID = HPS.PositionID AND HPS.SplitID = @SplitID
WHERE HPOS.InstrumentID = @InstrumentID
  AND HPOS.InitDateTime < @MinDate
  AND HPS.PositionID IS NULL
```

### 8.3 Verify split completion

```sql
SELECT COUNT(*) AS ProcessedPositions, MIN(SplitDate) AS FirstProcessed, MAX(SplitDate) AS LastProcessed
FROM History.PositionSplit WITH (NOLOCK)
WHERE SplitID = 37
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SplitClosePositions | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.SplitClosePositions.sql*
