# History.ExecutionRequestBreakdownLog

> Legacy archived version of the hedge execution request log - records that a hedge order was sent to a liquidity provider (capturing both eToro's internal price and the provider's quoted price at request time). Superseded by Hedge.ExecutionRequestBreakdownLog (which added ExposureID and MarketPriceRateID columns).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | EntryID (int, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (NONCLUSTERED PK on EntryID, CLUSTERED on Occurred) |

---

## 1. Business Meaning

This table is a **legacy archive of hedge execution request records**, representing the original version of `Hedge.ExecutionRequestBreakdownLog` before the `ExposureID` and `MarketPriceRateID` columns were added (circa 2012 per the SP change log). The active table is now `Hedge.ExecutionRequestBreakdownLog`.

Each row represents a single **hedge order request event**: when eToro's hedge engine sent an order to a liquidity provider (LP) to open or close a hedge position for a specific instrument. The record captures:
- **Which request**: HedgeID, InstrumentID, HedgeServerID, LiquidityAccountID
- **When**: Occurred (UTC, default = GETUTCDATE()), OccurredAtServer (hedge server timestamp)
- **What**: AmountInUnits, IsBuy, IsManualRequest
- **Price snapshot at request time**: eToro's internal bid/ask AND the LP's quoted bid/ask

The price comparison columns (`eToroPriceBid`, `eToroPriceAsk` vs `ProviderPriceBid`, `ProviderPriceAsk`) enable **Transaction Cost Analysis (TCA)** - measuring the difference between the price eToro observed internally and the price the LP quoted/executed, to evaluate LP execution quality.

**Relationship to Hedge schema**:
- `Hedge.ExecutionRequestBreakdownLog` is the current active table (16 columns including ExposureID, MarketPriceRateID)
- `History.ExecutionRequestBreakdownLog` is the legacy version (14 columns, no ExposureID or MarketPriceRateID)
- `Hedge.LogHedgeExecutionRequest` SP writes to `Hedge.ExecutionRequestBreakdownLog` (not this table)
- This History table is no longer written by any SP in SSDT

The table has **0 rows** in this staging environment.

---

## 2. Business Logic

### 2.1 Hedge Execution Request Logging

**What**: When the hedge engine sends an order to an LP, it calls `Hedge.LogHedgeExecutionRequest` which logs the event with a real-time price snapshot.

**Columns/Parameters Involved**: All columns

**Rules** (from `Hedge.LogHedgeExecutionRequest` and the equivalent Hedge version):
- `eToroPriceBid` / `eToroPriceAsk`: Retrieved from `Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID` at the moment of logging - eToro's live internal price.
- `ProviderPriceBid` / `ProviderPriceAsk`: Passed in by the hedge engine - the LP's quoted price at the time of the request.
- `Occurred`: Defaults to `GETUTCDATE()` on INSERT - when the log record was written.
- `OccurredAtServer`: Passed explicitly - the hedge server's own timestamp when it processed the request.
- `IsManualRequest = 1`: Request was triggered manually by a hedge operator.
- `IsManualRequest = 0`: Request was generated automatically by the hedge engine.

### 2.2 TCA (Transaction Cost Analysis) Use Case

**What**: Request records are joined with response records to measure LP execution quality.

**Columns/Parameters Involved**: `eToroPriceBid`, `eToroPriceAsk`, `ProviderPriceBid`, `ProviderPriceAsk`, `HedgeID`

**Rules** (from `Hedge.Report_TCA` and `Hedge.Report_TCA_Test`):
- Request and response logs are FULL JOINed on `HedgeID` to pair each request with its response.
- Price slippage = difference between `eToroPriceBid`/`eToroPriceAsk` (what eToro saw) and the LP's execution price (from the response record).
- If a request has no matching response, the hedge order was not confirmed.
- TCA reports compute aggregated statistics per LP account and instrument over a time window.

### 2.3 Legacy Status - Schema Migration

**What**: This table was the original log destination before the Hedge schema version was created.

**Rules**:
- Per the `Hedge.LogHedgeExecutionRequest` change log comment: "2-9-2012 Yitzchak Wahnon - Change MarketPriceRateID and PriceRateID to BIGINT instead of INT" - this change was made to the Hedge version.
- The History version lacks `ExposureID` (int NULL) and `MarketPriceRateID` (bigint NULL) columns that exist in the Hedge version.
- All current SP readers (`Hedge.InsertKPIData`, `Hedge.Report_TCA`, `Hedge.Report_TCA_Test`) reference `Hedge.ExecutionRequestBreakdownLog`, not this table.
- The History version is retained for reference to pre-2012 execution data; it receives no new rows.

### 2.4 HedgeID as the Request-Response Correlation Key

**What**: `HedgeID` links each request to its corresponding response in `Hedge.ExecutionResponseBreakdownLog`.

**Rules**:
- One `HedgeID` -> one request record + (ideally) one response record.
- If the LP executed the order, there is a matching `Hedge.ExecutionResponseBreakdownLog` row with the same `HedgeID`.
- If no response row exists, the order was either rejected, timed out, or not acknowledged.
- `Hedge.InsertKPIData` counts successes as `(request records) JOIN (response records) ON HedgeID`.

---

## 3. Data Overview

The table contains **0 rows** in this staging environment. In production, this table would contain historical records from before the schema migration (pre-2012) when logging was moved to `Hedge.ExecutionRequestBreakdownLog`. A representative row:

| EntryID | HedgeID | InstrumentID | HedgeServerID | LiquidityAccountID | Occurred | AmountInUnits | IsBuy | IsManualRequest | eToroPriceBid | eToroPriceAsk | ProviderPriceBid | ProviderPriceAsk |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 100001 | 55432 | 4 (NASDAQ) | 3 | 12 | 2011-06-15 14:23:11 | 150000.000000 | 1 | 0 | 3245.10 | 3245.20 | 3245.08 | 3245.18 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EntryID | int | NO | - | CODE-BACKED | Surrogate PK. IDENTITY(1,1) in the Hedge version (NOT FOR REPLICATION); carried as-is in this archive. NONCLUSTERED PK allows the CLUSTERED index to be on Occurred for time-series access. |
| 2 | HedgeID | int | NO | - | CODE-BACKED | The hedge execution event identifier. Links this request to its response in History/Hedge.ExecutionResponseBreakdownLog and to the hedge engine's execution record. One HedgeID = one order sent to one LP. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | The instrument being hedged (e.g., AAPL, EURUSD). Used for TCA analysis by instrument and for KPI aggregation by instrument per hedge server. |
| 4 | HedgeServerID | int | NO | - | VERIFIED | The hedge server that processed this execution request. FK to Trade.HedgeServer (FK_ExecutionRequestBreakdownLog_HedgeServer). Used to attribute KPI metrics per hedge server instance. |
| 5 | LiquidityAccountID | int | NO | - | VERIFIED | The liquidity provider account that received this order. FK to Trade.LiquidityAccounts (FK_ExecutionRequestBreakdownLog_LiquidityAccounts). Used to evaluate per-LP execution quality. |
| 6 | Occurred | datetime | NO | - | VERIFIED | UTC datetime when this log record was inserted (default = GETUTCDATE()). CLUSTERED index leading column - primary access pattern is time-range queries. Used as the time dimension for TCA and KPI reports. |
| 7 | OccurredAtServer | datetime | NO | - | VERIFIED | The hedge server's own timestamp when it processed the execution request. May differ slightly from Occurred due to network/insert latency. Used for latency analysis between server event and log write. |
| 8 | AmountInUnits | decimal(16,6) | NO | - | VERIFIED | The order size in instrument units (e.g., shares, contracts). 6 decimal places supports fractional unit hedging. Used in KPI aggregation to sum total volume hedged per server/instrument. |
| 9 | IsBuy | bit | NO | - | VERIFIED | 1 = buy order (eToro hedging a net short position), 0 = sell order (eToro hedging a net long position). |
| 10 | IsManualRequest | bit | NO | - | VERIFIED | 1 = hedge operator manually triggered this order (override/intervention), 0 = automated hedge engine decision. Manual requests appear in TCA reports and may indicate market stress conditions. |
| 11 | eToroPriceBid | decimal(16,8) | NO | - | VERIFIED | eToro's internal bid price at the moment the request was logged. Sourced from Trade.CurrencyPrice for the instrument. 8 decimal places for forex precision. Used as TCA baseline. |
| 12 | eToroPriceAsk | decimal(16,8) | NO | - | VERIFIED | eToro's internal ask price at the moment the request was logged. Sourced from Trade.CurrencyPrice for the instrument. Used as TCA baseline for buy orders. |
| 13 | ProviderPriceBid | decimal(16,8) | NO | - | VERIFIED | The LP's quoted bid price at the time the request was sent. Passed in by the hedge engine. Compared to eToroPriceBid to measure bid-side price discrepancy. |
| 14 | ProviderPriceAsk | decimal(16,8) | NO | - | VERIFIED | The LP's quoted ask price at the time the request was sent. Passed in by the hedge engine. Compared to eToroPriceAsk to measure ask-side price discrepancy. |

**Missing columns** (present in `Hedge.ExecutionRequestBreakdownLog` but NOT in this legacy version):
- `ExposureID` (int NULL) - links the request to a net open exposure record
- `MarketPriceRateID` (bigint NULL) - the market price rate snapshot ID at request time

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (FK_ExecutionRequestBreakdownLog_HedgeServer) | The hedge server that sent this execution request |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_ExecutionRequestBreakdownLog_LiquidityAccounts) | The LP account that received the order |
| HedgeID | Hedge.ExecutionResponseBreakdownLog | Implicit | The corresponding response record for this request |
| InstrumentID | Trade.InstrumentMetaData | Implicit | The instrument being hedged |

