# Trade.PositionEditExternalInfo

> Updates a position's hedge server assignment and CloseOnEndOfWeek flag, propagating the end-of-week change through the position tree.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (Trade.PositionTbl partition key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionEditExternalInfo is called when a position's external routing attributes need to be updated after it has been opened. The two effective operations are: (1) update the HedgeID on Trade.PositionTbl (the hedge server or partner system this position is routed to), and (2) propagate a CloseOnEndOfWeek flag change through the position tree via Trade.UpdateTree.

The name "ExternalInfo" refers to attributes that are determined by the hedging/routing layer external to the core position lifecycle - the hedge assignment and the weekend-close preference. These are set when the position is placed on a hedge server and may be adjusted as the hedge topology changes (e.g., position moved to a different hedge server).

The SP signature includes many parameters (@LastOpPriceRate, @LastOpPriceRateID, @LastOpConversionRate, @LastOpConversionRateID, @IsInitiatedByUser, and a @PositionInfo table variable) that are declared but not used in the current implementation. A developer comment ("Should check with Moty that we can stop updating that") suggests the HedgeID update itself may be under review for removal. The SP reflects an older, more complex design that was simplified over time.

---

## 2. Business Logic

### 2.1 HedgeID Update

**What**: Updates Trade.PositionTbl.HedgeID to the provided hedge server value.

**Columns/Parameters Involved**: Trade.PositionTbl.HedgeID, @HedgeID, @PositionID

**Rules**:
- UPDATE Trade.PositionTbl SET HedgeID=@HedgeID WHERE PositionID=@PositionID
- No partition elimination applied (unlike other PositionTbl writes that use PartitionCol=@PositionID%50)
- Developer note: "Should check with Moty that we can stop updating that" - suggests this UPDATE may be a candidate for removal
- @HedgeID is INTEGER (not BIGINT) - maps to the HedgeID column type

### 2.2 CloseOnEndOfWeek Tree Propagation

**What**: Reads the TreeID for the position and calls Trade.UpdateTree to propagate the CloseOnEndOfWeek flag.

**Columns/Parameters Involved**: Trade.Position.TreeID, Trade.UpdateTree (@TreeID, NULL, NULL, @CloseOnEndOfWeek, 1)

**Rules**:
- Reads TreeID from Trade.Position (view) WHERE PositionID=@PositionID
- Calls Trade.UpdateTree with @CloseOnEndOfWeek as the 4th argument; other rate/stop arguments are NULL
- 5th argument value 1 is a flag to Trade.UpdateTree (exact semantics defined in Trade.UpdateTree)
- Tree propagation ensures all positions in the same tree hierarchy get consistent CloseOnEndOfWeek

### 2.3 Transaction and Error Handling

**What**: Wraps all operations in a transaction with structured error capture.

**Rules**:
- BEGIN TRY / BEGIN TRANSACTION; COMMIT on success
- CATCH: populates @ErrOut with schema, proc name, ERROR_NUMBER, ERROR_LINE, ERROR_MESSAGE
- ROLLBACK if @@TRANCOUNT=1; COMMIT if @@TRANCOUNT>1 (handles nested transaction scenarios)
- THROW re-raises the exception after capture
- Returns 0 on success; returns ERROR_NUMBER on failure (but THROW prevents RETURN from executing in practice)

### 2.4 Unused Parameters (Vestigial Signature)

**What**: Several parameters and variables are declared but never used in the current SP body.

