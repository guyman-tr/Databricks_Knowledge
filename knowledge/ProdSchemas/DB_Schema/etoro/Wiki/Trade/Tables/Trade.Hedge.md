# Trade.Hedge

> Broker-side hedge position tracking table. Stores executed hedges that offset client CFD exposure at liquidity providers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | HedgeID (INT, CLUSTERED PK) |
| **Partition** | Yes - ON [MAIN] |
| **Indexes** | 7 active (PK + 6 NC) |

---

## 1. Business Meaning

Trade.Hedge stores executed hedge positions that eToro opens at liquidity providers to offset client CFD exposure. When a customer opens a CFD position, eToro takes the opposite side and must hedge aggregate net exposure by opening offsetting positions at external brokers. Each row in Trade.Hedge represents one such executed hedge: the instrument, direction (IsBuy), amount, initiation rate, SL/TP levels, and linkage to the hedge server, account, and parent trade.

This table exists because hedging is a core risk-management activity. Without it, the system could not track which hedges have been executed, what their P&L is, or reconcile with the broker's hedge server and liquidity accounts. Trade.HedgeExposureQuery, Trade.GetHedgeExposure, Trade.GetPosition, and Trade.HedgeClose all depend on this table to compute exposure, resolve position-to-hedge mappings, and move closed hedges to History.Hedge.

Data is created by `Trade.HedgeOpen` (INSERT from HedgeRequest data) and removed by `Trade.HedgeClose` (copy to History.Hedge, then DELETE). HedgeEditTakeProfit and HedgeEditStopLost UPDATE LimitRate and StopRate. The table has no triggers; history is maintained explicitly by HedgeClose.

---

## 2. Business Logic

### 2.1 Hedge Lifecycle: Open -> History on Close

**What**: Hedge rows are live while the hedge position is open; on close they move to History.Hedge.

**Columns/Parameters Involved**: `HedgeID`, `TradeID`, `ParentTradeID`, `InitForexRate`, `Occurred`, `RequestOccurred`

**Rules**:
- Trade.HedgeOpen INSERTs a new row when a hedge is executed. Data comes from Trade.HedgeRequest (ProviderID, InstrumentID, Leverage, etc.) plus parameters (Amount, InitForexRate, IsBuy, TradeID, AccountID).
- Trade.HedgeClose copies the row to History.Hedge (with EndForexRate, EndDateTime, NetProfit, Commission) then DELETEs from Trade.Hedge.
- FirstParentOpenOccured is populated from the parent hedge when closing a partially filled position that was split.

**Diagram**:
```
Trade.HedgeRequest (pending) -> Trade.HedgeOpen -> Trade.Hedge (live)
                                              -> Trade.HedgeClose -> History.Hedge
                                                                  -> DELETE Trade.Hedge
```

### 2.2 Instrument-Provider-HedgeServer Tuple

**What**: Each hedge is tied to a specific (ProviderID, InstrumentID) via ProviderToInstrument and a HedgeServerID.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `HedgeServerID`, `CurrencyID`, `LiquidityAccountID`

**Rules**:
- ProviderID and InstrumentID must exist in Trade.ProviderToInstrument (FK_TPVI_THDG).
- CurrencyID references Dictionary.Currency (FK_DCUR_THDG).
- HedgeServerID references Trade.HedgeServer (FK_THSV_THDG).
- LiquidityAccountID defaults to -1; identifies which liquidity account executed the hedge for multi-account routing.

---

## 3. Data Overview

| HedgeID | ProviderID | InstrumentID | HedgeServerID | IsBuy | Amount | InitForexRate | TradeID | AccountID | Meaning |
|---------|------------|--------------|---------------|-------|--------|---------------|---------|-----------|---------|
| (Sample data unavailable - table may be empty in this environment) | | | | | | | | | Hedge rows represent executed offset positions at liquidity providers. When present, each row is an open hedge awaiting close. |

