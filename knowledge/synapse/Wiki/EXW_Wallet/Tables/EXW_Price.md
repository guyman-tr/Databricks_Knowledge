# EXW_Wallet.EXW_Price

> 9.95M-row hourly cryptocurrency price table tracking ask, bid, and average prices for ~172 crypto instruments across 12 blockchain networks from 2018-04-23 to present. Populated daily by SP_Prices from ETL_InstrumentRates_ByHour with hourly gap-filling logic. ~4,128 rows inserted per day (172 instruments x 24 hours).

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | Unknown (no resolvable upstream wiki; data originates from EXW_Wallet.ETL_InstrumentRates_ByHour via SP_Prices) |
| **Refresh** | Daily — delete+insert per date via EXW_Wallet.SP_Prices(@dt) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateFrom ASC, CryptoID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

EXW_Price stores **hourly cryptocurrency price snapshots** for every wallet-eligible crypto instrument. Each row represents one instrument's ask, bid, and average price for a one-hour time bucket. The table is the price backbone for the eToroX / eToro Wallet platform, providing historical and intraday pricing used for portfolio valuation, P&L calculation, and trade settlement.

The table is populated daily by `EXW_Wallet.SP_Prices`, which:
1. Builds an instrument-to-crypto mapping by joining `EXW_Currency.Instruments`, `EXW_Currency.Currencies`, `EXW_Wallet.CryptoMarketRatesMappings`, and `EXW_Wallet.CryptoTypes` — filtering to USD-denominated pairs only.
2. Pulls hourly average ask and bid rates from `EXW_Wallet.ETL_InstrumentRates_ByHour` for the target date.
3. Generates a full 24-hour grid per instrument and fills price gaps using the most recent available price (OUTER APPLY lookback). If an instrument has no price at all for the target date, it backfills from the latest available price in EXW_Price itself (prior-day fallback).
4. Deletes existing rows for the target date, then inserts the gap-filled result.

The table currently holds ~9.95M rows spanning from 2018-04-23 to present, covering 172 distinct crypto instruments across 12 blockchain networks (ETH-based tokens dominate at ~93% of rows). The `eToroInstrumentID` column is NULL for ~65% of instruments — these are crypto-native instruments that do not have an eToro trading platform mapping.

---

## 2. Business Logic

### 2.1 InstrumentID Remapping

**What**: The InstrumentID stored in EXW_Price is not the raw wallet instrument ID — it is conditionally remapped.
**Columns Involved**: InstrumentID, eToroInstrumentID, CryptoID
**Rules**:
- If `eToroInstrumentID >= 100000` → InstrumentID = eToroInstrumentID (eToro-mapped instrument)
- Otherwise → InstrumentID = CryptoID (crypto-native instrument without eToro mapping)
- This means InstrumentID is NOT a FK to EXW_Currency.Instruments.Id in all cases

### 2.2 Hourly Price Gap-Filling

**What**: The SP ensures every instrument has a price row for every hour of the target date, even if market rates data is missing for some hours.
**Columns Involved**: AskLast, BidLast, AvgPrice
**Rules**:
- For any hour where no rate exists, the SP carries forward the most recent non-NULL price from an earlier hour on the same day (OUTER APPLY lookback)
- If the entire day has no rates for an instrument, the SP backfills from the latest price row in EXW_Price before @dt (prior-day fallback UPDATE)
- Zero prices (0.00000000) indicate a dormant or delisted instrument, not a gap-fill failure

### 2.3 Average Price Computation

**What**: AvgPrice is the midpoint of bid and ask.
**Columns Involved**: AvgPrice, AskLast, BidLast
**Rules**:
- `AvgPrice = (BidRateAvg + AskRateAvg) / 2` computed from ETL_InstrumentRates_ByHour
- After gap-filling, AvgPrice may reflect carried-forward values rather than live market data

### 2.4 Blockchain Network Classification

