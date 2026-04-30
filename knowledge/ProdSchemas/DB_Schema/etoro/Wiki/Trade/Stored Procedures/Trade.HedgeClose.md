# Trade.HedgeClose

> Archives a live hedge to History.Hedge, reassigns open positions to a replacement hedge, and removes the closed hedge from Trade.Hedge - the final step in the hedge close lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeID (hedge being closed); Modifies: Trade.Hedge, Trade.HedgeRequest, Trade.Position; Writes: History.Hedge or History.HedgeFail |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeClose is the **hedge close executor** stored procedure. It is called by the hedge server when a liquidity provider confirms that a hedge position has been closed. The procedure archives the hedge data to History.Hedge, updates all open customer positions that referenced this hedge to point to the replacement hedge (@ReplaceHedgeID), removes the hedge from the live Trade.Hedge table, and cleans up the associated close request from Trade.HedgeRequest.

This procedure exists because hedge positions represent eToro's broker-side risk management: when customer CFD positions are closed (or aggregate exposure is reduced), the corresponding hedge must be unwound at the liquidity provider. The SP implements the atomic commit of that unwind - it must not partially complete, which is why it runs inside an explicit transaction with full TRY/CATCH error handling.

Data flows: the hedge server confirms the close by calling this SP with the filled execution details (end rate, datetime, P&L, commission). The SP first verifies the hedge exists in Trade.Hedge; if not found (error code 60004), it logs the failure to History.HedgeFail and aborts. On success, it moves the hedge record to History.Hedge, redirects position hedge linkages, and deletes the live hedge and pending close request.

@NetProfit and @Commission are passed in **cents** (comment "-- cents") and stored in History.Hedge divided by 100 (converted to dollars). @ReplaceHedgeID supports partial-fill scenarios: when a hedge is only partially closed, the remaining exposure continues under a new HedgeID; this parameter updates Trade.Position rows to reference the new hedge.

---

## 2. Business Logic

### 2.1 Hedge Close Lifecycle

**What**: The complete transactional sequence for closing a hedge position at the liquidity provider.

**Columns/Parameters Involved**: `@HedgeID`, `@ReplaceHedgeID`, `Trade.Hedge`, `Trade.HedgeRequest (RequestType=2)`, `History.Hedge`, `Trade.Position.HedgeID`

**Rules**:
- All operations run within an explicit BEGIN TRANSACTION / COMMIT TRANSACTION (or ROLLBACK in CATCH)
- Step 1: INSERT INTO History.Hedge, SELECTing from Trade.Hedge LEFT JOIN Trade.HedgeRequest (RequestType=2) WHERE HedgeID=@HedgeID
- Step 2: If 0 rows inserted (hedge not found): log to History.HedgeFail (FailTypeID=2, FailReasonID=17), COMMIT, RAISERROR(60004), RETURN
- Step 3: UPDATE Trade.Position SET HedgeID=@ReplaceHedgeID WHERE HedgeID=@HedgeID
- Step 4: DELETE FROM Trade.Hedge WHERE HedgeID=@HedgeID
- Step 5: DELETE FROM Trade.HedgeRequest WHERE HedgeID=@HedgeID AND RequestType=2

**Diagram**:
```
HedgeServer confirms close fill
        |
        v
Trade.HedgeClose(@HedgeID, @ReplaceHedgeID, @NetProfit, ...)
        |
        +-- (1) INSERT History.Hedge
        |         <- Trade.Hedge (all fields)
        |         <- Trade.HedgeRequest RequestType=2 (RequestedEndForexRate, Occurred)
        |         <- @NetProfit/100, @Commission/100 (cents -> dollars)
        |         <- @EndForexRate, @EndDateTime, @ActionType, @CloseCharge
        |
        +-- (2) IF 0 rows: -> History.HedgeFail (FailTypeID=2, FailReasonID=17, error 60004)
        |                  -> COMMIT, RETURN
        |
        +-- (3) UPDATE Trade.Position SET HedgeID=@ReplaceHedgeID WHERE HedgeID=@HedgeID
        |         (positions re-pointed to new/replacement hedge)
        |
        +-- (4) DELETE Trade.Hedge WHERE HedgeID=@HedgeID
        +-- (5) DELETE Trade.HedgeRequest WHERE HedgeID=@HedgeID AND RequestType=2
        +-- (6) COMMIT TRANSACTION
```