### 5.2 Referenced By (other objects point to this)

No objects in SSDT reference this History table. All current readers use `Hedge.ExecutionRequestBreakdownLog`.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExecutionRequestBreakdownLog (table)
- Legacy archive - receives no new data
- Equivalent (older) version of Hedge.ExecutionRequestBreakdownLog
- FK deps: Trade.HedgeServer, Trade.LiquidityAccounts

Active version: Hedge.ExecutionRequestBreakdownLog
- Written by: Hedge.LogHedgeExecutionRequest (SP)
- Read by: Hedge.InsertKPIData, Hedge.Report_TCA, Hedge.Report_TCA_Test
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK - HedgeServerID must exist |
| Trade.LiquidityAccounts | Table | FK - LiquidityAccountID must exist |

### 6.2 Objects That Depend On This

No active dependencies. See `Hedge.ExecutionRequestBreakdownLog` for the current version's consumers.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryExecutionRequestBreakdownLog | NONCLUSTERED (PK) | EntryID ASC | - | - | Active |
| IX_HistoryExecutionRequestBreakdownLog_Occurred | CLUSTERED | Occurred ASC | - | - | Active |

**Note**: NONCLUSTERED PK + CLUSTERED on Occurred is the standard pattern for append-heavy time-series log tables - the clustered index optimizes time-range scans while the PK provides point lookups by EntryID.

