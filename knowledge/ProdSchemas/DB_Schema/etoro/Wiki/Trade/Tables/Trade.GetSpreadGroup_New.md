# Trade.GetSpreadGroup_New

> Flattened spread lookup per (ProviderID, InstrumentID) for pip value and pricing calculations. Denormalized bid/ask offsets used by Internal.GetOnePipValueDollar.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | (ProviderID, InstrumentID) - composite PK |
| **Partition** | No |
| **Indexes** | 1 (PK) |

---

## 1. Business Meaning

Trade.GetSpreadGroup_New stores a flattened per-(ProviderID, InstrumentID) spread configuration: Bid and Ask pip offsets plus a SpreadID reference. Unlike Trade.Spread (which joins via SpreadToGroup for spread-group resolution), this table provides a direct lookup of Bid/Ask for each provider-instrument pair. The "New" suffix indicates it replaced an older spread group resolution path.

This table exists because pip value and conversion calculations need fast access to spread offsets without traversing SpreadGroup → SpreadToGroup → Spread. Internal.GetOnePipValueDollar joins CurrencyPrice, GetSpreadGroup_New, and ProviderToInstrument to compute `TCRP.Bid + CAST(TGSG.Bid AS DECIMAL(16,8))/POWER(10,TPVI.Precision)` for cross-rate conversion. Without it, pip value and USD conversion would require multiple joins through spread groups.

Data is populated during instrument onboarding (likely via Trade.InsertInstrumentRealTable or similar bulk load). There are no direct INSERT/UPDATE procedures in the stored procedure search; the table may be maintained by ETL or migration scripts. Read by Internal.GetOnePipValueDollar only.

---

## 2. Business Logic

### 2.1 Bid and Ask as Pip Offsets

**What**: Bid and Ask are decimal pip offsets applied to raw provider prices in pip value and conversion calculations.

**Columns/Parameters Involved**: `Bid`, `Ask`, `SpreadID`

**Rules**:
- Bid is typically negative (e.g., -2, -3). Sample: Bid ∈ {-3..-1}, Ask ∈ {1..2}.
- Internal.GetOnePipValueDollar: `TCRP.Bid + CAST(TGSG.Bid AS DECIMAL(16,8))/POWER(10,TPVI.Precision)` — Bid is scaled by instrument precision and added to raw bid.
- SpreadID links to Trade.Spread for lineage; the table denormalizes Bid/Ask for performance.

**Diagram**:
```
Internal.GetOnePipValueDollar
  CurrencyPrice (TCRP) + GetSpreadGroup_New (TGSG) + ProviderToInstrument (TPVI)
  → Result = DollarRatio * (Bid + TGSG.Bid/10^Precision) for cross-rate
```

### 2.2 One Row Per (ProviderID, InstrumentID)

**What**: Composite PK ensures exactly one spread record per provider-instrument.

**Rules**:
- PK (ProviderID, InstrumentID) — no duplicates.
- 281 rows observed. ProviderID=1 covers instruments 1–5 in sample; SpreadID aligns 1:1 with InstrumentID for Provider 1.

---

## 3. Data Overview

| ProviderID | InstrumentID | SpreadID | Bid | Ask | Meaning |
|------------|--------------|----------|-----|-----|---------|
| 1 | 1 | 1 | -2 | 1 | EUR/USD. Bid offset -2, Ask +1. |
| 1 | 2 | 2 | -2 | 2 | GBP pair. Wider ask. |
| 1 | 3 | 3 | -3 | 2 | NZD/USD. Tighter bid. |
| 1 | 4 | 4 | -1 | 2 | Instrument 4. |
| 1 | 5 | 5 | -1 | 1 | Instrument 5. |

**Selection criteria**: First 5 by (ProviderID, InstrumentID). 281 rows total. Bid negative, Ask positive; used in pip value calculations.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | FK to Trade.Provider. Part of PK. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Part of PK. |
| 3 | SpreadID | int | NO | - | CODE-BACKED | FK to Trade.Spread. Links to spread definition. |
| 4 | Bid | dbo.dtPrice | NO | - | CODE-BACKED | Pip offset for bid (negative = discount). |
| 5 | Ask | dbo.dtPrice | NO | - | CODE-BACKED | Pip offset for ask (positive = markup). |

---

## 5. Relationships

### 5.1 References To

- **Trade.Provider** (ProviderID)
- **Trade.Instrument** (InstrumentID)
- **Trade.Spread** (SpreadID)

### 5.2 Referenced By

- **Internal.GetOnePipValueDollar** (read-only, JOIN)

---

## 6. Dependencies

### 6.0 Chain

```
Trade.Provider → Trade.GetSpreadGroup_New
Trade.Instrument → Trade.GetSpreadGroup_New
Trade.Spread → Trade.GetSpreadGroup_New
```

### 6.1 Depends On

- Trade.Provider
- Trade.Instrument
- Trade.Spread

### 6.2 Depended On By

- Internal.GetOnePipValueDollar (function)

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Columns |
|------|------|---------|
| PK_GetSpreadGroup_New | CLUSTERED | (ProviderID, InstrumentID) |

### 7.2 Constraints

- PK_GetSpreadGroup_New: PRIMARY KEY (ProviderID, InstrumentID)

---

## 8. Sample Queries

```sql
-- Row count
SELECT COUNT(*) AS Cnt FROM Trade.GetSpreadGroup_New WITH (NOLOCK);

-- Sample rows
SELECT TOP 5 * FROM Trade.GetSpreadGroup_New WITH (NOLOCK);

-- Spread by provider and instrument
SELECT ProviderID, InstrumentID, SpreadID, Bid, Ask
FROM Trade.GetSpreadGroup_New WITH (NOLOCK)
WHERE ProviderID = 1 AND InstrumentID IN (1, 2, 3);
```

---

## 9. Atlassian Knowledge Sources

*None discovered.*

---

*Generated: 2026-03-14 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
