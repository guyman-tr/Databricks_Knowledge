# Trade.HedgeOpen

> Executes a hedge open: reads the RequestType=1 row from Trade.HedgeRequest, inserts it into Trade.Hedge (converting @NetProfit and @Commission from cents to dollars), then deletes the request. Logs to History.HedgeFail (FailTypeID=3, FailReasonID=17) if the open request is not found.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeID; INSERT: Trade.Hedge; DELETE: Trade.HedgeRequest (RequestType=1); Logs: History.HedgeFail (FailTypeID=3) on failure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeOpen is the **hedge execution procedure**: it transitions a hedge from "pending open request" to "live hedge position". When the hedge server confirms it has opened a hedge at the liquidity provider, it calls this procedure to:

1. Take the parameters confirmed by the provider (@Amount, @IsBuy, etc. may differ from what was requested)
2. Read the RequestType=1 row from Trade.HedgeRequest to get provider-side data (ProviderID, InstrumentID, CurrencyID, Leverage, OrderID, Occurred)
3. INSERT a new row in Trade.Hedge combining request data with execution data
4. DELETE the RequestType=1 row from Trade.HedgeRequest (request fulfilled)

The comment in the DDL explains: "PARAMETERS BELOW MAY BE CHANGED BY PROVIDER, SO THE SERVER PASS THEM AGAIN. THERE IS NO NECESSITY TO KEEP REQUESTED DATA, IT WILL BE USED IN CASE OF FAILURE ONLY." This means the provider may modify Amount/IsBuy/lots from the original request; the SP accepts the provider-confirmed values and the request row is only needed for static fields like ProviderID, InstrumentID, CurrencyID.

**Error 60004**: If the RequestType=1 row is not found (INSERT returns 0 rows), the SP logs a failure to History.HedgeFail (FailTypeID=3, FailReasonID=17, "Cannot find corresponding request") and raises RAISERROR 60004. This is the hedge-open-not-found failure code (vs 60005 for hedge-close failure in Trade.HedgeClose).

**cents-to-dollars conversion**: @NetProfit and @Commission are received in cents from the hedge server and stored as `/100` in Trade.Hedge (dollars).

**ParentTradeID handling**: If @ParentTradeID is provided (partial fill scenario), the procedure looks up `FirstParentOpenOccured` from Trade.Hedge first, then History.Hedge. This timestamp chains parent-child hedges for P&L attribution.

This is the counterpart to Trade.HedgeClose. Together they maintain the Trade.Hedge lifecycle.

---

## 2. Business Logic

### 2.1 Main Path - Read Request and Insert Hedge

**What**: Reads RequestType=1 from HedgeRequest, inserts into Trade.Hedge with provider-confirmed parameters.

**Columns/Parameters Involved**: `@HedgeID`, `@HedgeServerID`, `@NetProfit`, `@InitForexRate`, `@Amount`, `@IsBuy`, etc.

**Rules**:
- INSERT INTO Trade.Hedge SELECT from Trade.HedgeRequest WHERE HedgeID=@HedgeID AND RequestType=1
- Columns from HedgeRequest: ProviderID, InstrumentID, Leverage, OrderID, Occurred (->RequestOccurred), CurrencyID (unless @CurrencyID provided)
- Columns from parameters (provider-confirmed): @Amount, @AmountInUnitsDecimal, @LotCountDecimal, @IsBuy, @NetProfit/100, @InitForexRate, @InitDateTime, @LimitRate, @StopRate, @TradeID, @AccountID, @Premium, @OpenCharge, @Commission, @Fee, @NfaFee, @LiquidityAccountID
- HedgeServerID: `ISNULL(@HedgeServerID, 1)` - defaults to 1 if NULL (legacy safety)
- CurrencyID: `ISNULL(@CurrencyID, CurrencyID)` - use parameter if provided, else from HedgeRequest
- OrigAmountInUnits: set to @AmountInUnitsDecimal (snapshot of original amount before any adjustments)
- FirstParentOpenOccured: from parent hedge lookup (see 2.2) or GETUTCDATE() if none

### 2.2 Parent Hedge Chain Resolution

**What**: Resolves the FirstParentOpenOccured timestamp for partial-fill child hedges.

**Rules**:
- IF @ParentTradeID IS NOT NULL:
  - SELECT TOP 1 @FirstParentOpenOccured = FirstParentOpenOccured FROM Trade.Hedge WHERE TradeID = @ParentTradeID
  - IF not found (NULL): SELECT TOP 1 @FirstParentOpenOccured = FirstParentOpenOccured FROM History.Hedge WHERE TradeID = @ParentTradeID
- If neither found: ISNULL(@FirstParentOpenOccured, GETUTCDATE()) defaults to current time
- This preserves the original hedge open time through a chain of partial fills

### 2.3 Failure Path - Open Request Not Found

**What**: If INSERT returns 0 rows (RequestType=1 missing), log failure and raise error.

