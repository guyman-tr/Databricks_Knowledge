# Trade.CollectCurrencyPriceDifferencesBetweenFeeds

> Compares bid/ask prices between primary and secondary market data feeds, collecting instruments where prices diverge beyond a configurable tolerance percentage into a differences table for alerting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts to dbo.Syn_CurrencyPriceFeedDifferences |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CollectCurrencyPriceDifferencesBetweenFeeds is a monitoring procedure that detects price discrepancies between the platform's primary and secondary market data feeds. In a multi-feed architecture, the primary feed drives trading prices while the secondary feed serves as a validation source. When the two feeds diverge beyond a configurable tolerance, it may indicate a feed malfunction, stale data, or market data provider issues.

This procedure is critical for market data integrity. If a primary feed reports incorrect prices, traders could open positions at wrong rates, causing financial losses and regulatory issues. By continuously comparing feeds, the system catches anomalies before they cause harm.

The procedure reads current prices from Trade.CurrencyPrice (primary) and Trade.CurrencyPriceSecondary (secondary), computes tolerance bands using the @DifferenceTolleranceInPercentage parameter, and inserts any instruments that exceed the bands into dbo.Syn_CurrencyPriceFeedDifferences (a synonym pointing to a centralized monitoring table). Trade.CurrencyPriceDifferencesAlert then reads this data to send email alerts.

---

## 2. Business Logic

### 2.1 Tolerance Band Calculation

**What**: Price differences are evaluated against configurable percentage tolerance bands around the primary feed's prices.

**Columns/Parameters Involved**: `@DifferenceTolleranceInPercentage`, `CurrencyPrice.Bid`, `CurrencyPrice.Ask`

**Rules**:
- Lower band = Primary price * (1 - tolerance/100)
- Upper band = Primary price * (1 + tolerance/100)
- Default tolerance is 10% if not specified
- Both Bid and Ask are checked independently against their respective bands
- Only enabled instruments (ProviderToInstrument.Enabled=1) and tradable instruments (InstrumentMetaData.Tradable=1) are compared

### 2.2 Feed Comparison Logic

**What**: Secondary feed (FeedID=2) prices are compared against primary feed tolerance bands.

**Columns/Parameters Involved**: `CurrencyPriceSecondary.Bid`, `CurrencyPriceSecondary.Ask`

**Rules**:
- Join between primary and secondary on ProviderID + InstrumentID
- Only secondary feed rows with FeedID=2 are compared
- An instrument is flagged if the secondary Bid falls outside BOTH the Bid AND Ask tolerance ranges

**Diagram**:
```
Primary Feed (CurrencyPrice)
    |
    +-- Calculate tolerance bands (Bid +/- X%, Ask +/- X%)
    |
    +-- Compare with Secondary Feed (CurrencyPriceSecondary, FeedID=2)
    |
    +-- If outside bands:
          INSERT into Syn_CurrencyPriceFeedDifferences
          |
          +-- CurrencyPriceDifferencesAlert reads and emails
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DifferenceTolleranceInPercentage | INT | NO | 10 | CODE-BACKED | Percentage tolerance for acceptable price differences between primary and secondary feeds. A value of 10 means +/-10% of the primary price is acceptable. Outside this range triggers logging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Primary prices | Trade.CurrencyPrice | Reader | Reads current bid/ask prices from the primary market data feed |
| Secondary prices | Trade.CurrencyPriceSecondary | Reader | Reads current bid/ask prices from the secondary (validation) feed |
| Instrument filter | Trade.ProviderToInstrument | Lookup | Filters to only enabled instruments (Enabled=1) |
| Instrument filter | Trade.InstrumentMetaData | Lookup | Filters to only tradable instruments (Tradable=1) |
| Output | dbo.Syn_CurrencyPriceFeedDifferences | Writer | Inserts divergent price records into the centralized differences tracking table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CurrencyPriceDifferencesAlert | Dependency | Consumer | Reads the differences table populated by this procedure and sends email alerts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CollectCurrencyPriceDifferencesBetweenFeeds (procedure)
+-- Trade.CurrencyPrice (table)
+-- Trade.CurrencyPriceSecondary (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.InstrumentMetaData (table)
+-- dbo.Syn_CurrencyPriceFeedDifferences (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | Primary feed prices (CTE source) |
| Trade.CurrencyPriceSecondary | Table | Secondary feed prices (JOIN for comparison) |
| Trade.ProviderToInstrument | Table | EXISTS filter for enabled instruments |
| Trade.InstrumentMetaData | Table | EXISTS filter for tradable instruments |
| dbo.Syn_CurrencyPriceFeedDifferences | Synonym | INSERT target for divergent price records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPriceDifferencesAlert | Stored Procedure | Downstream alerting - reads differences and sends emails |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check recent price differences
```sql
SELECT TOP 20 *
FROM   Trade.CurrencyPriceFeedDifferences WITH (NOLOCK)
WHERE  CollectionTime >= DATEADD(HOUR, -1, GETDATE())
ORDER BY CollectionTime DESC
```

### 8.2 Compare primary vs secondary for a specific instrument
```sql
SELECT cp.InstrumentID, cp.Bid AS PrimaryBid, cp.Ask AS PrimaryAsk,
       cps.Bid AS SecondaryBid, cps.Ask AS SecondaryAsk,
       ABS(cp.Bid - cps.Bid) / cp.Bid * 100 AS BidDiffPct
FROM   Trade.CurrencyPrice cp WITH (NOLOCK)
       JOIN Trade.CurrencyPriceSecondary cps WITH (NOLOCK)
            ON cp.ProviderID = cps.ProviderID AND cp.InstrumentID = cps.InstrumentID
WHERE  cp.InstrumentID = 1001
       AND cps.FeedID = 2
```

### 8.3 Check enabled tradable instruments
```sql
SELECT pti.InstrumentID, imd.SymbolFull
FROM   Trade.ProviderToInstrument pti WITH (NOLOCK)
       JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON pti.InstrumentID = imd.InstrumentID
WHERE  pti.Enabled = 1
       AND imd.Tradable = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CollectCurrencyPriceDifferencesBetweenFeeds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CollectCurrencyPriceDifferencesBetweenFeeds.sql*
