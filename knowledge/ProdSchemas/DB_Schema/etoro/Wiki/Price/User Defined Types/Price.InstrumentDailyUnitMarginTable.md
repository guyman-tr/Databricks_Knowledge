# Price.InstrumentDailyUnitMarginTable

> Table-valued parameter (TVP) for bulk upserts of daily unit margin values into Price.InstrumentDailyUnitMargin, carrying one margin snapshot per instrument with its associated price rate and timestamp.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (upsert key in Price.InstrumentDailyUnitMargin) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the input contract for `Price.SetDailyUnitMarginBulk`. It carries the daily unit margin for a batch of instruments - the margin deposit required per traded unit on a given trading day. Unit margin is recalculated daily (or at significant price moves) based on instrument volatility, regulatory requirements, and pricing model parameters.

The daily margin is used to determine how much collateral a client must hold for each open unit of a position. Storing it separately from the live price table (Price.InstrumentDailyUnitMargin vs Trade.CurrencyPrice) allows the margin to be managed on a daily cycle independently from the real-time price feed.

Data flows from the margin calculation engine -> this TVP -> `SetDailyUnitMarginBulk` -> upsert into `Price.InstrumentDailyUnitMargin`. The SP updates existing rows (matched by InstrumentID) and inserts new rows for instruments not yet in the margin table.

---

## 2. Business Logic

### 2.1 Upsert Pattern for Daily Margin Maintenance

**What**: Supports both initial margin setup and daily margin refresh for any number of instruments in a single bulk call.

**Columns/Parameters Involved**: `InstrumentID`, `UnitMargin`, `Occurred`

**Rules**:
- When InstrumentID already exists in Price.InstrumentDailyUnitMargin: UPDATE PriceRateID, UnitMargin, Occurred
- When InstrumentID is new: INSERT a fresh row
- One row per instrument in the TVP (instrument is the natural key for daily margin)

**Diagram**:
```
Margin Calculation Engine (daily/intraday)
  |-- computes UnitMargin per instrument
  |-- packages into InstrumentDailyUnitMarginTable TVP
  v
Price.SetDailyUnitMarginBulk
  |-- UPDATE existing: SET PriceRateID, UnitMargin, Occurred WHERE InstrumentID matches
  |-- INSERT new: for instruments not yet in InstrumentDailyUnitMargin
  v
Price.InstrumentDailyUnitMargin (daily margin store)
  |-- Read by: position opening, margin calls, account equity calculations
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. NOT NULL - upsert key for Price.InstrumentDailyUnitMargin. One row per instrument per bulk call. |
| 2 | PriceRateID | bigint | NOT NULL | - | CODE-BACKED | The price rate ID at the time this margin was calculated. Links the margin snapshot to its source price tick, enabling audit: "this margin was set based on PriceRateID X". NOT NULL - margin must be anchored to a specific price point. |
| 3 | UnitMargin | decimal(12,5) | NOT NULL | - | CODE-BACKED | Required margin deposit per traded unit, in the instrument's denomination currency. NOT NULL - the core data point this TVP exists to deliver. Precision (12,5) supports both large-value and micro-value instruments. |
| 4 | Occurred | datetime | NOT NULL | - | CODE-BACKED | Timestamp when this margin value was calculated/became effective. NOT NULL - provides temporal context for the margin, enabling time-series analysis and debugging of margin changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SetDailyUnitMarginBulk | @RatesToUpdate | TVP Parameter | Bulk-upserts Price.InstrumentDailyUnitMargin with new/updated margin values |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.SetDailyUnitMarginBulk | Stored Procedure | Declares @RatesToUpdate as this type READONLY; upserts Price.InstrumentDailyUnitMargin |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| InstrumentID NOT NULL | NOT NULL | Instrument identification mandatory for margin upsert |
| PriceRateID NOT NULL | NOT NULL | Margin must be anchored to a source price rate |
| UnitMargin NOT NULL | NOT NULL | The margin value itself must always be provided |
| Occurred NOT NULL | NOT NULL | Temporal context required for margin change tracking |

---

## 8. Sample Queries

### 8.1 Bulk-update daily margins for a set of instruments

```sql
DECLARE @Margins Price.InstrumentDailyUnitMarginTable;
INSERT INTO @Margins (InstrumentID, PriceRateID, UnitMargin, Occurred)
VALUES (1, 9999001, 0.00150, GETUTCDATE()),
       (2, 9999002, 0.00200, GETUTCDATE()),
       (10, 9999003, 0.01000, GETUTCDATE());
EXEC Price.SetDailyUnitMarginBulk @RatesToUpdate = @Margins;
```

### 8.2 Check current daily margins

```sql
SELECT TOP 20
    InstrumentID, PriceRateID, UnitMargin, Occurred
FROM Price.InstrumentDailyUnitMargin WITH (NOLOCK)
ORDER BY Occurred DESC;
```

### 8.3 Find instruments with high unit margin (risky/volatile)

```sql
SELECT TOP 10
    InstrumentID, UnitMargin, Occurred
FROM Price.InstrumentDailyUnitMargin WITH (NOLOCK)
ORDER BY UnitMargin DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentDailyUnitMarginTable | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.InstrumentDailyUnitMarginTable.sql*
