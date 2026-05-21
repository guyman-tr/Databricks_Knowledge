# EXW_Wallet.EXW_PriceDaily

> 414K-row daily cryptocurrency price table tracking average prices for 173 crypto assets across 13 blockchain networks from 2018-04-23 to present. Populated by `EXW_Wallet.SP_Prices` via daily DELETE+INSERT. One row per CryptoID per day representing the last hourly price snapshot.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant — no upstream wiki resolvable) |
| **Refresh** | Daily via `EXW_Wallet.SP_Prices @dt` — date-partitioned DELETE+INSERT |
| **Synapse Distribution** | HASH(CryptoID) |
| **Synapse Index** | CLUSTERED INDEX (FullDateID ASC, CryptoID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

EXW_PriceDaily stores one daily price per cryptocurrency instrument in the eToroX / eToro Money wallet ecosystem. Each row captures the average of bid and ask rates for a given CryptoID on a given date, derived from hourly rate snapshots in `EXW_Wallet.ETL_InstrumentRates_ByHour`.

The table currently holds ~414K rows spanning 2018-04-23 to 2026-04-25, covering 173 distinct CryptoIDs mapped to 13 blockchain networks (ETH-based tokens dominate at ~95% of rows). Of 191 distinct InstrumentIDs, only 61 have an `eToroInstrumentID` (the rest are NULL, indicating tokens not listed on the eToro trading platform).

**ETL pattern**: `SP_Prices` runs daily with a `@dt` date parameter. It:
1. Builds an instrument-to-crypto mapping via `EXW_Currency.Instruments`, `EXW_Currency.Currencies`, `EXW_Wallet.CryptoMarketRatesMappings`, and `EXW_Wallet.CryptoTypes`.
2. Pulls hourly bid/ask averages from `ETL_InstrumentRates_ByHour` for the target date.
3. Computes `AvgPrice = (BidRateAvg + AskRateAvg) / 2`.
4. Gap-fills missing hours using the last known price (forward-fill from prior hours, then from `EXW_Price` for the previous day).
5. Assigns `ROW_NUMBER() OVER (PARTITION BY CryptoId ORDER BY DateFrom DESC)` and writes only `Rn = 1` (the last hourly snapshot of the day) into EXW_PriceDaily.

---

## 2. Business Logic

### 2.1 Daily Price Selection

**What**: The daily price is the last available hourly price snapshot for each CryptoID on the given date.
**Columns Involved**: AvgPrice, CryptoID, FullDate
**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY CryptoId ORDER BY DateFrom DESC)` with `Rn = 1` selects the latest hourly record per crypto per day.
- AvgPrice is the midpoint: `(BidRateAvg + AskRateAvg) / 2`.

### 2.2 Instrument ID Resolution

**What**: InstrumentID is conditionally assigned based on whether the crypto has an eToro platform listing.
**Columns Involved**: InstrumentID, eToroInstrumentID, CryptoID
**Rules**:
- If `eToroInstrumentID >= 100000` → InstrumentID = eToroInstrumentID (eToro-listed instrument).
- Otherwise → InstrumentID = CryptoID (wallet-only instrument).

### 2.3 Price Gap-Filling

**What**: Missing hourly prices are forward-filled from the most recent available price.
**Columns Involved**: AvgPrice
**Rules**:
- For each hour without a price, `OUTER APPLY` retrieves the most recent non-NULL AvgPrice for the same CryptoID.
- If no price exists for the entire day, prices from the previous day are pulled from `EXW_Wallet.EXW_Price`.

### 2.4 Crypto-to-Blockchain Mapping

**What**: Each crypto asset is mapped to its underlying blockchain network.
**Columns Involved**: CryptoID, BlockchainCryptoId, BlockchainCryptoName
**Rules**:
- Mapping flows through `CryptoMarketRatesMappings` → `CryptoTypes` (for InstrumentId and BlockchainCryptoId) → `CryptoTypes` again (self-join via BlockchainCryptoId for BlockchainCryptoName).
- Only instruments where the sell currency is USD and CryptoId IS NOT NULL are included.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(CryptoID) — queries filtering or grouping by CryptoID avoid data movement.
- **Clustered Index**: (FullDateID ASC, CryptoID ASC) — date-range scans are efficient; always include FullDateID or FullDate in WHERE clauses.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Price of BTC on a given date | `WHERE CryptoName = 'BTC' AND FullDate = '2025-01-01'` |
| Price history for a crypto | `WHERE CryptoID = @id ORDER BY FullDateID` |
| All crypto prices on a date | `WHERE FullDate = @date` |
| Compare blockchain networks | `GROUP BY BlockchainCryptoName` with `AVG(AvgPrice)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_Wallet.EXW_Price | InstrumentID + DateFrom | Hourly price detail |
| EXW_Wallet.CryptoTypes | CryptoID = CryptoTypes.CryptoID | Full crypto metadata |
| EXW_Currency.Instruments | InstrumentID = Instruments.Id | Instrument details (buy/sell currencies) |