**Selection criteria**: Live query returned 0 rows. Structure documented from DDL and procedure logic.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeID | int | NO | - | CODE-BACKED | Primary key. Allocated externally (e.g., from HedgeRequest). Trade.HedgeOpen INSERTs; Trade.HedgeClose DELETEs after copy to History.Hedge. |
| 2 | CurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. Denomination currency for the hedge. Used for P&L and conversion. |
| 3 | ProviderID | int | NO | - | CODE-BACKED | Part of FK (ProviderID, InstrumentID) -> Trade.ProviderToInstrument. Execution provider. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Part of FK -> Trade.ProviderToInstrument. Tradeable instrument being hedged. |
| 5 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer. Which hedge server executed this hedge. |
| 6 | Leverage | int | NO | - | CODE-BACKED | Leverage multiple (e.g., 1, 5, 10). Sourced from HedgeRequest in HedgeOpen. |
| 7 | Amount | money | NO | - | CODE-BACKED | Hedge position size in currency. Trade.HedgeOpen receives @Amount; HedgeClose may pass @Amount for partial close. |
| 8 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units. Used for fractional lot reporting. |
| 9 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count. Provider-specific sizing. |
| 10 | NetProfit | money | NO | - | CODE-BACKED | P&L in currency. HedgeOpen sets @NetProfit/100 (cents to dollars); HedgeClose passes close P&L. |
| 11 | InitForexRate | dbo.dtPrice | NO | - | CODE-BACKED | Rate at which the hedge was opened. Used for P&L calc with EndForexRate. |
| 12 | InitDateTime | datetime | NO | - | CODE-BACKED | When the hedge was opened. |
| 13 | LimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take-profit rate. HedgeEditTakeProfit UPDATEs this. |
| 14 | StopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop-loss rate. HedgeEditStopLost UPDATEs this. |
| 15 | IsBuy | bit | NO | - | CODE-BACKED | 1 = long hedge (buy), 0 = short hedge (sell). Opposite of client position direction. |
| 16 | TradeID | varchar(50) | YES | - | CODE-BACKED | Broker-assigned trade ID. Normalized by Internal.NormalizeString in HedgeOpen. |
| 17 | ParentTradeID | varchar(50) | YES | - | CODE-BACKED | For partial fills/splits - references parent hedge TradeID. HedgeClose and exposure queries use this. |
| 18 | AccountID | varchar(50) | YES | - | CODE-BACKED | Broker account that holds the hedge. |
| 19 | OrderID | varchar(50) | YES | - | CODE-BACKED | Broker order ID. Sourced from HedgeRequest in HedgeOpen. |
| 20 | RequestOccurred | datetime | NO | - | CODE-BACKED | When the hedge request was submitted. Default getutcdate(). |
| 21 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | When the hedge was executed. THDG_OCCURRED default. |
| 22 | Fee | money | YES | - | CODE-BACKED | Execution fee. Passed from HedgeOpen. |
| 23 | NfaFee | money | YES | - | CODE-BACKED | NFA-related fee. |
| 24 | OrigAmountInUnits | int | YES | - | CODE-BACKED | Original unit count before partial close. |
| 25 | FirstParentOpenOccured | datetime | YES | - | CODE-BACKED | When the first parent hedge opened (for split/partial scenarios). Populated from parent when @ParentTradeID is set. |
| 26 | Premium | money | YES | - | CODE-BACKED | Premium charge. |
| 27 | OpenCharge | money | YES | - | CODE-BACKED | Charge on open. |
| 28 | Commission | money | YES | - | CODE-BACKED | Commission. HedgeClose receives @Commission in cents, stores /100. |
| 29 | LiquidityAccountID | int | YES | -1 | CODE-BACKED | Liquidity account used. Default -1. DF_TradeHedge_LiquidityAccountID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | FK | Denomination currency (FK_DCUR_THDG). |
| HedgeServerID | Trade.HedgeServer | FK | Hedge server that executed (FK_THSV_THDG). |
| ProviderID, InstrumentID | Trade.ProviderToInstrument | FK | Instrument-provider config (FK_TPVI_THDG). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeOpen | INSERT | Writer | Creates hedge rows. |
| Trade.HedgeClose | FROM/DELETE | Deleter | Copies to History.Hedge, then deletes. |
| Trade.HedgeEditTakeProfit | UPDATE | Modifier | Updates LimitRate. |
| Trade.HedgeEditStopLost | UPDATE | Modifier | Updates StopRate. |
| Trade.HedgeRemove, HedgeRemoveFully, HedgeRemoveDiff | DELETE | Deleter | Cleanup/remove hedges. |
| Trade.HedgeExposureQuery | FROM | Reader | Aggregates exposure by instrument/server. |
| Trade.GetHedgeExposure, GetHedgeExposureDetailed | FROM | Reader | Exposure views. |
| Trade.GetPosition | JOIN | Reader | Resolves hedge data for positions. |
| Trade.GetAverageHedgeInitRate | FROM | Reader | Computes average init rate. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Hedge (table)
├── Dictionary.Currency (table)
├── Trade.HedgeServer (table)
└── Trade.ProviderToInstrument (table)
      ├── Trade.Provider (table)
      └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | FK CurrencyID |
