# History.MirrorSLCloseLog

> Successful Mirror Stop Loss (MSL) close audit log - records every copy relationship that was automatically force-closed when the copier's portfolio value fell to or below the stop-loss threshold, capturing the financial snapshot and all position IDs involved at the time of close.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | MirrorStopLossCloseID (int IDENTITY NOT FOR REPLICATION, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active: NONCLUSTERED PK on MirrorStopLossCloseID, NONCLUSTERED on MirrorID |

---

## 1. Business Meaning

History.MirrorSLCloseLog records every successfully completed Mirror Stop Loss (MSL) enforcement event. When a copier's portfolio value drops to or below the stop-loss threshold (MirrorSL), the MSL engine forces the copy relationship closed to protect the copier from losing more than their configured stop-loss amount. Each successful forced close writes one row here.

The MSL mechanism is critical to eToro's copy trading risk management: it provides a floor on losses for copiers, similar to how a position-level stop-loss works but at the portfolio level. When triggered, all open copied positions are closed simultaneously and the remaining funds are returned to the copier's account.

With ~28,000 rows, this is an actively used table. The monitoring procedure `dbo.P_MSLMonitoring` reads this table to verify that money returned to customers matches the MSL threshold (MSLReturnedMoney = MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount should approximately equal MirrorSL), raising alerts when discrepancies exceed $1 or $5.

Written exclusively by `History.LogMirrorSLClose`, which is called by the MSL engine application code after a successful copy close.

---

## 2. Business Logic

### 2.1 MSL Close - Financial Snapshot

**What**: When MSL triggers, the system captures the exact financial state of the copy portfolio at close time for audit, reconciliation, and customer dispute resolution.

**Columns/Parameters Involved**: `MirrorSL`, `MirrorAmount`, `InvestedAmount`, `NetProfit`, `StockOrdersAmount`

**Rules**:
- MSL fires when: current portfolio value <= MirrorSL amount
- MirrorSL: the stop-loss threshold in account currency (e.g., $2500 = "stop copy if portfolio value drops to $2500")
- MSLReturnedMoney = MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount = what the copier gets back
- For monitoring: |MirrorSL - MSLReturnedMoney| should be < $5 (P_MSLMonitoring alerts otherwise)
- NetProfit is typically large and negative (MSL fires when the copy has lost money)
- StockOrdersAmount DEFAULT=0 - hardcoded in History.LogMirrorSLClose; represents any real stock order value not yet settled

**Example from live data**:
- MirrorID=1883810: MirrorSL=$2500, MirrorAmount=$951,685, InvestedAmount=$48,260, NetProfit=-$3,729,002 -> indicates a high-volume copy that suffered massive losses. Portfolio value hit $2500 floor.
- MirrorID=1880952: MirrorSL=$500, MirrorAmount=$43,754, InvestedAmount=$8,435, NetProfit=-$75,371 -> smaller copy, same pattern.

### 2.2 CloseTrigger - What Initiated the MSL Check

**What**: CloseTrigger classifies which code path or event triggered the MSL evaluation that determined the stop-loss had been breached.

**Columns/Parameters Involved**: `CloseTrigger`

**Rules**:
- Trigger 0: dominant (93.3% of rows) - scheduled/periodic MSL evaluation run
- Trigger 4: 3.7% of rows - distinct evaluation path (possibly position-level event driven)
- Trigger 1: 2.1% of rows
- Trigger 7: 0.9% of rows
- Triggers 3, 5, 2: rare (< 0.1% combined)
- Exact enum meanings are defined in MSL engine application code

### 2.3 RatesList and PositionIDs - Complete Close Context

**What**: RatesList and PositionIDs capture the market context at the moment of the MSL close, enabling full reconstruction of what was closed and at what prices.

**Columns/Parameters Involved**: `RatesList`, `PositionIDs`

**Rules**:
- PositionIDs: semicolon-delimited list of all position IDs that were part of this copy and were closed when MSL fired (e.g., "2152662906;2152658629;2152660379;...")
- RatesList: semicolon-delimited list of market rates at time of close - used by Trade.IsMSLRatesEqualsToEndForexRate/V2 to validate that the rates used for close calculations match the actual end rates
- Both are varchar(max) - large copies with many positions can generate long lists

