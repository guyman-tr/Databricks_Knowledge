# Trade.InsertBSLMessagesIntoQueue

> The core BSL (Balance Stop Loss) risk engine: scans all open CFD positions in real time, calculates unrealized equity per customer, and inserts liquidation or warning messages into the BSL queue for customers whose equity falls below configured thresholds.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsDebug TINYINT = 0 (production) / 1 (debug mode) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertBSLMessagesIntoQueue is the **BSL (Balance Stop Loss / Break Stop Loss) risk assessment engine** that runs on a scheduled basis to protect both customers and the platform from runaway losses. It scans every open CFD position in real time, computes each customer's total unrealized P&L using current market prices, and compares their total equity (RealizedEquity + UnrealizedPnL - BonusCredit) against their BSLRealFunds stop thresholds. Customers who breach configured thresholds receive warning or liquidation messages.

This SP exists because eToro operates leveraged CFD trading, where customers can lose more than their deposited balance if positions move against them. The BSL system is the automated circuit breaker - it sends warnings before liquidation and triggers margin calls when equity drops to the blocking threshold, protecting customers from negative balances and protecting eToro from credit risk.

Data flows in three stages: (1) snapshot - reads all open CFD positions and calculates real-time equity using Trade.CurrencyPrice rates, storing snapshots in temp tables; (2) classification - classifies each customer as no-action/warning/liquidation based on BSL thresholds from Dictionary.BSLOperationThreshold; (3) output - inserts messages into RW_ManageBSL (synonym for Trade.ManageBSL), queues them in RW_BSLQueue, records position snapshots, and sends email alerts for liquidation events. Called externally by a scheduled SQL Agent job.

---

## 2. Business Logic

### 2.1 Position Scope - CFD Only, Non-Mirror, Non-Whitelisted

**What**: Only certain positions qualify for BSL monitoring.

**Columns/Parameters Involved**: `SettlementTypeID`, `IsSettled`, `MirrorID`, `StatusID`

**Rules**:
- Only CFD positions: `(SettlementTypeID <> 1 OR IsSettled = 0)` - excludes real stock positions (SettlementTypeID=1 = real stocks)
- Only non-mirror positions: `MirrorID = 0` - only the account holder's own positions, not copy-trade mirrors
- Only open positions: `StatusID = 1` - closed positions do not affect current equity
- Exclusions: Users in CIDsInLiquidation (already being liquidated), BSLUsersWhiteList (exempt from BSL), PlayerLevelID=4 (internal/special accounts), CountryID=250 (excluded jurisdiction)
- US-regulated customers with CountryGroupID=4 and DesignatedRegulationID in (8,14) are excluded

### 2.2 Real-Time Equity Calculation (P&L Formula)

**What**: Calculates unrealized P&L for each position using live bid/ask prices.

**Columns/Parameters Involved**: `IsBuy`, `InitForexRate`, `CurrentRate`, `AmountInUnitsDecimal`, `ConversionRate`, `RealizedEquity`, `BonusCredit`, `BSLRealFunds`

**Rules**:
- `CurrentRate` = Bid (for BUY positions without discount) or Ask (for SELL positions without discount), or discounted rates when IsDiscounted=1
- `PnL per position = (CurrentRate - InitForexRate) * IIF(IsBuy=1, 1, -1) * AmountInUnitsDecimal * ConversionRate`
- ConversionRate converts to USD: `CASE WHEN SellCurrencyID=1 THEN 1 WHEN IsReciprocal=1 THEN 1/Bid ELSE Bid END`
- `Total P&L per CID = SUM(PnL across all open positions)`
- `Total Equity = RealizedEquity + TotalPnL - BonusCredit` (bonus is excluded from equity for BSL purposes)

