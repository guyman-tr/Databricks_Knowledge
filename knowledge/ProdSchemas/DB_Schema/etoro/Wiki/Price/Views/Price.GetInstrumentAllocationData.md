# Price.GetInstrumentAllocationData

> Combined instrument-to-source allocation view that pairs each prioritized rate source with its associated liquidity account, ranks sources per instrument, and flags benchmark feeds - the primary allocation summary read by the pricing configuration layer.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + AccountRateSourceID + LiquidityAccountID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetInstrumentAllocationData answers: "For each instrument, what rate sources are allocated, in what priority order, via which liquidity accounts, and which (if any) is the benchmark?" Each row represents one complete allocation slot: an instrument, its rate source, the priority at which that source is queried, the liquidity account carrying that source, a rank within the instrument, and a benchmark indicator.

The view exists to give the pricing configuration system a single query that returns everything needed to understand an instrument's full feed allocation - priority order, account identity, and benchmark designation - without the caller needing to join InstrumentRateSources, LiquidityAccountToInstrument, LiquidityAccounts, and BenchmarkFeedConfiguration separately. It enforces coherence: a rate source only appears for an instrument if it is both configured in InstrumentRateSources AND the liquidity account carrying that source is eligible for the instrument in LiquidityAccountToInstrument.

Data characteristics: covers all active instruments (via Trade.GetInstrument filter) with at least one rate source. Instrument 1 (EUR/USD) has two rows: primary ZBFX (AccountRateSourceID=21, Priority=10, Row=1) and secondary AccountRateSource 301 (Priority=30, Row=2). All IsBenchmark=0 currently (BenchmarkFeedConfiguration holds 0 rows). The Row column provides a dense priority rank per instrument starting at 1.

---

## 2. Business Logic

### 2.1 Priority Ranking via CTE ROW_NUMBER

**What**: The CTE ranks each instrument's rate sources by priority, assigning a dense row number (Row=1 = highest priority). This gives consumers both the raw Priority value and a normalized rank.

**Columns/Parameters Involved**: `Priority`, `Row`, `InstrumentID`, `AccountRateSourceID`

**Rules**:
- CTE uses ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY Priority ASC) -> Row
- Row=1 is always the highest-priority (lowest Priority value) source for that instrument
- Priority values: 10=primary, 20=secondary, 30=tertiary, 40=quaternary (from InstrumentRateSources)
- Row differs from Priority: Priority is the configured tier (can have gaps), Row is a dense sequence starting at 1 (no gaps)
- Consumers that want only the primary source filter WHERE Row=1

**Diagram**:
```
InstrumentID=1 (EUR/USD):
  AccountRateSourceID=21,  Priority=10, Row=1  <- primary (ZBFX)
  AccountRateSourceID=301, Priority=30, Row=2  <- tertiary configured but Row=2 (no P20 row)

InstrumentID=3:
  AccountRateSourceID=21,  Priority=10, Row=1  <- primary
  AccountRateSourceID=300, Priority=20, Row=2  <- secondary
```

### 2.2 Coherence Filter: Account Must Match Both Eligibility and Rate Source

**What**: The triple JOIN (LATI + TLA) ensures only rows where the liquidity account is both eligible for the instrument AND carries the correct rate source are returned.

**Columns/Parameters Involved**: `LiquidityAccountID`, `AccountRateSourceID`, `InstrumentID`

**Rules**:
- JOIN Price.LiquidityAccountToInstrument ON LATI.InstrumentID = IRS.InstrumentID: account must be eligible for this instrument
- JOIN Trade.LiquidityAccounts ON IRS.AccountRateSourceID = TLA.AccountRateSourceID AND LATI.LiquidityAccountID = TLA.LiquidityAccountID: the same account must carry the correct rate source
- This double-join eliminates inconsistent configurations: if InstrumentRateSources says "use rate source X for instrument Y" but no account carrying rate source X is eligible for instrument Y in LiquidityAccountToInstrument, that row is silently dropped
- JOIN Trade.GetInstrument further restricts to valid instruments (InstrumentID != 0, InstrumentTypeID not NULL)

### 2.3 Benchmark Designation via BenchmarkFeedConfiguration

**What**: The IsBenchmark flag marks whether this rate source is the designated benchmark feed for the instrument's type.

**Columns/Parameters Involved**: `IsBenchmark`, `AccountRateSourceID`, `InstrumentTypeID`

**Rules**:
- LEFT JOIN Price.BenchmarkFeedConfiguration ON BFC.BenchmarkAccountRateSourceID = IRS.AccountRateSourceID AND InstrumentTypeID = CurrencyTypeID
- IsBenchmark = IIF(BenchmarkAccountRateSourceID IS NULL, 0, 1)
- IsBenchmark=1: this source is the designated benchmark for the instrument's CurrencyType (for comparison/quality tracking)
- IsBenchmark=0: not a benchmark (or BenchmarkFeedConfiguration has no rows - currently empty)
- The InstrumentTypeID used in the JOIN comes from Trade.GetInstrument (via the GI JOIN in the view)

---

## 3. Data Overview

