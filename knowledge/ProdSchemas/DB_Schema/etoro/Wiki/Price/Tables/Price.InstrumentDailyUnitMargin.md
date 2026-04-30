# Price.InstrumentDailyUnitMargin

> Live store of the current daily margin deposit required per traded unit for each instrument - one row per instrument holding the most recently calculated UnitMargin value, the price rate it was anchored to, and when it was computed. Updated in bulk by Price.SetDailyUnitMarginBulk via the InstrumentDailyUnitMarginTable TVP.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK, FK to Trade.Instrument) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR=95) |

---

## 1. Business Meaning

Price.InstrumentDailyUnitMargin is the live margin rate table for eToro's position management system. Each row stores the current required margin deposit per traded unit for one instrument - the collateral a client must maintain for each unit of an open position.

Unit margin is recalculated periodically (at minimum once per day, possibly more frequently on volatile instruments) by the margin calculation engine. The calculation considers current instrument prices, volatility, leverage limits, and regulatory requirements. When the engine computes new values, it calls `Price.SetDailyUnitMarginBulk` which upserts rows in bulk using the `Price.InstrumentDailyUnitMarginTable` TVP.

With 10,507 rows and recent timestamps (2026-03-18 13:21-13:22), this table is actively updated and contains fresh margin data for all active instruments. UnitMargin values range widely:
- 0.25783 (e.g., for crypto/low-priced instruments in smaller denomination)
- 179.11 (e.g., for high-value stocks)
- 356.97 (e.g., for very high-priced instruments like BTC)

Data lifecycle: initially inserted when a new instrument goes live; subsequently upserted on every margin recalculation cycle. The PriceRateID provides an audit trail linking each margin value to the specific price tick that was used to calculate it.

---

## 2. Business Logic

### 2.1 Daily Margin Calculation Cycle

**What**: The margin engine recalculates unit margin based on current prices and deposits results via bulk upsert.

**Columns/Parameters Involved**: `InstrumentID`, `PriceRateID`, `UnitMargin`, `Occurred`

**Rules**:
- UnitMargin = margin deposit required per 1 unit of the instrument (in instrument denomination currency)
- Higher instrument price -> typically higher UnitMargin (margin is proportional to notional value)
- PriceRateID links to the Trade.CurrencyPrice row that was the basis for this calculation - enables audit: "what price was used to calculate this margin?"
- Occurred = timestamp when this UnitMargin was calculated (not inserted - may differ from DB insert time)
- When instrument already exists in table: UPDATE PriceRateID, UnitMargin, Occurred
- When instrument is new: INSERT a fresh row

**Diagram**:
```
Margin Calculation Engine (periodic or price-triggered):
  1. For each active instrument:
     - Read current price from Trade.CurrencyPrice (-> PriceRateID)
     - Compute UnitMargin = f(price, leverage, volatility, regulatory_factor)
  2. Package into InstrumentDailyUnitMarginTable TVP
  3. EXEC Price.SetDailyUnitMarginBulk -> UPSERT Price.InstrumentDailyUnitMargin

Consumers:
  - Position opening: check UnitMargin * units <= available_equity
  - Margin call logic: recalculate required margin for open positions
  - Account equity calculations: sum(UnitMargin * units) per account
```

### 2.2 Margin Anchoring to Price Rate

**What**: PriceRateID creates a traceable link between the margin value and the price that produced it.

**Rules**:
- PriceRateID references Trade.CurrencyPrice (or equivalent price store) by its rate ID
- bigint PriceRateID accommodates very large IDs (Trade.CurrencyPrice is a high-volume table with IDENTITY PKs reaching billions)
- When a margin value seems incorrect, PriceRateID lets operations find the source price tick

---

## 3. Data Overview

| Note | Value |
|------|-------|
| Row count | 10,507 (one per active instrument) |
| Last updated | 2026-03-18 13:22 UTC (actively refreshed) |
| UnitMargin range | ~0.25 (small/crypto units) to ~357 (high-priced instruments) |