**Diagram**:
```
BSL Thresholds (from Dictionary.BSLOperationThreshold):
  @PercentForBlocking = ID=1 (ValueInPercent) e.g., 25%
  @PercentForAlert1   = ID=2 (ValueInPercent) e.g., 50%
  @PercentForAlert2   = ID=3 (ValueInPercent) e.g., 75%

Classification per customer:
  IF TotalEquity <= BSLRealFunds * @PercentForBlocking / 100
    OR BSLRealFunds <= 0
    OR TotalEquity <= 0
  THEN MessageType=2 (LIQUIDATION)

  ELSE IF TotalEquity <= BSLRealFunds * @PercentForAlert1 / 100
  THEN MessageType=1 (WARNING), WarningType=1

  (WarningType=2 for Alert2 if more severe within Warning range)

  ELSE MessageType=0 (no action)
```

### 2.3 Alert Rate Limiting (24-Hour Window)

**What**: Prevents warning spam - each alert type is sent at most once per 24 hours per customer.

**Columns/Parameters Involved**: `MessageType`, `WarningType`, `TimeMessageInsertedToQueue`

**Rules**:
- Reads Trade.ManageBSL for last MessageType=1 messages per CID/WarningType
- Warning is included only if:
  - WarningType=1 and no prior WarningType=1 sent (LastWarningType1 IS NULL), OR
  - WarningType=1 and last WarningType=1 was sent > 24 hours ago
  - Same rule for WarningType=2
- Liquidations (MessageType=2) are always included (no rate limiting)
- Also includes: `RealizedEquity + PnL <= 0` (negative total equity always triggers)

### 2.4 Safety Net - Prevents False Liquidations

**What**: A sanity check that vetoes liquidation when equity ratios suggest the calculation may be unreliable.

**Columns/Parameters Involved**: `@SaftyNet` (from Maintenance.Feature FeatureID=53), `RealizedEquity`, `UnRealizedEquity`, `IsPassedSaftyNet`

**Rules**:
- `@SaftyNet = CAST(Value AS INT) FROM Maintenance.Feature WHERE FeatureID=53`
- For MessageType=2 (liquidation):
  - `WHEN RealizedEquity > 0 AND UnRealizedEquity < @SaftyNet THEN IsPassedSaftyNet=0` (VETO)
  - `WHEN RealizedEquity < @SaftyNet THEN IsPassedSaftyNet=0` (VETO)
  - Otherwise `IsPassedSaftyNet=1` (proceed with liquidation)
- `IsPassedSaftyNet=0` records are logged to `RW_BSLSuspectedWrongResults` and emailed for manual review - they are NOT queued for actual liquidation
- For warnings (MessageType=1): always `IsPassedSaftyNet=1`

### 2.5 CurrencyPrice Validation Pre-Check

**What**: Validates that Trade.CurrencyPrice has current data before running the BSL check.

**Rules**:
- First step: `EXEC Monitor.TradeCurrencyPriceCheckUpdate_DataDog` to verify price freshness
- If result = 1 (stale/missing prices): RAISERROR with message "Trade.CurrencyPrice not have relevant price. Please contact MarketData OnCall"
- Only proceeds with BSL calculation if price data passes validation
- This prevents false liquidations due to stale price data

### 2.6 Output - BSL Queue Population

**What**: Writes results to the BSL message pipeline.

**Tables Written**:
- `RW_ManageBSL` (synonym for Trade.ManageBSL): main BSL message queue - MessageType, WarningType, CID, financials, ExecutionID
- `RW_BSLQueue` (synonym for Trade.BSLQueue): secondary queue for dequeue consumers
- `RW_BSLPositionsInfo`: per-position detail for this BSL run
- `RW_BSLCurrencyPriceSnapShots`: price snapshot used for this run (for audit/investigation)
- `RW_BSLSuspectedWrongResults`: records that failed safety net check (for manual review)
- `RW_BSLDataForAllUsers`: debug mode only - all customers regardless of black list status

### 2.7 Email Notification

**What**: Sends HTML alert emails for actual liquidation events and safety net suspects.

