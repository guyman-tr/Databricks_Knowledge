# Dealing_dbo.Dealing_MarketMakerAllTrade

> Daily market maker hedge trade log — every LP hedge execution on the eToro market maker with price, quantity, fees, and execution discrepancy flags.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `MarketMaker.dbo.HedgeTrades` (production) |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |

---

## 1. Business Meaning

This table records individual hedge trade executions from the market maker system. Each row is one hedge trade between eToro and an LP (liquidity provider) or exchange. It captures both the API-requested price/quantity and the actual executed values, enabling discrepancy analysis.

Source: `CopyFromLake.MarketMaker_dbo_HedgeTrades`, enriched with instrument names from `Dealing_staging.External_MarketMaker_dbo_Instruments` and exchange names from `External_MarketMaker_dbo_Exchanges`. Filtered: `OrderStatus NOT IN (2, 4)` (excludes cancelled/rejected orders).

Previously included an eToroX exchange section (loaded into `Dealing_MarketMakerAllTradeEtoroX`), which was removed in SR-239249 (2024-03-04). The eToroX table is now HOLD (deprecated).

Author: Adva, created 2022-05-02.

---

## 2. Business Logic

### 2.1 Price/Quantity Discrepancy Tracking

**What**: The table tracks differences between API-requested and actually executed prices and quantities.

**Columns Involved**: `Price`, `Quantity`, `ApiPrice`, `APiQuantity`, `ApiFunds`, `DIFF`

**Rules**:
- `Price` = API-requested price (HedgeTrades.ApiPrice)
- `ApiPrice` (confusingly named) = 0 when executed matches API; otherwise the actual ExecutedPrice
- `APiQuantity` = 0 when executed matches API; otherwise ExecutedQuantity
- `DIFF` flag: 'X' = prices or quantities differ, 'DB' = dealer-overridden (Price=-1), 'API' = API-only trade (no PartyName or User)

### 2.2 Value Calculation

**What**: Net monetary value of the trade.

**Columns Involved**: `Value`, `Unit`, `Fee`, `FeeCurrency`

**Rules**:
- `Unit` = signed quantity (negative for Sell, positive for Buy)
- `Value = Unit * -1 * Price - Fee` when FeeCurrency is USD or empty
- `Value = Unit * -1 * Price` when FeeCurrency is non-USD (fee excluded from USD value)

### 2.3 Side Mapping

**Columns Involved**: `Side`

**Rules**: `0` → 'Buy', `1` → 'Sell' (from HedgeTrades.Side integer)

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's hedge trades | `WHERE Date = @date` |
| Trades with execution discrepancies | `WHERE DIFF = 'X' AND Date = @date` |
| Dealer-overridden trades | `WHERE DIFF = 'DB' AND Date = @date` |
| Volume by exchange | `GROUP BY Name WHERE Date = @date` |
| Fee analysis | `WHERE Fee > 0 AND Date = @date` |

### 3.2 Gotchas

