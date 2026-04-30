# Price.SetDailyUnitMarginBulk

> Bulk UPSERT for Price.InstrumentDailyUnitMargin: updates existing rows with new PriceRateID, UnitMargin, and Occurred; inserts new rows for instruments not yet present. The primary write path for the margin calculation engine's daily/periodic unit margin updates.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RatesToUpdate (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.SetDailyUnitMarginBulk is the bulk write procedure for the margin calculation engine. When the pricing infrastructure recalculates unit margin values (periodically or on significant price moves), it packages all updated values into a `Price.InstrumentDailyUnitMarginTable` TVP and calls this procedure to persist them in bulk.

The procedure performs a standard UPSERT:
- **UPDATE**: for instruments already in `Price.InstrumentDailyUnitMargin`, update PriceRateID (the price tick that anchored the margin calculation), UnitMargin (the new required margin per unit), and Occurred (when this margin was calculated)
- **INSERT**: for instruments appearing in the TVP for the first time (new instrument onboarding), insert a fresh row

With 10,507 rows of current data (updated 2026-03-18 at ~13:21-13:22 UTC), this table is actively maintained. Values range from ~0.26 (small denomination instruments) to ~357 (e.g., BTC), reflecting the margin deposit required per unit of each instrument.

Notable difference from the CurrencyPrice bulk update procedures: no `@ProviderID` parameter (InstrumentDailyUnitMargin has no ProviderID column - margin is a derived calculation, not provider-sourced), and no temp table (the TVP is joined directly - simpler for the 3-column update that doesn't benefit from temp table indexing at this scale).

---

## 2. Business Logic

### 2.1 UPDATE Existing Rows (Direct TVP Join)

**What**: Updates existing InstrumentDailyUnitMargin rows by joining directly to the TVP (no temp table).

**Columns/Parameters Involved**: `PriceRateID`, `UnitMargin`, `Occurred`

**Rules**:
- `FROM Price.InstrumentDailyUnitMargin IDUM WITH(NOLOCK) JOIN @RatesToUpdate RTU ON IDUM.InstrumentID = RTU.InstrumentID`
- `SET PriceRateID = RTU.PriceRateID`: records which CurrencyPrice tick was used for the margin calculation
- `SET UnitMargin = RTU.UnitMargin`: the new margin rate (deposit per unit traded, in instrument denomination currency)
- `SET Occurred = RTU.Occurred`: when the margin was calculated (not when this procedure was called)
- No PriceRateID change guard - every instrument in the TVP is updated unconditionally
- WITH(NOLOCK) on IDUM is safe since the UPDATE will acquire appropriate locks

### 2.2 INSERT New Rows

**What**: Inserts rows for instruments in the TVP that do not yet exist in InstrumentDailyUnitMargin.

**Columns/Parameters Involved**: `InstrumentID`

**Rules**:
- `FROM @RatesToUpdate RTU LEFT JOIN Price.InstrumentDailyUnitMargin IDUM ON IDUM.InstrumentID = RTU.InstrumentID WHERE IDUM.InstrumentID IS NULL`
- Standard LEFT JOIN / IS NULL anti-join pattern for identifying new instruments
- INSERT columns: InstrumentID, PriceRateID, UnitMargin, Occurred (all from TVP)
- Note: the UPDATE runs first; a race condition between the UPDATE and INSERT paths for the same InstrumentID is not guarded against, but in practice the margin engine calls this procedure as a single batch

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RatesToUpdate | Price.InstrumentDailyUnitMarginTable READONLY | NOT NULL | - | CODE-BACKED | TVP of margin calculations to upsert. Type: Price.InstrumentDailyUnitMarginTable (4 columns: InstrumentID INT, PriceRateID BIGINT, UnitMargin DECIMAL, Occurred DATETIME). One row per instrument. The margin engine populates this with the complete set of recalculated margins and passes it as a single batch. |

**Result set**: None.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RatesToUpdate | Price.InstrumentDailyUnitMarginTable | TVP type | Input margin calculation batch |
| InstrumentID | Price.InstrumentDailyUnitMargin | WRITER (UPSERT) | UPDATE existing + INSERT new margin rows |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (margin calculation engine) | @RatesToUpdate | CALLER | Called after each margin recalculation cycle to persist all updated margin values |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SetDailyUnitMarginBulk (procedure)
+-- Price.InstrumentDailyUnitMarginTable (UDT) - TVP type
+-- Price.InstrumentDailyUnitMargin (table) - UPSERT target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentDailyUnitMarginTable | User Defined Type | TVP parameter type |
| Price.InstrumentDailyUnitMargin | Table | UPSERT target - UPDATE existing + INSERT new margin values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (margin calculation engine) | External | Calls to bulk-persist recalculated unit margin values for all instruments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON. No explicit transaction (UPDATE and INSERT are separate implicit transactions). No temp table - joins TVP directly (appropriate for the small 3-column update; the CurrencyPrice variants use temp tables because their TVPs have 15-20 columns and benefit from indexed access). No @ProviderID parameter (InstrumentDailyUnitMargin has no ProviderID - margin is a derived calculation, not a feed-specific value). No PriceRateID change guard. The UnitMargin values in this table are consumed by: position opening checks (available equity vs. required margin), margin call calculations, and account equity computations.

---

## 8. Sample Queries

### 8.1 Bulk update unit margins

```sql
DECLARE @Margins Price.InstrumentDailyUnitMarginTable;
INSERT INTO @Margins (InstrumentID, PriceRateID, UnitMargin, Occurred)
VALUES (1, 987654, 0.05430, GETUTCDATE()),
       (2, 987655, 0.04210, GETUTCDATE());

EXEC Price.SetDailyUnitMarginBulk @RatesToUpdate = @Margins;
```

### 8.2 Check current unit margins for key instruments

```sql
SELECT InstrumentID, UnitMargin, PriceRateID, Occurred
FROM Price.InstrumentDailyUnitMargin WITH (NOLOCK)
ORDER BY UnitMargin DESC;
-- Currently: 10,507 rows, UnitMargin range ~0.26 to ~357
```

### 8.3 Equivalent manual upsert

```sql
-- Update existing
UPDATE IDUM
SET PriceRateID = 987654, UnitMargin = 0.05430, Occurred = GETUTCDATE()
FROM Price.InstrumentDailyUnitMargin IDUM
WHERE IDUM.InstrumentID = 1;

-- Insert new
INSERT INTO Price.InstrumentDailyUnitMargin (InstrumentID, PriceRateID, UnitMargin, Occurred)
SELECT 99999, 987999, 1.23456, GETUTCDATE()
WHERE NOT EXISTS (
    SELECT 1 FROM Price.InstrumentDailyUnitMargin WHERE InstrumentID = 99999
);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SetDailyUnitMarginBulk | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.SetDailyUnitMarginBulk.sql*
