# Trade.ManualModifySLForCriptoPositions

> Manual-use utility procedure that modifies the stop-loss rate for crypto (and other) positions where the user is adding capital to tighten their SL - intended to be run ad-hoc by operations staff, not called by the application.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @tbl (TVP of PositionIDs + new SL rates) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure enables operations staff to manually reset the stop-loss (SL) rate on one or more crypto (or any) positions where the position owner wants to invest additional capital in exchange for a tighter SL. Normally the application handles SL edits, but this procedure was created for bulk correction scenarios where the standard application flow is not suitable.

The core business need it serves is allowing a user to "put more money in" to protect a position with a tighter stop-loss - the user pays a credit delta (the extra capital at risk under the new SL rate) in exchange for the SL moving closer to the current market price. Without this procedure, such corrections would require manual SQL edits or a custom admin tool.

Data flow: The caller prepares a TVP (`Trade.PositionsAndNewSL`) listing the target positions and their desired new SL rates. The procedure iterates via cursor, validates each position, computes the credit delta, converts to cents, delegates to `Trade.PositionEditStopLoss` for the actual update, fires a Service Broker notification for downstream consumers, and logs the change to `History.LogTreesManualModifications`. Errors per position are collected and returned at the end.

---

## 2. Business Logic

### 2.1 Capital-at-Risk Delta Calculation

**What**: Determines how much additional capital the user must commit to support the new (tighter) SL rate.

**Columns/Parameters Involved**: `@Rate` (new SL), `@InitForexRate` (original open rate), `@Amount` (current invested amount), `@AmountInUnitsDecimal` (position size in units), `@IsBuy` (direction), `@ConversionRate` (instrument-to-USD conversion)

**Rules**:
- Formula: `@CreditChangeInDollars = @Amount + ((@Rate - @InitForexRate) * IIF(@IsBuy=1,1,-1) * @AmountInUnitsDecimal * @ConversionRate)`
- If result >= 0: the new SL rate does NOT require more capital (SL is looser, not tighter) - procedure raises an error and skips this position
- If result < 0: the absolute value represents additional capital needed in USD
- Converted to cents for `Trade.PositionEditStopLoss`: `@CreditChangeInCents = @CreditChangeInDollars * (-100)` (negated and scaled by 100)

**Diagram**:
```
New SL tighter than open rate -> capital at risk increases -> CreditChangeDollars < 0
  -> CreditChangeCents = abs(CreditChangeDollars) * 100 -> passed to PositionEditStopLoss

New SL looser than open rate -> capital at risk decreases -> CreditChangeDollars >= 0
  -> RAISERROR: "The new SL rate does not require investing more money in the position"
```

### 2.2 Conversion Rate Resolution

**What**: Resolves the USD conversion rate for the instrument's sell currency to normalize PnL into USD cents.

**Columns/Parameters Involved**: `Trade.Instrument.SellCurrencyID`, `Trade.GetCurrencyConversionsView.IsReciprocal`, `Trade.CurrencyPrice.Bid`

**Rules**:
- If `SellCurrencyID = 1` (USD): ConversionRate = 1 (no conversion needed)
- If `IsReciprocal = 1`: ConversionRate = 1 / Bid (reciprocal rate)
- Otherwise: ConversionRate = Bid (direct rate)
- Only queries open positions (`StatusID = 1`)

**Diagram**:
```
SellCurrencyID = 1 (USD)  -> ConversionRate = 1
IsReciprocal = 1          -> ConversionRate = 1 / CurrencyPrice.Bid
Otherwise                 -> ConversionRate = CurrencyPrice.Bid
```

### 2.3 Mirror Position Guard

**What**: Prevents modifying SL on copied/mirror positions - only manual (non-copied) positions may be modified.

**Columns/Parameters Involved**: `Trade.Position.MirrorID`

**Rules**:
- If `MirrorID > 0`: position is a CopyTrader mirror - raise error and skip
- Only positions with `MirrorID = 0` or `MirrorID IS NULL` may be processed
- Note: The `WHERE MirrorID = 0` filter in the cursor definition is commented out - the guard is enforced inside the cursor loop via RAISERROR

**Diagram**:
```
MirrorID > 0  -> RAISERROR: "You can edit only manual positions. This is a copied position"
MirrorID = 0  -> Allowed to proceed
```

### 2.4 Error Accumulation and Reporting

**What**: Collects per-position errors without aborting the batch - allows partial success.

**Columns/Parameters Involved**: `#Errors (PositionID, FailReason)`

**Rules**:
- Each position is wrapped in its own TRY/CATCH
- On any failure (validation RAISERROR or execution error): INSERT into `#Errors`
- After all positions processed: if `#Errors` is non-empty, SELECT and return the error rows
- Caller should inspect the returned result set for failed positions

**Diagram**:
```
Per position:
  TRY
    Validate (MirrorID, CreditChangeDollars)
    Execute PositionEditStopLoss
    Send Service Broker notification
    Log to History.LogTreesManualModifications
  CATCH
    INSERT #Errors (PositionID, ERROR_MESSAGE())

End: SELECT failed positions if any
```

### 2.5 Service Broker Notification

**What**: Sends an XML notification to the downstream position notification consumer after each successful SL edit.

**Columns/Parameters Involved**: `@XMLResult`, `@Handle`, Service Broker `svcInitiator` -> `svcPosition`

