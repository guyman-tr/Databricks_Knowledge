# Trade.InstrumentRateSourceAdd

> Upserts an instrument rate source mapping: if the combination (InstrumentID + LiquidityAccountID + PriceServerID) already exists, updates its Priority; otherwise creates a new mapping in Trade.InstrumentRateSources and returns the assigned ID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentRateSourceID OUTPUT - ID of the created or existing mapping |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentRateSourceAdd is the upsert endpoint for instrument rate source mappings. When a new price feed (liquidity account + price server) needs to supply rates for an instrument, this procedure creates the mapping and assigns a unique ID. If the same combination already exists, it simply updates the Priority instead of failing - making it idempotent and safe to call multiple times.

Without this procedure, creating rate source mappings would require callers to check for duplicates themselves. The upsert logic prevents duplicate rows for the same (InstrumentID, LiquidityAccountID, PriceServerID) combination, which would confuse the rate routing logic. The @InstrumentRateSourceID OUTPUT allows the caller to track which row was affected (new or existing).

Data flow: Operations tooling or instrument configuration pipelines call this procedure when connecting an instrument to a liquidity provider's price feed. If the mapping already exists, only Priority is updated (delegated to Trade.InstrumentRateSourceEdit). If new, Internal.GetInstrumentRateSourceID allocates the next ID, and the row is inserted. Trade.InstrumentRateSources holds the result, which is read by the price subsystem for rate source resolution.

---

## 2. Business Logic

### 2.1 Upsert: Edit if Exists, Insert if Not

**What**: Deduplication check on (InstrumentID + LiquidityAccountID + PriceServerID) before deciding whether to update or insert.

**Columns/Parameters Involved**: `@InstrumentID`, `@LiquidityAccountID`, `@PriceServerID`, `@Priority`, `@InstrumentRateSourceID` (OUTPUT)

**Rules**:
- Check: SELECT InstrumentRateSourceID WHERE (InstrumentID = @InstrumentID AND LiquidityAccountID = @LiquidityAccountID AND PriceServerID = @PriceServerID).
- If found (@InstrumentRateSourceIDCheck IS NOT NULL):
  - Call Trade.InstrumentRateSourceEdit with the existing ID and the new @Priority.
  - @InstrumentRateSourceID OUTPUT is NOT set in this path (remains NULL/uninitialized) - the caller does not receive the existing ID back via output param; only RETURN 0/error is returned.
  - If Edit returns != 0: RAISERROR(60000) and RETURN (no explicit return code).
- If not found:
  - SET @InstrumentRateSourceID = NULL (defensive reset).
  - BEGIN TRAN, call Internal.GetInstrumentRateSourceID @InstrumentRateSourceID OUTPUT.
  - INSERT with allocated ID.
  - @@ERROR check: on error ROLLBACK + RAISERROR + RETURN 60000; on success COMMIT + RETURN 0.

**Diagram**:
```
Inputs: @InstrumentID, @LiquidityAccountID, @PriceServerID, @Priority
    |
    v
SELECT InstrumentRateSourceID WHERE (InstrumentID, LiquidityAccountID, PriceServerID)
    |
    +--[EXISTS]--> EXEC Trade.InstrumentRateSourceEdit
    |                  @InstrumentRateSourceIDCheck, @Priority
    |              -> RETURN 0 (or error if Edit fails)
    |
    +--[NOT EXISTS]--> BEGIN TRAN
                           Internal.GetInstrumentRateSourceID -> @InstrumentRateSourceID OUTPUT
                           INSERT Trade.InstrumentRateSources
                               (InstrumentRateSourceID, InstrumentID, LiquidityAccountID,
                                PriceServerID, Priority)
                           @@ERROR = 0 -> COMMIT + RETURN 0
                           @@ERROR != 0 -> ROLLBACK + RAISERROR(60000) + RETURN 60000

Output: @InstrumentRateSourceID (new ID on insert path; unset on edit path)
```

### 2.2 Error Conventions

**What**: Error handling follows the platform's 60000 convention and uses old-style @@ERROR checking.