**Rules**:
- Recipients: Maintenance.Feature FeatureID=103 (BSL liquidation alert email recipients)
- Sends email when: `IsInBlackList=1 AND MessageType=2 AND IsPassedSaftyNet=1` (real liquidations)
- Also sends separate email for safety net failures: `IsInBlackList=1 AND MessageType=2 AND IsPassedSaftyNet=0`
- Subject format: "Margin Call from BSL - {date} {time}" or "Suspicious accounts from Margin Call..."
- Email contains: MessageType, WarningType, CID, BonusCredit, RealizedEquity, RealizedEquity+PnL, BSLRealFunds

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsDebug | TINYINT | YES | 0 | CODE-BACKED | Debug mode flag. 0=production (normal). Non-zero=debug: writes ALL customers' financial data to RW_BSLDataForAllUsers and RW_BSLPositionsInfo regardless of whether they triggered BSL, enabling analysis of why customers were or were not included in BSL. Also bypasses the "no records = early exit" optimization. |

**Key internal variables and temp tables:**

| # | Name | Type | Confidence | Description |
|---|------|------|------------|-------------|
| 2 | @PercentForBlocking | NUMERIC(4,2) | VERIFIED | Liquidation threshold percentage from Dictionary.BSLOperationThreshold (ID=1). Customer equity < BSLRealFunds * this% triggers MessageType=2 (liquidation). |
| 3 | @PercentForAlert1 | NUMERIC(4,2) | VERIFIED | First warning threshold from Dictionary.BSLOperationThreshold (ID=2). Customer equity < BSLRealFunds * this% triggers MessageType=1/WarningType=1. |
| 4 | @PercentForAlert2 | NUMERIC(4,2) | VERIFIED | Second (more severe) warning threshold from Dictionary.BSLOperationThreshold (ID=3). Triggers WarningType=2 within MessageType=1 alerts. |
| 5 | @SaftyNet | INT | CODE-BACKED | Safety net threshold from Maintenance.Feature FeatureID=53. Prevents false liquidations when equity ratios appear anomalous. Liquidations where RealizedEquity or UnRealizedEquity is below this value are vetoed and investigated instead. |
| 6 | @ExecutionID | BIGINT | CODE-BACKED | Unique ID for this BSL run from RW_TradeBSLNewExecutionID. Links all ManageBSL messages, price snapshots, and position info from the same execution. Used for audit and investigation. |
| 7 | #RawData | Temp table | CODE-BACKED | One row per open CFD position with real-time P&L components: CID, PositionID, InstrumentID, IsBuy, AmountInUnitsDecimal, InitForexRate, CurrentRate (live bid/ask), PriceRateID, ConversionRate, BonusCredit, RealizedEquity, BSLRealFunds, IsInBlackList. |
| 8 | #PnLPerCID | Temp table | CODE-BACKED | Aggregated P&L and MessageType classification per CID. SUM of PnL across all positions, classified as 0/1/2 based on threshold comparison. |
| 9 | #CID2Liquid | Temp table | CODE-BACKED | Set of CIDs with open CFD positions eligible for liquidation (non-real-stock, non-mirror). Used to filter out MessageType=2 for customers who aren't in this set. |
| 10 | #T2 | Temp table | CODE-BACKED | Final filtered set: MessageType 1 or 2 customers after 24-hour rate limiting and safety net checks. IsPassedSaftyNet flag gates which records actually go to the queue. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Trade.PositionTbl | READER | Reads all open CFD positions (StatusID=1, MirrorID=0, non-real-stock) |
| (reads) | Trade.CurrencyPrice | READER | Current bid/ask prices for P&L calculation |
| (reads) | Trade.ManageBSL | READER | Reads last warning times for 24h rate limiting |
| (reads) | Trade.CIDsInLiquidation | READER | Excludes already-being-liquidated customers |
| (reads) | Trade.BSLUsersWhiteList | READER | Excludes whitelisted/exempt customers |
| (reads) | Trade.Instrument | READER | Gets SellCurrencyID for conversion rate calculation |
| (reads) | Trade.GetCurrencyConversionsView | READER | Gets conversion rate instrument for FX conversion |
| (reads) | Trade.PositionTreeInfo | READER | Gets TreeID/PTI context for position scope |
| (reads) | Customer.Customer | READER | Gets RealizedEquity, BonusCredit, BSLRealFunds, PlayerLevelID |
| (reads) | BackOffice.Customer | READER | Gets DesignatedRegulationID for jurisdiction exclusions |
| (reads) | Dictionary.BSLOperationThreshold | READER | Gets BSL alert/liquidation threshold percentages |
| (reads) | Maintenance.Feature (FeatureID=53) | Config Lookup | Safety net threshold value |
| (reads) | Maintenance.Feature (FeatureID=103) | Config Lookup | Email recipients for BSL liquidation alerts |
| (writes) | Trade.ManageBSL (via RW_ManageBSL) | WRITER | Main BSL message queue - alerts and liquidations |
| (writes) | Trade.BSLQueue (via RW_BSLQueue) | WRITER | Secondary dequeue queue for BSL consumer |
| (writes) | RW_BSLPositionsInfo | WRITER | Per-position detail for this BSL run |
| (writes) | RW_BSLCurrencyPriceSnapShots | WRITER | Price snapshot for this BSL run (audit) |
| (writes) | RW_BSLSuspectedWrongResults | WRITER | Safety net failures for manual review |
| (calls) | Monitor.TradeCurrencyPriceCheckUpdate_DataDog | SP call | Price freshness validation before BSL run |
| (calls) | RW_TradeBSLNewExecutionID | SP call | Gets unique execution ID for this run |
| (calls) | dbo.RW_UpdateBslLastExecute | SP call | Records timestamp of last BSL execution |
| (calls) | Trade.SendUnBlockMessage | SP call | Processes unblock messages at end of run |
| (sends) | msdb.dbo.sp_send_dbmail | External call | Sends HTML email alerts for liquidations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job (external) | EXEC Trade.InsertBSLMessagesIntoQueue | Scheduled call | Called periodically (every few minutes) as the BSL risk check; also callable with @IsDebug=1 for investigation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertBSLMessagesIntoQueue (procedure)
├── Trade.PositionTbl (table)
├── Trade.CurrencyPrice (table)
├── Trade.ManageBSL (table)
├── Trade.CIDsInLiquidation (table)
├── Trade.BSLUsersWhiteList (table)
├── Trade.Instrument (table)
├── Trade.GetCurrencyConversionsView (view)
├── Trade.PositionTreeInfo (table)
├── Customer.Customer (table - cross-schema)
├── BackOffice.Customer (table - cross-schema)
├── Dictionary.BSLOperationThreshold (table - cross-schema)
├── Maintenance.Feature (table - cross-schema)
├── Trade.ManageBSL via RW_ManageBSL (write target)
├── Trade.BSLQueue via RW_BSLQueue (write target)
├── Monitor.TradeCurrencyPriceCheckUpdate_DataDog (procedure - cross-schema)
├── RW_TradeBSLNewExecutionID (procedure - synonym)
├── dbo.RW_UpdateBslLastExecute (procedure)
└── Trade.SendUnBlockMessage (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Main input - all open CFD positions with P&L components |
| Trade.CurrencyPrice | Table | Live bid/ask prices for P&L calculation |
| Trade.ManageBSL | Table | Read for 24h rate limiting of warnings |
| Trade.CIDsInLiquidation | Table | Exclusion filter |
| Trade.BSLUsersWhiteList | Table | Exclusion filter (exempt customers) |
| Trade.Instrument | Table | SellCurrencyID for FX conversion |
| Trade.GetCurrencyConversionsView | View | FX conversion instrument lookup |
| Trade.PositionTreeInfo | Table | TreeID context |
| Customer.Customer | Table (cross-schema) | RealizedEquity, BonusCredit, BSLRealFunds, PlayerLevelID |
| BackOffice.Customer | Table (cross-schema) | DesignatedRegulationID for jurisdiction checks |
| Dictionary.BSLOperationThreshold | Table (cross-schema) | Alert and liquidation threshold percentages |
| Maintenance.Feature | Table (cross-schema) | Safety net (FeatureID=53) and email recipients (FeatureID=103) |
| Trade.SendUnBlockMessage | Procedure | Called at end to process any unblock messages |
| Monitor.TradeCurrencyPriceCheckUpdate_DataDog | Procedure (cross-schema) | Price freshness validation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManageBSL | Table | Populated by this SP - BSL messages flow from here to BSL consumer |
| External BSL Consumer | Application | Reads Trade.ManageBSL / Trade.BSLQueue and executes liquidations/notifications |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Several temp table indexes created for performance:
- `#CID2Liquid`: CLUSTERED INDEX on (CID)
- `#RawData`: CLUSTERED INDEX on (CID, BonusCredit, RealizedEquity, BSLRealFunds, IsInBlackList)
- `#CurrencyPrice`: CLUSTERED INDEX on (InstrumentID), non-clustered PK on (PriceRateID)
- `#LastMessagePerCID`: CLUSTERED INDEX on (CID)
- `#Final`: CLUSTERED INDEX on (CID)
- `#T2.IsSecondPass`: DEFAULT (0)

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Price validation | Pre-check | RAISERROR if Monitor.TradeCurrencyPriceCheckUpdate_DataDog returns 1 (stale prices) |
| Early exit | IF NOT EXISTS | If #T2 is empty and @IsDebug=0, calls SendUnBlockMessage and returns without inserting anything |
| Safety net veto | IsPassedSaftyNet | MessageType=2 records that fail safety net are logged but NOT queued for liquidation |
| 24h rate limit | Date comparison | Warning per WarningType limited to 1 per 24 hours per CID |
| OPTION (RECOMPILE) | Query hint | Used on the main position SELECT to prevent bad plan caching on highly selective query |

---

## 8. Sample Queries

### 8.1 Check current BSL queue for unprocessed messages

```sql
SELECT TOP 20 MessageType, WarningType, CID, RealizedEquity, BSLRealFunds,
       UnRealizedEquity, TimeMessageInsertedToQueue, ExecutionID
FROM Trade.ManageBSL WITH (NOLOCK)
WHERE TimeMessageWasAck IS NULL
ORDER BY MessageType DESC, TimeMessageInsertedToQueue ASC
```

### 8.2 Check BSL thresholds configuration

```sql
SELECT ID,
    CASE ID WHEN 1 THEN 'Blocking (Liquidation)' WHEN 2 THEN 'Alert1' WHEN 3 THEN 'Alert2' END AS ThresholdType,
    ValueInPercent
FROM Dictionary.BSLOperationThreshold WITH (NOLOCK)
ORDER BY ID
```

### 8.3 Run BSL in debug mode to analyze why a customer was/was not included

```sql
-- Debug mode: logs ALL customers to RW_BSLDataForAllUsers
EXEC Trade.InsertBSLMessagesIntoQueue @IsDebug = 1

-- Then check debug output for a specific CID
SELECT * FROM RW_BSLDataForAllUsers WHERE CID = @TargetCID
ORDER BY ExecutionID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [ALS - Trigger Liquidation on Staging environment guide](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12952305833) | Confluence | Context on BSL/ALS liquidation triggering process on staging environments; confirms BSL system's role in margin call processing |

No dedicated Confluence page found for Trade.InsertBSLMessagesIntoQueue. Business context inherited from Trade.ManageBSL documentation (documented earlier in this schema).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers (external job) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertBSLMessagesIntoQueue | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertBSLMessagesIntoQueue.sql*
