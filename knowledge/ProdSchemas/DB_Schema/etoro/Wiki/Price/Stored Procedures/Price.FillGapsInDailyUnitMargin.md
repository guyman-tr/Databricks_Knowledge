# Price.FillGapsInDailyUnitMargin

> Gap-filling procedure that inserts rows into Price.InstrumentDailyUnitMargin for any instruments present in Trade.CurrencyPrice that do not yet have a unit margin record - initializes missing instruments with their current price data.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - operates on full gap set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.FillGapsInDailyUnitMargin is a bootstrap/recovery procedure for the daily unit margin system. It inserts a seed row into Price.InstrumentDailyUnitMargin for every instrument in Trade.CurrencyPrice that does not already have a margin record. The seeded row uses the instrument's current PriceRateID, UnitMargin, and Occurred values directly from CurrencyPrice.

The standard write path to InstrumentDailyUnitMargin is Price.SetDailyUnitMarginBulk, which bulk-upserts pre-calculated margin values. FillGapsInDailyUnitMargin handles the edge case where an instrument exists in CurrencyPrice (has a live price) but has no entry in InstrumentDailyUnitMargin at all - this can happen when a new instrument starts trading before the margin calculation engine has processed it. Running this procedure seeds those instruments so the margin system has a starting value.

The OUTPUT clause streams all inserted rows back to the caller, allowing real-time visibility into which instruments were seeded.

---

## 2. Business Logic

### 2.1 Anti-Join Gap Detection Pattern

**What**: A LEFT JOIN to InstrumentDailyUnitMargin with WHERE IDUM.InstrumentID IS NULL identifies instruments in CurrencyPrice that have no margin record (the classic SQL anti-join / NOT EXISTS pattern).

**Columns/Parameters Involved**: `InstrumentID`, `PriceRateID`, `UnitMargin`, `Occurred`

**Rules**:
- Source: Trade.CurrencyPrice (all instruments with live price data)
- Anti-join: LEFT JOIN Price.InstrumentDailyUnitMargin ON CP.InstrumentID = IDUM.InstrumentID
- Filter: WHERE IDUM.InstrumentID IS NULL -> keeps only instruments NOT in InstrumentDailyUnitMargin
- Insert: seeds the gap instrument with its CurrencyPrice values (PriceRateID, UnitMargin, Occurred)
- This is an initialization operation - subsequent updates happen via SetDailyUnitMarginBulk
- Idempotent for any already-seeded instrument: they are excluded by the anti-join condition

### 2.2 INSERT...OUTPUT - Streaming Inserted Rows

**What**: The OUTPUT clause returns all inserted rows immediately as a result set, allowing callers to see which instruments were seeded.

**Columns/Parameters Involved**: `InstrumentID`, `PriceRateID`, `UnitMargin`, `Occurred`

**Rules**:
- OUTPUT INSERTED.InstrumentID, INSERTED.PriceRateID, INSERTED.UnitMargin, INSERTED.Occurred
- Returns one row per inserted instrument - callers can log or process the gap-filled list
- If no gaps exist: INSERT inserts 0 rows, OUTPUT returns empty result set

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No input parameters. Gap detection is fully automated via the anti-join between Trade.CurrencyPrice and Price.InstrumentDailyUnitMargin. |

**Output result set (via OUTPUT clause):**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 1 | InstrumentID | int | NO | CODE-BACKED | Instrument ID that was gap-filled (newly seeded into InstrumentDailyUnitMargin). |
| 2 | PriceRateID | - | - | CODE-BACKED | Price rate identifier from Trade.CurrencyPrice used as the seed value for this instrument. |
| 3 | UnitMargin | - | - | CODE-BACKED | Unit margin value from Trade.CurrencyPrice used as the initial margin for this instrument. |
| 4 | Occurred | - | - | CODE-BACKED | Timestamp from Trade.CurrencyPrice indicating when this price/margin was originally computed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID + PriceRateID + UnitMargin + Occurred | Trade.CurrencyPrice | READ source | All gap-fill seed values come from CurrencyPrice |
| InstrumentID | Price.InstrumentDailyUnitMargin | LEFT JOIN (anti-join) + INSERT | Anti-join detects gaps; INSERT fills them |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no SQL callers found within the Price schema (called by external margin management tooling or scheduled jobs).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.FillGapsInDailyUnitMargin (procedure)
├── Trade.CurrencyPrice (table) - source of instrument price and margin data
└── Price.InstrumentDailyUnitMargin (table) - gap detection + INSERT target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | SELECT source - provides seed values (PriceRateID, UnitMargin, Occurred) for gap-fill |
| Price.InstrumentDailyUnitMargin | Table | LEFT JOIN anti-join (gap detection) + INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found in Price schema | - | Called by external margin management tooling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No explicit transaction - single INSERT statement is atomic. Trade.CurrencyPrice is queried WITH (NOLOCK) to avoid blocking; InstrumentDailyUnitMargin anti-join also uses WITH (NOLOCK). INSERT uses the PK on InstrumentID in InstrumentDailyUnitMargin - if called concurrently, duplicate key violations are possible but unlikely since the procedure is a gap-filler.

---

## 8. Sample Queries

### 8.1 Run the gap-fill procedure and capture inserted rows

```sql
EXEC Price.FillGapsInDailyUnitMargin;
-- Returns result set of all newly-inserted InstrumentID, PriceRateID, UnitMargin, Occurred rows
```

### 8.2 Preview which instruments would be gap-filled (dry-run)

```sql
SELECT CP.InstrumentID, CP.PriceRateID, CP.UnitMargin, CP.Occurred
FROM Trade.CurrencyPrice CP WITH (NOLOCK)
LEFT JOIN Price.InstrumentDailyUnitMargin IDUM WITH (NOLOCK)
    ON CP.InstrumentID = IDUM.InstrumentID
WHERE IDUM.InstrumentID IS NULL
ORDER BY CP.InstrumentID;
```

### 8.3 Compare instrument coverage between CurrencyPrice and InstrumentDailyUnitMargin

```sql
SELECT
    (SELECT COUNT(DISTINCT InstrumentID) FROM Trade.CurrencyPrice WITH (NOLOCK)) AS CurrencyPriceCount,
    (SELECT COUNT(*) FROM Price.InstrumentDailyUnitMargin WITH (NOLOCK)) AS UnitMarginCount;
-- If CurrencyPriceCount > UnitMarginCount, FillGapsInDailyUnitMargin would insert rows
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.FillGapsInDailyUnitMargin | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.FillGapsInDailyUnitMargin.sql*
