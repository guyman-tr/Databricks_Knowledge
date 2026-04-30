# Price.GetSpreadConfigurationFeed

> Multi-feed spread configuration view that applies active skew offsets (SkewBid/SkewAsk) to reference spreads for all feeds - extends GetSpreadConfiguration by adding skew-adjusted bid/ask values, per-feed rows, and skew identification.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + FeedID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetSpreadConfigurationFeed answers: "What are the current bid/ask spreads for each instrument on each feed, with active skew applied?" It is the skew-aware version of Price.GetSpreadConfiguration. While GetSpreadConfiguration returns raw reference spreads for FeedID=1 only, this view applies active skew adjustments (SkewBid/SkewAsk from Price.ActiveSkew) and returns rows for ALL feeds an instrument is configured for (via Price.InstrumentSkewModel).

Price skewing is a risk management technique: when client order flow is imbalanced (more buyers than sellers), the pricing engine shifts bid/ask prices to reduce firm exposure. This view computes `Bid = ReferenceBid + SkewBid` and `Ask = ReferenceAsk + SkewAsk` to produce the actually-distributed spread configuration per feed. MarkupBid/MarkupAsk columns expose how much skew is currently applied.

Architecture (UNION ALL of two branches):
- **Branch 1** (non-FeedID=1 skew feeds): Instruments with InstrumentSkewModel rows where FeedID != 1. Applies skew from ActiveSkew for the secondary feed. Currently produces 0 rows (InstrumentSkewModel is empty).
- **Branch 2** (FeedID=1): All instruments, applies primary-feed skew from ActiveSkew where FeedID=1. Currently identical to GetSpreadConfiguration with MarkupBid=0/MarkupAsk=0 (no active skew).

Current state: 10,466 rows, all FeedID=1, MarkupBid=0, MarkupAsk=0, SkewID=NULL. No active skew; InstrumentSkewModel empty.

---

## 2. Business Logic

### 2.1 Skew Application to Reference Spreads

**What**: SkewBid and SkewAsk from Price.ActiveSkew are added to ReferenceBid/ReferenceAsk to produce the currently-distributed Bid/Ask values.

**Columns/Parameters Involved**: `Bid`, `Ask`, `MarkupBid`, `MarkupAsk`, `ReferenceBid`, `ReferenceAsk`, `SkewID`

**Rules**:
- Bid = ReferenceBid + ISNULL(PAS.SkewBid, 0)  <- LEFT JOIN to ActiveSkew, 0 when no skew
- Ask = ReferenceAsk + ISNULL(PAS.SkewAsk, 0)
- MarkupBid = ISNULL(PAS.SkewBid, 0)  <- the delta from reference on the bid side
- MarkupAsk = ISNULL(PAS.SkewAsk, 0)  <- the delta from reference on the ask side
- SkewID: identifies which ActiveSkew row's values are applied (NULL when no skew)
- When no skew active: Bid = ReferenceBid, Ask = ReferenceAsk, Markup = 0

### 2.2 UNION ALL: Primary Feed vs Secondary Skew Feeds

**What**: Two SELECT branches cover different feed scenarios.

**Columns/Parameters Involved**: `FeedID`, `SkewID`, `InstrumentID`

**Rules**:
- **Branch 1** (ISM.FeedID != 1): Instruments with InstrumentSkewModel rows for secondary feeds. Each such instrument-FeedID combination generates a row with secondary-feed skew applied. FeedID = ISNULL(ISM.FeedID, 1).
- **Branch 2** (all instruments, FeedID=1): LEFT JOIN to ActiveSkew where FeedID=1. FeedID = ISNULL(PAS.FeedID, 1). Always produces one row per instrument with primary-feed skew (or 0 skew if none active).
- An instrument with a secondary skew model will appear in BOTH branches: once for each secondary feed (Branch 1) and once for FeedID=1 (Branch 2).
- An instrument without any InstrumentSkewModel rows only appears once (Branch 2, FeedID=1).

---

## 3. Data Overview

| InstrumentID | SpreadTypeID | Bid | Ask | PriceServerID | Precision | MarkupBid | MarkupAsk | ReferenceBid | ReferenceAsk | FeedID | SkewID | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | -2 | 2 | 1 | 3 | 0 | 0 | -2 | 2 | 1 | NULL | EUR/USD: FeedID=1, no active skew (MarkupBid/Ask=0). Bid=ReferenceBid. |
| 2 | 1 | -1 | 1 | 3 | 5 | 0 | 0 | -1 | 1 | 1 | NULL | GBP/USD: same pattern. No skew active. |
| 3 | 1 | -1 | 1 | 1 | 5 | 0 | 0 | -1 | 1 | 1 | NULL | NZD/USD. No skew. |
| 4 | 1 | -1 | 1 | 2 | 5 | 0 | 0 | -1 | 1 | 1 | NULL | USD/CAD. No skew. |
| 5 | 1 | -1 | 1 | 3 | 3 | 0 | 0 | -1 | 1 | 1 | NULL | JPY/USD: Precision=3, FeedID=1. |