**What**: Each instrument maps to a blockchain network via the CryptoTypes hierarchy.
**Columns Involved**: BlockchainCryptoId, BlockchainCryptoName, CryptoID
**Rules**:
- BlockchainCryptoId is resolved via `CryptoTypes.BlockchainCryptoId` (the parent blockchain for each token)
- BlockchainCryptoName is the name of the blockchain network (e.g., ETH, BTC, SOL)
- 12 distinct blockchain networks are currently active
- ETH accounts for ~93% of instrument rows (most tokens are ERC-20)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no colocation benefit on JOINs. Queries filtering on a single instrument will scan all distributions.
- **Clustered Index**: (DateFrom ASC, CryptoID ASC) — efficient for date-range + crypto filters. Always include DateFrom or FullDate in WHERE clauses for range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest price for a specific crypto | `WHERE CryptoID = @id ORDER BY DateFrom DESC` — uses clustered index |
| Daily closing price | `WHERE FullDate = @date AND DateTo = DATEADD(D,1,CAST(@date AS DATETIME))` — last hour of day |
| Price history for date range | `WHERE DateFrom >= @start AND DateFrom < @end AND CryptoID = @id` — clustered index seek |
| Cross-blockchain comparison | Filter by BlockchainCryptoName, aggregate AvgPrice by FullDate |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_Wallet.EXW_PriceDaily | InstrumentID + FullDate | Daily aggregated prices (one row/day vs 24 rows/day) |
| EXW_Wallet.CryptoTypes | CryptoID = CryptoTypes.CryptoID | Resolve full crypto metadata |
| EXW_Wallet.CryptoMarketRatesMappings | CryptoID = CryptoMarketRatesMappings.CryptoId | Map to market rates currency symbol |

### 3.4 Gotchas

