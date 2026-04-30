# Trade.HedgingCheckUsersEquity

> Computes realized and unrealized equity for a batch of CIDs. Uses three-path FX rate conversion (direct USD pair, USD/quote pair, or cross-currency via I2/I3 intermediaries) and spread-adjusted current prices to calculate open position P&L.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @CIDs (Typ_CID TVP); Output: CID, RealizedEquity, UnRealizedEquity |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgingCheckUsersEquity calculates **total equity** for a batch of customers: both the realized component (cash balance from Customer.CustomerMoney) and the unrealized component (mark-to-market P&L on open positions). The result supports hedging checks - i.e., verifying whether a customer's total equity is above margin thresholds for hedge eligibility.

The procedure handles **three-path FX conversion** to express P&L in USD:
1. **Direct USD sell pair** (e.g., EUR/USD where SellCurrencyID=1): use DollarRatio directly.
2. **USD buy pair** (e.g., USD/JPY where BuyCurrencyID=1): divide DollarRatio by current price (the USD is the base).
3. **Cross-currency pair** (neither buy nor sell is USD, e.g., EUR/GBP): use intermediate instruments I2 (SellCurrency->USD via direct pair) or I3 (USD->SellCurrency via inverse pair), falling back to 1.0 if no intermediary found.

The spread adjustment: `current_bid + SpreadedPipBid / POWER(10, Precision)` gives the actual quoted bid including the spread, matching how P&L is calculated in real-time.

Called by linked server accounts (LinkedSrvRO_WE_DB, LinkedSrvRO) indicating regional servers query this SP cross-server.

---

## 2. Business Logic

### 2.1 Data Preparation

**What**: Build temp tables for prices and positions.

**Rules**:
- #CID: CID list from @CIDs TVP, with UnRealizedEquity and RealizedEquity columns (initially NULL).
- #Price: `SELECT InstrumentID, Bid [RateBid], Ask [RateAsk] FROM Trade.CurrencyPrice` - current market prices snapshot.
- #positions: `SELECT from Trade.PositionTbl JOIN #CID ON PositionTbl.CID = CID` - all open positions for input CIDs.
- Clustered index on #positions.InstrumentID for subsequent UPDATE joins.

### 2.2 Instrument Rate Resolution (Three-Currency Path)

**What**: Populate #positions with current prices and cross-rate instruments.

**Rules**:
- I1 (direct): I1_RateBid/I1_RateAsk = price of the position's own instrument.
- I2 (cross via sell): An instrument where SellCurrencyID=Pair.SellCurrencyID AND BuyCurrencyID=1 (USD). Example: EUR/GBP position -> find EUR/USD as I2.
- I3 (cross via buy): An instrument where BuyCurrencyID=Pair.SellCurrencyID AND SellCurrencyID=1 (USD). Example: EUR/GBP -> if USD/EUR exists, use it as I3.
- Comment "This is so I won't get doubled records": LEFT JOINs on I2/I3 include `I2.InstrumentID <> Pair.InstrumentID` to prevent joining the original instrument to itself.

### 2.3 Unrealized P&L Calculation

**What**: Mark-to-market P&L per position, summed by CID.

**Rules (per position)**:
```
rate_diff =
  IsBuy=1: (I1_RateBid + SpreadedPipBid/POWER(10,Precision)) - InitForexRate
  IsBuy=0: InitForexRate - (I1_RateAsk + SpreadedPipAsk/POWER(10,Precision))

dollar_ratio_path:
  SellCurrencyID=1: Pair.DollarRatio (direct)
  BuyCurrencyID=1: Pair.DollarRatio / current_bid_ask (USD is base, divide by rate)
  cross-rate:
    COALESCE(
      I2.DollarRatio / (I2_RateBid + I2_Spread/POWER(10,I2_Precision)),  -- via sell->USD
      I3.DollarRatio * (I3_RateBid + I3_Spread/POWER(10,I3_Precision)),  -- via USD->sell
      1)                                                                  -- fallback

CalculatedNetProfit =
  (rate_diff * POWER(10, Precision) * dollar_ratio_path)
  / (TPTI.Benchmark / AmountInUnitsDecimal)
  AS DECIMAL(16,4)
```
- Groups by CID, SUM(CalculatedNetProfit) = UnrealizedPNL
- UPDATE #CID SET UnRealizedEquity = ISNULL(UnrealizedPNL, 0)

### 2.4 Realized Equity

**What**: Cash balance from Customer.CustomerMoney.

**Rules**:
- `UPDATE #CID SET RealizedEquity = ISNULL(M.RealizedEquity, 0) FROM Customer.CustomerMoney M WHERE M.CID = C.CID`

### 2.5 Result

**What**: Returns per-CID equity summary.

