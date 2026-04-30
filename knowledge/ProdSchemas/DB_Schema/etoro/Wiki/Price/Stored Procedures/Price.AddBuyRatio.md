# Price.AddBuyRatio

> Single-INSERT writer procedure for the buy ratio time-series log - appends one calculated buy/sell imbalance snapshot (ratio, position counts, units, skew value, and time window) to Price.BuyRatio for a given instrument.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID + @DateFrom/@DateTo (identifies the snapshot) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.AddBuyRatio is the sole write path to Price.BuyRatio. It records one completed buy/sell imbalance calculation cycle for a single instrument into the historical log. Each call represents: "the skew calculation engine has just finished computing the buy ratio for instrument X over the window [DateFrom, DateTo] and the result is BuyRatio with skew value Skew."

The procedure exists as an isolated write boundary around Price.BuyRatio. All 10 input parameters map directly to Price.BuyRatio columns - there is no transformation logic. The caller (skew calculation service) derives all values before calling this procedure.

Data flow: The pricing engine periodically samples open client positions per instrument, computes buy/sell position counts, sums units on each side, derives the ratio and its smoothed average, evaluates BuyRatioThresholds and BuyRatioSkewConditions to determine the Skew value, then calls Price.AddBuyRatio to persist the snapshot. The snapshot becomes the historical audit trail; the live applied skew is managed separately via Price.SetActiveSkew -> Price.ActiveSkew.

---

## 2. Business Logic

### 2.1 Direct Parameter-to-Column Mapping (No Transformation)

**What**: All 10 parameters map 1:1 to Price.BuyRatio columns. No computation, no conditional logic, no lookup joins.

**Columns/Parameters Involved**: All 10 parameters

**Rules**:
- @BuyRatio -> BuyRatio: the calculated imbalance ratio for this snapshot
- @InstrumentID -> InstrumentID: which instrument this snapshot belongs to
- @BuyPositionCount -> BuyPositionCount: open long position count at calculation time
- @SellPositionCount -> SellPositionCount: open short position count at calculation time
- @BuyUnits -> BuyUnits: total units on buy side
- @SellUnits -> SellUnits: total units on sell side
- @AverageBuyRatio -> AverageBuyRatio: smoothed ratio; computed by caller before calling this proc
- @Skew -> Skew: derived skew offset; may be NULL if ratio is within threshold bounds
- @DateFrom -> DateFrom: start of the position aggregation window
- @DateTo -> DateTo: end of the position aggregation window
- Date column in BuyRatio is NOT a parameter - it uses DEFAULT getdate() (auto-populated by the INSERT)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BuyRatio | decimal(5,4) | IN | - | CODE-BACKED | The buy-side ratio for this snapshot: BuyPositionCount / (BuyPositionCount + SellPositionCount) or unit-weighted equivalent. Logically in [0.0000, 1.0000]; 0.5000 = balanced. Stored in Price.BuyRatio.BuyRatio. |
| 2 | @InstrumentID | int | IN | - | CODE-BACKED | eToro instrument identifier. Identifies which instrument this buy ratio snapshot belongs to. Stored in Price.BuyRatio.InstrumentID. |
| 3 | @BuyPositionCount | int | IN | - | CODE-BACKED | Count of open client buy (long) positions for this instrument at calculation time. Stored in Price.BuyRatio.BuyPositionCount. |
| 4 | @SellPositionCount | int | IN | - | CODE-BACKED | Count of open client sell (short) positions for this instrument at calculation time. Stored in Price.BuyRatio.SellPositionCount. |
| 5 | @BuyUnits | decimal(12,4) | IN | - | CODE-BACKED | Total units held across all open buy positions for this instrument. Provides volume-weighted imbalance signal alongside the count-based ratio. Stored in Price.BuyRatio.BuyUnits. |
| 6 | @SellUnits | decimal(12,4) | IN | - | CODE-BACKED | Total units held across all open sell positions for this instrument. Paired with @BuyUnits for volume-dimension imbalance measurement. Stored in Price.BuyRatio.SellUnits. |
| 7 | @AverageBuyRatio | decimal(5,4) | IN | - | CODE-BACKED | Smoothed or rolling average of buy ratio across recent snapshots. Pre-computed by the calling skew engine before this procedure is called. Reduces reaction to transient single-snapshot spikes. Stored in Price.BuyRatio.AverageBuyRatio. |
| 8 | @Skew | decimal(6,4) | IN | - | CODE-BACKED | The skew offset value (in price units) derived from this snapshot's ratio and the BuyRatioThresholds/BuyRatioSkewConditions configuration. NULL when ratio is within acceptable bounds and no skew adjustment is warranted. Stored in Price.BuyRatio.Skew. |
| 9 | @DateFrom | datetime | IN | - | CODE-BACKED | Start of the time window over which client positions were aggregated to produce this snapshot. Stored in Price.BuyRatio.DateFrom. |
| 10 | @DateTo | datetime | IN | - | CODE-BACKED | End of the time window for this snapshot. Paired with @DateFrom to define the exact aggregation window boundary. Stored in Price.BuyRatio.DateTo. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All parameters | Price.BuyRatio | WRITER (INSERT) | Appends one buy ratio snapshot row; sole write path to this table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no SQL callers found within the Price schema (called by external skew calculation service).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.AddBuyRatio (procedure)
└── Price.BuyRatio (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.BuyRatio | Table | INSERT target - appends one snapshot row per call |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found in Price schema | - | Called by external skew calculation service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Single INSERT statement; no error handling, no transactions, no SET options beyond ANSI_NULLS/QUOTED_IDENTIFIER. The Date column in Price.BuyRatio uses DEFAULT getdate() and is NOT supplied by this procedure - the DB fills it automatically.

---

## 8. Sample Queries

### 8.1 Call the procedure to log a buy ratio snapshot

```sql
EXEC Price.AddBuyRatio
    @BuyRatio = 0.6500,
    @InstrumentID = 1,
    @BuyPositionCount = 13000,
    @SellPositionCount = 7000,
    @BuyUnits = 9500.0000,
    @SellUnits = 5500.0000,
    @AverageBuyRatio = 0.6200,
    @Skew = 0.0005,
    @DateFrom = '2026-03-18 10:00:00',
    @DateTo = '2026-03-18 10:05:00';
```

### 8.2 Verify the inserted snapshot

```sql
SELECT TOP 1
    BuyRatioID, InstrumentID, BuyRatio, AverageBuyRatio, Skew,
    BuyPositionCount, SellPositionCount, DateFrom, DateTo, Date
FROM Price.BuyRatio WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Date DESC;
```

### 8.3 Check latest snapshot per instrument with skew context

```sql
SELECT
    BR.InstrumentID,
    BR.BuyRatio,
    BR.AverageBuyRatio,
    BR.Skew AS LoggedSkew,
    PAS.SkewBid AS ActiveSkewBid,
    PAS.SkewAsk AS ActiveSkewAsk,
    BR.Date AS SnapshotTime
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY Date DESC) AS rn
    FROM Price.BuyRatio WITH (NOLOCK)
) BR
LEFT JOIN Price.ActiveSkew PAS WITH (NOLOCK)
    ON PAS.InstrumentID = BR.InstrumentID
WHERE BR.rn = 1
ORDER BY ABS(BR.BuyRatio - 0.5) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.AddBuyRatio | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.AddBuyRatio.sql*