**Rules**:
- IF @@ROWCOUNT = 0 after INSERT:
  - INSERT History.HedgeFail (HedgeID, FailTypeID=3, HedgeServerID=@HedgeServerID, NetProfit=@NetProfit/100, LimitRate=@LimitRate, StopRate=@StopRate, TradeID=@TradeID, ParentTradeID=@ParentTradeID, AccountID=@AccountID, FailReason='Cannot find corresponding request', LiquidityAccountID=@LiquidityAccountID, FailReasonID=17)
  - COMMIT TRANSACTION (to ensure HedgeFail is persisted)
  - RAISERROR(60004, 16, 1) - caller gets error 60004

### 2.4 String Normalization

**What**: TradeID and AccountID are normalized before use.

**Rules**:
- `@TradeID = Internal.NormalizeString(@TradeID)` - removes leading/trailing whitespace, normalizes encoding
- `@AccountID = Internal.NormalizeString(@AccountID)` - same

**Diagram**:
```
Trade.HedgeOpen(@HedgeID, @HedgeServerID, @NetProfit, @InitForexRate, @Amount, @IsBuy, ...)
    |
    BEGIN TRY / BEGIN TRANSACTION
    |
    +-- IF @ParentTradeID IS NOT NULL:
    |       SELECT FirstParentOpenOccured FROM Trade.Hedge WHERE TradeID=@ParentTradeID
    |       ELSE SELECT from History.Hedge (fallback)
    |
    +-- @TradeID = Internal.NormalizeString(@TradeID)
    +-- @AccountID = Internal.NormalizeString(@AccountID)
    |
    +-- INSERT Trade.Hedge
    |       SELECT (provider-confirmed params + request fields)
    |       FROM Trade.HedgeRequest WHERE HedgeID=@HedgeID AND RequestType=1
    |
    +-- IF @@ROWCOUNT = 0:
    |       INSERT History.HedgeFail (FailTypeID=3, FailReasonID=17, 'Cannot find corresponding request')
    |       COMMIT; RAISERROR(60004)
    |
    +-- DELETE Trade.HedgeRequest WHERE HedgeID=@HedgeID AND RequestType=1
    +-- COMMIT TRANSACTION
    +-- RETURN 0
    |
    BEGIN CATCH:
    +-- ROLLBACK (if outermost tran) or COMMIT (nested)
    +-- RAISERROR(@LocalError) + RETURN @LocalError
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | CODE-BACKED | ID of the hedge being opened. Must match HedgeRequest.HedgeID WHERE RequestType=1. Allocated by Internal.GetHedgeID when the open request was created. |
| 2 | @HedgeServerID | INTEGER | NO | - | CODE-BACKED | Hedge server that executed the open. Stored in Trade.Hedge.HedgeServerID. ISNULL(@HedgeServerID,1) defaults to 1. |
| 3 | @NetProfit | MONEY | NO | - | CODE-BACKED | Net profit in CENTS (from broker). Stored as @NetProfit/100 in Trade.Hedge (dollars). Matches Trade.HedgeClose convention. |
| 4 | @InitForexRate | dtPrice | NO | - | CODE-BACKED | Actual execution rate at which the hedge was opened at the liquidity provider. dtPrice = user-defined decimal type. |
| 5 | @InitDateTime | DATETIME | NO | - | CODE-BACKED | When the hedge was opened at the liquidity provider. |
| 6 | @LimitRate | dtPrice | NO | - | CODE-BACKED | Take-profit rate for the hedge (can be updated later by HedgeEditTakeProfit). |
| 7 | @StopRate | dtPrice | NO | - | CODE-BACKED | Stop-loss rate for the hedge (can be updated later by HedgeEditStopLost). |
| 8 | @TradeID | VARCHAR(50) | NO | - | CODE-BACKED | Broker trade ID. Normalized via Internal.NormalizeString. Stored in Trade.Hedge.TradeID. |
| 9 | @AccountID | VARCHAR(50) | NO | - | CODE-BACKED | Broker account ID. Normalized via Internal.NormalizeString. Stored in Trade.Hedge.AccountID. |
| 10 | @Amount | MONEY | NO | - | CODE-BACKED | Provider-confirmed position size in currency. May differ from the originally requested amount. |
| 11 | @AmountInUnitsDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Provider-confirmed position size in instrument units. Also stored as OrigAmountInUnits for audit. |
| 12 | @LotCountDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Provider-confirmed lot count. May differ from requested. |
| 13 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction of the hedge (1=long/buy, 0=short/sell). Opposite of net customer position direction. |
| 14 | @ParentTradeID | VARCHAR(50) | YES | NULL | CODE-BACKED | Parent broker trade ID for partial fills / chained hedges. Used to look up FirstParentOpenOccured from Trade.Hedge or History.Hedge. |
| 15 | @Premium | MONEY | YES | NULL | CODE-BACKED | Premium paid/received. Stored in Trade.Hedge.Premium. |
| 16 | @OpenCharge | MONEY | YES | NULL | CODE-BACKED | Charge at open. Stored in Trade.Hedge.OpenCharge. |
| 17 | @Commission | MONEY | YES | NULL | CODE-BACKED | Commission in CENTS. Stored as @Commission (no /100 division in INSERT - note: no cents conversion here, unlike @NetProfit). |
| 18 | @Fee | MONEY | YES | NULL | CODE-BACKED | Additional fee. Stored in Trade.Hedge.Fee. |
| 19 | @NfaFee | MONEY | YES | NULL | CODE-BACKED | NFA (National Futures Association) fee for US-regulated trades. Stored in Trade.Hedge.NfaFee. |
| 20 | @LiquidityAccountID | INT | YES | NULL | CODE-BACKED | Liquidity account used for this hedge. Stored in Trade.Hedge.LiquidityAccountID. |
| 21 | @CurrencyID | INT | YES | NULL | CODE-BACKED | Currency override. If provided, overrides CurrencyID from HedgeRequest. ISNULL(@CurrencyID, HedgeRequest.CurrencyID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeID, RequestType=1 | Trade.HedgeRequest | SELECT (read request data) + DELETE (fulfill request) | Source of provider-side hedge request data |
| @ParentTradeID | Trade.Hedge | SELECT TOP 1 (FirstParentOpenOccured) | Parent hedge for chain resolution |
| @ParentTradeID | History.Hedge | SELECT TOP 1 (fallback FirstParentOpenOccured) | Fallback for already-closed parent hedges |
| @TradeID, @AccountID | Internal.NormalizeString | Scalar function call | String normalization |
| @HedgeID + all params | Trade.Hedge | INSERT | Creates the live hedge position |
| FailTypeID=3 | History.HedgeFail | INSERT (on failure path) | Logs failed open (request not found) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Hedge server calls this after confirming open at liquidity provider |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeOpen (procedure)
+-- Trade.HedgeRequest (table) [SELECT source data + DELETE on open]
+-- Trade.Hedge (table) [INSERT new live hedge]
+-- History.Hedge (table) [x-schema, SELECT fallback for FirstParentOpenOccured]
+-- History.HedgeFail (table) [x-schema, INSERT on failure]
+-- Internal.NormalizeString (function) [x-schema, string normalization]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeRequest | Table | SELECT request data + DELETE fulfilled request (RequestType=1) |
| Trade.Hedge | Table | INSERT new live hedge + SELECT parent chain |
| History.Hedge | Table | SELECT fallback for parent FirstParentOpenOccured |
| History.HedgeFail | Table | INSERT failure log (FailTypeID=3, FailReasonID=17) |
| Internal.NormalizeString | Function | Normalize @TradeID and @AccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | Calls to confirm hedge execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

TRY/CATCH with nested transaction handling (ROLLBACK if @@TRANCOUNT=1, COMMIT if nested). @LocalError initialized to 60000 (generic hedge error); overrides to 60004 if request not found. Note: @Commission is stored without /100 division in the INSERT (unlike @NetProfit which is /100) - check whether @Commission is already in dollars or needs the same cents conversion.

---

## 8. Sample Queries

### 8.1 Execute a hedge open (called by hedge server)

```sql
EXEC Trade.HedgeOpen
    @HedgeID = 12345,
    @HedgeServerID = 24,
    @NetProfit = 0,         -- cents
    @InitForexRate = 1.08520,
    @InitDateTime = '2026-03-17 10:00:00',
    @LimitRate = 1.09500,
    @StopRate = 1.07500,
    @TradeID = 'BROKER-TRADE-001',
    @AccountID = 'BROKER-ACCOUNT-001',
    @Amount = 10000,
    @AmountInUnitsDecimal = 100000.000000,
    @LotCountDecimal = 1.000000,
    @IsBuy = 1;
```

### 8.2 Verify the new hedge was inserted

```sql
SELECT HedgeID, InstrumentID, HedgeServerID, InitForexRate, Amount, LotCountDecimal,
       IsBuy, TradeID, AccountID, Occurred, RequestOccurred
FROM Trade.Hedge WITH (NOLOCK)
WHERE HedgeID = 12345;
```

### 8.3 Check HedgeRequest was cleaned up

```sql
SELECT * FROM Trade.HedgeRequest WITH (NOLOCK)
WHERE HedgeID = 12345;
-- Should return no rows after HedgeOpen succeeds
```

### 8.4 Check HedgeFail log if open failed

```sql
SELECT HedgeID, FailTypeID, FailReasonID, FailReason, HedgeServerID
FROM History.HedgeFail WITH (NOLOCK)
WHERE HedgeID = 12345 AND FailTypeID = 3;
-- FailTypeID=3 = hedge open failure; FailReasonID=17 = request not found
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeOpen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeOpen.sql*