| InstrumentID | AccountRateSourceID | Priority | LiquidityAccountID | IsBenchmark | Row | Meaning |
|---|---|---|---|---|---|---|
| 1 | 21 | 10 | 7 | 0 | 1 | EUR/USD primary source: ZBFX (ARS=21) via account 7. Highest priority - queried first for EUR/USD prices. |
| 1 | 301 | 30 | 327 | 0 | 2 | EUR/USD tertiary source: ARS=301 via account 327. Fallback if primary unavailable. Row=2 (dense rank, no P20 gap). |
| 2 | 21 | 10 | 7 | 0 | 1 | GBP/USD primary source: same ZBFX account serves multiple major forex pairs. |
| 3 | 21 | 10 | 7 | 0 | 1 | Another forex pair, primary = ZBFX. |
| 3 | 300 | 20 | 326 | 0 | 2 | Instrument 3 secondary source: ARS=300 via account 326. Has a true P20 row unlike instrument 1. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. From Price.InstrumentRateSources (via CTE). Must exist in Trade.GetInstrument (JOIN enforces validity). |
| 2 | AccountRateSourceID | int | NO | - | CODE-BACKED | Rate source identifier for this allocation slot. From Price.InstrumentRateSources. FK to Price.AccountRateSource. Identifies the named price feed (ZBFX=21, QuantHouse=301/300, Bloomberg=196, etc.). |
| 3 | Priority | int | NO | - | CODE-BACKED | Configured priority tier from Price.InstrumentRateSources: 10=primary, 20=secondary, 30=tertiary, 40=quaternary. Lower value = higher precedence. Can have gaps (e.g., an instrument may have P10 and P30 but no P20). |
| 4 | LiquidityAccountID | int | NO | - | CODE-BACKED | Active liquidity account carrying this rate source for this instrument. From Trade.LiquidityAccounts (TLA alias). Resolved by the double-join: account must be in LiquidityAccountToInstrument for this instrument AND carry the matching AccountRateSourceID. |
| 5 | IsBenchmark | int | NO | - | CODE-BACKED | Benchmark designation flag: 1 = this rate source is the configured benchmark for the instrument's CurrencyType (from BenchmarkFeedConfiguration), 0 = not a benchmark. Computed: IIF(BenchmarkAccountRateSourceID IS NULL, 0, 1). Currently always 0 (BenchmarkFeedConfiguration is empty). |
| 6 | Row | bigint | NO | - | CODE-BACKED | Dense priority rank for this source within its instrument: Row=1 = highest priority source. Computed by ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY Priority ASC) in the CTE. Differs from Priority in that Row has no gaps (1, 2, 3...) even when Priority values skip tiers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Price.InstrumentRateSources | CTE source | Rate source priority configuration |
| InstrumentID | Trade.GetInstrument | JOIN filter | Ensures instrument is valid and provides InstrumentTypeID |
| InstrumentID + LiquidityAccountID | Price.LiquidityAccountToInstrument | JOIN | Ensures account is eligible for this instrument |
| AccountRateSourceID + LiquidityAccountID | Trade.LiquidityAccounts | JOIN | Resolves account identity; validates ARS-account pairing |
| AccountRateSourceID + InstrumentTypeID | Price.BenchmarkFeedConfiguration | LEFT JOIN | Determines IsBenchmark flag per source-type combination |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetInstrumentAllocationData (view)
├── Price.InstrumentRateSources (table)
├── Price.LiquidityAccountToInstrument (table)
├── Price.BenchmarkFeedConfiguration (table)
├── Trade.LiquidityAccounts (table)
└── Trade.GetInstrument (view)
      ├── Trade.Instrument (table)
      ├── Dictionary.Currency (table)
      └── Trade.InstrumentMetaData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSources | Table | CTE source - provides InstrumentID, AccountRateSourceID, Priority with ROW_NUMBER rank |
| Price.LiquidityAccountToInstrument | Table | JOIN - validates account eligibility per instrument |
| Price.BenchmarkFeedConfiguration | Table | LEFT JOIN - provides benchmark designation per source+InstrumentType |
| Trade.LiquidityAccounts | Table | JOIN - resolves LiquidityAccountID and validates ARS-account coherence |
| Trade.GetInstrument | View | JOIN - ensures instrument validity and provides InstrumentTypeID for benchmark check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. Effective coherence filter: account must be eligible for instrument (LATI JOIN) AND carry the correct rate source (TLA JOIN on both ARS and AccountID).

---

## 8. Sample Queries

### 8.1 Get full allocation for a specific instrument

```sql
SELECT InstrumentID, AccountRateSourceID, Priority, LiquidityAccountID, IsBenchmark, Row
FROM Price.GetInstrumentAllocationData WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Row;
```

### 8.2 Get only primary sources (Row=1) for all instruments

```sql
SELECT InstrumentID, AccountRateSourceID, LiquidityAccountID
FROM Price.GetInstrumentAllocationData WITH (NOLOCK)
WHERE Row = 1
ORDER BY InstrumentID;
```

### 8.3 Join to AccountRateSource for source names

```sql
SELECT
    GIAD.InstrumentID,
    GIAD.Row,
    GIAD.Priority,
    ARS.Name AS RateSourceName,
    GIAD.LiquidityAccountID,
    GIAD.IsBenchmark
FROM Price.GetInstrumentAllocationData GIAD WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = GIAD.AccountRateSourceID
WHERE GIAD.InstrumentID = 1
ORDER BY GIAD.Row;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetInstrumentAllocationData | Type: View | Source: etoro/etoro/Price/Views/Price.GetInstrumentAllocationData.sql*