### 3.4 Gotchas

- **eToroInstrumentID is mostly NULL**: 83% of rows (344K/414K) have NULL eToroInstrumentID — these are wallet-only tokens not listed on the eToro trading platform.
- **InstrumentID is overloaded**: It equals eToroInstrumentID for platform-listed instruments (>=100000) or CryptoID for wallet-only tokens. Do not assume it matches EXW_Currency.Instruments.Id for all rows.
- **AvgPrice = 1.0 or 0.0 for inactive tokens**: Many older/inactive tokens show AvgPrice = 1.00000000 or 0E-8 — these are likely placeholder/gap-filled values from periods with no trading.
- **One row per CryptoID per day**: This is the daily snapshot (Rn=1). For hourly granularity, use `EXW_Wallet.EXW_Price`.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | No source traceable; reason given |
| Tier 4 | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Wallet instrument identifier. CASE logic: equals eToroInstrumentID when >= 100000 (eToro-listed), otherwise equals CryptoID (wallet-only). Derived from EXW_Currency.Instruments.Id via CryptoMarketRatesMappings join. (Tier 2 — EXW_Currency.Instruments / EXW_Wallet.CryptoMarketRatesMappings) |
| 2 | eToroInstrumentID | int | YES | eToro trading platform instrument identifier. Sourced from EXW_Wallet.CryptoTypes.InstrumentId. NULL for wallet-only tokens not listed on the eToro platform (~83% of rows). (Tier 2 — EXW_Wallet.CryptoTypes) |
| 3 | CryptoID | int | YES | Internal crypto asset identifier from EXW_Wallet.CryptoMarketRatesMappings. Distribution key. Used to uniquely identify each cryptocurrency across the wallet system. (Tier 2 — EXW_Wallet.CryptoMarketRatesMappings) |
| 4 | CryptoName | varchar(50) | YES | Cryptocurrency ticker symbol (e.g., BTC, ETH, CVC). Sourced as MarketRatesCurrencySymbol from EXW_Wallet.CryptoMarketRatesMappings. 173 distinct values. (Tier 2 — EXW_Wallet.CryptoMarketRatesMappings) |
| 5 | AvgPrice | decimal(38,8) | YES | Daily average price in USD. Computed as (BidRateAvg + AskRateAvg) / 2 from hourly rates in ETL_InstrumentRates_ByHour, taking the last hourly snapshot (ROW_NUMBER Rn=1 DESC by DateFrom). Gap-filled from prior hours or previous-day EXW_Price when missing. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 6 | BlockchainCryptoId | int | YES | Identifier of the underlying blockchain network for this crypto asset. Sourced from EXW_Wallet.CryptoTypes.BlockchainCryptoId. 12 distinct values (e.g., 1=BTC, 2=ETH). (Tier 3 — EXW_Wallet.CryptoTypes) |
| 7 | BlockchainCryptoName | varchar(50) | YES | Name of the underlying blockchain network (e.g., BTC, ETH, XRP, SOL). Sourced as CryptoTypes.Name via self-join on BlockchainCryptoId. 13 distinct values; ETH dominates at ~95% of rows. (Tier 2 — EXW_Wallet.CryptoTypes) |
| 8 | FullDate | date | YES | Calendar date for this daily price record. Derived as CAST(DateHour AS DATE) from ETL_InstrumentRates_ByHour.DateHour. Range: 2018-04-23 to present. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 9 | FullDateID | int | YES | Integer date key in YYYYMMDD format (e.g., 20250101). Derived as CONVERT(VARCHAR(8), DateHour, 112) from ETL_InstrumentRates_ByHour.DateHour. Part of the clustered index. (Tier 2 — EXW_Wallet.ETL_InstrumentRates_ByHour) |
| 10 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at INSERT time by SP_Prices. Indicates when this row was last written. (Tier 2 — EXW_Wallet.SP_Prices) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| InstrumentID | EXW_Currency.Instruments / CryptoMarketRatesMappings | Id / CryptoId | CASE: eToroInstrumentID >= 100000 → eToroInstrumentID, else CryptoId |
| eToroInstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | Passthrough |
| CryptoID | EXW_Wallet.CryptoMarketRatesMappings | CryptoId | Passthrough |
| CryptoName | EXW_Wallet.CryptoMarketRatesMappings | MarketRatesCurrencySymbol | Rename |
| AvgPrice | EXW_Wallet.ETL_InstrumentRates_ByHour | AskRateAvg, BidRateAvg | (Bid + Ask) / 2, Rn=1 last hour, gap-filled |
| BlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | Passthrough via mapping |
| BlockchainCryptoName | EXW_Wallet.CryptoTypes | Name | Rename (ct1.Name via BlockchainCryptoId self-join) |
| FullDate | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | CAST(DateHour AS DATE) |
| FullDateID | EXW_Wallet.ETL_InstrumentRates_ByHour | DateHour | CONVERT(VARCHAR(8), DateHour, 112) |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
EXW_Currency.Instruments + EXW_Currency.Currencies
  |-- JOIN on BuyCurrencyId / SellCurrencyId (WHERE sell = 'USD') --|
  v
