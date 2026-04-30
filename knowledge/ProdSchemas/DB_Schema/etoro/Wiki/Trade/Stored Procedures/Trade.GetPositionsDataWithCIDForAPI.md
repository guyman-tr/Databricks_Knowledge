# Trade.GetPositionsDataWithCIDForAPI

> Returns all open positions for a given customer ID, used by the Trading API to load a customer's complete open portfolio.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the full set of open trading positions for a customer. It is the bulk-read variant of `Trade.GetPositionsDataWithCIDAndPositionIdForAPI` (which reads a single position). Every open position for the given CID is returned with complete state: instrument, direction, leverage, SL/TP rates, settlement type, copy-trade linkage, fees, lot count, and more. This is used when the API needs to reconstruct a customer's entire current portfolio - for example, on login, when computing available equity, or when processing a bulk operation (close all positions).

The procedure exists as the canonical "load all positions for a customer" operation in `eToro.Trading.Infrastructure.Repositories.PositionRepository`, called from `PositionRepository.GetPositionsByCidAsync(cid)`. It reads from `Trade.Position` (the open-positions view), meaning it implicitly returns only positions with StatusID=1.

Data flows: SELECT from Trade.Position view filtered by CID only. No pagination. For customers with many open positions (CopyTrader leaders can have thousands), this can return large result sets. Each row is deserialized by `PositionRepository.CreatePosition(reader)` into a `Position` domain object. Notably, this procedure does NOT include the `OrderForCloseID` column that appears in `GetPositionsDataWithCIDAndPositionIdForAPI` - the bulk load does not check for in-flight close orders per position.

---

## 2. Business Logic

### 2.1 Complete Portfolio Snapshot

**What**: Returns all open positions for a customer in one query without pagination.

**Columns/Parameters Involved**: `@cid`, `Trade.Position` view

**Rules**:
- No StatusID filter is needed - Trade.Position view already surfaces only open (StatusID=1) positions.
- No ordering guarantee - caller must sort if needed.
- No pagination - all positions returned. For high-volume accounts, callers should be aware of result set size.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | The customer whose open positions to retrieve. Returns ALL open positions for this customer. |