| Trade.HedgeServer | Table | FK HedgeServerID |
| Trade.ProviderToInstrument | Table | FK (ProviderID, InstrumentID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeOpen | Procedure | INSERT |
| Trade.HedgeClose | Procedure | SELECT, INSERT History.Hedge, DELETE |
| Trade.HedgeEditTakeProfit | Procedure | UPDATE LimitRate |
| Trade.HedgeEditStopLost | Procedure | UPDATE StopRate |
| Trade.HedgeExposureQuery | Procedure | FROM for exposure aggregation |
| Trade.GetHedgeExposure | View | FROM |
| Trade.GetHedgeExposureDetailed | View | FROM |
| Trade.GetPosition | View | LEFT JOIN for hedge data |
| History.Hedge | Table | Target of HedgeClose copy |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_THDG | CLUSTERED | HedgeID | - | - | Active |
| IX_THEDGE_1 | NC | InstrumentID, HedgeServerID, IsBuy | - | - | Active |
| IX_THEDGE_INCL1 | NC | InstrumentID, HedgeServerID, IsBuy | InitForexRate | - | Active |
| IX_TradeHedge_ParentTradeID | NC | ParentTradeID | - | - | Active |
| THDG_CURRENCY | NC | CurrencyID | - | - | Active |
| THDG_HEDGESERVER | NC | HedgeServerID | - | - | Active |
| THDG_INSTRUMENT | NC | InstrumentID | - | - | Active |
| THDG_PROVIDER | NC | ProviderID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_DCUR_THDG | FK | CurrencyID -> Dictionary.Currency(CurrencyID) |
| FK_THSV_THDG | FK | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_TPVI_THDG | FK | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument |
| THDG_OCCURRED | DEFAULT | Occurred = getutcdate() |
| DF_TradeHedge_LiquidityAccountID | DEFAULT | LiquidityAccountID = -1 |

---

## 8. Sample Queries

### 8.1 Get open hedges by instrument and hedge server
```sql
SELECT TH.HedgeID, TH.InstrumentID, TH.HedgeServerID, TH.IsBuy, TH.Amount,
       TH.InitForexRate, TH.LimitRate, TH.StopRate, TH.TradeID
  FROM Trade.Hedge TH WITH (NOLOCK)
 WHERE TH.InstrumentID = 1 AND TH.HedgeServerID = 1
 ORDER BY TH.Occurred DESC
```

### 8.2 Resolve hedge to instrument and currency names
```sql
SELECT TH.HedgeID, TH.InstrumentID, TH.CurrencyID, DC.Abbreviation AS Currency,
       PTI.PresentationCode, TH.IsBuy, TH.Amount, TH.InitForexRate
  FROM Trade.Hedge TH WITH (NOLOCK)
  JOIN Dictionary.Currency DC WITH (NOLOCK) ON TH.CurrencyID = DC.CurrencyID
  JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK)
    ON TH.ProviderID = PTI.ProviderID AND TH.InstrumentID = PTI.InstrumentID
 WHERE TH.HedgeServerID = 1
```

### 8.3 Hedge exposure summary by instrument
```sql
SELECT TH.InstrumentID, TH.HedgeServerID, TH.IsBuy,
       SUM(TH.Amount) AS TotalAmount, COUNT(*) AS HedgeCount
  FROM Trade.Hedge TH WITH (NOLOCK)
 GROUP BY TH.InstrumentID, TH.HedgeServerID, TH.IsBuy
 ORDER BY TH.InstrumentID, TH.HedgeServerID, TH.IsBuy
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8+ analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.Hedge | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Hedge.sql*
