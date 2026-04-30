# History.PostDetachMirrorPosition

> Async post-action step (StepID=6) for mirror detach events - parses a multi-position XML payload from the Internal async framework and bulk inserts all detached position state records into History.PositionChangeLog_Active_BIGINT. Called by Internal.AsyncExecuter{N} after a copy-trading detach operation completes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params (XML) - contains one or more Pos nodes with position state at detach time |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PostDetachMirrorPosition` is the async post-processing handler for copy-trading mirror detach events. It is registered as **StepID=6** in `Dictionary.Steps` ("After mirror detach"), meaning it is enqueued in `Internal.ActionSteps` whenever a position is detached from a copy-trading mirror relationship, and then executed asynchronously by the `Internal.AsyncExecuter{N}` family of procedures.

When a copier detaches one or more positions from a Popular Investor's copy relationship, the primary trading operation records the detach event. This procedure then receives the full position state for each detached position (packaged as XML nodes), parses them, and bulk inserts them into `History.PositionChangeLog_Active_BIGINT`. The inserted rows typically carry ChangeTypeID=14 (Detach from Mirror), creating the permanent audit trail in the position change log.

The procedure supports bulk processing: a single call can insert multiple detached positions via multiple `<Pos>` nodes in the `<Root>` XML. If the INSERT fails, the error is caught and reflected in the return value without re-raising, allowing the async framework to detect and handle the failure gracefully.

Data flow: (1) Async framework calls with @Params=XML containing one or more `<Pos>` elements, @PartsToDo=bitflag, @ID=action record ID; (2) check if bit 0 of @PartsToDo is set (or @PartsToDo=0 for "run all"); (3) parse all `<Pos>` nodes via `@Params.nodes('Root/Pos')` XQuery; (4) INSERT all parsed rows into History.PositionChangeLog_Active_BIGINT in one batch; (5) return @PartsToDo (success) or @PartsToDo+1 (INSERT failed); (6) END.

History note: PositionID changed to BIGINT on 2021-11-17 (per DDL comment "Bonnie - Change positionID to bigint").

---

## 2. Business Logic

### 2.1 Async Framework @PartsToDo Bitflag

**What**: The @PartsToDo parameter is a bitmask that controls which "parts" of the post-action procedure execute. Bit 0 (value 1) controls this procedure's sole operation.

**Columns/Parameters Involved**: `@PartsToDo`, `@RetVal`

**Rules**:
- `IF @PartsToDo = 0 OR @PartsToDo & 1 = 1` - the insert runs if @PartsToDo=0 (run all) OR bit 0 is set
- @PartsToDo=0 is the "run everything" sentinel used by Internal.AsyncExecuter for a full pass
- Non-zero @PartsToDo with specific bits set enables selective partial re-runs (e.g., re-run only failed parts)
- Return value: starts at @PartsToDo; incremented by 1 in CATCH block if INSERT fails

**Return Value Semantics**:
```
Success:  RETURN @PartsToDo      (e.g., 0 if @PartsToDo=0)
Failure:  RETURN @PartsToDo + 1  (caller detects failure: RetVal > @PartsToDo)
```

### 2.2 XML Bulk Parse and INSERT

**What**: All `<Pos>` nodes in the XML are parsed in a single set-based INSERT without a row-by-row loop.

**Columns/Parameters Involved**: `@Params` (XML), `History.PositionChangeLog_Active_BIGINT`

**Rules**:
- XQuery path: `@Params.nodes('Root/Pos')` - each `<Pos>` node maps to one INSERT row
- Attribute extraction pattern: `tbl.xcol.value('(ColumnName/@Value)[1]', 'type')` - values are in `Value` attributes of child elements
- All 27 columns are populated from the XML in a single INSERT...SELECT
- ChangeTypeID is embedded in the XML payload (set by the caller, typically 14 = Detach from Mirror)
- No transaction, no explicit error handling beyond TRY/CATCH

**XML Structure** (one Pos node per detached position):
```xml
<Root>
  <Pos>
    <PositionID Value="123456789"/>
    <CID Value="1001"/>
    <ChangeTypeID Value="14"/>
    <MirrorID Value="555"/>
    <ParentPositionID Value="111111"/>
    <OrigParentPositionID Value="111111"/>
    <Occurred Value="2026-03-21T10:00:00"/>
    <PreviousCloseOnEndOfWeek Value="0"/>
    <CloseOnEndOfWeek Value="0"/>
    <PreviousEndOfWeekFee Value="0"/>
    <EndOfWeekFee Value="0"/>
    <PreviousAmount Value="1000.00"/>
    <AmountChanged Value="0"/>
    <NewAmount Value="1000.00"/>
    <PreviousLimitRate Value="0"/>
    <LimitRate Value="0"/>
    <PreviousStopRate Value="0"/>
    <StopRate Value="0"/>
    <LastOpPriceRate Value="1.2345"/>
    <LastOpPriceRateID Value="9876"/>
    <LastOpConversionRate Value="1.0"/>
    <LastOpConversionRateID Value="5432"/>
    <ClientVersion Value="W"/>
    <AccountRealizedEquity Value="5000.00"/>
    <MirrorRealizedEquity Value="2000.00"/>
    <TreeID Value="789"/>
    <PrevTreeID Value="789"/>
  </Pos>