**Rules**:
- Parameters declared but never read: @LastOpPriceRate, @LastOpPriceRateID, @LastOpConversionRate, @LastOpConversionRateID, @IsInitiatedByUser
- Table variable @PositionInfo is declared with 12 columns but never populated or queried
- Scalar variables derived from @PositionInfo (@PreviousCloseOnEndOfWeek, @EndOfWeekFee, etc.) are declared but never assigned
- These reflect a prior version of the SP with more complex logic that was stripped out

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position to update. Used in PositionTbl UPDATE and Trade.Position SELECT for TreeID. |
| 2 | @HedgeID | INTEGER | NO | - | CODE-BACKED | New hedge server assignment. Written to Trade.PositionTbl.HedgeID. Identifies the routing partner for this position. |
| 3 | @CloseOnEndOfWeek | BIT | YES | 0 | CODE-BACKED | Whether the position should auto-close at end of trading week. Propagated to the position tree via Trade.UpdateTree. |
| 4 | @LastOpPriceRate | dtPrice | YES | NULL | CODE-BACKED | Declared but unused. Last operation price rate. Present in signature for API compatibility with callers. |
| 5 | @LastOpPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Declared but unused. Last operation price rate row ID. Present for API compatibility. |
| 6 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Declared but unused. Last operation conversion rate. Present for API compatibility. |
| 7 | @LastOpConversionRateID | BIGINT | YES | NULL | CODE-BACKED | Declared but unused. Last operation conversion rate row ID. Present for API compatibility. |
| 8 | @IsInitiatedByUser | INT | NO | - | CODE-BACKED | Declared but unused. Flag indicating whether the edit was user-initiated vs. system-initiated. Present for API compatibility. |
| 9 | @ErrOut | NVARCHAR(4000) | YES | '' | CODE-BACKED | OUTPUT parameter populated on error with SP name, ERROR_NUMBER, ERROR_LINE, ERROR_MESSAGE. Allows callers to inspect error details without catching the re-thrown exception. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE HedgeID | Trade.PositionTbl | DML write | Updates HedgeID for the given PositionID |
| SELECT TreeID | Trade.Position | DML read | Reads TreeID to identify the tree for UpdateTree call |
| EXEC | Trade.UpdateTree | Procedure call | Propagates CloseOnEndOfWeek change through position tree |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in SSDT repo or application repos. Called by external hedge management or position routing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionEditExternalInfo (procedure)
+-- Trade.PositionTbl (table) - HedgeID UPDATE
+-- Trade.Position (view/table) - TreeID read
+-- Trade.UpdateTree (procedure) - tree propagation for CloseOnEndOfWeek
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | UPDATE HedgeID for @PositionID |
| Trade.Position | View/Table | SELECT TreeID WHERE PositionID=@PositionID |
| Trade.UpdateTree | Stored Procedure | EXEC to propagate CloseOnEndOfWeek change through tree |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called by external routing/hedge management services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Note: Trade.PositionTbl UPDATE lacks partition elimination (no PartitionCol=@PositionID%50 filter) which is atypical for PositionTbl writes.

### 7.2 Constraints

- @PositionID must exist in Trade.PositionTbl and Trade.Position for the UPDATE and SELECT to succeed
- The nested transaction handling (@@TRANCOUNT > 1 -> COMMIT) supports callers that wrap this in an outer transaction

---

## 8. Sample Queries

### 8.1 Update hedge assignment and end-of-week flag

```sql
DECLARE @ErrOut NVARCHAR(4000) = '';
EXEC Trade.PositionEditExternalInfo
    @PositionID          = 123456789,
    @HedgeID             = 42,
    @CloseOnEndOfWeek    = 1,
    @IsInitiatedByUser   = 1,
    @ErrOut              = @ErrOut OUTPUT;

IF @ErrOut <> ''
    PRINT 'Error: ' + @ErrOut;
```

### 8.2 Update hedge assignment only (no end-of-week change)

```sql
DECLARE @ErrOut NVARCHAR(4000) = '';
EXEC Trade.PositionEditExternalInfo
    @PositionID          = 123456789,
    @HedgeID             = 15,
    @CloseOnEndOfWeek    = 0,
    @IsInitiatedByUser   = 0,
    @ErrOut              = @ErrOut OUTPUT;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionEditExternalInfo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionEditExternalInfo.sql*
