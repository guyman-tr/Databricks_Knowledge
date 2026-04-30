# Trade.NewCheckBSL

> Post-execution BSL audit: independently recalculates which customers should have been warned or liquidated for a given BSL execution cycle, compares against what actually happened, and emails the operations team if false positives (liquidated but shouldn't be) or false negatives (should have been liquidated but weren't) are found at MessageType=2 level.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExecutionID - the BSL run to verify |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.NewCheckBSL is an independent verification layer for eToro's Balance Stop Loss (BSL) system. BSL protects customers from losing more than their deposited equity by liquidating positions when total equity (RealizedEquity + UnrealizedPnL) falls at or below their BonusCredit level. After each BSL execution cycle, this procedure recalculates the expected liquidation and warning population from first principles and compares it against what Trade.ManageBSL/History.ManageBSL actually recorded.

Two failure modes trigger email alerts to the operations team (edenli, ilanazi, pinikr, adico):
- **False positives** (MessageType=2): customers who were liquidated but the recalculation says they shouldn't have been - potentially wrongful liquidations requiring remediation.
- **False negatives** (MessageType=2): customers who should have been liquidated but weren't - BSL missed them, creating regulatory/financial risk.

The recalculation uses the exact price snapshot captured at the time of BSL execution (History.BSLCurrencyPriceSnapShots) and the BSL position snapshot (History.BSLPositionsInfo), ensuring apples-to-apples comparison with the original run. Multi-currency PnL conversion handles GBX (InstrumentID=2, requires /100 scaling), direct USD quote, and cross-currency chains.

Warning levels: MessageType=1 at 20% of available MIMO equity above bonus; MessageType=2 (full trigger) at 0% (equity <= bonus). Sub-thresholds: WarningType=2 at 10%, WarningType=1 at 20%.

---

## 2. Business Logic

### 2.1 Execution Anchor and Price Snapshot

**What**: Establishes the time anchor for the BSL run and loads the price snapshot used during the original execution.

**Columns/Parameters Involved**: `Trade.ManageBSL.TimeMessageInsertedToQueue`, `History.BSLCurrencyPriceSnapShots.ExecutionID`, `@GBX_ConversionRate`

**Rules**:
- @StartDate = MIN(TimeMessageInsertedToQueue) FROM Trade.ManageBSL WHERE ExecutionID=@ExecutionID: the earliest message time of the batch - used to look up the last credit operation before the BSL run.
- Prices loaded from History.BSLCurrencyPriceSnapShots JOIN Trade.GetInstrument WHERE ExecutionID=@ExecutionID into #prices.
- @GBX_ConversionRate = Bid/100 WHERE InstrumentID=2: GBX (pence) requires division by 100 for USD conversion.

### 2.2 Multi-Currency Unrealized PnL Calculation

**What**: Recalculates per-position unrealized PnL using the BSL-time price snapshot, with multi-currency conversion chain.

**Columns/Parameters Involved**: `Trade.Position`, `History.Position`, `History.BSLPositionsInfo`, `#prices.Bid/Ask`, `Customer.Customer.PlayerLevelID`, `Customer.Customer.CountryID`, `Trade.BSLBlackList`

**Rules**:
- Position source: UNION ALL of Trade.Position and History.Position joined with History.BSLPositionsInfo WHERE ExecutionID=@ExecutionID (captures both open and positions that closed during the BSL run).
- PnL formula: AmountInUnitsDecimal * (CurrentPrice - InitForexRate) * Direction * CurrencyConversionFactor.
  - Direction: IsBuy=1 -> (Bid - InitForexRate), IsBuy=0 -> (Ask - InitForexRate) * -1.
  - Currency conversion:
    - SellCurrencyID=1 (USD-quoted): factor=1.
    - BuyCurrencyID=1 (reversed USD): factor=1/CurrentPrice.
    - SellCurrencyID=666 (GBX): factor=@GBX_ConversionRate (Bid/100 for pence-to-USD).
    - Cross-currency chain via self-join on #prices (SellCurrencyID chain or BuyCurrencyID chain to find USD leg).
- Filters: CustomerLevelID<>4 (excludes demo/internal accounts), CountryID<>250 (excludes specific jurisdiction), must exist in Trade.BSLBlackList (only BSL-enrolled customers).
- Aggregated to CID level in #PnL with a clustered index for join performance.