| InstrumentID | PriceRateID | UnitMargin | Occurred |
|---|---|---|---|
| 100041 | 46,806,980,182 | 10.3881 | 2026-03-18 13:22 |
| 8852 | 46,806,940,084 | 179.1119 | 2026-03-18 13:21 |
| 100043 | 46,806,988,742 | 0.25783 | 2026-03-18 13:21 |
| 100270 | 46,806,988,593 | 1.9811 | 2026-03-18 13:21 |
| 100271 | 46,806,988,574 | 356.96827 | 2026-03-18 13:21 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. CLUSTERED PK (one row per instrument - this is a "current state" table, not a time series). FK to Trade.Instrument. |
| 2 | PriceRateID | bigint | NOT NULL | - | CODE-BACKED | The price rate ID (from Trade.CurrencyPrice or equivalent) that was current when this UnitMargin was calculated. bigint accommodates the very large identity values seen in live data (e.g., 46,806,988,742). Provides audit traceability: "which price tick produced this margin?" |
| 3 | UnitMargin | decimal(12,5) | NOT NULL | - | CODE-BACKED | Required margin deposit per 1 traded unit, in the instrument's denomination currency. Ranges from fractional values (crypto micro-units) to hundreds (high-priced equities). Used by position opening to check if client has sufficient equity: OpenMargin = UnitMargin * units_requested. |
| 4 | Occurred | datetime | NOT NULL | - | CODE-BACKED | Timestamp when this margin was calculated by the margin engine. Not the DB insert/update time - represents when the calculation was performed, which may precede the DB write. Used for staleness detection: if Occurred is very old, margin may need refresh. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_InstrumentDailyUnitMargin_InstrumentID) | Margin is per instrument; FK enforces instrument existence |
| PriceRateID | Trade.CurrencyPrice (implied) | Implicit | Links margin snapshot to the price tick used for calculation; no FK enforced |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SetDailyUnitMarginBulk | Price.InstrumentDailyUnitMargin | UPSERT WRITER | Bulk-upserts margin values via InstrumentDailyUnitMarginTable TVP |
| Price.FillGapsInDailyUnitMargin | Price.InstrumentDailyUnitMargin | WRITER | Fills in missing margin rows for instruments without current values |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InstrumentDailyUnitMargin (table)
  |-- FK -> Trade.Instrument
  ^-- Written by: Price.SetDailyUnitMarginBulk (bulk upsert via TVP)
  ^-- Written by: Price.FillGapsInDailyUnitMargin (gap-fill)
  ^-- Read by: position opening logic (application code)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK - instrument must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.SetDailyUnitMarginBulk | Stored Procedure | Bulk-upserts margin values; primary writer |
| Price.FillGapsInDailyUnitMargin | Stored Procedure | Inserts margin rows for instruments missing entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InstrumentDailyUnitMargin | CLUSTERED PK | InstrumentID ASC | - | - | Active, FILLFACTOR=95 |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_InstrumentDailyUnitMargin_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |

---

## 8. Sample Queries

### 8.1 Current margin for all active instruments

```sql
SELECT InstrumentID, UnitMargin, PriceRateID, Occurred
FROM Price.InstrumentDailyUnitMargin WITH (NOLOCK)
ORDER BY UnitMargin DESC;
```

### 8.2 Instruments with stale margin (not updated in last 2 hours)

```sql
SELECT InstrumentID, UnitMargin, Occurred
FROM Price.InstrumentDailyUnitMargin WITH (NOLOCK)
WHERE Occurred < DATEADD(HOUR, -2, GETUTCDATE())
ORDER BY Occurred ASC;
```

### 8.3 Highest-margin instruments (most expensive to trade)

```sql
SELECT TOP 20 InstrumentID, UnitMargin, Occurred
FROM Price.InstrumentDailyUnitMargin WITH (NOLOCK)
ORDER BY UnitMargin DESC;
```

### 8.4 Calculate required margin for a position

```sql
DECLARE @InstrumentID int = 1;
DECLARE @Units decimal(12,5) = 10.0;

SELECT
    InstrumentID,
    UnitMargin,
    @Units AS Units,
    UnitMargin * @Units AS TotalRequiredMargin,
    Occurred
FROM Price.InstrumentDailyUnitMargin WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentDailyUnitMargin | Type: Table | Source: etoro/etoro/Price/Tables/Price.InstrumentDailyUnitMargin.sql*