### 2.2 Cents-to-Dollars Unit Conversion

**What**: @NetProfit and @Commission are sent in cents by the hedge server; stored in History.Hedge in dollars.

**Columns/Parameters Involved**: `@NetProfit`, `@Commission`, `History.Hedge.NetProfit`, `History.Hedge.Commission`

**Rules**:
- Hedge server sends monetary values in cents (scale: × 100)
- History.Hedge stores these in dollars: `@NetProfit / 100`, `@Commission / 100`
- This conversion is documented inline: `@NetProfit MONEY, -- cents` and `@Commission MONEY, -- cents`

### 2.3 Failure Logging (Error 60004)

**What**: When the hedge is not found in Trade.Hedge, the failure is logged and the operation aborts.

**Columns/Parameters Involved**: `History.HedgeFail.FailTypeID`, `History.HedgeFail.FailReasonID`, `History.HedgeFail.FailReason`

**Rules**:
- FailTypeID = 2 (request to close)
- FailReasonID = 17 (derived from code)
- FailReason = 'Cannot find corresponding request or data itself'
- Error code 60004 is raised: hedge not found
- The FULL OUTER JOIN pattern in the failure INSERT ensures all available data is captured even when Hedge/HedgeRequest is partially missing

### 2.4 Nested Transaction Handling

**What**: Supports being called from within an outer transaction.

**Columns/Parameters Involved**: `@TranLevel`

