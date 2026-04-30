# Trade.AlertForExitOrders_which_should_have_closed

> Detects orphaned exit orders (stop loss, take profit) that should have triggered but remain open, and sends an HTML email alert to the trading backend team with detailed position data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Recipients, @Copy_Recipients, @CallFromPagerDuty |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a critical operational alert that identifies exit orders (stop loss, take profit, or similar pending close orders) that should have been executed based on current market prices but remain in an open/pending state. These "orphaned" exit orders represent a significant business risk - customers expect their protective orders to trigger when prices hit the threshold, and failure to close means potential additional losses.

Without this alert, the team would have no automated way to detect stuck exit orders. In a fast-moving market, even a short delay can result in significant financial impact for both customers and the platform's risk exposure.

The procedure works by joining `Trade.OrdersExitTbl` (pending exit orders with StatusID=1) to `Trade.PositionTbl` (the positions they protect), then cross-referencing against `Trade.CurrencyPrice` (latest market prices). If the price received on the price server is more recent than the position's open time, the exit order should have seen that price and triggered. Orphaned orders are enriched with fail history from `History.PositionFail` and instrument names from `Trade.InstrumentMetaData`, then emailed as an HTML report. When called from PagerDuty (@CallFromPagerDuty=1), it returns a result set instead of sending email.

---

## 2. Business Logic

### 2.1 Orphan Detection Algorithm

**What**: Identifies exit orders where market prices have been received but the order remains pending.

**Columns/Parameters Involved**: `OrdersExitTbl.StatusID`, `PositionTbl.InstrumentID`, `PositionTbl.OpenOccurred`, `CurrencyPrice.ReceivedOnPriceServer`

**Rules**:
- Exit orders with StatusID=1 (pending/active) are candidates
- Instruments 3011, 8620, and 8650 are excluded (known exceptions)
- For each pending exit order, check if `CurrencyPrice.ReceivedOnPriceServer > Position.OpenOccurred` for the same instrument
- If a price was received after the position opened and the exit order is still pending, it is potentially orphaned
- The procedure also cross-references `Trade.InstrumentsOmeID` to tag each position with its OME (Order Matching Engine) ID

**Diagram**:
```
OrdersExitTbl (StatusID=1)
    |
    JOIN PositionTbl (get InstrumentID, OpenOccurred)
    |
    JOIN InstrumentsOmeID (get OMEID)
    |
    JOIN CurrencyPrice (OpenOccurred < ReceivedOnPriceServer?)
    |
    +-- YES: Orphaned exit order (should have triggered)
    +-- NO: Not yet - price not received after open
```

### 2.2 Dual Output Mode

**What**: The procedure supports two output modes depending on the caller.

**Columns/Parameters Involved**: `@CallFromPagerDuty`, `@Recipients`, `@Copy_Recipients`

**Rules**:
- @CallFromPagerDuty = 0 (default): Builds HTML tables and sends via sp_send_dbmail
- @CallFromPagerDuty = 1: Returns PositionID and OMEID as a result set for programmatic consumption
- Email includes two HTML tables: detailed per-order data and an aggregate summary by InstrumentID
- If no orphaned orders exist, the procedure prints a message and returns without sending email

### 2.3 Fail History Enrichment

**What**: Orphaned orders are enriched with the most recent failure reason from History.PositionFail.

**Rules**:
- Uses OUTER APPLY with TOP 1 to get the latest fail within 30 days
- FailReason and FailOccurred are included in the email table for diagnosis
- Not all orphaned orders have a fail history record - some may be stuck without a logged failure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Recipients | varchar(max) | YES | 'tradingbackend@etoro.com;pinikr@etoro.com;yitzchakwa@etoro.com;' | CODE-BACKED | Email recipients for the alert. Semicolon-delimited list of email addresses. Default targets the trading backend team. |
| 2 | @Copy_Recipients | varchar(max) | YES | '' | CODE-BACKED | CC recipients for the alert email. Empty string by default. |
| 3 | @CallFromPagerDuty | bit | YES | 0 | CODE-BACKED | Output mode toggle. 0 = send HTML email alert. 1 = return result set (PositionID, OMEID) for PagerDuty integration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Trade.OrdersExitTbl | READER | Pending exit orders (StatusID=1) |
| JOIN | Trade.PositionTbl | READER | Position details for the exit orders |
| JOIN | Trade.CurrencyPrice | READER | Latest market prices per instrument |
| JOIN | Trade.InstrumentsOmeID | READER | OME assignment per instrument |
| JOIN | Trade.Position (view) | READER | Position view for Amount and AmountInUnitsDecimal |
| JOIN | Trade.InstrumentMetaData | READER | Instrument display names |
| OUTER APPLY | History.PositionFail | READER | Most recent failure reason within 30 days |
| EXEC | msdb.dbo.sp_send_dbmail | System call | Sends HTML email alert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (SQL Agent job) | - | Scheduler | Periodic execution to detect orphaned exit orders |
| (PagerDuty integration) | - | Caller | Called with @CallFromPagerDuty=1 for automated incident creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertForExitOrders_which_should_have_closed (procedure)
+-- Trade.OrdersExitTbl (table)
+-- Trade.PositionTbl (table)
+-- Trade.Position (view)
+-- Trade.CurrencyPrice (table)
+-- Trade.InstrumentsOmeID (table)
+-- Trade.InstrumentMetaData (table)
+-- History.PositionFail (table)
+-- msdb.dbo.sp_send_dbmail (system procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExitTbl | Table | READER - pending exit orders (StatusID=1) |
| Trade.PositionTbl | Table | READER - position details (InstrumentID, OpenOccurred) |
| Trade.Position | View | READER - Amount and AmountInUnitsDecimal for email detail |
| Trade.CurrencyPrice | Table | READER - latest market prices per instrument |
| Trade.InstrumentsOmeID | Table | READER - OME assignment per instrument |
| Trade.InstrumentMetaData | Table | READER - InstrumentDisplayName |
| History.PositionFail | Table | READER - failure reasons for enrichment |
| msdb.dbo.sp_send_dbmail | System Procedure | Sends alert email |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No SQL-level dependents found) | - | Called by SQL Agent and PagerDuty |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | Used on key queries to account for varying data sizes |
| Temp table indexes | Performance | #position has PK on PositionID + NC IX on (OpenOccurred, InstrumentID) |

---

## 8. Sample Queries

### 8.1 Run the alert for email delivery

```sql
EXEC Trade.AlertForExitOrders_which_should_have_closed;
```

### 8.2 Run for PagerDuty (result set mode)

```sql
EXEC Trade.AlertForExitOrders_which_should_have_closed
    @CallFromPagerDuty = 1;
```

### 8.3 Preview orphaned exit orders without sending email

```sql
SELECT  O.PositionID, P.InstrumentID, P.OpenOccurred, C.ReceivedOnPriceServer
FROM    Trade.OrdersExitTbl O WITH (NOLOCK)
JOIN    Trade.PositionTbl P WITH (NOLOCK) ON O.PositionID = P.PositionID
JOIN    Trade.CurrencyPrice C WITH (NOLOCK) ON P.InstrumentID = C.InstrumentID
WHERE   O.StatusID = 1
        AND P.OpenOccurred < C.ReceivedOnPriceServer
        AND P.InstrumentID NOT IN (3011, 8620, 8650);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertForExitOrders_which_should_have_closed | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertForExitOrders_which_should_have_closed.sql*