</Root>
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | CODE-BACKED | XML payload containing one or more `<Root><Pos>` nodes. Each `<Pos>` node holds the full position state at detach time, to be parsed and inserted into History.PositionChangeLog_Active_BIGINT. |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Async framework bitmask. 0 = run all parts. Bit 0 (value 1) = run the INSERT part. Non-zero with bit 0 unset = skip (no-op). Return value = @PartsToDo on success, @PartsToDo+1 on INSERT failure. |
| 3 | @ID | INT | NO | - | CODE-BACKED | Action record ID from Internal.ActionSteps. Part of the standard async step interface contract. Not used in the procedure body - present for interface compatibility with Internal.AsyncExecuter{N} callers. |

**Columns Inserted into History.PositionChangeLog_Active_BIGINT:**

| # | Column | XML Element | Type | Description |
|---|--------|-------------|------|-------------|
| C1 | PositionID | PositionID/@Value | BIGINT | Position ID of the detached position. Changed to BIGINT 2021-11-17. |
| C2 | CID | CID/@Value | INT | Customer ID of the copier who detached. |
| C3 | ChangeTypeID | ChangeTypeID/@Value | SMALLINT | Type of change. For detach operations: 14 = Detach from Mirror. |
| C4 | MirrorID | MirrorID/@Value | INT | Mirror/copy relationship ID being detached from. |
| C5 | ParentPositionID | ParentPositionID/@Value | BIGINT | Parent trader's position ID being detached from. |
| C6 | OrigParentPositionID | OrigParentPositionID/@Value | BIGINT | Original parent position ID at copy open time (before any prior detachments). |
| C7 | Occurred | Occurred/@Value | DATETIME | Timestamp of the detach event. |
| C8 | PreviousCloseOnEndOfWeek | PreviousCloseOnEndOfWeek/@Value | SMALLINT | CloseOnEndOfWeek value before the detach. |
| C9 | CloseOnEndOfWeek | CloseOnEndOfWeek/@Value | SMALLINT | CloseOnEndOfWeek value after the detach. |
| C10 | PreviousEndOfWeekFee | PreviousEndOfWeekFee/@Value | MONEY | End-of-week fee before detach. |
| C11 | EndOfWeekFee | EndOfWeekFee/@Value | MONEY | End-of-week fee after detach. |
| C12 | PreviousAmount | PreviousAmount/@Value | MONEY | Invested amount before the detach. |
| C13 | AmountChanged | AmountChanged/@Value | MONEY | Amount delta during the detach operation. |
| C14 | NewAmount | NewAmount/@Value | MONEY | Invested amount after the detach. |
| C15 | PreviousLimitRate | PreviousLimitRate/@Value | MONEY | Take profit rate before detach. |
| C16 | LimitRate | LimitRate/@Value | MONEY | Take profit rate after detach. |
| C17 | PreviousStopRate | PreviousStopRate/@Value | MONEY | Stop loss rate before detach. |
| C18 | StopRate | StopRate/@Value | MONEY | Stop loss rate after detach. |
| C19 | LastOpPriceRate | LastOpPriceRate/@Value | MONEY | Price rate at the time of the detach operation. |
| C20 | LastOpPriceRateID | LastOpPriceRateID/@Value | BIGINT | Rate ID for the last operation price. |
| C21 | LastOpConversionRate | LastOpConversionRate/@Value | MONEY | Currency conversion rate at detach time. |
| C22 | LastOpConversionRateID | LastOpConversionRateID/@Value | BIGINT | Rate ID for the last operation conversion rate. |
| C23 | ClientVersion | ClientVersion/@Value | CHAR(1) | Client type that initiated the detach (W=Web, M=Mobile, etc.). |
| C24 | AccountRealizedEquity | AccountRealizedEquity/@Value | MONEY | Customer's total realized equity at detach time. |
| C25 | MirrorRealizedEquity | MirrorRealizedEquity/@Value | MONEY | Realized equity for the mirror relationship at detach time. |
| C26 | TreeID | TreeID/@Value | BIGINT | Copy-tree structure ID after the detach. |
| C27 | PrevTreeID | PrevTreeID/@Value | BIGINT | Copy-tree structure ID before the detach. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Parsed XML data | History.PositionChangeLog_Active_BIGINT | INSERT (bulk) | Bulk inserts all parsed Pos nodes as position change log records with ChangeTypeID=14 (Detach from Mirror) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.AsyncExecuter{N} | Dictionary.Steps StepID=6 | Calls (EXEC) | Called asynchronously by the Internal async executer family after a mirror detach operation is enqueued in Internal.ActionSteps |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PostDetachMirrorPosition (procedure, StepID=6)
+-- History.PositionChangeLog_Active_BIGINT (table)
    (called by Internal.AsyncExecuter{N} via Dictionary.Steps StepID=6)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLog_Active_BIGINT | Table | INSERT target for parsed detach position state records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.AsyncExecuter{N} | Procedure family | Calls this procedure as StepID=6 post-action handler after mirror detach |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StepID=6 registration | Framework | Registered in Dictionary.Steps as the "After mirror detach" handler; called by Internal.AsyncExecuter{N} |
