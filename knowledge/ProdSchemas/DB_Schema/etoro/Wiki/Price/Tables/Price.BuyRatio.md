# Price.BuyRatio

> Time-series store of buy/sell position and unit ratio snapshots per instrument, capturing the imbalance metrics that drive the price skew algorithm - each row records a calculated buy ratio, its smoothed average, and the resulting skew value for a given instrument over a specific time window.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | BuyRatioID (bigint IDENTITY, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 (NONCLUSTERED PK on BuyRatioID; CLUSTERED on Date ASC + InstrumentID ASC) |

---

## 1. Business Meaning

Price.BuyRatio is the data log of the eToro price skew system. It records periodic snapshots of client buy/sell imbalance for each instrument: how many clients are long vs short, how many units are on each side, and what ratio that produces. These snapshots are the input that the skew algorithm consumes to decide whether and how much to shift instrument prices.

The skew mechanism works as follows: when significantly more clients are buying than selling, eToro's risk position becomes net-short against its clients. To reduce this exposure, the pricing engine skews bid/ask prices upward - making buying slightly more expensive and selling slightly more attractive. This self-correcting mechanism reduces the firm's net exposure without outright refusing trades. Each row in this table represents one calculation cycle's snapshot.

The `Skew` column captures the skew value derived from the ratio at that point in time. The live, currently-applied skew lives in `Price.ActiveSkew`, which is updated by reading the latest BuyRatio data together with configuration from `Price.BuyRatioThresholds` and `Price.BuyRatioSkewConditions`.

Data lifecycle: rows are written by `Price.AddBuyRatio` (called periodically by the skew calculation engine). The table is append-only - there are no UPDATE or DELETE operations. The clustered index on (Date, InstrumentID) optimizes time-range queries and time-series retrieval patterns.

---

## 2. Business Logic

### 2.1 Buy Ratio Calculation and Skew Derivation

**What**: BuyRatio and AverageBuyRatio are the core metrics used to determine whether client-side imbalance has crossed a threshold requiring price adjustment.

**Columns/Parameters Involved**: `BuyPositionCount`, `SellPositionCount`, `BuyUnits`, `SellUnits`, `BuyRatio`, `AverageBuyRatio`, `Skew`

**Rules**:
- BuyRatio = proportion of client exposure on the buy side (range 0.0000-1.0000; 0.5000 = balanced)
- BuyRatio > 0.5000: more clients are long than short -> potential need to skew prices up
- BuyRatio < 0.5000: more clients are short than long -> potential need to skew prices down
- AverageBuyRatio: smoothed/rolling average of BuyRatio, reducing noise from single-snapshot spikes
- Skew: the resulting skew offset calculated for this snapshot; feeds into Price.ActiveSkew update cycle
- decimal(5,4) precision for BuyRatio and AverageBuyRatio: up to 9.9999 max, but logically constrained to [0,1]

**Diagram**:
```
Client Position Data
  |-- count open buy positions -> BuyPositionCount
  |-- count open sell positions -> SellPositionCount
  |-- sum buy side units -> BuyUnits
  |-- sum sell side units -> SellUnits
  v
Calculate BuyRatio = buy/(buy+sell)
Calculate AverageBuyRatio (rolling/smoothed)
  |
  v
Compare against Price.BuyRatioThresholds (per instrument)
  |
  v
Lookup matching Price.BuyRatioSkewConditions
  |
  v
Derive Skew value
  |
  v
INSERT into Price.BuyRatio (this table - historical record)
  |
  v
Price.SetActiveSkew -> UPDATE Price.ActiveSkew (live skew application)
```

### 2.2 Time Window Tracking

**What**: DateFrom, DateTo, and Date together track when the ratio was measured and what time window the position counts cover.

**Columns/Parameters Involved**: `DateFrom`, `DateTo`, `Date`

**Rules**:
- DateFrom: start of the calculation window (e.g., positions opened after this timestamp are included)
- DateTo: end of the calculation window
- Date: the timestamp when this ratio was computed/inserted; DEFAULT = getdate() (server time)
- The clustered index on (Date, InstrumentID) makes lookups by "most recent ratio per instrument" efficient

---

## 3. Data Overview

| Note | Value |
|------|-------|
| Row count (this environment) | 0 (read replica / pre-population state) |
| Append-only | Yes - no UPDATE or DELETE operations |
| Query pattern | Latest row per instrument: ORDER BY Date DESC, filtered by InstrumentID |

*This table is 0 rows in this environment. The data pattern below is inferred from the schema and Price.AddBuyRatio SP.*

| InstrumentID | BuyRatio | AverageBuyRatio | Skew | Meaning |
|---|---|---|---|---|
| (e.g.) 1 | 0.6500 | 0.6200 | 0.0005 | EUR/USD: 65% of positions are long; above typical threshold; small upward skew applied |
| (e.g.) 1 | 0.5100 | 0.5300 | 0.0000 | EUR/USD: near-balanced; within tolerance; no skew |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BuyRatioID | bigint IDENTITY(1,1) | NOT NULL | - | CODE-BACKED | Surrogate primary key. Auto-incremented. NONCLUSTERED - the table's physical ordering is by Date+InstrumentID (clustered index), not by insert order. Used for precise row identification in downstream processing. |
| 2 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. No explicit FK constraint, but implicitly references Trade.Instrument. The skew algorithm processes each instrument independently; this column partitions the time series per instrument. Part of the clustered index (secondary key). |
| 3 | BuyPositionCount | int | NOT NULL | - | CODE-BACKED | Count of currently open client buy (long) positions for this instrument at the time of calculation. Integer count; combined with SellPositionCount to determine directional exposure by position count. |
| 4 | SellPositionCount | int | NOT NULL | - | CODE-BACKED | Count of currently open client sell (short) positions for this instrument at the time of calculation. Integer count; combined with BuyPositionCount to measure the position-count dimension of imbalance. |
| 5 | BuyUnits | decimal(12,4) | NOT NULL | - | CODE-BACKED | Total units held in open buy positions for this instrument. Measures the volume/notional dimension of imbalance (vs BuyPositionCount which measures count). A large BuyUnits with a small BuyPositionCount indicates a few large long positions. |
| 6 | SellUnits | decimal(12,4) | NOT NULL | - | CODE-BACKED | Total units held in open sell positions for this instrument. Paired with BuyUnits for volume-based imbalance measurement. decimal(12,4) supports instruments with large position sizes. |
| 7 | BuyRatio | decimal(5,4) | NOT NULL | - | CODE-BACKED | The calculated buy-side ratio for this snapshot. Logically in range [0.0000, 1.0000] where 0.5000 = perfectly balanced. Values above 0.5 indicate net long client exposure; values below 0.5 indicate net short. The primary input to the skew decision logic in BuyRatioThresholds. |
| 8 | AverageBuyRatio | decimal(5,4) | NOT NULL | - | CODE-BACKED | Smoothed or rolling average of BuyRatio over recent snapshots. Reduces reaction to transient spikes in the instantaneous BuyRatio. The skew algorithm uses this averaged value to avoid over-reacting to short-lived imbalances. |
| 9 | DateFrom | datetime | NOT NULL | - | CODE-BACKED | Start of the time window over which positions were aggregated to produce this ratio snapshot. Defines the lookback start point: positions opened or active after DateFrom are included in the count/unit totals. |
| 10 | DateTo | datetime | NOT NULL | - | CODE-BACKED | End of the time window for this ratio snapshot. Paired with DateFrom to define the exact aggregation window. Typically the current time or a rolling cutoff. |
| 11 | Date | datetime | NOT NULL | getdate() | CODE-BACKED | Timestamp when this ratio row was inserted (calculation time). DEFAULT = getdate(). Part of the clustered index (primary sort key): time-range queries over this column are the dominant access pattern. Used to retrieve the most recent ratio per instrument. |
| 12 | Skew | decimal(10,4) | YES | - | CODE-BACKED | The skew offset value derived from this ratio snapshot, in price units. NULL when no skew was triggered (ratio within threshold). When non-NULL, this value represents the price adjustment that should be (or was) applied to the instrument's bid/ask. Connects the ratio measurement to the skew output that flows into Price.ActiveSkew. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Buy/sell ratio is tracked per instrument; no FK enforced |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.AddBuyRatio | Price.BuyRatio | WRITER | Inserts new buy ratio snapshots; the only write path to this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.BuyRatio (table) - leaf node
  ^-- Price.AddBuyRatio writes to this table
  --> Price.BuyRatioThresholds + Price.BuyRatioSkewConditions define the skew rules (sibling tables)
  --> Price.ActiveSkew stores the live applied skew (output table)
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.AddBuyRatio | Stored Procedure | Inserts new buy ratio + skew snapshots (sole writer) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PriceBuyRatio | NONCLUSTERED PK | BuyRatioID ASC | - | - | Active, FILLFACTOR=95 |
| IX_PriceBuyRatio_Date | CLUSTERED | Date ASC, InstrumentID ASC | - | - | Active, FILLFACTOR=95 |

*Note: The PK is NONCLUSTERED, which is unusual. Physical row ordering is by Date+InstrumentID for time-series access patterns. The NONCLUSTERED PK on BuyRatioID supports point-lookup by identity but is not the primary query path.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_PriceBuyRation_Date | DEFAULT | Date = getdate() - auto-populates the insertion timestamp |

*Note: The constraint name contains a typo ("BuyRation" instead of "BuyRatio") - preserved from the original DDL.*

---

## 8. Sample Queries

### 8.1 Most recent buy ratio per instrument

```sql
SELECT InstrumentID, BuyRatio, AverageBuyRatio, Skew, Date
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY Date DESC) AS rn
    FROM Price.BuyRatio WITH (NOLOCK)
) t
WHERE rn = 1
ORDER BY ABS(BuyRatio - 0.5) DESC;  -- most imbalanced first
```

### 8.2 Instruments with significant buy imbalance in last hour

```sql
SELECT InstrumentID, BuyRatio, AverageBuyRatio, BuyPositionCount, SellPositionCount, Skew, Date
FROM Price.BuyRatio WITH (NOLOCK)
WHERE Date >= DATEADD(HOUR, -1, GETUTCDATE())
  AND BuyRatio > 0.65
ORDER BY BuyRatio DESC;
```

### 8.3 Buy ratio history for a specific instrument

```sql
SELECT BuyRatioID, BuyRatio, AverageBuyRatio, BuyPositionCount, SellPositionCount,
       BuyUnits, SellUnits, Skew, DateFrom, DateTo, Date
FROM Price.BuyRatio WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Date DESC;
```

### 8.4 Correlation between skew and imbalance

```sql
SELECT
    InstrumentID,
    AVG(BuyRatio) AS AvgBuyRatio,
    AVG(AverageBuyRatio) AS AvgSmoothedRatio,
    AVG(ISNULL(Skew, 0)) AS AvgSkew,
    COUNT(*) AS SnapshotCount
FROM Price.BuyRatio WITH (NOLOCK)
WHERE Date >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY InstrumentID
ORDER BY ABS(AVG(BuyRatio) - 0.5) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.BuyRatio | Type: Table | Source: etoro/etoro/Price/Tables/Price.BuyRatio.sql*