**Rules**:
- OperationTypeId = 3 (EditStopLoss)
- Payload includes: PositionID, InstrumentID, TreeID, CID, new StopLoss rate, @CreditChangeInCents as PositionSLAmountDelta, SLManualVer, StopLossVersionTimestamp
- Contract: `ctrAnyXMLData`, message type: `mtAnyXMLData`
- Only sent on successful SL edit (inside TRY, after PositionEditStopLoss call)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @tbl | Trade.PositionsAndNewSL READONLY | NO | - | CODE-BACKED | Table-valued input parameter containing the batch of positions to process. Each row provides a PositionID and the target new SL rate (@Rate). Defined as Trade.PositionsAndNewSL UDT. |

**Temp Table: #Errors**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | YES | - | CODE-BACKED | The ID of the position that failed to process. |
| 2 | FailReason | VARCHAR(1000) | YES | - | CODE-BACKED | The SQL error message or business validation error explaining why this position was not updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @tbl | Trade.PositionsAndNewSL | UDT (TVP) | Input table-valued parameter type defining the PositionID + Rate rows to process |
| Internal | Trade.Position | JOIN (READ) | View joined to get position details: AmountInUnitsDecimal, Amount, InstrumentID, InitForexRate, IsBuy, CID, StopRate, Leverage, MirrorID |
| Internal | Trade.PositionTbl | JOIN (READ) | Direct join for ConversionRate calculation, filtered to StatusID = 1 (open positions only) |
| Internal | Trade.Instrument | JOIN (READ) | Gets SellCurrencyID and BuyCurrencyID for conversion rate logic |
| Internal | Trade.GetCurrencyConversionsView | JOIN (READ) | Gets IsReciprocal flag for currency conversion direction |
| Internal | Trade.CurrencyPrice | JOIN (READ) | Gets current Bid price for conversion rate |
| Internal | Trade.PositionEditStopLoss | EXEC (CALL) | Delegate for the actual SL update - handles versioning and all position field changes |
| Internal | History.LogTreesManualModifications | INSERT (WRITE) | Audit trail: logs TreeID, CID, InstrumentID, original SL, and new SL for each processed position |
| Internal | svcPosition (Service Broker) | SEND | Downstream notification with OperationTypeId=3 (EditStopLoss) for async consumers |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository - this procedure is invoked manually (ad-hoc DBA/ops execution), not called from application code or other procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ManualModifySLForCriptoPositions (procedure)
+-- Trade.Position (view) [READ - position data]
+-- Trade.PositionTbl (table) [READ - conversion rate query]
+-- Trade.Instrument (table) [READ - currency pair metadata]
+-- Trade.GetCurrencyConversionsView (view) [READ - IsReciprocal flag]
+-- Trade.CurrencyPrice (table) [READ - current Bid price]
+-- Trade.PositionEditStopLoss (procedure) [EXEC - actual SL update]
+-- History.LogTreesManualModifications (table) [WRITE - audit log]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsAndNewSL | User Defined Type | TVP parameter type - defines the input schema (PositionID, Rate columns) |
| Trade.Position | View | Cursor SELECT - reads position details (Amount, InstrumentID, InitForexRate, IsBuy, CID, StopRate, Leverage, MirrorID, AmountInUnitsDecimal) |
| Trade.PositionTbl | Table | Subquery for ConversionRate - reads open positions (StatusID=1) joined to Instrument and CurrencyPrice |
| Trade.Instrument | Table | Joined for SellCurrencyID (conversion direction) and BuyCurrencyID |
| Trade.GetCurrencyConversionsView | View | Joined for IsReciprocal flag on the instrument's sell currency |
| Trade.CurrencyPrice | Table | Joined for current Bid price used in conversion rate calculation |
| Trade.PositionEditStopLoss | Stored Procedure | Called per position to apply the new SL rate, updating versioning fields and position state |
| History.LogTreesManualModifications | Table | Written to log the manual SL modification audit record |

### 6.2 Objects That Depend On This

No dependents found - this is a standalone manual utility procedure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MirrorID > 0 guard | Business validation | Copied (mirror) positions are blocked from manual SL edits |
| CreditChangeInDollars >= 0 guard | Business validation | New SL must be tighter (require more capital) - looser SLs are rejected |
| StatusID = 1 filter | Query filter | Conversion rate is only queried for open positions; prevents stale rate from closed positions |

---

## 8. Sample Queries

### 8.1 Execute for a single position (test with one position)
```sql
-- Declare the TVP and populate with one position
DECLARE @tbl Trade.PositionsAndNewSL;
INSERT INTO @tbl (PositionID, Rate)
VALUES (123456789, 45000.0); -- new SL rate for crypto position

EXEC Trade.ManualModifySLForCriptoPositions @tbl = @tbl;
```

### 8.2 Check the audit log for recent manual SL modifications
```sql
SELECT TOP 20
    TreeID,
    CID,
    InstrumentID,
    OrigStopLoss,
    NewStopLoss,
    -- ModifiedDate if available
    *
FROM History.LogTreesManualModifications WITH (NOLOCK)
ORDER BY 1 DESC;
```

### 8.3 Verify positions eligible for manual SL modification (open, non-mirrored)
```sql
SELECT
    p.PositionID,
    p.InstrumentID,
    i.InstrumentDisplayName,
    p.StopRate AS CurrentSL,
    p.Amount,
    p.MirrorID,
    p.StatusID
FROM Trade.PositionTbl p WITH (NOLOCK)
INNER JOIN Trade.Instrument i WITH (NOLOCK) ON p.InstrumentID = i.InstrumentID
WHERE p.StatusID = 1       -- open positions only
  AND p.MirrorID = 0       -- non-mirrored (manual) positions only
  AND i.InstrumentTypeID = 5  -- crypto instruments (example filter)
ORDER BY p.PositionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (PositionEditStopLoss) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ManualModifySLForCriptoPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ManualModifySLForCriptoPositions.sql*