### 2.3 Last Credit and MIMO Reference Point

**What**: Identifies each customer's most recent credit operation and most recent MIMO (deposit/cashout/compensation/bonus) operation before the BSL run start.

**Columns/Parameters Involved**: `History.ActiveCredit.CreditID`, `History.ActiveCredit.CreditTypeID`, `History.ActiveCredit.Occurred`, `@StartDate`

**Rules**:
- #LastOp: FROM History.ActiveCredit NOLOCK WHERE Occurred < @StartDate, grouped by CID.
  - CreditID = MAX(CreditID): the latest operation.
  - Mimo_CreditID = MAX CASE WHEN CreditTypeID IN (1,2,6,7) AND RealizedEquity IS NOT NULL THEN CreditID: the latest MIMO operation with a valid equity snapshot.
  - CreditTypeID 1=Deposit, 2=Cashout, 6=Compensation, 7=Bonus.
- #Data: JOINs History.ActiveCredit ON CreditID=CreditID OR CreditID=Mimo_CreditID to get RealizedEquity and BonusCredit at both reference points.

### 2.4 BSL Warning/Trigger Level Computation

**What**: Applies the BSL threshold logic to classify each customer into a MessageType and WarningType.

**Columns/Parameters Involved**: `#Data.RealizedEquity`, `#Data.BonusCredit`, `#PnL.UnrealizedPnL`, `#Data.[Last MIMO RealizedEquity]`, `#Data.[Last MIMO BonusCredit]`

**Rules**:
- TotalEquity = RealizedEquity + UnrealizedPnL.
- AvailableMIMOEquity = [Last MIMO RealizedEquity] - [Last MIMO BonusCredit]: equity above the bonus level at the last MIMO event.
- T_MessageType:
  - 2: TotalEquity <= BonusCredit (full trigger - equity gone below bonus level).
  - 1: TotalEquity <= BonusCredit + AvailableMIMOEquity * 0.20 (warning zone).
  - 0: no action.
- T_WarningType:
  - 0: TotalEquity <= BonusCredit (full trigger, no warning type distinction).
  - 2: TotalEquity <= BonusCredit + AvailableMIMOEquity * 0.10 (10% threshold).
  - 1: TotalEquity <= BonusCredit + AvailableMIMOEquity * 0.20 (20% threshold).
  - 0: no action.
- Filter: only customers with BonusCredit >= 0 (or NULL) AND meeting at least a warning threshold.

### 2.5 Comparison and Email Alert

**What**: Compares recalculated results with actual BSL execution output; emails operations team on MessageType=2 discrepancies.

**Columns/Parameters Involved**: `Trade.ManageBSL`, `History.ManageBSL`, `#Final`, `msdb.dbo.sp_send_dbmail`

