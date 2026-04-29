# Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX

> **DORMANT / DROPPED** — ~5M-row eToroX crypto exchange trade log covering 2022-05-01 to 2024-02-20. Archived in `HOLD_Dealing_MarketMakerAllTradeEtoroX` after removal from active ETL on 2024-03-04 (SR-239249). Originally sourced from `CopyFromLake.MarketMaker_ExchangesData_Trades` via `SP_MarketMakerAllTrade`. No longer refreshed.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (archived as HOLD) |
| **Production Source** | `CopyFromLake.MarketMaker_ExchangesData_Trades` via `SP_MarketMakerAllTrade` (EtoroX section — commented out since 2024-03-04) |
| **Refresh** | None (dormant since 2024-03-04). Was daily DELETE+INSERT by @Date. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| **UC Target** | _Not_Migrated (dormant) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table stored eToroX crypto exchange trade records — the subset of market-maker hedge trades that were executed on the eToroX exchange platform. It was a companion to `Dealing_dbo.Dealing_MarketMakerAllTrade`, which tracked the main hedge trades from `CopyFromLake.MarketMaker_dbo_HedgeTrades`.

The table contained ~5M rows from 2022-05-01 to 2024-02-20. Each row represents a single trade execution on the eToroX exchange, recording instrument, side (Buy/Sell), price, quantity, fees, and the counterparty exchange name. The data was loaded daily by `SP_MarketMakerAllTrade` with a DELETE+INSERT pattern per date.

The EtoroX section of the SP was fully commented out on 2024-03-04 by Gili (SR-239249, "Removing [Dealing_dbo].[Dealing_MarketMakerAllTradeEtoroX]"). The original table was renamed to `HOLD_Dealing_MarketMakerAllTradeEtoroX` for archival. The HOLD table retains ~5M historical rows but receives no new data.

Name distribution: 65% "Aggregated", 35% "eToroX". PartyName distribution: ~52% etoro_cfd, ~46% eToro_Crypto_Spot, with small fractions for eToro_GER_Real, eToro_Real_IM, and etoro_MM_HBC_Real. Top instruments: LUNA-USD, BTC-USD, XRP-USD, ETH-USD, SOL-USD.

---

## 2. Business Logic

### 2.1 Trade Side Encoding

**What**: The Side column converts numeric exchange codes to human-readable labels.
**Columns Involved**: Side
**Rules**:
- 0 → 'Buy'
- 1 → 'Sell'

### 2.2 Sentinel Value Handling

**What**: Price, Quantity, and Fee use -1 as a sentinel for "no data" or "not applicable".
**Columns Involved**: Price, Quantity, Fee
**Rules**:
- -1 is converted to '0' in the SP CASE logic
- This affects downstream computations (Funds, Value, Unit)

### 2.3 Unit Sign Convention

**What**: Unit represents the signed quantity — negative for sells, positive for buys.
**Columns Involved**: Unit, Side, Quantity
**Rules**:
- Sell → Quantity × (-1)
- Buy → Quantity (positive)

### 2.4 Value Computation

**What**: Value represents the net trade value in the trade's settlement currency, accounting for fees.
**Columns Involved**: Value, Unit, Price, ApiPrice, Fee, FeeCurrency
**Rules**:
- If FeeCurrency is not NULL and not 'USD' and not blank: Value = Unit × (-1) × Price (or ApiPrice if Price = -1)
- Otherwise: Value = Unit × (-1) × Price - Fee (or ApiPrice if Price = -1)
- Fee is subtracted only when the fee is denominated in USD (empty FeeCurrency implies USD)

### 2.5 API vs Executed Price Comparison

**What**: The ApiPrice, APiQuantity, and ApiFunds columns in the SP's main (non-EtoroX) section track discrepancies between API-requested and executed values. In the EtoroX section, these columns are simple passthroughs from the source.
**Columns Involved**: ApiPrice, APiQuantity, ApiFunds
**Rules**:
- EtoroX variant: ApiPrice and ApiQuantity are passed through directly from the exchange
- ApiFunds = ApiPrice × ApiQuantity

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution is ROUND_ROBIN (no hash key), clustered on [Date] ASC. Date-filtered queries are efficient. Cross-distribution shuffles occur on any GROUP BY or JOIN — acceptable for a HOLD/archive table not used in active analytics.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Daily trade volume for a specific instrument | `WHERE Instrument_Name = 'BTC-USD' AND Date = '2023-01-15'` |
| Total value by exchange name | `GROUP BY Name WHERE Date BETWEEN ... AND ...` |
| Fee analysis by currency | `WHERE FeeCurrency <> '' GROUP BY FeeCurrency` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| Dealing_dbo.Dealing_MarketMakerAllTrade | Date, Id (approximate) | Compare eToroX trades with main hedge trades |

