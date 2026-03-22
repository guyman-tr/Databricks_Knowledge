# Dealing_dbo.Dealing_CFDs_Stocks_Credit_Risk

> Daily credit risk stress-test report for CFD Stocks and ETFs hedged via JP Morgan and Goldman Sachs (HedgeServerID 2 and 101), showing client vs LP NOP, effective leverage, equity buffer, and scenario-based loss estimates at 10 price shock levels.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — LP netting + client CFD positions + commission history |
| **Refresh** | Daily |
| **Author** | Adar Cahlon (2021-08-19) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dealing_CFDs_Stocks_Credit_Risk is a daily credit risk monitoring table produced by `SP_CFDs_Stocks_Credit_Risk`. It answers the question: **"If stock prices drop (or rise) by X%, how much would eToro lose on client CFD positions that exceed their equity buffer?"**

The table focuses exclusively on CFD positions in Stocks and ETFs (InstrumentTypeID IN 5,6) hedged through JP Morgan (HedgeServerID=2) and Goldman Sachs (HedgeServerID=101). For each instrument, it computes:

1. **Client positions**: Long and short open position values, with NOP-weighted average effective leverage
2. **LP positions**: The corresponding LP hedge NOP (USD-converted)
3. **Net exposure**: Client NOP minus LP NOP — the unhedged gap
4. **Buffer**: The inverse of effective leverage (1/EffLev) — representing the fraction of equity buffer before margin call territory
5. **10 stress scenarios**: Estimated loss at price shocks of ±15%, ±20%, ±25%, ±30%, ±50%. If the buffer exceeds the shock %, the loss is 0 (buffer absorbs it); otherwise, loss = OP × (shock% - buffer)
6. **Commission context**: 30-day trailing commission revenue per instrument, for risk-vs-reward assessment

---

## 2. Business Logic

### 2.1 Effective Leverage and Buffer

**What**: Measures how leveraged client positions are and how much equity buffer exists.

**Columns Involved**: `EffLevLong`, `EffLevShort`, `Buffer_Long`, `Buffer_Short`

**Rules**:
- Per-position EffLev = `ABS(NOP) / (Amount + PositionPnL)` — ratio of notional to equity
- Instrument-level EffLev = NOP-weighted average: `SUM(ABS(NOP)*EffLev) / SUM(ABS(NOP))`
- Buffer = `1 / EffLev` — the price move fraction that equity can absorb
- Example: EffLev=2.0 → Buffer=0.50 → can absorb up to 50% price drop before going negative
- Instruments where Buffer_Long=0 OR Buffer_Short=0 are excluded (division by zero guard, SR-244076/SR-245341)

### 2.2 Stress Scenarios

**What**: Estimates potential losses at various price shock levels.

**Columns Involved**: `Scenario_1_-15%` through `Scenario_10_50%`

**Rules**:
- If Buffer ≥ shock%: Loss = 0 (equity absorbs the move)
- If Buffer < shock%: Loss = OP × (shock% - Buffer)
- Scenarios 1-4 and 9: Downside (affect longs) — use OPLong and Buffer_Long
- Scenarios 5-8 and 10: Upside (affect shorts) — use OPShort and Buffer_Short
- The naming convention embeds the shock direction: negative = price drop, positive = price rise

### 2.3 Scope Filter

**What**: Only JP/GS hedge servers, only CFD Stocks/ETF.

**Rules**:
- LP: HedgeServerID IN (2, 101) AND InstrumentTypeID IN (5, 6)
- Clients: IsSettled=0 (CFD only) AND IsValidCustomer=1 AND same instruments/servers as LP

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date. Filter by Date.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Instruments with largest -25% scenario loss | `WHERE Date = @Date ORDER BY [Scenario_3_-25%] DESC` |
| Top net exposure gaps | `WHERE Date = @Date ORDER BY ABS([NetExposure(Clients-LP)]) DESC` |
| Instruments where buffer < 20% | `WHERE Date = @Date AND Buffer_Long < 0.20` |
| Risk-to-revenue ratio | `WHERE Date = @Date` and compute `[Scenario_3_-25%] / NULLIF(Commissions30Days, 0)` |

### 3.3 Gotchas

