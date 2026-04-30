# Price.ActiveSkew

> Stores the currently active bid and ask skew adjustment values per instrument per feed, representing real-time price distortions applied by the skew algorithm to shift prices in response to client buy/sell imbalances.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID + FeedID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR=95) |

---

## 1. Business Meaning

ActiveSkew maintains the live skew values being applied by the eToro price skew algorithm to each instrument's bid and ask prices for a given feed. Price skewing is a risk management technique: when more clients are buying than selling (or vice versa), the pricing engine intentionally shifts prices to reduce the firm's net exposure - making the "popular" side slightly less attractive while improving the "unpopular" side.

This table is the output of the skew algorithm - it holds the current, actively-applied skew values that are added to raw bid/ask prices before distribution to clients. The values are consumed by the price bulk-update TVPs (CurrencyPriceTable, CurrencyPriceSeconadryTable) which carry SkewValueBid/SkewValueAsk fields that originate from this table.

Data lifecycle: the skew algorithm periodically calculates skew values based on buy/sell ratio data (Price.BuyRatio) and configuration (Price.BuyRatioThresholds, Price.BuyRatioSkewConditions), then writes the results here via `Price.SetActiveSkew`. All changes are audited in History.AuditHistory. When skew is inactive or zero, rows exist with SkewBid=0 and SkewAsk=0.

---

## 2. Business Logic

### 2.1 Price Skew Mechanism

**What**: Skew values are signed decimal offsets added to raw bid/ask prices to balance client-side exposure.

**Columns/Parameters Involved**: `SkewBid`, `SkewAsk`, `InstrumentID`, `FeedID`

**Rules**:
- SkewBid > 0: bid price is shifted upward (clients get a worse buy price when too many are buying)
- SkewBid < 0: bid price is shifted downward (incentivizes buying)
- SkewAsk works symmetrically for the ask side
- SkewBid=0 and SkewAsk=0 (the common state seen in data): no skew is active for this instrument/feed
- FeedID allows different skew values per feed for the same instrument

**Diagram**:
```
Buy/Sell Imbalance (from Price.BuyRatio)
      |
      v
Skew Algorithm (reads BuyRatioThresholds + BuyRatioSkewConditions)
      |
      v
Price.SetActiveSkew -> UPDATE Price.ActiveSkew
      |
      v
Price.ActiveSkew (live skew store)
  SkewBid/SkewAsk -> injected into CurrencyPrice(Seconadry)Table TVPs
      |
      v
Trade.CurrencyPrice / Trade.CurrencyPriceSecondary
  (SkewValueBid = skew applied to final client price)
```

### 2.2 Feed-Level Skew Granularity

**What**: Skew is tracked per instrument per feed, allowing different feeds to carry different skew states for the same instrument.

**Columns/Parameters Involved**: `InstrumentID`, `FeedID`

**Rules**:
- Primary feed instruments: one row per InstrumentID with the primary FeedID
- Secondary feed instruments: additional rows for each alternative FeedID
- SkewID (nullable uniqueidentifier) links to the skew model or configuration snapshot that produced these values

---

## 3. Data Overview

| InstrumentID | FeedID | SkewBid | SkewAsk | Meaning |
|---|---|---|---|---|
| 1 | 1 | 0.0000 | 0.0000 | EUR/USD on feed 1 - no skew active; buy/sell imbalance is within tolerance thresholds |
| 2 | 1 | 0.0000 | 0.0000 | GBP/USD on feed 1 - no skew active |
| 3 | 1 | 0.0000 | 0.0000 | Typical state: most instruments have zero skew when market is balanced |

*Note: All sampled rows show zero skew, reflecting that skew is either not active in this environment or buy/sell ratios are within tolerance.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. Part of the composite PK with FeedID. No explicit FK constraint, but implicitly references Trade.Instrument. |
| 2 | FeedID | int | NOT NULL | - | CODE-BACKED | Identifies which price feed this skew applies to. Part of the composite PK. Allows per-feed skew differentiation when an instrument has multiple active feeds. |
| 3 | SkewBid | decimal(10,4) | NOT NULL | - | CODE-BACKED | Bid price skew offset in price units (not percentage). Positive = bid shifted up (penalizes buyers), negative = bid shifted down (incentivizes buyers). 0 = no skew active. Applied as: FinalBid = RawBid + SkewBid. |
| 4 | SkewAsk | decimal(10,4) | NOT NULL | - | CODE-BACKED | Ask price skew offset in price units. Positive = ask shifted up (penalizes sellers viewing from buy side), negative = ask shifted down. Applied as: FinalAsk = RawAsk + SkewAsk. 0 = no skew active. |
| 5 | SkewID | uniqueidentifier | YES | - | NAME-INFERRED | Optional identifier linking these skew values to a specific skew model configuration or calculation run. NULL when skew values are manually set or when no model tracking is needed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Skew is defined per instrument; no FK enforced |
| FeedID | Trade.LiquidityAccounts (via AccountRateSourceID) | Implicit | Feed IDs correspond to liquidity feed identifiers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SetActiveSkew | Price.ActiveSkew | WRITER/MODIFIER | Sets or updates skew values for an instrument/feed pair |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.ActiveSkew (table) - leaf node
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.SetActiveSkew | Stored Procedure | Writes/updates SkewBid and SkewAsk values |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Price_ActiveSkew | CLUSTERED PK | InstrumentID ASC, FeedID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| AuditDelete_Price_ActiveSkew | TRIGGER (DELETE) | Logs SkewAsk and SkewBid old values to History.AuditHistory |
| AuditInsert_Price_ActiveSkew | TRIGGER (INSERT) | Logs new SkewAsk and SkewBid values to History.AuditHistory |
| AuditUpdate_Price_ActiveSkew | TRIGGER (UPDATE) | Logs old/new SkewAsk and SkewBid when changed to History.AuditHistory |

---

## 8. Sample Queries

### 8.1 Check all active non-zero skews

```sql
SELECT InstrumentID, FeedID, SkewBid, SkewAsk, SkewID
FROM Price.ActiveSkew WITH (NOLOCK)
WHERE SkewBid <> 0 OR SkewAsk <> 0
ORDER BY ABS(SkewBid) + ABS(SkewAsk) DESC;
```

### 8.2 List skew values for a specific instrument across all feeds

```sql
SELECT InstrumentID, FeedID, SkewBid, SkewAsk
FROM Price.ActiveSkew WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY FeedID;
```

### 8.3 Recent skew audit history

```sql
SELECT AuditDate, UserName, AppName, ColumnName, OldValue, NewValue, PK_Value
FROM History.AuditHistory WITH (NOLOCK)
WHERE TableName = 'ActiveSkew'
ORDER BY AuditDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1, 2, 3, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.ActiveSkew | Type: Table | Source: etoro/etoro/Price/Tables/Price.ActiveSkew.sql*
