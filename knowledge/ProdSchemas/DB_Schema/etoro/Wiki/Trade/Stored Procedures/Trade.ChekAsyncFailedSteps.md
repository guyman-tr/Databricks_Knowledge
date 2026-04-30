# Trade.ChekAsyncFailedSteps

> Retries failed asynchronous steps of the position close flow using bitmask-driven selective step execution, including demo refill, redeem status update, service broker notification, contract rollover messaging, position change logging, and detached mirror history.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (from @Params XML) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChekAsyncFailedSteps (note: "Chek" is a typo for "Check") is a recovery procedure for the position close workflow. When a position is closed, multiple post-close steps execute (billing, notifications, logging). If any step fails, its bit is recorded in @PartsToDo bitmask and this procedure is called later to retry only the failed steps.

The procedure parses an XML payload (@Params) containing all the close-operation context (PositionID, equities, session info, partial close details, rates, redeem info) and selectively executes steps based on the @PartsToDo bitmask:

| Bit | Value | Step |
|-----|-------|------|
| 2 | 4 | Demo account refill (Billing.AmountAdd if TotalCash <= 500 and no open positions) |
| 3 | 8 | Billing.RedeemStatusUpdate for real accounts with active redeems |
| 7 | 128 | Service Broker notification to Trade Server (for ActionType 2=EOF, 7=Rollover) |
| 12 | 4096 | Customer.SendMessage for contract rollover (ActionType=7, offline users) |
| 13 | 8192 | History.PositionChangeLog_Insert (close/partial close audit trail) |
| 14 | 16384 | History.Mirror update for detached positions |
| 15 | 32768 | History.PositionChangeLog_Insert for the open position modification (partial close only) |

When @PartsToDo=0, all steps execute (full retry).

---

## 2. Business Logic

### 2.1 XML Parameter Extraction

**What**: Extracts ~35 parameters from the @Params XML using XQuery value() method.

**Key Parameters**: PositionID, MirrorRealizedEquity, AccountRealizedEquity, SessionID, ClosedExitOrderID, IsMirrorActive, ClientRequestGuid, IsPartial, PartialClosePositionID, PartialClosedPositionAmount, OpenPositionAmount, ClientVersion, PositionStopLoss, PartialClosedEndOfWeekFee, OriginalEndOfWeekFee, PreviousAmountInUnits, AmountInUnits, UnitsBaseValueInCents, ClientViewRate/ID, ClientRateForCalc/ID, SkewValue, RedeemID, RedeemReasonID, RedeemStatus, AmountOnClose, ExecutedWithoutSettings

### 2.2 Bitmask Step Selection

**What**: Each step is guarded by @PartsToDo = 0 (run all) OR @PartsToDo & N = N (run specific step).

**Rules**:
- Each step is wrapped in BEGIN TRY/BEGIN CATCH
- On failure, @RetVal accumulates the step's bit value
- Steps are independent and do not depend on each other's success

### 2.3 Demo Refill (Bit 4)

**What**: If demo account with TotalCash <= 500, no open positions, and not partial close, triggers Billing.AmountAdd.

### 2.4 Redeem Status Update (Bit 8)

**What**: For real accounts with active RedeemStatus, calls Billing.RedeemStatusUpdate.

### 2.5 Position Change Log (Bit 8192)

**What**: Calls History.PositionChangeLog_Insert to record the close event with all rate/amount details.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | CODE-BACKED | XML payload containing all close-operation context (PositionID, equities, rates, etc.) |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bitmask of failed steps to retry. 0 = retry all steps. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | SELECT | TotalCash for demo refill check |
| @CID | Trade.Position | EXISTS check | Check for remaining open positions |
| @CID | Customer.Login | SELECT | ClientVersion and online status check |
| @PositionID | Billing.Redeem | SELECT | RedeemID lookup fallback |
| (calls) | Billing.AmountAdd | EXEC (print only) | Demo account refill |
| (calls) | Billing.RedeemStatusUpdate | EXEC (print only) | Redeem status update |
| (calls) | Customer.SendMessage | EXEC (print only) | Contract rollover notification |
| (calls) | History.PositionChangeLog_Insert | EXEC | Position change audit trail |
| (calls) | History.Mirror | INSERT (print only) | Detached mirror history |
| (references) | Maintenance.MessageTemplate | SELECT | Message template check for rollover |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Close position workflow | (async retry) | EXEC | Retries failed post-close steps |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChekAsyncFailedSteps (procedure)
+-- Customer.Customer (table)
+-- Trade.Position (table)
+-- Customer.Login (table)
+-- Billing.Redeem (table)
+-- Billing.AmountAdd (procedure)
+-- Billing.RedeemStatusUpdate (procedure)
+-- History.PositionChangeLog_Insert (procedure)
+-- Customer.SendMessage (procedure)
+-- Maintenance.MessageTemplate / MessageTemplateEn (tables)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Demo refill check |
| Trade.Position | Table | Open position check |
| Customer.Login | Table | Online status, ClientVersion |
| Billing.Redeem | Table | RedeemID fallback lookup |
| History.PositionChangeLog_Insert | Procedure | Audit trail |
| Maintenance.MessageTemplate | Table | Message template validation |
| Maintenance.MessageTemplateEn | Table | Message template validation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Async close retry engine | External | Failed step recovery |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Many PRINT statements | Code smell | Several steps are stubbed with PRINT instead of actual EXEC calls, suggesting this is a partially-deactivated or debug version |
| No explicit transaction | Atomicity | Each step is independent; partial success is expected |
| Bitmask accumulation | Error tracking | @RetVal accumulates failed step bits but is never returned or logged in this version |

---

## 8. Sample Queries

### 8.1 Retry all failed steps for a position

```sql
DECLARE @Params XML = '<Root>
  <PositionID Value="123456789" />
  <MirrorRealizedEquity Value="5000.00" />
  <AccountRealizedEquity Value="10000.00" />
  <SessionID Value="1" />
  <IsPartial Value="0" />
</Root>';
EXEC Trade.ChekAsyncFailedSteps @Params = @Params, @PartsToDo = 0;
```

### 8.2 Retry only position change log step

```sql
EXEC Trade.ChekAsyncFailedSteps @Params = @Params, @PartsToDo = 8192;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ChekAsyncFailedSteps | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ChekAsyncFailedSteps.sql*