**Rules**:
- `SELECT CID, RealizedEquity, UnRealizedEquity FROM #CID`

---

## 3. Data Overview

N/A for stored procedure - returns computed per-CID equity data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | dbo.Typ_CID (TVP) | NO | READONLY | CODE-BACKED | Table-valued parameter. List of CIDs to compute equity for. Typ_CID is a table type with a single INT column (CID). |
| 2 | CID | INT | NO | - | CODE-BACKED | Output. Customer ID. |
| 3 | RealizedEquity | DECIMAL(16,6) | NO | 0 | CODE-BACKED | Output. Cash/realized balance from Customer.CustomerMoney.RealizedEquity. 0 if customer has no money record. |
| 4 | UnRealizedEquity | DECIMAL(16,6) | NO | 0 | CODE-BACKED | Output. Sum of mark-to-market P&L on all open positions. Uses spread-adjusted current prices with three-path FX conversion. 0 if no open positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (price snapshot) | Trade.CurrencyPrice | SELECT INTO #Price | Current bid/ask rates per instrument |
| @CIDs | Trade.PositionTbl | SELECT INTO #positions | Open positions for input CIDs |
| InstrumentID | Trade.Instrument | LEFT JOIN (x3) | Pair + I2 + I3 for FX path resolution |
| InstrumentID | Trade.ProviderToInstrument | LEFT JOIN (x3) | Precision + Benchmark for P&L calc |
| InstrumentID | Trade.GetSpreadGroup (SpreadGroupID=0) | LEFT JOIN (I2, I3) | Default spread for cross-currency intermediaries |
| CID | Customer.CustomerMoney | JOIN | Realized equity (cash balance) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| LinkedSrvRO_WE_DB | GRANT EXECUTE | Linked server access | Western Europe regional server queries equity |
| LinkedSrvRO | GRANT EXECUTE | Linked server access | Read-only linked server access |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgingCheckUsersEquity (procedure)
+-- dbo.Typ_CID (user-defined table type) [TVP parameter]
+-- Trade.CurrencyPrice (table) [current prices]
+-- Trade.PositionTbl (table) [open positions]
+-- Trade.Instrument (table) [FX pair metadata - x3 joins]
+-- Trade.ProviderToInstrument (table) [Precision, Benchmark - x3 joins]
+-- Trade.GetSpreadGroup (view) [default spread for cross-currency]
+-- Customer.CustomerMoney (x-schema table) [realized equity]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Typ_CID | User-defined table type | TVP parameter type definition |
| Trade.CurrencyPrice | Table | Current market prices snapshot |
| Trade.PositionTbl | Table | Open positions for input CIDs |
| Trade.Instrument | Table | Instrument FX metadata (SellCurrencyID, BuyCurrencyID, DollarRatio) |
| Trade.ProviderToInstrument | Table | Precision (pip scaling) + Benchmark (lot sizing) |
| Trade.GetSpreadGroup | View | Default spread group (SpreadGroupID=0) for cross-currency I2/I3 |
| Customer.CustomerMoney | Table | Realized equity (cash balance) per CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Linked server clients | External callers | Regional servers query customer equity for hedging checks |

---

## 7. Technical Details

### 7.1 Indexes

#positions gets a clustered index on InstrumentID (`CREATE CLUSTERED INDEX #b ON #positions (InstrumentID)`) for the UPDATE join performance.

### 7.2 Constraints

No transaction, no error handling. Note: LEFT JOINs on Trade.ProviderToInstrument without ProviderID filter - may return multiple rows per instrument if multiple providers are active. The lack of DISTINCT in the #positions INSERT and the multiple LEFT JOINs can produce duplicate position rows under certain data conditions.

---

## 8. Sample Queries

### 8.1 Check equity for specific CIDs

```sql
DECLARE @CIDList dbo.Typ_CID;
INSERT INTO @CIDList VALUES (123456), (789012), (345678);
EXEC Trade.HedgingCheckUsersEquity @CIDs = @CIDList;
```

### 8.2 Find customers with negative unrealized equity

```sql
DECLARE @CIDList dbo.Typ_CID;
INSERT INTO @CIDList
    SELECT CID FROM Trade.PositionTbl WITH (NOLOCK) WHERE InstrumentID = 1 GROUP BY CID;

-- Then interpret: CIDs where UnRealizedEquity + RealizedEquity < 0 are at risk
```

### 8.3 Check CurrencyPrice data freshness (affects accuracy)

```sql
SELECT TOP 5 InstrumentID, Bid, Ask, UpdateTime
FROM Trade.CurrencyPrice WITH (NOLOCK)
ORDER BY UpdateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: callers found, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgingCheckUsersEquity | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgingCheckUsersEquity.sql*
