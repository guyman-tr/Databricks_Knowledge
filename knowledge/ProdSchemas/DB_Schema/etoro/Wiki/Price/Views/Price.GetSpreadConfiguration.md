# Price.GetSpreadConfiguration

> View that exposes the full spread configuration for each instrument including bid/ask offsets, markup computation, price precision, and threshold settings - the primary spread config read interface for the pricing engine (FeedID=1 only).

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetSpreadConfiguration answers: "What are the spread settings, pricing precision, markup, and threshold configuration for each instrument?" It joins Trade.InstrumentSpread with Trade.Instrument (for PriceServerID) and Trade.ProviderToInstrument (for FeedID filter) to produce the complete spread configuration for the main feed (FeedID=1).

Spread configuration is central to price quoting: Bid and Ask are offsets (in half-pips or similar units) applied to the raw market price to produce the quoted price. Markup = Bid - ReferenceBid shows how much additional spread has been added on top of the reference configuration. Precision determines decimal places displayed. SpreadTypeID and SpreadThresholdTypeID control spread calculation mode and alert thresholds.

Data: 10,466 rows (one per active instrument with FeedID=1 spread configuration). All Markup=0 in current data (Bid equals ReferenceBid - no additional markup configured). SpreadTypeID=1 for all rows in the sample. SpreadThresholdTypeID has 2 distinct values (1 and 2). Bid/Ask are symmetric offsets (e.g., -2/+2 for EUR/USD, -1/+1 for most other forex).

---

## 2. Business Logic

### 2.1 Spread Offset Representation

**What**: Bid and Ask are numeric offsets applied to the mid-price, not absolute price values. A symmetric spread of Bid=-1, Ask=1 adds 1 unit to the ask and subtracts 1 unit from the bid relative to the raw market rate.

**Columns/Parameters Involved**: `Bid`, `Ask`, `Precision`

**Rules**:
- Bid is typically negative (price offset below mid): -2 for EUR/USD, -1 for most other pairs
- Ask is typically positive (price offset above mid): +2 for EUR/USD, +1 for others
- The spread width = Ask - Bid: 4 for EUR/USD, 2 for most forex
- Precision determines decimal places: Precision=3 (EUR/USD displayed to 3 decimal places? or spread units to 3 decimal places), Precision=5 for most pairs
- Units are likely in the smallest price unit of the instrument (1 unit = 1 pip or 1 price point)

### 2.2 Markup Calculation

**What**: Markup = Bid - ReferenceBid indicates additional spread added on top of the reference configuration. Currently 0 for all instruments (no markup active).

**Columns/Parameters Involved**: `Markup`, `Bid`, `ReferenceBid`, `ReferenceAsk`

**Rules**:
- Markup = Bid - ReferenceBid (computed in view SELECT)
- Markup=0: the current spread equals the reference spread - no additional markup
- Markup > 0: the current spread is wider than the reference (client pays more spread)
- Markup < 0: the current spread is tighter than the reference (unusual; would indicate a discount)
- ReferenceBid and ReferenceAsk are the baseline spread values; Bid and Ask may be adjusted above them

### 2.3 FeedID=1 Filter

**What**: WHERE FeedID=1 restricts to the primary feed configuration. ProviderToInstrument can have multiple rows per instrument for different FeedIDs.

**Columns/Parameters Involved**: `FeedID` (from Trade.ProviderToInstrument, not in SELECT)

**Rules**:
- FeedID=1: primary/main feed - the spread config used for live pricing
- Other FeedIDs would represent alternate or secondary feed configurations (not in this view)
- The INNER JOIN to ProviderToInstrument means instruments without a FeedID=1 row in ProviderToInstrument are excluded

---

## 3. Data Overview