**Rules**:
- @TranLevel = @@TRANCOUNT at procedure start
- If CATCH fires AND @TranLevel = @@TranCount AND @@trancount = 1: ROLLBACK (this is the outermost transaction)
- If CATCH fires AND @@trancount > 1: COMMIT (savepoint behavior - let outer transaction handle rollback)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | CODE-BACKED | ID of the hedge position being closed. Must exist in Trade.Hedge; if not found, error 60004 is raised and the close is logged to History.HedgeFail. |
| 2 | @ReplaceHedgeID | INTEGER | NO | - | CODE-BACKED | The replacement HedgeID to assign to positions that referenced @HedgeID. For a full close, this is typically a null/zero replacement. For partial fills, this is the ID of the new hedge covering residual exposure. All Trade.Position rows with HedgeID=@HedgeID are updated to HedgeID=@ReplaceHedgeID. |
| 3 | @NetProfit | MONEY | NO | - | CODE-BACKED | Net P&L of the hedge at close, expressed in CENTS. Stored in History.Hedge as @NetProfit/100 (dollars). Passed by the hedge server from the liquidity provider confirmation. |
| 4 | @Commission | MONEY | NO | - | CODE-BACKED | Broker commission charged on the hedge close, in CENTS. Stored in History.Hedge as @Commission/100 (dollars). |
| 5 | @EndForexRate | dtPrice | NO | - | CODE-BACKED | Closing price of the hedge at the liquidity provider. Stored as History.Hedge.EndForexRate. dtPrice is a user-defined decimal type for price values. |
| 6 | @EndDateTime | DATETIME | NO | - | CODE-BACKED | Timestamp when the hedge was closed at the liquidity provider. Stored as History.Hedge.EndDateTime. |
| 7 | @ActionType | INTEGER | NO | 0 | CODE-BACKED | Reason for close. Default 0 = REGULAR CLOSE BY HEDGE SERVER (inline comment). Stored as History.Hedge.ActionType. Non-zero values represent other close reasons (stop-loss, take-profit, etc.). |
| 8 | @Amount | money | YES | NULL | CODE-BACKED | Override for the hedge amount at close. If NULL, uses Trade.Hedge.Amount. Supports partial close scenarios. |
| 9 | @AmountInUnitsDecimal | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Override for units at close. If NULL, uses Trade.Hedge.AmountInUnitsDecimal. Supports partial close scenarios. |
| 10 | @LotCountDecimal | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Override for lot count at close. If NULL, uses Trade.Hedge.LotCountDecimal. Supports partial close scenarios. |
| 11 | @CloseCharge | MONEY | YES | NULL | CODE-BACKED | Additional charge levied on close. Stored directly as History.Hedge.CloseCharge. NULL if no close charge applies. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeID | Trade.Hedge | SELECT / DELETE | Reads hedge data for archiving, then deletes the live row |
| @HedgeID | Trade.HedgeRequest (RequestType=2) | SELECT / DELETE | Reads close request for RequestedEndForexRate; deletes after processing |
| @HedgeID | History.Hedge | INSERT | Archives the closed hedge record |
| @HedgeID | History.HedgeFail | INSERT (on failure) | Logs failed close attempt with FailTypeID=2, FailReasonID=17 |
| @HedgeID | Trade.Position | UPDATE | Reassigns HedgeID to @ReplaceHedgeID for all positions referencing this hedge |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | The hedge server calls this SP when a liquidity provider confirms a hedge close execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeClose (procedure)
+-- Trade.Hedge (table) [leaf - source for archive INSERT + DELETE]
+-- Trade.HedgeRequest (table) [leaf - source for RequestedEndForexRate + DELETE]
+-- History.Hedge (table) [x-schema, leaf - archive target INSERT]
+-- History.HedgeFail (table) [x-schema, leaf - failure log INSERT]
+-- Trade.Position (view) [leaf for UPDATE - HedgeID reassignment]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | SELECT (for archive data) + DELETE (removes closed hedge) |
| Trade.HedgeRequest | Table | LEFT JOIN (for RequestedEndForexRate, Occurred) + DELETE (RequestType=2 cleanup) |
| History.Hedge | Table | INSERT (archives the closed hedge record) |
| History.HedgeFail | Table | INSERT (logs failed close attempts) |
| Trade.Position | View | UPDATE (HedgeID reassignment to @ReplaceHedgeID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external system) | External caller | Calls HedgeClose when liquidity provider confirms close execution |
| Trade.Hedge.md | Documentation | References this SP as the DELETER in the hedge lifecycle |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None declared. Business constraint: @HedgeID must exist in Trade.Hedge; violation triggers 60004 error and HedgeFail log.

---

## 8. Sample Queries

### 8.1 Check what would be archived (preview History.Hedge INSERT)

```sql
SELECT
    h.HedgeID, h.CurrencyID, h.ProviderID, h.InstrumentID, h.HedgeServerID,
    h.Amount, h.InitForexRate, h.IsBuy,
    hr.RequestedEndForexRate,
    hr.Occurred AS RequestCloseOccurred
FROM Trade.Hedge h WITH (NOLOCK)
LEFT OUTER JOIN Trade.HedgeRequest hr WITH (NOLOCK)
    ON h.HedgeID = hr.HedgeID AND hr.RequestType = 2
WHERE h.HedgeID = 12345;
```

### 8.2 Check positions that will be reassigned

```sql
SELECT PositionID, HedgeID, CID, InstrumentID
FROM Trade.Position WITH (NOLOCK)
WHERE HedgeID = 12345;  -- positions that will be updated to @ReplaceHedgeID
```

### 8.3 Review hedge close history

```sql
SELECT TOP 10
    hh.HedgeID, hh.InstrumentID, hh.IsBuy, hh.Amount,
    hh.InitForexRate, hh.EndForexRate,
    hh.NetProfit, hh.Commission,
    hh.EndDateTime, hh.ActionType
FROM History.Hedge hh WITH (NOLOCK)
WHERE hh.HedgeID = 12345
ORDER BY hh.EndDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Close Position Flow](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13789659145) | Confluence | General context for position/hedge close flows in the trading system; HedgeClose is part of the hedge server integration in the post-execution phase |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.Hedge, Trade.HedgeRequest dependency docs) | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeClose | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeClose.sql*