### 3.4 Gotchas

- **Table is dormant**: The active table was dropped; only `HOLD_Dealing_MarketMakerAllTradeEtoroX` remains. Query the HOLD table.
- **char(50) padding**: All string columns are fixed-width `char(50)` or `char(70)`. Use `RTRIM()` when comparing or displaying values.
- **-1 sentinel in source**: Price, Quantity, Fee may contain -1 in raw source but the SP converted these to '0' before insert. The HOLD data reflects the converted values.
- **FeeCurrency mostly blank**: ~99.9% of rows have blank FeeCurrency, implying USD-denominated fees. Non-USD fee currencies appear in ~6.5K rows.
- **No DIFF or Dealer columns**: Unlike the main `Dealing_MarketMakerAllTrade` table, the EtoroX variant does not have DIFF or Dealer columns.
- **TradeId format inconsistency**: Earlier rows (eToroX source) have GUID-format TradeIds; later rows (Aggregated source) have timestamp-format TradeIds like `231018-122908`.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Grounded in DDL + live data, no upstream wiki available |
| Tier 4 | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | The reporting date for the trade batch. Set from the SP @Date input parameter. Used as the clustered index key and DELETE+INSERT partition key for daily loads. (Tier 2 — SP_MarketMakerAllTrade) |
| 2 | Id | int | YES | Trade record identifier from the source exchange system (`MarketMaker_ExchangesData_Trades.Id`). Not guaranteed unique across dates. Sample values: 82991130, 79021348. (Tier 3 — CopyFromLake.MarketMaker_ExchangesData_Trades, no upstream wiki) |
| 3 | CreationTime | datetime | YES | Timestamp when the trade was created on the exchange platform. Passthrough from `MarketMaker_ExchangesData_Trades.CreationTime`. Millisecond precision. (Tier 3 — CopyFromLake.MarketMaker_ExchangesData_Trades, no upstream wiki) |
| 4 | Instrument_Name | char(50) | YES | Crypto instrument trading pair name (e.g., 'BTC-USD', 'ETH-USD', 'LUNA-USD'). Resolved via JOIN to `Dealing_staging.External_MarketMaker_dbo_Instruments` on InstrumentId. Top instruments: LUNA-USD, BTC-USD, XRP-USD, ETH-USD, SOL-USD. (Tier 3 — External_MarketMaker_dbo_Instruments.Name, no upstream wiki) |
| 5 | Name | char(50) | YES | Exchange or aggregation source name. Two values: 'Aggregated' (~65%) and 'eToroX' (~35%). Resolved via JOIN to `Dealing_staging.External_MarketMaker_dbo_Exchanges` on ExchangeId. (Tier 3 — External_MarketMaker_dbo_Exchanges.Name, no upstream wiki) |
| 6 | Side | char(50) | YES | Trade direction. ETL-transformed from numeric code: 0='Buy', 1='Sell'. Distribution: ~56% Sell, ~44% Buy. (Tier 2 — SP_MarketMakerAllTrade) |
| 7 | Price | float | YES | Execution price of the trade in the instrument's quote currency (USD). SP converts -1 sentinel to '0' indicating no price available. (Tier 2 — SP_MarketMakerAllTrade) |
| 8 | Quantity | float | YES | Number of units traded. SP converts -1 sentinel to '0' indicating no quantity available. (Tier 2 — SP_MarketMakerAllTrade) |
| 9 | Funds | float | YES | Gross trade value. ETL-computed as Price × Quantity. Represents the total notional value of the trade before fees. (Tier 2 — SP_MarketMakerAllTrade) |
| 10 | ApiPrice | float | YES | API-submitted price from the exchange. Passthrough from source. Value is -1 when no API price was provided. In the HOLD data, most rows show -1.0, indicating the exchange did not return a distinct API price. (Tier 3 — CopyFromLake.MarketMaker_ExchangesData_Trades, no upstream wiki) |
| 11 | APiQuantity | float | YES | API-submitted quantity from the exchange. Passthrough from source. Value is -1 when no API quantity was provided. Column name preserves original casing from source system ('APi' not 'Api'). (Tier 3 — CopyFromLake.MarketMaker_ExchangesData_Trades, no upstream wiki) |
| 12 | ApiFunds | float | YES | Gross value based on API prices. ETL-computed as ApiPrice × ApiQuantity. When both ApiPrice and ApiQuantity are -1, this equals 1.0 ((-1)×(-1)). (Tier 2 — SP_MarketMakerAllTrade) |
| 13 | Fee | float | YES | Trading fee charged for the transaction. SP converts -1 sentinel to '0'. In the HOLD data, most rows show 0.0 (no fee). (Tier 2 — SP_MarketMakerAllTrade) |
| 14 | FeeCurrency | char(50) | YES | Currency denomination of the fee. Blank/empty for ~99.9% of rows (implies USD). When populated, contains lowercase crypto ticker symbols (e.g., 'usd', 'btc', 'eth'). Drives the Value computation branching logic. (Tier 3 — CopyFromLake.MarketMaker_ExchangesData_Trades, no upstream wiki) |
| 15 | PartyName | char(50) | YES | Counterparty or execution venue name. 6 distinct values: 'etoro_cfd' (~52%), 'eToro_Crypto_Spot' (~46%), 'eToro_GER_Real', blank, 'eToro_Real_IM', 'etoro_MM_HBC_Real'. (Tier 3 — CopyFromLake.MarketMaker_ExchangesData_Trades, no upstream wiki) |
| 16 | InsertTime | datetime | YES | Timestamp when the trade record was inserted into the source system. Passthrough from `MarketMaker_ExchangesData_Trades.InsertTime`. Typically within seconds of CreationTime. (Tier 3 — CopyFromLake.MarketMaker_ExchangesData_Trades, no upstream wiki) |
| 17 | OrderId | char(70) | YES | Exchange order identifier. GUID format (e.g., '593f4471-e005-422f-983c-2cd457bb9a8b'). Passthrough from source. (Tier 3 — CopyFromLake.MarketMaker_ExchangesData_Trades, no upstream wiki) |
| 18 | TradeId | char(70) | YES | Exchange trade identifier. Mixed format: GUID for eToroX-sourced trades, timestamp-based (e.g., '231018-122908') for Aggregated-sourced trades. Passthrough from source. (Tier 3 — CopyFromLake.MarketMaker_ExchangesData_Trades, no upstream wiki) |
| 19 | Unit | float | YES | Signed trade quantity. ETL-computed: Sell → Quantity × (-1), Buy → Quantity (positive). Represents the net position change from the trade. (Tier 2 — SP_MarketMakerAllTrade) |
| 20 | Value | float | YES | Net trade value in settlement currency. ETL-computed with FeeCurrency branching: when FeeCurrency is non-USD, Value = Unit × (-1) × Price (or ApiPrice if Price = -1); when FeeCurrency is blank/USD, Value = Unit × (-1) × Price - Fee. Represents the cash impact of the trade. (Tier 2 — SP_MarketMakerAllTrade) |
| 21 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at insert time by the SP. Indicates when the row was written to Synapse, not when the trade occurred. (Tier 2 — SP_MarketMakerAllTrade) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Date | SP parameter | @Date | Direct assignment |
| Id | MarketMaker_ExchangesData_Trades | Id | Passthrough |
| CreationTime | MarketMaker_ExchangesData_Trades | CreationTime | Passthrough |
| Instrument_Name | External_MarketMaker_dbo_Instruments | Name | JOIN on InstrumentId |
| Name | External_MarketMaker_dbo_Exchanges | Name | JOIN on ExchangeId |
| Side | MarketMaker_ExchangesData_Trades | Side | CASE: 0→Buy, 1→Sell |
| Price | MarketMaker_ExchangesData_Trades | Price | CASE: -1→0 |
| Quantity | MarketMaker_ExchangesData_Trades | Quantity | CASE: -1→0 |
| Funds | MarketMaker_ExchangesData_Trades | Price, Quantity | Price × Quantity |
| ApiPrice | MarketMaker_ExchangesData_Trades | ApiPrice | Passthrough |
| APiQuantity | MarketMaker_ExchangesData_Trades | ApiQuantity | Passthrough |
| ApiFunds | MarketMaker_ExchangesData_Trades | ApiPrice, ApiQuantity | ApiPrice × ApiQuantity |
| Fee | MarketMaker_ExchangesData_Trades | Fee | CASE: -1→0 |
| FeeCurrency | MarketMaker_ExchangesData_Trades | FeeCurrency | Passthrough |
| PartyName | MarketMaker_ExchangesData_Trades | PartyName | Passthrough |
| InsertTime | MarketMaker_ExchangesData_Trades | InsertTime | Passthrough |
| OrderId | MarketMaker_ExchangesData_Trades | OrderId | Passthrough |
| TradeId | MarketMaker_ExchangesData_Trades | TradeId | Passthrough |
| Unit | MarketMaker_ExchangesData_Trades | Quantity, Side | Side-adjusted sign |
| Value | MarketMaker_ExchangesData_Trades | Unit, Price, Fee, FeeCurrency | Complex formula |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
MarketMaker.ExchangesData.Trades (eToroX exchange, production)
  |-- Generic Pipeline (Bronze lake export) ---|
  v