#mapping (InstrumentID, eToroInstrumentID, CryptoId, CryptoName, BlockchainCryptoId, BlockchainCryptoName)
  |-- JOIN EXW_Wallet.CryptoMarketRatesMappings + EXW_Wallet.CryptoTypes --|
  v
EXW_Wallet.ETL_InstrumentRates_ByHour (hourly bid/ask averages)
  |-- JOIN #mapping ON InstrumentID --|
  v
#rates → #price → #pricesprep → #prices (gap-filled, ROW_NUMBER by CryptoId)
  |-- EXW_Wallet.SP_Prices @dt (daily DELETE+INSERT, Rn=1 filter) --|
  v
EXW_Wallet.EXW_PriceDaily (414K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CryptoID | EXW_Wallet.CryptoMarketRatesMappings | Crypto asset identifier |
| eToroInstrumentID | EXW_Wallet.CryptoTypes.InstrumentId | eToro platform instrument |
| BlockchainCryptoId | EXW_Wallet.CryptoTypes.CryptoID | Blockchain network identifier |
| InstrumentID | EXW_Currency.Instruments.Id | Wallet instrument |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| Unknown | — | No downstream consumers identified in bundle |

---

## 7. Sample Queries

### 7.1 Bitcoin Daily Price History (Last 30 Days)

```sql
SELECT FullDate, AvgPrice
FROM EXW_Wallet.EXW_PriceDaily
WHERE CryptoName = 'BTC'
  AND FullDate >= DATEADD(DAY, -30, GETDATE())
ORDER BY FullDate DESC;
```

### 7.2 All Crypto Prices on a Specific Date

```sql
SELECT CryptoName, BlockchainCryptoName, AvgPrice
FROM EXW_Wallet.EXW_PriceDaily
WHERE FullDate = '2025-04-01'
ORDER BY AvgPrice DESC;
```

### 7.3 Distinct Cryptos per Blockchain Network

```sql
SELECT BlockchainCryptoName,
       COUNT(DISTINCT CryptoID) AS crypto_count
FROM EXW_Wallet.EXW_PriceDaily
GROUP BY BlockchainCryptoName
ORDER BY crypto_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.EXW_PriceDaily | Type: Table | Production Source: Unknown (dormant)*