- **ApiPrice column is NOT the API price**: Despite its name, `ApiPrice` stores the executed price difference (0 = no difference, else the actual ExecutedPrice). The actual API-requested price is in the `Price` column.
- **char(50) padding**: Most text columns are `char(50)`, meaning they are space-padded. Use `RTRIM()` when comparing or displaying.
- **EtoroX deprecated**: The companion `Dealing_MarketMakerAllTradeEtoroX` table is HOLD/deprecated since SR-239249.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date. (Tier 2 — SP_MarketMakerAllTrade) |
| 2 | Id | int | YES | Hedge trade ID from MarketMaker.dbo.HedgeTrades. (Tier 2 — SP_MarketMakerAllTrade) |
| 3 | ExecutionTime | datetime | YES | When the hedge trade was executed. (Tier 2 — SP_MarketMakerAllTrade) |
| 4 | Instrument_Name | char(50) | YES | Instrument name from MarketMaker instruments. E.g., "BTC-USD". (Tier 2 — SP_MarketMakerAllTrade) |
| 5 | Name | char(50) | YES | Exchange/LP name from MarketMaker exchanges. E.g., "B2C2". (Tier 2 — SP_MarketMakerAllTrade) |
| 6 | Side | char(50) | YES | Trade direction: 'Buy' or 'Sell'. Mapped from Side integer (0=Buy, 1=Sell). (Tier 2 — SP_MarketMakerAllTrade) |
| 7 | Price | float | YES | API-requested execution price. From HedgeTrades.ApiPrice. (Tier 2 — SP_MarketMakerAllTrade) |
| 8 | Quantity | float | YES | API-requested quantity. From HedgeTrades.ApiQuantity. (Tier 2 — SP_MarketMakerAllTrade) |
| 9 | Funds | float | YES | Requested trade value. `ApiPrice * ApiQuantity`. (Tier 2 — SP_MarketMakerAllTrade) |
| 10 | ApiPrice | float | YES | **Execution price discrepancy**: 0 if executed at requested price, otherwise the actual ExecutedPrice. Confusingly named — this is NOT the API price. (Tier 2 — SP_MarketMakerAllTrade) |
| 11 | APiQuantity | float | YES | **Execution quantity discrepancy**: 0 if executed at requested quantity, otherwise ExecutedQuantity. (Tier 2 — SP_MarketMakerAllTrade) |
| 12 | ApiFunds | float | YES | **Execution funds discrepancy**: 0 if no price/qty difference, otherwise ExecutedPrice × ExecutedQuantity. (Tier 2 — SP_MarketMakerAllTrade) |
| 13 | Fee | float | YES | Trade fee. 0 when source Fee = -1 (unknown/not applicable). (Tier 2 — SP_MarketMakerAllTrade) |
| 14 | FeeCurrency | char(50) | YES | Currency of the fee. When non-USD, fee is excluded from Value calculation. (Tier 2 — SP_MarketMakerAllTrade) |
| 15 | PartyName | char(50) | YES | Counter-party name. NULL for API-only trades. (Tier 2 — SP_MarketMakerAllTrade) |
| 16 | InsertTime | datetime | YES | When the trade record was inserted into the source system. (Tier 2 — SP_MarketMakerAllTrade) |
| 17 | OrderId | char(70) | YES | Unique order identifier (UUID format). (Tier 2 — SP_MarketMakerAllTrade) |
| 18 | Unit | float | YES | Signed instrument units. Negative for Sell, positive for Buy. Uses ExecutedQuantity when ApiQuantity=-1. (Tier 2 — SP_MarketMakerAllTrade) |
| 19 | Value | float | YES | Net USD value of the trade. `Unit * -1 * Price - Fee` (USD fees) or `Unit * -1 * Price` (non-USD fees). (Tier 2 — SP_MarketMakerAllTrade) |
| 20 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()`. (Tier 2 — SP_MarketMakerAllTrade) |
| 21 | DIFF | char(20) | YES | Execution discrepancy flag. 'X'=price/qty difference between API and execution. 'DB'=dealer override (Price=-1 with non-zero ApiPrice). 'API'=no PartyName or User. NULL otherwise. (Tier 2 — SP_MarketMakerAllTrade) |
| 22 | Dealer | char(50) | YES | Trade executor username (HedgeTrades.User). NULL for automated trades. (Tier 2 — SP_MarketMakerAllTrade) |

---

## 5. Lineage

### 5.1 ETL Pipeline

```
MarketMaker.dbo.HedgeTrades → CopyFromLake → SP_MarketMakerAllTrade → Dealing_MarketMakerAllTrade
```

---

## 6. Relationships

### 6.1 Companion Objects

| Object | Relationship |
|--------|-------------|
| Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX | Deprecated (HOLD) — was loaded by same SP until SR-239249 |
| Dealing_dbo.Dealing_MarketMakerBoundaries_CFD | Related: boundaries define acceptable exposure ranges |
| Dealing_dbo.Dealing_MarketMakerBoundaries_Real | Related: boundaries define acceptable exposure ranges |

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 8/14*
*Tiers: 0 T1, 22 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_MarketMakerAllTrade | Type: Table | Production Source: MarketMaker.dbo.HedgeTrades*
