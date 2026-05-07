# BI_DB_dbo.BI_DB_CreditRiskMatrix

**Schema**: BI_DB_dbo | **UC Target**: `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix`
**Row count**: ~480k (snapshot frozen at 2024-03-25 ~20:00–22:00 UTC) | **Refresh**: nominally hourly (Override) but **STALE since 2024-03-25**
**Distribution**: ROUND_ROBIN | **Clustered Index**: HedgeServerID

---

## 1. Business Meaning

Credit-risk **price-shock simulation matrix** at the (LP server, instrument, regulation, leverage, Buy/Sell) grain. For each open-position group, the table stores the aggregated client units NOP (`UnitsNOP`) plus what that NOP would become under symmetric ±N% bid/ask price shocks across 22 buckets in each direction:

```
+1% +2% +3% ... +9% +10% +15% +20% +25% +30% +40% +50% +60% +70% +80% +90% +100% +200% +300% +400% +900%
-1% -2% -3% ... -9% -10% -15% -20% -25% -30% -40% -50% -60% -70% -80% -90% -99% -100%
```

The bucketed `UnitsNOP±N%` columns represent the **post-shock client open-position units** if the underlying instrument's bid/ask were stressed by that percentage. Combined with the `Min/Max/Mean/Std_BankruptcyRate` aggregates, the matrix supports **margin-call / bankruptcy stress-testing** over the entire client book.

> ⚠️ **STALE TABLE** — last and only data window in production is `PositionsTime` between `2024-03-25 20:00:34` and `2024-03-25 22:00:09`, with `UpdateDate = 2024-03-26 00:49`. The hourly Override generic-pipeline mapping still runs but has not received new data since 2024-03-26. **Do not use for current credit-risk reporting.** Treat as a historical sample only.

---

## 2. Business Logic

### 2.1 Grouping Grain
Each row is one combination of `(HedgeServerID, InstrumentID, IsBuy, Leverage, Regulation, PositionsTime)`. `Bid`, `Ask`, `ConversionRate` are the prices/FX captured at `PositionsTime`. `UnitsNOP` is the aggregated client-side NOP in instrument units for that group.

### 2.2 Shock Bucket Construction
The `UnitsNOP+N%` and `UnitsNOP-N%` columns hold the simulated post-shock NOP. Where the shock would exceed the contractual margin/stop-out (e.g., position liquidated), the column is set to `0E-8` (literal zero). Rows where the shock pushes the position past bankruptcy threshold show zero clamping (visible in samples — high positive shocks for a buy position eventually saturate to zero on the negative side and vice versa).

### 2.3 BankruptcyRate Aggregates
`Min_BankruptcyRate`, `Max_BankruptcyRate`, `Mean_BankruptcyRate`, `Std_BankruptcyRate` summarize the distribution of bankruptcy-trigger price levels across the underlying client positions in the group. These reflect dispersion of margin-call thresholds — useful to estimate at what shock magnitude the group would start liquidating.

### 2.4 IsSettled Flag
Binary flag (0/1) indicating whether the group's positions are settled (cash-settled / closed) versus open. In the sample, all rows have `IsSettled = 0` (open positions only).

---

## 3. Query Advisory

### 3.1 Column Names Contain `+`, `-`, `%` — Bracket Required
All 44 shock-bucket columns use names like `[UnitsNOP+1%]`, `[UnitsNOP-50%]`. T-SQL **requires bracket quoting**. In Unity Catalog (Delta), the columns are exposed with their raw names — backtick or escape per Spark syntax.

### 3.2 Frozen Snapshot — Use Only for Historical
The table is effectively a **single-time snapshot** at `2024-03-25T22:00`. Any production credit-risk dashboard pointing here is likely showing stale data. Verify before relying on this table.

### 3.3 Pivot for Analysis
The shock buckets are **wide format** — for distribution charting, unpivot to (`bucket_name`, `bucket_value`). PowerBI/Spark `unpivot` patterns recommended.

