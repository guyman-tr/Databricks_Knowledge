# History.PostPositionFail

> Async post-action step (StepID=5) for position failure events - parses the XML payload enqueued by History.PositionFailInfo and inserts a single position failure record into History.PositionFailWrite (-> History.PositionFailLocal staging table). Part of the three-tier position fail persistence pipeline: PositionFailInfo enqueues -> PostPositionFail writes local -> InsertFailPositionToAzure syncs to Azure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params (XML) - single Root element containing all 57 position failure fields |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PostPositionFail` is the async consumer half of the position failure recording pipeline. It is registered as **StepID=5** in `Dictionary.Steps` ("After position failure"), called by `Internal.AsyncExecuter{N}` to process each failure record enqueued via `Trade.InsertAsyncRecord` (ActionID=5) by `History.PositionFailInfo`.

**Pipeline architecture**:
```
Trading engine
    |
    EXEC History.PositionFailInfo (at point of failure)
         |
         EXEC Trade.InsertAsyncRecord @CID, 5, @XML
              |
              Internal.AsyncExecuter{N} dequeues ActionID=5
                   |
                   EXEC History.PostPositionFail @XML, @PartsToDo, @ID
                        |
                        INSERT INTO History.PositionFailWrite
                             |
                             History.PositionFailLocal (local staging)
                                  |
                             History.InsertFailPositionToAzure
                                  |
                             History.PositionFailInsert -> Azure PositionFailReal primary
                                  |
                             History.PositionFail <- Azure PositionFailReal secondary (READ)