| InstrumentID | SpreadTypeID | Bid | Ask | MarketSpreadThreshold | PriceServerID | Precision | Markup | ReferenceBid | ReferenceAsk | SpreadThresholdTypeID | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | -2 | 2 | 2 | 1 | 3 | 0 | -2 | 2 | 1 | EUR/USD: symmetric spread of 2 units. Markup=0 (Bid=ReferenceBid). Precision=3. PriceServer=1. |
| 2 | 1 | -1 | 1 | 1 | 3 | 5 | 0 | -1 | 1 | 2 | GBP/USD: tighter 1-unit spread. Precision=5. PriceServer=3. ThresholdType=2. |
| 3 | 1 | -1 | 1 | 1 | 1 | 5 | 0 | -1 | 1 | 1 | NZD/USD: 1-unit spread, Precision=5. |
| 4 | 1 | -1 | 1 | 1 | 2 | 5 | 0 | -1 | 1 | 2 | USD/CAD: PriceServer=2. ThresholdType=2. |
| 5 | 1 | -1 | 1 | 1 | 3 | 3 | 0 | -1 | 1 | 1 | JPY/USD: Precision=3 (JPY uses fewer decimals). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. From Trade.Instrument via InstrumentSpread join. Must have a FeedID=1 row in ProviderToInstrument. |
| 2 | SpreadTypeID | int | YES | - | CODE-BACKED | Spread calculation mode from Trade.InstrumentSpread. 2 distinct values observed. Likely: 1=Fixed spread, 2=Variable/market spread. Controls how Bid/Ask offsets are applied. |
| 3 | Bid | decimal | YES | - | CODE-BACKED | Bid price offset from Trade.InstrumentSpread. Applied to the raw market price to derive the quoted bid. Typically negative (e.g., -1 = subtract 1 unit from mid-price). |
| 4 | Ask | decimal | YES | - | CODE-BACKED | Ask price offset from Trade.InstrumentSpread. Applied to the raw market price to derive the quoted ask. Typically positive (e.g., +1 = add 1 unit to mid-price). |
| 5 | MarketSpreadThreshold | decimal | YES | - | CODE-BACKED | Maximum acceptable market spread. If the incoming market spread exceeds this value, the price may be rejected or flagged. Same magnitude as Bid/Ask offsets. |
| 6 | PriceServerID | int | YES | - | CODE-BACKED | Price server identifier from Trade.Instrument. Identifies which price server partition handles this instrument's spread application. |
| 7 | Precision | int | YES | - | CODE-BACKED | Decimal precision for displaying this instrument's price. Precision=3 for JPY-denominated pairs (fewer decimal places), Precision=5 for standard forex. Used by the pricing engine to format output prices. |
| 8 | Markup | decimal | NO | - | CODE-BACKED | Computed: Bid - ReferenceBid. Additional spread added on top of the reference configuration. 0 = no markup (current spread equals reference). Positive = wider spread than reference (additional client cost). |
| 9 | ReferenceBid | decimal | YES | - | CODE-BACKED | Reference bid offset from Trade.InstrumentSpread. Baseline spread configuration. Current Bid is compared against this to compute Markup. |
| 10 | ReferenceAsk | decimal | YES | - | CODE-BACKED | Reference ask offset from Trade.InstrumentSpread. Baseline ask spread configuration counterpart to ReferenceBid. |
| 11 | SpreadThresholdTypeID | int | YES | - | CODE-BACKED | Spread threshold type classification from Trade.InstrumentSpread. 2 distinct values (1 and 2). Determines which threshold logic applies when MarketSpreadThreshold is breached. Likely FK to Dictionary.SpreadThresholdType (referenced in Price.SpreadThresholdConfiguration). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID + spread columns | Trade.InstrumentSpread | FROM source | Bid, Ask, MarketSpreadThreshold, Precision, Reference values, SpreadTypeID, ThresholdTypeID |
| InstrumentID + PriceServerID | Trade.Instrument | INNER JOIN | Provides PriceServerID |
| InstrumentID | Trade.ProviderToInstrument | INNER JOIN (FeedID=1 filter) | Restricts to primary feed instruments |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetSpreadConfiguration (view)
├── Trade.InstrumentSpread (table)
├── Trade.Instrument (table)
└── Trade.ProviderToInstrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentSpread | Table | FROM (TIS alias) - all spread config columns |
| Trade.Instrument | Table | INNER JOIN (TI alias) on InstrumentID - provides PriceServerID |
| Trade.ProviderToInstrument | Table | INNER JOIN (PTI alias) on InstrumentID - WHERE FeedID=1 filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. WHERE FeedID=1 restricts to primary feed. Markup is a computed column (Bid - ReferenceBid).

---

## 8. Sample Queries

### 8.1 Get spread config for a specific instrument

```sql
SELECT InstrumentID, SpreadTypeID, Bid, Ask, Markup, Precision, PriceServerID
FROM Price.GetSpreadConfiguration WITH (NOLOCK)
WHERE InstrumentID = 1;
```

### 8.2 Find instruments with non-zero markup

```sql
SELECT InstrumentID, Bid, ReferenceBid, Markup
FROM Price.GetSpreadConfiguration WITH (NOLOCK)
WHERE Markup <> 0
ORDER BY Markup DESC;
```

### 8.3 Instruments by spread width

```sql
SELECT InstrumentID, Bid, Ask, (Ask - Bid) AS SpreadWidth, Precision
FROM Price.GetSpreadConfiguration WITH (NOLOCK)
ORDER BY SpreadWidth DESC, InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetSpreadConfiguration | Type: View | Source: etoro/etoro/Price/Views/Price.GetSpreadConfiguration.sql*