### 3.4 ROUND_ROBIN Distribution + ClusteredIndex on HedgeServerID
Filter by `HedgeServerID` first to avoid full table scan. Joins to instrument/regulation dimensions will incur shuffle.

### 3.5 ConversionRate
Treat as the FX rate from instrument trade currency to USD (or the report currency) at `PositionsTime`. Multiply local-currency `UnitsNOP × Bid × ConversionRate` to get USD exposure.

---

## 4. Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | PositionsTime | datetime | Timestamp of the position snapshot used to compute the matrix (e.g., 2024-03-25 21:00). |
| 2 | HedgeServerID | int | LP/hedge server identifier — the eToro hedge book the positions belong to. |
| 3 | InstrumentID | int | eToro instrument identifier. Joins to `DWH_dbo.Dim_Instrument`. |
| 4 | InstrumentName | varchar(50) | Instrument display ticker (e.g., 'PII/USD', 'KNEBV/EUR'). |
| 5 | InstrumentType | varchar(50) | Instrument category — Stocks, ETF, Crypto, Currencies, Commodities, etc. |
| 6 | IsBuy | int | Direction flag — 1 = Buy/long aggregated NOP, 0 = Sell/short aggregated NOP. |
| 7 | Leverage | int | Leverage tier of the position bucket (1, 2, 5, 10, 30, etc). |
| 8 | Regulation | varchar(50) | Regulatory entity for the customer's account (CySEC, FCA, FSA Seychelles, ASIC, etc). |
| 9 | Region | varchar(50) | Geographic region grouping (often empty in sample). |
| 10 | Bid | decimal(16,6) | Instrument bid price at `PositionsTime` in instrument trade currency. |
| 11 | Ask | decimal(16,6) | Instrument ask price at `PositionsTime` in instrument trade currency. |
| 12 | ConversionRate | decimal(16,6) | FX rate from instrument trade currency to report currency (typically USD) at `PositionsTime`. |
| 13 | UnitsNOP | decimal(38,8) | Aggregated client-side net-open-position in instrument units for this (Server, Instrument, IsBuy, Leverage, Regulation) group. Sign carries direction. |
| 14 | UnitsNOP+1% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +1% from current. |
| 15 | UnitsNOP+2% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +2% from current. |
| 16 | UnitsNOP+3% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +3% from current. |
| 17 | UnitsNOP+4% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +4% from current. |
| 18 | UnitsNOP+5% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +5% from current. |
| 19 | UnitsNOP+6% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +6% from current. |
| 20 | UnitsNOP+7% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +7% from current. |
| 21 | UnitsNOP+8% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +8% from current. |
| 22 | UnitsNOP+9% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +9% from current. |
| 23 | UnitsNOP+10% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +10% from current. |
| 24 | UnitsNOP+15% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +15% from current. |
| 25 | UnitsNOP+20% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +20% from current. |
| 26 | UnitsNOP+25% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +25% from current. |
| 27 | UnitsNOP+30% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +30% from current. |
| 28 | UnitsNOP+40% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +40% from current. |
| 29 | UnitsNOP+50% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +50% from current. |
| 30 | UnitsNOP+60% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +60% from current. |
| 31 | UnitsNOP+70% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +70% from current. |
| 32 | UnitsNOP+80% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +80% from current. |
| 33 | UnitsNOP+90% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +90% from current. |
| 34 | UnitsNOP+100% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved +100% (price doubled) from current. |
| 35 | UnitsNOP+200% | decimal(38,8) | Simulated post-shock NOP at +200% price shock. |
| 36 | UnitsNOP+300% | decimal(38,8) | Simulated post-shock NOP at +300% price shock. |
| 37 | UnitsNOP+400% | decimal(38,8) | Simulated post-shock NOP at +400% price shock. |
| 38 | UnitsNOP+900% | decimal(38,8) | Simulated post-shock NOP at +900% price shock (extreme stress test). |
| 39 | UnitsNOP-1% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -1% from current. |
| 40 | UnitsNOP-2% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -2% from current. |
| 41 | UnitsNOP-3% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -3% from current. |
| 42 | UnitsNOP-4% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -4% from current. |
| 43 | UnitsNOP-5% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -5% from current. |
| 44 | UnitsNOP-6% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -6% from current. |
| 45 | UnitsNOP-7% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -7% from current. |
| 46 | UnitsNOP-8% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -8% from current. |
| 47 | UnitsNOP-9% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -9% from current. |
| 48 | UnitsNOP-10% | decimal(38,8) | Simulated post-shock NOP if Bid/Ask moved -10% from current. |
| 49 | UnitsNOP-15% | decimal(38,8) | Simulated post-shock NOP at -15% price shock. |
| 50 | UnitsNOP-20% | decimal(38,8) | Simulated post-shock NOP at -20% price shock. |
| 51 | UnitsNOP-25% | decimal(38,8) | Simulated post-shock NOP at -25% price shock. |
| 52 | UnitsNOP-30% | decimal(38,8) | Simulated post-shock NOP at -30% price shock. |
| 53 | UnitsNOP-40% | decimal(38,8) | Simulated post-shock NOP at -40% price shock. |
| 54 | UnitsNOP-50% | decimal(38,8) | Simulated post-shock NOP at -50% price shock. |
| 55 | UnitsNOP-60% | decimal(38,8) | Simulated post-shock NOP at -60% price shock. |
| 56 | UnitsNOP-70% | decimal(38,8) | Simulated post-shock NOP at -70% price shock. |
| 57 | UnitsNOP-80% | decimal(38,8) | Simulated post-shock NOP at -80% price shock. |
| 58 | UnitsNOP-90% | decimal(38,8) | Simulated post-shock NOP at -90% price shock. |
| 59 | UnitsNOP-99% | decimal(38,8) | Simulated post-shock NOP at -99% price shock (near-total drop). |
| 60 | UnitsNOP-100% | decimal(38,8) | Simulated post-shock NOP at -100% price shock (price → 0). |
| 61 | UpdateDate | datetime | Batch insert timestamp (GETDATE() at the time of writing). |
| 62 | IsSettled | int | Flag — 1 = closed/settled positions, 0 = open positions. Sample shows all 0. |
| 63 | Min_BankruptcyRate | decimal(16,6) | Minimum bankruptcy-trigger price rate across the underlying client positions in this group. |
| 64 | Max_BankruptcyRate | decimal(16,6) | Maximum bankruptcy-trigger price rate across the underlying client positions in this group. |
| 65 | Mean_BankruptcyRate | decimal(16,6) | Mean bankruptcy-trigger price rate across the underlying client positions. |
| 66 | Std_BankruptcyRate | decimal(16,6) | Standard deviation of bankruptcy-trigger price rates (NULL when only one position). |

---

## 5. Lineage

### 5.1 Source / Writer
No active SP populating this table is present in the current Synapse codebase. Migration scripts (`2024_09_22_*BI_DB_Migration.JUNK_BI_DB_CreditRiskMatrix.sql`) suggest the writer was deprecated or moved out of Synapse during the 2024 migration. The historical writer was an analytics SP/Python job in the legacy BI database that aggregated `BI_DB_PositionPnL` into shock buckets per LP server.

A sibling table `BI_DB_dbo.BI_DB_CreditRiskMatrix_History` exists in DDL — likely the historical archive.

### 5.2 Consumers
- Generic Pipeline (hourly Override) → `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix` (UC export still scheduled)

---

## 6. Status & Recommendation

| Property | Value |
|----------|-------|
| **Status** | **STALE / Snapshot frozen at 2024-03-25 22:00** |
| **Active writer present?** | No |
| **Replacement** | Refer to current credit-risk team for live exposure-matrix source (likely a Databricks notebook / external system) |
| **Recommendation** | Treat as historical reference. Do not power new dashboards from this table. |

---

*Generated as part of Wave 2 medium-priority documentation effort.*
