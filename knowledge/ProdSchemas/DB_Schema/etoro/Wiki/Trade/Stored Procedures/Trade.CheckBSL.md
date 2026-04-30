# Trade.CheckBSL

> Verifies BSL (Balance Stop Loss) execution results by independently recalculating customer equity from position-level PnL and comparing against the BSL engine's output, sending email alerts for discrepancies.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExecutionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckBSL is a post-execution verification procedure for the Balance Stop Loss (BSL) system. BSL is eToro's margin protection mechanism that monitors customer equity in real-time and triggers warnings or forced liquidation when equity falls below thresholds. This procedure independently recalculates what the BSL engine should have produced for a given execution and compares it against actual BSL messages.

This procedure exists because BSL is a critical safety system - incorrect BSL calculations could either fail to protect customers (missing liquidations) or incorrectly liquidate customers (false positives). The verification recalculates unrealized PnL per position using the exact price snapshots from the BSL execution, applies currency conversions, computes total equity, and classifies customers into message types (0=OK, 1=Warning, 2=Liquidation).

When discrepancies are found (customers in the BSL output but not matching the verification), an email alert is sent to the trading team via sp_send_dbmail.

---

## 2. Business Logic

### 2.1 PnL Recalculation from Price Snapshots

**What**: Independently calculates unrealized PnL per position using BSL execution price snapshots.

**Columns/Parameters Involved**: `History.BSLCurrencyPriceSnapShots`, `Trade.Position`, `History.Position`, `History.BSLPositionsInfo`

**Rules**:
- Uses exact prices from the BSL execution (@ExecutionID) via History.BSLCurrencyPriceSnapShots
- PnL = AmountInUnitsDecimal * (CurrentPrice - InitForexRate) * Direction * CurrencyConversion
- Direction: IsBuy=1 -> multiply by 1, IsBuy=0 -> multiply by -1
- CurrentPrice: IsBuy=1 -> Bid, IsBuy=0 -> Ask
- Currency conversion: SellCurrencyID=1 -> 1x, BuyCurrencyID=1 -> 1/price, SellCurrencyID=666 -> GBX rate/100

### 2.2 BSL Message Classification

**What**: Classifies customers into BSL message types based on equity thresholds.

**Columns/Parameters Involved**: `RealizedEquity`, `UnrealizedPnL`, `BonusCredit`, `Last MIMO RealizedEquity`

**Rules**:
- MessageType=2 (Liquidation): RealizedEquity + UnrealizedPnL <= BonusCredit
- MessageType=1 (Warning): Equity <= BonusCredit + (LastMIMORealizedEquity - LastMIMOBonusCredit) * 0.20
- MessageType=0 (OK): Above both thresholds
- WarningType: Further classifies into 10% and 20% warning levels
- Excludes PlayerLevelID=4 and CountryID=250 from BSL

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionID | INT | NO | - | CODE-BACKED | BSL execution cycle ID. References Trade.ManageBSL and History.BSLCurrencyPriceSnapShots for the specific BSL run to verify. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionID | Trade.ManageBSL | SELECT | Gets BSL execution start time and results |
| @ExecutionID | History.ManageBSL | SELECT | Gets historical BSL results for comparison |
| @ExecutionID | History.BSLCurrencyPriceSnapShots | SELECT | Price snapshots used in BSL execution |
| @ExecutionID | History.BSLPositionsInfo | SELECT | Position list included in BSL execution |
| (reads) | Trade.Position | SELECT | Current open positions for PnL calculation |
| (reads) | History.Position | SELECT | Closed positions that were open during execution |
| (reads) | Trade.GetInstrument | SELECT | Instrument details (BuyCurrencyID, SellCurrencyID) |
| (reads) | History.ActiveCredit | SELECT | Credit history for equity calculation |
| (reads) | Customer.Customer | SELECT | Excludes PlayerLevelID=4 and CountryID=250 |
| (reads) | Trade.BSLBlackList | JOIN | BSL blacklist filter |
| (sends) | msdb.dbo.sp_send_dbmail | EXEC | Sends email alert when discrepancies found |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | (external) | EXEC | Run after BSL execution cycles for verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckBSL (procedure)
+-- Trade.ManageBSL (table)
+-- History.ManageBSL (table)
+-- History.BSLCurrencyPriceSnapShots (table)
+-- History.BSLPositionsInfo (table)
+-- Trade.Position (view)
+-- History.Position (table)
+-- Trade.GetInstrument (view/synonym)
+-- History.ActiveCredit (table)
+-- Customer.Customer (table)
+-- Trade.BSLBlackList (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManageBSL | Table | SELECT execution metadata and results |
| History.ManageBSL | Table | SELECT historical BSL results |
| History.BSLCurrencyPriceSnapShots | Table | SELECT price snapshots for PnL calc |
| History.BSLPositionsInfo | Table | SELECT positions included in BSL run |
| Trade.Position | View | SELECT current position data |
| History.Position | Table | SELECT closed position data |
| Trade.GetInstrument | View | SELECT instrument currency info |
| History.ActiveCredit | Table | SELECT credit history for equity |
| Customer.Customer | Table | SELECT for exclusion filters |
| Trade.BSLBlackList | Table | JOIN for blacklist filtering |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Job | External | Post-BSL verification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query Hint | Used on main queries because @ExecutionID varies widely |
| Temp table clustered indexes | Performance | #PnL and #LastOp get clustered indexes for JOIN performance |
| Email alert | Notification | sp_send_dbmail sends HTML table to trading team on MessageType=2 discrepancies |

---

## 8. Sample Queries

### 8.1 Run BSL verification for a specific execution

```sql
EXEC Trade.CheckBSL @ExecutionID = 77229;
```

### 8.2 Check recent BSL executions

```sql
SELECT TOP 10 ExecutionID, MIN(TimeMessageInsertedToQueue) AS StartTime,
       COUNT(*) AS MessageCount
FROM   Trade.ManageBSL WITH (NOLOCK)
GROUP BY ExecutionID
ORDER BY ExecutionID DESC;
```

### 8.3 Check BSL results for a specific customer

```sql
SELECT MessageType, WarningType, CID, RealizedEquity,
       UnRealizedEquity, BonusCredit, BSLRealFunds
FROM   Trade.ManageBSL WITH (NOLOCK)
WHERE  ExecutionID = @ExecutionID
       AND CID = @CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CheckBSL | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CheckBSL.sql*
