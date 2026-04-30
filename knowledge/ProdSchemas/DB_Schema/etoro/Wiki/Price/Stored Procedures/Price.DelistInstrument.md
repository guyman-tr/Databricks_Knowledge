# Price.DelistInstrument

> Instrument delisting procedure that removes all liquidity account-to-instrument feed eligibility mappings for a given instrument and triggers orphan cleanup in InstrumentRateSources, returning the AccountRateSourceIDs of the affected feeds so the caller can update its in-memory routing state.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - instrument to delist |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.DelistInstrument is the instrument delisting entry point for the Price schema's feed routing system. When an instrument is delisted from eToro's platform, this procedure removes it from the pricing infrastructure in two coordinated steps.

This procedure exists because delisting an instrument is not just a data delete - it requires cascaded cleanup of the feed routing configuration. Without this cleanup, the pricing engine's in-memory source tables would continue to reference routing entries for the instrument, potentially causing errors or routing attempts to a non-existent feed.

The three-step execution:
1. DELETE all rows from `Price.LiquidityAccountToInstrument` for the instrument (removes all feed account eligibility), capturing the deleted LiquidityAccountIDs into a temp table.
2. SELECT `AccountRateSourceID` from `Trade.LiquidityAccounts` for those deleted accounts - this is the result set returned to the caller. The calling service uses these IDs to purge the instrument's sources from its in-memory feed routing cache.
3. EXEC `Price.CleanUnmappedInstrumentRateSources` - cascades cleanup to `Price.InstrumentRateSources`, removing orphaned priority-source assignments that are now backed by no active account.

---

## 2. Business Logic

### 2.1 Feed Routing Deregistration Flow

**What**: Removing an instrument from the pricing system requires both DB-level cleanup and returning the affected feed identifiers to the caller.

**Columns/Parameters Involved**: `@InstrumentID`, `LiquidityAccountID`, `AccountRateSourceID`

**Rules**:
- DELETE uses OUTPUT clause: all deleted `LiquidityAccountID` values are captured into `#Accounts` before the call to CleanUnmappedInstrumentRateSources
- The SELECT result set is the procedure's primary output - it returns the `AccountRateSourceID` of every liquidity account that was servicing the instrument. The caller is expected to use this to update its in-memory instrument-to-source mapping
- EXEC CleanUnmappedInstrumentRateSources runs after the DELETE, ensuring the InstrumentRateSources table is also cleaned (see that procedure's doc for its two-pass orphan deletion logic)
- No transaction wrapping: if CleanUnmappedInstrumentRateSources fails, the DELETE is already committed

**Diagram**:
```
EXEC Price.DelistInstrument @InstrumentID = X
  |
  +--> DELETE Price.LiquidityAccountToInstrument WHERE InstrumentID = X
  |      OUTPUT deleted.LiquidityAccountID -> #Accounts
  |
  +--> SELECT AccountRateSourceID FROM Trade.LiquidityAccounts
  |      JOIN #Accounts ON LiquidityAccountID
  |      [Returns result set to caller: "these feed sources were removed"]
  |
  +--> EXEC Price.CleanUnmappedInstrumentRateSources
         [Removes orphaned rows from Price.InstrumentRateSources]
```

### 2.2 No Error Handling / Transaction

**What**: The procedure has no TRY/CATCH, no explicit transaction, and SET NOCOUNT ON.

**Rules**:
- SET NOCOUNT ON suppresses row-count messages but does NOT suppress the SELECT result set (result sets are always returned regardless of NOCOUNT)
- The DELETE and SELECT run as individual implicit transactions
- If the EXEC of CleanUnmappedInstrumentRateSources fails after the DELETE has committed, the LiquidityAccountToInstrument rows are gone but InstrumentRateSources orphans may remain - requiring a manual re-run of the cleanup procedure

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The instrument to delist. Used as the WHERE predicate in the DELETE against Price.LiquidityAccountToInstrument (InstrumentID = @InstrumentID). Must be a valid InstrumentID; no existence check is performed - if the instrument has no rows in LiquidityAccountToInstrument, the DELETE silently affects 0 rows. |

**Result set returned**: AccountRateSourceID values (INT) for all liquidity accounts that were mapped to the delisted instrument. The caller uses these to purge in-memory feed routing entries.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Price.LiquidityAccountToInstrument | DELETE target | Removes all eligibility mappings for the instrument |
| LiquidityAccountID (from #Accounts) | Trade.LiquidityAccounts | JOIN (SELECT) | Resolves deleted account IDs to their AccountRateSourceIDs for the result set |
| (implicit) | Price.CleanUnmappedInstrumentRateSources | EXEC | Cascades cleanup to InstrumentRateSources after the eligibility removal |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (application code) | @InstrumentID | CALLER | No SP callers found in DB. Called from application layer when an instrument is delisted from the platform. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.DelistInstrument (procedure)
+-- Price.LiquidityAccountToInstrument (table) - DELETE target
+-- Trade.LiquidityAccounts (table) - SELECT source for AccountRateSourceIDs
+-- Price.CleanUnmappedInstrumentRateSources (procedure)
      +-- Price.InstrumentRateSources (table) - DELETE target (orphan cleanup)
      +-- Price.LiquidityAccountToInstrument (table) - backing check
      +-- Trade.LiquidityAccounts (table) - activity + type filter
      +-- Price.PCSToLiquidityAccount (table) - PCS coverage check
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityAccountToInstrument | Table | DELETE target - removes all feed account eligibility for the instrument |
| Trade.LiquidityAccounts | Table | SELECT source - resolves deleted LiquidityAccountIDs to AccountRateSourceIDs for result set |
| Price.CleanUnmappedInstrumentRateSources | Stored Procedure | EXEC callee - cascades orphan cleanup to InstrumentRateSources |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (application layer) | - | Calls this procedure when delisting an instrument from the trading platform |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No transaction, no TRY/CATCH, no error handling. The procedure uses SET NOCOUNT ON and relies on implicit single-statement transactions for the DELETE and SELECT. The OUTPUT clause on the DELETE captures deleted rows into #Accounts before the SELECT - this is the mechanism enabling the caller to know which sources were affected. CleanUnmappedInstrumentRateSources is called unconditionally after the DELETE (even if 0 rows were deleted).

---

## 8. Sample Queries

### 8.1 Execute the delisting procedure for an instrument

```sql
EXEC Price.DelistInstrument @InstrumentID = 12345;
-- Returns result set: AccountRateSourceIDs that were freed
```

### 8.2 Preview what will be deleted before running

```sql
SELECT LATI.LiquidityAccountID, TLA.AccountRateSourceID, LATI.InstrumentID
FROM Price.LiquidityAccountToInstrument LATI WITH (NOLOCK)
JOIN Trade.LiquidityAccounts TLA WITH (NOLOCK)
    ON TLA.LiquidityAccountID = LATI.LiquidityAccountID
WHERE LATI.InstrumentID = 12345;
```

### 8.3 Verify cleanup was successful

```sql
-- Should return 0 rows after running DelistInstrument
SELECT * FROM Price.LiquidityAccountToInstrument WITH (NOLOCK) WHERE InstrumentID = 12345;
SELECT * FROM Price.InstrumentRateSources WITH (NOLOCK) WHERE InstrumentID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped - no app code), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira MCP 410 error) | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.DelistInstrument | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.DelistInstrument.sql*