| @PartsToDo bitflag | Interface | 0=run all; bit 0 set=run INSERT part. Return value encodes success/failure status for the caller |
| @ID unused | Interface note | @ID parameter is present for framework interface compatibility but not used in the procedure body |
| TRY/CATCH | Error handling | INSERT errors are caught and reflected in return value (+1 to @PartsToDo) without re-raising; prevents async framework from crashing |
| SET NOCOUNT ON | Optimization | Suppresses row count messages for async processing compatibility |
| PositionID BIGINT | Change history | PositionID changed from INT to BIGINT on 2021-11-17 per inline comment |

---

## 8. Sample Queries

### 8.1 Check recent detach change log entries

```sql
SELECT TOP 20 PositionID, CID, MirrorID, ParentPositionID, Occurred,
       ChangeTypeID, PreviousAmount, NewAmount
FROM History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE ChangeTypeID = 14  -- Detach from Mirror
ORDER BY Occurred DESC
```

### 8.2 Find pending detach post-actions in the queue

```sql
SELECT COUNT(*) AS PendingDetachActions
FROM Internal.ActionSteps WITH (NOLOCK)
WHERE StepID = 6  -- History.PostDetachMirrorPosition
  AND IsProcessed = 0
```

### 8.3 Verify detach records for a specific mirror

```sql
SELECT PositionID, CID, MirrorID, Occurred, AccountRealizedEquity, MirrorRealizedEquity
FROM History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE MirrorID = 555
  AND ChangeTypeID = 14
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PostDetachMirrorPosition | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.PostDetachMirrorPosition.sql*