**Output Columns** (all inherited from Trade.Position view and identical to GetPositionsDataWithCIDAndPositionIdForAPI except OrderForCloseID is absent)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | BIGINT | NO | - | VERIFIED | Unique position identifier. Maps to `Position.PositionID`. |
| 3 | CID | INT | NO | - | VERIFIED | Customer ID. ISNULL(..., 0). Maps to `Position.CID`. |
| 4 | Amount | DECIMAL | NO | - | VERIFIED | Current invested amount in USD. Maps to `Position.Amount`. |
| 5 | InitDateTime | DATETIME | NO | - | VERIFIED | Timestamp when position was opened. App property: `Position.OpenDateTime`. |
| 6 | InitForexRate | DECIMAL | NO | - | VERIFIED | Instrument price at open (open rate). App property: `Position.OpenRate`. |
| 7 | InstrumentID | INT | NO | - | VERIFIED | The traded instrument. FK to Trade.Instrument. Maps to `Position.InstrumentID`. |
| 8 | IsBuy | BIT | NO | - | VERIFIED | Direction: 1=Buy/Long, 0=Sell/Short. Maps to `Position.IsBuy`. |
| 9 | Leverage | INT | NO | - | VERIFIED | Leverage multiplier at open. 1=no leverage (real stocks). Maps to `Position.Leverage`. |
| 10 | LimitRate | DECIMAL | NO | - | VERIFIED | Take-profit rate. App property: `Position.TakeProfitRate`. LimitRate IS the take-profit rate. |
| 11 | StopRate | DECIMAL | NO | - | VERIFIED | Stop-loss rate. App reads as `new Position(stopLossRate, stopLossVersion)`. |
| 12 | MirrorID | INT | NO | - | VERIFIED | CopyTrader mirror ID. 0=manual trade. ISNULL(..., 0). FK to Trade.Mirror. |
| 13 | OrderID | BIGINT | NO | - | VERIFIED | Opening order ID. 0 if no order. ISNULL(..., 0). FK to Trade.Orders. |
| 14 | OrderType | INT | NO | - | CODE-BACKED | Type of the originating order. ISNULL(..., 0). |
| 15 | ParentPositionID | BIGINT | NO | - | VERIFIED | Leader's position this was copied from. 0=root. ISNULL(..., 0). |
| 16 | AmountInUnitsDecimal | DECIMAL | NO | - | VERIFIED | Current position size in units. ISNULL(..., 0). App property: `Position.Units`. |
| 17 | EndOfWeekFee | DECIMAL | NO | - | VERIFIED | Accumulated overnight/end-of-week financing fee. App property: `Position.TotalFees`. |
| 18 | InitialAmountInDollars | DECIMAL | NO | - | VERIFIED | Original investment in USD at open. Computed as `InitialAmountCents / 100`. App property: `Position.InitialAmountInDollars`. |
| 19 | IsTslEnabled | BIT | NO | - | VERIFIED | Trailing stop-loss active flag. 1=TSL active. Maps to `Position.IsTslEnabled`. |
| 20 | StopLossVersion | INT | NO | - | VERIFIED | Stop-loss generation indicator (from SLManualVer). Backward-compatibility version for SL calculations. Maps to `Position.StopLossVersion`. |
| 21 | TreeID | BIGINT | NO | - | VERIFIED | CopyTrader tree root. TreeID=PositionID for root positions; children share root's TreeID. Links to Trade.PositionTreeInfo. |
| 22 | IsSettled | BIT | NO | - | VERIFIED | Legacy settlement flag. 1=real stock, 0=CFD. Predates SettlementTypeID. |
| 23 | SettlementTypeID | INT | NO | - | VERIFIED | Modern settlement type: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE (Dictionary.SettlementTypes). |
| 24 | RedeemStatus | INT | NO | - | VERIFIED | Redemption status. ISNULL(..., 0). 0=no active redemption. App property: `Position.RedeemStatusID`. |
| 25 | InitialUnits | DECIMAL | NO | - | VERIFIED | Original unit count at open. ISNULL(InitialUnits, ISNULL(AmountInUnitsDecimal, 0)) - fallback for older positions. |
| 26 | UnitsBaseValueDollars | DECIMAL | NO | - | VERIFIED | Base value of units in USD. CONVERT(DECIMAL(12,2), UnitsBaseValueCents) / 100. |
| 27 | IsDiscounted | BIT | NO | - | CODE-BACKED | Fee discount applied flag. Maps to `Position.IsDiscounted`. |
| 28 | OpenActionType | INT | NO | - | VERIFIED | How position was opened. 0=Customer manual, 1=CopyTrader copy. App property: `Position.OpenPositionActionType`. |
| 29 | OrigParentPositionID | BIGINT | NO | - | VERIFIED | Original parent before any re-parenting. ISNULL(..., 0). Maps to `Position.OrigParentPositionID`. |
| 30 | InitConversionRate | DECIMAL | NO | - | VERIFIED | Currency-to-USD conversion rate at open. Used in PnL calculations. Maps to `Position.InitConversionRate`. |
| 31 | PnLVersion | INT | NO | - | VERIFIED | PnL formula version. 0=legacy CFD, 1=real stock. Derived from SettlementType. Maps to `Position.PnlVersion`. |
| 32 | OpenTotalTaxes | DECIMAL | NO | - | VERIFIED | Total external taxes at open. Maps to `Position.TotalExternalTaxes`. |
| 33 | OpenTotalFees | DECIMAL | NO | - | VERIFIED | Total external fees (non-EOW) at open. Maps to `Position.TotalExternalFees`. |
| 34 | IsNoStopLoss | BIT | YES | - | VERIFIED | TRUE=position explicitly has no stop-loss. NULL=flag not set. Maps to `Position.IsNoStopLoss`. |
| 35 | IsNoTakeProfit | BIT | YES | - | VERIFIED | TRUE=position explicitly has no take-profit. NULL=flag not set. Maps to `Position.IsNoTakeProfit`. |
| 36 | LotCountDecimal | DECIMAL | NO | - | VERIFIED | Position size in lots (units / lot size). App property: `Position.LotCount`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | Trade.Position | Primary source | All open position data for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PositionRepository.GetPositionsByCidAsync | @cid | Application call | Called from trading-shared PositionRepository to load all Position domain objects for a customer |
| TradingSettingsAPI (DB user) | GRANT EXECUTE | Permission | Trading settings service access |
| TAPIUser (DB user) | GRANT EXECUTE | Permission | TAPI user access |
| PROD_BIadmins (DB user) | GRANT EXECUTE | Permission | BI admin access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsDataWithCIDForAPI (procedure)
└── Trade.Position (view)
      ├── Trade.PositionTbl (table)
      └── Trade.PositionTreeInfo (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT all open positions filtered by CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eToro.Trading.Infrastructure.Repositories.PositionRepository | Application class | GetPositionsByCidAsync() calls this to load all open Position objects for a customer |
| TradingSettingsAPI | Application service | Loads all open positions for settings/configuration operations |
| TAPIUser | Application | TAPI trading operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None explicit beyond the Trade.Position view's own filters.

---

## 8. Sample Queries

### 8.1 Get all open positions for a customer

```sql
EXEC Trade.GetPositionsDataWithCIDForAPI @cid = 14952810;
```

### 8.2 Count positions by instrument for a customer

```sql
-- Run procedure then group - or equivalent inline:
SELECT InstrumentID, COUNT(*) AS PositionCount, SUM(Amount) AS TotalInvested
FROM Trade.Position WITH (NOLOCK)
WHERE CID = 14952810
GROUP BY InstrumentID
ORDER BY TotalInvested DESC;
```

### 8.3 Check positions with TSL enabled for a customer

```sql
SELECT PositionID, InstrumentID, Amount, StopRate, LimitRate, IsTslEnabled
FROM Trade.Position WITH (NOLOCK)
WHERE CID = 14952810
  AND IsTslEnabled = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 29 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 1 files (PositionRepository.cs) | Corrections: 0 applied*
*Object: Trade.GetPositionsDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsDataWithCIDForAPI.sql*