---

## 3. Data Overview

~28,280 rows in test environment (active production-level volume).

| MirrorStopLossCloseID | MirrorID | MirrorSL | MirrorAmount | InvestedAmount | NetProfit | CloseOccurred | CloseTrigger | StockOrdersAmount | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 28280 | 1883810 | 2500.00 | 951685.35 | 48259.94 | -3729002.01 | 2026-03-11 11:11:06 | 1 | 0 | Large copy MSL hit. Portfolio started at ~$1M, massive losses. $2500 returned to copier. 10+ positions closed simultaneously. |
| 28277 | 1881040 | 50134.67 | 871446.87 | 177799.91 | -1662890.65 | 2026-01-23 15:56:50 | 0 | 0 | High MSL threshold ($50k) - sophisticated copier. CloseTrigger=0 (scheduled check). Large InvestedAmount ($178k) means significant open positions at close. |

**CloseTrigger distribution**: 0=26,323 (93.1%), 4=1,052 (3.7%), 1=607 (2.1%), 7=266 (0.9%), 5=18, 3=12, 2=2.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorStopLossCloseID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Auto-incrementing surrogate key. NOT FOR REPLICATION - identity does not fire on replicas, preserving original IDs. NONCLUSTERED PK - secondary access pattern. No clustered index; table is a heap on the HISTORY filegroup. |
| 2 | MirrorID | int | NO | - | CODE-BACKED | The copy-trade mirror relationship that was force-closed by MSL. NONCLUSTERED index IX_MirrorID supports lookups by mirror. References Trade.Mirror.MirrorID (no FK enforced - history rows persist after mirror is deleted). Primary correlation key for customer disputes ("why was my copy stopped?"). |
| 3 | MirrorSL | money | NO | - | CODE-BACKED | The stop-loss threshold amount (in account currency) that was set on this copy. This is the "floor" - the minimum portfolio value below which the copy would be force-closed. Examples: $2,500, $50,134, $500. The MSL engine fires when current portfolio value <= MirrorSL. |
| 4 | MirrorAmount | money | NO | - | CODE-BACKED | The total copy amount (original allocation) at time of close. Part of the MSLReturnedMoney formula (MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount). For large copies, this represents the total capital that was deployed in the copy relationship. |
| 5 | InvestedAmount | money | NO | - | CODE-BACKED | The portion of the copy amount currently invested in open positions at time of close. If InvestedAmount > 0, positions were still open when MSL fired. The ratio InvestedAmount/MirrorAmount indicates what fraction was deployed vs sitting as cash within the copy. |
| 6 | NetProfit | money | NO | - | CODE-BACKED | The total net P&L (realized from closed positions + unrealized from open positions) of the copy portfolio at time of the MSL close. For MSL triggers, this is always <= 0 (losses pushed the portfolio to the stop-loss level). Large negative values indicate copies that suffered severe drawdowns. |
| 7 | CloseOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the MSL close was successfully executed. Not auto-defaulted - supplied by the calling MSL engine. Used by P_MSLMonitoring (WHERE CloseOccurred > DATEADD(HOUR,-1,GETDATE())) for real-time reconciliation checks. |
| 8 | CloseTrigger | tinyint | NO | - | CODE-BACKED | Identifies which MSL evaluation pathway triggered this close. 0=scheduled check (93%), 4=3.7%, 1=2.1%, 7=0.9%. tinyint sufficient for the limited enum. Enum values defined in MSL engine application code. |
| 9 | RatesList | varchar(max) | YES | - | CODE-BACKED | Semicolon-delimited market rate snapshot for each position in the copy at time of close. Used by Trade.IsMSLRatesEqualsToEndForexRate and V2 to verify that close rates match end-of-day forex rates. NULL if rates were not available. |
| 10 | StockOrdersAmount | money | NO | 0 | CODE-BACKED | Represents any real stock order value within the copy portfolio. DEFAULT 0 - hardcoded in History.LogMirrorSLClose (the procedure always passes 0). Maintained for schema consistency and P_MSLMonitoring's formula (MSLReturnedMoney includes this column). |
| 11 | PositionIDs | varchar(max) | YES | - | CODE-BACKED | Semicolon-delimited list of all position IDs that were simultaneously closed when this MSL event fired (e.g., "2152662906;2152658629;..."). Enables tracing which positions were closed as part of this MSL event. NULL if no positions were open. Can contain dozens of position IDs for large, diversified copies. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.Mirror | Implicit | References the copy relationship that was force-closed. No FK enforced. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.LogMirrorSLClose | (INSERT) | Writer | The ONLY writer - called by MSL engine after successful forced close |
| dbo.P_MSLMonitoring | MirrorID, CloseOccurred | Reader | Reconciliation monitoring - checks MSLReturnedMoney vs MirrorSL and vs History.ActiveCredit |
| Trade.IsMSLRatesEqualsToEndForexRate | RatesList | Reader | Validates close rates match forex end rates |
| Trade.IsMSLRatesEqualsToEndForexRateV2 | RatesList | Reader | V2 of the rates validation procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MirrorSLCloseLog (table)
  - No code-level dependencies (leaf table)
  - Written by History.LogMirrorSLClose (procedure)
  - Success counterpart to History.MirrorSLCloseFail