```

The procedure reads every field individually from the XML using scalar `.value()` calls (not a batch XQuery), then performs a single INSERT into `History.PositionFailWrite`. If the INSERT fails, `THROW` re-raises the error to the async framework (unlike other post-action steps that absorb errors and return an error code).

**ClientVersion notable omission**: The ClientVersion field is parsed from XML (`SELECT @ClientVersion = @Params.value(...)`) but is commented out of both the INSERT column list (`------ ClientVersion,`) and VALUES (`--- @ClientVersion,`). ClientVersion is not stored in PositionFailLocal.

History note: Created FB:16683 (2013-06-06); SessionID added 2014-10-29; FaileOccurred added FB:50211 (2018-01-17); ClientRequestGuid FB:51172 (2018-05-01); ClientViewRate params FB:53286 (2018-12-18); HedgeServerID/ExecutionID added 2019-10-22; PositionID to BIGINT 2021-11-24.

---

## 2. Business Logic

### 2.1 XML Parsing Pattern

**What**: All 57 fields are extracted from the XML using individual scalar `.value()` calls.

**Columns/Parameters Involved**: `@Params` (XML), all local variables

**Rules**:
- XML structure: `<Root><FieldName Value="..."/><FieldName Value="..."/>...</Root>` (single-position, attribute-style values)
- @CID is parsed first (before the @PartsToDo check) for logging/routing purposes
- All other fields parsed inside the TRY block after the @PartsToDo gate check
- FaileOccurred typo: the XML element is `FaileOccurred` (not `FailedOccurred` or `FailOccurred`) - matches the typo in History.PositionFailInfo which builds this XML
- AdditionalParam defaults: `ISNULL(@AdditionalParam, 'DB_Direct')` - if AdditionalParam is NULL, stored as 'DB_Direct' to indicate direct database path

### 2.2 @PartsToDo Gate and Error Handling

**What**: Standard async framework bitflag controls execution. THROW on failure re-raises to caller.

**Columns/Parameters Involved**: `@PartsToDo`, `@RetVal`

**Rules**:
- Gate: `IF @RetVal = 0 OR @RetVal & 1 = 1` (0=run all; bit 0 set=run insert)
- On success: returns @PartsToDo
- On failure: `THROW` re-raises the error (does NOT absorb and return error code like PostDetachMirrorPosition)
- @@ERROR check after INSERT: `IF @@ERROR <> 0 RAISERROR(...)` is a legacy pattern; unreachable if THROW is in CATCH and there's no error, but present as a defensive artifact
- SET @RetVal = @RetVal & 1 in CATCH is also unreachable after THROW - dead code

### 2.3 ClientVersion Exclusion

**What**: ClientVersion is parsed from XML but intentionally excluded from INSERT.

**Rules**:
- `SELECT @ClientVersion = @Params.value('(Root/ClientVersion/@Value)[1]','VARCHAR(20)')` - parsed
- INSERT column list: `------  ClientVersion,` - commented out
- VALUES: `--- @ClientVersion,` - commented out
- ClientVersion is not a column in History.PositionFailLocal/PositionFailWrite
- Parsing it prevents XML validation errors but the value is discarded

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | CODE-BACKED | XML payload built and enqueued by History.PositionFailInfo. Structure: `<Root><PositionID Value="..."/><CID Value="..."/>...</Root>`. One element per field, all as attributes named "Value". |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Async framework bitmask. 0 = run all. Bit 0 (value 1) = run the INSERT. Returns @PartsToDo on success; THROW re-raises on failure. |
| 3 | @ID | INT | NO | - | CODE-BACKED | Action record ID from Internal.ActionSteps. Not used in procedure body. Standard async step interface parameter. |

**Fields Parsed from XML and Inserted into History.PositionFailWrite:**

| # | XML Element | Local Var | SQL Type | Description |
|---|-------------|-----------|----------|-------------|
| 1 | CID | @CID | INT | Customer ID - parsed before @PartsToDo gate |
| 2 | PositionID | @PositionID | BIGINT | Failed position ID (changed to BIGINT 2021-11-24) |
| 3 | FailTypeID | @FailTypeID | INT | Failure type (FK to Dictionary.FailType: 1=Req Open, 2=Req Close, 3=Open, 4=Close, 5=Edit, etc.) |
| 4 | ForexResultID | @ForexResultID | BIGINT | Game/trading context ID |
| 5 | CurrencyID | @CurrencyID | INT | Account currency ID |
| 6 | ProviderID | @ProviderID | INT | Market data provider ID |
| 7 | GameServerID | @GameServerID | INT | Game server that processed the operation |
| 8 | InstrumentID | @InstrumentID | INT | Financial instrument ID |
| 9 | HedgeID | @HedgeID | INT | Hedge order ID |
| 10 | Leverage | @Leverage | INT | Leverage applied |
| 11 | Amount | @Amount | MONEY | Invested amount (note: PositionFailInfo divides by 100 from cents; this receives dollar-unit value) |
| 12 | AmountInUnitsDecimal | @AmountInUnitsDecimal | DECIMAL(16,6) | Position size in instrument units |
| 13 | UnitMargin | @UnitMargin | INT | Margin per unit |
| 14 | LotCountDecimal | @LotCountDecimal | DECIMAL(16,6) | Position size in lots |
| 15 | NetProfit | @NetProfit | MONEY | Net profit at failure time (cents-converted, dollar units in XML) |
| 16 | InitForexRate | @InitForexRate | dtPrice | Opening exchange rate |
| 17 | InitDateTime | @InitDateTime | DATETIME | Position open request timestamp |
| 18 | LimitRate | @LimitRate | dtPrice | Take profit rate |
| 19 | StopRate | @StopRate | dtPrice | Stop loss rate |
| 20 | IsBuy | @IsBuy | BIT | 1=Buy/Long, 0=Sell/Short |
| 21 | CloseOnEndOfWeek | @CloseOnEndOfWeek | BIT | Auto-close at weekend flag |
| 22 | Commission | @Commission | MONEY | Spread/commission amount |
| 23 | CommissionOnClose | @CommissionOnClose | MONEY | Deferred commission on close |
| 24 | SpreadedCommission | @SpreadedCommission | INT | Spreaded commission in points |
| 25 | EndForexRate | @EndForexRate | dtPrice | Closing exchange rate (0 for open failures) |
| 26 | RequestedEndForexRate | @RequestedEndForexRate | dtPrice | Client-requested close rate |
| 27 | EndDateTime | @EndDateTime | DATETIME | Close attempt timestamp |
| 28 | AdditionalParam | @AdditionalParam | SQL_VARIANT | Defaults to 'DB_Direct' if NULL |
| 29 | RequestOpenOccurred | @RequestOpenOccurred | DATETIME | Open request received UTC timestamp |
| 30 | RequestCloseOccurred | @RequestCloseOccurred | DATETIME | Close request received UTC timestamp |
| 31 | OpenOccurred | @OpenOccurred | DATETIME | Actual open timestamp (NULL for open failures) |
| 32 | OrderID | @OrderID | INT | Order ID (NULL if no specific order) |
| 33 | FailReason | @FailReason | VARCHAR(MAX) | Human-readable failure reason text |
| 34 | InitForexPriceRateID | @InitForexPriceRateID | BIGINT | Rate ID for opening rate snapshot |
| 35 | EndForexPriceRateID | @EndForexPriceRateID | BIGINT | Rate ID for closing rate snapshot |
| 36 | OrderPriceRateID | @OrderPriceRateID | BIGINT | Order price rate ID |
| 37 | OrderPriceRate | @OrderPriceRate | dtPrice | Order price rate |
| 38 | ParentPositionID | @ParentPositionID | BIGINT | Parent copy position ID (0=not a copy) |
| 39 | OrigParentPositionID | @OrigParentPositionID | BIGINT | Original parent position ID at open time |
| 40 | LastOpPriceRate | @LastOpPriceRate | dtPrice | Price at last operation |
| 41 | LastOpPriceRateID | @LastOpPriceRateID | BIGINT | Rate ID for last operation |
| 42 | LastOpConversionRate | @LastOpConversionRate | dtPrice | Conversion rate at last operation |
| 43 | LastOpConversionRateID | @LastOpConversionRateID | BIGINT | Rate ID for last conversion |
| 44 | MirrorID | @MirrorID | INT | Mirror relationship ID (0=not mirrored) |
| 45 | IsOpenOpen | @IsOpenOpen | BIT | Pre-market/pending open position flag |
| 46 | ClientVersion | @ClientVersion | VARCHAR(20) | Parsed but NOT inserted (commented out of INSERT) |
| 47 | AmountInUnitsDecimalUnAdjusted | @AmountInUnitsDecimalUnAdjusted | DECIMAL(16,6) | Unadjusted units (before lot-size normalization) |
| 48 | LotCountDecimalUnAdjusted | @LotCountDecimalUnAdjusted | DECIMAL(16,6) | Unadjusted lot count |
| 49 | InitForexRateUnAdjusted | @InitForexRateUnAdjusted | dtPrice | Unadjusted opening rate |
| 50 | LimitRateUnAdjusted | @LimitRateUnAdjusted | dtPrice | Unadjusted take profit rate |
| 51 | StopRateUnAdjusted | @StopRateUnAdjusted | dtPrice | Unadjusted stop loss rate |
| 52 | SessionID | @SessionID | BIGINT | Trading session ID (added 2014-10-29) |
| 53 | ClosePositionActionTypeID | @ClosePositionActionTypeID | INT | Close action type (Manual, SL, TP, etc.) |
| 54 | OrderType | @OrderType | INT | Order type (market, limit, etc.) |
| 55 | FaileOccurred | @FailedOccurred | DATETIME | Failure timestamp - NOTE: XML element name has typo "FaileOccurred" (matches PositionFailInfo builder); stored in column FailOccurred |
| 56 | ClientRequestGuid | @ClientRequestGuid | UNIQUEIDENTIFIER | Client idempotency GUID (added FB:51172) |
| 57 | ClientViewRateID, ClientViewRate, ClientRateForCalcID, ClientRateForCalc | - | BIGINT/DECIMAL(16,6) | Client-visible rate fields (added FB:53286); HedgeServerID, ExecutionID, ErrorCode also added 2019-10-22 |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All parsed XML fields | History.PositionFailWrite | INSERT | Writes parsed failure record to local staging table (synonym -> History.PositionFailLocal) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.AsyncExecuter{N} | Dictionary.Steps StepID=5 | Calls (EXEC) | Called asynchronously after position failure events enqueued by History.PositionFailInfo via Trade.InsertAsyncRecord ActionID=5 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PostPositionFail (procedure, StepID=5)
+-- History.PositionFailWrite (synonym -> History.PositionFailLocal)
    (enqueued by History.PositionFailInfo via Trade.InsertAsyncRecord ActionID=5)
    (called by Internal.AsyncExecuter{N} via Dictionary.Steps StepID=5)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFailWrite | Synonym (-> PositionFailLocal) | INSERT target for the parsed position failure record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.AsyncExecuter{N} | Procedure family | Calls this as StepID=5; the async bridge between Trade.InsertAsyncRecord ActionID=5 queue and History.PositionFailWrite |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StepID=5 registration | Framework | Registered in Dictionary.Steps as "After position failure"; called by Internal.AsyncExecuter{N} |
| THROW on failure | Error handling | Unlike PostDetachMirrorPosition (which returns error code), this re-raises to async framework via THROW |
| ClientVersion excluded | Data gap | ClientVersion is parsed from XML but commented out of INSERT - not stored in PositionFailLocal |
| ISNULL(@AdditionalParam,'DB_Direct') | Default | NULL AdditionalParam stored as 'DB_Direct' string |
| FaileOccurred typo | XML contract | XML element named "FaileOccurred" (not "FailOccurred"); must match History.PositionFailInfo builder which uses the same typo |
| PositionID BIGINT | Change history | PositionID changed from INT to BIGINT on 2021-11-24 per inline comment |

---

## 8. Sample Queries

### 8.1 Check recently inserted local position fail records

```sql
SELECT TOP 20 PositionID, CID, FailTypeID, FailOccurred, FailReason
FROM History.PositionFailLocal WITH (NOLOCK)
ORDER BY FailOccurred DESC
```

### 8.2 Check pending StepID=5 actions in async queue

```sql
SELECT COUNT(*) AS PendingPositionFailActions
FROM Internal.ActionSteps WITH (NOLOCK)
WHERE StepID = 5
  AND IsProcessed = 0
```

### 8.3 Read position failures after Azure sync (via read replica)

```sql
SELECT pf.PositionID, pf.CID, pf.FailTypeID, pf.FailOccurred, pf.FailReason,
       ft.Name AS FailTypeName
FROM History.PositionFail pf WITH (NOLOCK)
LEFT JOIN Dictionary.FailType ft WITH (NOLOCK) ON ft.FailTypeID = pf.FailTypeID
WHERE pf.CID = 12345678
ORDER BY pf.FailOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 57 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PostPositionFail | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.PostPositionFail.sql*
