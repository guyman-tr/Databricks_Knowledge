# Price.GetInstrumentConfiguration

> View that propagates the instrument-type-level market filter interval down to individual instruments - each row gives one instrument its inherited price throttle setting (MarketFilterIntervalMS) based on its InstrumentTypeID.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetInstrumentConfiguration answers: "What is the market filter interval for this specific instrument?" It expands the 7-row Price.InstrumentTypeConfiguration table into one row per instrument by joining on InstrumentTypeID, giving each of the 10,484 active instruments its inherited throttle interval.

The view exists because the pricing engine works at the instrument level, not the type level. Rather than requiring the engine to first look up an instrument's type and then look up the type's configuration, this view pre-joins and exposes a direct instrument-to-interval mapping. Consumers (pricing engine processes, configuration APIs) can query this view with just an InstrumentID and immediately receive the MarketFilterIntervalMS.

Data: 10,484 rows (one per instrument in Trade.GetInstrument), 3 distinct interval values inherited from Price.InstrumentTypeConfiguration: 300ms (Forex, Commodity, CFD, Indices), 400ms (Crypto), 1000ms (Stocks, ETF). The INNER JOIN to Trade.GetInstrument ensures only valid, non-placeholder instruments appear (InstrumentID != 0, InstrumentTypeID not NULL).

---

## 2. Business Logic

### 2.1 Type-Level Setting Fan-Out to Instruments

**What**: A single InstrumentTypeConfiguration row expands to N instrument rows via the JOIN on InstrumentTypeID.

**Columns/Parameters Involved**: `InstrumentID`, `MarketFilterIntervalMS`

**Rules**:
- All instruments of the same type share the same MarketFilterIntervalMS (type-level default).
- If Price.InstrumentTypeConfiguration changes the interval for a type, all instruments of that type see the change immediately (no per-instrument copy to update).
- Only instrument types that exist in InstrumentTypeConfiguration (7 of 10 types) produce rows. Instrument types with no InstrumentTypeConfiguration row are excluded.
- Per-instrument throttle overrides are stored separately in Price.PricingConfigurations (TopOfBookThrottlingInMs, FeedThrottlingInMs, ClientThrottlingInMs) - this view reflects only the type-level default.

**Known interval mappings (from InstrumentTypeConfiguration)**:
| MarketFilterIntervalMS | Instrument Types |
|---|---|
| 300ms | Forex (1), Commodity (2), CFD (3), Indices (4) |
| 400ms | Crypto (10) |
| 1000ms | Stocks (5), ETF (6) |

---

## 3. Data Overview

| InstrumentID | MarketFilterIntervalMS | Meaning |
|---|---|---|
| 1 | 300 | EUR/USD (Forex, InstrumentTypeID=1). Minimum 300ms between price publications - up to 3.3 ticks/sec. |
| 2 | 300 | GBP/USD (Forex). Same 300ms interval as all major forex pairs. |
| 3 | 300 | NZD/USD (Forex). All forex instruments inherit 300ms from InstrumentTypeConfiguration. |
| 4 | 300 | USD/CAD (Forex). Same. |
| 5 | 300 | JPY/USD (Forex). 300ms interval applies regardless of volatility characteristics. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. From Trade.GetInstrument. All valid instruments with a configured InstrumentTypeID (10,484 rows). |
| 2 | MarketFilterIntervalMS | int | NO | - | CODE-BACKED | Minimum milliseconds between consecutive price update publications for this instrument. Inherited from Price.InstrumentTypeConfiguration via the instrument's InstrumentTypeID. Values: 300 (Forex/Commodity/CFD/Indices), 400 (Crypto), 1000 (Stocks/ETF). Type-level default only - per-instrument overrides live in Price.PricingConfigurations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.GetInstrument | JOIN | Provides InstrumentTypeID and validates instrument existence |
| MarketFilterIntervalMS | Price.InstrumentTypeConfiguration | JOIN source (via InstrumentTypeID) | Source of the throttle interval per type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetInstrumentConfiguration (view)
├── Price.InstrumentTypeConfiguration (table)
└── Trade.GetInstrument (view)
      ├── Trade.Instrument (table)
      ├── Dictionary.Currency (table)
      └── Trade.InstrumentMetaData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentTypeConfiguration | Table | FROM - provides MarketFilterIntervalMS per InstrumentTypeID |
| Trade.GetInstrument | View | INNER JOIN on InstrumentTypeID - expands type config to instrument level; filters to valid instruments |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. INNER JOIN means instruments with no matching InstrumentTypeConfiguration row are excluded.

---

## 8. Sample Queries

### 8.1 Get the filter interval for a specific instrument

```sql
SELECT InstrumentID, MarketFilterIntervalMS
FROM Price.GetInstrumentConfiguration WITH (NOLOCK)
WHERE InstrumentID = 1;
```

### 8.2 Count instruments per interval tier

```sql
SELECT MarketFilterIntervalMS, COUNT(*) AS InstrumentCount
FROM Price.GetInstrumentConfiguration WITH (NOLOCK)
GROUP BY MarketFilterIntervalMS
ORDER BY MarketFilterIntervalMS;
```

### 8.3 Get all instruments with their interval, joined to instrument name

```sql
SELECT
    GIC.InstrumentID,
    GI.Name AS InstrumentName,
    GIC.MarketFilterIntervalMS
FROM Price.GetInstrumentConfiguration GIC WITH (NOLOCK)
JOIN Trade.GetInstrument GI WITH (NOLOCK)
    ON GI.InstrumentID = GIC.InstrumentID
ORDER BY GIC.MarketFilterIntervalMS, GIC.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetInstrumentConfiguration | Type: View | Source: etoro/etoro/Price/Views/Price.GetInstrumentConfiguration.sql*
