# Price.InstrumentRateSourceAdd

> Upsert procedure for Price.InstrumentRateSources: inserts a new instrument-to-rate-source mapping if it does not exist, or delegates to Price.InstrumentRateSourceEdit to update the Priority if it already exists. Output parameter @InstrumentRateSourceID is declared but never populated (always returns NULL).

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID, @AccountRateSourceID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.InstrumentRateSourceAdd is the primary write procedure for managing instrument rate source routing. It implements an upsert pattern: the caller can unconditionally call it to "ensure this instrument uses this rate source at this priority" without needing to first check whether the mapping exists.

Two scenarios:
1. **New mapping**: The (InstrumentID, AccountRateSourceID) combination does not exist in InstrumentRateSources -> insert a new row at the specified Priority
2. **Existing mapping**: The combination already exists -> call `Price.InstrumentRateSourceEdit` to update the Priority of the existing row

This enforces the business rule that each instrument can have each rate source at most once in its routing table. Calling this procedure twice for the same (InstrumentID, AccountRateSourceID) with different priorities simply changes the priority - it does not create a second row.

The OUTPUT parameter `@InstrumentRateSourceID` is declared for historical compatibility: original code called `Internal.GetInstrumentRateSourceID` (commented out) to retrieve a generated ID. The parameter is never SET in the current implementation and always returns NULL. Callers should not rely on this output.

---

## 2. Business Logic

### 2.1 Upsert: Existence Check and Branch

**What**: Checks if the (InstrumentID, AccountRateSourceID) combination already exists, then takes the appropriate path.

**Columns/Parameters Involved**: `@InstrumentID`, `@AccountRateSourceID`, `@InstrumentRateSourceIDCheck`

**Rules**:
- `SELECT @InstrumentRateSourceIDCheck = InstrumentRateSourceID FROM Price.InstrumentRateSources WITH(NOLOCK) WHERE InstrumentID = @InstrumentID AND AccountRateSourceID = @AccountRateSourceID`
- If result is NOT NULL (row exists): route to UPDATE path (call InstrumentRateSourceEdit)
- If result is NULL (row doesn't exist): route to INSERT path
- NOLOCK on the existence check read (consistent with other Price SP patterns)

### 2.2 Update Path - Delegate to InstrumentRateSourceEdit

**What**: When the mapping already exists, InstrumentRateSourceEdit is called to update the Priority.

**Columns/Parameters Involved**: `@InstrumentRateSourceIDCheck`, `@Priority`, `@Answer`

**Rules**:
- `EXEC @Answer = Price.InstrumentRateSourceEdit @InstrumentRateSourceIDCheck, @Priority`
- `IF @Answer <> 0`: edit failed -> RAISERROR(60000, 16, 1, 'Price.InstrumentRateSourceEdit', @Answer); RETURN
- `IF @Answer = 0`: edit succeeded -> no explicit RETURN in this branch (procedure exits naturally)
- Uses the return value from InstrumentRateSourceEdit (0=success, 60000=not found) to detect failure

### 2.3 Insert Path - New Row with Transaction

**What**: When no existing mapping is found, inserts a new row with explicit transaction and @@ERROR checking.

**Columns/Parameters Involved**: `@InstrumentID`, `@AccountRateSourceID`, `@Priority`

**Rules**:
- `BEGIN TRAN` -> `INSERT INTO Price.InstrumentRateSources (InstrumentID, AccountRateSourceID, Priority) VALUES (@InstrumentID, @AccountRateSourceID, @Priority)`
- `IF @@ERROR <> 0`: ROLLBACK; RAISERROR(60000, 16, 1, 'Price.InstrumentRateSourceAdd', @@ERROR); RETURN 60000
- `ELSE`: COMMIT (only COMMIT is controlled by ELSE; RETURN 0 follows unconditionally if RETURN 60000 was not executed)
- The IDENTITY column (InstrumentRateSourceID) is auto-generated on INSERT

### 2.4 @InstrumentRateSourceID OUTPUT - Unused Parameter

**What**: The OUTPUT parameter is declared but never assigned - always returns NULL.

**Columns/Parameters Involved**: `@InstrumentRateSourceID`

**Rules**:
- Declared: `@InstrumentRateSourceID INT OUTPUT`
- Never SET in any code path
- Comment in code: `--SET @InstrumentRateSourceID = NULL` and `--EXEC Internal.GetInstrumentRateSourceID @InstrumentRateSourceID OUTPUT` (commented out)
- Historical artifact: prior implementation called Internal.GetInstrumentRateSourceID to populate this; replaced by IDENTITY auto-generation; parameter kept for API compatibility
- Callers passing an OUTPUT variable will receive NULL; do not rely on this value

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The instrument to add or update a rate source mapping for. FK to Trade.Instrument. Combined with @AccountRateSourceID to determine upsert branch. |
| 2 | @AccountRateSourceID | INT | NOT NULL | - | CODE-BACKED | The rate source to assign to this instrument. FK to Price.AccountRateSource. Combined with @InstrumentID to check for existing mapping. |
| 3 | @Priority | INT | NOT NULL | - | CODE-BACKED | Priority tier for this rate source mapping. Standard values: 10=primary (first queried), 20=secondary, 30=tertiary, 40=quaternary. Lower value = higher precedence in the pricing engine fallback chain. |
| 4 | @InstrumentRateSourceID | INT OUTPUT | YES | - | CODE-BACKED | OUTPUT parameter - always returns NULL in current implementation. Declared for historical API compatibility (previously populated by Internal.GetInstrumentRateSourceID, now commented out). Do not use this output. |

**Result set**: None. Returns 0 (success) or 60000 (error) via RETURN. RAISERROR raised on failure.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID + AccountRateSourceID | Price.InstrumentRateSources | WRITER (UPSERT) | INSERT if new, UPDATE Priority via InstrumentRateSourceEdit if existing |
| @InstrumentRateSourceIDCheck | Price.InstrumentRateSourceEdit | CALLER | Called in update path with existing InstrumentRateSourceID and new Priority |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing configuration API/OPS tool) | @InstrumentID, @AccountRateSourceID, @Priority | CALLER | Called to add or update instrument rate source routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InstrumentRateSourceAdd (procedure)
+-- Price.InstrumentRateSources (table) - read (existence check) + INSERT target
+-- Price.InstrumentRateSourceEdit (procedure) - called in update path
    +-- Price.InstrumentRateSources (table) - UPDATE target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSources | Table | SELECT existence check; INSERT on new mapping |