**Rules**:
- RAISERROR(60000, 16, 1, 'Trade.InstrumentRateSourceEdit', @Answer) when Edit fails.
- RAISERROR(60000, 16, 1, 'Trade.InstrumentRateSourceEdit', @@ERROR) when INSERT fails (misleading context message - references Edit in the error text even though it is the INSERT path).
- RETURN 60000 on INSERT failure; no explicit RETURN on Edit failure path (falls through).
- Uses legacy @@ERROR instead of TRY/CATCH.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | The instrument to configure a rate source for. Must exist in Trade.Instrument. Part of the uniqueness key (InstrumentID + LiquidityAccountID + PriceServerID). |
| 2 | @LiquidityAccountID | int | NO | - | CODE-BACKED | The liquidity account supplying price rates for this instrument. Part of the uniqueness key. References Trade.LiquidityAccounts. |
| 3 | @PriceServerID | int | NO | - | CODE-BACKED | The price server scoping this rate source. Part of the uniqueness key. Can effectively be NULL for unscoped sources (depends on calling conventions). |
| 4 | @Priority | int | NO | - | CODE-BACKED | Priority of this rate source relative to others for the same instrument. Controls which liquidity account is preferred for rate selection. Updated when the mapping already exists (upsert Edit path). |
| 5 | @InstrumentRateSourceID | int OUTPUT | NO | - | CODE-BACKED | OUTPUT. On INSERT path: newly allocated ID from Internal.GetInstrumentRateSourceID. On EDIT path (existing mapping): value is NOT set by this procedure - remains at whatever the caller initialized it to. Callers should only rely on this output when RETURN = 0 and a new insert occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (dedup check) | Trade.InstrumentRateSources | Reader | Checks for existing mapping on same (InstrumentID, LiquidityAccountID, PriceServerID) |
| EXEC (edit path) | Trade.InstrumentRateSourceEdit | Callee | Delegates Priority update to Edit when duplicate exists |
| EXEC (insert path) | Internal.GetInstrumentRateSourceID | Callee | Allocates next InstrumentRateSourceID before INSERT |
| INSERT target | Trade.InstrumentRateSources | Writer | New rate source mapping on insert path |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called from instrument rate source administration tooling or the Price schema's InstrumentRateSourceAdd procedure (Price.InstrumentRateSourceAdd.sql references the same pattern).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentRateSourceAdd (procedure)
├── Trade.InstrumentRateSources (table) - dedup check + INSERT target
├── Trade.InstrumentRateSourceEdit (procedure) - called on duplicate path
└── Internal.GetInstrumentRateSourceID (procedure) - ID generator on insert path
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentRateSources | Table | Deduplication check and INSERT target |
| Trade.InstrumentRateSourceEdit | Stored Procedure | Called when existing mapping detected (updates Priority) |
| Internal.GetInstrumentRateSourceID | Stored Procedure | Allocates InstrumentRateSourceID for new inserts |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instrument rate source administration tooling | External | Calls to add or update rate source mappings |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error code 60000 | Convention | Platform-standard error code for instrument management errors |
| @@ERROR pattern | Legacy | Pre-TRY/CATCH error handling - same as InstrumentRateSourceDelete/Edit |
| @InstrumentRateSourceID behavior | Design | OUTPUT param only reliably set on INSERT path. On EDIT path it is initialized to NULL and never assigned by this procedure. Callers must not rely on it for the edit path. |

---

## 8. Sample Queries

### 8.1 Add a rate source mapping for an instrument

```sql
DECLARE @NewID INT = NULL;
DECLARE @RC INT;
EXEC @RC = Trade.InstrumentRateSourceAdd
    @InstrumentID           = 1,
    @LiquidityAccountID     = 10,
    @PriceServerID          = 5,
    @Priority               = 1,
    @InstrumentRateSourceID = @NewID OUTPUT;

SELECT @RC AS ReturnCode, @NewID AS AssignedID;
-- @NewID is set only if a new row was inserted (not on update path)
```

### 8.2 Re-call with same combo to update Priority (upsert)

```sql
DECLARE @ExistingID INT = NULL;
EXEC Trade.InstrumentRateSourceAdd
    @InstrumentID           = 1,
    @LiquidityAccountID     = 10,
    @PriceServerID          = 5,
    @Priority               = 2,  -- updated priority
    @InstrumentRateSourceID = @ExistingID OUTPUT;
-- Will call InstrumentRateSourceEdit internally; @ExistingID remains NULL
```

### 8.3 View rate sources for an instrument after add

```sql
SELECT
    irs.InstrumentRateSourceID,
    irs.InstrumentID,
    irs.LiquidityAccountID,
    irs.PriceServerID,
    irs.Priority
FROM Trade.InstrumentRateSources irs WITH (NOLOCK)
WHERE irs.InstrumentID = 1
ORDER BY irs.Priority;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentRateSourceAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InstrumentRateSourceAdd.sql*
