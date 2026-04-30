# BackOffice.GetCustomerClosedPositions

> Returns the closed trading position history for a customer within a date range, with instrument details, open/close rates, profit, copy-trading linkage, CFD vs real stock flag, and processing latency metrics.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @DateFrom / @DateTo on History.Position.CloseOccurred |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure shows the BackOffice agent a customer's closed position history - each row representing one trade that was opened and subsequently closed within the given date window. It combines core position data (instrument, direction, amounts, rates, profit) with supplementary metrics: total compensation adjustments, whether the position was excluded from statistics, whether it was a recurring investment, and how long the close operation took to process.

The procedure covers both CFD (leveraged synthetic) positions and Real Stock positions (actual share purchases), distinguished by the `[Is Real]` column. Copy-trading positions are identified by a non-zero `[Mirror ID]`.

---

## 2. Business Logic

### 2.1 CFD vs Real Stock Classification

**What**: [Is Real] classifies whether the position was a CFD or a real stock/asset position.

**Columns/Parameters Involved**: `[Is Real]`, `HPOS.IsSettled`

**Rules**:
```
CASE WHEN HPOS.IsSettled=0 THEN 'CFD'
     WHEN HPOS.IsSettled=1 THEN 'Real'
     ELSE '' END
```
- IsSettled=0: CFD (Contract for Difference) - customer holds a synthetic derivative, no actual asset ownership
- IsSettled=1: Real stock position - customer actually owns the underlying shares/asset
- Empty string for other values (data anomaly guard)

### 2.2 Recurring Investment Flag

**What**: [Recurring] identifies positions opened through the recurring investment feature.

**Columns/Parameters Involved**: `[Recurring]`, `HPOS.OpenActionType`

**Rules**:
- `CASE HPOS.OpenActionType WHEN 17 THEN 'Yes' ELSE 'No' END`
- ActionType=17 = recurring (automatic periodic investment)
- Recurring positions are opened automatically on a schedule without manual customer action

### 2.3 Initial Amount vs Current Amount

**What**: Two amount columns capture the original investment and the current position amount.

**Columns/Parameters Involved**: `[Initial Amount]`, `Amount`, `HPOS.InitialAmountCents`, `HPOS.Amount`

**Rules**:
- `[Initial Amount]` = InitialAmountCents / 100 - the original investment at open time, stored as integer cents in the source
- `Amount` = HPOS.Amount - the current/adjusted amount at close (may differ from initial due to mirror amount changes, copy adjustments)
- Both cast to DECIMAL(16,2)

### 2.4 Close Latency

**What**: [Close Latency(ms)] measures the delay between when the close was logged in the engine (EndDateTime) and when it was recorded in the database (CloseOccurred).

**Columns/Parameters Involved**: `[Close Latency(ms)]`, `HPOS.EndDateTime`, `HPOS.CloseOccurred`

**Rules**:
- `DATEDIFF(millisecond, HPOS.EndDateTime, HPOS.CloseOccurred)` - positive = database record was later than engine close
- Used in operations monitoring to detect processing delays
- Large values may indicate system backlog or timing issues

### 2.5 Duration Guard for Negative Values

**What**: [Duration (Minutes)] is floored at 0 to handle data anomalies where CloseOccurred precedes OpenOccurred.

**Columns/Parameters Involved**: `[Duration (Minutes)]`, `HPOS.OpenOccurred`, `HPOS.CloseOccurred`

**Rules**:
- `CASE WHEN DATEDIFF(minute, OpenOccurred, CloseOccurred) > 0 THEN DATEDIFF(...) ELSE 0 END`
- Negative durations (clock skew or data issues) are clamped to 0

### 2.6 Original Position ID - Reopen Detection

**What**: [Original PosID] identifies positions that were reopened from another position.

**Columns/Parameters Involved**: `[Original PosID]`, `HPOS.OriginalPositionID`, `HPOS.PositionID`