CopyFromLake.MarketMaker_ExchangesData_Trades (Synapse staging)
  |
  |  Dealing_staging.External_MarketMaker_dbo_Instruments (instrument lookup)
  |  Dealing_staging.External_MarketMaker_dbo_Exchanges   (exchange lookup)
  |
  |-- SP_MarketMakerAllTrade @Date (daily DELETE+INSERT) ---|
  v
Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX (~5M rows, 2022-05 to 2024-02)
  |
  |-- DROPPED 2024-03-04 (SR-239249) ---|
  v
Dealing_dbo.HOLD_Dealing_MarketMakerAllTradeEtoroX (archive, no refresh)
  |
  (No UC migration — _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| Instrument_Name | Dealing_staging.External_MarketMaker_dbo_Instruments | Resolved via JOIN on InstrumentId in SP |
| Name | Dealing_staging.External_MarketMaker_dbo_Exchanges | Resolved via JOIN on ExchangeId in SP |

### 6.2 Referenced By (other objects point to this)

No known consumers. The table was dropped from active use on 2024-03-04.

---

## 7. Sample Queries

### 7.1 Daily trade volume and value by instrument

```sql
SELECT
    Date,
    RTRIM(Instrument_Name) AS Instrument,
    COUNT(*) AS TradeCount,
    SUM(Funds) AS GrossValue,
    SUM(Value) AS NetValue
FROM [Dealing_dbo].[HOLD_Dealing_MarketMakerAllTradeEtoroX]
WHERE Date = '2023-06-15'
GROUP BY Date, Instrument_Name
ORDER BY TradeCount DESC;
```

### 7.2 Buy vs Sell breakdown by exchange source

```sql
SELECT
    RTRIM(Name) AS ExchangeSource,
    RTRIM(Side) AS Side,
    COUNT(*) AS TradeCount,
    SUM(ABS(Unit)) AS TotalUnits
FROM [Dealing_dbo].[HOLD_Dealing_MarketMakerAllTradeEtoroX]
WHERE Date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY Name, Side
ORDER BY Name, Side;
```

### 7.3 Trades with non-USD fees

```sql
SELECT TOP 20
    Date,
    RTRIM(Instrument_Name) AS Instrument,
    RTRIM(FeeCurrency) AS FeeCurrency,
    Fee,
    Price,
    Quantity,
    Value
FROM [Dealing_dbo].[HOLD_Dealing_MarketMakerAllTradeEtoroX]
WHERE FeeCurrency <> '' AND FeeCurrency IS NOT NULL
ORDER BY Date DESC;
```

---

## 8. Atlassian Knowledge Sources

No table-specific Confluence pages or Jira tickets found. General Market Maker documentation exists in the EMM Confluence space but does not reference this specific table.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 9 T2, 12 T3, 0 T4, 0 T5 | Elements: 21/21, Logic: 7/10, Lineage: 8/10*
*Object: Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX | Type: Table (archived HOLD) | Production Source: CopyFromLake.MarketMaker_ExchangesData_Trades via SP_MarketMakerAllTrade (dormant)*
