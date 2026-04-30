# Trade.AlertForExitOrders_which_should_have_clsoed

> Legacy variant of the orphaned exit orders alert that uses the Trade.Position view directly without temp table staging or OME enrichment. Note the misspelled name ("clsoed" instead of "closed").

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Recipients, @Copy_Recipients |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is an older variant of the orphaned exit orders alert (`Trade.AlertForExitOrders_which_should_have_closed`). It detects pending exit orders (SL/TP) where market prices have been received but the order remains unfulfilled, indicating a potential system failure. The procedure name contains a typo ("clsoed" instead of "closed") that has been preserved for backward compatibility.

This variant differs from the corrected-name version in that it: (1) queries the `Trade.Position` view directly instead of `Trade.PositionTbl`, (2) does not use temp tables for the initial position scan, (3) does not include OME (Order Matching Engine) enrichment, (4) does not support PagerDuty integration, and (5) does not exclude specific instruments.

The data flow is the same: find exit orders with StatusID=1 where CurrencyPrice.ReceivedOnPriceServer > OpenOccurred, enrich with fail history from History.PositionFail, generate HTML, and email via sp_send_dbmail.

---

## 2. Business Logic

### 2.1 Simplified Orphan Detection

**What**: Simpler query than the corrected-name variant - joins exit orders directly to Position view and CurrencyPrice without staging.

**Rules**:
- Uses Trade.Position view (not PositionTbl) with NOLOCK for the EXISTS check
- No instrument exclusion list
- No temp table staging - queries directly into SELECT...INTO for the detail step
- OPTION(RECOMPILE) on the fail history outer apply
- Also includes a `SELECT @tableHTML` debug statement before sending email

### 2.2 Email Notification

**What**: Same dual-table email format as the corrected-name variant.

**Rules**:
- Aggregate table by InstrumentID with sums of Amount and AmountInUnitsDecimal
- Detail table with OrderID, CID, PositionID, amounts, dates, fail info
- Same recipients, subject, and formatting as the family of alert procedures

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Recipients | varchar(max) | YES | 'tradingbackend@etoro.com;pinikr@etoro.com;yitzchakwa@etoro.com;' | CODE-BACKED | Email recipients for the alert notification. |
| 2 | @Copy_Recipients | varchar(max) | YES | '' | CODE-BACKED | CC recipients for the alert email. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Trade.OrdersExitTbl | READER | Pending exit orders (StatusID=1) |
| JOIN | Trade.Position (view) | READER | Position details |
| JOIN | Trade.CurrencyPrice | READER | Latest market prices |
| JOIN | Trade.InstrumentMetaData | READER | Instrument display names |
| OUTER APPLY | History.PositionFail | READER | Recent failure reasons |
| EXEC | msdb.dbo.sp_send_dbmail | System call | HTML email alert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (SQL Agent job) | - | Scheduler | Periodic alert check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertForExitOrders_which_should_have_clsoed (procedure)
+-- Trade.OrdersExitTbl (table)
+-- Trade.Position (view)
+-- Trade.CurrencyPrice (table)
+-- Trade.InstrumentMetaData (table)
+-- History.PositionFail (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExitTbl | Table | READER - pending exit orders |
| Trade.Position | View | READER - position details |
| Trade.CurrencyPrice | Table | READER - market price timestamps |
| Trade.InstrumentMetaData | Table | READER - instrument names |
| History.PositionFail | Table | READER - fail history |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run the legacy alert

```sql
EXEC Trade.AlertForExitOrders_which_should_have_clsoed;
```

### 8.2 Run with custom recipients

```sql
EXEC Trade.AlertForExitOrders_which_should_have_clsoed
    @Recipients = 'dba_team@etoro.com;',
    @Copy_Recipients = '';
```

### 8.3 Preview orphaned exit orders

```sql
SELECT  O.OrderID, O.CID, O.PositionID, P.InstrumentID, O.OpenOccurred, C.ReceivedOnPriceServer
FROM    Trade.OrdersExitTbl O WITH (NOLOCK)
JOIN    Trade.Position P WITH (NOLOCK) ON O.PositionID = P.PositionID
JOIN    Trade.CurrencyPrice C WITH (NOLOCK) ON P.InstrumentID = C.InstrumentID
WHERE   O.OpenOccurred < C.ReceivedOnPriceServer
        AND O.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertForExitOrders_which_should_have_clsoed | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertForExitOrders_which_should_have_clsoed.sql*