- **InstrumentID is NOT always the wallet instrument ID**: It is conditionally remapped. Use CryptoID for a stable crypto identifier, or eToroInstrumentID (when non-NULL) for the eToro trading platform reference.
- **eToroInstrumentID is NULL for ~65% of rows**: These are crypto-native instruments without an eToro platform mapping. Do not use eToroInstrumentID as a join key without NULL handling.
- **Zero prices exist**: AskLast/BidLast/AvgPrice = 0.00000000 for dormant or delisted instruments (e.g., BTU, SGDX). Filter `WHERE AvgPrice > 0` for active-instrument analytics.
- **Gap-filled rows are indistinguishable**: There is no flag indicating whether a row contains live market data or carried-forward prices. If precision matters, cross-reference with ETL_InstrumentRates_ByHour directly.
- **24 rows per instrument per day**: Aggregations should account for 24 hourly buckets. Use EXW_PriceDaily for daily-level analysis.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (production source documented) |
| Tier 2 | Derived from SP code / ETL logic with identified source table |
| Tier 3 | No source traceable; described from DDL + data evidence |
| Tier 4 | Inferred from column name only (banned in this pipeline) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Composite instrument identifier. CASE WHEN eToroInstrumentID >= 100000 THEN eToroInstrumentID ELSE CryptoId END. For eToro-mapped instruments, equals eToroInstrumentID; for crypto-native instruments, equals CryptoID. Not a direct FK to EXW_Currency.Instruments. (Tier 2 — EXW_Wallet.CryptoTypes / EXW_Wallet.CryptoMarketRatesMappings) |
| 2 | eToroInstrumentID | int | YES | eToro trading platform instrument identifier. Sourced from CryptoTypes.InstrumentId via the crypto mapping chain. NULL for ~65% of instruments that are crypto-native without eToro platform mapping. Values >= 100000 when present. (Tier 2 — EXW_Wallet.CryptoTypes) |
| 3 | CryptoID | int | YES | Unique crypto asset identifier from CryptoMarketRatesMappings. Stable identifier for the crypto asset regardless of eToro mapping. One row per CryptoID per hour. (Tier 2 — EXW_Wallet.CryptoMarketRatesMappings) |
| 4 | CryptoName | varchar(50) | YES | Crypto asset ticker symbol (e.g., BNT, BTC, ETH, ALICE). Sourced as MarketRatesCurrencySymbol from CryptoMarketRatesMappings, renamed to CryptoName. (Tier 2 — EXW_Wallet.CryptoMarketRatesMappings) |
| 5 | AskLast | decimal(38,8) | YES | Average ask rate for the hour bucket. Sourced as AskRateAvg from ETL_InstrumentRates_ByHour. Gap-filled from the most recent prior hour with data, or from prior-day EXW_Price if the entire day is missing. Zero indicates a dormant or delisted instrument. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 6 | BidLast | decimal(38,8) | YES | Average bid rate for the hour bucket. Sourced as BidRateAvg from ETL_InstrumentRates_ByHour. Gap-filled from the most recent prior hour with data, or from prior-day EXW_Price if the entire day is missing. Zero indicates a dormant or delisted instrument. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 7 | AvgPrice | decimal(38,8) | YES | Midpoint price computed as (BidRateAvg + AskRateAvg) / 2 from ETL_InstrumentRates_ByHour. Gap-filled using same logic as AskLast/BidLast. Primary price column for portfolio valuation. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 8 | DateFrom | datetime | YES | Start of the one-hour price bucket. Sourced as DateHour from ETL_InstrumentRates_ByHour. Part of the clustered index. Range: every hour on the hour from midnight to 23:00 for each date. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 9 | DateTo | datetime | YES | End of the one-hour price bucket. Computed as DATEADD(HOUR, 1, DateHour). Always exactly one hour after DateFrom. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 10 | BlockchainCryptoId | int | YES | Identifier of the parent blockchain network for this crypto asset. Resolved via CryptoTypes.BlockchainCryptoId — maps each token to its underlying blockchain (e.g., all ERC-20 tokens map to ETH's BlockchainCryptoId). 12 distinct values. (Tier 3 — EXW_Wallet.CryptoTypes) |
| 11 | BlockchainCryptoName | varchar(50) | YES | Name of the parent blockchain network (e.g., ETH, BTC, SOL, ADA, XRP). Resolved from CryptoTypes.Name for the blockchain-level CryptoTypes row (ct1 alias in SP_Prices). 12 distinct values: ETH, BTC, LTC, SOL, TRX, XLM, XRP, ADA, BCH, DOGE, EOS, ETC. (Tier 2 — EXW_Wallet.CryptoTypes) |
| 12 | FullDate | date | YES | Calendar date of the price record. Computed as CAST(DateHour AS DATE) from ETL_InstrumentRates_ByHour. Used for daily-level filtering and joins to EXW_PriceDaily. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 13 | FullDateID | int | YES | Integer date key in YYYYMMDD format. Computed as CONVERT(VARCHAR(8), DateHour, 112) from ETL_InstrumentRates_ByHour. Used for date-range filtering and partition-style access. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 14 | UpdateDate | datetime | YES | Timestamp when the row was inserted by SP_Prices. Set to GETDATE() at insert time. Not updated on backfill — reflects the ETL execution time, not the price observation time. (Tier 2 — EXW_Wallet.SP_Prices) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| InstrumentID | EXW_Wallet.CryptoTypes / CryptoMarketRatesMappings | InstrumentId / CryptoId | CASE remapping based on eToroInstrumentID threshold |
| eToroInstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | Passthrough via mapping chain |
| CryptoID | EXW_Wallet.CryptoMarketRatesMappings | CryptoId | Passthrough |
| CryptoName | EXW_Wallet.CryptoMarketRatesMappings | MarketRatesCurrencySymbol | Rename |
| AskLast | EXW_Wallet.ETL_InstrumentRates_ByHour | AskRateAvg | Rename + gap-fill |
| BidLast | EXW_Wallet.ETL_InstrumentRates_ByHour | BidRateAvg | Rename + gap-fill |
| AvgPrice | EXW_Wallet.ETL_InstrumentRates_ByHour | AskRateAvg, BidRateAvg | (Bid + Ask) / 2 + gap-fill |
| DateFrom | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | Rename |
| DateTo | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | DATEADD(HOUR, 1, DateHour) |
| BlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | Passthrough via mapping chain |
| BlockchainCryptoName | EXW_Wallet.CryptoTypes | Name (ct1 alias) | Rename |
| FullDate | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | CAST(DateHour AS DATE) |
| FullDateID | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | CONVERT(VARCHAR(8), DateHour, 112) |
| UpdateDate | SP_Prices | — | GETDATE() |

### 5.2 ETL Pipeline

```
EXW_Currency.Instruments + EXW_Currency.Currencies
  |-- JOIN on BuyCurrencyId / SellCurrencyId (USD filter) --|
  v
EXW_Wallet.CryptoMarketRatesMappings
  |-- LEFT JOIN on currency Symbol → CryptoId --|
  v
EXW_Wallet.CryptoTypes (dct + ct1)
  |-- LEFT JOIN on CryptoId → eToroInstrumentID, BlockchainCryptoId --|
  v
#mapping (instrument-to-crypto mapping, USD pairs only)
  |-- JOIN --|
  v
EXW_Wallet.ETL_InstrumentRates_ByHour (hourly avg rates for @dt)
  |-- JOIN #mapping ON InstrumentID --|
  v
#rates → #price (InstrumentID CASE remap) → #allhours (24h grid × instruments)
  |-- LEFT JOIN prices → OUTER APPLY gap-fill → UPDATE prior-day backfill --|
  v
#prices (gap-filled hourly prices)
  |-- DELETE + INSERT for @dt --|
  v
EXW_Wallet.EXW_Price (~9.95M rows, 172 instruments × 24h × ~2,400 days)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CryptoID | EXW_Wallet.CryptoMarketRatesMappings | Maps to CryptoMarketRatesMappings.CryptoId for market rate symbol resolution |
| CryptoID | EXW_Wallet.CryptoTypes | Maps to CryptoTypes.CryptoID for crypto asset metadata |
| BlockchainCryptoId | EXW_Wallet.CryptoTypes | Maps to CryptoTypes.CryptoID for blockchain network metadata |
| eToroInstrumentID | EXW_Wallet.CryptoTypes | Maps to CryptoTypes.InstrumentId for eToro platform mapping |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element | Description |
|-------------------|---------|-------------|
| EXW_Wallet.SP_Prices | InstrumentID, DateFrom | Self-reference for prior-day price backfill (missing_previous_prices logic) |
| EXW_Wallet.EXW_PriceDaily | — | Daily aggregation target populated by the same SP_Prices run |

---

## 7. Sample Queries

### 7.1 Latest Hourly Price for a Specific Crypto

```sql
SELECT TOP 1 CryptoName, AskLast, BidLast, AvgPrice, DateFrom, DateTo
FROM EXW_Wallet.EXW_Price
WHERE CryptoID = 1  -- e.g., Bitcoin
  AND AvgPrice > 0
ORDER BY DateFrom DESC;
```

### 7.2 Daily Closing Price Across All Active Cryptos

```sql
SELECT CryptoName, BlockchainCryptoName, AvgPrice, FullDate
FROM EXW_Wallet.EXW_Price
WHERE FullDate = '2026-04-25'
  AND DATEPART(HOUR, DateFrom) = 23
  AND AvgPrice > 0
ORDER BY AvgPrice DESC;
```

### 7.3 Price Availability Check — Detect Gap-Filled vs Live Hours

```sql
SELECT p.CryptoName, p.FullDate,
       COUNT(*) AS total_hours,
       SUM(CASE WHEN r.InstrumentID IS NOT NULL THEN 1 ELSE 0 END) AS live_hours
FROM EXW_Wallet.EXW_Price p
LEFT JOIN EXW_Wallet.ETL_InstrumentRates_ByHour r
  ON p.InstrumentID = r.InstrumentID AND p.DateFrom = r.DateHour
WHERE p.FullDate = '2026-04-25'
GROUP BY p.CryptoName, p.FullDate
ORDER BY live_hours ASC;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this object (regen-harness mode — Atlassian search skipped).

---

*Generated: 2026-04-30 | Quality: pending judge | Phases: 13/14*
*Tiers: 0 T1, 14 T2, 0 T3, 0 T4, 0 T5 | Elements: 14/14, Logic: 4/10, Query: 3*
*Object: EXW_Wallet.EXW_Price | Type: Table | Production Source: Unknown (dormant — no upstream wiki)*