**Rules**:
- `CASE WHEN OriginalPositionID = PositionID THEN NULL ELSE OriginalPositionID END`
- If OriginalPositionID = PositionID: the position was opened fresh (not a reopen); returns NULL
- If OriginalPositionID != PositionID: this position was reopened from the OriginalPositionID (e.g., after stop-loss hit and manual reopen); returns the original position ID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose closed positions to return. |
| 2 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of the date window applied to History.Position.CloseOccurred. |
| 3 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of the date window applied to History.Position.CloseOccurred. |
| **Output Columns** | | | | | | |
| 4 | PositionID | INT | NO | - | CODE-BACKED | Unique identifier of the closed position. PK of History.Position. |
| 5 | Buy/Sell | VARCHAR(8) | NO | - | CODE-BACKED | Trade direction with trailing space: 'Buy ' or 'Sell ' or 'Unknown '. From IsBuy flag. |
| 6 | Instrument | NVARCHAR | NO | - | CODE-BACKED | Display name of the traded instrument. From Trade.InstrumentMetaData.InstrumentDisplayName. |
| 7 | Instrument ID | INT | NO | - | CODE-BACKED | Numeric instrument identifier. |
| 8 | Initial Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | Original investment amount when position was opened. From HPOS.InitialAmountCents / 100 (stored as integer cents). |
| 9 | Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | Position amount at close (may differ from Initial Amount for mirror/copy adjustments). From HPOS.Amount. |
| 10 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier applied to the position. |
| 11 | Units | DECIMAL | YES | - | CODE-BACKED | Number of instrument units held. From HPOS.AmountInUnitsDecimal. |
| 12 | Open Rate | DECIMAL(16,6) | YES | - | CODE-BACKED | Exchange rate at which the position was opened. From HPOS.InitForexRate. |
| 13 | Close Rate | DECIMAL(16,6) | YES | - | CODE-BACKED | Exchange rate at which the position was closed. From HPOS.EndForexRate. |
| 14 | Close Reason | NVARCHAR | YES | - | CODE-BACKED | Why the position was closed. From Dictionary.ClosePositionActionType.ClosePositionActionName via HPOS.ActionType. Examples: "Customer Request", "Stop Loss", "Take Profit", "Copy Stop". |
| 15 | Commission | DECIMAL(16,2) | YES | - | CODE-BACKED | Commission charged at close. From HPOS.CommissionOnClose. |
| 16 | Profit | DECIMAL(16,2) | YES | - | CODE-BACKED | Net realized profit/loss on the position. From HPOS.NetProfit. Negative = loss. |
| 17 | Init DateTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the position was initialized in the trading engine. From HPOS.InitDateTime. |
| 18 | End DateTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the close was processed by the trading engine. From HPOS.EndDateTime. |
| 19 | Stop Rate | DECIMAL(16,6) | YES | - | CODE-BACKED | Stop-loss rate on the position. From HPOS.StopRate. |
| 20 | Limit Rate | DECIMAL(16,6) | YES | - | CODE-BACKED | Take-profit rate on the position. From HPOS.LimitRate. |
| 21 | Mirror ID | INT | YES | - | CODE-BACKED | ID of the copy-trading relationship that opened this position. From HPOS.MirrorID. Non-zero for copy-trading positions; 0 or NULL for manual trades. |
| 22 | Duration (Minutes) | INT | NO | 0 | CODE-BACKED | How long the position was open in minutes: DATEDIFF(minute, OpenOccurred, CloseOccurred). Clamped to 0 if negative (see section 2.5). |
| 23 | Parent PosID | INT | YES | - | CODE-BACKED | Parent position ID for copy-trading positions. From HPOS.ParentPositionID. Links this position to the original trader's position being copied. |
| 24 | Original Parent PosID | INT | YES | - | CODE-BACKED | Original parent position ID before any reopen operations. From HPOS.OrigParentPositionID. |
| 25 | Original PosID | INT | YES | NULL | CODE-BACKED | The position this was reopened from. NULL if the position was opened fresh (OriginalPositionID = PositionID). Non-NULL indicates this is a reopened position. See section 2.6. |
| 26 | Close Latency(ms) | INT | YES | - | CODE-BACKED | Milliseconds between engine close (EndDateTime) and database record (CloseOccurred). Operations metric for processing delay detection. See section 2.4. |
| 27 | Total Compensation | DECIMAL | YES | NULL | CODE-BACKED | Total compensation adjustments applied to this position. From History.Position_Extra.TotalCompensation. NULL if no extra record. |
| 28 | Is Open Open | VARCHAR(3) | NO | No | CODE-BACKED | Whether the position was opened at market open (pre-market). 'Yes' if IsOpenOpen=1, 'No' otherwise. |
| 29 | Excluded From Statistics | VARCHAR(3) | NO | No | CODE-BACKED | Whether this position is excluded from the customer's statistics/performance calculation. 'Yes' if History.Position_Extra.ExcludeFromStatistics=1. |
| 30 | Is Real | VARCHAR(3) | NO | '' | CODE-BACKED | Position type: 'CFD' (IsSettled=0), 'Real' (IsSettled=1), or '' for other. See section 2.1. |
| 31 | Close Total Fees | DECIMAL(16,2) | YES | NULL | CODE-BACKED | Total fees charged at close. From History.PositionForExternalUse.CloseTotalFees. NULL if not available. |
| 32 | Recurring | VARCHAR(3) | NO | No | CODE-BACKED | Whether the position was opened by a recurring investment: 'Yes' if OpenActionType=17, 'No' otherwise. See section 2.2. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID / PositionID | History.Position | Primary Source | Core closed position data |
| PositionID | History.Position_Extra | Lookup / LEFT JOIN | Supplementary data: compensation, statistics exclusion |
| InstrumentID | Trade.InstrumentMetaData | Lookup / JOIN | Instrument display name and ID |
| ActionType | Dictionary.ClosePositionActionType | Lookup / JOIN | Close reason name |
| PositionID | History.PositionForExternalUse | Lookup / LEFT JOIN | Close total fees |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Customer closed positions history tab |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerClosedPositions (procedure)
|- History.Position (primary - closed position records)
|- History.Position_Extra (compensation + statistics flags)
|- Trade.InstrumentMetaData (instrument name)
|- Dictionary.ClosePositionActionType (close reason)
+-- History.PositionForExternalUse (close fees)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Primary source - all closed positions for CID in date range |
| History.Position_Extra | Table | LEFT JOINed for TotalCompensation and ExcludeFromStatistics |
| Trade.InstrumentMetaData | Table | JOINed to resolve InstrumentID to display name |
| Dictionary.ClosePositionActionType | Table | JOINed to resolve ActionType to close reason name |
| History.PositionForExternalUse | Table | LEFT JOINed for CloseTotalFees |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Closed positions history tab in customer profile |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- No OPTION(Recompile) or WITH(NOLOCK) inconsistency: NOLOCK is used on all joined tables.
- ORDER BY HPOS.CloseOccurred DESC - most recently closed positions first.

---

## 8. Sample Queries

### 8.1 Get closed positions in a date range

```sql
EXEC BackOffice.GetCustomerClosedPositions
    @CID      = 12345678,
    @DateFrom = '2026-01-01',
    @DateTo   = '2026-03-17';
```

### 8.2 Find only Real Stock (IsSettled=1) closed positions

```sql
SELECT PositionID, InstrumentID, InitForexRate, EndForexRate, NetProfit,
    CloseOccurred, ActionType
FROM History.Position WITH(NOLOCK)
WHERE CID = 12345678
    AND IsSettled = 1
    AND CloseOccurred BETWEEN '2026-01-01' AND '2026-03-17'
ORDER BY CloseOccurred DESC;
```

### 8.3 Find recurring investment positions

```sql
SELECT PositionID, InstrumentID, NetProfit, CloseOccurred
FROM History.Position WITH(NOLOCK)
WHERE CID = 12345678
    AND OpenActionType = 17
    AND CloseOccurred BETWEEN '2026-01-01' AND '2026-03-17';
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerClosedPositions | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerClosedPositions.sql*