- **Column names with special characters**: `[NetExposure(Clients-LP)]`, `[Scenario_1_-15%]`, etc. — always use brackets
- **Zero scenarios are expected**: Most instruments have buffer > 15-30%, so scenario values are often 0
- **Only 2 hedge servers**: This is NOT a platform-wide credit risk view — it covers JP (2) and GS (101) only
- **CFD only**: Real/settled positions are excluded from client NOP

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — SP_CFDs_Stocks_Credit_Risk)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date from SP `@Date` parameter. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 2 | InstrumentID | int | YES | Instrument identifier. Only includes instruments with LP positions on hedge servers 2 or 101. From `DWH_dbo.Dim_Instrument`. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 3 | InstrumentType | varchar(20) | YES | Asset class — only Stocks or ETF (InstrumentTypeID IN 5,6). From `Dim_Instrument.InstrumentType`. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 4 | InstrumentName | varchar(max) | YES | Instrument ticker name. Format: `TICKER/CURRENCY` e.g. `AMD.RTH/USD`. From `Dim_Instrument.Name`. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 5 | InstrumentDisplayName | varchar(max) | YES | Human-readable instrument name. From `Dim_Instrument.InstrumentDisplayName`. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 6 | OPLong | money | YES | Total client long open position value (absolute). `SUM(ABS(Clients_NOP))` where IsBuy=1, for CFD positions on servers 2/101, valid customers. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 7 | EffLevLong | decimal(16,6) | YES | NOP-weighted average effective leverage for long positions. `SUM(ABS(NOP)*EffLev)/SUM(ABS(NOP))` where EffLev=`ABS(NOP)/(Amount+PositionPnL)`. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 8 | OPShort | money | YES | Total client short open position value (absolute). `SUM(ABS(Clients_NOP))` where IsBuy=0. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 9 | EffLevShort | decimal(16,6) | YES | NOP-weighted average effective leverage for short positions. Same formula as EffLevLong but for shorts. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 10 | Clients_NOP | money | YES | Net client NOP (signed sum). `SUM(NOP)` from BI_DB_PositionPnL where IsSettled=0, IsValidCustomer=1, HedgeServerID IN (2,101). (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 11 | LP_NOP | money | YES | LP net open position (USD-converted). `SUM(Units*Price*(2*IsBuy-1)*FX_rate)` from netting data, HedgeServerID IN (2,101), InstrumentTypeID IN (5,6). (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 12 | NetExposure(Clients-LP) | money | YES | Unhedged gap: `Clients_NOP - LP_NOP`. Positive = eToro net long vs LP. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 13 | Buffer_Long | decimal(16,6) | YES | Equity buffer for longs: `1/EffLevLong`. Fraction of price drop that equity absorbs before going negative. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 14 | Buffer_Short | decimal(16,6) | YES | Equity buffer for shorts: `1/EffLevShort`. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 15 | Scenario_1_-15% | money | YES | Estimated loss if prices drop 15%. `CASE WHEN Buffer_Long>0.15 THEN 0 ELSE OPLong*(0.15-Buffer_Long) END`. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 16 | Scenario_2_-20% | money | YES | Estimated loss at -20%. Same pattern, threshold 0.20. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 17 | Scenario_3_-25% | money | YES | Estimated loss at -25%. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 18 | Scenario_4_-30% | money | YES | Estimated loss at -30%. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 19 | Scenario_5_15% | money | YES | Estimated short-side loss if prices rise 15%. Uses OPShort and Buffer_Short. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 20 | Scenario_6_20% | money | YES | Short-side loss at +20%. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 21 | Scenario_7_25% | money | YES | Short-side loss at +25%. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 22 | Scenario_8_30% | money | YES | Short-side loss at +30%. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 23 | Scenario_9_-50% | money | YES | Estimated loss at -50% price drop. Extreme downside scenario. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 24 | Scenario_10_50% | money | YES | Estimated short-side loss at +50% price rise. Extreme upside scenario. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 25 | UpdateDate | datetime | YES | ETL load timestamp — `GETDATE()`. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |
| 26 | Commissions30Days | money | YES | Sum of `RealizedCommission` from `Dealing_DailyZeroPnL_Stocks` for this instrument over trailing 30 days. Revenue context for risk assessment. (Tier 2 — SP_CFDs_Stocks_Credit_Risk) |

---

## 5. Lineage

Full lineage: see [Dealing_CFDs_Stocks_Credit_Risk.lineage.md](Dealing_CFDs_Stocks_Credit_Risk.lineage.md)

### 5.2 ETL Pipeline

| Step | Object | Description |
|------|--------|-------------|
| Source (LP) | etoro_History_Netting_History + etoro_Hedge_Netting | LP hedge netting, filtered to servers 2/101 |
| Source (LP) | Fact_CurrencyPriceWithSplit | Prices for USD NOP conversion |
| Source (Clients) | BI_DB_PositionPnL | CFD client positions (IsSettled=0) on servers 2/101 |
| Source (Clients) | Dim_Customer | IsValidCustomer filter |
| Source (shared) | Dim_Instrument | InstrumentType filter (5,6) and names |
| Source (commissions) | Dealing_DailyZeroPnL_Stocks | 30-day trailing commissions |
| ETL | SP_CFDs_Stocks_Credit_Risk | Compute EffLev, Buffer, Scenarios, join Commission |
| Target | Dealing_CFDs_Stocks_Credit_Risk | Daily per-instrument credit risk stress test |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument details and type |
| Commissions30Days | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | 30-day trailing commission revenue |

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 26 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 8/10*
*Object: Dealing_dbo.Dealing_CFDs_Stocks_Credit_Risk | Type: Table | Production Source: Derived (LP netting + client CFD positions)*