**Filegroup**: [PRIMARY] - no DATA_COMPRESSION specified (default = none).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryExecutionRequestBreakdownLog | PRIMARY KEY (NONCLUSTERED) | Uniqueness on EntryID |
| FK_ExecutionRequestBreakdownLog_HedgeServer | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer |
| FK_ExecutionRequestBreakdownLog_LiquidityAccounts | FOREIGN KEY | LiquidityAccountID -> Trade.LiquidityAccounts |

---

## 8. Sample Queries

### 8.1 TCA analysis - price discrepancy between eToro and provider
```sql
SELECT HedgeID, InstrumentID, LiquidityAccountID, Occurred,
       IsBuy, AmountInUnits,
       eToroPriceBid, ProviderPriceBid,
       ProviderPriceBid - eToroPriceBid AS BidSlippage,
       eToroPriceAsk, ProviderPriceAsk,
       ProviderPriceAsk - eToroPriceAsk AS AskSlippage
FROM [History].[ExecutionRequestBreakdownLog]
WHERE Occurred BETWEEN '2011-01-01' AND '2012-01-01'
  AND InstrumentID = 4
ORDER BY Occurred
```

### 8.2 Volume by hedge server and instrument
```sql
SELECT HedgeServerID, InstrumentID,
       COUNT(*) AS OrderCount,
       SUM(AmountInUnits) AS TotalUnits,
       SUM(CASE WHEN IsBuy = 1 THEN AmountInUnits ELSE 0 END) AS BuyUnits,
       SUM(CASE WHEN IsBuy = 0 THEN AmountInUnits ELSE 0 END) AS SellUnits
FROM [History].[ExecutionRequestBreakdownLog]
WHERE Occurred BETWEEN '2011-01-01' AND '2012-01-01'
GROUP BY HedgeServerID, InstrumentID
ORDER BY HedgeServerID, TotalUnits DESC
```

### 8.3 Cross-reference with current Hedge table (combined view)
```sql
-- Historical records (pre-migration)
SELECT 'History' AS Source, EntryID, HedgeID, InstrumentID, Occurred, AmountInUnits, IsBuy
FROM [History].[ExecutionRequestBreakdownLog]
UNION ALL
-- Current records
SELECT 'Hedge' AS Source, EntryID, HedgeID, InstrumentID, Occurred, AmountInUnits, IsBuy
FROM [Hedge].[ExecutionRequestBreakdownLog]
ORDER BY Occurred
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table has 0 rows in staging. Legacy version of Hedge.ExecutionRequestBreakdownLog - no longer written*
*Object: History.ExecutionRequestBreakdownLog | Type: Table | Source: etoro/etoro/History/Tables/History.ExecutionRequestBreakdownLog.sql*
