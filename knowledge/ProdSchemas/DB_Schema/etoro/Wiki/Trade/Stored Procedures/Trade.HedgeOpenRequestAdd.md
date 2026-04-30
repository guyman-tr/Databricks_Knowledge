# Trade.HedgeOpenRequestAdd

> Queues a hedge open request: allocates a new HedgeID via Internal.GetHedgeID, then inserts a RequestType=1 row into Trade.HedgeRequest for the hedge server to pick up and execute.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Output: @HedgeID (allocated); Writes: Trade.HedgeRequest (RequestType=1); Calls: Internal.GetHedgeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeOpenRequestAdd is the **first step in the hedge open lifecycle**: it allocates a unique HedgeID and queues an open request in Trade.HedgeRequest (RequestType=1). The hedge server polls this table and calls Trade.HedgeOpen when it executes the open at the liquidity provider.

This procedure is the counterpart of Trade.HedgeCloseRequestAdd (which queues RequestType=2). Together they feed the HedgeRequest queue that the hedge server processes asynchronously.

The @HedgeID OUTPUT parameter returns the allocated ID to the caller, which can then track the hedge through the system. The ID is allocated by Internal.GetHedgeID (a centralized ID allocator for hedge IDs).

Unlike Trade.HedgeCloseRequestAdd, there is no displacement logic here: if an open request already exists for a given InstrumentID/HedgeServerID, the new request is simply added alongside it. The uniqueness constraint is at the HedgeID level, not the instrument level.

---

## 2. Business Logic

### 2.1 HedgeID Allocation

**What**: Gets a new unique HedgeID for the open request.

**Rules**:
- `EXECUTE Internal.GetHedgeID @HedgeID OUTPUT` - allocates from the centralized hedge ID sequence.
- @HedgeID is an OUTPUT parameter; the caller receives the allocated ID.

### 2.2 Open Request Insertion

**What**: Inserts a RequestType=1 row into Trade.HedgeRequest.

**Rules**:
- INSERT Trade.HedgeRequest (HedgeID, RequestType=1, CurrencyID, ProviderID, InstrumentID, HedgeServerID, Leverage, Amount, AmountInUnitsDecimal, LotCountDecimal, IsBuy)
- Occurred column gets GETUTCDATE() default from the table.
- @HedgeServerID is optional (NULL allowed); if NULL, the hedge request is unassigned to a specific server until the hedge server picks it up.
- No SL/TP rates (LimitRate/StopRate) are set in the open request - these may be set later via HedgeEditStopLost/HedgeEditTakeProfit.
- RETURN @@ERROR (legacy pattern: 0 on success, error number on failure).

**Diagram**:
```
HedgeOpenRequestAdd(@HedgeID OUT, @CurrencyID, @ProviderID, @InstrumentID, ...)
    |
    +-- EXEC Internal.GetHedgeID @HedgeID OUTPUT
    |       (allocates unique HedgeID from sequence)
    |
    +-- INSERT Trade.HedgeRequest
    |       (HedgeID=@HedgeID, RequestType=1, ...)
    |
    +-- RETURN @@ERROR
    |       (0 = success; non-zero = SQL error)
    |
    -> Caller receives @HedgeID (OUTPUT)
    -> Hedge server picks up RequestType=1 row -> calls Trade.HedgeOpen
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | OUTPUT | CODE-BACKED | OUTPUT parameter. Returns the newly allocated HedgeID. Allocated by Internal.GetHedgeID. The caller uses this to track the hedge through HedgeOpen -> Trade.Hedge. |
| 2 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Denomination currency of the hedge. FK to Dictionary.Currency. Stored in HedgeRequest and later in Trade.Hedge. |
| 3 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Liquidity provider for this hedge. Part of the ProviderToInstrument tuple. Determines execution venue. |
| 4 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Financial instrument to hedge (e.g., 1=EUR/USD). Stored in HedgeRequest.InstrumentID. |
| 5 | @Leverage | INTEGER | NO | - | CODE-BACKED | Leverage multiple (e.g., 400). Stored in HedgeRequest.Leverage and later Trade.Hedge.Leverage. |
| 6 | @Amount | MONEY | NO | - | CODE-BACKED | Position size in currency. Provider may adjust this during execution; Trade.HedgeOpen accepts provider-confirmed value. |
| 7 | @AmountInUnitsDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in instrument units. |
| 8 | @LotCountDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Lot count for execution. |
| 9 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=long/buy, 0=short/sell. Opposite of the net customer position being hedged. |
| 10 | @HedgeServerID | INTEGER | YES | NULL | CODE-BACKED | Target hedge server. Optional: if NULL, the request is unassigned until a hedge server claims it. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeID | Internal.GetHedgeID | EXEC (OUTPUT parameter) | Allocates unique HedgeID from centralized sequence |
| @HedgeID, RequestType=1 | Trade.HedgeRequest | INSERT | Creates hedge open request for hedge server to pick up |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server / Trading API (external) | - | Called by external system | Trading system calls this to initiate a hedge open with the hedge server |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeOpenRequestAdd (procedure)
+-- Internal.GetHedgeID (procedure) [x-schema, HedgeID allocation]
+-- Trade.HedgeRequest (table) [INSERT RequestType=1]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetHedgeID | Procedure | Allocates unique HedgeID (OUTPUT) |
| Trade.HedgeRequest | Table | INSERT open request (RequestType=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeOpen | Procedure | Reads and processes the RequestType=1 row created by this SP |
| Trading API (external) | External caller | Calls this to initiate hedge open flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No duplicate-request displacement (unlike HedgeCloseRequestAdd). Multiple open requests can exist for the same instrument. No TRY/CATCH; uses legacy RETURN @@ERROR pattern. No transaction wrapper.

---

## 8. Sample Queries

### 8.1 Queue a hedge open request

```sql
DECLARE @NewHedgeID INT;
EXEC Trade.HedgeOpenRequestAdd
    @HedgeID = @NewHedgeID OUTPUT,
    @CurrencyID = 1,         -- USD
    @ProviderID = 5,
    @InstrumentID = 1,       -- EUR/USD
    @Leverage = 400,
    @Amount = 10000,
    @AmountInUnitsDecimal = 100000.000000,
    @LotCountDecimal = 1.000000,
    @IsBuy = 1,
    @HedgeServerID = 24;
SELECT @NewHedgeID AS AllocatedHedgeID;
```

### 8.2 Verify open request was created

```sql
SELECT HedgeID, RequestType, InstrumentID, HedgeServerID, Amount, IsBuy, Occurred
FROM Trade.HedgeRequest WITH (NOLOCK)
WHERE HedgeID = @NewHedgeID AND RequestType = 1;
```

### 8.3 Track the hedge through its lifecycle

```sql
-- After HedgeOpen executes:
SELECT HedgeID, InstrumentID, InitForexRate, Amount, IsBuy, Occurred
FROM Trade.Hedge WITH (NOLOCK)
WHERE HedgeID = @NewHedgeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeOpenRequestAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeOpenRequestAdd.sql*
