# Dealing_dbo.Dealing_LP_StocksNOP

> Daily LP (Liquidity Provider) net open position and trading volume report by hedge server, instrument type, and settlement mode — used alongside client capital adequacy for regulatory risk analysis.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — LP netting history + hedge execution logs |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dealing_LP_StocksNOP tracks the daily net open position (NOP) and intraday trading volume of eToro's Liquidity Providers across 57 hedge servers and 6 instrument types (Stocks, ETF, Currencies, Commodities, Indices, Crypto). It is the LP-side counterpart to `Dealing_ClientsCapitalAdequacy`, which tracks client-side positions.

Together, these two tables enable the Dealing desk and Risk team to compare client exposure versus LP hedged exposure — identifying potential imbalances. The table is produced by `SP_Capital_Adequacy_IFR_KPMG` as part of the IFR regulatory capital adequacy calculation.

Key features:
- **NOP values are USD-converted** using a multi-step FX conversion via `Fact_CurrencyPriceWithSplit` — unlike the client table which uses native currency NOP
- **LP Volume** (buy/sell) is only populated for HedgeServerID=81 (Real Stocks server); all other servers get 0
- **Real/CFD** is determined by a hardcoded hedge server list, not by position attributes
- Netting data comes from temporal history (`etoro_History_Netting_History` with SysStartTime/SysEndTime) unioned with current state (`etoro_Hedge_Netting`), then deduplicated to latest per server+instrument

---

## 2. Business Logic

### 2.1 LP NOP Calculation

**What**: Computes the notional value of LP open positions by converting units to USD using Bid/Ask prices and multi-step FX rates.

**Columns Involved**: `OPLong`, `OPShort`

**Rules**:
- OPLong = `Units * Bid * (2*IsBuy-1) * FX_rate` when IsBuy=1, else 0
- OPShort = `Units * Ask * (2*IsBuy-1) * FX_rate` when IsBuy=0, else 0
- FX conversion cascade to CurrencyID=1 (USD):
  1. If SellCurrencyID=1: rate=1.00 (already USD)
  2. If BuyCurrencyID=1: rate=1.00/price (inverse)
  3. If neither: cross via intermediate currency pair
- Aggregated by HedgeServerID + InstrumentType + Real/CFD
- Excluded hedge servers: 101, 221, 223, 224, 225, 226, 5000

### 2.2 LP Volume (Execution Volume)

**What**: Captures the LP's daily executed trading volume.

**Columns Involved**: `LP_VolumeBuy`, `LP_VolumeSell`

**Rules**:
- Only populated for HedgeServerID=81 (Real Stocks hedge server)
- Volume = `SUM(Units * ExecutionRate)` from Etoro_Hedge_ExecutionLog
- Only successful executions (Success=1) for the target date
- All other hedge servers get LP_VolumeBuy=0, LP_VolumeSell=0

### 2.3 Real/CFD Server Mapping

**What**: Determines settlement mode based on hedge server identity.

**Columns Involved**: `Real/CFD`

**Rules**:
- Real = HedgeServerID IN (3, 9, 102, 112, 125, 126, 81)
- CFD = all other hedge servers
- This is a hardcoded mapping in the SP, not derived from position attributes

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on Date. Always filter by `Date`. ~102K rows total.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| LP exposure by instrument type | `WHERE Date = @Date GROUP BY InstrumentType` |
| Compare LP vs Client exposure | JOIN `Dealing_ClientsCapitalAdequacy` on Date + InstrumentType + Real/CFD |
| Find servers with largest exposure | `WHERE Date = @Date ORDER BY ABS(OPLong) + ABS(OPShort) DESC` |
| LP trading volume (Real Stocks only) | `WHERE Date = @Date AND HedgeServerID = 81` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_dbo.Dealing_ClientsCapitalAdequacy | ON Date AND InstrumentType AND [Real/CFD] | Compare client vs LP exposure |
| Dealing_dbo.Dealing_NOP_LPandClients | ON Date | Overall NOP reconciliation |

### 3.4 Gotchas