| Price.InstrumentRateSourceEdit | Stored Procedure | EXEC in update path to change Priority of existing row |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing configuration API) | External | Calls to ensure instrument-to-rate-source mapping exists at given priority |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON. Uses legacy @@ERROR pattern (not TRY/CATCH). Custom error code 60000 propagated via RAISERROR in both failure paths. Race condition risk: the SELECT EXISTS check is done with NOLOCK and then an INSERT is attempted without a UNIQUE constraint - concurrent calls for the same (InstrumentID, AccountRateSourceID) could both see NULL and both try to INSERT. However, in practice this is a configuration-management procedure called rarely by admin tools (not high-concurrency), so the risk is accepted. The ELSE in the INSERT path only governs COMMIT; RETURN 0 follows as the next unconditional statement. No output to the caller beyond the RETURN value; the OUTPUT parameter is a vestigial API element.

---

## 8. Sample Queries

### 8.1 Add a new rate source mapping

```sql
DECLARE @NewID INT = NULL;
EXEC Price.InstrumentRateSourceAdd
    @InstrumentID = 1,
    @AccountRateSourceID = 21,
    @Priority = 10,
    @InstrumentRateSourceID = @NewID OUTPUT;
-- @NewID remains NULL (unused output parameter)
```

### 8.2 Update priority of existing mapping

```sql
DECLARE @ID INT = NULL;
EXEC Price.InstrumentRateSourceAdd
    @InstrumentID = 1,
    @AccountRateSourceID = 21,
    @Priority = 20,   -- demote from primary to secondary
    @InstrumentRateSourceID = @ID OUTPUT;
-- If (1, 21) exists: calls InstrumentRateSourceEdit to set Priority=20
```

### 8.3 Check current routing before calling

```sql
SELECT IRS.InstrumentRateSourceID, IRS.InstrumentID, IRS.AccountRateSourceID,
       IRS.Priority, ARS.Name AS RateSourceName
FROM Price.InstrumentRateSources IRS WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = IRS.AccountRateSourceID
WHERE IRS.InstrumentID = 1
ORDER BY IRS.Priority;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentRateSourceAdd | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.InstrumentRateSourceAdd.sql*