*When skew is active: MarkupBid/MarkupAsk would be non-zero, and Bid/Ask would differ from ReferenceBid/ReferenceAsk.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. From Trade.InstrumentSpread (FeedID=1 base) via Trade.Instrument. |
| 2 | SpreadTypeID | int | YES | - | CODE-BACKED | Spread calculation mode from Trade.InstrumentSpread. Values: 1=Fixed spread (seen in data). Controls how Bid/Ask offsets are interpreted. |
| 3 | Bid | decimal | YES | - | CODE-BACKED | Computed: ReferenceBid + ISNULL(SkewBid, 0). Currently equals ReferenceBid (no active skew). The distributed bid-side offset applied to raw market price. |
| 4 | Ask | decimal | YES | - | CODE-BACKED | Computed: ReferenceAsk + ISNULL(SkewAsk, 0). Currently equals ReferenceAsk (no active skew). The distributed ask-side offset applied to raw market price. |
| 5 | MarketSpreadThreshold | decimal | YES | - | CODE-BACKED | Maximum acceptable market spread from Trade.InstrumentSpread. Incoming prices with spread wider than this may be rejected. |
| 6 | PriceServerID | int | YES | - | CODE-BACKED | Price server identifier from Trade.Instrument. Identifies which price server partition handles this instrument. |
| 7 | Precision | int | YES | - | CODE-BACKED | Decimal precision from Trade.ProviderToInstrument (PTI alias). Precision=3 for JPY pairs, 5 for standard forex. |
| 8 | MarkupBid | decimal | NO | - | CODE-BACKED | Current bid-side skew applied: ISNULL(SkewBid, 0). 0 = no active skew. Non-zero = skew algorithm has shifted the bid price by this amount. |
| 9 | MarkupAsk | decimal | NO | - | CODE-BACKED | Current ask-side skew applied: ISNULL(SkewAsk, 0). 0 = no active skew. Symmetric counterpart to MarkupBid. |
| 10 | ReferenceBid | decimal | YES | - | CODE-BACKED | Reference bid offset from Trade.InstrumentSpread (no skew). Baseline bid spread value. Bid = ReferenceBid when no skew active. |
| 11 | ReferenceAsk | decimal | YES | - | CODE-BACKED | Reference ask offset from Trade.InstrumentSpread. Baseline ask spread value. |
| 12 | SpreadThresholdTypeID | int | YES | - | CODE-BACKED | Spread threshold type from Trade.InstrumentSpread. 2 distinct values (1 and 2). Determines alerting/rejection logic when MarketSpreadThreshold is breached. |
| 13 | FeedID | int | NO | - | CODE-BACKED | Feed identifier for this spread row. Branch 1: ISNULL(ISM.FeedID, 1) - secondary feed ID. Branch 2: ISNULL(PAS.FeedID, 1) - always 1 (primary). Currently always 1 (InstrumentSkewModel empty). |
| 14 | SkewID | int | YES | - | CODE-BACKED | Identifier of the ActiveSkew row whose values are applied. NULL when no skew is active for this instrument+feed combination. From Price.ActiveSkew. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All spread columns | Trade.InstrumentSpread | FROM source (FeedID=1) | Reference bid/ask, thresholds, SpreadTypeID |
| PriceServerID | Trade.Instrument | INNER JOIN | Price server for the instrument |
| Precision | Trade.ProviderToInstrument | INNER JOIN | Price display precision |
| SkewBid/SkewAsk -> MarkupBid/MarkupAsk | Price.ActiveSkew | LEFT JOIN | Active skew offset values; NULL when no skew |
| FeedID (Branch 1) | Price.InstrumentSkewModel | INNER JOIN | Secondary feed skew model assignment |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetSpreadConfigurationFeed (view)
├── Trade.InstrumentSpread (table)
├── Trade.Instrument (table)
├── Trade.ProviderToInstrument (table)
├── Price.InstrumentSkewModel (table)
└── Price.ActiveSkew (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentSpread | Table | FROM (TIS, FeedID=1) - all reference spread columns |
| Trade.Instrument | Table | INNER JOIN - PriceServerID |
| Trade.ProviderToInstrument | Table | INNER JOIN - Precision |
| Price.InstrumentSkewModel | Table | INNER JOIN (Branch 1 only) - secondary feed skew model |
| Price.ActiveSkew | Table | LEFT JOIN - SkewBid, SkewAsk, SkewID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. UNION ALL of two branches. Branch 1 currently returns 0 rows (InstrumentSkewModel empty).

---

## 8. Sample Queries

### 8.1 Get spread config with skew for a specific instrument

```sql
SELECT InstrumentID, FeedID, Bid, Ask, MarkupBid, MarkupAsk, ReferenceBid, ReferenceAsk, SkewID
FROM Price.GetSpreadConfigurationFeed WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY FeedID;
```

### 8.2 Find instruments with active skew (non-zero markup)

```sql
SELECT InstrumentID, FeedID, MarkupBid, MarkupAsk, SkewID
FROM Price.GetSpreadConfigurationFeed WITH (NOLOCK)
WHERE MarkupBid <> 0 OR MarkupAsk <> 0
ORDER BY InstrumentID, FeedID;
```

### 8.3 Compare current spread vs reference (skew impact)

```sql
SELECT InstrumentID, FeedID,
       ReferenceBid, Bid, MarkupBid,
       ReferenceAsk, Ask, MarkupAsk
FROM Price.GetSpreadConfigurationFeed WITH (NOLOCK)
WHERE FeedID = 1
ORDER BY ABS(MarkupBid) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetSpreadConfigurationFeed | Type: View | Source: etoro/etoro/Price/Views/Price.GetSpreadConfigurationFeed.sql*