- **OPShort is negative** — LP short positions carry negative NOP values (unlike `Dealing_ClientsCapitalAdequacy` where short is absolute)
- **LP_VolumeBuy/Sell** are only non-zero for HedgeServerID=81 — do not use for other servers
- **Real/CFD** is server-based, not position-based — different logic than `Dealing_ClientsCapitalAdequacy` where it derives from `IsSettled`
- Many rows show `LP_VolumeBuy=0, LP_VolumeSell=0` for non-81 hedge servers — this is expected, not missing data
- Quote the `[Real/CFD]` column in all queries

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — SP_Capital_Adequacy_IFR_KPMG)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date. Set from SP `@Date` parameter. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 2 | HedgeServerID | int | YES | LP hedge server identifier. From `etoro_History_Netting_History` / `etoro_Hedge_Netting`, deduplicated to latest netting state per server+instrument. 57 distinct servers in production. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 3 | InstrumentType | varchar(100) | YES | Asset class. From `DWH_dbo.Dim_Instrument.InstrumentType` via InstrumentID JOIN on netting data. Values: Stocks, ETF, Currencies, Commodities, Indices, Crypto Currencies. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 4 | Real/CFD | varchar(50) | YES | Settlement mode determined by hedge server. `CASE WHEN HedgeServerID IN (3,9,102,112,125,126,81) THEN 'Real' ELSE 'CFD' END`. Hardcoded server mapping. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 5 | UpdateDate | datetime | NO | ETL load timestamp — `GETDATE()` at SP execution. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 6 | LP_VolumeBuy | money | YES | LP buy execution volume for the day. `SUM(Units*ExecutionRate)` where IsBuy=1 from `Etoro_Hedge_ExecutionLog` where Success=1. Only populated for HedgeServerID=81; 0 for all other servers. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 7 | LP_VolumeSell | money | YES | LP sell execution volume for the day. `SUM(Units*ExecutionRate)` where IsBuy=0 from `Etoro_Hedge_ExecutionLog` where Success=1. Only populated for HedgeServerID=81; 0 for all other servers. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 8 | OPLong | money | YES | LP long open position value in USD. `SUM(Units*Bid*(2*IsBuy-1)*FX_rate)` where IsBuy=1, from hedge netting data. Multi-step FX conversion to CurrencyID=1 (USD). Excludes servers 101,221,223-226,5000. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |
| 9 | OPShort | money | YES | LP short open position value in USD (negative). `SUM(Units*Ask*(2*IsBuy-1)*FX_rate)` where IsBuy=0. Multi-step FX conversion to USD. Values are negative for short positions. (Tier 2 — SP_Capital_Adequacy_IFR_KPMG) |

---

## 5. Lineage

### 5.1 Production Sources

Hedge netting data comes from production dealing system: `etoro_History_Netting_History` (temporal) and `etoro_Hedge_Netting` (current state), ingested via staging layer.

Full lineage: see [Dealing_LP_StocksNOP.lineage.md](Dealing_LP_StocksNOP.lineage.md)

### 5.2 ETL Pipeline

```
etoro_History_Netting_History ──┐
etoro_Hedge_Netting ────────────┤──► #hedge ──► #hedge1 (dedup) ──► #LP (NOP calc) ──► #temp_NOP (agg)──┐
Fact_CurrencyPriceWithSplit ────┤                                                                        ├──► #temp ──► Dealing_LP_StocksNOP
Dim_Instrument ─────────────────┘                                                                        │
Etoro_Hedge_ExecutionLog ──────────────────────────────────────────────── #LPVolume ─────────────────────┘
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro_History_Netting_History | Historical hedge netting snapshots (temporal SCD2) |
| Source | etoro_Hedge_Netting | Current hedge netting state |
| Source | Fact_CurrencyPriceWithSplit | Bid/Ask prices and currency pair data for NOP valuation |
| Source | Dim_Instrument | Instrument type classification |
| Source | Etoro_Hedge_ExecutionLog | LP execution logs (Volume, only HedgeServerID=81) |
| ETL | SP_Capital_Adequacy_IFR_KPMG | Deduplicates netting, calculates USD NOP, aggregates by server/instrument/mode |
| Target | Dealing_LP_StocksNOP | Daily LP NOP and volume by hedge server |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentType | DWH_dbo.Dim_Instrument | Instrument asset class |
| HedgeServerID | Production Dealing System | LP hedge server identity |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_ClientsCapitalAdequacy | Date, InstrumentType, Real/CFD | Paired table for client-vs-LP risk comparison |

---

## 7. Sample Queries

### 7.1 Total LP NOP by instrument type for latest date

```sql
SELECT InstrumentType,
    SUM(OPLong) AS Total_LP_Long,
    SUM(OPShort) AS Total_LP_Short,
    SUM(OPLong) + SUM(OPShort) AS Net_Exposure
FROM Dealing_dbo.Dealing_LP_StocksNOP
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_LP_StocksNOP)
GROUP BY InstrumentType
ORDER BY ABS(SUM(OPLong) + SUM(OPShort)) DESC;
```

### 7.2 Client vs LP exposure comparison

```sql
SELECT c.InstrumentType, c.[Real/CFD],
    SUM(c.Clients_Long_OP) AS Client_Long,
    SUM(c.Clients_Short_OP) AS Client_Short,
    SUM(l.OPLong) AS LP_Long,
    SUM(l.OPShort) AS LP_Short
FROM Dealing_dbo.Dealing_ClientsCapitalAdequacy c
JOIN Dealing_dbo.Dealing_LP_StocksNOP l
    ON c.Date = l.Date AND c.InstrumentType = l.InstrumentType AND c.[Real/CFD] = l.[Real/CFD]
WHERE c.Date = '2026-03-10'
GROUP BY c.InstrumentType, c.[Real/CFD];
```

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 9 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_LP_StocksNOP | Type: Table | Production Source: Derived (staging netting + execution logs)*