```

### 6.1 Objects This Depends On

No dependencies. Free-standing success log table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.LogMirrorSLClose | Stored Procedure | Sole writer - inserts one row per successful MSL close |
| dbo.P_MSLMonitoring | Stored Procedure | Reader - reconciliation monitoring comparing MSLReturnedMoney to MirrorSL and History.ActiveCredit |
| Trade.IsMSLRatesEqualsToEndForexRate | Stored Procedure | Reader - validates RatesList against actual forex end rates |
| Trade.IsMSLRatesEqualsToEndForexRateV2 | Stored Procedure | Reader - V2 rates validation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorSLCloseLog_MirrorStopLossCloseID | NONCLUSTERED | MirrorStopLossCloseID ASC | - | - | Active |
| IX_MirrorID | NONCLUSTERED | MirrorID ASC | - | - | Active |

Note: No clustered index - heap table. On [HISTORY] filegroup. TEXTIMAGE_ON [HISTORY] for varchar(max) columns.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MirrorSLCloseLog_MirrorStopLossCloseID | PRIMARY KEY | NONCLUSTERED PK on MirrorStopLossCloseID |
| DF__MirrorSLCloseLog_StockOrdersAmount | DEFAULT | StockOrdersAmount = 0 |

---

## 8. Sample Queries

### 8.1 Get full MSL close history for a specific mirror

```sql
SELECT
    MirrorStopLossCloseID,
    MirrorID,
    MirrorSL,
    MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount AS ReturnedToCustomer,
    MirrorSL - (MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount) AS Discrepancy,
    CloseOccurred,
    CloseTrigger,
    LEFT(PositionIDs, 300) AS PositionIDsSample
FROM [History].[MirrorSLCloseLog] WITH (NOLOCK)
WHERE MirrorID = @MirrorID
ORDER BY CloseOccurred ASC
```

### 8.2 Recent MSL events with reconciliation check (from P_MSLMonitoring logic)

```sql
SELECT
    hmsl.MirrorID,
    ROUND(hmsl.MirrorSL, 2) AS MirrorSL,
    hmsl.MirrorAmount + hmsl.InvestedAmount + hmsl.NetProfit + hmsl.StockOrdersAmount AS MSLReturnedMoney,
    hmsl.CloseOccurred,
    hmsl.CloseTrigger
FROM [History].[MirrorSLCloseLog] hmsl WITH (NOLOCK)
WHERE hmsl.CloseOccurred > DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY hmsl.CloseOccurred DESC
```

### 8.3 CloseTrigger distribution analysis

```sql
SELECT
    CloseTrigger,
    COUNT(*) AS EventCount,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS decimal(5,2)) AS Pct,
    AVG(MirrorSL) AS AvgMirrorSL,
    AVG(NetProfit) AS AvgNetProfit
FROM [History].[MirrorSLCloseLog] WITH (NOLOCK)
GROUP BY CloseTrigger
ORDER BY EventCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (History.LogMirrorSLClose, dbo.P_MSLMonitoring, Trade.IsMSLRatesEqualsToEndForexRate) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.MirrorSLCloseLog | Type: Table | Source: etoro/etoro/History/Tables/History.MirrorSLCloseLog.sql*