**Rules**:
- #BSL: UNION ALL of Trade.ManageBSL and History.ManageBSL for the ExecutionID (current + historical records).
- Match key: CID + MessageType + WarningType.
- #Should_Be_Liquidated_But_Wasnt: in #Final (recalculated) but NOT in #BSL (actual) - missed liquidations.
- #Liquidated_But_Shouldnt_Be: in #BSL (actual) but NOT in #Final (recalculated) - wrongful liquidations.
- Email trigger: only MessageType=2 rows in either set trigger alerts; warning (MessageType=1) discrepancies are not alerted.
- Recipients hardcoded: edenli, ilanazi, pinikr, adico at etoro.com.
- HTML table format with customer details (CID, MessageType, WarningType, RealizedEquity, UnrealizedEquity, BonusCredit, BSLRealFunds).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionID | INT | NO | - | CODE-BACKED | Identifier of the BSL execution cycle to audit. Used to filter Trade.ManageBSL, History.ManageBSL, History.BSLCurrencyPriceSnapShots, and History.BSLPositionsInfo. Each BSL cycle gets a unique ExecutionID assigned by the BSL engine. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionID | Trade.ManageBSL | Read | Reads TimeMessageInsertedToQueue for @StartDate anchor; reads actual BSL results for comparison |
| @ExecutionID | History.ManageBSL | Read | Reads historical BSL execution results for comparison |
| @ExecutionID | History.BSLCurrencyPriceSnapShots | Read | Price snapshot used during original BSL run |
| @ExecutionID | History.BSLPositionsInfo | Read | Position snapshot used during original BSL run |
| InstrumentID | Trade.GetInstrument | JOIN/Read | Provides BuyCurrencyID/SellCurrencyID for currency conversion |
| PositionID | Trade.Position | Read | Open positions for PnL recalculation |
| PositionID | History.Position | Read | Closed positions included in BSL snapshot |
| CID | Customer.Customer | JOIN/Read | PlayerLevelID<>4 and CountryID<>250 filters |
| CID | Trade.BSLBlackList | JOIN/Read | Only BSL-enrolled customers included |
| CID | History.ActiveCredit | Read | Last credit and last MIMO credit before @StartDate |
| - | msdb.dbo.sp_send_dbmail | EXEC | Sends HTML email alerts for MessageType=2 discrepancies |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SP callers found) | - | - | Called by operations/BI team (PROD_BIadmins) after BSL execution cycles to validate results. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.NewCheckBSL (procedure)
├── Trade.ManageBSL (table)
├── History.ManageBSL (table)
├── History.BSLCurrencyPriceSnapShots (table)
├── Trade.GetInstrument (view)
├── History.BSLPositionsInfo (table)
├── Trade.Position (view/table)
├── History.Position (table)
├── Customer.Customer (table)
├── Trade.BSLBlackList (table)
├── History.ActiveCredit (table)
└── msdb.dbo.sp_send_dbmail (system procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManageBSL | Table | Anchor date + actual BSL results for comparison |
| History.ManageBSL | Table | Historical BSL results for comparison |
| History.BSLCurrencyPriceSnapShots | Table | Price snapshot for PnL recalculation |
| Trade.GetInstrument | View | Currency IDs for conversion chain |
| History.BSLPositionsInfo | Table | Position snapshot filter for this execution |
| Trade.Position | View/Table | Open position data for PnL recalculation |
| History.Position | Table | Closed position data for PnL recalculation |
| Customer.Customer | Table | PlayerLevelID and CountryID filters |
| Trade.BSLBlackList | Table | BSL enrollment filter |
| History.ActiveCredit | Table | NOLOCK; last credit and MIMO reference points |
| msdb.dbo.sp_send_dbmail | System Procedure | HTML email alert dispatch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found) | - | Verification tool; called ad-hoc or scheduled after BSL execution. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Creates two inline clustered indexes on temp tables: `#PnLIndex ON #PnL(CID)` and `#LOIndex ON #LastOp(CreditID, Mimo_CreditID)` to accelerate the join-heavy aggregation steps. Both #prices SELECT and #PnLPerPos SELECT use OPTION (RECOMPILE) to prevent parameter-sniffing plan reuse across different ExecutionIDs.

### 7.2 Constraints

N/A for stored procedure. No explicit transaction - read-only SELECT pipeline with two email sends at the end. No TRY/CATCH wrapper - errors propagate to caller.

---

## 8. Sample Queries

### 8.1 Check BSL execution records for a given ExecutionID

```sql
SELECT CID, MessageType, WarningType, RealizedEquity, UnRealizedEquity, BonusCredit, BSLRealFunds
FROM Trade.ManageBSL WITH (NOLOCK)
WHERE ExecutionID = <ExecutionID>
ORDER BY MessageType DESC, CID;
```

### 8.2 Find all BSL executions with their anchored start times

```sql
SELECT ExecutionID, MIN(TimeMessageInsertedToQueue) AS StartDate,
       COUNT(*) AS MessageCount
FROM Trade.ManageBSL WITH (NOLOCK)
GROUP BY ExecutionID
ORDER BY StartDate DESC;
```

### 8.3 Check price snapshots for a BSL execution

```sql
SELECT BSP.InstrumentID, BSP.Ask, BSP.Bid, GI.BuyCurrencyID, GI.SellCurrencyID
FROM History.BSLCurrencyPriceSnapShots AS BSP WITH (NOLOCK)
JOIN Trade.GetInstrument AS GI ON BSP.InstrumentID = GI.InstrumentID
WHERE BSP.ExecutionID = <ExecutionID>;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.NewCheckBSL | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.NewCheckBSL.sql*
